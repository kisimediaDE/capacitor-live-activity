import ActivityKit
import Capacitor
import Foundation

/// Please read the Capacitor iOS Plugin Development Guide
/// here: https://capacitorjs.com/docs/plugins/ios
@available(iOS 16.1, *)
@objc(LiveActivityPlugin)
public class LiveActivityPlugin: CAPPlugin, CAPBridgedPlugin {
    public let identifier = "LiveActivityPlugin"
    public let jsName = "LiveActivity"
    public let pluginMethods: [CAPPluginMethod] = [
        CAPPluginMethod(name: "startActivity", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "updateActivity", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "endActivity", returnType: CAPPluginReturnPromise),
    ]
    private let implementation = LiveActivity()

    @objc func startActivity(_ call: CAPPluginCall) {
        guard let id = call.getString("id"),
            let title = call.getString("title"),
            let timerEndDateString = call.getString("timerEndDate"),
            let timerEndDate = ISO8601DateFormatter().date(from: timerEndDateString)
        else {
            call.reject("Missing or invalid parameters")
            return
        }

        let subtitle = call.getString("subtitle")
        let imageBase64 = call.getString("imageBase64")

        implementation.startActivity(
            id: id,
            title: title,
            subtitle: subtitle,
            timerEndDate: timerEndDate,
            imageBase64: imageBase64
        ) { success in
            if success {
                call.resolve()
            } else {
                call.reject("Failed to start Live Activity")
            }
        }
    }

    @objc func updateActivity(_ call: CAPPluginCall) {
        guard let id = call.getString("id") else {
            call.reject("Missing 'id'")
            return
        }

        let title = call.getString("title")
        let subtitle = call.getString("subtitle")
        let timerEndDateString = call.getString("timerEndDate")
        let timerEndDate =
            timerEndDateString != nil ? ISO8601DateFormatter().date(from: timerEndDateString!) : nil
        let imageBase64 = call.getString("imageBase64")

        implementation.updateActivity(
            id: id,
            title: title,
            subtitle: subtitle,
            timerEndDate: timerEndDate,
            imageBase64: imageBase64
        ) { success in
            if success {
                call.resolve()
            } else {
                call.reject("Failed to update Live Activity")
            }
        }
    }

    @objc func endActivity(_ call: CAPPluginCall) {
        guard let id = call.getString("id") else {
            call.reject("Missing 'id'")
            return
        }

        let dismissed = call.getBool("dismissed") ?? true

        implementation.endActivity(
            id: id,
            dismissed: dismissed
        ) { success in
            if success {
                call.resolve()
            } else {
                call.reject("Failed to end Live Activity")
            }
        }
    }
}
