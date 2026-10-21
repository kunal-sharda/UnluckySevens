import XCTest
@testable import ULS_CoreGame

final class TurnVictoryV1Tests: XCTestCase {
    private let topology = StandardBoardTopologyV1.standard()

    func testTwoVPPurchasesWinAtTenWithHiddenOrRevealedExistingCard() throws {
        for existingRevealed in [false, true] {
            let state = makeState(
                currentPlayer: "A",
                devCardsByPlayer: ["A": DevCardInventoryV1(victoryPoint: existingRevealed ? 0 : 1)],
                revealedVictoryPointsByPlayer: ["A": existingRevealed ? 1 : 0],
                settlementsByNode: [0: "A", 3: "A", 6: "A", 9: "A", 12: "A"],
                resourcesByPlayer: ["A": ResourceHandV1(sheep: 2, wheat: 2, ore: 2), "B": .zero],
                devDeck: [.victoryPoint, .victoryPoint],
                knightsPlayedByPlayer: ["A": 3], largestArmyOwner: "A", largestArmySize: 3,
                devCardActionPlayedThisTurn: true
            )
            let nine = try apply(intent: .buyDevCard, to: state, actor: "A")
            XCTAssertEqual(nine.phase, .turn)
            XCTAssertEqual(nine.revealedVictoryPointsByPlayer["A"], existingRevealed ? 1 : 0)
            XCTAssertNoThrow(try validateTransition(from: state, to: nine, actor: "A"))
            let ten = try apply(intent: .buyDevCard, to: nine, actor: "A")
            XCTAssertEqual(ten.phase, .gameOver)
            XCTAssertEqual(ten.winnerPlayer, "A")
            XCTAssertEqual(ten.winningVictoryPoints, 10)
            XCTAssertEqual(ten.revealedVictoryPointsByPlayer["A"], 3)
            XCTAssertEqual(ten.gameResult?.finalScoresByPlayer["A"], 10)
            XCTAssertNoThrow(try validateTransition(from: nine, to: ten, actor: "A"))
        }
    }

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

        let won = try apply(intent: .revealVictoryPoint, to: state, actor: "A")
        XCTAssertEqual(won.phase, .gameOver)
        XCTAssertEqual(won.winnerPlayer, "A")
        XCTAssertEqual(won.winningVictoryPoints, 10)
        XCTAssertEqual(won.revealedVictoryPointsByPlayer["A"], 2)
        XCTAssertEqual(won.devCardsByPlayer["A"]?.victoryPoint, 0)
        XCTAssertEqual(won.newDevCardsByPlayer["A"]?.victoryPoint, 0)
        XCTAssertEqual(won.auditLog.last?.action, .revealVictoryPoint)
        XCTAssertNoThrow(try validateTransition(from: state, to: won, actor: "A"))
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

