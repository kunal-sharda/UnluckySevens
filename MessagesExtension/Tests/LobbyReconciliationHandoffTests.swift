import XCTest
import Messages
import ULS_CoreGame
@_spi(CompactState) import ULS_Transport
@testable import MessagesExtensionSupport

@MainActor
final class LobbyReconciliationHandoffTests: XCTestCase {
    private func scenario() throws -> (LobbyDriverViewModel, TranscriptGameLedgerStore, CoreGameStateV1, CoreGameStateV1) {
        let root = CoreGameStateV1(gameId: "handoff-lobby", rev: 0, prevHash: nil, stateHash: "",
                                   roster: ["host"], currentPlayer: "host", phase: .lobby,
                                   seed: nil, diceRngState: nil, resourcesByPlayer: ["host": .zero]).rehashed()
        let a = try XCTUnwrap(LobbyMembershipResolver.joinedLobbyState(state: root, localParticipant: "a"))
        let b = try XCTUnwrap(LobbyMembershipResolver.joinedLobbyState(state: root, localParticipant: "b"))
        let defaults = try XCTUnwrap(UserDefaults(suiteName: UUID().uuidString))
        let ledger = TranscriptGameLedgerStore(userDefaults: defaults)
        for state in [root, a, b] { ledger.record(state: state, payload: "", localActor: "host") }
        let model = LobbyDriverViewModel(userDefaults: defaults, tutorialState: a)
        model.localParticipantForTesting = "host"
        // Bind the session through the same validated receipt path as a real selected bubble.
        let envelope = EnvelopeV1(kind: .state, body: .state(payload: try CompactStateTransport.encode(a)))
        let message = try TranscriptTransportSupport.buildMessage(encodedEnvelope: encode(envelope), caption: "Lobby",
            summaryLabel: "Lobby", session: MSSession(), sessionPolicy: .state(gameId: root.gameId)).message
        _ = model.updateContext(conversation: nil, selectedMessage: message, trigger: .didSelect)
        return (model, ledger, root, a)
    }

    func testLateReconciliationDoesNotReopenClosedGame() throws {
        let (model, _, _, anchor) = try scenario()
        var callback: ((Result<Void, Error>) -> Void)?
        model.stateHandoffForTesting = { callback = $0 }
        XCTAssertTrue(model.publishLobbyReconciliationIfNeeded(from: anchor))
        model.prepareNewGame()
        try XCTUnwrap(callback)(.success(()))
        XCTAssertEqual(model.gameplayShellProjection.gameId, "-")
        XCTAssertFalse(model.isReconcilingLobby)
    }

    func testClaimArrivingDuringReconciliationStartsFollowupWithoutAnotherHostEvent() throws {
        let (model, ledger, root, anchor) = try scenario()
        var callbacks: [(Result<Void, Error>) -> Void] = []
        model.stateHandoffForTesting = { callbacks.append($0) }
        XCTAssertTrue(model.publishLobbyReconciliationIfNeeded(from: anchor))
        let third = try XCTUnwrap(LobbyMembershipResolver.joinedLobbyState(state: root, localParticipant: "c"))
        ledger.record(state: third, payload: "", localActor: "host")
        XCTAssertFalse(model.publishLobbyReconciliationIfNeeded(from: anchor))
        callbacks[0](.success(()))
        XCTAssertEqual(callbacks.count, 2)
        XCTAssertTrue(model.isReconcilingLobby)
        callbacks[1](.success(()))
        XCTAssertFalse(model.isReconcilingLobby)
        XCTAssertEqual(Set(try XCTUnwrap(ledger.latestState(for: root.gameId)).roster), ["host", "a", "b", "c"])
    }

