import XCTest
@testable import MessagesExtension
import ULS_CoreGame

final class GamePhysicalNotPrimaryPlayerContextTests: XCTestCase {
    func testEligibleNotPrimaryContextSelectsTheProductionPhysicalLayout() {
        XCTAssertEqual(
            GameTabletopLayoutStyleResolver.resolve(
                isNormalPostRollTurn: false,
                hasNotPrimaryPlayerContext: true
            ),
            .physicalProps
        )
        XCTAssertEqual(
            GameTabletopLayoutStyleResolver.resolve(
                isNormalPostRollTurn: false,
                hasNotPrimaryPlayerContext: false
            ),
            .physicalProps
        )
    }

    func testDebugFixturesCannotOverrideProductionRouting() {
        XCTAssertEqual(
            GameTabletopLayoutStyleResolver.resolve(
                isNormalPostRollTurn: false,
                hasNotPrimaryPlayerContext: false,
                testingStyle: .physicalProps
            ),
            .physicalProps
        )
    }

    func testSetupPlacementSelectsTheProductionPhysicalLayout() {
        XCTAssertEqual(
            GameTabletopLayoutStyleResolver.resolve(
                isNormalPostRollTurn: false,
                hasNotPrimaryPlayerContext: false,
                isSetupPlacement: true
            ),
            .physicalProps
        )
    }

    func testStartOfTurnSelectsTheProductionPhysicalLayout() {
        XCTAssertEqual(
            GameTabletopLayoutStyleResolver.resolve(
                isNormalPostRollTurn: false,
                isNormalPreRollTurn: true,
                hasNotPrimaryPlayerContext: false
            ),
            .physicalProps
        )
    }

    func testForcedDiscardSelectsTheProductionPhysicalLayout() {
        XCTAssertEqual(
            GameTabletopLayoutStyleResolver.resolve(
                isNormalPostRollTurn: false,
                hasNotPrimaryPlayerContext: false,
                isForcedDiscard: true
            ),
            .physicalProps
        )
    }

    func testNeedsRollForAnotherPlayerResolvesOrdinaryWaiting() {
        let state = makeState(
            currentPlayer: "alice",
            turnState: TurnStateV1(step: .needsRoll, lastRoll: nil)
        )

        XCTAssertEqual(
            GamePhysicalNotPrimaryPlayerContext.resolve(
                state: state,
                actingAs: "host",
                tradePanel: nil,
                discardPanel: nil
            ),
            .ordinaryWaiting
        )
    }

    func testTargetedUnansweredOfferResolvesIncomingTrade() {
        let state = makeState(
            currentPlayer: "alice",
            turnState: TurnStateV1(
                step: .afterRoll,
                lastRoll: DiceRollV1(d1: 3, d2: 4)
            )
        )
        let panel = GameTradePanelModel(
            roleTitle: "Incoming Offer",
            message: "Accept, decline, or counter this offer.",
            activeOffer: GameTradeOfferSummary(
                proposerPlayerID: "alice",
                proposerDisplay: "Maya",
                giveLabel: "1 Wood",
                give: [GameHandChip(resource: .wood, count: 1)],
                receiveLabel: "1 Brick",
                receive: [GameHandChip(resource: .brick, count: 1)],
                recipientPlayerIDs: ["host"],
                recipientsLabel: "You"
            ),
            participantStatuses: [],
            responderActions: GameTradeResponderActions(
                canAccept: true,
                canDecline: true,
                canCounter: true
            ),
            maritimeOptions: [],
            pendingBannerText: nil,
            canReplaceOffer: false
        )

        XCTAssertEqual(
            GamePhysicalNotPrimaryPlayerContext.resolve(
                state: state,
                actingAs: "host",
                tradePanel: panel,
                discardPanel: nil
            ),
            .incomingTrade
        )
    }

    func testResponderActionsWithoutAnOfferRemainOrdinaryWaiting() {
        let state = makeState(
            currentPlayer: "alice",
            turnState: TurnStateV1(
                step: .afterRoll,
                lastRoll: DiceRollV1(d1: 3, d2: 4)
            )
        )
        let panel = GameTradePanelModel(
            roleTitle: "Incoming Offer",
            message: "Accept, decline, or counter this offer.",
            activeOffer: nil,
            participantStatuses: [],
            responderActions: GameTradeResponderActions(
                canAccept: true,
                canDecline: true,
                canCounter: true
            ),
            maritimeOptions: [],
            pendingBannerText: nil,
            canReplaceOffer: false
        )

        XCTAssertEqual(
            GamePhysicalNotPrimaryPlayerContext.resolve(
                state: state,
                actingAs: "host",
                tradePanel: panel,
                discardPanel: nil
            ),
            .ordinaryWaiting
        )
    }

    func testNextOrderedDiscarderDoesNotResolvePassiveContext() {
        let state = makeState(
            currentPlayer: "alice",
            turnState: TurnStateV1(
                step: .pendingDiscards,
                lastRoll: DiceRollV1(d1: 4, d2: 3),
                discardRequirementsByPlayer: ["host": 2]
            )
        )
        let panel = GameDiscardPanelModel(
            waitingPlayers: ["Kunal"],
            action: .publishDiscard(requiredCount: 2, availableHand: [])
        )

        XCTAssertNil(
            GamePhysicalNotPrimaryPlayerContext.resolve(
                state: state,
                actingAs: "host",
                tradePanel: nil,
                discardPanel: panel
            )
        )
    }

    private func makeState(
        currentPlayer: String,
        turnState: TurnStateV1
    ) -> CoreGameStateV1 {
        CoreGameStateV1(
            gameId: "not-primary-context",
            rev: 1,
            prevHash: "hash-0",
            stateHash: "",
            roster: ["host", "alice", "ben"],
            currentPlayer: currentPlayer,
            phase: .turn,
            seed: 1,
            diceRngState: 2,
            robberRngState: 3,
            resourcesByPlayer: [
                "host": ResourceHandV1(wood: 2, brick: 1),
                "alice": .zero,
                "ben": .zero,
            ],
            boardRules: BoardRulesV1(strategy: .noRedAdjacentV1),
            board: StandardBoardGeneratorV1.generate(
                boardSeed: 44,
                rules: BoardRulesV1(strategy: .noRedAdjacentV1)
            ),
            turnState: turnState
        ).rehashed()
    }
}
