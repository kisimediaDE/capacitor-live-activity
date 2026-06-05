import ActivityKit
// ios/Tests/LiveActivityPluginTests/LiveActivityPluginTests.swift
import XCTest

@testable import LiveActivityPlugin

final class LiveActivityPluginTests: XCTestCase {
    private let updateTokenEndpointKey =
        "de.kisimedia.capacitor-live-activity.updateTokenEndpoint"
    private let cachedUpdateTokensKey =
        "de.kisimedia.capacitor-live-activity.cachedUpdateTokens"
    var plugin: LiveActivity!

    override func setUp() {
        super.setUp()
        UserDefaults.standard.removeObject(forKey: updateTokenEndpointKey)
        UserDefaults.standard.removeObject(forKey: cachedUpdateTokensKey)
        plugin = LiveActivity()
    }

    override func tearDown() {
        UserDefaults.standard.removeObject(forKey: updateTokenEndpointKey)
        UserDefaults.standard.removeObject(forKey: cachedUpdateTokensKey)
        super.tearDown()
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

    func testSetUpdateTokenEndpointRejectsNonHttpUrls() {
        if #available(iOS 16.2, *) {
            XCTAssertThrowsError(
                try plugin.setUpdateTokenEndpoint(
                    url: "ftp://example.com/live-activity/register-token",
                    headers: [:]
                )
            )
        }
    }

    func testSetUpdateTokenEndpointRejectsNonLoopbackHttpUrls() {
        if #available(iOS 16.2, *) {
            XCTAssertThrowsError(
                try plugin.setUpdateTokenEndpoint(
                    url: "http://example.com/live-activity/register-token",
                    headers: [:]
                )
            )
        }
    }

    func testSetUpdateTokenEndpointRejectsHttpsUrlsWithoutHost() {
        if #available(iOS 16.2, *) {
            XCTAssertThrowsError(
                try plugin.setUpdateTokenEndpoint(
                    url: "https:example.com/live-activity/register-token",
                    headers: [:]
                )
            )
        }
    }

    func testSetUpdateTokenEndpointAllowsLoopbackHttpUrls() throws {
        if #available(iOS 16.2, *) {
            try plugin.setUpdateTokenEndpoint(
                url: "http://localhost:3000/live-activity/register-token",
                headers: [:]
            )
            XCTAssertEqual(
                plugin.getUpdateTokenEndpoint()?["url"] as? String,
                "http://localhost:3000/live-activity/register-token"
            )
        }
    }

    func testSetUpdateTokenEndpointPersistsAndReloadsUrlOnly() throws {
        if #available(iOS 16.2, *) {
            try plugin.setUpdateTokenEndpoint(
                url: "https://example.com/live-activity/register-token",
                headers: ["Authorization": "Bearer test-token"]
            )

            let reloadedPlugin = LiveActivity()
            let endpoint = reloadedPlugin.getUpdateTokenEndpoint()

            XCTAssertEqual(
                endpoint?["url"] as? String,
                "https://example.com/live-activity/register-token"
            )
            XCTAssertEqual((endpoint?["headers"] as? [String: String])?.isEmpty, true)
        }
    }

    func testGetActivityPushTokensReturnsPersistedTokens() throws {
        if #available(iOS 16.2, *) {
            let cachedTokens = [
                "activity-1": [
                    "id": "logical-1",
                    "activityId": "activity-1",
                    "token": "abc123",
                ],
                "activity-2": [
                    "id": "logical-2",
                    "activityId": "activity-2",
                    "token": "def456",
                ],
            ]
            let data = try JSONEncoder().encode(cachedTokens)
            UserDefaults.standard.set(data, forKey: cachedUpdateTokensKey)

            let reloadedPlugin = LiveActivity()

            XCTAssertEqual(reloadedPlugin.getActivityPushTokens(id: nil).count, 2)
            XCTAssertEqual(
                reloadedPlugin.getActivityPushTokens(id: "logical-2").first?["token"],
                "def456"
            )
        }
    }

    func testGetActivityPushTokensSortsByCachedAtWithoutExposingTimestamp() throws {
        if #available(iOS 16.2, *) {
            let cachedTokens: [String: [String: Any]] = [
                "activity-new": [
                    "id": "logical-1",
                    "activityId": "activity-new",
                    "token": "new-token",
                    "cachedAt": 200.0,
                ],
                "activity-old": [
                    "id": "logical-1",
                    "activityId": "activity-old",
                    "token": "old-token",
                    "cachedAt": 100.0,
                ],
            ]
            let data = try JSONSerialization.data(withJSONObject: cachedTokens)
            UserDefaults.standard.set(data, forKey: cachedUpdateTokensKey)

            let reloadedPlugin = LiveActivity()
            let tokens = reloadedPlugin.getActivityPushTokens(id: "logical-1")

            XCTAssertEqual(tokens.map { $0["token"] }, ["old-token", "new-token"])
            XCTAssertNil(tokens.last?["cachedAt"])
        }
    }

    func testGetActivityPushTokensPrunesPersistedCacheOnStartup() throws {
        if #available(iOS 16.2, *) {
            let cachedTokens = Dictionary(
                uniqueKeysWithValues: (0..<55).map { index in
                    (
                        "activity-\(index)",
                        [
                            "id": "logical-\(index)",
                            "activityId": "activity-\(index)",
                            "token": "token-\(index)",
                            "cachedAt": Double(index),
                        ] as [String: Any]
                    )
                })
            let data = try JSONSerialization.data(withJSONObject: cachedTokens)
            UserDefaults.standard.set(data, forKey: cachedUpdateTokensKey)

            let reloadedPlugin = LiveActivity()
            let tokens = reloadedPlugin.getActivityPushTokens(id: nil)

            XCTAssertEqual(tokens.count, 50)
            XCTAssertNil(tokens.first { $0["activityId"] == "activity-0" })
            XCTAssertNotNil(tokens.first { $0["activityId"] == "activity-54" })
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

            await plugin.end(
                id: id,
                content: content,
                dismissalPolicy: "immediate",
                dismissalDate: nil
            )

            let current = plugin.getCurrent(id: id)
            XCTAssertNil(current, "Activity sollte nach end(immediate) entfernt sein")
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
            await plugin.end(id: id, content: content, dismissalPolicy: nil, dismissalDate: nil)
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
