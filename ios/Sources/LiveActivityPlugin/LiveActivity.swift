import ActivityKit
import Capacitor
import Foundation

private let EVT_PUSH_TOKEN = "liveActivityPushToken"
private let EVT_PUSH_TO_START_TOKEN = "liveActivityPushToStartToken"
private let EVT_ACTIVITY_UPDATE = "liveActivityUpdate"
private let UPDATE_TOKEN_ENDPOINT_KEY =
    "de.kisimedia.capacitor-live-activity.updateTokenEndpoint"

private struct UpdateTokenEndpoint: Codable {
    let url: String
    let headers: [String: String]
}

@available(iOS 16.2, *)
@objc public class LiveActivity: NSObject {
    private var activities: [String: Activity<GenericAttributes>] = [:]
    private var activityOrder: [String] = []
    private var observedTokenActivityIds = Set<String>()
    private var updateTokenEndpoint: UpdateTokenEndpoint?
    private let activitiesQueue = DispatchQueue(
        label: "de.kisimedia.capacitor-live-activity.activities")
    private let endpointQueue = DispatchQueue(
        label: "de.kisimedia.capacitor-live-activity.update-token-endpoint")
    weak var plugin: CAPPlugin?

    override public init() {
        super.init()
        updateTokenEndpoint = Self.loadUpdateTokenEndpoint()

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
            ["http", "https"].contains(scheme)
        else {
            throw NSError(
                domain: "LiveActivity",
                code: 1,
                userInfo: [
                    NSLocalizedDescriptionKey:
                        "setUpdateTokenEndpoint requires a valid http or https URL"
                ])
        }

        let endpoint = UpdateTokenEndpoint(url: url, headers: headers)
        endpointQueue.sync {
            updateTokenEndpoint = endpoint
            Self.saveUpdateTokenEndpoint(endpoint)
        }
    }

    @objc public func start(id: String, attributes: [String: String], content: [String: String])
        async throws
    {
        let attr = GenericAttributes(id: id, staticValues: attributes)
        let state = GenericAttributes.ContentState(values: content)
        let activity = try Activity<GenericAttributes>.request(
            attributes: attr, contentState: state, pushType: nil)
        setActivity(activity, for: id)
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

        setActivity(activity, for: id)

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

        setActivity(activity, for: id)

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

    private func setActivity(_ activity: Activity<GenericAttributes>, for id: String) {
        activitiesQueue.sync {
            if let existingActivity = activities[id] {
                if existingActivity.id != activity.id {
                    activityOrder.removeAll { $0 == id }
                    activityOrder.append(id)
                }
            } else {
                activityOrder.append(id)
            }
            activities[id] = activity
        }
        observePushTokenUpdates(for: activity, logicalId: id)
    }

    private func removeActivity(for id: String) {
        activitiesQueue.sync {
            _ = activities.removeValue(forKey: id)
            activityOrder.removeAll { $0 == id }
        }
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
        let shouldObserve = activitiesQueue.sync {
            if observedTokenActivityIds.contains(activity.id) {
                return false
            }
            observedTokenActivityIds.insert(activity.id)
            return true
        }

        guard shouldObserve else { return }

        Task { [weak self] in
            for await data in activity.pushTokenUpdates {
                let token = data.map { String(format: "%02x", $0) }.joined()
                await self?.handlePushToken(id: id, activityId: activity.id, token: token)
            }
        }
    }

    private func handlePushToken(id: String, activityId: String, token: String) async {
        let payload: [String: String] = [
            "id": id,
            "activityId": activityId,
            "token": token,
        ]

        plugin?.notifyListeners(EVT_PUSH_TOKEN, data: payload)
        await registerUpdateToken(payload: payload)
    }

    private func registerUpdateToken(payload: [String: String]) async {
        guard let endpoint = currentUpdateTokenEndpoint(),
            let url = URL(string: endpoint.url)
        else { return }

        do {
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            endpoint.headers.forEach { key, value in
                request.setValue(value, forHTTPHeaderField: key)
            }
            request.httpBody = try JSONSerialization.data(withJSONObject: payload)

            let (_, response) = try await URLSession.shared.data(for: request)
            if let httpResponse = response as? HTTPURLResponse,
                !(200...299).contains(httpResponse.statusCode)
            {
                print(
                    "⚠️ LiveActivity update token registration failed with HTTP \(httpResponse.statusCode)"
                )
            }
        } catch {
            print(
                "⚠️ LiveActivity update token registration failed: \(error.localizedDescription)"
            )
        }
    }

    private func currentUpdateTokenEndpoint() -> UpdateTokenEndpoint? {
        endpointQueue.sync {
            updateTokenEndpoint
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
}
