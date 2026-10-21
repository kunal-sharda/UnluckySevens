import ULS_CoreGame
import XCTest
@testable import MessagesExtensionSupport

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
            TurnActionDraft(
                intent: .proposeTrade(
                    give: ResourceHandV1(wood: 1),
                    receive: ResourceHandV1(brick: 1),
                    recipients: ["B", "C"]
                ),
                actor: "A",
                state: state
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
            resourcesByPlayer: ["A": ResourceHandV1(wood: 1), "B": ResourceHandV1(brick: 1)],
            activeTradeOffer: offer
        )

        let intent = TradeInteractionResolver.draftAcceptTradeIntent(
            state: state,
            actingAs: "B"
        )

        XCTAssertEqual(
            intent,
            TurnActionDraft(
                intent: .acceptTrade(acceptingPlayer: "B", offerHash: offer.offerHash),
                actor: "B",
                state: state
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
            resourcesByPlayer: ["A": ResourceHandV1(wood: 1), "B": ResourceHandV1(brick: 1)],
            activeTradeOffer: offer
        )

        let intent = TradeInteractionResolver.draftDeclineTradeIntent(
            state: state,
            actingAs: "B"
        )

        XCTAssertEqual(
            intent,
            TurnActionDraft(
                intent: .declineTrade(decliningPlayer: "B", offerHash: offer.offerHash),
                actor: "B",
                state: state
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
            TurnActionDraft(
                intent: .counterTrade(
                    counteringPlayer: "B",
                    offerHash: offer.offerHash,
                    give: ResourceHandV1(brick: 1),
                    receive: ResourceHandV1(ore: 1)
                ),
                actor: "B",
                state: state
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
            resourcesByPlayer: ["A": ResourceHandV1(wood: 1), "B": ResourceHandV1(brick: 1)],
            activeTradeOffer: offer
        )

        let intent = TradeInteractionResolver.draftAcceptTradeIntent(
            state: state,
            actingAs: "B"
        )

        XCTAssertNil(intent)
    }

    func testDraftAcceptTradeIntentRequiresProposerToStillFundPublishedOffer() {
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

        XCTAssertEqual(
            TradeAcceptEligibilityResolver.resolve(state: state, actingAs: "B"),
            .offerNoLongerFunded
        )
        XCTAssertNil(
            TradeInteractionResolver.draftAcceptTradeIntent(state: state, actingAs: "B")
        )
    }

    func testAcceptEligibilityDiagnosticsContainNoHandsCountsOrActorIdentity() {
        let offer = TradeOfferV1(
            offerHash: "private-offer-hash",
            proposer: "A",
            give: ResourceHandV1(wood: 7),
            receive: ResourceHandV1(brick: 9),
            recipients: ["B"],
            createdRev: 8
        )
        let state = makeState(
            currentPlayer: "A",
            resourcesByPlayer: ["A": .zero, "B": ResourceHandV1(brick: 8)],
            activeTradeOffer: offer
        )

        #if DEBUG
        let value = TradeAcceptEligibilityResolver.diagnostic(
            state: state,
            actingAs: "B"
        ).diagnosticValue

        XCTAssertEqual(value, "reason=offerNoLongerFunded;rev=7;offer=present;actor=known")
        XCTAssertFalse(value.contains("private-offer-hash"))
        XCTAssertFalse(value.contains("A"))
        XCTAssertFalse(value.contains("B"))
        XCTAssertFalse(value.contains("7 wood"))
        XCTAssertFalse(value.contains("8 brick"))
        #endif
    }

    func testAcceptEligibilityReasonsAgreeWithIntentAvailability() {
        let offer = TradeOfferV1(
            offerHash: "offer-1",
            proposer: "A",
            give: ResourceHandV1(wood: 1),
            receive: ResourceHandV1(brick: 1),
            recipients: ["B"],
            createdRev: 8
        )
        let eligible = makeState(
            currentPlayer: "A",
            resourcesByPlayer: ["A": ResourceHandV1(wood: 1), "B": ResourceHandV1(brick: 1), "C": .zero],
            activeTradeOffer: offer
        )
        let alreadyResponded = makeState(
            currentPlayer: "A",
            resourcesByPlayer: ["A": ResourceHandV1(wood: 1), "B": ResourceHandV1(brick: 1)],
            activeTradeOffer: offer,
            tradeResponses: [
                TradeResponseV1(
                    respondingPlayer: "B",
                    offerHash: offer.offerHash,
                    kind: .decline,
                    respondedAtRev: 9
                )
            ]
        )
        let cases: [(CoreGameStateV1?, String?, TradeAcceptEligibilityReason)] = [
            (nil, "B", .stateUnavailable),
            (eligible, nil, .actorUnavailable),
            (makeState(
                currentPlayer: "A",
                resourcesByPlayer: ["A": ResourceHandV1(wood: 1), "B": ResourceHandV1(brick: 1)],
                activeTradeOffer: offer,
                turnStep: .needsRoll
            ), "B", .turnUnavailable),
            (makeState(
                currentPlayer: "A",
                resourcesByPlayer: ["A": ResourceHandV1(wood: 1), "B": ResourceHandV1(brick: 1)]
            ), "B", .offerMissing),
            (eligible, "A", .responderInvalid),
            (eligible, "C", .responderNotTargeted),
            (alreadyResponded, "B", .responderAlreadyResponded),
            (makeState(
                currentPlayer: "A",
                resourcesByPlayer: ["A": .zero, "B": ResourceHandV1(brick: 1)],
                activeTradeOffer: offer
            ), "B", .offerNoLongerFunded),
            (makeState(
                currentPlayer: "A",
                resourcesByPlayer: ["A": ResourceHandV1(wood: 1), "B": .zero],
                activeTradeOffer: offer
            ), "B", .responderInsufficientResources),
            (eligible, "B", .eligible),
        ]

        for (state, actor, expectedReason) in cases {
            XCTAssertEqual(
                TradeAcceptEligibilityResolver.resolve(state: state, actingAs: actor),
                expectedReason
            )
            XCTAssertEqual(
                TradeInteractionResolver.draftAcceptTradeIntent(state: state, actingAs: actor) != nil,
                expectedReason == .eligible
            )
        }
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

        XCTAssertEqual(intent?.intent, .maritimeTrade(give: ResourceHandV1(wood: 3), receive: ResourceHandV1(brick: 1)))
        XCTAssertEqual(intent?.actor, "A")
    }

    private func makeState(
        currentPlayer: String,
        resourcesByPlayer: [String: ResourceHandV1],
        activeTradeOffer: TradeOfferV1? = nil,
        tradeResponses: [TradeResponseV1] = [],
        turnStep: TurnStepV1 = .afterRoll
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
            turnState: TurnStateV1(
                step: turnStep,
                lastRoll: turnStep == .needsRoll ? nil : DiceRollV1(d1: 3, d2: 4)
            )
        ).rehashed()
    }
}
