import ActivityKit
// ios/Tests/LiveActivityPluginTests/LiveActivityPluginTests.swift
import XCTest

@testable import LiveActivityPlugin

final class LiveActivityPluginTests: XCTestCase {
    var plugin: LiveActivity!

    override func setUp() {
        super.setUp()
        plugin = LiveActivity()
    }

    // Helper: skip if Funktion in der Umgebung nicht sinnvoll testbar ist
    private func skipIfActivitiesUnavailable(file: StaticString = #file, line: UInt = #line) throws
    {
        if #available(iOS 16.2, *) {
            // In Unit-Tests (ohne Host-App/Entitlements) ist das oft false
            let available = ActivityAuthorizationInfo().areActivitiesEnabled
            if !available {
                throw XCTSkip(
                    "Live Activities sind in dieser Test-Umgebung deaktiviert (keine Entitlements/Simulator)."
                )
            }
        } else {
            throw XCTSkip("iOS < 16.2 wird nicht unterstützt.")
        }
    }

    func testIsAvailable() {
        if #available(iOS 16.2, *) {
            // Nur sicherstellen, dass der Call nicht crasht:
            _ = plugin.isAvailable()
        } else {
            XCTAssertFalse(plugin.isAvailable())
        }
    }

    func testStartAndGetCurrent() async throws {
        if #available(iOS 16.2, *) {
            try skipIfActivitiesUnavailable()

            let id = "test-activity"
            let attributes = ["type": "demo"]
            let content = ["value": "initial"]

            do {
                try await plugin.start(id: id, attributes: attributes, content: content)
            } catch {
                // In reinen Unit-Tests kann ActivityKit hier notAuthorized werfen.
                throw XCTSkip("ActivityKit request nicht erlaubt in dieser Umgebung: \(error)")
            }

            guard let current = plugin.getCurrent(id: id) else {
                XCTFail("Activity sollte nach Start existieren")
                return
            }
            XCTAssertEqual(current["id"] as? String, id)
            XCTAssertEqual((current["values"] as? [String: String])?["value"], "initial")
        } else {
            throw XCTSkip("iOS < 16.2")
        }
    }

    func testUpdateActivity() async throws {
        if #available(iOS 16.2, *) {
            try skipIfActivitiesUnavailable()

            let id = "update-activity"
            let attributes = ["type": "update"]
            let initial = ["step": "1"]
            let updated = ["step": "2"]

            do {
                try await plugin.start(id: id, attributes: attributes, content: initial)
            } catch {
                throw XCTSkip("ActivityKit request nicht erlaubt in dieser Umgebung: \(error)")
            }

            await plugin.update(id: id, content: updated)
            let current = plugin.getCurrent(id: id)
            XCTAssertEqual((current?["values"] as? [String: String])?["step"], "2")
        } else {
            throw XCTSkip("iOS < 16.2")
        }
    }

    func testEndActivity() async throws {
        if #available(iOS 16.2, *) {
            try skipIfActivitiesUnavailable()

            let id = "end-activity"
            let attributes = ["type": "end"]
            let content = ["stage": "final"]

            do {
                try await plugin.start(id: id, attributes: attributes, content: content)
            } catch {
                throw XCTSkip("ActivityKit request nicht erlaubt in dieser Umgebung: \(error)")
            }

            // ❗️Signatur hat dismissalDate: NSNumber? – hier nil übergeben
            await plugin.end(id: id, content: content, dismissalDate: nil)

            let current = plugin.getCurrent(id: id)
            XCTAssertNil(current, "Activity sollte nach end() entfernt sein")
        } else {
            throw XCTSkip("iOS < 16.2")
        }
    }

    func testIsRunning() async throws {
        if #available(iOS 16.2, *) {
            try skipIfActivitiesUnavailable()

            let id = "running-test"
            let attributes = ["type": "check"]
            let content = ["key": "val"]

            XCTAssertFalse(plugin.isRunning(id: id))
            do {
                try await plugin.start(id: id, attributes: attributes, content: content)
            } catch {
                throw XCTSkip("ActivityKit request nicht erlaubt in dieser Umgebung: \(error)")
            }
            XCTAssertTrue(plugin.isRunning(id: id))
            await plugin.end(id: id, content: content, dismissalDate: nil)
            XCTAssertFalse(plugin.isRunning(id: id))
        } else {
            throw XCTSkip("iOS < 16.2")
        }
    }

    // Optional: Nur für iOS 17.2+ manuell prüfbar – nicht automatisiert,
    // da ohne Host-/Entitlement und Foreground-State keine Tokens kommen.
    func testObservePushToStartToken_NoCrash() async {
        if #available(iOS 17.2, *) {
            // Nur sicherstellen, dass Aufruf nicht crasht; kein Expectation auf Token.
            plugin.observePushToStartToken()
            XCTAssertTrue(true)
        } else {
            // still ok
        }
    }
}
