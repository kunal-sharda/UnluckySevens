import ULS_CoreGame
import ULS_Transport
import XCTest

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
            actingAs: "A",
            selectedTurnIntent: nil
        )

        XCTAssertEqual(
            model,
            GameDiscardPanelModel(
                waitingPlayers: ["A"],
                action: .publishSuggestedDiscard(
                    requiredCount: 2,
                    suggested: [
                        GameHandChip(resource: .wood, count: 1),
                        GameHandChip(resource: .brick, count: 1),
                    ]
                )
            )
        )
    }

    func testBuildReturnsSendActionForNonCurrentPlayerDiscard() {
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
            actingAs: "B",
            selectedTurnIntent: nil
        )

        XCTAssertEqual(
            model,
            GameDiscardPanelModel(
                waitingPlayers: ["B"],
                action: .sendSuggestedDiscard(
                    requiredCount: 2,
                    suggested: [
                        GameHandChip(resource: .wood, count: 1),
                        GameHandChip(resource: .brick, count: 1),
                    ]
                )
            )
        )
    }

    func testBuildReturnsApplyActionForCurrentPlayerWithSelectedDiscardIntent() {
        let state = makeTurnState(
            resourcesByPlayer: ["A": .zero, "B": ResourceHandV1(wood: 3)],
            currentPlayer: "A",
            turnState: TurnStateV1(
                step: .pendingDiscards,
                lastRoll: DiceRollV1(d1: 5, d2: 2),
                discardRequirementsByPlayer: ["B": 2]
            )
        )
        let selectedIntent = TurnIntentV1(
            submitDiscardFor: "B",
            discarded: TransportResourceHandV1(wood: 2),
            gameId: state.gameId,
            anchorRev: state.rev,
            anchorHash: state.stateHash,
            actor: "B"
        )

        let model = GameDiscardPanelModelBuilder.build(
            state: state,
            actingAs: "A",
            selectedTurnIntent: selectedIntent
        )

        XCTAssertEqual(
            model,
            GameDiscardPanelModel(
                waitingPlayers: ["B"],
                action: .applySelectedDiscard(
                    playerDisplay: "B",
                    suggested: [GameHandChip(resource: .wood, count: 2)]
                )
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
            actingAs: "A",
            selectedTurnIntent: nil
        )

        XCTAssertEqual(
            model,
            GameDiscardPanelModel(waitingPlayers: ["B", "C"], action: nil)
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
