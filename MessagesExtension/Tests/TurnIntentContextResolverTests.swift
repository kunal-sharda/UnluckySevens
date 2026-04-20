import ULS_CoreGame
import ULS_Transport
import XCTest
@testable import MessagesExtension

final class TurnIntentContextResolverTests: XCTestCase {
    func testResolveReturnsExactAnchorMatchAndNewestBestAvailableState() {
        let anchorState = makeState(rev: 7)
        let latestState = makeState(rev: 8)
        let turnIntent = ULS_Transport.TurnIntentV1(
            acceptTradePlayer: "B",
            offerHash: "offer-1",
            gameId: anchorState.gameId,
            anchorRev: anchorState.rev,
            anchorHash: anchorState.stateHash,
            actor: "B"
        )

        let resolution = TurnIntentContextResolver.resolve(
            turnIntent: turnIntent,
            selectedState: nil,
            latestKnownStatesByGameId: [latestState.gameId: latestState],
            localLedgerState: anchorState
        )

        XCTAssertEqual(resolution.anchorMatched?.state.rev, 7)
        XCTAssertEqual(resolution.anchorMatched?.source, .localLedgerState)
        XCTAssertEqual(resolution.bestAvailable?.state.rev, 8)
        XCTAssertEqual(resolution.bestAvailable?.source, .latestKnownState)
    }

    func testShouldAutoApplyTradeResponseForCurrentPlayerAuthority() {
        let anchorState = makeState(rev: 7, currentPlayer: "A")
        let turnIntent = ULS_Transport.TurnIntentV1(
            acceptTradePlayer: "B",
            offerHash: "offer-1",
            gameId: anchorState.gameId,
            anchorRev: anchorState.rev,
            anchorHash: anchorState.stateHash,
            actor: "B"
        )

        let resolution = TurnIntentContextResolver.resolve(
            turnIntent: turnIntent,
            selectedState: anchorState,
            latestKnownStatesByGameId: [:],
            localLedgerState: nil
        )

        XCTAssertTrue(
            TurnIntentContextResolver.shouldAutoApply(
                turnIntent,
                resolution: resolution,
                localParticipant: "A"
            )
        )
    }

    func testShouldNotAutoApplyForLegacyIntentOrNonAuthorityParticipant() {
        let anchorState = makeState(rev: 7, currentPlayer: "A")
        let endTurnIntent = ULS_Transport.TurnIntentV1(
            kind: .endTurn,
            gameId: anchorState.gameId,
            anchorRev: anchorState.rev,
            anchorHash: anchorState.stateHash,
            actor: "A"
        )
        let tradeIntent = ULS_Transport.TurnIntentV1(
            acceptTradePlayer: "B",
            offerHash: "offer-1",
            gameId: anchorState.gameId,
            anchorRev: anchorState.rev,
            anchorHash: anchorState.stateHash,
            actor: "B"
        )

        let resolution = TurnIntentContextResolver.resolve(
            turnIntent: tradeIntent,
            selectedState: anchorState,
            latestKnownStatesByGameId: [:],
            localLedgerState: nil
        )

        XCTAssertFalse(
            TurnIntentContextResolver.shouldAutoApply(
                endTurnIntent,
                resolution: resolution,
                localParticipant: "B"
            )
        )
        XCTAssertFalse(
            TurnIntentContextResolver.shouldAutoApply(
                tradeIntent,
                resolution: resolution,
                localParticipant: "B"
            )
        )
        XCTAssertFalse(
            TurnIntentContextResolver.shouldPreferRecoveredState(
                endTurnIntent,
                resolution: resolution,
                localParticipant: "B"
            )
        )
    }

    func testResponderTradeResponsePrefersRecoveredStateEvenAtAnchorRevForNonAuthority() {
        let anchorState = makeState(rev: 7, currentPlayer: "A")
        let tradeIntent = ULS_Transport.TurnIntentV1(
            acceptTradePlayer: "B",
            offerHash: "offer-1",
            gameId: anchorState.gameId,
            anchorRev: anchorState.rev,
            anchorHash: anchorState.stateHash,
            actor: "B"
        )

        let resolution = TurnIntentContextResolver.resolve(
            turnIntent: tradeIntent,
            selectedState: anchorState,
            latestKnownStatesByGameId: [:],
            localLedgerState: nil
        )

        XCTAssertTrue(
            TurnIntentContextResolver.shouldPreferRecoveredState(
                tradeIntent,
                resolution: resolution,
                localParticipant: "B"
            )
        )
    }

