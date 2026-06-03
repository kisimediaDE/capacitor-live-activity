import ActivityKit
import Capacitor
import Foundation

private let EVT_PUSH_TOKEN = "liveActivityPushToken"
private let EVT_PUSH_TO_START_TOKEN = "liveActivityPushToStartToken"
private let EVT_ACTIVITY_UPDATE = "liveActivityUpdate"

@available(iOS 16.2, *)
@objc public class LiveActivity: NSObject {
    private var activities: [String: Activity<GenericAttributes>] = [:]
    private let activitiesQueue = DispatchQueue(
        label: "de.kisimedia.capacitor-live-activity.activities")
    weak var plugin: CAPPlugin?

    override public init() {
        super.init()

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

        Task { [weak self] in
            for await data in activity.pushTokenUpdates {
                let token = data.map { String(format: "%02x", $0) }.joined()
                self?.plugin?.notifyListeners(
                    EVT_PUSH_TOKEN,
                    data: [
                        "id": id,
                        "activityId": activity.id,
                        "token": token,
                    ])
            }
        }

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

        // If push is enabled, observe push token updates
        if enablePushToUpdate {
            Task { [weak self] in
                for await data in activity.pushTokenUpdates {
                    let token = data.map { String(format: "%02x", $0) }.joined()
                    self?.plugin?.notifyListeners(
                        EVT_PUSH_TOKEN,
                        data: [
                            "id": id,
                            "activityId": activity.id,
                            "token": token,
                        ])
                }
            }
        }

        return activity.id
    }

    @objc public func update(id: String, content: [String: String]) async {
        if let activity = activity(for: id), isRunningActivity(activity) {
            let state = GenericAttributes.ContentState(values: content)
            await activity.update(ActivityContent(state: state, staleDate: nil))
        }
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
            activities[id] = activity
        }
    }

    private func removeActivity(for id: String) {
        activitiesQueue.sync {
            _ = activities.removeValue(forKey: id)
        }
    }

    private func activity(for id: String) -> Activity<GenericAttributes>? {
        activitiesQueue.sync {
            activities[id]
        }
    }

    private func firstRunningActivity() -> Activity<GenericAttributes>? {
        activitiesQueue.sync {
            activities.values.first { isRunningActivity($0) }
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
}
