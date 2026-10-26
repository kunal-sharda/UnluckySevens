import Foundation
import Observation

@MainActor
@Observable
final class AppPreferences {
    static let tutorialPopupsKey = "uls.tutorialPopupsEnabled"
    static let disabledTutorialTipsKey = "uls.disabledTutorialTips"
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

    private var disabledTutorialTips: Set<String> {
        didSet { userDefaults.set(disabledTutorialTips.sorted(), forKey: Self.disabledTutorialTipsKey) }
    }

    func isTipEnabled(_ tip: GameTutorialTip) -> Bool {
        !disabledTutorialTips.contains(tip.rawValue)
    }

    func shouldShowTip(_ tip: GameTutorialTip) -> Bool {
        tutorialPopupsEnabled && isTipEnabled(tip)
    }

    func setTip(_ tip: GameTutorialTip, enabled: Bool) {
        if enabled { disabledTutorialTips.remove(tip.rawValue) }
        else { disabledTutorialTips.insert(tip.rawValue) }
    }

    func enableAllTutorialTips() {
        disabledTutorialTips.removeAll()
        tutorialPopupsEnabled = true
    }

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
        disabledTutorialTips = Set(userDefaults.stringArray(forKey: Self.disabledTutorialTipsKey) ?? [])
        tutorialPopupsEnabled = userDefaults.object(forKey: Self.tutorialPopupsKey) as? Bool ?? true
        skipsAnimations = userDefaults.bool(forKey: Self.skipAnimationsKey)
    }
}
