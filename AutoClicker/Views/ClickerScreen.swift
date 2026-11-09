import SwiftUI

/// Écran principal : barre d'adresse, navigateur, points et bouton flottant.
struct ClickerScreen: View {
    @Environment(AppState.self) private var app
    @State private var addressDraft = ""
    @FocusState private var addressFocused: Bool

    var body: some View {
        @Bindable var app = app

        VStack(spacing: 0) {
            topBar
            ZStack {
                WebView(browser: app.browser)
                PointsOverlay()
                FloatingControl()
            }
            // Le navigateur et les points partagent exactement le même cadre :
            // c'est ce qui garantit que les coordonnées affichées = coordonnées cliquées.
            .ignoresSafeArea(edges: .bottom)
            .clipped()
        }
        .background(Color.black)
        .overlay(alignment: .top) {
            if app.isPlacingPoints { placementBanner.padding(.top, 64) }
        }
        .overlay(alignment: .bottom) {
            if let toast = app.toast {
                Text(toast)
                    .font(.subheadline.weight(.medium))
                    .padding(.horizontal, 16).padding(.vertical, 10)
                    .background(.ultraThinMaterial, in: Capsule())
                    .padding(.bottom, 40)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.spring(duration: 0.3), value: app.toast)
        .animation(.spring(duration: 0.3), value: app.isPlacingPoints)
        .sheet(isPresented: $app.showsProfiles) {
            ProfilesView()
                .environment(app)
        }
        .sheet(isPresented: $app.showsGuide) {
            GuideView()
                .environment(app)
        }
        .onChange(of: app.engine.isActive) { _, active in
            // Garde l'écran allumé pendant l'auto-clic.
            UIApplication.shared.isIdleTimerDisabled = active
        }
        .onChange(of: app.browser.addressText) { _, text in
            if !addressFocused { addressDraft = displayAddress(text) }
        }
        .onAppear { addressDraft = displayAddress(app.browser.addressText) }
    }

    // MARK: - Barre du haut

    private var topBar: some View {
        HStack(spacing: 8) {
            profileMenu

            HStack(spacing: 6) {
                Image(systemName: app.browser.isTestPage ? "checkmark.seal" : "globe")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                TextField("Adresse ou recherche", text: $addressDraft)
                    .focused($addressFocused)
                    .keyboardType(.webSearch)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .submitLabel(.go)
                    .onSubmit { app.browser.load(addressDraft) }
                    .font(.subheadline)
                if app.browser.isLoading {
                    ProgressView().controlSize(.mini)
                } else {
                    Button { app.browser.reload() } label: {
                        Image(systemName: "arrow.clockwise").font(.footnote)
                    }
                    .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 10)
            .frame(height: 38)
            .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 12, style: .continuous))

            Menu {
                Button { app.browser.goBack() } label: { Label("Précédent", systemImage: "chevron.backward") }
                    .disabled(!app.browser.canGoBack)
                Button { app.browser.goForward() } label: { Label("Suivant", systemImage: "chevron.forward") }
                    .disabled(!app.browser.canGoForward)
                Button { app.browser.load(TestPage.urlString) } label: {
                    Label("Page de test", systemImage: "checkmark.seal")
                }
                Divider()
                Toggle(isOn: Binding(get: { app.showsPoints }, set: { app.showsPoints = $0 })) {
                    Label("Afficher les points", systemImage: "scope")
                }
                Button { app.showsGuide = true } label: {
                    Label("Ce qui est possible sur iOS", systemImage: "info.circle")
                }
            } label: {
                Image(systemName: "ellipsis.circle")
                    .font(.title3)
                    .frame(width: 38, height: 38)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(.bar)
    }

    private var profileMenu: some View {
        Button { app.showsProfiles = true } label: {
            HStack(spacing: 6) {
                Circle()
                    .fill(statusColor)
                    .frame(width: 8, height: 8)
                Text(app.activeProfile?.name ?? "Profil")
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(1)
                Image(systemName: "chevron.down")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 10)
            .frame(height: 38)
            .frame(maxWidth: 150)
            .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private var statusColor: Color {
        switch app.engine.state {
        case .idle: return .gray
        case .countdown, .running: return Theme.running
        case .paused: return Theme.paused
        }
    }

    // MARK: - Mode placement

    private var placementBanner: some View {
        let isSequence = app.activeProfile?.mode == .sequence
        return HStack(spacing: 12) {
            Image(systemName: "hand.tap")
                .font(.title3)
                .foregroundStyle(Theme.accent)
            VStack(alignment: .leading, spacing: 2) {
                Text("Placement des points").font(.subheadline.weight(.semibold))
                Text(isSequence
                     ? "Touchez pour ajouter, glissez pour déplacer, maintenez pour supprimer."
                     : "Touchez l'endroit à cliquer ou glissez le point.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
            Button("OK") { app.isPlacingPoints = false }
                .buttonStyle(.borderedProminent)
                .foregroundStyle(.black)
        }
        .padding(12)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .padding(.horizontal, 12)
        .transition(.move(edge: .top).combined(with: .opacity))
    }

    private func displayAddress(_ text: String) -> String {
        text == TestPage.urlString ? "Page de test" : text
    }
}
