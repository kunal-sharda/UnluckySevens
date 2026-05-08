import XCTest
@testable import ULS_CoreGame

final class TurnVictoryV1Tests: XCTestCase {
    private let topology = StandardBoardTopologyV1.standard()

    func testRevealVictoryPointTransitionsToGameOverAtTen() throws {
        let state = makeState(
            currentPlayer: "A",
            devCardsByPlayer: [
                "A": DevCardInventoryV1(victoryPoint: 1),
                "B": .zero,
            ],
            settlementsByNode: [0: "A"],
            citiesByNode: [1: "A", 2: "A", 3: "A", 4: "A"]
        )

        let won = try apply(intent: .revealVictoryPoint, to: state, actor: "A")

        XCTAssertEqual(won.phase, .gameOver)
        XCTAssertEqual(won.winnerPlayer, "A")
        XCTAssertEqual(won.winningVictoryPoints, 10)
        XCTAssertNil(won.turnState)
        XCTAssertNoThrow(try validateTransition(from: state, to: won, actor: "A"))
    }

    func testRevealVictoryPointCountsAllHiddenVictoryPointsForWinningThreshold() throws {
        let state = makeState(
            currentPlayer: "A",
            devCardsByPlayer: [
                "A": DevCardInventoryV1(victoryPoint: 1),
                "B": .zero,
            ],
            newDevCardsByPlayer: [
                "A": DevCardInventoryV1(victoryPoint: 1),
                "B": .zero,
            ],
            citiesByNode: [1: "A", 2: "A", 3: "A", 4: "A"]
        )

        let firstReveal = try apply(intent: .revealVictoryPoint, to: state, actor: "A")

        XCTAssertEqual(firstReveal.phase, .turn)
        XCTAssertEqual(firstReveal.revealedVictoryPointsByPlayer["A"], 1)
        XCTAssertEqual(victoryPoints(for: "A", in: firstReveal), 9)
        XCTAssertEqual(firstReveal.devCardsByPlayer["A"]?.victoryPoint, 0)
        XCTAssertEqual(firstReveal.newDevCardsByPlayer["A"]?.victoryPoint, 1)
        XCTAssertEqual(firstReveal.auditLog.last?.action, .revealVictoryPoint)

        let secondReveal = try apply(intent: .revealVictoryPoint, to: firstReveal, actor: "A")

        XCTAssertEqual(secondReveal.phase, .gameOver)
        XCTAssertEqual(secondReveal.winnerPlayer, "A")
        XCTAssertEqual(secondReveal.winningVictoryPoints, 10)
        XCTAssertEqual(secondReveal.revealedVictoryPointsByPlayer["A"], 2)
        XCTAssertEqual(secondReveal.newDevCardsByPlayer["A"]?.victoryPoint, 0)
        XCTAssertNil(secondReveal.turnState)
        XCTAssertNoThrow(try validateTransition(from: firstReveal, to: secondReveal, actor: "A"))
    }

    func testRevealVictoryPointStillRequiresHiddenTotalToReachWinningThreshold() throws {
        let state = makeState(
            currentPlayer: "A",
            devCardsByPlayer: [
                "A": DevCardInventoryV1(victoryPoint: 1),
                "B": .zero,
            ],
            citiesByNode: [1: "A", 2: "A", 3: "A", 4: "A"]
        )

        XCTAssertThrowsError(try apply(intent: .revealVictoryPoint, to: state, actor: "A")) { error in
            XCTAssertEqual(error as? CoreGameError, .victoryPointRevealNotWinning)
        }
    }

    func testNonCurrentPlayerAtTenDoesNotWinUntilTheirTurn() throws {
        let state = makeState(
            currentPlayer: "A",
            revealedVictoryPointsByPlayer: [
                "A": 0,
                "B": 1,
            ],
            settlementsByNode: [0: "B"],
            citiesByNode: [1: "B", 2: "B", 3: "B", 4: "B"]
        )

        let ended = try apply(intent: .endTurn, to: state, actor: "A")

        XCTAssertEqual(ended.phase, .turn)
        XCTAssertEqual(ended.currentPlayer, "B")
        XCTAssertNil(ended.winnerPlayer)
        XCTAssertEqual(ended.winningVictoryPoints, 0)
        XCTAssertNoThrow(try validateTransition(from: state, to: ended, actor: "A"))
    }

    func testGameplayIntentRejectedAfterGameOverWithNoMutation() {
        let state = makeState(
            currentPlayer: "A",
            phase: .gameOver,
            turnState: nil,
            revealedVictoryPointsByPlayer: ["A": 1, "B": 0],
            settlementsByNode: [0: "A"],
            citiesByNode: [1: "A", 2: "A", 3: "A", 4: "A"],
            winnerPlayer: "A",
            winningVictoryPoints: 10
        )
        let snapshot = state

        XCTAssertThrowsError(try apply(intent: .rollDice, to: state, actor: "A")) { error in
            XCTAssertEqual(error as? CoreGameError, .gameAlreadyOver)
        }
        XCTAssertEqual(state, snapshot)
    }

    private func makeState(
        currentPlayer: String,
        phase: PhaseV1 = .turn,
        turnState: TurnStateV1? = TurnStateV1(step: .afterRoll, lastRoll: DiceRollV1(d1: 4, d2: 3)),
        devCardsByPlayer: [String: DevCardInventoryV1] = [:],
        newDevCardsByPlayer: [String: DevCardInventoryV1] = [:],
        revealedVictoryPointsByPlayer: [String: Int] = [:],
        settlementsByNode: [NodeID: String] = [:],
        citiesByNode: [NodeID: String] = [:],
        winnerPlayer: String? = nil,
        winningVictoryPoints: Int = 0
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
            gameId: "game-victory",
            rev: 120,
            prevHash: "hash-119",
            stateHash: "",
            roster: ["A", "B"],
            currentPlayer: currentPlayer,
            phase: phase,
            seed: 11,
            diceRngState: 22,
            robberRngState: 33,
            resourcesByPlayer: [
                "A": .zero,
                "B": .zero,
            ],
            bankResources: .standardBank,
            devCardsByPlayer: devCardsByPlayer,
            newDevCardsByPlayer: newDevCardsByPlayer,
            revealedVictoryPointsByPlayer: revealedVictoryPointsByPlayer,
            winnerPlayer: winnerPlayer,
            winningVictoryPoints: winningVictoryPoints,
            settlementsByNode: settlementsByNode,
            citiesByNode: citiesByNode,
            roadsByEdge: [:],
            boardRules: BoardRulesV1(strategy: .randomV1),
            board: board,
            setupState: nil,
            turnState: turnState
        ).rehashed()
    }
}
