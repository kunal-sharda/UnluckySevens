import XCTest
@testable import MessagesExtension

final class GamePhysicalTurnHeaderPromptResolverTests: XCTestCase {
    func testPassiveRoutesKeepDice() {
        XCTAssertNil(prompt(route: .none))
        XCTAssertNil(prompt(route: .utility(.bank)))
        XCTAssertNil(prompt(route: .gameInfo))
        XCTAssertNil(prompt(route: .endTurnConfirmation))
    }

    func testActionRoutesDescribeTheCurrentChoice() {
        XCTAssertEqual(prompt(route: .build), .choosePiece)
        XCTAssertEqual(prompt(route: .trade(.chooser)), .chooseTrade)
        XCTAssertEqual(
            prompt(route: .trade(.playerDraft(.emptyOffer))),
            .makeOffer
        )
        XCTAssertEqual(prompt(route: .trade(.maritime)), .tradeWithBank)
        XCTAssertEqual(prompt(route: .trade(.liveOffer)), .waitingForPlayers)
        XCTAssertEqual(
            prompt(route: .devCards, mode: .playDevCard),
            .chooseDevCard
        )
    }

    func testBuildPromptsReflectSelectionWithoutReimplementingLegality() {
        XCTAssertEqual(prompt(route: .build, mode: .buildRoad), .placeRoad)
        XCTAssertEqual(
            prompt(route: .build, mode: .buildRoad, hasBoardCommitDraft: true),
            .tapAgainToPlace
        )
        XCTAssertEqual(
            prompt(route: .build, mode: .buildSettlement),
            .placeSettlement
        )
        XCTAssertEqual(prompt(route: .build, mode: .buildCity), .upgradeCity)
        XCTAssertEqual(
            prompt(route: .build, mode: .buildCity, hasBoardCommitDraft: true),
            .tapAgainToUpgrade
        )
    }

    func testDevCardPromptsFollowThePresentationDraft() {
        XCTAssertEqual(prompt(route: .devCards, mode: .devCardKnightMove), .moveRobber)
        XCTAssertEqual(prompt(route: .devCards, mode: .devCardKnightVictim), .choosePlayer)
        XCTAssertEqual(prompt(route: .devCards, mode: .devCardMonopoly), .chooseResource)
        XCTAssertEqual(
            prompt(
                route: .devCards,
                mode: .devCardYearOfPlenty,
                devCardDraft: .yearOfPlenty(first: nil, second: nil)
            ),
            .chooseTwoResources
        )
        XCTAssertEqual(
            prompt(
                route: .devCards,
                mode: .devCardYearOfPlenty,
                devCardDraft: .yearOfPlenty(first: .wood, second: nil)
            ),
            .chooseOneMore
        )
        XCTAssertNil(
            prompt(
                route: .devCards,
                mode: .devCardYearOfPlenty,
                devCardDraft: .yearOfPlenty(first: .wood, second: .brick)
            )
        )
        XCTAssertEqual(
            prompt(route: .devCards, mode: .devCardRoadBuildingFirst),
            .placeFirstRoad
        )
        XCTAssertEqual(
            prompt(route: .devCards, mode: .devCardRoadBuildingSecond),
            .placeSecondRoad
        )
    }

    private func prompt(
        route: GameShellRoute,
        mode: GameMode = .idle,
        hasBoardCommitDraft: Bool = false,
        devCardDraft: GameDevCardDraft? = nil
    ) -> GamePhysicalTurnHeaderPrompt? {
        GamePhysicalTurnHeaderPromptResolver.prompt(
            route: route,
            mode: mode,
            hasBoardCommitDraft: hasBoardCommitDraft,
            devCardDraft: devCardDraft
        )
    }
}

private extension GameTradeDraft {
    static var emptyOffer: GameTradeDraft {
        GameTradeDraft(
            kind: .offer,
            give: .zero,
            receive: .zero,
            recipients: []
        )
    }
}
