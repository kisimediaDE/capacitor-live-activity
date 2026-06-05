import ActivityKit
import Capacitor
import Foundation

private let EVT_PUSH_TOKEN = "liveActivityPushToken"
private let EVT_PUSH_TO_START_TOKEN = "liveActivityPushToStartToken"
private let EVT_ACTIVITY_UPDATE = "liveActivityUpdate"
private let UPDATE_TOKEN_ENDPOINT_KEY =
    "de.kisimedia.capacitor-live-activity.updateTokenEndpoint"
private let CACHED_UPDATE_TOKENS_KEY =
    "de.kisimedia.capacitor-live-activity.cachedUpdateTokens"

private struct UpdateTokenEndpoint: Codable {
    let url: String
}

private struct CachedUpdateToken: Codable {
    let id: String
    let activityId: String
    let token: String
    let cachedAt: TimeInterval
}

@available(iOS 16.2, *)
@objc public class LiveActivity: NSObject {
    private static let maxCachedUpdateTokens = 50
    private var activities: [String: Activity<GenericAttributes>] = [:]
    private var activityOrder: [String] = []
    private var observedTokenActivityIds = Set<String>()
    private var pushTokenObserverTasks: [String: Task<Void, Never>] = [:]
    private var pushTokenObserverGenerations: [String: UUID] = [:]
    private var pushTokenObservationDisabledActivityIds = Set<String>()
    private var updateTokenEndpoint: UpdateTokenEndpoint?
    private var updateTokenHeaders: [String: String] = [:]
    private var cachedUpdateTokens: [String: CachedUpdateToken] = [:]
    private let activitiesQueue = DispatchQueue(
        label: "de.kisimedia.capacitor-live-activity.activities")
    private let endpointQueue = DispatchQueue(
        label: "de.kisimedia.capacitor-live-activity.update-token-endpoint")
    private let tokenCacheQueue = DispatchQueue(
        label: "de.kisimedia.capacitor-live-activity.update-token-cache")
    weak var plugin: CAPPlugin?

    override public init() {
        super.init()
        updateTokenEndpoint = Self.loadUpdateTokenEndpoint()
        cachedUpdateTokens = Self.loadCachedUpdateTokens()
        tokenCacheQueue.sync {
            let prunedTokens = Self.prunedCachedUpdateTokens(cachedUpdateTokens)
            if prunedTokens.count != cachedUpdateTokens.count {
                cachedUpdateTokens = prunedTokens
                Self.saveCachedUpdateTokens(cachedUpdateTokens)
            }
        }

        Task {
            for activity in Activity<GenericAttributes>.activities {
                let id = activity.attributes.id

                switch activity.activityState {
                case .active, .stale, .pending, .ended:
                    setActivity(activity, for: id)
                case .dismissed:
                    print("🧹 Ignored dismissed activity: \(id)")
                @unknown default:
                    print("⚠️ Unknown state for activity: \(id)")
                }
            }

            print("✅ Init complete. Known activities: \(knownActivityCount())")
            self.observeActivityUpdates()
        }
    }

    @objc public func isAvailable() -> Bool {
        return ActivityAuthorizationInfo().areActivitiesEnabled
    }

    @objc public func setUpdateTokenEndpoint(url: String, headers: [String: String]) throws {
        guard let endpointUrl = URL(string: url),
            let scheme = endpointUrl.scheme?.lowercased(),
            let host = endpointUrl.host,
            scheme == "https" || (scheme == "http" && Self.isLoopbackHost(host))
        else {
            throw NSError(
                domain: "LiveActivity",
                code: 1,
                userInfo: [
                    NSLocalizedDescriptionKey:
                        "setUpdateTokenEndpoint requires an https URL or a loopback http URL for development"
                ])
        }

        let endpoint = UpdateTokenEndpoint(url: url)
        endpointQueue.sync {
            updateTokenEndpoint = endpoint
            updateTokenHeaders = headers
            Self.saveUpdateTokenEndpoint(endpoint)
        }
    }

