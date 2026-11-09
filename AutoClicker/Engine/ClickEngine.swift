import Foundation
import CoreGraphics
import Observation

/// Exécute un profil : démarrer, mettre en pause, reprendre, arrêter.
@MainActor
@Observable
final class ClickEngine {
    enum State: Equatable {
        case idle
        case countdown(seconds: Int)
        case running
        case paused
    }

    struct LastTap: Equatable {
        let serial: Int
        let pointIndex: Int
        let point: CGPoint
        let hit: Bool
    }

    private(set) var state: State = .idle
    private(set) var tapsPerformed = 0
    private(set) var missedTaps = 0
    private(set) var cyclesCompleted = 0
    private(set) var totalCycles: Int?
    private(set) var lastTap: LastTap?
    private(set) var runningProfileID: UUID?

    @ObservationIgnored weak var target: ClickTarget?
    @ObservationIgnored private var task: Task<Void, Never>?
    @ObservationIgnored private var runToken = UUID()
    @ObservationIgnored private var serial = 0

    var isActive: Bool { state != .idle }
    var isRunning: Bool { state == .running }

    // MARK: - Commandes

    /// Démarre un profil. Renvoie false si le profil n'a aucun point ou s'il n'y a pas de cible.
    @discardableResult
    func start(profile: ClickProfile) -> Bool {
        stop()
        let steps = ClickPlan.cycle(for: profile)
        guard !steps.isEmpty, target != nil else { return false }

        tapsPerformed = 0
        missedTaps = 0
        cyclesCompleted = 0
        totalCycles = ClickPlan.totalCycles(for: profile)
        runningProfileID = profile.id

        let token = UUID()
        runToken = token
        let cycles = totalCycles
        let startDelay = max(0, profile.startDelayMs)
        let touch = profile.sendTouchEvents
        task = Task { [weak self] in
            await self?.run(token: token, steps: steps, totalCycles: cycles,
                            startDelayMs: startDelay, sendTouchEvents: touch)
        }
        return true
    }

    func pause() {
        if state == .running { state = .paused }
    }

    func resume() {
        if state == .paused { state = .running }
    }

    func stop() {
        task?.cancel()
        task = nil
        runToken = UUID()
        state = .idle
        runningProfileID = nil
    }

    // MARK: - Boucle

    private func run(token: UUID, steps: [ClickStep], totalCycles: Int?,
                     startDelayMs: Int, sendTouchEvents: Bool) async {
        do {
            var remaining = startDelayMs
            while remaining > 0 {
                guard token == runToken else { return }
                state = .countdown(seconds: Int((Double(remaining) / 1000).rounded(.up)))
                let chunk = min(remaining, 100)
                try await Task.sleep(nanoseconds: UInt64(chunk) * 1_000_000)
                remaining -= chunk
            }
            guard token == runToken else { return }
            state = .running

            let clock = ContinuousClock()
            var cycle = 0
            while totalCycles.map({ cycle < $0 }) ?? true {
                for step in steps {
                    try await waitWhilePaused(token: token)
                    try Task.checkCancellation()
                    guard token == runToken else { return }

                    let started = clock.now
                    let hit = await target?.performTap(at: step.point,
                                                       sendTouchEvents: sendTouchEvents) ?? false
                    guard token == runToken else { return }
                    if hit { tapsPerformed += 1 } else { missedTaps += 1 }
                    serial += 1
                    lastTap = LastTap(serial: serial, pointIndex: step.pointIndex,
                                      point: step.point, hit: hit)

                    // On retire le temps déjà passé à cliquer pour garder un rythme régulier.
                    let deadline = started.advanced(by: .milliseconds(step.delayAfterMs))
                    try await Task.sleep(until: deadline, clock: clock)
                }
                cycle += 1
                cyclesCompleted = cycle
            }
            if token == runToken {
                state = .idle
                task = nil
                runningProfileID = nil
            }
        } catch {
            // Annulé par stop() : rien à faire.
        }
    }

    private func waitWhilePaused(token: UUID) async throws {
        while state == .paused && token == runToken {
            try await Task.sleep(nanoseconds: 50_000_000)
        }
    }
}
