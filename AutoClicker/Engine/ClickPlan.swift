import Foundation
import CoreGraphics

/// Une action élémentaire : un appui à un point, puis une attente.
struct ClickStep: Equatable {
    let pointIndex: Int
    let point: CGPoint
    let delayAfterMs: Int
}

/// Transforme un profil en liste d'actions pour un cycle.
/// Logique pure, sans interface : facile à tester.
enum ClickPlan {
    static func cycle(for profile: ClickProfile) -> [ClickStep] {
        switch profile.mode {
        case .single:
            guard let point = profile.points.first else { return [] }
            return [ClickStep(pointIndex: 0, point: point.normalized,
                              delayAfterMs: clamp(profile.intervalMs))]
        case .sequence:
            var steps: [ClickStep] = []
            for (index, point) in profile.points.enumerated() {
                let taps = max(1, point.tapCount)
                for tap in 0..<taps {
                    let isLastTap = tap == taps - 1
                    let delay = isLastTap ? point.delayAfterMs : point.tapIntervalMs
                    steps.append(ClickStep(pointIndex: index, point: point.normalized,
                                           delayAfterMs: clamp(delay)))
                }
            }
            return steps
        }
    }

    /// Nombre de cycles à exécuter, ou nil pour illimité.
    static func totalCycles(for profile: ClickProfile) -> Int? {
        profile.isInfinite ? nil : max(1, profile.repeatCount)
    }

    static func tapsPerCycle(for profile: ClickProfile) -> Int {
        cycle(for: profile).count
    }

    /// Durée d'un cycle en ms (hors temps d'exécution des clics).
    static func cycleDurationMs(for profile: ClickProfile) -> Int {
        cycle(for: profile).reduce(0) { $0 + $1.delayAfterMs }
    }

    /// Clics par seconde théoriques.
    static func clicksPerSecond(for profile: ClickProfile) -> Double {
        let duration = cycleDurationMs(for: profile)
        guard duration > 0 else { return 0 }
        return Double(tapsPerCycle(for: profile)) * 1000 / Double(duration)
    }

    static func clamp(_ ms: Int) -> Int {
        max(ClickProfile.minimumIntervalMs, ms)
    }
}
