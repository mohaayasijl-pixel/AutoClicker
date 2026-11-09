import SwiftUI

/// Calque au-dessus du navigateur : affiche les points, permet de les placer
/// et montre un retour visuel à chaque clic.
struct PointsOverlay: View {
    @Environment(AppState.self) private var app
    /// Positions en cours de glissement (enregistrées seulement au relâchement).
    @State private var dragPositions: [UUID: CGPoint] = [:]

    var body: some View {
        GeometryReader { geo in
            let size = geo.size
            ZStack {
                if app.isPlacingPoints {
                    Color.black.opacity(0.28)
                        .contentShape(Rectangle())
                        .gesture(
                            SpatialTapGesture()
                                .onEnded { value in placePoint(at: value.location, in: size) }
                        )
                }

                if let profile = app.activeProfile, app.showsPoints || app.isPlacingPoints {
                    ForEach(Array(profile.points.enumerated()), id: \.element.id) { index, point in
                        if profile.mode == .sequence || index == 0 {
                            marker(point: point, index: index, mode: profile.mode, size: size)
                        }
                    }
                }

                if let tap = app.engine.lastTap, app.engine.isActive {
                    TapRipple(hit: tap.hit)
                        .position(x: tap.point.x * size.width, y: tap.point.y * size.height)
                        .id(tap.serial)
                }
            }
            .coordinateSpace(.named("points"))
        }
        .allowsHitTesting(app.isPlacingPoints)
    }

    // MARK: - Marqueur

    @ViewBuilder
    private func marker(point: ClickPoint, index: Int, mode: ClickMode, size: CGSize) -> some View {
        let normalized = dragPositions[point.id] ?? point.normalized
        let isCurrent = app.engine.isActive && app.engine.lastTap?.pointIndex == index
        let color = Theme.pointColor(index)
        let placing = app.isPlacingPoints

        ZStack {
            Circle()
                .fill(color.opacity(placing ? 0.28 : 0.18))
            Circle()
                .strokeBorder(color, lineWidth: isCurrent ? 3 : 2)
            if mode == .sequence {
                Text("\(index + 1)")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .offset(y: -11)
            }
            Circle()
                .fill(color)
                .frame(width: 5, height: 5)
        }
        .frame(width: placing ? 46 : 38, height: placing ? 46 : 38)
        .scaleEffect(isCurrent ? 1.12 : 1)
        .opacity(placing || app.engine.isActive ? 1 : 0.75)
        .shadow(color: .black.opacity(0.4), radius: 4, y: 2)
        .animation(.easeOut(duration: 0.12), value: isCurrent)
        .contentShape(Circle().inset(by: -8))
        .gesture(
            DragGesture(minimumDistance: 2, coordinateSpace: .named("points"))
                .onChanged { value in
                    dragPositions[point.id] = clampedNormalized(value.location, in: size)
                }
                .onEnded { value in
                    movePoint(point.id, to: clampedNormalized(value.location, in: size))
                    dragPositions[point.id] = nil
                }
        )
        .contextMenu {
            if mode == .sequence {
                Button(role: .destructive) { deletePoint(point.id) } label: {
                    Label("Supprimer \(point.name)", systemImage: "trash")
                }
            }
        }
        .position(x: normalized.x * size.width, y: normalized.y * size.height)
    }

    // MARK: - Modifications

    private func clampedNormalized(_ location: CGPoint, in size: CGSize) -> CGPoint {
        guard size.width > 0, size.height > 0 else { return .zero }
        return CGPoint(x: min(max(location.x / size.width, 0), 1),
                       y: min(max(location.y / size.height, 0), 1))
    }

    private func placePoint(at location: CGPoint, in size: CGSize) {
        guard var profile = app.activeProfile else { return }
        let p = clampedNormalized(location, in: size)
        if profile.mode == .single, !profile.points.isEmpty {
            profile.points[0].x = p.x
            profile.points[0].y = p.y
        } else {
            let delay = profile.points.last?.delayAfterMs ?? 500
            profile.points.append(ClickPoint(name: "Point \(profile.points.count + 1)",
                                             x: p.x, y: p.y, delayAfterMs: delay))
        }
        app.store.update(profile)
    }

    private func movePoint(_ id: UUID, to p: CGPoint) {
        guard var profile = app.activeProfile,
              let index = profile.points.firstIndex(where: { $0.id == id }) else { return }
        profile.points[index].x = p.x
        profile.points[index].y = p.y
        app.store.update(profile)
    }

    private func deletePoint(_ id: UUID) {
        guard var profile = app.activeProfile else { return }
        profile.points.removeAll { $0.id == id }
        app.store.update(profile)
    }
}

/// Onde affichée à chaque clic (turquoise = touché, rouge = rien sous le point).
struct TapRipple: View {
    let hit: Bool
    @State private var animate = false

    var body: some View {
        Circle()
            .stroke(hit ? Theme.accent : Theme.danger, lineWidth: 3)
            .frame(width: 44, height: 44)
            .scaleEffect(animate ? 1.5 : 0.4)
            .opacity(animate ? 0 : 0.9)
            .allowsHitTesting(false)
            .onAppear {
                withAnimation(.easeOut(duration: 0.35)) { animate = true }
            }
    }
}
