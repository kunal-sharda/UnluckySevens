import XCTest
import ULS_CoreGame
import ULS_Transport

final class LobbyScreenModelBuilderTests: XCTestCase {
    func testBuildForHostLobbyShowsParticipantsAndStart() {
        let host = "host-player"
        let alice = "alice-player"
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
                pendingJoiners: [alice],
                contextMeta: "Source: test",
                staleWarning: "-",
                lastError: "-",
                canInvite: true,
                canJoin: false,
                canStartGame: true
            )
        )

        XCTAssertEqual(model.title, "Ready to Start")
        XCTAssertEqual(model.participants.count, 2)
        XCTAssertEqual(model.participants.first?.detailText, "Host")
        XCTAssertEqual(model.startButton?.title, "Start Game")
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
                pendingJoiners: [],
                contextMeta: "Source: test",
                staleWarning: "-",
                lastError: "-",
                canInvite: true,
                canJoin: true,
                canStartGame: false
            )
        )

        XCTAssertEqual(model.title, "Join This Game")
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
                pendingJoiners: ["guest-player"],
                contextMeta: "Source: test",
                staleWarning: "-",
                lastError: "-",
                canInvite: true,
                canJoin: false,
                canStartGame: false
            )
        )

        XCTAssertEqual(model.title, "Join Sent")
        XCTAssertEqual(model.participants.first?.displayName, "guest-pl")
        XCTAssertNil(model.joinButton)
        XCTAssertNil(model.startButton)
    }
}
