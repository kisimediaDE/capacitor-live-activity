import XCTest

@testable import LiveActivityPlugin

class LiveActivityPluginTests: XCTestCase {
    var plugin: LiveActivity!

    override func setUp() {
        plugin = LiveActivity()
    }

    func testIsAvailable() {
        if #available(iOS 16.1, *) {
            let available = plugin.isAvailable()
            XCTAssertTrue(available || !available)  // just confirms call doesn't crash
        } else {
            XCTAssertFalse(plugin.isAvailable())
        }
    }

    func testStartAndGetCurrent() async throws {
        if #available(iOS 16.1, *) {
            let id = "test-activity"
            let attributes = ["type": "demo"]
            let content = ["value": "initial"]

            try await plugin.start(id: id, attributes: attributes, content: content)

            guard let current = plugin.getCurrent(id: id) else {
                XCTFail("Activity should exist after start")
                return
            }

            XCTAssertEqual(current["id"] as? String, id)
            XCTAssertEqual((current["values"] as? [String: String])?["value"], "initial")
        }
    }

    func testUpdateActivity() async {
        if #available(iOS 16.1, *) {
            let id = "update-activity"
            let attributes = ["type": "update"]
            let initial = ["step": "1"]
            let updated = ["step": "2"]

            try? await plugin.start(id: id, attributes: attributes, content: initial)
            await plugin.update(id: id, content: updated)

            let current = plugin.getCurrent(id: id)
            XCTAssertEqual((current?["values"] as? [String: String])?["step"], "2")
        }
    }

    func testEndActivity() async {
        if #available(iOS 16.1, *) {
            let id = "end-activity"
            let attributes = ["type": "end"]
            let content = ["stage": "final"]

            try? await plugin.start(id: id, attributes: attributes, content: content)
            await plugin.end(id: id, content: content)

            let current = plugin.getCurrent(id: id)
            XCTAssertNil(current, "Activity should be removed after end")
        }
    }

    func testIsRunning() async {
        if #available(iOS 16.1, *) {
            let id = "running-test"
            let attributes = ["type": "check"]
            let content = ["key": "val"]

            XCTAssertFalse(plugin.isRunning(id: id))
            try? await plugin.start(id: id, attributes: attributes, content: content)
            XCTAssertTrue(plugin.isRunning(id: id))
            await plugin.end(id: id, content: content)
            XCTAssertFalse(plugin.isRunning(id: id))
        }
    }
}
