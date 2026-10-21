import XCTest
@testable import ULS_CoreGame

final class CanonicalStatePreferenceV1Tests: XCTestCase {
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

    func testCompetingAcceptWinnerIsIndependentOfObservationOrder() throws {
        let branches = try makeCompetingAcceptBranches()

        let bWins = CanonicalStatePreferenceV1.prefers(branches.acceptedByB, over: branches.acceptedByC)
        let cWins = CanonicalStatePreferenceV1.prefers(branches.acceptedByC, over: branches.acceptedByB)

        XCTAssertNotEqual(bWins, cWins)
    }

    func testWinningAcceptLineageOutranksLaterLosingDescendant() throws {
        let branches = try makeCompetingAcceptBranches()
        let winner = CanonicalStatePreferenceV1.prefers(branches.acceptedByB, over: branches.acceptedByC)
            ? branches.acceptedByB
            : branches.acceptedByC
        let loser = winner.stateHash == branches.acceptedByB.stateHash
            ? branches.acceptedByC
            : branches.acceptedByB
        let losingDescendant = try apply(intent: .endTurn, to: loser, actor: "A")
        var context = CanonicalStateConvergenceContextV1()
        context.observe(branches.acceptedByB)
        context.observe(branches.acceptedByC)

        XCTAssertGreaterThan(losingDescendant.rev, winner.rev)
        XCTAssertTrue(CanonicalStatePreferenceV1.prefers(winner, over: losingDescendant, context: context))
        XCTAssertFalse(CanonicalStatePreferenceV1.prefers(losingDescendant, over: winner, context: context))
    }

    func testUnrelatedAcceptLineagesDoNotCreateContentionPreference() throws {
        let firstBase = makeBaseState()
        let secondBase = CoreGameStateV1(
            gameId: firstBase.gameId,
            rev: firstBase.rev,
            prevHash: firstBase.prevHash,
            stateHash: "",
            roster: firstBase.roster,
            currentPlayer: firstBase.currentPlayer,
            phase: firstBase.phase,
            seed: firstBase.seed,
            diceRngState: firstBase.diceRngState,
            robberRngState: firstBase.robberRngState,
            resourcesByPlayer: [
                "A": ResourceHandV1(wood: 3),
                "B": ResourceHandV1(brick: 2),
                "C": ResourceHandV1(brick: 2),
            ],
            bankResources: firstBase.bankResources,
            turnState: firstBase.turnState
        ).rehashed()
        let acceptedByB = try acceptedBranch(base: firstBase, responder: "B")
        let acceptedByC = try acceptedBranch(base: secondBase, responder: "C")
        let laterC = try apply(intent: .endTurn, to: acceptedByC, actor: "A")
        var context = CanonicalStateConvergenceContextV1()
        context.observe(acceptedByB)
        context.observe(acceptedByC)

        XCTAssertNotEqual(acceptedByB.prevHash, acceptedByC.prevHash)
        XCTAssertTrue(CanonicalStatePreferenceV1.prefers(laterC, over: acceptedByB, context: context))
        XCTAssertFalse(CanonicalStatePreferenceV1.prefers(acceptedByB, over: laterC, context: context))
    }

    func testProvenContentionDoesNotCaptureUnrelatedLookalikeLineage() throws {
        let branches = try makeCompetingAcceptBranches()
        let winner = CanonicalStatePreferenceV1.prefers(branches.acceptedByB, over: branches.acceptedByC)
            ? branches.acceptedByB
            : branches.acceptedByC
        let winningActor = try XCTUnwrap(winner.auditLog.last?.actor)
        let genuineBase = makeBaseState()
        let unrelatedBase = CoreGameStateV1(
            gameId: genuineBase.gameId,
            rev: genuineBase.rev,
            prevHash: genuineBase.prevHash,
            stateHash: "",
            roster: genuineBase.roster,
            currentPlayer: genuineBase.currentPlayer,
            phase: genuineBase.phase,
            seed: genuineBase.seed,
            diceRngState: genuineBase.diceRngState,
            robberRngState: genuineBase.robberRngState,
            resourcesByPlayer: [
                "A": ResourceHandV1(wood: 3),
                "B": ResourceHandV1(brick: 2),
                "C": ResourceHandV1(brick: 2),
            ],
            bankResources: genuineBase.bankResources,
            turnState: genuineBase.turnState
        ).rehashed()
        let unrelatedAccept = try acceptedBranch(base: unrelatedBase, responder: winningActor)
        let unrelatedLater = try apply(intent: .endTurn, to: unrelatedAccept, actor: "A")
        var context = CanonicalStateConvergenceContextV1()
        context.observe(branches.acceptedByB)
        context.observe(branches.acceptedByC)
        context.observe(unrelatedAccept)
        context.observe(unrelatedLater)

        XCTAssertEqual(unrelatedAccept.auditLog, winner.auditLog)
        XCTAssertNotEqual(unrelatedAccept.prevHash, winner.prevHash)
        XCTAssertGreaterThan(unrelatedLater.rev, winner.rev)
        XCTAssertTrue(
            CanonicalStatePreferenceV1.prefers(unrelatedLater, over: winner, context: context)
        )
        XCTAssertFalse(
            CanonicalStatePreferenceV1.prefers(winner, over: unrelatedLater, context: context)
        )
    }

