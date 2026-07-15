import ULS_CoreGame
import XCTest
@testable import MessagesExtension

final class GameDevCardPanelModelBuilderTests: XCTestCase {
    func testRootBuildForCurrentPlayerShowsChoiceDrivenPlayableActions() throws {
        let topology = StandardBoardTopologyV1.standard()
        let victimNode = try XCTUnwrap(topology.tiles[1].nodes.first)
        let state = makeState(
            currentPlayer: "A",
            resourcesByPlayer: [
                "A": ResourceHandV1(wood: 1, brick: 1, sheep: 1, wheat: 1, ore: 1),
                "B": ResourceHandV1(wood: 2),
            ],
            devCardsByPlayer: ["A": DevCardInventoryV1(knight: 1, monopoly: 1)],
            settlementsByNode: [victimNode: "B"]
        )

        let panel = try XCTUnwrap(
            GameDevCardPanelModelBuilder.build(
                state: state,
                actingAs: "A"
            )
        )

        XCTAssertTrue(panel.playActions.contains(where: { $0.kind == .playKnight }))
        XCTAssertTrue(panel.playActions.contains(where: { $0.kind == .playMonopoly }))
        XCTAssertEqual(panel.playableCounts.first(where: { $0.title == "Knight" })?.count, 1)
        XCTAssertEqual(panel.confirmTitle, nil)
        XCTAssertFalse(panel.canConfirm)
        XCTAssertFalse(panel.showsBackButton)
        XCTAssertTrue(panel.message.contains("Choose one of your legal development cards"))
        XCTAssertTrue(panel.timingNotes.contains { $0.contains("Only one non-Victory Point") })
        XCTAssertTrue(panel.cards.contains(where: { $0.kind == .knight && $0.isEnabled }))
        XCTAssertTrue(panel.cards.contains(where: { $0.kind == .monopoly && $0.isEnabled }))
    }

    func testBuildBeforeRollingShowsWinningRevealAndPlayableActions() throws {
        let topology = StandardBoardTopologyV1.standard()
        let victimNode = try XCTUnwrap(topology.tiles[1].nodes.first)
        let state = makeState(
            currentPlayer: "A",
            resourcesByPlayer: [
                "A": ResourceHandV1(wood: 1, brick: 1, sheep: 1, wheat: 1, ore: 1),
                "B": ResourceHandV1(wood: 2),
            ],
            devCardsByPlayer: ["A": DevCardInventoryV1(knight: 1)],
            newDevCardsByPlayer: ["A": DevCardInventoryV1(victoryPoint: 1)],
            settlementsByNode: [victimNode: "B"],
            revealedVictoryPointsByPlayer: ["A": 9, "B": 0],
            turnState: TurnStateV1(step: .needsRoll, lastRoll: nil)
        )

        let panel = try XCTUnwrap(
            GameDevCardPanelModelBuilder.build(
                state: state,
                actingAs: "A"
            )
        )

        XCTAssertTrue(panel.playActions.contains(where: { $0.kind == .playKnight }))
        XCTAssertTrue(panel.playActions.contains(where: { $0.kind == .revealVictoryPoint }))
        XCTAssertTrue(panel.message.contains("Choose one of your legal development cards"))
    }

    func testBuildForNonCurrentPlayerShowsWaitingMessage() throws {
        let state = makeState(
            currentPlayer: "A",
            resourcesByPlayer: ["A": .zero, "B": .zero],
            devCardsByPlayer: ["A": DevCardInventoryV1(knight: 1)]
        )

        let panel = try XCTUnwrap(
            GameDevCardPanelModelBuilder.build(
                state: state,
                actingAs: "B"
            )
        )

        XCTAssertTrue(panel.playActions.isEmpty)
        XCTAssertEqual(panel.confirmTitle, nil)
        XCTAssertFalse(panel.canConfirm)
        XCTAssertTrue(
            panel.message.contains(
                PlayerPseudonymResolver.displayName(for: "A", gameID: state.gameId, roster: state.roster)
            )
        )
    }

    func testBuildShowsHiddenVictoryPointCountButNoRevealActionUntilWinning() throws {
        let state = makeState(
            currentPlayer: "A",
            resourcesByPlayer: ["A": .zero, "B": .zero],
            devCardsByPlayer: ["A": DevCardInventoryV1(victoryPoint: 1)],
            newDevCardsByPlayer: ["A": DevCardInventoryV1(yearOfPlenty: 1)]
        )

        let panel = try XCTUnwrap(
            GameDevCardPanelModelBuilder.build(
                state: state,
                actingAs: "A"
            )
        )

        XCTAssertEqual(panel.heldCounts.first(where: { $0.title == "Victory Point" })?.count, 1)
        XCTAssertEqual(panel.newCounts.first(where: { $0.title == "Year of Plenty" })?.count, 1)
        XCTAssertFalse(panel.playActions.contains(where: { $0.kind == .revealVictoryPoint }))
        XCTAssertTrue(panel.timingNotes.contains { $0.contains("Victory Point cards only reveal") })
        XCTAssertTrue(panel.cards.contains(where: { $0.kind == .victoryPoint && !$0.isEnabled }))
        XCTAssertTrue(panel.cards.contains(where: { $0.kind == .yearOfPlenty && !$0.isEnabled }))
    }

