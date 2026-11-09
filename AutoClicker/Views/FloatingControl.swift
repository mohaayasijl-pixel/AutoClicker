import SwiftUI

/// Bouton flottant déplaçable.
/// - Toucher : démarrer / pause / reprendre.
/// - Maintenir : ouvrir les actions (arrêter, placer les points, profils).
/// - Glisser : déplacer ; il se cale sur le bord le plus proche.
struct FloatingControl: View {
    @Environment(AppState.self) private var app
    @AppStorage("floating.side") private var side: Double = 1      // 0 = gauche, 1 = droite
    @AppStorage("floating.y") private var relativeY: Double = 0.62
    @State private var dragOffset: CGSize = .zero
    @State private var expanded = false

    private let diameter: CGFloat = 62
    private let margin: CGFloat = 14

    var body: some View {
        GeometryReader { geo in
            let base = basePosition(in: geo.size)
            let opensUpward = relativeY > 0.4

            mainButton
                .overlay(alignment: opensUpward ? .bottom : .top) {
                    if expanded {
                        actions
                            .fixedSize()
                            .padding(opensUpward ? .bottom : .top, diameter + 12)
                            .transition(.scale(scale: 0.6, anchor: opensUpward ? .bottom : .top)
                                .combined(with: .opacity))
                    }
                }
                .overlay(alignment: side > 0.5 ? .trailing : .leading) {
                    if expanded { statusPanel.fixedSize().padding(side > 0.5 ? .trailing : .leading, diameter + 10) }
                }
                .simultaneousGesture(dragGesture(in: geo.size))
                .position(x: base.x + dragOffset.width, y: base.y + dragOffset.height)
                .animation(.spring(duration: 0.3), value: expanded)
        }
        .opacity(app.isPlacingPoints ? 0.35 : 1)
    }

    // MARK: - Bouton principal

    private var mainButton: some View {
        ZStack {
            Circle()
                .fill(fillColor)
            Circle()
                .strokeBorder(Color.white.opacity(0.18), lineWidth: 1)
            mainContent
                .foregroundStyle(app.engine.state == .running ? Theme.running : Color.black)
        }
        .frame(width: diameter, height: diameter)
        .shadow(color: .black.opacity(0.45), radius: 10, y: 4)
        .overlay(alignment: .topTrailing) { counterBadge }
        .contentShape(Circle())
        .onTapGesture { app.togglePrimary() }
        .onLongPressGesture(minimumDuration: 0.35) { expanded.toggle() }
        .sensoryFeedback(.impact(weight: .medium), trigger: app.engine.state)
        .sensoryFeedback(.selection, trigger: expanded)
        .accessibilityLabel(accessibilityTitle)
        .accessibilityHint("Maintenir pour plus d'actions")
    }

    @ViewBuilder
    private var mainContent: some View {
        switch app.engine.state {
        case .idle:
            Image(systemName: "play.fill").font(.system(size: 24, weight: .bold))
        case .running:
            Image(systemName: "pause.fill").font(.system(size: 22, weight: .bold))
        case .paused:
            Image(systemName: "play.fill").font(.system(size: 24, weight: .bold))
        case .countdown(let seconds):
            Text("\(seconds)").font(.system(size: 26, weight: .heavy, design: .rounded))
        }
    }

    private var fillColor: Color {
        switch app.engine.state {
        case .idle: return Theme.accent
        case .running: return Color(white: 0.12)
        case .paused: return Theme.paused
        case .countdown: return Color.white
        }
    }

    @ViewBuilder
    private var counterBadge: some View {
        if app.engine.isActive || app.engine.tapsPerformed > 0 {
            Text(app.engine.tapsPerformed.formatted(.number.notation(.compactName)))
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .monospacedDigit()
                .padding(.horizontal, 6).padding(.vertical, 3)
                .background(Color.white, in: Capsule())
                .foregroundStyle(.black)
                .offset(x: 6, y: -4)
        }
    }

    // MARK: - Actions

    private var actions: some View {
        VStack(spacing: 10) {
            actionButton("stop.fill", label: "Arrêter", tint: Theme.danger, disabled: !app.engine.isActive) {
                app.stop()
            }
            actionButton("hand.tap.fill", label: "Placer les points", tint: Theme.marker) {
                if let id = app.activeProfile?.id { app.beginPlacingPoints(for: id) }
                expanded = false
            }
            actionButton("rectangle.stack.fill", label: "Profils", tint: .white) {
                app.showsProfiles = true
                expanded = false
            }
            actionButton(app.showsPoints ? "eye.fill" : "eye.slash.fill",
                         label: app.showsPoints ? "Masquer les points" : "Afficher les points", tint: .white) {
                app.showsPoints.toggle()
            }
        }
    }

    private func actionButton(_ symbol: String, label: String, tint: Color, disabled: Bool = false,
                              action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(tint)
                .frame(width: 46, height: 46)
                .background(.ultraThinMaterial, in: Circle())
                .overlay(Circle().strokeBorder(Color.white.opacity(0.12)))
        }
        .buttonStyle(.plain)
        .disabled(disabled)
        .opacity(disabled ? 0.4 : 1)
        .accessibilityLabel(label)
    }

    private var statusPanel: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(app.activeProfile?.name ?? "Aucun profil")
                .font(.caption.weight(.semibold))
                .lineLimit(1)
            Text(statusLine)
                .font(.caption2)
                .monospacedDigit()
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 12).padding(.vertical, 8)
        .frame(maxWidth: 190, alignment: .leading)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private var statusLine: String {
        let engine = app.engine
        var parts = ["\(engine.tapsPerformed) clics"]
        if let total = engine.totalCycles, app.activeProfile?.mode == .sequence {
            parts.append("cycle \(min(engine.cyclesCompleted + 1, total))/\(total)")
        }
        if engine.missedTaps > 0 { parts.append("\(engine.missedTaps) ratés") }
        return parts.joined(separator: " · ")
    }

    private var accessibilityTitle: String {
        switch app.engine.state {
        case .idle: return "Démarrer l'auto-clic"
        case .running: return "Mettre en pause"
        case .paused: return "Reprendre"
        case .countdown: return "Annuler le compte à rebours"
        }
    }

    // MARK: - Déplacement

    private func basePosition(in size: CGSize) -> CGPoint {
        let half = diameter / 2
        let x = side > 0.5 ? size.width - margin - half : margin + half
        let minY = margin + half
        let maxY = max(minY, size.height - margin - half - 24)
        let y = min(max(relativeY * size.height, minY), maxY)
        return CGPoint(x: x, y: y)
    }

    private func dragGesture(in size: CGSize) -> some Gesture {
        DragGesture(minimumDistance: 8)
            .onChanged { value in
                dragOffset = value.translation
            }
            .onEnded { value in
                let base = basePosition(in: size)
                let final = CGPoint(x: base.x + value.translation.width, y: base.y + value.translation.height)
                withAnimation(.spring(duration: 0.35, bounce: 0.25)) {
                    side = final.x < size.width / 2 ? 0 : 1
                    relativeY = size.height > 0 ? Double(final.y / size.height) : relativeY
                    dragOffset = .zero
                }
            }
    }
}
