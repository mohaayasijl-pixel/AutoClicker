import AppIntents
import Foundation

// Intégration à l'app Raccourcis et à Siri.
// Un raccourci peut lancer un profil dans l'app, mais iOS ne lui permet pas
// de toucher l'écran d'une autre app : il n'existe pas d'action « Toucher ».

struct ProfileEntity: AppEntity {
    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Profil Auto Clicker"
    static var defaultQuery = ProfileEntityQuery()

    var id: UUID
    var name: String

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(name)")
    }

    init(id: UUID, name: String) {
        self.id = id
        self.name = name
    }

    init(_ profile: ClickProfile) {
        self.init(id: profile.id, name: profile.name)
    }
}

struct ProfileEntityQuery: EntityQuery {
    @MainActor
    func entities(for identifiers: [ProfileEntity.ID]) async throws -> [ProfileEntity] {
        AppState.shared.store.profiles
            .filter { identifiers.contains($0.id) }
            .map(ProfileEntity.init)
    }

    @MainActor
    func suggestedEntities() async throws -> [ProfileEntity] {
        AppState.shared.store.profiles.map(ProfileEntity.init)
    }
}

struct StartProfileIntent: AppIntent {
    static var title: LocalizedStringResource = "Démarrer un profil"
    static var description = IntentDescription("Ouvre Auto Clicker, charge le profil et lance l'auto-clic.")
    static var openAppWhenRun: Bool = true

    @Parameter(title: "Profil")
    var profile: ProfileEntity

    @MainActor
    func perform() async throws -> some IntentResult {
        AppState.shared.startFromShortcut(profileID: profile.id)
        return .result()
    }
}

struct StopClickerIntent: AppIntent {
    static var title: LocalizedStringResource = "Arrêter l'auto-clic"
    static var description = IntentDescription("Arrête l'auto-clic en cours.")

    @MainActor
    func perform() async throws -> some IntentResult {
        AppState.shared.stop()
        return .result()
    }
}

struct AutoClickerShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: StartProfileIntent(),
            phrases: [
                "Démarrer \(\.$profile) avec \(.applicationName)",
                "Lancer \(.applicationName)"
            ],
            shortTitle: "Démarrer un profil",
            systemImageName: "play.circle"
        )
        AppShortcut(
            intent: StopClickerIntent(),
            phrases: ["Arrêter \(.applicationName)"],
            shortTitle: "Arrêter",
            systemImageName: "stop.circle"
        )
    }
}
