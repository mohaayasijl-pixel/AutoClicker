import Foundation
import CoreGraphics

/// Un point de clic. La position est normalisée (0…1) par rapport à la zone
/// de clic, pour rester valable quelle que soit la taille de l'écran.
struct ClickPoint: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var name: String
    /// Position horizontale normalisée (0 = bord gauche, 1 = bord droit).
    var x: Double
    /// Position verticale normalisée (0 = haut, 1 = bas).
    var y: Double
    /// Nombre d'appuis consécutifs sur ce point (mode séquence).
    var tapCount: Int = 1
    /// Délai entre deux appuis consécutifs sur ce même point, en ms.
    var tapIntervalMs: Int = 100
    /// Délai après ce point, avant de passer au suivant, en ms.
    var delayAfterMs: Int = 500

    var normalized: CGPoint { CGPoint(x: x, y: y) }

    /// Ramène la position dans les bornes 0…1.
    mutating func clampPosition() {
        x = min(max(x, 0), 1)
        y = min(max(y, 0), 1)
    }
}