    func testLateLobbyCallbackPreservesReceivedSetupAndDoesNotReportPersistenceFailure() throws {
        let (model, ledger, root, anchor) = try scenario()
        var callback: ((Result<Void, Error>) -> Void)?
        model.stateHandoffForTesting = { callback = $0 }
        XCTAssertTrue(model.publishLobbyReconciliationIfNeeded(from: anchor))
        let union = try XCTUnwrap(reconcileLobbyV1(anchor: anchor, observedStates: ledger.lobbyStates(for: root.gameId), actor: "host").state)
        let setup = initializeSetupState(roster: union.roster)
        let started = CoreGameStateV1(gameId: union.gameId, rev: union.rev + 1, prevHash: union.stateHash,
            stateHash: "", roster: union.roster, currentPlayer: setup.order[0], phase: .setup,
            seed: 1, diceRngState: 2, resourcesByPlayer: union.resourcesByPlayer, setupState: setup).rehashed()
        try validateCanonicalSnapshot(started)
        try receive(started, model: model)
        XCTAssertEqual(model.gameplayShellProjection.stateHash, started.stateHash)
        try XCTUnwrap(callback)(.success(()))
        XCTAssertEqual(model.gameplayShellProjection.stateHash, started.stateHash)
        XCTAssertEqual(model.lastError, "-")
        XCTAssertFalse(model.isReconcilingLobby)
    }

    func testFreshGuestCanOpenLatestJoinedBubbleWithoutGenesis() throws {
        let (_, _, root, joined) = try scenario()
        let defaults = try XCTUnwrap(UserDefaults(suiteName: UUID().uuidString))
        let model = LobbyDriverViewModel(userDefaults: defaults)
        model.localParticipantForTesting = "new-guest"
        try receive(joined, model: model, trigger: .didSelect)
        XCTAssertEqual(model.gameplayShellProjection.stateHash, joined.stateHash)
        XCTAssertTrue(model.canJoin)
        XCTAssertNotEqual(root.stateHash, joined.stateHash)
    }

    func testReconciliationReceivedBeforeClaimsIsRetriedWhenEvidenceArrives() throws {
        let (_, _, root, a) = try scenario()
        let b = try XCTUnwrap(LobbyMembershipResolver.joinedLobbyState(state: root, localParticipant: "b"))
        let c = try XCTUnwrap(LobbyMembershipResolver.joinedLobbyState(state: root, localParticipant: "c"))
        let union = try XCTUnwrap(reconcileLobbyV1(anchor: a, observedStates: [root, a, b, c], actor: "host").state)
        let defaults = try XCTUnwrap(UserDefaults(suiteName: UUID().uuidString))
        let model = LobbyDriverViewModel(userDefaults: defaults)
        model.localParticipantForTesting = "a"
        try receive(root, model: model, trigger: .didSelect)
        try receive(a, model: model)
        try receive(union, model: model)
        XCTAssertNotEqual(model.gameplayShellProjection.stateHash, union.stateHash)
        try receive(b, model: model)
        XCTAssertNotEqual(model.gameplayShellProjection.stateHash, union.stateHash)
        try receive(c, model: model)
        XCTAssertEqual(model.gameplayShellProjection.stateHash, union.stateHash)
    }

    private func receive(_ state: CoreGameStateV1, model: LobbyDriverViewModel,
                         trigger: TranscriptSelectionTrigger = .didReceive) throws {
        let envelope = EnvelopeV1(kind: .state, body: .state(payload: try CompactStateTransport.encode(state)))
        let message = try TranscriptTransportSupport.buildMessage(encodedEnvelope: encode(envelope), caption: "Lobby",
            summaryLabel: "Lobby", session: MSSession(), sessionPolicy: .state(gameId: state.gameId)).message
        _ = model.updateContext(conversation: nil, selectedMessage: message, trigger: trigger)
    }

    func testInvalidatedTransactionIgnoresOldCallback() throws {
        var transaction = LobbyReconciliationPublicationTransaction()
        let first = try XCTUnwrap(transaction.begin(gameId: "first", anchorHash: "a", targetHash: "b", frontierDigest: "c"))
        transaction.invalidate()
        let second = try XCTUnwrap(transaction.begin(gameId: "second", anchorHash: "d", targetHash: "e", frontierDigest: "f"))
        XCTAssertEqual(transaction.resolveSend(attemptID: first.id, outcome: .succeeded), .ignore)
        XCTAssertEqual(transaction.activeAttempt, second)
    }
}
