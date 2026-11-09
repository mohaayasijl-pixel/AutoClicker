import SwiftUI

/// Réglages d'un profil. Chaque changement est enregistré tout de suite.
struct ProfileEditorView: View {
    @Environment(AppState.self) private var app
    @Environment(\.dismiss) private var dismiss
    let profileID: UUID
    @State private var confirmDelete = false

    var body: some View {
        if let binding = profileBinding {
            form(binding)
        } else {
            ContentUnavailableView("Profil introuvable", systemImage: "questionmark.folder")
        }
    }

    private var profileBinding: Binding<ClickProfile>? {
        guard app.store.profile(with: profileID) != nil else { return nil }
        let store = app.store
        let id = profileID
        return Binding(
            get: { store.profile(with: id) ?? .makeDefault() },
            set: { store.update($0) }
        )
    }

    // MARK: - Formulaire

    private func form(_ profile: Binding<ClickProfile>) -> some View {
        let value = profile.wrappedValue
        return Form {
            Section("Général") {
                TextField("Nom du profil", text: profile.name)
                    .onSubmit { app.profilesDidChange() }
                Picker("Mode", selection: profile.mode) {
                    ForEach(ClickMode.allCases) { mode in
                        Text(mode.label).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
            }

            Section {
                if value.mode == .single {
                    NumberField(title: "Intervalle", value: profile.intervalMs,
                                range: ClickProfile.minimumIntervalMs...600_000, step: 10)
                }
                Toggle("Illimité", isOn: profile.isInfinite)
                if !value.isInfinite {
                    NumberField(title: value.mode == .single ? "Nombre de clics" : "Nombre de cycles",
                                value: profile.repeatCount, unit: "×", range: 1...1_000_000, step: 1)
                }
                NumberField(title: "Compte à rebours", value: profile.startDelayMs,
                            range: 0...60_000, step: 500)
            } header: {
                Text("Rythme")
            } footer: {
                Text(rhythmSummary(value))
            }

            Section {
                if value.points.isEmpty {
                    Text("Aucun point. Ajoutez-en un ou placez-les à l'écran.")
                        .foregroundStyle(.secondary)
                }
                ForEach(Array(profile.points.enumerated()), id: \.element.id) { index, point in
                    pointEditor(point, index: index, mode: value.mode)
                }
                .onDelete { offsets in profile.wrappedValue.points.remove(atOffsets: offsets) }
                .onMove { source, destination in profile.wrappedValue.points.move(fromOffsets: source, toOffset: destination) }

                Button {
                    app.beginPlacingPoints(for: profileID)
                } label: {
                    Label("Placer les points à l'écran", systemImage: "hand.tap")
                }
                if value.mode == .sequence || value.points.isEmpty {
                    Button {
                        var updated = profile.wrappedValue
                        updated.points.append(ClickPoint(name: "Point \(updated.points.count + 1)", x: 0.5, y: 0.5))
                        profile.wrappedValue = updated
                    } label: {
                        Label("Ajouter un point au centre", systemImage: "plus.circle")
                    }
                }
            } header: {
                Text(value.mode == .single ? "Point" : "Séquence de points")
            } footer: {
                if value.mode == .single && value.points.count > 1 {
                    Text("En mode point unique, seul le premier point est utilisé.")
                }
            }

            Section {
                TextField("Adresse de la page", text: profile.targetURL)
                    .keyboardType(.URL)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                Button {
                    profile.wrappedValue.targetURL = app.browser.addressText
                } label: {
                    Label("Utiliser la page affichée", systemImage: "arrow.down.doc")
                }
                Button {
                    profile.wrappedValue.targetURL = TestPage.urlString
                } label: {
                    Label("Utiliser la page de test", systemImage: "checkmark.seal")
                }
                Toggle("Événements tactiles", isOn: profile.sendTouchEvents)
            } header: {
                Text("Page cible")
            } footer: {
                Text("La page s'ouvre quand le profil est chargé. Activez les événements tactiles si un jeu web ne réagit pas aux clics normaux.")
            }

            Section {
                Button {
                    app.activate(profileID) { _ in app.startActiveProfile() }
                    app.showsProfiles = false
                } label: {
                    Label("Charger et démarrer", systemImage: "play.fill")
                }
                .disabled(value.points.isEmpty)

                Button(role: .destructive) {
                    confirmDelete = true
                } label: {
                    Label("Supprimer le profil", systemImage: "trash")
                }
                .disabled(app.store.profiles.count <= 1)
            }
        }
        .navigationTitle(value.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) { EditButton() }
        }
        .onDisappear { app.profilesDidChange() }
        .confirmationDialog("Supprimer « \(value.name) » ?", isPresented: $confirmDelete, titleVisibility: .visible) {
            Button("Supprimer", role: .destructive) {
                if app.engine.runningProfileID == profileID { app.stop() }
                app.store.delete(profileID)
                app.profilesDidChange()
                dismiss()
            }
        }
    }

    @ViewBuilder
    private func pointEditor(_ point: Binding<ClickPoint>, index: Int, mode: ClickMode) -> some View {
        let p = point.wrappedValue
        DisclosureGroup {
            TextField("Nom", text: point.name)
            LabeledContent("Position") {
                Text("\(Int((p.x * 100).rounded())) % · \(Int((p.y * 100).rounded())) %")
                    .monospacedDigit()
            }
            if mode == .sequence {
                NumberField(title: "Appuis", value: point.tapCount, unit: "×", range: 1...1000, step: 1)
                if p.tapCount > 1 {
                    NumberField(title: "Entre appuis", value: point.tapIntervalMs,
                                range: ClickProfile.minimumIntervalMs...60_000, step: 10)
                }
                NumberField(title: "Délai après", value: point.delayAfterMs,
                            range: ClickProfile.minimumIntervalMs...600_000, step: 50)
            }
        } label: {
            HStack(spacing: 10) {
                Text("\(index + 1)")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.black)
                    .frame(width: 22, height: 22)
                    .background(Theme.pointColor(index), in: Circle())
                VStack(alignment: .leading, spacing: 2) {
                    Text(p.name)
                    if mode == .sequence {
                        Text("\(p.tapCount)× · puis \(ClickPlan.clamp(p.delayAfterMs).formattedDuration)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }

    private func rhythmSummary(_ profile: ClickProfile) -> String {
        let cps = ClickPlan.clicksPerSecond(for: profile)
        let perCycle = ClickPlan.tapsPerCycle(for: profile)
        let cpsText = cps.formatted(.number.precision(.fractionLength(0...1)))
        var text = "≈ \(cpsText) clics par seconde"
        if profile.mode == .sequence {
            text += " · \(perCycle) appui\(perCycle > 1 ? "s" : "") par cycle de \(ClickPlan.cycleDurationMs(for: profile).formattedDuration)"
        }
        if !profile.isInfinite {
            let total = profile.mode == .single ? profile.repeatCount : profile.repeatCount * perCycle
            text += " · \(total) clics au total"
        }
        text += ". Le rythme réel peut être un peu plus lent selon la page."
        return text
    }
}