    func testLaterAcceptOnLosingBranchRemainsInOriginalLosingLineage() throws {
        let branches = try makeCompetingAcceptBranches()
        let winner = CanonicalStatePreferenceV1.prefers(branches.acceptedByB, over: branches.acceptedByC)
            ? branches.acceptedByB
            : branches.acceptedByC
        let loser = winner.stateHash == branches.acceptedByB.stateHash
            ? branches.acceptedByC
            : branches.acceptedByB
        var context = CanonicalStateConvergenceContextV1()
        context.observe(branches.acceptedByB)
        context.observe(branches.acceptedByC)

        let ended = try apply(intent: .endTurn, to: loser, actor: "A")
        context.observe(ended)
        let rolled = try apply(intent: .rollDice, to: ended, actor: "B")
        context.observe(rolled)
        let proposed = try apply(
            intent: .proposeTrade(
                give: ResourceHandV1(brick: 1),
                receive: ResourceHandV1(wood: 1),
                recipients: ["A"]
            ),
            to: rolled,
            actor: "B"
        )
        context.observe(proposed)
        let offerHash = try XCTUnwrap(proposed.activeTradeOffer?.offerHash)
        let laterAccept = try apply(
            intent: .acceptTrade(acceptingPlayer: "A", offerHash: offerHash),
            to: proposed,
            actor: "A"
        )
        context.observe(laterAccept)

        XCTAssertGreaterThan(laterAccept.rev, winner.rev)
        XCTAssertTrue(CanonicalStatePreferenceV1.prefers(winner, over: laterAccept, context: context))
        XCTAssertFalse(CanonicalStatePreferenceV1.prefers(laterAccept, over: winner, context: context))
    }

    func testNonContentiousStatesKeepRevisionThenHashOrdering() {
        let older = makeBaseState()
        let newer = CoreGameStateV1(
            gameId: older.gameId,
            rev: older.rev + 1,
            prevHash: older.stateHash,
            stateHash: "",
            roster: older.roster,
            currentPlayer: older.currentPlayer,
            phase: older.phase,
            seed: older.seed,
            diceRngState: older.diceRngState,
            robberRngState: older.robberRngState,
            resourcesByPlayer: older.resourcesByPlayer,
            bankResources: older.bankResources,
            turnState: older.turnState
        ).rehashed()

        XCTAssertTrue(CanonicalStatePreferenceV1.prefers(newer, over: older))
        XCTAssertFalse(CanonicalStatePreferenceV1.prefers(older, over: newer))
    }

    func testContentionKeyIsStableAndSeparatesResponders() {
        let first = CanonicalStatePreferenceV1.tradeAcceptanceContentionKey(
            gameId: "game",
            acceptedAtRev: 12,
            responderActorID: "B"
        )
        let repeated = CanonicalStatePreferenceV1.tradeAcceptanceContentionKey(
            gameId: "game",
            acceptedAtRev: 12,
            responderActorID: "B"
        )
        let other = CanonicalStatePreferenceV1.tradeAcceptanceContentionKey(
            gameId: "game",
            acceptedAtRev: 12,
            responderActorID: "C"
        )

        XCTAssertEqual(first, repeated)
        XCTAssertNotEqual(first, other)
        XCTAssertEqual(first.count, 64)
    }

    private func makeCompetingAcceptBranches() throws -> (
        acceptedByB: CoreGameStateV1,
        acceptedByC: CoreGameStateV1
    ) {
        let proposed = try apply(
            intent: .proposeTrade(
                give: ResourceHandV1(wood: 1),
                receive: ResourceHandV1(brick: 1),
                recipients: ["B", "C"]
            ),
            to: makeBaseState(),
            actor: "A"
        )
        let offerHash = try XCTUnwrap(proposed.activeTradeOffer?.offerHash)
        return (
            try apply(
                intent: .acceptTrade(acceptingPlayer: "B", offerHash: offerHash),
                to: proposed,
                actor: "B"
            ),
            try apply(
                intent: .acceptTrade(acceptingPlayer: "C", offerHash: offerHash),
                to: proposed,
                actor: "C"
            )
        )
    }

    private func acceptedBranch(
        base: CoreGameStateV1,
        responder: String
    ) throws -> CoreGameStateV1 {
        let proposed = try apply(
            intent: .proposeTrade(
                give: ResourceHandV1(wood: 1),
                receive: ResourceHandV1(brick: 1),
                recipients: ["B", "C"]
            ),
            to: base,
            actor: "A"
        )
        let offerHash = try XCTUnwrap(proposed.activeTradeOffer?.offerHash)
        return try apply(
            intent: .acceptTrade(acceptingPlayer: responder, offerHash: offerHash),
            to: proposed,
            actor: responder
        )
    }

    private func makeBaseState() -> CoreGameStateV1 {
        CoreGameStateV1(
            gameId: "trade-contention",
            rev: 20,
            prevHash: "hash-19",
            stateHash: "",
            roster: ["A", "B", "C"],
            currentPlayer: "A",
            phase: .turn,
            seed: 1,
            diceRngState: Self.nonSevenRollSeed,
            robberRngState: 3,
            resourcesByPlayer: [
                "A": ResourceHandV1(wood: 2),
                "B": ResourceHandV1(brick: 2),
                "C": ResourceHandV1(brick: 2),
            ],
            bankResources: .standardBank,
            turnState: TurnStateV1(step: .afterRoll, lastRoll: DiceRollV1(d1: 4, d2: 3))
        ).rehashed()
    }
}
