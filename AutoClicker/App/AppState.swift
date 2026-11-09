import Foundation
import Observation
import AppIntents

/// État partagé de l'application : profils, moteur d'auto-clic et navigateur.
@MainActor
@Observable
final class AppState {
    static let shared = AppState()

    let store: ProfileStore
    let engine: ClickEngine
    let browser: BrowserController

    /// Mode placement : toucher l'écran ajoute / déplace des points.
    var isPlacingPoints = false
    var showsPoints = true
    var showsProfiles = false
    var showsGuide = false
    /// Message bref affiché en bas de l'écran.
    var toast: String?

    init(store: ProfileStore = ProfileStore(),
         engine: ClickEngine = ClickEngine(),
         browser: BrowserController = BrowserController()) {
        self.store = store
        self.engine = engine
        self.browser = browser
        engine.target = browser
        browser.load(store.activeProfile?.targetURL ?? TestPage.urlString)
    }

    var activeProfile: ClickProfile? { store.activeProfile }

    // MARK: - Commandes du bouton flottant

    /// Démarrer → pause → reprise.
    func togglePrimary() {
        switch engine.state {
        case .idle:
            startActiveProfile()
        case .running:
            engine.pause()
        case .paused:
            engine.resume()
        case .countdown:
            engine.stop()
        }
    }

    func startActiveProfile() {
        guard let profile = activeProfile else { return }
        isPlacingPoints = false
        if profile.points.isEmpty {
            show("Ajoutez au moins un point dans ce profil")
            return
        }
        if !engine.start(profile: profile) {
            show("Impossible de démarrer")
        }
    }

    func stop() {
        engine.stop()
    }

    // MARK: - Profils

    /// Charge un profil : le rend actif et ouvre sa page si elle est différente.
    func activate(_ id: UUID, openPage: Bool = true, completion: ((Bool) -> Void)? = nil) {
        engine.stop()
        store.setActive(id)
        guard openPage, let profile = store.profile(with: id) else {
            completion?(true)
            return
        }
        if isCurrentPage(profile.targetURL) {
            completion?(true)
        } else {
            browser.load(profile.targetURL, completion: completion)
        }
    }

    func beginPlacingPoints(for id: UUID) {
        activate(id)
        showsProfiles = false
        engine.stop()
        isPlacingPoints = true
    }

    /// Appelé par le raccourci « Démarrer un profil ».
    func startFromShortcut(profileID: UUID) {
        showsProfiles = false
        showsGuide = false
        activate(profileID) { [weak self] _ in
            self?.startActiveProfile()
        }
    }

    func profilesDidChange() {
        AutoClickerShortcuts.updateAppShortcutParameters()
    }

    func show(_ message: String) {
        toast = message
        let current = message
        Task { [weak self] in
            try? await Task.sleep(nanoseconds: 2_500_000_000)
            if self?.toast == current { self?.toast = nil }
        }
    }

    private func isCurrentPage(_ target: String) -> Bool {
        let trimmed = target.trimmingCharacters(in: .whitespacesAndNewlines)
        if TestPage.matches(trimmed) {
            return browser.isTestPage
        }
        guard let url = BrowserController.url(from: trimmed) else { return false }
        return browser.addressText == url.absoluteString
    }
}
