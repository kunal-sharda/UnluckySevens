import ULS_CoreGame
import ULS_Transport
import XCTest
@testable import MessagesExtension

final class TradeInteractionResolverTests: XCTestCase {
    private let topology = StandardBoardTopologyV1.standard()

    func testDraftTradeOfferIntentForCurrentPlayer() {
        let state = makeState(
            currentPlayer: "A",
            resourcesByPlayer: ["A": ResourceHandV1(wood: 2, brick: 1), "B": .zero, "C": .zero]
        )

        let intent = TradeInteractionResolver.draftTradeOfferIntent(
            state: state,
            actingAs: "A",
            give: ResourceHandV1(wood: 1),
            receive: ResourceHandV1(brick: 1),
            targetPlayers: ["C", "B"]
        )

        XCTAssertEqual(
            intent,
            TurnIntentV1(
                proposeTradeGive: TransportResourceHandV1(wood: 1),
                receive: TransportResourceHandV1(brick: 1),
                targetPlayers: ["B", "C"],
                gameId: state.gameId,
                anchorRev: state.rev,
                anchorHash: state.stateHash,
                actor: "A"
            )
        )
    }

    func testDraftAcceptTradeIntentForTargetedResponder() {
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

        let intent = TradeInteractionResolver.draftAcceptTradeIntent(
            state: state,
            actingAs: "B"
        )

        XCTAssertEqual(
            intent,
            TurnIntentV1(
                acceptTradePlayer: "B",
                offerHash: offer.offerHash,
                gameId: state.gameId,
                anchorRev: state.rev,
                anchorHash: state.stateHash,
                actor: "B"
            )
        )
    }

    func testDraftDeclineTradeIntentForTargetedResponder() {
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

        let intent = TradeInteractionResolver.draftDeclineTradeIntent(
            state: state,
            actingAs: "B"
        )

        XCTAssertEqual(
            intent,
            TurnIntentV1(
                declineTradePlayer: "B",
                offerHash: offer.offerHash,
                gameId: state.gameId,
                anchorRev: state.rev,
                anchorHash: state.stateHash,
                actor: "B"
            )
        )
    }

    func testDraftCounterTradeIntentForTargetedResponder() {
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
            resourcesByPlayer: ["A": .zero, "B": ResourceHandV1(brick: 1, ore: 1)],
            activeTradeOffer: offer
        )

        let intent = TradeInteractionResolver.draftCounterTradeIntent(
            state: state,
            actingAs: "B",
            give: ResourceHandV1(brick: 1),
            receive: ResourceHandV1(ore: 1)
        )

        XCTAssertEqual(
            intent,
            TurnIntentV1(
                counterTradePlayer: "B",
                offerHash: offer.offerHash,
                counterGive: TransportResourceHandV1(brick: 1),
                receive: TransportResourceHandV1(ore: 1),
                gameId: state.gameId,
                anchorRev: state.rev,
                anchorHash: state.stateHash,
                actor: "B"
            )
        )
    }

    func testDraftAcceptTradeIntentRequiresResponderToAffordRequestedCards() {
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

        let intent = TradeInteractionResolver.draftAcceptTradeIntent(
            state: state,
            actingAs: "B"
        )

        XCTAssertNil(intent)
    }

    func testDraftMaritimeTradeIntentForOwnedPort() throws {
        let port = try XCTUnwrap(topology.ports.first)
        let portEdge = topology.edges[port.edge]
        let board = BoardSetupV1(
            resourcesByTile: [.wood] + Array(repeating: .desert, count: 18),
            numbersByTile: [5] + Array(repeating: nil, count: 18),
            portsByIndex: topology.ports.map(\.kind),
            robberTile: 1,
            generator: .randomV1,
            boardHash: ""
        ).rehashed()
        let state = CoreGameStateV1(
            gameId: "trade-maritime",
            rev: 7,
            prevHash: "hash-6",
            stateHash: "",
            roster: ["A", "B"],
            currentPlayer: "A",
            phase: .turn,
            seed: 1,
            diceRngState: 2,
            robberRngState: 3,
            resourcesByPlayer: [
                "A": ResourceHandV1(wood: 4),
                "B": .zero,
            ],
            bankResources: ResourceHandV1(wood: 19, brick: 19, sheep: 19, wheat: 19, ore: 19),
            settlementsByNode: [portEdge.a: "A"],
            boardRules: BoardRulesV1(strategy: .randomV1),
            board: board,
            turnState: TurnStateV1(step: .afterRoll, lastRoll: DiceRollV1(d1: 3, d2: 4))
        ).rehashed()

        let intent = TradeInteractionResolver.draftMaritimeTradeIntent(
            state: state,
            actingAs: "A",
            give: ResourceHandV1(wood: 3),
            receive: ResourceHandV1(brick: 1)
        )

        XCTAssertEqual(intent?.kind, .maritimeTrade)
        XCTAssertEqual(intent?.actor, "A")
    }

    private func makeState(
        currentPlayer: String,
        resourcesByPlayer: [String: ResourceHandV1],
        activeTradeOffer: TradeOfferV1? = nil,
        tradeResponses: [TradeResponseV1] = []
    ) -> CoreGameStateV1 {
        CoreGameStateV1(
            gameId: "trade-resolver",
            rev: 7,
            prevHash: "hash-6",
            stateHash: "",
            roster: Array(resourcesByPlayer.keys).sorted(),
            currentPlayer: currentPlayer,
            phase: .turn,
            seed: 2,
            diceRngState: 3,
            robberRngState: 4,
            resourcesByPlayer: resourcesByPlayer,
            activeTradeOffer: activeTradeOffer,
            tradeResponses: tradeResponses,
            turnState: TurnStateV1(step: .afterRoll, lastRoll: DiceRollV1(d1: 3, d2: 4))
        ).rehashed()
    }
}
