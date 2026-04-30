import XCTest
import ULS_CoreGame
@testable import MessagesExtension

final class LobbyMembershipResolverTests: XCTestCase {
    func testJoinedLobbyStateCarriesSubmittedDisplayName() throws {
        let host = "host"
        let guest = "guest"
        let state = makeLobbyState(roster: [host], customNames: [host: "Hosty"])

        let joined = try XCTUnwrap(
            LobbyMembershipResolver.joinedLobbyState(
                state: state,
                localParticipant: guest,
                displayName: "Kunal"
            )
        )

        XCTAssertEqual(joined.playerDisplayNamesByPlayer[host], "Hosty")
        XCTAssertEqual(joined.playerDisplayNamesByPlayer[guest], "Kunal")
    }

    func testRenamedLobbyStateUpdatesOnlyJoinedPlayerName() throws {
        let host = "host"
        let guest = "guest"
        let state = makeLobbyState(
            roster: [host, guest],
            customNames: [host: "Hosty", guest: "Guesty"]
        )

        let renamed = try XCTUnwrap(
            LobbyMembershipResolver.renamedLobbyState(
                state: state,
                localParticipant: guest,
                displayName: "Kunal"
            )
        )

        XCTAssertEqual(renamed.playerDisplayNamesByPlayer[host], "Hosty")
        XCTAssertEqual(renamed.playerDisplayNamesByPlayer[guest], "Kunal")
        XCTAssertEqual(renamed.rev, state.rev + 1)
    }

    private func makeLobbyState(
        roster: [String],
        customNames: [String: String]
    ) -> CoreGameStateV1 {
        CoreGameStateV1(
            gameId: "lobby-membership-tests",
            rev: 0,
            prevHash: nil,
            stateHash: "",
            roster: roster,
            currentPlayer: roster[0],
            playerDisplayNamesByPlayer: customNames,
            phase: .lobby,
            seed: nil,
            diceRngState: nil,
            resourcesByPlayer: Dictionary(uniqueKeysWithValues: roster.map { ($0, .zero) }),
            boardRules: nil,
            board: nil
        ).rehashed()
    }
}
