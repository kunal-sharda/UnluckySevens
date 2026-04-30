import Foundation
import ULS_CoreGame

struct LobbyDisplayNamePreferenceStore {
    private let userDefaults: UserDefaults
    private let key = "uls.preferredLobbyDisplayName"

    init(userDefaults: UserDefaults) {
        self.userDefaults = userDefaults
    }

    func load() -> String? {
        let storedValue = userDefaults.string(forKey: key)
        let normalized = CoreGameStateV1.normalizedPlayerDisplayName(storedValue)
        if normalized != storedValue {
            save(normalized)
        }
        return normalized
    }

    func save(_ value: String?) {
        if let normalized = CoreGameStateV1.normalizedPlayerDisplayName(value) {
            userDefaults.set(normalized, forKey: key)
        } else {
            userDefaults.removeObject(forKey: key)
        }
    }
}
