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
                localParticipant: "guest-player"
            )
        )
    }

    func testCanJoinLobbyRejectsJoinedParticipant() {
        let state = makeLobbyState(host: "host-player")

        XCTAssertFalse(
            LobbyMembershipResolver.canJoin(
                state: state,
                localParticipant: "host-player"
            )
        )
    }

    func testCanStartLobbyRequiresInviterAsLocalParticipant() {
        let state = makeLobbyState(host: "host-player")
        let laterLobbyState = CoreGameStateV1(
            gameId: state.gameId,
            rev: 2,
            prevHash: "hash-1",
            stateHash: "",
            roster: ["host-player", "guest-player"],
            currentPlayer: "host-player",
            phase: .lobby,
            seed: nil,
            diceRngState: nil,
            resourcesByPlayer: ["host-player": .zero, "guest-player": .zero],
            boardRules: nil,
            board: nil
        ).rehashed()

        XCTAssertFalse(
            LobbyMembershipResolver.canStart(
                state: state,
                localParticipant: "host-player"
            )
        )
        XCTAssertFalse(
            LobbyMembershipResolver.canStart(
                state: state,
                localParticipant: "guest-player"
            )
        )
        XCTAssertTrue(
            LobbyMembershipResolver.canStart(
                state: laterLobbyState,
                localParticipant: "host-player"
            )
        )
    }

    func testJoinedLobbyStateUsesActualLocalParticipant() {
        let state = makeLobbyState(host: "host-player")

        let joinedState = LobbyMembershipResolver.joinedLobbyState(
            state: state,
            localParticipant: "guest-player"
        )

        XCTAssertEqual(joinedState?.gameId, state.gameId)
        XCTAssertEqual(joinedState?.rev, 1)
        XCTAssertEqual(joinedState?.prevHash, state.stateHash)
        XCTAssertEqual(joinedState?.roster, ["host-player", "guest-player"])
        XCTAssertEqual(joinedState?.currentPlayer, state.currentPlayer)
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
