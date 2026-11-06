import ULS_CoreGame
import XCTest
@testable import MessagesExtensionSupport

@MainActor
final class GameControlsTourTests: XCTestCase {
    func testSkipDoesNotCompleteAndOnlyExpectedInteractionCounts() {
        var progress = GameControlsTourProgress()
        progress.record(.endTurn)
        XCTAssertTrue(progress.completed.isEmpty)
        progress.advance()
        XCTAssertFalse(progress.completed.contains(.bank))
        progress.record(.publicDev)
        XCTAssertEqual(progress.completed, [.publicDev])
        progress.back()
        progress.record(.bank)
        XCTAssertEqual(progress.completed, [.bank, .publicDev])
        XCTAssertFalse(progress.isComplete)
    }

    func testProgressPersistsAndResetClearsCompletion() {
        let name = "GameControlsTourTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: name)!
        defer { defaults.removePersistentDomain(forName: name) }
        let preferences = AppPreferences(userDefaults: defaults)
        var progress = GameControlsTourProgress()
        for event in GameControlInteraction.allCases {
            progress.record(event)
            progress.advance()
        }
        preferences.controlsTourProgress = progress
        XCTAssertTrue(AppPreferences(userDefaults: defaults).controlsTourProgress.isComplete)
        preferences.controlsTourProgress = GameControlsTourProgress()
        XCTAssertFalse(AppPreferences(userDefaults: defaults).controlsTourProgress.isComplete)
    }

    func testPracticeEndTurnUsesCoreWithoutTransportOrPersistentGameWrites() {
        let name = "GameControlsTourTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: name)!
        defer { defaults.removePersistentDomain(forName: name) }
        let state = GameTutorialStateComposer.state(for: .endTurn)
        let model = LobbyDriverViewModel(
            userDefaults: defaults, tutorialState: state,
            tutorialActorID: GameTutorialStateComposer.localPlayer,
            isInteractivePractice: true
        )
        let persistedBefore = defaults.persistentDomain(forName: name) as NSDictionary?
        var handoffs = 0
        model.stateHandoffForTesting = { _ in handoffs += 1 }
        XCTAssertTrue(model.publishTurnState(for: .endTurn))
        XCTAssertNotEqual(model.gameplayShellProjection.currentPlayer, state.currentPlayer)
        XCTAssertEqual(handoffs, 0)
        XCTAssertEqual(defaults.persistentDomain(forName: name) as NSDictionary?, persistedBefore)
    }

    func testPracticePurchaseIsExplicitAndChangesOnlySyntheticHand() throws {
        let name = "GameControlsTourTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: name)!
        defer { defaults.removePersistentDomain(forName: name) }
        let model = LobbyDriverViewModel(
            userDefaults: defaults,
            tutorialState: GameTutorialStateComposer.state(for: .buildCosts),
            tutorialActorID: GameTutorialStateComposer.localPlayer,
            isInteractivePractice: true
        )
        let before = model.gameplayShellProjection.rev
        var handoffs = 0
        model.stateHandoffForTesting = { _ in handoffs += 1 }
        XCTAssertTrue(model.handleDevCardAction(.buyDevCard))
        XCTAssertNotEqual(model.gameplayShellProjection.rev, before)
        XCTAssertEqual(handoffs, 0)
    }
}
