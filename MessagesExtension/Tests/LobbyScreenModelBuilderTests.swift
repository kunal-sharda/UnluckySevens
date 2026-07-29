import XCTest
import ULS_CoreGame
@testable import MessagesExtension

final class LobbyScreenModelBuilderTests: XCTestCase {
    func testBuildForEmptyLobbyEntryShowsInviteHero() {
        let model = LobbyScreenModelBuilder.build(
            context: LobbyScreenContext(
                selectedState: nil,
                localActor: "host-player",
                activeContextSource: "-",
                staleWarning: "-",
                lastError: "-",
                canInvite: true,
                canJoin: false,
                canStartGame: false
            )
        )

        XCTAssertTrue(model.showsInviteEntryHero)
        XCTAssertEqual(model.title, "Start an Unlucky Sevens Game")
        XCTAssertEqual(model.subtitle, "")
        XCTAssertEqual(model.inviteButton?.title, "Send Invite")
        XCTAssertEqual(model.nameEditor?.title, "Display Name")
        XCTAssertEqual(model.nameEditor?.helperText, "")
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
                staleWarning: "-",
                lastError: "-",
                canInvite: true,
                canJoin: false,
                canStartGame: false
            )
        )

        XCTAssertEqual(model.title, "Waiting for Players")
        XCTAssertEqual(model.subtitle, "")
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
                staleWarning: "-",
                lastError: "-",
                canInvite: true,
                canJoin: false,
                canStartGame: true
            )
        )

        XCTAssertEqual(model.title, "Ready to Start")
        XCTAssertEqual(model.subtitle, "")
        XCTAssertEqual(model.helperText, "")
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
                staleWarning: "-",
                lastError: "-",
                canInvite: true,
                canJoin: false,
                canStartGame: false
            )
        )

        XCTAssertEqual(model.title, "Invite Sent")
        XCTAssertEqual(model.subtitle, "Return to the chat. Reopen the latest invite to see who joined.")
        XCTAssertEqual(model.participants.count, 1)
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
                staleWarning: "-",
                lastError: "-",
                canInvite: true,
                canJoin: true,
                canStartGame: false
            )
        )

        XCTAssertEqual(model.title, "Join the Table")
        XCTAssertEqual(
            model.subtitle,
            "\(PlayerPseudonymResolver.displayName(for: host, in: state)) invited you to play Unlucky Sevens."
        )
        XCTAssertFalse(model.showsInviteEntryHero)
        XCTAssertEqual(model.joinButton?.title, "Join Game")
        XCTAssertNil(model.startButton)
    }

    func testBuildForJoinedLobbyShowsNameEditorAndCustomDisplayName() {
        let host = "host-player"
        let guest = "guest-player"
        let state = makeLobbyState(
            roster: [host, guest],
            currentPlayer: host,
            rev: 1,
            customNames: [guest: "Kunal"]
        )

        let model = LobbyScreenModelBuilder.build(
            context: LobbyScreenContext(
                selectedState: state,
                localActor: guest,
                activeContextSource: "selectedBubble",
                staleWarning: "-",
                lastError: "-",
                canInvite: true,
                canJoin: false,
                canStartGame: false
            )
        )

        XCTAssertEqual(model.participants.last?.displayName, "Kunal")
        XCTAssertEqual(model.title, "You're In")
        XCTAssertEqual(
            model.subtitle,
            "Waiting for \(PlayerPseudonymResolver.displayName(for: host, in: state)) to start."
        )
        XCTAssertEqual(model.nameEditor?.title, "Display Name")
        XCTAssertEqual(model.nameEditor?.helperText, "")
        XCTAssertEqual(model.nameEditor?.saveButton?.title, "Save Name")
    }

    private func makeLobbyState(
        roster: [String],
        currentPlayer: String,
        rev: Int,
        prevHash: String? = nil,
        customNames: [String: String] = [:]
    ) -> CoreGameStateV1 {
        CoreGameStateV1(
            gameId: "game-1",
            rev: rev,
            prevHash: prevHash,
            stateHash: "",
            roster: roster,
            currentPlayer: currentPlayer,
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
