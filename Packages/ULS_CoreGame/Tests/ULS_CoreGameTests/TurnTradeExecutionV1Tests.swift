import XCTest
@testable import ULS_CoreGame

final class TurnTradeExecutionV1Tests: XCTestCase {
    func testAcceptTradeTransfersResourcesAtomicallyOnFirstAcceptance() throws {
        let state = makeStateWithOffer(
            proposerHand: ResourceHandV1(wood: 2, brick: 1),
            acceptorHand: ResourceHandV1(brick: 2, sheep: 1),
            offerGive: ResourceHandV1(wood: 1),
            offerReceive: ResourceHandV1(brick: 1)
        )
        let offerHash = try XCTUnwrap(state.activeTradeOffer?.offerHash)

        let executed = try apply(
            intent: .acceptTrade(acceptingPlayer: "B", offerHash: offerHash),
            to: state,
            actor: "B"
        )

        XCTAssertEqual(executed.resourcesByPlayer["A"], ResourceHandV1(wood: 1, brick: 2))
        XCTAssertEqual(executed.resourcesByPlayer["B"], ResourceHandV1(wood: 1, brick: 1, sheep: 1))
        XCTAssertEqual(executed.bankResources, state.bankResources)
        XCTAssertNil(executed.activeTradeOffer)
        XCTAssertEqual(executed.tradeResponses.map(\.kind), [.accept])
        XCTAssertEqual(executed.tradeResponses.map(\.respondingPlayer), ["B"])
        XCTAssertEqual(executed.auditLog.last?.action, .acceptTrade)
        XCTAssertNoThrow(try validateTransition(from: state, to: executed, actor: "B"))
    }

    func testAcceptTradeRejectsWhenResponderHasInsufficientResources() {
        let state = makeStateWithOffer(
            proposerHand: ResourceHandV1(wood: 2, brick: 1),
            acceptorHand: ResourceHandV1(brick: 0, sheep: 1),
            offerGive: ResourceHandV1(wood: 1),
            offerReceive: ResourceHandV1(brick: 1)
        )
        let offerHash = state.activeTradeOffer?.offerHash ?? "missing"

        XCTAssertThrowsError(
            try apply(
                intent: .acceptTrade(acceptingPlayer: "B", offerHash: offerHash),
                to: state,
                actor: "B"
            )
        ) { error in
            XCTAssertEqual(error as? CoreGameError, .tradeExecutionInsufficientResources)
        }
    }

    func testAcceptTradeRejectsWhenOfferExpired() {
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
                intent: .acceptTrade(acceptingPlayer: "B", offerHash: "expired-offer"),
                to: state,
                actor: "B"
            )
        ) { error in
            XCTAssertEqual(error as? CoreGameError, .tradeOfferMissing)
        }
    }

    private func makeStateWithOffer(
        proposerHand: ResourceHandV1,
        acceptorHand: ResourceHandV1,
        offerGive: ResourceHandV1,
        offerReceive: ResourceHandV1,
        tradeResponses: [TradeResponseV1] = []
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
            recipients: ["B"],
            anchorRev: base.rev,
            anchorHash: base.stateHash
        )
        let normalizedResponses = tradeResponses.isEmpty
            ? []
            : tradeResponses.map {
                TradeResponseV1(
                    respondingPlayer: $0.respondingPlayer,
                    offerHash: offerHash,
                    kind: $0.kind,
                    respondedAtRev: $0.respondedAtRev,
                    counterGive: $0.counterGive,
                    counterReceive: $0.counterReceive
                )
            }
        let offer = TradeOfferV1(
            offerHash: offerHash,
            proposer: "A",
            give: offerGive,
            receive: offerReceive,
            recipients: ["B"],
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
            tradeResponses: normalizedResponses,
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
