import XCTest
import ULS_CoreGame
@testable import MessagesExtension

final class LobbyScreenModelBuilderTests: XCTestCase {
    func testBuildForEmptyLobbyEntryShowsInviteHero() {
        let model = LobbyScreenModelBuilder.build(
            context: LobbyScreenContext(
                selectedState: nil,
                localActor: nil,
                activeContextSource: "-",
                contextMeta: "Source: test",
                staleWarning: "-",
                lastError: "-",
                canInvite: true,
                canJoin: false,
                canStartGame: false
            )
        )

        XCTAssertTrue(model.showsInviteEntryHero)
        XCTAssertEqual(model.title, "Invite Players to Unlucky Sevens")
        XCTAssertEqual(model.inviteButton?.title, "Invite Players")
        XCTAssertNil(model.joinButton)
        XCTAssertNil(model.startButton)
    }

    func testBuildForHostSelectedSinglePlayerLobbyShowsInteractiveRoster() {
        let host = "host-player"
        let state = makeLobbyState(roster: [host], currentPlayer: host, rev: 0)

        let model = LobbyScreenModelBuilder.build(
            context: LobbyScreenContext(
                selectedState: state,
                localActor: host,
                activeContextSource: "selectedBubble",
                contextMeta: "Source: test",
                staleWarning: "-",
                lastError: "-",
                canInvite: true,
                canJoin: false,
                canStartGame: false
            )
        )

        XCTAssertEqual(model.title, "Invite Friends")
        XCTAssertFalse(model.showsInviteEntryHero)
        XCTAssertEqual(model.participants.count, 1)
        XCTAssertEqual(model.participants.first?.detailText, "Host")
        XCTAssertNil(model.startButton)
        XCTAssertNil(model.joinButton)
    }

    func testBuildForStartedLobbyUsesCanonicalRosterOnly() {
        let host = "host-player"
        let alice = "alice-player"
        let state = makeLobbyState(roster: [host, alice], currentPlayer: host, rev: 1, prevHash: "hash-0")

        let model = LobbyScreenModelBuilder.build(
            context: LobbyScreenContext(
                selectedState: state,
                localActor: host,
                activeContextSource: "selectedBubble",
                contextMeta: "Source: test",
                staleWarning: "-",
                lastError: "-",
                canInvite: true,
                canJoin: false,
                canStartGame: true
            )
        )

        XCTAssertEqual(model.title, "Ready to Start")
        XCTAssertFalse(model.showsInviteEntryHero)
        XCTAssertEqual(model.participants.count, 2)
        XCTAssertEqual(Set(model.participants.map(\.displayName)).count, 2)
        XCTAssertEqual(model.startButton?.title, "Start Game")
    }

    func testBuildForHostLastSentSinglePlayerLobbyShowsPassiveWaitingShell() {
        let host = "host-player"
        let state = makeLobbyState(roster: [host], currentPlayer: host, rev: 0)

        let model = LobbyScreenModelBuilder.build(
            context: LobbyScreenContext(
                selectedState: state,
                localActor: host,
                activeContextSource: "lastSentState",
                contextMeta: "Source: test",
                staleWarning: "-",
                lastError: "-",
                canInvite: true,
                canJoin: false,
                canStartGame: false
            )
        )

        XCTAssertEqual(model.title, "Invite Sent")
        XCTAssertFalse(model.showsInviteEntryHero)
        XCTAssertNil(model.startButton)
        XCTAssertNil(model.joinButton)
    }

    func testBuildForJoinableLobbyShowsJoinAction() {
        let host = "host-player"
        let guest = "guest-player"
        let state = makeLobbyState(roster: [host], currentPlayer: host, rev: 0)

        let model = LobbyScreenModelBuilder.build(
            context: LobbyScreenContext(
                selectedState: state,
                localActor: guest,
                activeContextSource: "selectedBubble",
                contextMeta: "Source: test",
                staleWarning: "-",
                lastError: "-",
                canInvite: true,
                canJoin: true,
                canStartGame: false
            )
        )

        XCTAssertEqual(model.title, "Join This Game")
        XCTAssertFalse(model.showsInviteEntryHero)
        XCTAssertEqual(model.joinButton?.title, "Join Game")
        XCTAssertNil(model.startButton)
    }

    private func makeLobbyState(
        roster: [String],
        currentPlayer: String,
        rev: Int,
        prevHash: String? = nil
    ) -> CoreGameStateV1 {
        CoreGameStateV1(
            gameId: "game-1",
            rev: rev,
            prevHash: prevHash,
            stateHash: "",
            roster: roster,
            currentPlayer: currentPlayer,
            phase: .lobby,
            seed: nil,
            diceRngState: nil,
            resourcesByPlayer: Dictionary(uniqueKeysWithValues: roster.map { ($0, .zero) }),
            boardRules: nil,
            board: nil
        ).rehashed()
    }
}
