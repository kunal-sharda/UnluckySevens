import ULS_CoreGame
import ULS_Transport
import XCTest
@testable import MessagesExtension

final class GameDevCardPanelModelBuilderTests: XCTestCase {
    func testBuildForCurrentPlayerShowsPlayableActionsOnly() throws {
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

        XCTAssertNil(panel.buyAction)
        XCTAssertTrue(panel.playActions.contains(where: { $0.kind == .playKnight }))
        XCTAssertTrue(panel.playActions.contains(where: { $0.kind == .playMonopoly }))
        XCTAssertEqual(panel.playableCounts.first(where: { $0.title == "Knight" })?.count, 1)
        XCTAssertTrue(panel.timingNotes.contains { $0.contains("Only one non-Victory Point") })
        XCTAssertTrue(panel.message.contains("legal cards already available"))
    }

    func testBuildBeforeRollingShowsPlayableActionsButNotPurchase() throws {
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
            turnState: TurnStateV1(step: .needsRoll, lastRoll: nil)
        )

        let panel = try XCTUnwrap(
            GameDevCardPanelModelBuilder.build(
                state: state,
                actingAs: "A"
            )
        )

        XCTAssertNil(panel.buyAction)
        XCTAssertTrue(panel.playActions.contains(where: { $0.kind == .playKnight }))
        XCTAssertTrue(panel.playActions.contains(where: { $0.kind == .revealVictoryPoint }))
        XCTAssertTrue(panel.message.contains("legal cards already available"))
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

        XCTAssertNil(panel.buyAction)
        XCTAssertTrue(panel.playActions.isEmpty)
        XCTAssertTrue(
            panel.message.contains(
                PlayerPseudonymResolver.displayName(for: "A", gameID: state.gameId, roster: state.roster)
            )
        )
    }

    func testBuildShowsNewVictoryPointCountAndRevealAction() throws {
        let state = makeState(
            currentPlayer: "A",
            resourcesByPlayer: ["A": .zero, "B": .zero],
            newDevCardsByPlayer: ["A": DevCardInventoryV1(victoryPoint: 1)]
        )

        let panel = try XCTUnwrap(
            GameDevCardPanelModelBuilder.build(
                state: state,
                actingAs: "A"
            )
        )

        XCTAssertEqual(panel.newCounts.first(where: { $0.title == "Victory Point" })?.count, 1)
        XCTAssertTrue(panel.playActions.contains(where: { $0.kind == .revealVictoryPoint }))
        XCTAssertTrue(panel.timingNotes.contains { $0.contains("Victory Point cards can be revealed immediately") })
    }

    func testBuildAfterDevCardActionPlayedThisTurnKeepsRevealMessaging() throws {
        let state = makeState(
            currentPlayer: "A",
            resourcesByPlayer: ["A": ResourceHandV1(sheep: 1, wheat: 1, ore: 1), "B": .zero],
            newDevCardsByPlayer: ["A": DevCardInventoryV1(victoryPoint: 1)],
            devCardActionPlayedThisTurn: true
        )

        let panel = try XCTUnwrap(
            GameDevCardPanelModelBuilder.build(
                state: state,
                actingAs: "A"
            )
        )

        XCTAssertNil(panel.buyAction)
        XCTAssertEqual(panel.playActions.map(\.kind), [.revealVictoryPoint])
        XCTAssertTrue(panel.message.contains("Victory Point reveals may still be available"))
    }

    private func makeState(
        currentPlayer: String,
        resourcesByPlayer: [String: ResourceHandV1],
        devCardsByPlayer: [String: DevCardInventoryV1] = [:],
        newDevCardsByPlayer: [String: DevCardInventoryV1] = [:],
        settlementsByNode: [Int: String] = [:],
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
            devCardActionPlayedThisTurn: devCardActionPlayedThisTurn,
            settlementsByNode: settlementsByNode,
            boardRules: BoardRulesV1(strategy: .randomV1),
            board: board,
            turnState: turnState
        ).rehashed()
    }
}
