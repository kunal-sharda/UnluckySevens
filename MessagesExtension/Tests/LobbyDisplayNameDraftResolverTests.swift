import XCTest
import ULS_CoreGame
@testable import MessagesExtensionSupport

final class LobbyDisplayNameDraftResolverTests: XCTestCase {
    func testResolveUsesPreferredNameBeforeJoin() {
        let state = makeLobbyState(roster: ["host"], customNames: [:])

        let resolved = LobbyDisplayNameDraftResolver.resolve(
            state: state,
            localParticipant: "guest",
            preferredDisplayName: "Kunal"
        )

        XCTAssertEqual(resolved, "Kunal")
    }

    func testResolveUsesCanonicalNameForJoinedPlayer() {
        let state = makeLobbyState(
            roster: ["host", "guest"],
            customNames: ["guest": "Guesty"]
        )

        let resolved = LobbyDisplayNameDraftResolver.resolve(
            state: state,
            localParticipant: "guest",
            preferredDisplayName: "Kunal"
        )

        XCTAssertEqual(resolved, "Guesty")
    }

    func testResolveFallsBackToBlankForJoinedPlayerWithoutCanonicalName() {
        let state = makeLobbyState(
            roster: ["host", "guest"],
            customNames: [:]
        )

        let resolved = LobbyDisplayNameDraftResolver.resolve(
            state: state,
            localParticipant: "guest",
            preferredDisplayName: "Kunal"
        )

        XCTAssertEqual(resolved, "")
    }

    func testResolveFallsBackToPreferredNameOutsideLobbyContext() {
        let resolved = LobbyDisplayNameDraftResolver.resolve(
            state: nil,
            localParticipant: nil,
            preferredDisplayName: "Kunal"
        )

        XCTAssertEqual(resolved, "Kunal")
    }

    private func makeLobbyState(
        roster: [String],
        customNames: [String: String]
    ) -> CoreGameStateV1 {
        CoreGameStateV1(
            gameId: "lobby-display-name-draft-resolver-tests",
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
