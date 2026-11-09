import XCTest
@testable import AutoClicker

@MainActor
final class ClickPlanTests: XCTestCase {
    func testSingleModeUsesFirstPointAndInterval() {
        var profile = ClickProfile.makeDefault()
        profile.mode = .single
        profile.intervalMs = 250
        profile.points = [ClickPoint(name: "A", x: 0.1, y: 0.2), ClickPoint(name: "B", x: 0.9, y: 0.9)]

        let steps = ClickPlan.cycle(for: profile)

        XCTAssertEqual(steps.count, 1)
        XCTAssertEqual(steps[0].point, CGPoint(x: 0.1, y: 0.2))
        XCTAssertEqual(steps[0].delayAfterMs, 250)
    }

    func testIntervalIsClampedToMinimum() {
        var profile = ClickProfile.makeDefault()
        profile.intervalMs = 1
        XCTAssertEqual(ClickPlan.cycle(for: profile)[0].delayAfterMs, ClickProfile.minimumIntervalMs)
    }

    func testSequenceExpandsTapCountWithPerPointDelays() {
        var profile = ClickProfile.makeDefault()
        profile.mode = .sequence
        profile.points = [
            ClickPoint(name: "A", x: 0.2, y: 0.2, tapCount: 3, tapIntervalMs: 50, delayAfterMs: 400),
            ClickPoint(name: "B", x: 0.8, y: 0.8, tapCount: 1, tapIntervalMs: 50, delayAfterMs: 1000)
        ]

        let steps = ClickPlan.cycle(for: profile)

        XCTAssertEqual(steps.map(\.pointIndex), [0, 0, 0, 1])
        XCTAssertEqual(steps.map(\.delayAfterMs), [50, 50, 400, 1000])
        XCTAssertEqual(ClickPlan.cycleDurationMs(for: profile), 1500)
        XCTAssertEqual(ClickPlan.tapsPerCycle(for: profile), 4)
    }

    func testEmptyProfileHasNoSteps() {
        var profile = ClickProfile.makeDefault()
        profile.points = []
        XCTAssertTrue(ClickPlan.cycle(for: profile).isEmpty)
        profile.mode = .sequence
        XCTAssertTrue(ClickPlan.cycle(for: profile).isEmpty)
    }

    func testTotalCycles() {
        var profile = ClickProfile.makeDefault()
        profile.isInfinite = true
        XCTAssertNil(ClickPlan.totalCycles(for: profile))
        profile.isInfinite = false
        profile.repeatCount = 0
        XCTAssertEqual(ClickPlan.totalCycles(for: profile), 1)
        profile.repeatCount = 42
        XCTAssertEqual(ClickPlan.totalCycles(for: profile), 42)
    }

    func testClicksPerSecond() {
        var profile = ClickProfile.makeDefault()
        profile.intervalMs = 100
        XCTAssertEqual(ClickPlan.clicksPerSecond(for: profile), 10, accuracy: 0.001)
    }

    func testTapScriptCallClampsCoordinates() {
        let js = TapScript.tapCall(x: 1.5, y: -0.2, touch: true)
        XCTAssertTrue(js.contains("tap(1.0, 0.0, true)"), js)
    }

    func testURLParsing() {
        XCTAssertEqual(BrowserController.url(from: "https://example.com/a")?.absoluteString, "https://example.com/a")
        XCTAssertEqual(BrowserController.url(from: "example.com")?.absoluteString, "https://example.com")
        XCTAssertEqual(BrowserController.url(from: "cookie clicker")?.host, "www.google.com")
        XCTAssertTrue(TestPage.matches(""))
        XCTAssertTrue(TestPage.matches("Page de test"))
        XCTAssertFalse(TestPage.matches("example.com"))
    }
}
