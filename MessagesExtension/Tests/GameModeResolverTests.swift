import XCTest

final class GameModeResolverTests: XCTestCase {
    func testNormalizedPrefersForcedModeOverCurrentMode() {
        let availability = GameModeAvailability(
            canSetup: false,
            canBuildRoad: true,
            canBuildSettlement: true,
            canBuildCity: false,
            canRobberMove: true,
            canRobberVictim: false,
            canTrade: true,
            canPlayDevCard: false,
            canDiscard: false
        )

        XCTAssertEqual(
            GameModeResolver.normalized(currentMode: .trade, availability: availability),
            .robberMove
        )
    }

    func testBuildActionLeavesModeSelectionToTheBuildShelf() {
        let availability = GameModeAvailability(
            canSetup: false,
            canBuildRoad: true,
            canBuildSettlement: true,
            canBuildCity: false,
            canRobberMove: false,
            canRobberVictim: false,
            canTrade: false,
            canPlayDevCard: false,
            canDiscard: false
        )

        XCTAssertEqual(
            GameModeResolver.nextMode(for: .build, currentMode: .idle, availability: availability),
            .idle
        )
    }

    func testTradeModeTogglesOnAndOff() {
        let availability = GameModeAvailability(
            canSetup: false,
            canBuildRoad: false,
            canBuildSettlement: false,
            canBuildCity: false,
            canRobberMove: false,
            canRobberVictim: false,
            canTrade: true,
            canPlayDevCard: false,
            canDiscard: false
        )

        let selected = GameModeResolver.nextMode(for: .trade, currentMode: .idle, availability: availability)
        let cleared = GameModeResolver.nextMode(for: .trade, currentMode: selected, availability: availability)

        XCTAssertEqual(selected, .trade)
        XCTAssertEqual(cleared, .idle)
    }

    func testDevCardModeTogglesOnAndOff() {
        let availability = GameModeAvailability(
            canSetup: false,
            canBuildRoad: false,
            canBuildSettlement: false,
            canBuildCity: false,
            canRobberMove: false,
            canRobberVictim: false,
            canTrade: false,
            canPlayDevCard: true,
            canDiscard: false
        )

        let selected = GameModeResolver.nextMode(for: .devCards, currentMode: .idle, availability: availability)
        let cleared = GameModeResolver.nextMode(for: .devCards, currentMode: selected, availability: availability)

        XCTAssertEqual(selected, .playDevCard)
        XCTAssertEqual(cleared, .idle)
    }

    func testDevCardModeStaysOpenWhenThePanelIsAvailableForBuyingOnly() {
        let availability = GameModeAvailability(
            canSetup: false,
            canBuildRoad: false,
            canBuildSettlement: false,
            canBuildCity: false,
            canRobberMove: false,
            canRobberVictim: false,
            canTrade: false,
            canPlayDevCard: true,
            canDiscard: false
        )

        let selected = GameModeResolver.nextMode(for: .devCards, currentMode: .idle, availability: availability)
        let normalized = GameModeResolver.normalized(currentMode: selected, availability: availability)

        XCTAssertEqual(selected, .playDevCard)
        XCTAssertEqual(normalized, .playDevCard)
    }

    func testChoiceDrivenDevCardSubmodesRemainAvailableWhileDevCardsAreAvailable() {
        let availability = GameModeAvailability(
            canSetup: false,
            canBuildRoad: false,
            canBuildSettlement: false,
            canBuildCity: false,
            canRobberMove: false,
            canRobberVictim: false,
            canTrade: false,
            canPlayDevCard: true,
            canDiscard: false
        )

        XCTAssertEqual(
            GameModeResolver.normalized(currentMode: .devCardMonopoly, availability: availability),
            .devCardMonopoly
        )
        XCTAssertEqual(
            GameModeResolver.normalized(currentMode: .devCardRoadBuildingSecond, availability: availability),
            .devCardRoadBuildingSecond
        )
        XCTAssertTrue(GameMode.devCardKnightMove.isDevCardMode)
    }

    func testRollAndEndTurnClearModeToIdle() {
        let availability = GameModeAvailability(
            canSetup: false,
            canBuildRoad: true,
            canBuildSettlement: true,
            canBuildCity: true,
            canRobberMove: false,
            canRobberVictim: false,
            canTrade: true,
            canPlayDevCard: true,
            canDiscard: false
        )

        XCTAssertEqual(
            GameModeResolver.nextMode(for: .roll, currentMode: .buildCity, availability: availability),
            .idle
        )
        XCTAssertEqual(
            GameModeResolver.nextMode(for: .endTurn, currentMode: .trade, availability: availability),
            .idle
        )
    }
}
