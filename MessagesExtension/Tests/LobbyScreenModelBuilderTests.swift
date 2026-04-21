import XCTest
import ULS_CoreGame
import ULS_Transport
@testable import MessagesExtension

final class LobbyScreenModelBuilderTests: XCTestCase {
    func testBuildForEmptyLobbyEntryShowsInviteHero() {
        let model = LobbyScreenModelBuilder.build(
            context: LobbyScreenContext(
                selectedState: nil,
                selectedJoinIntent: nil,
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
        let state = CoreGameStateV1(
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

        let model = LobbyScreenModelBuilder.build(
            context: LobbyScreenContext(
                selectedState: state,
                selectedJoinIntent: nil,
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
        let state = CoreGameStateV1(
            gameId: "game-1",
            rev: 1,
            prevHash: "hash-0",
            stateHash: "",
            roster: [host, alice],
            currentPlayer: host,
            phase: .lobby,
            seed: nil,
            diceRngState: nil,
            resourcesByPlayer: [host: .zero, alice: .zero],
            boardRules: nil,
            board: nil
        ).rehashed()

        let model = LobbyScreenModelBuilder.build(
            context: LobbyScreenContext(
                selectedState: state,
                selectedJoinIntent: nil,
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
        let state = CoreGameStateV1(
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

        let model = LobbyScreenModelBuilder.build(
            context: LobbyScreenContext(
                selectedState: state,
                selectedJoinIntent: nil,
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
        let state = CoreGameStateV1(
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

        let model = LobbyScreenModelBuilder.build(
            context: LobbyScreenContext(
                selectedState: state,
                selectedJoinIntent: nil,
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

    func testBuildForJoinIntentShowsWaitingCopy() {
        let intent = JoinIntentV1(
            gameId: "game-1",
            anchorRev: 0,
            anchorHash: "hash",
            actor: "guest-player"
        )

        let model = LobbyScreenModelBuilder.build(
            context: LobbyScreenContext(
                selectedState: nil,
                selectedJoinIntent: intent,
                localActor: "guest-player",
                activeContextSource: "-",
                contextMeta: "Source: test",
                staleWarning: "-",
                lastError: "-",
                canInvite: true,
                canJoin: false,
                canStartGame: false
            )
        )

        XCTAssertEqual(model.title, "Join Sent")
        XCTAssertFalse(model.showsInviteEntryHero)
        XCTAssertEqual(
            model.participants.first?.displayName,
            PlayerPseudonymResolver.displayName(for: "guest-player", gameID: intent.gameId, roster: ["guest-player"])
        )
        XCTAssertNil(model.joinButton)
        XCTAssertNil(model.startButton)
    }

    func testBuildForJoinIntentUsesUniqueAliasWithinVisibleLobbyPlayers() {
        let intent = JoinIntentV1(
            gameId: "game-1",
            anchorRev: 0,
            anchorHash: "hash",
            actor: "guest-two"
        )

        let model = LobbyScreenModelBuilder.build(
            context: LobbyScreenContext(
                selectedState: nil,
                selectedJoinIntent: intent,
                localActor: "host-player",
                activeContextSource: "-",
                contextMeta: "Source: test",
                staleWarning: "-",
                lastError: "-",
                canInvite: true,
                canJoin: false,
                canStartGame: false
            )
        )

        XCTAssertEqual(model.participants.count, 1)
        XCTAssertNotEqual(
            model.participants[0].displayName,
            PlayerPseudonymResolver.displayName(
                for: "host-player",
                gameID: intent.gameId,
                roster: ["guest-two", "host-player"]
            )
        )
    }

    func testBuildForHostPostSendInviteShowsPassiveWaitingShell() {
        let host = "host-player"
        let state = CoreGameStateV1(
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

        let model = LobbyScreenModelBuilder.build(
            context: LobbyScreenContext(
                selectedState: state,
                selectedJoinIntent: nil,
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
        XCTAssertEqual(model.participants.count, 0)
        XCTAssertEqual(model.participantsEmptyTitle, "Lobby Lives in Messages")
        XCTAssertNil(model.joinButton)
        XCTAssertNil(model.startButton)
        XCTAssertTrue(model.helperText.contains("latest lobby bubble"))
    }
}
