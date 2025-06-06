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

        let imageData = ImageProcessor.resizedAndCompressedImage(from: imageBase64)

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

        let imageData = ImageProcessor.resizedAndCompressedImage(from: imageBase64)
        if imageData != nil {
            updatedState.imageData = imageData
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

    @objc public func isActivityRunning(id: String, completion: @escaping (Bool) -> Void) {
        let isRunning = Activity<LiveActivityAttributes>.activities.contains { activity in
            activity.attributes.id == id
        }
        completion(isRunning)
    }
}

private struct ImageProcessor {
    static func resizedAndCompressedImage(from base64: String?) -> Data? {
        guard let base64 = base64,
            let imageDecoded = Data(base64Encoded: base64),
            let uiImage = UIImage(data: imageDecoded)
        else {
            return nil
        }

        let targetSize = CGSize(width: 117, height: 117)
        UIGraphicsBeginImageContextWithOptions(targetSize, false, 1.0)
        uiImage.draw(in: CGRect(origin: .zero, size: targetSize))
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        guard let resized = resizedImage else {
            print("⚠️ Failed to resize image.")
            return nil
        }

        var quality: CGFloat = 0.8
        while quality > 0.1 {
            if let compressed = resized.jpegData(compressionQuality: quality),
                compressed.count < 3000
            {
                print("✅ Successfully resized and compressed image to \(compressed.count) bytes.")
                return compressed
            }
            print(
                "⚠️ Resized image too large: \(resized.jpegData(compressionQuality: quality)?.count ?? 0) bytes at quality \(quality)"
            )
            quality -= 0.1
        }

        print("⚠️ Resized image too large even after compression.")
        return nil
    }
}