    func getUpdateTokenEndpoint() -> [String: Any]? {
        endpointQueue.sync {
            guard let endpoint = updateTokenEndpoint else { return nil }
            return [
                "url": endpoint.url,
                "headers": updateTokenHeaders,
            ]
        }
    }

    @objc public func getActivityPushTokens(id: String?) -> [[String: String]] {
        tokenCacheQueue.sync {
            cachedUpdateTokens.values
                .filter { token in
                    guard let id else { return true }
                    return token.id == id
                }
                .sorted { left, right in
                    if left.cachedAt == right.cachedAt {
                        return left.activityId < right.activityId
                    }
                    return left.cachedAt < right.cachedAt
                }
                .map { token in
                    [
                        "id": token.id,
                        "activityId": token.activityId,
                        "token": token.token,
                    ]
                }
        }
    }

    @objc public func start(id: String, attributes: [String: String], content: [String: String])
        async throws
    {
        let attr = GenericAttributes(id: id, staticValues: attributes)
        let state = GenericAttributes.ContentState(values: content)
        let activity = try Activity<GenericAttributes>.request(
            attributes: attr, contentState: state, pushType: nil)
        setActivity(activity, for: id, observePushTokenUpdates: false)
    }

    @objc public func startActivityWithPush(
        _ id: String,
        attributes: [String: String],
        content: [String: String]
    ) async throws -> String {
        let attr = GenericAttributes(id: id, staticValues: attributes)
        let state = GenericAttributes.ContentState(values: content)

        let activity = try Activity<GenericAttributes>.request(
            attributes: attr,
            contentState: state,
            pushType: .token
        )

        setActivity(activity, for: id, observePushTokenUpdates: true)

        return activity.id
    }

    @available(iOS 26.0, *)
    @objc public func startActivityScheduled(
        id: String,
        attributes: [String: String],
        content: [String: String],
        startDate: Date,
        alertConfig: [String: Any],
        enablePushToUpdate: Bool,
        style: String
    ) async throws -> String {
        let attr = GenericAttributes(id: id, staticValues: attributes)
        let state = GenericAttributes.ContentState(values: content)
        let activityContent = ActivityContent(state: state, staleDate: nil)

        // Parse alert configuration
        let alertTitle = alertConfig["title"] as? String ?? ""
        let alertBody = alertConfig["body"] as? String ?? ""
        let alertSound = alertConfig["sound"] as? String

        let alert = AlertConfiguration(
            title: .init(stringLiteral: alertTitle),
            body: .init(stringLiteral: alertBody),
            sound: alertSound.map { .named($0) } ?? .default
        )

        // Determine activity style
        let activityStyle: ActivityStyle = (style == "transient") ? .transient : .standard

        // Determine push type
        let pushType: PushType? = enablePushToUpdate ? .token : nil

        // Request scheduled activity
        let activity = try Activity<GenericAttributes>.request(
            attributes: attr,
            content: activityContent,
            pushType: pushType,
            style: activityStyle,
            alertConfiguration: alert,
            start: startDate
        )

        setActivity(activity, for: id, observePushTokenUpdates: enablePushToUpdate)

        return activity.id
    }

    @objc public func update(id: String, content: [String: String]) async {
        if let activity = activity(for: id), isRunningActivity(activity) {
            let state = GenericAttributes.ContentState(values: content)
            await activity.update(ActivityContent(state: state, staleDate: nil))
        }
    }

    @objc public func end(id: String, content: [String: String], dismissalDate: NSNumber?) async {
        await end(id: id, content: content, dismissalPolicy: nil, dismissalDate: dismissalDate)
    }

