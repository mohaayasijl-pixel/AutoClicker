import CoreGraphics

/// Ce qui reçoit les clics. Dans l'app, c'est le navigateur intégré ;
/// dans les tests, une cible factice.
@MainActor
protocol ClickTarget: AnyObject {
    /// Simule un appui au point normalisé (0…1). Renvoie false si rien n'a été touché.
    func performTap(at point: CGPoint, sendTouchEvents: Bool) async -> Bool
}
