import XCTest
@testable import ULS_CoreGame

final class TradeAcceptEligibilityV1Tests: XCTestCase {
    func testEligibleWhenBothTradeSidesRemainFunded() {
        let state = makeState()

        XCTAssertEqual(state.tradeAcceptEligibility(for: "B"), .eligible)
    }

    func testOfferBecomesIneligibleWhenProposerNoLongerFundsPublishedGive() {
        let state = makeState(proposerHand: .zero)

        XCTAssertEqual(state.tradeAcceptEligibility(for: "B"), .offerNoLongerFunded)
    }

    func testResponderAffordabilityHasPrivateReason() {
        let state = makeState(responderHand: .zero)

        XCTAssertEqual(state.tradeAcceptEligibility(for: "B"), .responderInsufficientResources)
    }

    func testTargetingAndPriorResponseMatchReducerEligibility() {
        let notTargeted = makeState(recipients: ["C"])
        let alreadyResponded = makeState(
            responses: [
                TradeResponseV1(
                    respondingPlayer: "B",
                    offerHash: "offer-1",
                    kind: .decline,
                    respondedAtRev: 9
                )
            ]
        )

        XCTAssertEqual(notTargeted.tradeAcceptEligibility(for: "B"), .responderNotTargeted)
        XCTAssertEqual(alreadyResponded.tradeAcceptEligibility(for: "B"), .responderAlreadyResponded)
    }

    func testMissingOfferAndWrongTurnStepAreIneligible() {
        let noOffer = makeState(activeOffer: false)
        let wrongStep = makeState(turnStep: .needsRoll)

        XCTAssertEqual(noOffer.tradeAcceptEligibility(for: "B"), .offerMissing)
        XCTAssertEqual(wrongStep.tradeAcceptEligibility(for: "B"), .turnUnavailable)
    }

    private func makeState(
        proposerHand: ResourceHandV1 = ResourceHandV1(wood: 1),
        responderHand: ResourceHandV1 = ResourceHandV1(brick: 1),
        recipients: [String] = ["B"],
        responses: [TradeResponseV1] = [],
        activeOffer: Bool = true,
        turnStep: TurnStepV1 = .afterRoll
    ) -> CoreGameStateV1 {
        CoreGameStateV1(
            gameId: "trade-eligibility",
            rev: 8,
            prevHash: "hash-7",
            stateHash: "",
            roster: ["A", "B", "C"],
            currentPlayer: "A",
            phase: .turn,
            seed: 1,
            diceRngState: 2,
            robberRngState: 3,
            resourcesByPlayer: [
                "A": proposerHand,
                "B": responderHand,
                "C": ResourceHandV1(brick: 1),
            ],
            activeTradeOffer: activeOffer
                ? TradeOfferV1(
                    offerHash: "offer-1",
                    proposer: "A",
                    give: ResourceHandV1(wood: 1),
                    receive: ResourceHandV1(brick: 1),
                    recipients: recipients,
                    createdRev: 8
                )
                : nil,
            tradeResponses: responses,
            turnState: TurnStateV1(
                step: turnStep,
                lastRoll: turnStep == .needsRoll ? nil : DiceRollV1(d1: 3, d2: 4)
            )
        ).rehashed()
    }
}
