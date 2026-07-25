import ULS_CoreGame
import XCTest
@testable import MessagesExtension

final class GameTradePanelModelBuilderTests: XCTestCase {
    func testBuildIdlePanelForCurrentPlayerUsesConciseTradeTitle() throws {
        let state = makeState(
            currentPlayer: "A",
            resourcesByPlayer: [
                "A": ResourceHandV1(wood: 2, brick: 1),
                "B": .zero,
            ]
        )

        let panel = try XCTUnwrap(
            GameTradePanelModelBuilder.build(
                state: state,
                actingAs: "A"
            )
        )

        XCTAssertNil(panel.activeOffer)
        XCTAssertEqual(panel.roleTitle, "Trade")
        XCTAssertEqual(panel.message, "")
        XCTAssertNil(panel.responderActions)
    }

    func testBuildActiveOfferForTargetedResponderShowsResponderActions() throws {
        let offer = TradeOfferV1(
            offerHash: "offer-1",
            proposer: "A",
            give: ResourceHandV1(wood: 1),
            receive: ResourceHandV1(brick: 1),
            recipients: ["B"],
            createdRev: 8
        )
        let state = makeState(
            currentPlayer: "A",
            resourcesByPlayer: ["A": .zero, "B": ResourceHandV1(brick: 1)],
            activeTradeOffer: offer
        )

        let panel = try XCTUnwrap(
            GameTradePanelModelBuilder.build(
                state: state,
                actingAs: "B"
            )
        )

        XCTAssertEqual(panel.roleTitle, "Incoming Offer")
        XCTAssertEqual(panel.responderActions, GameTradeResponderActions(canAccept: true, canDecline: true, canCounter: true))
        XCTAssertEqual(panel.participantStatuses.first?.state, .waiting)
        XCTAssertEqual(
            panel.activeOffer?.proposerDisplay,
            PlayerPseudonymResolver.displayName(for: "A", gameID: state.gameId, roster: state.roster)
        )
    }

    func testBuildActiveOfferForCurrentPlayerShowsCounterStateWithoutManualApplyPath() throws {
        let offer = TradeOfferV1(
            offerHash: "offer-1",
            proposer: "A",
            give: ResourceHandV1(wood: 1),
            receive: ResourceHandV1(brick: 1),
            recipients: ["B", "C"],
            createdRev: 8
        )
        let state = makeState(
            currentPlayer: "A",
            resourcesByPlayer: ["A": .zero, "B": ResourceHandV1(brick: 1), "C": ResourceHandV1(brick: 2)],
            activeTradeOffer: offer,
            tradeResponses: [
                TradeResponseV1(
                    respondingPlayer: "B",
                    offerHash: offer.offerHash,
                    kind: .counter,
                    respondedAtRev: 9,
                    counterGive: ResourceHandV1(brick: 1),
                    counterReceive: ResourceHandV1(ore: 1)
                )
            ]
        )
        let panel = try XCTUnwrap(
            GameTradePanelModelBuilder.build(
                state: state,
                actingAs: "A"
            )
        )

        XCTAssertEqual(panel.roleTitle, "Your Offer")
        XCTAssertEqual(panel.message, "Review the counters below.")
        XCTAssertEqual(panel.participantStatuses.first(where: { $0.playerID == "B" })?.state, .countered)
        XCTAssertEqual(panel.participantStatuses.first(where: { $0.playerID == "C" })?.state, .waiting)
        XCTAssertTrue(panel.canReplaceOffer)
    }

    func testBuildActiveOfferForTableWatcherShowsTableOffer() throws {
        let offer = TradeOfferV1(
            offerHash: "offer-1",
            proposer: "A",
            give: ResourceHandV1(wood: 1),
            receive: ResourceHandV1(brick: 1),
            recipients: ["B"],
            createdRev: 8
        )
        let state = makeState(
            currentPlayer: "A",
            resourcesByPlayer: ["A": .zero, "B": ResourceHandV1(brick: 1), "C": .zero],
            activeTradeOffer: offer
        )

        let panel = try XCTUnwrap(
            GameTradePanelModelBuilder.build(
                state: state,
                actingAs: "C"
            )
        )

        XCTAssertEqual(panel.roleTitle, "Table Offer")
        XCTAssertNil(panel.responderActions)
        XCTAssertEqual(panel.message, "This offer wasn't sent to you.")
    }

    func testBuildActiveOfferForResponderWithoutRequiredCardsDisablesAccept() throws {
        let offer = TradeOfferV1(
            offerHash: "offer-1",
            proposer: "A",
            give: ResourceHandV1(wood: 1),
            receive: ResourceHandV1(brick: 2),
            recipients: ["B"],
            createdRev: 8
        )
        let state = makeState(
            currentPlayer: "A",
            resourcesByPlayer: ["A": .zero, "B": ResourceHandV1(brick: 1)],
            activeTradeOffer: offer
        )

        let panel = try XCTUnwrap(
            GameTradePanelModelBuilder.build(
                state: state,
                actingAs: "B"
            )
        )

        XCTAssertEqual(panel.responderActions?.canAccept, false)
        XCTAssertEqual(panel.responderActions?.canDecline, true)
        XCTAssertEqual(panel.responderActions?.canCounter, true)
        XCTAssertEqual(panel.message, "You don't have the cards to accept. Decline or counter instead.")
    }

    private func makeState(
        currentPlayer: String,
        resourcesByPlayer: [String: ResourceHandV1],
        activeTradeOffer: TradeOfferV1? = nil,
        tradeResponses: [TradeResponseV1] = []
    ) -> CoreGameStateV1 {
        CoreGameStateV1(
            gameId: "trade-panel",
            rev: 7,
            prevHash: "hash-6",
            stateHash: "",
            roster: Array(resourcesByPlayer.keys).sorted(),
            currentPlayer: currentPlayer,
            phase: .turn,
            seed: 1,
            diceRngState: 2,
            robberRngState: 3,
            resourcesByPlayer: resourcesByPlayer,
            activeTradeOffer: activeTradeOffer,
            tradeResponses: tradeResponses,
            turnState: TurnStateV1(step: .afterRoll, lastRoll: DiceRollV1(d1: 3, d2: 4))
        ).rehashed()
    }
}
