import ULS_CoreGame
import ULS_Transport
import XCTest
@testable import MessagesExtension

final class JoinIntentContextResolverTests: XCTestCase {
    func testResolveRecoversLobbyAndRecordsJoinerForHost() {
        let lobbyState = makeLobbyState(rev: 2, host: "host")
        let joinIntent = JoinIntentV1(
            gameId: lobbyState.gameId,
            anchorRev: lobbyState.rev,
            anchorHash: lobbyState.stateHash,
            actor: "guest"
        )

        let decision = JoinIntentContextResolver.resolve(
            joinIntent: joinIntent,
            selectedState: nil,
            latestKnownStatesByGameId: [lobbyState.gameId: lobbyState],
            cachedPublishedState: nil,
            localParticipant: "host"
        )

        XCTAssertEqual(decision.recoveredContext?.state.rev, lobbyState.rev)
        XCTAssertEqual(decision.recoveredContext?.source, .latestKnownState)
        XCTAssertTrue(decision.shouldRecordJoiner)
    }

    func testResolveRecoversLatestStateWithoutRecordingJoinerForNonHost() {
        let gameState = makeTurnState(rev: 6, currentPlayer: "host")
        let joinIntent = JoinIntentV1(
            gameId: gameState.gameId,
            anchorRev: 1,
            anchorHash: "hash-1",
            actor: "guest"
        )

        let decision = JoinIntentContextResolver.resolve(
            joinIntent: joinIntent,
            selectedState: nil,
            latestKnownStatesByGameId: [gameState.gameId: gameState],
            cachedPublishedState: nil,
            localParticipant: "guest"
        )

        XCTAssertEqual(decision.recoveredContext?.state.rev, gameState.rev)
        XCTAssertEqual(decision.recoveredContext?.source, .latestKnownState)
        XCTAssertFalse(decision.shouldRecordJoiner)
    }

    func testResolveUsesCachedPublishedStateFallbackWhenGameLedgerLookupMisses() {
        let turnState = makeTurnState(rev: 4, currentPlayer: "host")
        let joinIntent = JoinIntentV1(
            gameId: turnState.gameId,
            anchorRev: turnState.rev,
            anchorHash: turnState.stateHash,
            actor: "guest"
        )

        let decision = JoinIntentContextResolver.resolve(
            joinIntent: joinIntent,
            selectedState: nil,
            latestKnownStatesByGameId: [:],
            cachedPublishedState: turnState,
            localParticipant: "observer"
        )

        XCTAssertEqual(decision.recoveredContext?.state.rev, turnState.rev)
        XCTAssertEqual(decision.recoveredContext?.source, .cachedPublishedState)
        XCTAssertFalse(decision.shouldRecordJoiner)
    }

    private func makeLobbyState(rev: Int, host: String) -> CoreGameStateV1 {
        CoreGameStateV1(
            gameId: "join-context",
            rev: rev,
            prevHash: rev == 0 ? nil : "hash-\(rev - 1)",
            stateHash: "",
            roster: [host],
            currentPlayer: host,
            phase: .lobby,
            seed: 1,
            diceRngState: UInt64(rev),
            robberRngState: UInt64(rev + 1),
            resourcesByPlayer: [host: .zero]
        ).rehashed()
    }

    private func makeTurnState(rev: Int, currentPlayer: String) -> CoreGameStateV1 {
        CoreGameStateV1(
            gameId: "join-context",
            rev: rev,
            prevHash: rev == 0 ? nil : "hash-\(rev - 1)",
            stateHash: "",
            roster: ["host", "guest", "observer"],
            currentPlayer: currentPlayer,
            phase: .turn,
            seed: 2,
            diceRngState: UInt64(rev),
            robberRngState: UInt64(rev + 10),
            resourcesByPlayer: [
                "host": ResourceHandV1(wood: 2),
                "guest": ResourceHandV1(brick: 1),
                "observer": .zero,
            ],
            turnState: TurnStateV1(step: .afterRoll, lastRoll: DiceRollV1(d1: 3, d2: 4))
        ).rehashed()
    }
}
