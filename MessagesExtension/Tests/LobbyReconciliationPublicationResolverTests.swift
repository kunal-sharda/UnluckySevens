import XCTest
import ULS_CoreGame
@testable import MessagesExtensionSupport

final class LobbyReconciliationPublicationResolverTests: XCTestCase {
    func testHostWithBoundSessionPublishesUnresolvedSiblingClaim() throws {
        let root = makeLobby(roster: ["host"])
        let alice = try join("alice", to: root)
        let ben = try join("ben", to: root)

        let resolution = LobbyReconciliationPublicationResolver.pendingResolution(
            state: alice,
            localParticipant: "host",
            hasBoundSession: true,
            observedStates: [root, alice, ben]
        )

        XCTAssertEqual(Set(resolution?.state?.roster ?? []), ["host", "alice", "ben"])
    }

    func testGuestAndUnboundHostCannotPublish() throws {
        let root = makeLobby(roster: ["host"])
        let alice = try join("alice", to: root)
        let ben = try join("ben", to: root)
        let evidence = [root, alice, ben]

        XCTAssertNil(
            LobbyReconciliationPublicationResolver.pendingResolution(
                state: alice,
                localParticipant: "alice",
                hasBoundSession: true,
                observedStates: evidence
            )
        )
        XCTAssertNil(
            LobbyReconciliationPublicationResolver.pendingResolution(
                state: alice,
                localParticipant: "host",
                hasBoundSession: false,
                observedStates: evidence
            )
        )
    }

    func testReconciledRosterIsIdempotentAndStartedGameIsClosed() throws {
        let root = makeLobby(roster: ["host"])
        let alice = try join("alice", to: root)
        let ben = try join("ben", to: root)
        let first = try XCTUnwrap(
            LobbyReconciliationPublicationResolver.pendingResolution(
                state: alice,
                localParticipant: "host",
                hasBoundSession: true,
                observedStates: [root, alice, ben]
            )?.state
        )

        XCTAssertNil(
            LobbyReconciliationPublicationResolver.pendingResolution(
                state: first,
                localParticipant: "host",
                hasBoundSession: true,
                observedStates: [root, alice, ben, first]
            )
        )

        let started = CoreGameStateV1(
            gameId: first.gameId,
            rev: first.rev + 1,
            prevHash: first.stateHash,
            stateHash: "",
            roster: first.roster,
            currentPlayer: first.roster[0],
            phase: .setup,
            seed: 1,
            diceRngState: 2,
            resourcesByPlayer: first.resourcesByPlayer,
            setupState: initializeSetupState(roster: first.roster)
        ).rehashed()
        XCTAssertNil(
            LobbyReconciliationPublicationResolver.pendingResolution(
                state: started,
                localParticipant: "host",
                hasBoundSession: true,
                observedStates: [root, alice, ben]
            )
        )
    }

    private func join(_ actor: String, to state: CoreGameStateV1) throws -> CoreGameStateV1 {
        let joined = makeLobby(
            rev: state.rev + 1,
            prevHash: state.stateHash,
            roster: state.roster + [actor]
        )
        try validateTransition(from: state, to: joined, actor: actor)
        return joined
    }

    private func makeLobby(
        rev: Int = 0,
        prevHash: String? = nil,
        roster: [String]
    ) -> CoreGameStateV1 {
        CoreGameStateV1(
            gameId: "publication-resolver-tests",
            rev: rev,
            prevHash: prevHash,
            stateHash: "",
            roster: roster,
            currentPlayer: "host",
            phase: .lobby,
            seed: nil,
            diceRngState: nil,
            resourcesByPlayer: Dictionary(uniqueKeysWithValues: roster.map { ($0, .zero) })
        ).rehashed()
    }
}
