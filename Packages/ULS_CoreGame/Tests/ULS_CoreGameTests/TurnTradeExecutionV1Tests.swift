import XCTest
@testable import ULS_CoreGame

final class TurnTradeExecutionV1Tests: XCTestCase {
    func testExecuteTradeTransfersResourcesAtomically() throws {
        let state = makeStateWithOffer(
            proposerHand: ResourceHandV1(wood: 2, brick: 1),
            acceptorHand: ResourceHandV1(brick: 2, sheep: 1),
            offerGive: ResourceHandV1(wood: 1),
            offerReceive: ResourceHandV1(brick: 1)
        )
        let offerHash = try XCTUnwrap(state.activeTradeOffer?.offerHash)

        let executed = try apply(
            intent: .executeTrade(acceptingPlayer: "B", offerHash: offerHash),
            to: state,
            actor: "A"
        )

        XCTAssertEqual(executed.resourcesByPlayer["A"], ResourceHandV1(wood: 1, brick: 2))
        XCTAssertEqual(executed.resourcesByPlayer["B"], ResourceHandV1(wood: 1, brick: 1, sheep: 1))
        XCTAssertEqual(executed.bankResources, state.bankResources)
        XCTAssertNil(executed.activeTradeOffer)
        XCTAssertTrue(executed.pendingTradeAccepts.isEmpty)
        XCTAssertNoThrow(try validateTransition(from: state, to: executed, actor: "A"))
    }

    func testExecuteTradeRejectsWhenResourcesChangedAndInsufficient() {
        let state = makeStateWithOffer(
            proposerHand: ResourceHandV1(wood: 2, brick: 1),
            acceptorHand: ResourceHandV1(brick: 0, sheep: 1),
            offerGive: ResourceHandV1(wood: 1),
            offerReceive: ResourceHandV1(brick: 1)
        )
        let snapshot = state
        let offerHash = state.activeTradeOffer?.offerHash ?? "missing"

        XCTAssertThrowsError(
            try apply(
                intent: .executeTrade(acceptingPlayer: "B", offerHash: offerHash),
                to: state,
                actor: "A"
            )
        ) { error in
            XCTAssertEqual(error as? CoreGameError, .tradeExecutionInsufficientResources)
        }
        XCTAssertEqual(state, snapshot)
    }

    func testExecuteTradeRejectsWhenOfferExpired() {
        let state = CoreGameStateV1(
            gameId: "game-trade-exec-expired",
            rev: 60,
            prevHash: "hash-59",
            stateHash: "",
            roster: ["A", "B"],
            currentPlayer: "A",
            phase: .turn,
            seed: 1,
            diceRngState: 2,
            robberRngState: 3,
            resourcesByPlayer: [
                "A": ResourceHandV1(wood: 2),
                "B": ResourceHandV1(brick: 2),
            ],
            bankResources: .standardBank,
            boardRules: nil,
            board: nil,
            setupState: nil,
            turnState: TurnStateV1(step: .afterRoll, lastRoll: DiceRollV1(d1: 5, d2: 2))
        ).rehashed()

        XCTAssertThrowsError(
            try apply(
                intent: .executeTrade(acceptingPlayer: "B", offerHash: "expired-offer"),
                to: state,
                actor: "A"
            )
        ) { error in
            XCTAssertEqual(error as? CoreGameError, .tradeOfferMissing)
        }
    }

    private func makeStateWithOffer(
        proposerHand: ResourceHandV1,
        acceptorHand: ResourceHandV1,
        offerGive: ResourceHandV1,
        offerReceive: ResourceHandV1
    ) -> CoreGameStateV1 {
        let base = CoreGameStateV1(
            gameId: "game-trade-exec",
            rev: 50,
            prevHash: "hash-49",
            stateHash: "",
            roster: ["A", "B"],
            currentPlayer: "A",
            phase: .turn,
            seed: 1,
            diceRngState: 2,
            robberRngState: 3,
            resourcesByPlayer: [
                "A": proposerHand,
                "B": acceptorHand,
            ],
            bankResources: .standardBank,
            boardRules: nil,
            board: nil,
            setupState: nil,
            turnState: TurnStateV1(step: .afterRoll, lastRoll: DiceRollV1(d1: 4, d2: 3))
        ).rehashed()

        let offerHash = deterministicTradeOfferHash(
            gameId: base.gameId,
            proposer: "A",
            give: offerGive,
            receive: offerReceive,
            anchorRev: base.rev,
            anchorHash: base.stateHash
        )
        let offer = TradeOfferV1(
            offerHash: offerHash,
            proposer: "A",
            give: offerGive,
            receive: offerReceive,
            createdRev: base.rev + 1
        )

        return CoreGameStateV1(
            gameId: base.gameId,
            rev: base.rev,
            prevHash: base.prevHash,
            stateHash: "",
            roster: base.roster,
            currentPlayer: base.currentPlayer,
            phase: base.phase,
            seed: base.seed,
            diceRngState: base.diceRngState,
            robberRngState: base.robberRngState,
            resourcesByPlayer: base.resourcesByPlayer,
            bankResources: base.bankResources,
            activeTradeOffer: offer,
            pendingTradeAccepts: [
                TradeAcceptV1(acceptingPlayer: "B", offerHash: offerHash, acceptedAtRev: base.rev + 2),
            ],
            settlementsByNode: base.settlementsByNode,
            citiesByNode: base.citiesByNode,
            roadsByEdge: base.roadsByEdge,
            boardRules: base.boardRules,
            board: base.board,
            setupState: base.setupState,
            turnState: base.turnState
        ).rehashed()
    }
}
