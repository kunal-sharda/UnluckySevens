import XCTest
import Messages
import ULS_CoreGame
@_spi(CompactState) import ULS_Transport
@testable import MessagesExtensionSupport

@MainActor
final class StatePublicationHandoffTests: XCTestCase {
    func testViewModelKeepsCanonicalStateOnFailureThenCommitsOnlyAcceptedRetry() throws {
        let base = snapshot()
        let next = try XCTUnwrap(LobbyMembershipResolver.joinedLobbyState(state: base, localParticipant: "B"))
        let defaults = try XCTUnwrap(UserDefaults(suiteName: UUID().uuidString))
        let model = LobbyDriverViewModel(userDefaults: defaults, tutorialState: base, tutorialActorID: "A")
        let ledger = TranscriptGameLedgerStore(userDefaults: defaults)
        var completion: ((Result<Void, Error>) -> Void)?
        model.stateHandoffForTesting = { completion = $0 }
        let envelope = EnvelopeV1(kind: .state, body: .state(payload: try CompactStateTransport.encode(next)))
        let copy = TranscriptBubbleCopyBuilder.lobbyJoin(to: next, joiningPlayer: "B")

        try model.sendStateUpdate(envelope, bubbleCopy: copy, state: next, successStatus: "Joined")
        XCTAssertTrue(model.isSendingGameUpdate)
        XCTAssertNotEqual(ledger.latestState(for: base.gameId)?.stateHash, next.stateHash)
        XCTAssertEqual(model.gameplayShellProjection.stateHash, base.stateHash)
        XCTAssertThrowsError(try model.sendStateUpdate(envelope, bubbleCopy: copy, state: next, successStatus: "Joined"))
        let failedCallback = try XCTUnwrap(completion)
        failedCallback(.failure(NSError(domain: "test-send", code: 1)))
        XCTAssertFalse(model.isSendingGameUpdate)
        XCTAssertEqual(model.gameplayShellProjection.stateHash, base.stateHash)

        try model.sendStateUpdate(envelope, bubbleCopy: copy, state: next, successStatus: "Joined")
        let retryCallback = try XCTUnwrap(completion)
        failedCallback(.success(()))
        XCTAssertTrue(model.isSendingGameUpdate, "An old callback must not resolve the retry")
        XCTAssertEqual(model.gameplayShellProjection.stateHash, base.stateHash)
        retryCallback(.success(()))
        XCTAssertFalse(model.isSendingGameUpdate)
        XCTAssertEqual(model.gameplayShellProjection.stateHash, next.stateHash)
        XCTAssertEqual(model.gameplayShellProjection.rev, String(next.rev))
        XCTAssertEqual(ledger.latestState(for: base.gameId)?.stateHash, next.stateHash)
    }

    func testAcceptedLateCallbackDoesNotRegressReceivedStateOrReopenClosedGame() throws {
        let base = snapshot()
        let sent = try XCTUnwrap(LobbyMembershipResolver.joinedLobbyState(state: base, localParticipant: "B"))
        let received = try XCTUnwrap(LobbyMembershipResolver.renamedLobbyState(state: sent, localParticipant: "B", displayName: "Blake"))
        let defaults = try XCTUnwrap(UserDefaults(suiteName: UUID().uuidString))
        let model = LobbyDriverViewModel(userDefaults: defaults, tutorialState: base, tutorialActorID: "A")
        TranscriptGameLedgerStore(userDefaults: defaults).record(
            state: base, payload: try CompactStateTransport.encode(base), localActor: "A")
        var completion: ((Result<Void, Error>) -> Void)?
        model.stateHandoffForTesting = { completion = $0 }
        let envelope = EnvelopeV1(kind: .state, body: .state(payload: try CompactStateTransport.encode(sent)))
        let copy = TranscriptBubbleCopyBuilder.lobbyJoin(to: sent, joiningPlayer: "B")
        try model.sendStateUpdate(envelope, bubbleCopy: copy, state: sent, successStatus: "Joined")
        // A received echo and its successor can arrive before the original local callback.
        for observed in [sent, received] {
            let incoming = EnvelopeV1(kind: .state, body: .state(payload: try CompactStateTransport.encode(observed)))
            let message = try TranscriptTransportSupport.buildMessage(
                encodedEnvelope: encode(incoming), caption: "Updated", summaryLabel: "Updated",
                session: MSSession(), sessionPolicy: .state(gameId: base.gameId)
            ).message
            _ = model.updateContext(conversation: nil, selectedMessage: message, trigger: .didSelect)
        }
        XCTAssertEqual(model.gameplayShellProjection.stateHash, received.stateHash)
        try XCTUnwrap(completion)(.success(()))
        XCTAssertEqual(model.gameplayShellProjection.stateHash, received.stateHash)

        try model.sendStateUpdate(envelope, bubbleCopy: copy, state: sent, successStatus: "Resent")
        model.prepareNewGame()
        try XCTUnwrap(completion)(.success(()))
        XCTAssertEqual(model.gameplayShellProjection.gameId, "-")
    }

    private func snapshot() -> CoreGameStateV1 {
        CoreGameStateV1(gameId: "handoff", rev: 0, prevHash: nil, stateHash: "",
                        roster: ["A"], currentPlayer: "A", phase: .lobby,
                        seed: nil, diceRngState: nil, resourcesByPlayer: ["A": .zero],
                        boardRules: nil, board: nil).rehashed()
    }
}
