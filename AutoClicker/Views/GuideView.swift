import SwiftUI

/// Explique honnêtement ce que l'app peut faire, ce qu'iOS interdit,
/// et les solutions officielles d'Apple pour les autres apps.
struct GuideView: View {
    @Environment(AppState.self) private var app
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section {
                    item("checkmark.circle.fill", Theme.accent, "Auto-clic dans le navigateur intégré",
                         "Clics répétés, intervalle au milliseconde près, nombre de clics ou illimité, pause et arrêt.")
                    item("checkmark.circle.fill", Theme.accent, "Plusieurs points et séquences",
                         "Chaque point a son nombre d'appuis et son propre délai.")
                    item("checkmark.circle.fill", Theme.accent, "Profils sauvegardés",
                         "Création, modification, duplication, suppression, sauvegarde automatique.")
                    item("checkmark.circle.fill", Theme.accent, "Raccourcis et Siri",
                         "Action « Démarrer un profil » : ouvre l'app et lance l'auto-clic. Utilisable dans les automatisations.")
                } header: {
                    Text("Ce qui fonctionne")
                } footer: {
                    Text("Fonctionne sur les sites et jeux web (ex. jeux « clicker » en ligne). L'app reste au premier plan, écran allumé.")
                }

                Section {
                    item("xmark.octagon.fill", Theme.danger, "Cliquer dans les autres apps",
                         "iOS isole chaque app : aucune API publique ne permet de toucher l'écran à la place de l'utilisateur hors de sa propre app.")
                    item("xmark.octagon.fill", Theme.danger, "Bouton flottant au-dessus des autres apps",
                         "iOS n'autorise pas les fenêtres superposées (pas d'équivalent à Android). Le bouton flottant vit dans l'app.")
                    item("xmark.octagon.fill", Theme.danger, "Tourner en arrière-plan",
                         "iOS suspend une app quittée. L'auto-clic se met en pause et reprend quand vous revenez.")
                    item("xmark.octagon.fill", Theme.danger, "Créer une recette d'accessibilité automatiquement",
                         "Les réglages d'accessibilité ne sont pas modifiables par une app : il faut les configurer à la main.")
                } header: {
                    Text("Ce qu'Apple interdit aux apps")
                } footer: {
                    Text("Contourner ces règles exigerait un jailbreak ou des API privées : refusé par Apple et risqué pour l'iPhone. Cette app ne le fait pas.")
                }

                Section {
                    step(1, "Réglages → Accessibilité → Contrôle de sélection → Recettes → Créer une recette.")
                    step(2, "Attribuer une commande → Plein écran → Geste personnalisé.")
                    step(3, recipeInstruction)
                    step(4, "Recettes → Lancer la recette : choisissez la vôtre, puis activez le Contrôle de sélection.")
                    step(5, "Dans l'autre app, touchez l'écran : le geste enregistré est rejoué.")
                    step(6, "Ajoutez un raccourci : Accessibilité → Raccourci d'accessibilité → Contrôle de sélection (triple-clic du bouton latéral).")
                } header: {
                    Text("Dans les autres apps : Contrôle de sélection")
                } footer: {
                    Text("Outil officiel d'Apple. Limites : le geste est rejoué à chaque déclenchement, il ne boucle pas tout seul ; le rythme est celui que vous avez enregistré ; l'iPhone est plus difficile à utiliser tant que le mode est actif.")
                }

                Section {
                    step(1, "Réglages → Accessibilité → Toucher → AssistiveTouch → activer.")
                    step(2, "Créer un geste : tapotez rapidement à l'endroit voulu, puis enregistrez.")
                    step(3, "Bouton rond → Personnalisé → votre geste, puis touchez l'écran : tous les taps sont rejoués.")
                } header: {
                    Text("Dans les autres apps : AssistiveTouch")
                } footer: {
                    Text("Plus simple que le Contrôle de sélection, mais chaque lecture doit être relancée à la main.")
                }

                Section {
                    item("laptopcomputer", .secondary, "Recopie de l'iPhone (Mac)",
                         "Hors Union européenne seulement : Apple ne la propose pas en Belgique ni dans le reste de l'UE.")
                } header: {
                    Text("Autres pistes")
                }
            }
            .navigationTitle("Possible sur iOS ?")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("OK") { dismiss() }
                }
            }
        }
    }

    /// Consigne d'enregistrement adaptée au profil actif.
    private var recipeInstruction: String {
        guard let profile = app.activeProfile, !profile.points.isEmpty else {
            return "Tapotez les endroits à cliquer, dans l'ordre, puis Enregistrer."
        }
        switch profile.mode {
        case .single:
            return "Tapotez plusieurs fois au même endroit, à peu près toutes les \(ClickPlan.clamp(profile.intervalMs).formattedDuration), puis Enregistrer."
        case .sequence:
            let parts = profile.points.enumerated().map { index, point in
                "point \(index + 1) ×\(max(1, point.tapCount))"
            }
            return "Reproduisez votre séquence (\(parts.joined(separator: ", "))), puis Enregistrer."
        }
    }

    private func item(_ symbol: String, _ color: Color, _ title: String, _ detail: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: symbol)
                .foregroundStyle(color)
                .font(.body)
                .frame(width: 22)
            VStack(alignment: .leading, spacing: 3) {
                Text(title).font(.subheadline.weight(.semibold))
                Text(detail).font(.caption).foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 2)
    }

    private func step(_ number: Int, _ text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text("\(number)")
                .font(.caption.weight(.bold))
                .foregroundStyle(.black)
                .frame(width: 22, height: 22)
                .background(Theme.accent, in: Circle())
            Text(text).font(.subheadline)
        }
        .padding(.vertical, 2)
    }
}
