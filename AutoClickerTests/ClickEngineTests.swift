import XCTest
@testable import AutoClicker

/// Cible factice qui enregistre les clics reçus.
@MainActor
final class RecordingTarget: ClickTarget {
    var taps: [CGPoint] = []
    var answer = true

    func performTap(at point: CGPoint, sendTouchEvents: Bool) async -> Bool {
        taps.append(point)
        return answer
    }
}

@MainActor
final class ClickEngineTests: XCTestCase {
    private var engine: ClickEngine!
    private var target: RecordingTarget!

    override func setUp() async throws {
        engine = ClickEngine()
        target = RecordingTarget()
        engine.target = target
    }

    override func tearDown() async throws {
        engine.stop()
    }

    private func profile(mode: ClickMode, count: Int?, points: [ClickPoint], intervalMs: Int = 20) -> ClickProfile {
        var p = ClickProfile.makeDefault(name: "Test")
        p.mode = mode
        p.intervalMs = intervalMs
        p.isInfinite = count == nil
        p.repeatCount = count ?? 1
        p.points = points
        return p
    }

    /// Attend qu'une condition soit vraie (ou échoue après le délai).
    private func waitUntil(timeout: TimeInterval = 5, _ condition: () -> Bool,
                           file: StaticString = #filePath, line: UInt = #line) async {
        let end = Date().addingTimeInterval(timeout)
        while !condition() {
            if Date() > end {
                XCTFail("Condition non remplie à temps", file: file, line: line)
                return
            }
            try? await Task.sleep(nanoseconds: 10_000_000)
        }
    }

    func testSingleModeStopsAfterCount() async {
        let p = profile(mode: .single, count: 5, points: [ClickPoint(name: "A", x: 0.5, y: 0.5)])
        XCTAssertTrue(engine.start(profile: p))
        await waitUntil { self.engine.state == .idle }
        XCTAssertEqual(target.taps.count, 5)
        XCTAssertEqual(engine.tapsPerformed, 5)
        XCTAssertEqual(engine.cyclesCompleted, 5)
    }

    func testSequenceOrderAndCycles() async {
        let a = ClickPoint(name: "A", x: 0.1, y: 0.1, tapCount: 2, tapIntervalMs: 20, delayAfterMs: 20)
        let b = ClickPoint(name: "B", x: 0.9, y: 0.9, tapCount: 1, tapIntervalMs: 20, delayAfterMs: 20)
        let p = profile(mode: .sequence, count: 2, points: [a, b])
        engine.start(profile: p)
        await waitUntil { self.engine.state == .idle }
        let expected = [a.normalized, a.normalized, b.normalized, a.normalized, a.normalized, b.normalized]
        XCTAssertEqual(target.taps, expected)
    }

    func testPauseResumeAndStop() async {
        let p = profile(mode: .single, count: nil, points: [ClickPoint(name: "A", x: 0.5, y: 0.5)])
        engine.start(profile: p)
        await waitUntil { self.target.taps.count >= 2 }

        engine.pause()
        XCTAssertEqual(engine.state, .paused)
        try? await Task.sleep(nanoseconds: 100_000_000)
        let pausedCount = target.taps.count
        try? await Task.sleep(nanoseconds: 200_000_000)
        XCTAssertEqual(target.taps.count, pausedCount, "Aucun clic pendant la pause")

        engine.resume()
        await waitUntil { self.target.taps.count >= pausedCount + 2 }

        engine.stop()
        XCTAssertEqual(engine.state, .idle)
        let stoppedCount = target.taps.count
        try? await Task.sleep(nanoseconds: 150_000_000)
        XCTAssertEqual(target.taps.count, stoppedCount, "Aucun clic après l'arrêt")
    }

    func testMissedTapsAreCounted() async {
        target.answer = false
        let p = profile(mode: .single, count: 3, points: [ClickPoint(name: "A", x: 0.5, y: 0.5)])
        engine.start(profile: p)
        await waitUntil { self.engine.state == .idle }
        XCTAssertEqual(engine.missedTaps, 3)
        XCTAssertEqual(engine.tapsPerformed, 0)
    }

    func testStartDelayShowsCountdown() async {
        var p = profile(mode: .single, count: 1, points: [ClickPoint(name: "A", x: 0.5, y: 0.5)])
        p.startDelayMs = 1500
        engine.start(profile: p)
        await waitUntil { if case .countdown = self.engine.state { return true } else { return false } }
        XCTAssertEqual(engine.state, .countdown(seconds: 2))
        XCTAssertTrue(target.taps.isEmpty)
        await waitUntil { self.engine.state == .idle }
        XCTAssertEqual(target.taps.count, 1)
    }

    func testCannotStartWithoutPoints() {
        let p = profile(mode: .single, count: 1, points: [])
        XCTAssertFalse(engine.start(profile: p))
        XCTAssertEqual(engine.state, .idle)
    }

    func testRhythmIsRespected() async {
        let p = profile(mode: .single, count: 10, points: [ClickPoint(name: "A", x: 0.5, y: 0.5)], intervalMs: 50)
        let started = Date()
        engine.start(profile: p)
        await waitUntil { self.engine.state == .idle }
        let elapsed = Date().timeIntervalSince(started)
        // 10 clics à 50 ms ≈ 0,5 s ; marge large pour les machines lentes.
        XCTAssertGreaterThan(elapsed, 0.45)
        XCTAssertLessThan(elapsed, 2.0)
    }
}
