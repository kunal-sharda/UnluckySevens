import Foundation
import Observation

@MainActor
@Observable
final class AppPreferences {
    static let tutorialPopupsKey = "uls.tutorialPopupsEnabled"
    static let disabledTutorialTipsKey = "uls.disabledTutorialTips"
    static let skipAnimationsKey = "uls.skipAnimations"

    private static let devTeachingTurnsKey = "uls.devTeachingTurns"

    /// Consume only when the card can actually appear. Closing/reopening the host does not repeat it.
    func claimDevPurchaseTeaching(context: GameDevPurchaseTeachingContext?, canBuy: Bool, isBusy: Bool) -> Bool {
        guard shouldShowTip(.devPurchase), canBuy, !isBusy, let context else { return false }
        var turns = userDefaults.dictionary(forKey: Self.devTeachingTurnsKey) as? [String: String] ?? [:]
        guard turns[context.gameID] != context.turnID else { return false }
        turns[context.gameID] = context.turnID
        userDefaults.set(turns, forKey: Self.devTeachingTurnsKey)
        return true
    }

    var controlsTourProgress: GameControlsTourProgress {
        get {
            guard let data = userDefaults.data(forKey: "uls.controlsTour.progress"),
                  let progress = try? JSONDecoder().decode(GameControlsTourProgress.self, from: data),
                  (0...GameControlInteraction.allCases.count).contains(progress.index) else {
                return GameControlsTourProgress()
            }
            return progress
        }
        set {
            userDefaults.set(try? JSONEncoder().encode(newValue), forKey: "uls.controlsTour.progress")
        }
    }

    func hasSeenRollReceipt(gameID: String, revision: Int) -> Bool {
        let seen = userDefaults.dictionary(forKey: "uls.rollReceipt.lastSeen") as? [String: Int] ?? [:]
        return revision <= (seen[gameID] ?? -1)
    }

    func claimRollReceipt(gameID: String, revision: Int) -> Bool {
        let key = "uls.rollReceipt.lastSeen"
        var seen = userDefaults.dictionary(forKey: key) as? [String: Int] ?? [:]
        guard revision > (seen[gameID] ?? -1) else { return false }
        seen[gameID] = revision
        userDefaults.set(seen, forKey: key)
        return true
    }

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