    func testNormalTurnSelectionFiltersOwnedCardsThatAreNotExecutable() throws {
        let state = makeState(
            currentPlayer: "A",
            resourcesByPlayer: ["A": .zero, "B": ResourceHandV1(wood: 1)],
            devCardsByPlayer: ["A": DevCardInventoryV1(monopoly: 1, victoryPoint: 1)],
            newDevCardsByPlayer: ["A": DevCardInventoryV1(yearOfPlenty: 1)]
        )

        let panel = try XCTUnwrap(
            GameDevCardPanelModelBuilder.build(state: state, actingAs: "A")
        )
        let selection = panel.executableSelectionOnly()

        XCTAssertEqual(selection.cards.map(\.kind), [.monopoly])
        XCTAssertEqual(selection.heldCounts, panel.heldCounts)
        XCTAssertEqual(selection.newCounts, panel.newCounts)
    }

    func testBuildAfterDevCardActionPlayedThisTurnKeepsOnlyWinningRevealAvailable() throws {
        let state = makeState(
            currentPlayer: "A",
            resourcesByPlayer: ["A": ResourceHandV1(sheep: 1, wheat: 1, ore: 1), "B": .zero],
            newDevCardsByPlayer: ["A": DevCardInventoryV1(victoryPoint: 1)],
            revealedVictoryPointsByPlayer: ["A": 9, "B": 0],
            devCardActionPlayedThisTurn: true
        )

        let panel = try XCTUnwrap(
            GameDevCardPanelModelBuilder.build(
                state: state,
                actingAs: "A"
            )
        )

        XCTAssertEqual(panel.playActions.map(\.kind), [.revealVictoryPoint])
        XCTAssertTrue(panel.message.contains("Winning Victory Point reveals may still be available"))
    }

    func testMonopolyStageRequiresExplicitResourceSelection() throws {
        let state = makeState(
            currentPlayer: "A",
            resourcesByPlayer: ["A": .zero, "B": ResourceHandV1(ore: 2)],
            devCardsByPlayer: ["A": DevCardInventoryV1(monopoly: 1)]
        )

        let emptyStage = try XCTUnwrap(
            GameDevCardPanelModelBuilder.build(
                state: state,
                actingAs: "A",
                mode: .devCardMonopoly,
                draft: .monopoly(resource: nil)
            )
        )
        XCTAssertEqual(emptyStage.confirmTitle, "Play Monopoly")
        XCTAssertFalse(emptyStage.canConfirm)
        XCTAssertTrue(emptyStage.showsBackButton)

        let selectedStage = try XCTUnwrap(
            GameDevCardPanelModelBuilder.build(
                state: state,
                actingAs: "A",
                mode: .devCardMonopoly,
                draft: .monopoly(resource: .ore)
            )
        )
        XCTAssertTrue(selectedStage.canConfirm)
        XCTAssertTrue(selectedStage.draftSummary?.contains("ore") == true)
    }

    private func makeState(
        currentPlayer: String,
        resourcesByPlayer: [String: ResourceHandV1],
        devCardsByPlayer: [String: DevCardInventoryV1] = [:],
        newDevCardsByPlayer: [String: DevCardInventoryV1] = [:],
        settlementsByNode: [Int: String] = [:],
        revealedVictoryPointsByPlayer: [String: Int] = [:],
        devCardActionPlayedThisTurn: Bool = false,
        turnState: TurnStateV1 = TurnStateV1(step: .afterRoll, lastRoll: DiceRollV1(d1: 3, d2: 4))
    ) -> CoreGameStateV1 {
        let topology = StandardBoardTopologyV1.standard()
        let board = BoardSetupV1(
            resourcesByTile: Array(repeating: .wood, count: topology.tiles.count),
            numbersByTile: Array(repeating: 5, count: topology.tiles.count),
            portsByIndex: topology.ports.map(\.kind),
            robberTile: 0,
            generator: .randomV1,
            boardHash: ""
        ).rehashed()

        return CoreGameStateV1(
            gameId: "dev-panel",
            rev: 9,
            prevHash: "hash-8",
            stateHash: "",
            roster: Array(resourcesByPlayer.keys).sorted(),
            currentPlayer: currentPlayer,
            phase: .turn,
            seed: 1,
            diceRngState: 2,
            robberRngState: 3,
            resourcesByPlayer: resourcesByPlayer,
            bankResources: ResourceHandV1(wood: 19, brick: 19, sheep: 19, wheat: 19, ore: 19),
            devDeck: [.knight, .monopoly],
            devCardsByPlayer: devCardsByPlayer,
            newDevCardsByPlayer: newDevCardsByPlayer,
            revealedVictoryPointsByPlayer: revealedVictoryPointsByPlayer,
            devCardActionPlayedThisTurn: devCardActionPlayedThisTurn,
            settlementsByNode: settlementsByNode,
            boardRules: BoardRulesV1(strategy: .randomV1),
            board: board,
            turnState: turnState
        ).rehashed()
    }
}