    @objc public func end(
        id: String,
        content: [String: String],
        dismissalPolicy policy: String?,
        dismissalDate: NSNumber?
    ) async {
        if let activity = activity(for: id) {
            let state = GenericAttributes.ContentState(values: content)

            let dismissesImmediately = policy == "immediate"
            let dismissesAfterDate = policy == "after" || policy == nil
            let dismissalPolicy: ActivityUIDismissalPolicy
            if dismissesImmediately {
                dismissalPolicy = .immediate
            } else if dismissesAfterDate, let dismissalTimestamp = dismissalDate {
                let date = Date(timeIntervalSince1970: dismissalTimestamp.doubleValue)
                dismissalPolicy = .after(date)
            } else {
                dismissalPolicy = .default
            }

            await activity.end(
                ActivityContent(state: state, staleDate: nil),
                dismissalPolicy: dismissalPolicy
            )

            if dismissesImmediately {
                removeActivity(for: id)
            } else {
                setActivity(activity, for: id)
            }
        }
    }

    @objc public func isRunning(id: String) -> Bool {
        guard let activity = activity(for: id) else { return false }

        return isRunningActivity(activity)
    }

    private func isRunningActivity(_ activity: Activity<GenericAttributes>) -> Bool {
        switch activity.activityState {
        case .active, .stale, .pending:
            return true
        case .ended, .dismissed:
            return false
        @unknown default:
            return false
        }
    }

    @objc public func getCurrent(id: String?) -> [String: Any]? {
        var selectedActivity: Activity<GenericAttributes>?

        if let id = id {
            selectedActivity = activity(for: id)
        } else {
            selectedActivity = firstRunningActivity()
        }

        guard let a = selectedActivity else { return nil }
        guard isRunningActivity(a) else { return nil }

        return [
            "id": a.id,
            "values": a.content.state.values,
            "isStale": a.content.staleDate != nil,
            "isEnded": a.activityState == .ended,
            "startedAt": a.content.state.values["startedAt"] ?? "",
        ]
    }

    @objc public func observeActivityUpdates() {
        Task { [weak self] in
            for await a in Activity<GenericAttributes>.activityUpdates {
                switch a.activityState {
                case .active, .stale, .pending, .ended:
                    self?.setActivity(a, for: a.attributes.id)
                case .dismissed:
                    self?.removeActivity(for: a.attributes.id)
                @unknown default:
                    break
                }

                // Lebenszyklus-Event nach außen
                self?.plugin?.notifyListeners(
                    EVT_ACTIVITY_UPDATE,
                    data: [
                        "id": a.attributes.id,
                        "activityId": a.id,
                        "state": String(describing: a.activityState),
                    ])
            }
        }
    }

    private func setActivity(
        _ activity: Activity<GenericAttributes>,
        for id: String,
        observePushTokenUpdates shouldObservePushToken: Bool? = nil
    ) {
        var taskToCancel: Task<Void, Never>?
        activitiesQueue.sync {
            if let existingActivity = activities[id] {
                if existingActivity.id != activity.id {
                    activityOrder.removeAll { $0 == id }
                    activityOrder.append(id)
                    taskToCancel = stopObservingPushTokenUpdatesLocked(
                        for: existingActivity.id)
                    pushTokenObservationDisabledActivityIds.remove(existingActivity.id)
                }
            } else {
                activityOrder.append(id)
            }
            if let shouldObservePushToken {
                if shouldObservePushToken {
                    pushTokenObservationDisabledActivityIds.remove(activity.id)
                } else {
                    pushTokenObservationDisabledActivityIds.insert(activity.id)
                }
            }
            activities[id] = activity
        }
        taskToCancel?.cancel()

        let shouldObserve = shouldObservePushToken ?? shouldObserveDiscoveredPushTokens(
            for: activity.id)
        if shouldObserve {
            observePushTokenUpdates(for: activity, logicalId: id)
        }
    }

    private func removeActivity(for id: String) {
        var taskToCancel: Task<Void, Never>?
        activitiesQueue.sync {
            if let activity = activities.removeValue(forKey: id) {
                taskToCancel = stopObservingPushTokenUpdatesLocked(for: activity.id)
                pushTokenObservationDisabledActivityIds.remove(activity.id)
            }
            activityOrder.removeAll { $0 == id }
        }
        taskToCancel?.cancel()
    }

    private func activity(for id: String) -> Activity<GenericAttributes>? {
        activitiesQueue.sync {
            activities[id]
        }
    }

