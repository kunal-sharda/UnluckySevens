import Foundation
import Observation

@MainActor
@Observable
final class AppPreferences {
    static let skipAnimationsKey = "uls.skipAnimations"

    private let userDefaults: UserDefaults

    var skipsAnimations: Bool {
        didSet {
            userDefaults.set(skipsAnimations, forKey: Self.skipAnimationsKey)
        }
    }

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
        skipsAnimations = userDefaults.bool(forKey: Self.skipAnimationsKey)
    }
}
