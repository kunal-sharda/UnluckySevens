import ULS_CoreGame
import ULS_Transport
import XCTest
@testable import MessagesExtension

final class GameTradePanelModelBuilderTests: XCTestCase {
    func testBuildIdlePanelForCurrentPlayerShowsSuggestedOffer() throws {
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
                actingAs: "A",
                selectedTurnIntent: nil
            )
        )

        XCTAssertNil(panel.activeOffer)
        XCTAssertEqual(panel.roleTitle, "Trade Desk")
        XCTAssertTrue(panel.actions.contains(where: { $0.kind == .publishSuggestedOffer }))
        XCTAssertFalse(panel.footnotes.isEmpty)
    }

    func testBuildActiveOfferForNonCurrentPlayerShowsAcceptAction() throws {
        let offer = TradeOfferV1(
            offerHash: "offer-1",
            proposer: "A",
            give: ResourceHandV1(wood: 1),
            receive: ResourceHandV1(brick: 1),
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
                actingAs: "B",
                selectedTurnIntent: nil
            )
        )

        XCTAssertEqual(
            panel.activeOffer?.proposerDisplay,
            PlayerPseudonymResolver.displayName(for: "A", gameID: state.gameId, roster: state.roster)
        )
        XCTAssertEqual(panel.actions.map(\.kind), [.sendAcceptOffer])
        XCTAssertEqual(panel.roleTitle, "Incoming Offer")
        XCTAssertTrue(panel.footnotes.contains { $0.contains("Decline is passive") })
    }

    func testBuildActiveOfferForCurrentPlayerShowsApplySelectedAccept() throws {
        let offer = TradeOfferV1(
            offerHash: "offer-1",
            proposer: "A",
            give: ResourceHandV1(wood: 1),
            receive: ResourceHandV1(brick: 1),
            createdRev: 8
        )
        let state = makeState(
            currentPlayer: "A",
            resourcesByPlayer: ["A": .zero, "B": .zero],
            activeTradeOffer: offer
        )
        let selectedIntent = ULS_Transport.TurnIntentV1(
            acceptTradePlayer: "B",
            offerHash: offer.offerHash,
            gameId: state.gameId,
            anchorRev: state.rev,
            anchorHash: state.stateHash,
            actor: "B"
        )

        let panel = try XCTUnwrap(
            GameTradePanelModelBuilder.build(
                state: state,
                actingAs: "A",
                selectedTurnIntent: selectedIntent
            )
        )

        XCTAssertEqual(panel.actions.map(\.kind), [.applySelectedAccept])
        XCTAssertEqual(
            panel.participantStatuses.first(where: { $0.playerID == "B" })?.detailText,
            "Selected bubble"
        )
    }

    func testBuildActiveOfferForCurrentPlayerShowsExecuteOptions() throws {
        let offer = TradeOfferV1(
            offerHash: "offer-1",
            proposer: "A",
            give: ResourceHandV1(wood: 1),
            receive: ResourceHandV1(brick: 1),
            createdRev: 8
        )
        let state = makeState(
            currentPlayer: "A",
            resourcesByPlayer: ["A": .zero, "B": .zero, "C": .zero],
            activeTradeOffer: offer,
            pendingTradeAccepts: [
                TradeAcceptV1(acceptingPlayer: "C", offerHash: offer.offerHash, acceptedAtRev: 9),
                TradeAcceptV1(acceptingPlayer: "B", offerHash: offer.offerHash, acceptedAtRev: 10),
            ]
        )

        let panel = try XCTUnwrap(
            GameTradePanelModelBuilder.build(
                state: state,
                actingAs: "A",
                selectedTurnIntent: nil
            )
        )

        XCTAssertEqual(
            panel.executeOptions.map(\.displayName),
            [
                PlayerPseudonymResolver.displayName(for: "B", gameID: state.gameId, roster: state.roster),
                PlayerPseudonymResolver.displayName(for: "C", gameID: state.gameId, roster: state.roster),
            ]
        )
        XCTAssertEqual(
            panel.acceptedPlayers,
            [
                PlayerPseudonymResolver.displayName(for: "B", gameID: state.gameId, roster: state.roster),
                PlayerPseudonymResolver.displayName(for: "C", gameID: state.gameId, roster: state.roster),
            ]
        )
        XCTAssertTrue(panel.footnotes.contains { $0.contains("end the turn") })
    }

    func testBuildActiveOfferForResponderWithoutRequiredCardsShowsNoAcceptAction() throws {
        let offer = TradeOfferV1(
            offerHash: "offer-1",
            proposer: "A",
            give: ResourceHandV1(wood: 1),
            receive: ResourceHandV1(brick: 2),
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
                actingAs: "B",
                selectedTurnIntent: nil
            )
        )

        XCTAssertTrue(panel.actions.isEmpty)
        XCTAssertTrue(panel.message.contains("cannot accept"))
    }

    private func makeState(
        currentPlayer: String,
        resourcesByPlayer: [String: ResourceHandV1],
        activeTradeOffer: TradeOfferV1? = nil,
        pendingTradeAccepts: [TradeAcceptV1] = []
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
            pendingTradeAccepts: pendingTradeAccepts,
            turnState: TurnStateV1(step: .afterRoll, lastRoll: DiceRollV1(d1: 3, d2: 4))
        ).rehashed()
    }
}
