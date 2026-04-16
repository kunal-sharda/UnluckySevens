import XCTest
@testable import ULS_CoreGame

final class TurnTradeOffersV1Tests: XCTestCase {
    func testOnlyCurrentPlayerCanProposeTrade() {
        let state = makeState()

        XCTAssertThrowsError(
            try apply(
                intent: .proposeTrade(
                    give: ResourceHandV1(wood: 1),
                    receive: ResourceHandV1(brick: 1),
                    recipients: ["A", "B"]
                ),
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
            intent: .proposeTrade(
                give: ResourceHandV1(wood: 1),
                receive: ResourceHandV1(brick: 1),
                recipients: ["B"]
            ),
            to: state,
            actor: "A"
        )
        XCTAssertNoThrow(try validateTransition(from: state, to: proposed, actor: "A"))

        XCTAssertThrowsError(
            try apply(
                intent: .acceptTrade(acceptingPlayer: "B", offerHash: "wrong-offer-hash"),
                to: proposed,
                actor: "B"
            )
        ) { error in
            XCTAssertEqual(error as? CoreGameError, .tradeOfferAnchorMismatch)
        }
    }

    func testCurrentPlayerCanReplaceActiveOfferAndClearResponses() throws {
        let state = makeState()
        let proposed = try apply(
            intent: .proposeTrade(
                give: ResourceHandV1(wood: 1),
                receive: ResourceHandV1(brick: 1),
                recipients: ["B", "C"]
            ),
            to: state,
            actor: "A"
        )
        let offerHash = try XCTUnwrap(proposed.activeTradeOffer?.offerHash)
        let countered = try apply(
            intent: .counterTrade(
                counteringPlayer: "B",
                offerHash: offerHash,
                give: ResourceHandV1(brick: 1),
                receive: ResourceHandV1(ore: 1)
            ),
            to: proposed,
            actor: "B"
        )

        let replaced = try apply(
            intent: .proposeTrade(
                give: ResourceHandV1(sheep: 1),
                receive: ResourceHandV1(wheat: 1),
                recipients: ["C"]
            ),
            to: countered,
            actor: "A"
        )

        XCTAssertEqual(replaced.activeTradeOffer?.recipients, ["C"])
        XCTAssertEqual(replaced.activeTradeOffer?.give, ResourceHandV1(sheep: 1))
        XCTAssertTrue(replaced.tradeResponses.isEmpty)
        XCTAssertNoThrow(try validateTransition(from: countered, to: replaced, actor: "A"))
    }

    func testDeclinesFromAllRecipientsCloseOffer() throws {
        let state = makeState()
        let proposed = try apply(
            intent: .proposeTrade(
                give: ResourceHandV1(wood: 1),
                receive: ResourceHandV1(brick: 1),
                recipients: ["B", "C"]
            ),
            to: state,
            actor: "A"
        )
        let offerHash = try XCTUnwrap(proposed.activeTradeOffer?.offerHash)

        let declinedByB = try apply(
            intent: .declineTrade(decliningPlayer: "B", offerHash: offerHash),
            to: proposed,
            actor: "B"
        )
        XCTAssertNotNil(declinedByB.activeTradeOffer)
        XCTAssertEqual(declinedByB.tradeResponses.count, 1)

        let declinedByAll = try apply(
            intent: .declineTrade(decliningPlayer: "C", offerHash: offerHash),
            to: declinedByB,
            actor: "C"
        )

        XCTAssertNil(declinedByAll.activeTradeOffer)
        XCTAssertEqual(declinedByAll.tradeResponses.map(\.kind), [.decline, .decline])
        XCTAssertNoThrow(try validateTransition(from: declinedByB, to: declinedByAll, actor: "C"))
    }

    func testEndTurnExpiresOfferAndClearsResponses() throws {
        let state = makeState()
        let proposed = try apply(
            intent: .proposeTrade(
                give: ResourceHandV1(wood: 1),
                receive: ResourceHandV1(brick: 1),
                recipients: ["B"]
            ),
            to: state,
            actor: "A"
        )
        let offerHash = try XCTUnwrap(proposed.activeTradeOffer?.offerHash)
        let countered = try apply(
            intent: .counterTrade(
                counteringPlayer: "B",
                offerHash: offerHash,
                give: ResourceHandV1(brick: 1),
                receive: ResourceHandV1(ore: 1)
            ),
            to: proposed,
            actor: "B"
        )
        XCTAssertNoThrow(try validateTransition(from: proposed, to: countered, actor: "B"))

        let ended = try apply(intent: .endTurn, to: countered, actor: "A")

        XCTAssertEqual(ended.currentPlayer, "B")
        XCTAssertEqual(ended.turnState?.step, .needsRoll)
        XCTAssertNil(ended.activeTradeOffer)
        XCTAssertTrue(ended.tradeResponses.isEmpty)
        XCTAssertNoThrow(try validateTransition(from: countered, to: ended, actor: "A"))
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
                "C": ResourceHandV1(brick: 1, ore: 2),
            ],
            bankResources: .standardBank,
            boardRules: nil,
            board: nil,
            setupState: nil,
            turnState: TurnStateV1(step: .afterRoll, lastRoll: DiceRollV1(d1: 4, d2: 3))
        ).rehashed()
    }
}
