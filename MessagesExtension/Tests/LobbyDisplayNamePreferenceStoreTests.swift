import XCTest
@testable import MessagesExtension

final class LobbyDisplayNamePreferenceStoreTests: XCTestCase {
    func testSaveAndLoadNormalizesStoredPreference() throws {
        let defaults = makeUserDefaults()
        let store = LobbyDisplayNamePreferenceStore(userDefaults: defaults)

        store.save("   Kunal   Sharda   ")

        XCTAssertEqual(store.load(), "Kunal Sharda")
        XCTAssertEqual(defaults.string(forKey: "uls.preferredLobbyDisplayName"), "Kunal Sharda")
    }

    func testSaveNilClearsStoredPreference() {
        let defaults = makeUserDefaults()
        let store = LobbyDisplayNamePreferenceStore(userDefaults: defaults)

        store.save("Kunal")
        store.save(nil)

        XCTAssertNil(store.load())
    }

    private func makeUserDefaults() -> UserDefaults {
        let suiteName = "LobbyDisplayNamePreferenceStoreTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        return defaults
    }
}
