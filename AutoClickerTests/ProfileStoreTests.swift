import XCTest
@testable import AutoClicker

@MainActor
final class ProfileStoreTests: XCTestCase {
    private var fileURL: URL!
    private var defaults: UserDefaults!
    private var suiteName: String!

    override func setUp() async throws {
        fileURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathComponent("profiles.json")
        suiteName = "tests-\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suiteName)
    }

    override func tearDown() async throws {
        try? FileManager.default.removeItem(at: fileURL.deletingLastPathComponent())
        defaults.removePersistentDomain(forName: suiteName)
    }

    func testFirstLaunchCreatesStarterProfiles() {
        let store = ProfileStore(fileURL: fileURL, defaults: defaults)
        XCTAssertEqual(store.profiles.count, 2)
        XCTAssertEqual(store.activeProfileID, store.profiles.first?.id)
        XCTAssertTrue(FileManager.default.fileExists(atPath: fileURL.path))
    }

    func testChangesArePersistedAutomatically() {
        let store = ProfileStore(fileURL: fileURL, defaults: defaults)
        var profile = store.add(.makeDefault(name: "Farm"))
        profile.intervalMs = 333
        profile.points.append(ClickPoint(name: "B", x: 0.3, y: 0.4))
        store.update(profile)
        store.setActive(profile.id)

        let reloaded = ProfileStore(fileURL: fileURL, defaults: defaults)
        let saved = reloaded.profile(with: profile.id)
        XCTAssertEqual(saved?.name, "Farm")
        XCTAssertEqual(saved?.intervalMs, 333)
        XCTAssertEqual(saved?.points.count, 2)
        XCTAssertEqual(reloaded.activeProfileID, profile.id)
    }

    func testDuplicateGetsNewIdentifiers() {
        let store = ProfileStore(fileURL: fileURL, defaults: defaults)
        let original = store.profiles[1]
        let copy = store.duplicate(original.id)
        XCTAssertNotNil(copy)
        XCTAssertNotEqual(copy?.id, original.id)
        XCTAssertEqual(copy?.points.count, original.points.count)
        XCTAssertTrue(Set(copy!.points.map(\.id)).isDisjoint(with: original.points.map(\.id)))
    }

    func testNamesStayUnique() {
        let store = ProfileStore(fileURL: fileURL, defaults: defaults)
        let a = store.add(.makeDefault(name: "Profil"))
        let b = store.add(.makeDefault(name: "Profil"))
        XCTAssertEqual(a.name, "Profil")
        XCTAssertEqual(b.name, "Profil 2")
    }

    func testDeleteKeepsAtLeastOneProfileAndFixesActive() {
        let store = ProfileStore(fileURL: fileURL, defaults: defaults)
        let first = store.profiles[0].id
        let second = store.profiles[1].id
        store.setActive(first)

        XCTAssertTrue(store.delete(first))
        XCTAssertEqual(store.activeProfileID, second)
        XCTAssertFalse(store.delete(second), "Le dernier profil ne doit pas pouvoir être supprimé")
        XCTAssertEqual(store.profiles.count, 1)
    }
}
