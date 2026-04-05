import XCTest
import ULS_CoreGame
@testable import MessagesExtension

@MainActor
final class LobbyDriverViewModelIdentityTests: XCTestCase {
    func testCanJoinLobbyUsesActualLocalParticipant() {
        let state = makeLobbyState(host: "host-player")

        XCTAssertTrue(
            LobbyMembershipResolver.canJoin(
                state: state,
                localParticipant: "guest-player",
                pendingJoiners: []
            )
        )
    }

    func testCanJoinLobbyRejectsJoinedOrPendingParticipant() {
        let state = makeLobbyState(host: "host-player")

        XCTAssertFalse(
            LobbyMembershipResolver.canJoin(
                state: state,
                localParticipant: "host-player",
                pendingJoiners: []
            )
        )
        XCTAssertFalse(
            LobbyMembershipResolver.canJoin(
                state: state,
                localParticipant: "guest-player",
                pendingJoiners: ["guest-player"]
            )
        )
    }

    func testCanStartLobbyRequiresInviterAsLocalParticipant() {
        let state = makeLobbyState(host: "host-player")

        XCTAssertFalse(
            LobbyMembershipResolver.canStart(
                state: state,
                localParticipant: "host-player",
                pendingJoiners: []
            )
        )
        XCTAssertTrue(
            LobbyMembershipResolver.canStart(
                state: state,
                localParticipant: "host-player",
                pendingJoiners: ["guest-player"]
            )
        )
        XCTAssertFalse(
            LobbyMembershipResolver.canStart(
                state: state,
                localParticipant: "guest-player",
                pendingJoiners: ["guest-player"]
            )
        )
    }

    func testFinalLobbyRosterDeduplicatesJoinersAndKeepsInviterFirst() {
        let state = makeLobbyState(host: "host-player")

        XCTAssertEqual(
            LobbyMembershipResolver.finalRoster(
                state: state,
                pendingJoiners: ["host-player", "guest-player", "guest-player", "guest-two"]
            ),
            ["host-player", "guest-player", "guest-two"]
        )
    }

    private func makeLobbyState(host: String) -> CoreGameStateV1 {
        CoreGameStateV1(
            gameId: "game-1",
            rev: 0,
            prevHash: nil,
            stateHash: "",
            roster: [host],
            currentPlayer: host,
            phase: .lobby,
            seed: nil,
            diceRngState: nil,
            resourcesByPlayer: [host: .zero],
            boardRules: nil,
            board: nil
        ).rehashed()
    }
}
