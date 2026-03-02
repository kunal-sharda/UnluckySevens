import XCTest
@testable import ULS_CoreGame

final class TurnTradeOffersV1Tests: XCTestCase {
    func testOnlyCurrentPlayerCanProposeTrade() {
        let state = makeState()

        XCTAssertThrowsError(
            try apply(
                intent: .proposeTrade(give: ResourceHandV1(wood: 1), receive: ResourceHandV1(brick: 1)),
                to: state,
                actor: "B"
            )
        ) { error in
            XCTAssertEqual(error as? CoreGameError, .actorMismatch)
        }
    }

    func testAcceptTradeRejectsAnchorMismatch() throws {
        let state = makeState()
        let proposed = try apply(
            intent: .proposeTrade(give: ResourceHandV1(wood: 1), receive: ResourceHandV1(brick: 1)),
            to: state,
            actor: "A"
        )
        XCTAssertNoThrow(try validateTransition(from: state, to: proposed, actor: "A"))

        XCTAssertThrowsError(
            try apply(
                intent: .acceptTrade(acceptingPlayer: "B", offerHash: "wrong-offer-hash"),
                to: proposed,
                actor: "A"
            )
        ) { error in
            XCTAssertEqual(error as? CoreGameError, .tradeOfferAnchorMismatch)
        }
    }

    func testOnlyOneActiveOfferAllowedAtATime() throws {
        let state = makeState()
        let proposed = try apply(
            intent: .proposeTrade(give: ResourceHandV1(wood: 1), receive: ResourceHandV1(brick: 1)),
            to: state,
            actor: "A"
        )

        XCTAssertThrowsError(
            try apply(
                intent: .proposeTrade(give: ResourceHandV1(sheep: 1), receive: ResourceHandV1(wheat: 1)),
                to: proposed,
                actor: "A"
            )
        ) { error in
            XCTAssertEqual(error as? CoreGameError, .tradeOfferAlreadyActive)
        }
    }

    func testEndTurnExpiresOfferAndClearsAccepts() throws {
        let state = makeState()
        let proposed = try apply(
            intent: .proposeTrade(give: ResourceHandV1(wood: 1), receive: ResourceHandV1(brick: 1)),
            to: state,
            actor: "A"
        )
        let offerHash = try XCTUnwrap(proposed.activeTradeOffer?.offerHash)
        let accepted = try apply(
            intent: .acceptTrade(acceptingPlayer: "B", offerHash: offerHash),
            to: proposed,
            actor: "A"
        )
        XCTAssertNoThrow(try validateTransition(from: proposed, to: accepted, actor: "A"))

        let ended = try apply(intent: .endTurn, to: accepted, actor: "A")

        XCTAssertEqual(ended.currentPlayer, "B")
        XCTAssertEqual(ended.turnState?.step, .needsRoll)
        XCTAssertNil(ended.activeTradeOffer)
        XCTAssertTrue(ended.pendingTradeAccepts.isEmpty)
        XCTAssertNoThrow(try validateTransition(from: accepted, to: ended, actor: "A"))
    }

    private func makeState() -> CoreGameStateV1 {
        CoreGameStateV1(
            gameId: "game-trade-offers",
            rev: 40,
            prevHash: "hash-39",
            stateHash: "",
            roster: ["A", "B", "C"],
            currentPlayer: "A",
            phase: .turn,
            seed: 99,
            diceRngState: 123,
            robberRngState: 456,
            resourcesByPlayer: [
                "A": ResourceHandV1(wood: 2, brick: 1, sheep: 1),
                "B": ResourceHandV1(brick: 2, wheat: 1),
                "C": ResourceHandV1(ore: 2),
            ],
            bankResources: .standardBank,
            boardRules: nil,
            board: nil,
            setupState: nil,
            turnState: TurnStateV1(step: .afterRoll, lastRoll: DiceRollV1(d1: 4, d2: 3))
        ).rehashed()
    }
}