    func testShouldAutoApplyDiscardIntentForCurrentPlayerAuthority() {
        let anchorState = makeState(rev: 7, currentPlayer: "A")
        let discardIntent = ULS_Transport.TurnIntentV1(
            submitDiscardFor: "B",
            discarded: TransportResourceHandV1(wood: 1, brick: 1),
            gameId: anchorState.gameId,
            anchorRev: anchorState.rev,
            anchorHash: anchorState.stateHash,
            actor: "B"
        )

        let resolution = TurnIntentContextResolver.resolve(
            turnIntent: discardIntent,
            selectedState: anchorState,
            latestKnownStatesByGameId: [:],
            localLedgerState: nil
        )

        XCTAssertTrue(
            TurnIntentContextResolver.shouldAutoApply(
                discardIntent,
                resolution: resolution,
                localParticipant: "A"
            )
        )
    }

    func testShouldPreferRecoveredStateForTradeResponsesWhenRecoveredStateExists() {
        let anchorState = makeState(rev: 7, currentPlayer: "A")
        let laterState = makeState(rev: 8, currentPlayer: "B")
        let tradeIntent = ULS_Transport.TurnIntentV1(
            acceptTradePlayer: "B",
            offerHash: "offer-1",
            gameId: anchorState.gameId,
            anchorRev: anchorState.rev,
            anchorHash: anchorState.stateHash,
            actor: "B"
        )

        let resolution = TurnIntentContextResolver.resolve(
            turnIntent: tradeIntent,
            selectedState: laterState,
            latestKnownStatesByGameId: [laterState.gameId: laterState],
            localLedgerState: anchorState
        )

        XCTAssertTrue(
            TurnIntentContextResolver.shouldPreferRecoveredState(
                tradeIntent,
                resolution: resolution,
                localParticipant: "C"
            )
        )
    }

    func testGenericResolveUsesOnlyMatchingGameContext() {
        let matchingState = makeState(rev: 4)
        let otherGameState = CoreGameStateV1(
            gameId: "other-game",
            rev: 99,
            prevHash: "hash-98",
            stateHash: "",
            roster: ["A", "B"],
            currentPlayer: "A",
            phase: .lobby,
            seed: 42,
            diceRngState: 99,
            robberRngState: 199,
            resourcesByPlayer: ["A": .zero, "B": .zero]
        ).rehashed()

        let resolution = TurnIntentContextResolver.resolve(
            gameId: matchingState.gameId,
            anchorRev: matchingState.rev,
            anchorHash: matchingState.stateHash,
            selectedState: otherGameState,
            latestKnownStatesByGameId: [:],
            localLedgerState: matchingState
        )

        XCTAssertEqual(resolution.anchorMatched?.state.gameId, matchingState.gameId)
        XCTAssertEqual(resolution.anchorMatched?.source, .localLedgerState)
        XCTAssertEqual(resolution.bestAvailable?.state.gameId, matchingState.gameId)
        XCTAssertEqual(resolution.bestAvailable?.state.rev, matchingState.rev)
    }

    private func makeState(
        rev: Int,
        currentPlayer: String = "A"
    ) -> CoreGameStateV1 {
        CoreGameStateV1(
            gameId: "turn-intent-context",
            rev: rev,
            prevHash: rev == 0 ? nil : "hash-\(rev - 1)",
            stateHash: "",
            roster: ["A", "B", "C"],
            currentPlayer: currentPlayer,
            phase: .turn,
            seed: 1,
            diceRngState: UInt64(rev),
            robberRngState: UInt64(rev + 10),
            resourcesByPlayer: [
                "A": ResourceHandV1(wood: 2, brick: 1),
                "B": ResourceHandV1(brick: 2),
                "C": .zero,
            ],
            activeTradeOffer: TradeOfferV1(
                offerHash: "offer-1",
                proposer: "A",
                give: ResourceHandV1(wood: 1),
                receive: ResourceHandV1(brick: 1),
                recipients: ["B"],
                createdRev: rev
            ),
            turnState: TurnStateV1(step: .afterRoll, lastRoll: DiceRollV1(d1: 3, d2: 4))
        ).rehashed()
    }
}
