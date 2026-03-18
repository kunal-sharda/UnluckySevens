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
        XCTAssertTrue(panel.actions.contains(where: { $0.kind == .publishSuggestedOffer }))
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
            resourcesByPlayer: ["A": .zero, "B": .zero],
            activeTradeOffer: offer
        )

        let panel = try XCTUnwrap(
            GameTradePanelModelBuilder.build(
                state: state,
                actingAs: "B",
                selectedTurnIntent: nil
            )
        )

        XCTAssertEqual(panel.activeOffer?.proposerDisplay, "A")
        XCTAssertEqual(panel.actions.map(\.kind), [.sendAcceptOffer])
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

        XCTAssertEqual(panel.executeOptions.map(\.playerID), ["B", "C"])
        XCTAssertEqual(panel.acceptedPlayers, ["B", "C"])
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
