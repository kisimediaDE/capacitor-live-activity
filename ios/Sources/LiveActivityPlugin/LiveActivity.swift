import ActivityKit
import Foundation
import UIKit

/// Attributes used to define a Live Activity.
struct LiveActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        /// Title displayed in the Live Activity.
        var title: String
        /// Subtitle (optional).
        var subtitle: String?
        /// End time of countdown (if used).
        var timerEndDate: Date?
        /// Optional image as Data.
        var imageData: Data?
    }

    /// Required static attributes (can be empty if unused).
    var id: String
}

@available(iOS 16.1, *)
@objc public class LiveActivity: NSObject {

    /// Stores currently running activities by their custom ID.
    private var activities: [String: Activity<LiveActivityAttributes>] = [:]

    /// Starts a new Live Activity.
    @objc public func startActivity(
        id: String,
        title: String,
        subtitle: String?,
        timerEndDate: Date,
        imageBase64: String?,
        completion: @escaping (Bool) -> Void
    ) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            completion(false)
            return
        }

        let attributes = LiveActivityAttributes(id: id)

        var imageData: Data? = nil
        if let imageBase64 = imageBase64,
            let imageDecoded = Data(base64Encoded: imageBase64)
        {
            imageData = imageDecoded
        }

        let contentState = LiveActivityAttributes.ContentState(
            title: title,
            subtitle: subtitle,
            timerEndDate: timerEndDate,
            imageData: imageData
        )

        do {
            let activity = try Activity<LiveActivityAttributes>.request(
                attributes: attributes,
                contentState: contentState,
                pushType: nil
            )

            activities[id] = activity
            completion(true)
        } catch {
            print("Error starting Live Activity:", error.localizedDescription)
            completion(false)
        }
    }

    /// Updates an existing Live Activity.
    @objc public func updateActivity(
        id: String,
        title: String?,
        subtitle: String?,
        timerEndDate: Date?,
        imageBase64: String?,
        completion: @escaping (Bool) -> Void
    ) {
        guard let activity = activities[id] else {
            completion(false)
            return
        }

        var updatedState = activity.contentState

        if let title = title {
            updatedState.title = title
        }

        if let subtitle = subtitle {
            updatedState.subtitle = subtitle
        }

        if let date = timerEndDate {
            updatedState.timerEndDate = date
        }

        if let imageBase64 = imageBase64,
            let imageDecoded = Data(base64Encoded: imageBase64)
        {
            updatedState.imageData = imageDecoded
        }

        Task {
            await activity.update(using: updatedState)
            completion(true)
        }
    }

    /// Ends an existing Live Activity.
    @objc public func endActivity(
        id: String,
        dismissed: Bool,
        completion: @escaping (Bool) -> Void
    ) {
        guard let activity = activities[id] else {
            completion(false)
            return
        }

        Task {
            let finalState = activity.contentState
            await activity.end(
                using: finalState,
                dismissalPolicy: dismissed ? .immediate : .after(Date().addingTimeInterval(10))
            )
            activities.removeValue(forKey: id)
            completion(true)
        }
    }
}
