import ULS_CoreGame
import XCTest
@testable import MessagesExtension

final class GameRobberVictimOptionBuilderTests: XCTestCase {
    private let topology = StandardBoardTopologyV1.standard()

    func testBuildReturnsVisibleVictimOptionsForCurrentPlayer() {
        let robberTile = topology.tiles(adjacentToNode: 0).first ?? 0
        let state = makeTurnState(
            resourcesByPlayer: [
                "A": .zero,
                "B": ResourceHandV1(wood: 2, sheep: 1),
                "C": ResourceHandV1(ore: 2),
            ],
            settlementsByNode: [0: "B"],
            citiesByNode: [1: "C"],
            turnState: TurnStateV1(
                step: .needsRobberSteal,
                lastRoll: DiceRollV1(d1: 6, d2: 1),
                eligibleStealVictims: ["B", "C"]
            ),
            robberTile: robberTile
        )

        let options = GameRobberVictimOptionBuilder.build(state: state, actingAs: "A")

        XCTAssertEqual(
            options,
            [
                GameRobberVictimOption(
                    playerID: "B",
                    displayName: PlayerPseudonymResolver.displayName(for: "B", gameID: state.gameId, roster: state.roster),
                    handCount: 3
                ),
                GameRobberVictimOption(
                    playerID: "C",
                    displayName: PlayerPseudonymResolver.displayName(for: "C", gameID: state.gameId, roster: state.roster),
                    handCount: 2
                ),
            ]
        )
    }

    func testBuildReturnsEmptyForNonCurrentActor() {
        let state = makeTurnState(
            resourcesByPlayer: ["A": .zero, "B": ResourceHandV1(wood: 2)],
            settlementsByNode: [0: "B"],
            turnState: TurnStateV1(
                step: .needsRobberSteal,
                lastRoll: DiceRollV1(d1: 6, d2: 1),
                eligibleStealVictims: ["B"]
            ),
            robberTile: topology.tiles(adjacentToNode: 0).first ?? 0
        )

        XCTAssertEqual(GameRobberVictimOptionBuilder.build(state: state, actingAs: "B"), [])
    }

    private func makeTurnState(
        resourcesByPlayer: [String: ResourceHandV1],
        settlementsByNode: [NodeID: String] = [:],
        citiesByNode: [NodeID: String] = [:],
        turnState: TurnStateV1,
        robberTile: TileID
    ) -> CoreGameStateV1 {
        let board = BoardSetupV1(
            resourcesByTile: [.wood] + Array(repeating: .desert, count: 18),
            numbersByTile: [5] + Array(repeating: nil, count: 18),
            portsByIndex: topology.ports.map(\.kind),
            robberTile: robberTile,
            generator: .randomV1,
            boardHash: ""
        ).rehashed()

        return CoreGameStateV1(
            gameId: "robber-options",
            rev: 9,
            prevHash: "hash-8",
            stateHash: "",
            roster: resourcesByPlayer.keys.sorted(),
            currentPlayer: "A",
            phase: .turn,
            seed: 31,
            diceRngState: 32,
            robberRngState: 33,
            resourcesByPlayer: resourcesByPlayer,
            settlementsByNode: settlementsByNode,
            citiesByNode: citiesByNode,
            roadsByEdge: [:],
            boardRules: BoardRulesV1(strategy: .randomV1),
            board: board,
            turnState: turnState
        ).rehashed()
    }
}
