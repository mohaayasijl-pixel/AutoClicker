import Foundation
import Observation

/// Stocke les profils dans un fichier JSON (Application Support).
/// Chaque modification est enregistrée immédiatement : sauvegarde automatique.
@MainActor
@Observable
final class ProfileStore {
    private(set) var profiles: [ClickProfile] = []
    private(set) var activeProfileID: UUID?
    private(set) var lastSaveError: String?

    private let fileURL: URL
    private let defaults: UserDefaults
    private static let activeKey = "activeProfileID"

    static var defaultFileURL: URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return base.appendingPathComponent("AutoClicker", isDirectory: true)
            .appendingPathComponent("profiles.json")
    }

    init(fileURL: URL = ProfileStore.defaultFileURL, defaults: UserDefaults = .standard) {
        self.fileURL = fileURL
        self.defaults = defaults
        load()
        if profiles.isEmpty {
            profiles = ClickProfile.starterProfiles()
            save()
        }
        if let raw = defaults.string(forKey: Self.activeKey),
           let id = UUID(uuidString: raw),
           profiles.contains(where: { $0.id == id }) {
            activeProfileID = id
        } else {
            activeProfileID = profiles.first?.id
        }
    }

    // MARK: - Lecture

    var activeProfile: ClickProfile? {
        guard let id = activeProfileID else { return profiles.first }
        return profile(with: id)
    }

    func profile(with id: UUID) -> ClickProfile? {
        profiles.first { $0.id == id }
    }

    // MARK: - Modification

    func setActive(_ id: UUID) {
        guard profiles.contains(where: { $0.id == id }) else { return }
        activeProfileID = id
        defaults.set(id.uuidString, forKey: Self.activeKey)
    }

    @discardableResult
    func add(_ profile: ClickProfile = .makeDefault()) -> ClickProfile {
        var new = profile
        new.name = uniqueName(new.name)
        new.updatedAt = Date()
        profiles.append(new)
        save()
        return new
    }

    @discardableResult
    func duplicate(_ id: UUID) -> ClickProfile? {
        guard var copy = profile(with: id) else { return nil }
        copy.id = UUID()
        copy.points = copy.points.map { point in
            var p = point
            p.id = UUID()
            return p
        }
        copy.name = copy.name + " (copie)"
        return add(copy)
    }

    func update(_ profile: ClickProfile) {
        guard let index = profiles.firstIndex(where: { $0.id == profile.id }) else { return }
        guard profiles[index] != profile else { return }
        var updated = profile
        updated.updatedAt = Date()
        profiles[index] = updated
        save()
    }

    /// Supprime un profil. Le dernier profil restant ne peut pas être supprimé.
    @discardableResult
    func delete(_ id: UUID) -> Bool {
        guard profiles.count > 1, let index = profiles.firstIndex(where: { $0.id == id }) else { return false }
        profiles.remove(at: index)
        if activeProfileID == id, let first = profiles.first {
            setActive(first.id)
        }
        save()
        return true
    }

    func move(fromOffsets source: IndexSet, toOffset destination: Int) {
        profiles.move(fromOffsets: source, toOffset: destination)
        save()
    }

    // MARK: - Persistance

    private func load() {
        guard let data = try? Data(contentsOf: fileURL) else { return }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        profiles = (try? decoder.decode([ClickProfile].self, from: data)) ?? []
    }

    private func save() {
        do {
            try FileManager.default.createDirectory(at: fileURL.deletingLastPathComponent(),
                                                    withIntermediateDirectories: true)
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            try encoder.encode(profiles).write(to: fileURL, options: .atomic)
            lastSaveError = nil
        } catch {
            lastSaveError = error.localizedDescription
        }
    }

    private func uniqueName(_ base: String) -> String {
        let names = Set(profiles.map(\.name))
        guard names.contains(base) else { return base }
        var n = 2
        while names.contains("\(base) \(n)") { n += 1 }
        return "\(base) \(n)"
    }
}
