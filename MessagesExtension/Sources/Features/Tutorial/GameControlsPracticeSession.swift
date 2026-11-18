import Foundation
import Combine

@MainActor
final class GameControlsPracticeSession: ObservableObject {
    let model: LobbyDriverViewModel
    let preferences: AppPreferences
    private let defaultsName: String

    init(skipsAnimations: Bool) {
        let name = "uls.controls.practice.\(UUID().uuidString)"
        defaultsName = name
        let defaults = UserDefaults(suiteName: name)!
        preferences = AppPreferences(userDefaults: defaults)
        preferences.tutorialPopupsEnabled = false
        preferences.skipsAnimations = skipsAnimations
        model = LobbyDriverViewModel(
            userDefaults: defaults,
            tutorialState: GameTutorialStateComposer.state(for: .buildCosts),
            tutorialActorID: GameTutorialStateComposer.localPlayer,
            isInteractivePractice: true
        )
    }

    deinit {
        UserDefaults.standard.removePersistentDomain(forName: defaultsName)
    }
}
