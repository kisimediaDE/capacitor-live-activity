import ActivityKit
import Capacitor
import Foundation

private let EVT_PUSH_TOKEN = "liveActivityPushToken"
private let EVT_PUSH_TO_START_TOKEN = "liveActivityPushToStartToken"
private let EVT_ACTIVITY_UPDATE = "liveActivityUpdate"

@available(iOS 16.2, *)
@objc public class LiveActivity: NSObject {
    private var activities: [String: Activity<GenericAttributes>] = [:]
    weak var plugin: CAPPlugin?

    override public init() {
        super.init()

        Task {
            for activity in Activity<GenericAttributes>.activities {
                let id = activity.attributes.id

                switch activity.activityState {
                case .active, .stale, .pending:
                    activities[id] = activity
                case .ended, .dismissed:
                    /// No action: ignore ended/dismissed activities (cleanup)
                    print("🧹 Ignored ended activity: \(id)")
                @unknown default:
                    print("⚠️ Unknown state for activity: \(id)")
                }
            }

            print("✅ Init complete. Active activities: \(activities.count)")
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
        activities[id] = activity
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

        self.activities[id] = activity

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

    @objc public func update(id: String, content: [String: String]) async {
        if let activity = activities[id] {
            let state = GenericAttributes.ContentState(values: content)
            await activity.update(ActivityContent(state: state, staleDate: nil))
        }
    }

    @objc public func end(id: String, content: [String: String], dismissalDate: NSNumber?) async {
        if let activity = activities[id] {
            let state = GenericAttributes.ContentState(values: content)

            var dismissalPolicy: ActivityUIDismissalPolicy = .default

            if let dismissalTimestamp = dismissalDate {
                let date = Date(timeIntervalSince1970: dismissalTimestamp.doubleValue)
                dismissalPolicy = .after(date)
            }

            await activity.end(
                ActivityContent(state: state, staleDate: nil),
                dismissalPolicy: dismissalPolicy
            )

            activities.removeValue(forKey: id)
        }
    }

    @objc public func isRunning(id: String) -> Bool {
        return activities[id] != nil
    }

    @objc public func getCurrent(id: String?) -> [String: Any]? {
        var activity: Activity<GenericAttributes>?

        if let id = id {
            activity = activities[id]
        } else {
            activity = activities.values.first
        }

        guard let a = activity else { return nil }

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
                case .active, .stale, .pending:
                    self?.activities[a.attributes.id] = a
                case .ended, .dismissed:
                    self?.activities.removeValue(forKey: a.attributes.id)
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
