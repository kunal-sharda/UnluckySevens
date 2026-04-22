import ULS_CoreGame
import XCTest
@testable import MessagesExtension

final class GameDiscardPanelModelBuilderTests: XCTestCase {
    private let topology = StandardBoardTopologyV1.standard()

    func testBuildReturnsPublishActionForCurrentPlayerDiscard() {
        let state = makeTurnState(
            resourcesByPlayer: [
                "A": ResourceHandV1(wood: 1, brick: 1),
                "B": .zero,
            ],
            currentPlayer: "A",
            turnState: TurnStateV1(
                step: .pendingDiscards,
                lastRoll: DiceRollV1(d1: 5, d2: 2),
                discardRequirementsByPlayer: ["A": 2]
            )
        )

        let model = GameDiscardPanelModelBuilder.build(
            state: state,
            actingAs: "A"
        )

        XCTAssertEqual(
            model,
            GameDiscardPanelModel(
                waitingPlayers: [
                    PlayerPseudonymResolver.displayName(for: "A", gameID: state.gameId, roster: state.roster)
                ],
                action: .publishDiscard(
                    requiredCount: 2,
                    availableHand: [
                        GameHandChip(resource: .wood, count: 1),
                        GameHandChip(resource: .brick, count: 1),
                    ]
                )
            )
        )
    }

    func testBuildReturnsPublishActionForNextDiscarderEvenWhenTheyAreNotCurrentPlayer() {
        let state = makeTurnState(
            resourcesByPlayer: [
                "A": .zero,
                "B": ResourceHandV1(wood: 1, brick: 1),
            ],
            currentPlayer: "A",
            turnState: TurnStateV1(
                step: .pendingDiscards,
                lastRoll: DiceRollV1(d1: 5, d2: 2),
                discardRequirementsByPlayer: ["B": 2]
            )
        )

        let model = GameDiscardPanelModelBuilder.build(
            state: state,
            actingAs: "B"
        )

        XCTAssertEqual(
            model,
            GameDiscardPanelModel(
                waitingPlayers: [
                    PlayerPseudonymResolver.displayName(for: "B", gameID: state.gameId, roster: state.roster)
                ],
                action: .publishDiscard(
                    requiredCount: 2,
                    availableHand: [
                        GameHandChip(resource: .wood, count: 1),
                        GameHandChip(resource: .brick, count: 1),
                    ]
                )
            )
        )
    }

    func testBuildReturnsWaitingStateForRequiredPlayerWhoIsNotNextInOrder() {
        let state = makeTurnState(
            resourcesByPlayer: [
                "A": .zero,
                "B": ResourceHandV1(wood: 2),
                "C": ResourceHandV1(brick: 1),
            ],
            currentPlayer: "A",
            turnState: TurnStateV1(
                step: .pendingDiscards,
                lastRoll: DiceRollV1(d1: 5, d2: 2),
                discardRequirementsByPlayer: ["B": 2, "C": 1]
            )
        )

        let model = GameDiscardPanelModelBuilder.build(
            state: state,
            actingAs: "C"
        )

        XCTAssertEqual(
            model,
            GameDiscardPanelModel(
                waitingPlayers: [
                    PlayerPseudonymResolver.displayName(for: "B", gameID: state.gameId, roster: state.roster),
                    PlayerPseudonymResolver.displayName(for: "C", gameID: state.gameId, roster: state.roster)
                ],
                action: nil
            )
        )
    }

    func testBuildReturnsWaitingStateForCurrentPlayerWithoutManualApplyFallback() {
        let state = makeTurnState(
            resourcesByPlayer: ["A": .zero, "B": ResourceHandV1(wood: 3)],
            currentPlayer: "A",
            turnState: TurnStateV1(
                step: .pendingDiscards,
                lastRoll: DiceRollV1(d1: 5, d2: 2),
                discardRequirementsByPlayer: ["B": 2]
            )
        )
        let model = GameDiscardPanelModelBuilder.build(
            state: state,
            actingAs: "A"
        )

        XCTAssertEqual(
            model,
            GameDiscardPanelModel(
                waitingPlayers: [
                    PlayerPseudonymResolver.displayName(for: "B", gameID: state.gameId, roster: state.roster)
                ],
                action: nil
            )
        )
    }

    func testBuildReturnsWaitingStateWithoutApplicableAction() {
        let state = makeTurnState(
            resourcesByPlayer: ["A": .zero, "B": .zero, "C": .zero],
            currentPlayer: "A",
            turnState: TurnStateV1(
                step: .pendingDiscards,
                lastRoll: DiceRollV1(d1: 5, d2: 2),
                discardRequirementsByPlayer: ["B": 2, "C": 1]
            )
        )

        let model = GameDiscardPanelModelBuilder.build(
            state: state,
            actingAs: "A"
        )

        XCTAssertEqual(
            model,
            GameDiscardPanelModel(
                waitingPlayers: [
                    PlayerPseudonymResolver.displayName(for: "B", gameID: state.gameId, roster: state.roster),
                    PlayerPseudonymResolver.displayName(for: "C", gameID: state.gameId, roster: state.roster)
                ],
                action: nil
            )
        )
    }

    private func makeTurnState(
        resourcesByPlayer: [String: ResourceHandV1],
        currentPlayer: String,
        turnState: TurnStateV1
    ) -> CoreGameStateV1 {
        let board = BoardSetupV1(
            resourcesByTile: [.wood] + Array(repeating: .desert, count: 18),
            numbersByTile: [5] + Array(repeating: nil, count: 18),
            portsByIndex: topology.ports.map(\.kind),
            robberTile: 1,
            generator: .randomV1,
            boardHash: ""
        ).rehashed()

        return CoreGameStateV1(
            gameId: "discard-builder",
            rev: 7,
            prevHash: "hash-6",
            stateHash: "",
            roster: resourcesByPlayer.keys.sorted(),
            currentPlayer: currentPlayer,
            phase: .turn,
            seed: 31,
            diceRngState: 32,
            robberRngState: 33,
            resourcesByPlayer: resourcesByPlayer,
            settlementsByNode: [:],
            citiesByNode: [:],
            roadsByEdge: [:],
            boardRules: BoardRulesV1(strategy: .randomV1),
            board: board,
            turnState: turnState
        ).rehashed()
    }
}
