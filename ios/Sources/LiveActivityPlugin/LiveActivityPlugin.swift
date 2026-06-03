import Capacitor
import Foundation

@available(iOS 16.2, *)
@objc(LiveActivityPlugin)
public class LiveActivityPlugin: CAPPlugin, CAPBridgedPlugin {
    public let identifier = "LiveActivityPlugin"
    public let jsName = "LiveActivity"

    public let pluginMethods: [CAPPluginMethod] = [
        CAPPluginMethod(name: "startActivity", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "startActivityWithPush", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "startActivityScheduled", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "updateActivity", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "endActivity", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "isAvailable", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "isRunning", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "getCurrentActivity", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "listActivities", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "observePushToStartToken", returnType: CAPPluginReturnPromise),
    ]

    private let implementation = LiveActivity()

    public override func load() {
        super.load()
        implementation.plugin = self
    }

    @objc func startActivity(_ call: CAPPluginCall) {
        guard let id = call.getString("id"),
            let attributes = call.getObject("attributes") as? [String: String],
            let contentState = call.getObject("contentState") as? [String: String]
        else {
            call.reject("Missing required parameters")
            return
        }

        Task {
            do {
                try await implementation.start(
                    id: id, attributes: attributes, content: contentState)
                call.resolve()
            } catch {
                call.reject("Failed to start activity: \(error.localizedDescription)")
            }
        }
    }

    @objc func startActivityWithPush(_ call: CAPPluginCall) {
        let id = call.getString("id") ?? UUID().uuidString
        let attributes = call.getObject("attributes") as? [String: String] ?? [:]
        let contentState = call.getObject("contentState") as? [String: String] ?? [:]

        Task {
            do {
                let activityId = try await implementation.startActivityWithPush(
                    id, attributes: attributes, content: contentState
                )
                call.resolve(["activityId": activityId])
            } catch {
                call.reject("startActivityWithPush failed: \(error.localizedDescription)")
            }
        }
    }

    @objc func startActivityScheduled(_ call: CAPPluginCall) {
        if #available(iOS 26.0, *) {
            guard let id = call.getString("id"),
                let attributes = call.getObject("attributes") as? [String: String],
                let contentState = call.getObject("contentState") as? [String: String],
                let startDate = call.getDouble("startDate"),
                let alertConfig = call.getObject("alertConfiguration")
            else {
                call.reject("Missing required parameters for scheduled activity")
                return
            }

            let enablePushToUpdate = call.getBool("enablePushToUpdate") ?? false
            let styleString = call.getString("style") ?? "standard"

            Task {
                do {
                    let activityId = try await implementation.startActivityScheduled(
                        id: id,
                        attributes: attributes,
                        content: contentState,
                        startDate: Date(timeIntervalSince1970: startDate),
                        alertConfig: alertConfig,
                        enablePushToUpdate: enablePushToUpdate,
                        style: styleString
                    )
                    call.resolve(["activityId": activityId])
                } catch {
                    call.reject("startActivityScheduled failed: \(error.localizedDescription)")
                }
            }
        } else {
            call.reject("startActivityScheduled requires iOS 26.0+")
        }
    }

    @objc func updateActivity(_ call: CAPPluginCall) {
        guard let id = call.getString("id"),
            let contentState = call.getObject("contentState") as? [String: String]
        else {
            call.reject("Missing required parameters")
            return
        }

        Task {
            await implementation.update(id: id, content: contentState)
            call.resolve()
        }
    }

    @objc func endActivity(_ call: CAPPluginCall) {
        guard let id = call.getString("id"),
            let contentState = call.getObject("contentState") as? [String: String]
        else {
            call.reject("Missing required parameters")
            return
        }

        let dismissalPolicy = call.getString("dismissalPolicy")
        let dismissalDate = call.getDouble("dismissalDate").map(NSNumber.init(value:))
        Task {
            await implementation.end(
                id: id,
                content: contentState,
                dismissalPolicy: dismissalPolicy,
                dismissalDate: dismissalDate
            )
            call.resolve()
        }
    }

    @objc func isAvailable(_ call: CAPPluginCall) {
        let available = implementation.isAvailable()
        call.resolve(["value": available])
    }

    @objc func isRunning(_ call: CAPPluginCall) {
        guard let id = call.getString("id") else {
            call.reject("Missing activity id")
            return
        }
        let running = implementation.isRunning(id: id)
        call.resolve(["value": running])
    }

    @objc func getCurrentActivity(_ call: CAPPluginCall) {
        let id = call.getString("id")

        let result = implementation.getCurrent(id: id)

        if let result = result {
            call.resolve(result)
        } else {
            call.resolve([:])  // oder call.reject("No active activity found")
        }
    }

    @objc func listActivities(_ call: CAPPluginCall) {
        let items = implementation.listActivities()
        call.resolve(["items": items])
    }

    @objc func observePushToStartToken(_ call: CAPPluginCall) {
        if #available(iOS 17.2, *) {
            implementation.observePushToStartToken()
            call.resolve()
        } else {
            call.reject("observePushToStartToken requires iOS 17.2+")
        }
    }
}
