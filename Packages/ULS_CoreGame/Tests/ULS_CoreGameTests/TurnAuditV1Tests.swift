import XCTest
@testable import ULS_CoreGame

final class TurnAuditV1Tests: XCTestCase {
    private static let nonSevenRollSeed: UInt64 = {
        var seed: UInt64 = 0
        while true {
            var rng = DeterministicRNG(seed: seed)
            let roll = rng.rollDice()
            if roll.0 + roll.1 != 7 {
                return seed
            }
            seed += 1
        }
    }()

    func testSameSeedAndIntentSequenceProducesIdenticalAuditLog() throws {
        let initial = makeState(diceRngState: Self.nonSevenRollSeed)

        let firstRun = try runSimpleTurn(from: initial)
        let secondRun = try runSimpleTurn(from: initial)

        XCTAssertEqual(firstRun.auditLog, secondRun.auditLog)
        XCTAssertEqual(firstRun.lastTurnRecap, secondRun.lastTurnRecap)
        XCTAssertEqual(firstRun.stateHash, secondRun.stateHash)
    }

    func testLastTurnRecapMatchesCompletedTurnActions() throws {
        let initial = makeState(diceRngState: Self.nonSevenRollSeed)
        var rng = DeterministicRNG(seed: Self.nonSevenRollSeed)
        let expectedRoll = rng.rollDice()
        let expectedRollTotal = expectedRoll.0 + expectedRoll.1

        let rolled = try apply(intent: .rollDice, to: initial, actor: "A")
        let ended = try apply(intent: .endTurn, to: rolled, actor: "A")

        XCTAssertEqual(ended.auditLog.count, 2)
        XCTAssertEqual(ended.auditLog[0], AuditEntryV1(rev: rolled.rev, actor: "A", action: .rollDice, rollTotal: expectedRollTotal))
        XCTAssertEqual(ended.auditLog[1], AuditEntryV1(rev: ended.rev, actor: "A", action: .endTurn, rollTotal: nil))

        XCTAssertEqual(
            ended.lastTurnRecap,
            TurnRecapV1(
                actor: "A",
                startRev: rolled.rev,
                endRev: ended.rev,
                rollTotal: expectedRollTotal,
                actions: [.rollDice, .endTurn]
            )
        )
    }

    func testTamperedAuditActionFailsValidation() throws {
        let initial = makeState(diceRngState: Self.nonSevenRollSeed)
        let rolled = try apply(intent: .rollDice, to: initial, actor: "A")
        let ended = try apply(intent: .endTurn, to: rolled, actor: "A")

        var tamperedLog = ended.auditLog
        tamperedLog[tamperedLog.count - 1] = AuditEntryV1(
            rev: ended.rev,
            actor: "A",
            action: .buildRoad,
            rollTotal: nil
        )
        let tampered = stateWithAudit(ended, auditLog: tamperedLog, recap: computeLastTurnRecap(from: tamperedLog))

        XCTAssertNotEqual(tampered.stateHash, ended.stateHash)
        XCTAssertThrowsError(try validateTransition(from: rolled, to: tampered, actor: "A")) { error in
            XCTAssertEqual(error as? CoreGameError, .auditLogInvalid)
        }
    }

    private func runSimpleTurn(from state: CoreGameStateV1) throws -> CoreGameStateV1 {
        let rolled = try apply(intent: .rollDice, to: state, actor: "A")
        return try apply(intent: .endTurn, to: rolled, actor: "A")
    }

    private func makeState(diceRngState: UInt64) -> CoreGameStateV1 {
        let rules = BoardRulesV1(strategy: .randomV1)
        let board = StandardBoardGeneratorV1.generate(
            boardSeed: SeedDeriver(masterSeed: 444).seed(for: .board),
            rules: rules
        )

        return CoreGameStateV1(
            gameId: "game-audit",
            rev: 40,
            prevHash: "hash-39",
            stateHash: "",
            roster: ["A", "B"],
            currentPlayer: "A",
            phase: .turn,
            seed: 444,
            diceRngState: diceRngState,
            robberRngState: 99,
            resourcesByPlayer: [
                "A": .zero,
                "B": .zero,
            ],
            bankResources: .standardBank,
            boardRules: rules,
            board: board,
            setupState: nil,
            turnState: TurnStateV1(step: .needsRoll, lastRoll: nil)
        ).rehashed()
    }

    private func stateWithAudit(
        _ state: CoreGameStateV1,
        auditLog: [AuditEntryV1],
        recap: TurnRecapV1?
    ) -> CoreGameStateV1 {
        CoreGameStateV1(
            gameId: state.gameId,
            rev: state.rev,
            prevHash: state.prevHash,
            stateHash: state.stateHash,
            roster: state.roster,
            currentPlayer: state.currentPlayer,
            phase: state.phase,
            seed: state.seed,
            diceRngState: state.diceRngState,
            robberRngState: state.robberRngState,
            resourcesByPlayer: state.resourcesByPlayer,
            bankResources: state.bankResources,
            devDeck: state.devDeck,
            devCardsByPlayer: state.devCardsByPlayer,
            newDevCardsByPlayer: state.newDevCardsByPlayer,
            revealedVictoryPointsByPlayer: state.revealedVictoryPointsByPlayer,
            devCardActionPlayedThisTurn: state.devCardActionPlayedThisTurn,
            knightsPlayedByPlayer: state.knightsPlayedByPlayer,
            largestArmyOwner: state.largestArmyOwner,
            largestArmySize: state.largestArmySize,
            longestRoadOwner: state.longestRoadOwner,
            longestRoadLength: state.longestRoadLength,
            winnerPlayer: state.winnerPlayer,
            winningVictoryPoints: state.winningVictoryPoints,
            auditLog: auditLog,
            lastTurnRecap: recap,
            activeTradeOffer: state.activeTradeOffer,
            tradeResponses: state.tradeResponses,
            settlementsByNode: state.settlementsByNode,
            citiesByNode: state.citiesByNode,
            roadsByEdge: state.roadsByEdge,
            boardRules: state.boardRules,
            board: state.board,
            setupState: state.setupState,
            turnState: state.turnState
        ).rehashed()
    }
}
