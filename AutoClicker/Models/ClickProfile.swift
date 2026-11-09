import Foundation

enum ClickMode: String, Codable, CaseIterable, Identifiable {
    /// Un seul point, cliqué à intervalle régulier.
    case single
    /// Plusieurs points cliqués dans l'ordre, avec un délai propre à chacun.
    case sequence

    var id: String { rawValue }

    var label: String {
        switch self {
        case .single: return "Point unique"
        case .sequence: return "Séquence"
        }
    }
}

/// Une configuration complète d'auto-clic, enregistrable et rechargeable.
struct ClickProfile: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var name: String
    var mode: ClickMode = .single
    /// Intervalle entre deux clics en mode point unique, en ms.
    var intervalMs: Int = 200
    /// Répéter sans fin (jusqu'à l'arrêt manuel).
    var isInfinite: Bool = true
    /// Nombre de répétitions si non illimité : clics en mode point unique,
    /// cycles complets en mode séquence.
    var repeatCount: Int = 100
    /// Compte à rebours avant le premier clic, en ms.
    var startDelayMs: Int = 0
    /// Envoie aussi des événements tactiles (touchstart/touchend).
    /// Utile pour les jeux web qui n'écoutent que le tactile.
    var sendTouchEvents: Bool = false
    /// Page ouverte quand le profil est chargé.
    var targetURL: String = TestPage.urlString
    var points: [ClickPoint] = []
    var updatedAt: Date = Date()

    /// Délai minimal entre deux actions, pour ne pas bloquer la page web.
    static let minimumIntervalMs = 20

    static func makeDefault(name: String = "Nouveau profil") -> ClickProfile {
        ClickProfile(name: name, points: [ClickPoint(name: "Point 1", x: 0.5, y: 0.5)])
    }

    /// Profils créés au premier lancement, réglés sur la page de test intégrée.
    static func starterProfiles() -> [ClickProfile] {
        let single = ClickProfile(
            name: "Test – point unique",
            mode: .single,
            intervalMs: 100,
            points: [ClickPoint(name: "Gros bouton", x: TestPage.mainButton.x, y: TestPage.mainButton.y)]
        )
        let sequencePoints = TestPage.targets.enumerated().map { index, target in
            ClickPoint(name: "Cible \(index + 1)", x: target.x, y: target.y,
                       tapCount: index + 1, tapIntervalMs: 80, delayAfterMs: 300)
        }
        let sequence = ClickProfile(
            name: "Test – séquence",
            mode: .sequence,
            isInfinite: false,
            repeatCount: 10,
            startDelayMs: 1000,
            points: sequencePoints
        )
        return [single, sequence]
    }
}
