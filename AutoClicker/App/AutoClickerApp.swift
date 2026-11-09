import SwiftUI

@main
struct AutoClickerApp: App {
    @State private var appState = AppState.shared
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            ClickerScreen()
                .environment(appState)
                .preferredColorScheme(.dark)
                .tint(Theme.accent)
        }
        .onChange(of: scenePhase) { _, phase in
            // iOS suspend l'app en arrière-plan : on met en pause proprement.
            if phase != .active { appState.engine.pause() }
        }
    }
}
