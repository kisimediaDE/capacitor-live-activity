import ActivityKit
import Foundation

@available(iOS 16.2, *)
@objc public class LiveActivity: NSObject {
    private var activities: [String: Activity<GenericAttributes>] = [:]

    override public init() {
        super.init()

            Task {
                for activity in Activity<GenericAttributes>.activities {
                    let id = activity.attributes.id

                    switch activity.activityState {
                    case .active, .stale:
                        activities[id] = activity
                    case .ended, .dismissed:
                        // Keine Aktion: wird nicht übernommen = "Cleanup"
                        print("🧹 Ignored ended activity: \(id)")
                    @unknown default:
                        print("⚠️ Unknown state for activity: \(id)")
                    }
                }

                print("✅ Init complete. Active activities: \(activities.count)")
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
}