    private func firstRunningActivity() -> Activity<GenericAttributes>? {
        activitiesQueue.sync {
            activityOrder.reversed().compactMap { activities[$0] }.first {
                isRunningActivity($0)
            }
        }
    }

    private func knownActivityCount() -> Int {
        activitiesQueue.sync {
            activities.count
        }
    }

    @objc public func listActivities() -> [[String: String]] {
        Activity<GenericAttributes>.activities.map {
            [
                "id": $0.attributes.id,
                "activityId": $0.id,
                "state": String(describing: $0.activityState),
            ]
        }
    }

    @available(iOS 17.2, *)
    @objc public func observePushToStartToken() {
        Task { [weak self] in
            for await data in Activity<GenericAttributes>.pushToStartTokenUpdates {
                let token = data.map { String(format: "%02x", $0) }.joined()
                self?.plugin?.notifyListeners(
                    EVT_PUSH_TO_START_TOKEN,
                    data: [
                        "token": token
                    ])
            }
        }
    }

    private func observePushTokenUpdates(
        for activity: Activity<GenericAttributes>,
        logicalId id: String
    ) {
        let generation = UUID()
        let shouldCreateTask = activitiesQueue.sync {
            if observedTokenActivityIds.contains(activity.id) {
                return false
            }
            observedTokenActivityIds.insert(activity.id)
            pushTokenObserverGenerations[activity.id] = generation
            return true
        }

        guard shouldCreateTask else { return }

        let task = Task { [weak self] in
            defer {
                self?.finishObservingPushTokenUpdates(
                    for: activity.id,
                    generation: generation
                )
            }
            for await data in activity.pushTokenUpdates {
                let token = data.map { String(format: "%02x", $0) }.joined()
                await self?.handlePushToken(id: id, activityId: activity.id, token: token)
            }
        }

        let shouldCancelTask = activitiesQueue.sync {
            guard pushTokenObserverGenerations[activity.id] == generation else {
                return true
            }
            pushTokenObserverTasks[activity.id] = task
            return false
        }
        if shouldCancelTask {
            task.cancel()
        }
    }

    private func shouldObserveDiscoveredPushTokens(for activityId: String) -> Bool {
        activitiesQueue.sync {
            !pushTokenObservationDisabledActivityIds.contains(activityId)
        }
    }

    private func stopObservingPushTokenUpdatesLocked(for activityId: String) -> Task<Void, Never>?
    {
        observedTokenActivityIds.remove(activityId)
        pushTokenObserverGenerations.removeValue(forKey: activityId)
        return pushTokenObserverTasks.removeValue(forKey: activityId)
    }

    private func finishObservingPushTokenUpdates(for activityId: String, generation: UUID) {
        activitiesQueue.sync {
            guard pushTokenObserverGenerations[activityId] == generation else { return }
            observedTokenActivityIds.remove(activityId)
            pushTokenObserverGenerations.removeValue(forKey: activityId)
            pushTokenObserverTasks.removeValue(forKey: activityId)
        }
    }

    private func handlePushToken(id: String, activityId: String, token: String) async {
        let payload: [String: Any] = [
            "id": id,
            "activityId": activityId,
            "token": token,
        ]
        cacheUpdateToken(id: id, activityId: activityId, token: token)

        plugin?.notifyListeners(EVT_PUSH_TOKEN, data: payload)
        await registerUpdateToken(payload: payload)
    }

    private func cacheUpdateToken(id: String, activityId: String, token: String) {
        tokenCacheQueue.sync {
            if let existing = cachedUpdateTokens[activityId],
                existing.id == id,
                existing.token == token
            {
                return
            }

            cachedUpdateTokens[activityId] = CachedUpdateToken(
                id: id,
                activityId: activityId,
                token: token,
                cachedAt: Date().timeIntervalSince1970
            )
            pruneCachedUpdateTokens()
            Self.saveCachedUpdateTokens(cachedUpdateTokens)
        }
    }