        XCTAssertEqual(ended.phase, .gameOver)
        XCTAssertEqual(ended.currentPlayer, "B")
        XCTAssertEqual(ended.winnerPlayer, "B")
        XCTAssertEqual(ended.winningVictoryPoints, 10)
        XCTAssertNoThrow(try validateTransition(from: state, to: ended, actor: "A"))
    }

    func testLegacyWinningSnapshotPublishesVictoryBeforeRollingWithoutChangingInput() throws {
        let state = makeState(currentPlayer: "A", turnState: .init(step: .needsRoll, lastRoll: nil),
                              devCardsByPlayer: ["A": .init(victoryPoint: 2), "B": .init(victoryPoint: 1)],
                              citiesByNode: [1: "A", 2: "A", 3: "A", 4: "A"])
        let snapshot = state
        XCTAssertEqual(victoryPoints(for: "A", in: state), 8)
        let won = try apply(intent: .rollDice, to: state, actor: "A")
        XCTAssertEqual(state, snapshot)
        XCTAssertEqual(won.phase, .gameOver)
        XCTAssertEqual(won.diceRngState, state.diceRngState)
        XCTAssertEqual(won.resourcesByPlayer, state.resourcesByPlayer)
        XCTAssertEqual(won.devCardsByPlayer["B"], state.devCardsByPlayer["B"])
        XCTAssertEqual(won.revealedVictoryPointsByPlayer["B"], state.revealedVictoryPointsByPlayer["B"])
        XCTAssertEqual(won.gameResult?.finalScoresByPlayer["B"], 0)
        XCTAssertNoThrow(try validateTransition(from: state, to: won, actor: "A"))
    }

    func testKnightAwardWinsBeforeRollAndRevealsHiddenVP() throws {
        let state = makeState(currentPlayer: "A", turnState: .init(step: .needsRoll, lastRoll: nil),
                              devCardsByPlayer: ["A": .init(knight: 1, victoryPoint: 1)],
                              settlementsByNode: [0: "A"], citiesByNode: [1: "A", 2: "A", 3: "A"],
                              knightsPlayedByPlayer: ["A": 2])
        let won = try apply(intent: .playKnight(tileID: 0, victimPlayer: nil), to: state, actor: "A")
        XCTAssertEqual(won.phase, .gameOver)
        XCTAssertEqual(won.largestArmyOwner, "A")
        XCTAssertEqual(won.winningVictoryPoints, 10)
        XCTAssertTrue(won.devCardActionPlayedThisTurn)
        XCTAssertNoThrow(try validateTransition(from: state, to: won, actor: "A"))
    }

    func testResignationHandoffRecognizesNextPlayersWinningTotal() throws {
        let state = makeState(currentPlayer: "A", devCardsByPlayer: ["B": .init(victoryPoint: 2)],
                              citiesByNode: [1: "B", 2: "B", 3: "B", 4: "B"])
        let won = try apply(intent: GameLifecycleIntentV1.resign(anchoredTo: state), to: state, actor: "A")
        XCTAssertEqual(won.phase, .gameOver)
        XCTAssertEqual(won.winnerPlayer, "B")
        XCTAssertEqual(won.winningVictoryPoints, 10)
        XCTAssertNoThrow(try validateTransition(from: state, to: won, actor: "A"))
    }

    func testLegacyWinCanBeClaimedDuringForcedStepAndWithPublicPointsOnly() throws {
        let state = makeState(currentPlayer: "A", turnState: .init(step: .needsRobberMove, lastRoll: .init(d1: 3, d2: 4)),
                              revealedVictoryPointsByPlayer: ["A": 2],
                              citiesByNode: [1: "A", 2: "A", 3: "A", 4: "A"])
        XCTAssertTrue(state.canRevealVictoryPoint(for: "A"))
        XCTAssertFalse(state.canRevealVictoryPoint(for: "B"))
        let won = try apply(intent: .revealVictoryPoint, to: state, actor: "A")
        XCTAssertEqual(won.phase, .gameOver)
        XCTAssertEqual(won.board, state.board)
        XCTAssertNoThrow(try validateTransition(from: state, to: won, actor: "A"))
    }

    func testWinningTransitionRejectsRehashedTamperingAndWrongActor() throws {
        let state = makeState(currentPlayer: "A", devCardsByPlayer: ["A": .init(victoryPoint: 2)],
                              citiesByNode: [1: "A", 2: "A", 3: "A", 4: "A"])
        let won = try apply(intent: .revealVictoryPoint, to: state, actor: "A")
        XCTAssertThrowsError(try validateTransition(from: state, to: won, actor: "B"))
        for field in ["winningVictoryPoints", "seed", "diceRngState"] {
            var object = try XCTUnwrap(JSONSerialization.jsonObject(with: JSONEncoder().encode(won)) as? [String: Any])
            object[field] = 999
            let forged = try JSONDecoder().decode(CoreGameStateV1.self, from: JSONSerialization.data(withJSONObject: object)).rehashed()
            XCTAssertThrowsError(try validateTransition(from: state, to: forged, actor: "A"), field)
        }
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
        winningVictoryPoints: Int = 0,
        resourcesByPlayer: [String: ResourceHandV1] = ["A": .zero, "B": .zero],
        devDeck: [DevCardV1] = [],
        knightsPlayedByPlayer: [String: Int] = [:],
        largestArmyOwner: String? = nil,
        largestArmySize: Int = 0,
        devCardActionPlayedThisTurn: Bool = false
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
            resourcesByPlayer: resourcesByPlayer,
            bankResources: .standardBank,
            devDeck: devDeck,
            devCardsByPlayer: devCardsByPlayer,
            newDevCardsByPlayer: newDevCardsByPlayer,
            revealedVictoryPointsByPlayer: revealedVictoryPointsByPlayer,
            devCardActionPlayedThisTurn: devCardActionPlayedThisTurn,
            knightsPlayedByPlayer: knightsPlayedByPlayer,
            largestArmyOwner: largestArmyOwner,
            largestArmySize: largestArmySize,
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
