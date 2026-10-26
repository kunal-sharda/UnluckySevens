#if DEBUG
import XCTest
@testable import MessagesExtensionSupport

@MainActor
final class GamePreRollInspectionTests: XCTestCase {
    func testPreRollWithPlayableDevRetainsBothCanonicalChoices() throws {
        try assertChoices(fixtureID: UXTestFixtures.turnNeedsRollID, actor: UXTestFixtures.host,
                          isActive: true, canRoll: true, canPlayDev: true)
    }

    func testPreRollWithoutCardsRetainsOnlyRoll() throws {
        try assertChoices(fixtureID: UXTestFixtures.turnNeedsRollOnlyID, actor: UXTestFixtures.host,
                          isActive: true, canRoll: true, canPlayDev: false)
    }

    func testOffTurnPlayerDoesNotReceivePreRollControls() throws {
        try assertChoices(fixtureID: UXTestFixtures.turnNeedsRollID, actor: UXTestFixtures.alice,
                          isActive: false, canRoll: false, canPlayDev: false)
    }

    private func assertChoices(fixtureID: String, actor: String, isActive: Bool,
                               canRoll: Bool, canPlayDev: Bool) throws {
        let fixture = UXTestFixtures.fixture(id: fixtureID)
        let suite = "PreRollInspectionTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let model = LobbyDriverViewModel(userDefaults: defaults, tutorialState: fixture.state,
                                        tutorialActorID: actor)
        XCTAssertEqual(model.isNormalPreRollActiveTurn, isActive)
        let actions = model.gameplayShellProjection.gameScreenModel.actionDock.primaryItems
        XCTAssertEqual(actions.contains { $0.kind == .roll && $0.isEnabled }, canRoll)
        XCTAssertEqual(actions.contains { $0.kind == .devCards && $0.isEnabled }, canPlayDev)
        let panel = try XCTUnwrap(GameDevCardPanelModelBuilder.build(state: fixture.state, actingAs: actor))
        XCTAssertEqual(!panel.executableSelectionOnly().cards.isEmpty, canPlayDev)
    }
}
#endif