    private func pruneCachedUpdateTokens() {
        guard cachedUpdateTokens.count > Self.maxCachedUpdateTokens else { return }

        cachedUpdateTokens = Self.prunedCachedUpdateTokens(cachedUpdateTokens)
    }

    private func registerUpdateToken(payload: [String: Any]) async {
        guard let config = currentUpdateTokenConfiguration(),
            let url = URL(string: config.endpoint.url)
        else { return }

        do {
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            config.headers.forEach { key, value in
                request.setValue(value, forHTTPHeaderField: key)
            }
            request.httpBody = try JSONSerialization.data(withJSONObject: payload)

            let (_, response) = try await URLSession.shared.data(for: request)
            if let httpResponse = response as? HTTPURLResponse,
                !(200...299).contains(httpResponse.statusCode)
            {
                print(
                    "⚠️ LiveActivity update token registration failed with HTTP \(httpResponse.statusCode) for \(config.endpoint.url)"
                )
            }
        } catch {
            print(
                "⚠️ LiveActivity update token registration failed for \(config.endpoint.url): \(error.localizedDescription)"
            )
        }
    }

    private func currentUpdateTokenConfiguration() -> (
        endpoint: UpdateTokenEndpoint,
        headers: [String: String]
    )? {
        endpointQueue.sync {
            guard let endpoint = updateTokenEndpoint else { return nil }
            return (endpoint, updateTokenHeaders)
        }
    }

    private static func loadUpdateTokenEndpoint() -> UpdateTokenEndpoint? {
        guard let data = UserDefaults.standard.data(forKey: UPDATE_TOKEN_ENDPOINT_KEY) else {
            return nil
        }

        return try? JSONDecoder().decode(UpdateTokenEndpoint.self, from: data)
    }

    private static func saveUpdateTokenEndpoint(_ endpoint: UpdateTokenEndpoint) {
        guard let data = try? JSONEncoder().encode(endpoint) else { return }
        UserDefaults.standard.set(data, forKey: UPDATE_TOKEN_ENDPOINT_KEY)
    }

    private static func loadCachedUpdateTokens() -> [String: CachedUpdateToken] {
        guard let data = UserDefaults.standard.data(forKey: CACHED_UPDATE_TOKENS_KEY) else {
            return [:]
        }

        if let tokens = try? JSONDecoder().decode([String: CachedUpdateToken].self, from: data) {
            return tokens
        }

        guard let legacyTokens = try? JSONDecoder().decode(
            [String: [String: String]].self, from: data)
        else {
            return [:]
        }

        return Dictionary(
            uniqueKeysWithValues: legacyTokens.compactMap { activityId, token in
                guard let id = token["id"],
                    let tokenActivityId = token["activityId"],
                    let tokenValue = token["token"]
                else {
                    return nil
                }

                return (
                    activityId,
                    CachedUpdateToken(
                        id: id,
                        activityId: tokenActivityId,
                        token: tokenValue,
                        cachedAt: 0
                    )
                )
            })
    }

    private static func saveCachedUpdateTokens(_ tokens: [String: CachedUpdateToken]) {
        let prunedTokens = prunedCachedUpdateTokens(tokens)

        guard let data = try? JSONEncoder().encode(prunedTokens) else { return }
        UserDefaults.standard.set(data, forKey: CACHED_UPDATE_TOKENS_KEY)
    }

    private static func prunedCachedUpdateTokens(
        _ tokens: [String: CachedUpdateToken]
    ) -> [String: CachedUpdateToken] {
        guard tokens.count > maxCachedUpdateTokens else { return tokens }

        return Dictionary(
            uniqueKeysWithValues: tokens.values
                .sorted { left, right in
                    if left.cachedAt == right.cachedAt {
                        return left.activityId > right.activityId
                    }
                    return left.cachedAt > right.cachedAt
                }
                .prefix(maxCachedUpdateTokens)
                .map { ($0.activityId, $0) }
        )
    }

    private static func isLoopbackHost(_ host: String?) -> Bool {
        guard let host = host?.lowercased() else { return false }
        return ["localhost", "127.0.0.1", "::1"].contains(host)
    }
}
