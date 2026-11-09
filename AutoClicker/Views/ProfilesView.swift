import SwiftUI

/// Liste des profils : charger, créer, dupliquer, modifier, supprimer.
struct ProfilesView: View {
    @Environment(AppState.self) private var app
    @Environment(\.dismiss) private var dismiss
    @State private var path: [UUID] = []

    var body: some View {
        NavigationStack(path: $path) {
            List {
                Section {
                    ForEach(app.store.profiles) { profile in
                        row(profile)
                    }
                    .onMove { app.store.move(fromOffsets: $0, toOffset: $1) }
                } footer: {
                    Text("Touchez un profil pour le charger. Les modifications sont enregistrées automatiquement.")
                }
            }
            .navigationTitle("Profils")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(for: UUID.self) { id in
                ProfileEditorView(profileID: id)
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    EditButton()
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        let profile = app.store.add()
                        app.profilesDidChange()
                        path.append(profile.id)
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("Nouveau profil")
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("OK") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    private func row(_ profile: ClickProfile) -> some View {
        let isActive = profile.id == app.store.activeProfileID
        return HStack(spacing: 12) {
            Button {
                app.activate(profile.id)
                dismiss()
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: isActive ? "checkmark.circle.fill" : "circle")
                        .font(.title3)
                        .foregroundStyle(isActive ? Theme.accent : Color.secondary)
                    VStack(alignment: .leading, spacing: 3) {
                        Text(profile.name)
                            .font(.body.weight(isActive ? .semibold : .regular))
                            .foregroundStyle(.primary)
                        Text(summary(profile))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                    Spacer(minLength: 0)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Button {
                path.append(profile.id)
            } label: {
                Image(systemName: "slider.horizontal.3")
                    .foregroundStyle(Theme.accent)
                    .frame(width: 36, height: 36)
            }
            .buttonStyle(.borderless)
            .accessibilityLabel("Modifier \(profile.name)")
        }
        .swipeActions(edge: .trailing) {
            if app.store.profiles.count > 1 {
                Button(role: .destructive) {
                    if app.engine.runningProfileID == profile.id { app.stop() }
                    app.store.delete(profile.id)
                    app.profilesDidChange()
                } label: {
                    Label("Supprimer", systemImage: "trash")
                }
            }
            Button {
                app.store.duplicate(profile.id)
                app.profilesDidChange()
            } label: {
                Label("Dupliquer", systemImage: "plus.square.on.square")
            }
            .tint(.indigo)
        }
        .contextMenu {
            Button { app.activate(profile.id); dismiss() } label: { Label("Charger", systemImage: "play") }
            Button { path.append(profile.id) } label: { Label("Modifier", systemImage: "slider.horizontal.3") }
            Button {
                app.store.duplicate(profile.id)
                app.profilesDidChange()
            } label: { Label("Dupliquer", systemImage: "plus.square.on.square") }
            if app.store.profiles.count > 1 {
                Button(role: .destructive) {
                    if app.engine.runningProfileID == profile.id { app.stop() }
                    app.store.delete(profile.id)
                    app.profilesDidChange()
                } label: { Label("Supprimer", systemImage: "trash") }
            }
        }
    }

    private func summary(_ profile: ClickProfile) -> String {
        let repeatText = profile.isInfinite ? "illimité" : "×\(profile.repeatCount)"
        switch profile.mode {
        case .single:
            return "Point unique · toutes les \(ClickPlan.clamp(profile.intervalMs).formattedDuration) · \(repeatText)"
        case .sequence:
            let count = profile.points.count
            return "Séquence · \(count) point\(count > 1 ? "s" : "") · \(repeatText)"
        }
    }
}
