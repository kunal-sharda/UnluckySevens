import Foundation
import Observation

@MainActor
@Observable
final class AppPreferences {
    static let tutorialPopupsKey = "uls.tutorialPopupsEnabled"
    static let skipAnimationsKey = "uls.skipAnimations"

    private let userDefaults: UserDefaults

    var skipsAnimations: Bool {
        didSet {
            userDefaults.set(skipsAnimations, forKey: Self.skipAnimationsKey)
        }
    }

    var tutorialPopupsEnabled: Bool {
        didSet { userDefaults.set(tutorialPopupsEnabled, forKey: Self.tutorialPopupsKey) }
    }

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
        tutorialPopupsEnabled = userDefaults.object(forKey: Self.tutorialPopupsKey) as? Bool ?? true
        skipsAnimations = userDefaults.bool(forKey: Self.skipAnimationsKey)
    }
}
