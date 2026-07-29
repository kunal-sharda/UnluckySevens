import XCTest
import ULS_CoreGame
@testable import MessagesExtension

final class TranscriptGameLedgerTests: XCTestCase {
    func testRecordStateBootstrapsLatestKnownStateAndLastActiveGame() {
        let userDefaults = makeUserDefaults()
        let store = TranscriptGameLedgerStore(userDefaults: userDefaults)
        let state = makeLobbyState(gameId: "game-1", rev: 2, roster: ["host", "guest"])
        let payload = try! encode(state)

        store.record(state: state, payload: payload)
        store.markActiveGame(state.gameId)

        let snapshot = store.bootstrapSnapshot()

        XCTAssertEqual(snapshot.latestKnownStatesByGameId[state.gameId]?.rev, 2)
        XCTAssertEqual(snapshot.lastActiveGameId, state.gameId)
        XCTAssertEqual(store.observedJoiners(for: state.gameId), ["guest"])
    }

    func testRecordJoinDeduplicatesObservedJoiners() {
        let userDefaults = makeUserDefaults()
        let store = TranscriptGameLedgerStore(userDefaults: userDefaults)

        store.recordJoin(actor: "guest-a", gameId: "game-1")
        store.recordJoin(actor: "guest-a", gameId: "game-1")
        store.recordJoin(actor: "guest-b", gameId: "game-1")

        XCTAssertEqual(store.observedJoiners(for: "game-1"), ["guest-a", "guest-b"])
    }

    func testRecordOlderStateDoesNotReplaceNewerLatestState() {
        let userDefaults = makeUserDefaults()
        let store = TranscriptGameLedgerStore(userDefaults: userDefaults)
        let newer = makeLobbyState(gameId: "game-1", rev: 3, roster: ["host", "guest-a"])
        let older = makeLobbyState(gameId: "game-1", rev: 1, roster: ["host"])

        store.record(state: newer, payload: try! encode(newer))
        store.record(state: older, payload: try! encode(older))

        XCTAssertEqual(store.latestState(for: "game-1")?.rev, 3)
        XCTAssertEqual(store.observedJoiners(for: "game-1"), ["guest-a"])
    }

    func testMostRecentStatePrefersNewestRevisionAcrossGames() {
        let userDefaults = makeUserDefaults()
        let store = TranscriptGameLedgerStore(userDefaults: userDefaults)
        let older = makeLobbyState(gameId: "game-1", rev: 1, roster: ["host"])
        let newer = makeLobbyState(gameId: "game-2", rev: 4, roster: ["host", "guest"])

        store.record(state: older, payload: try! encode(older))
        store.record(state: newer, payload: try! encode(newer))

        XCTAssertEqual(store.mostRecentState()?.gameId, "game-2")
        XCTAssertEqual(store.mostRecentState()?.rev, 4)
    }

    func testRecoveredStatesPrioritizeLastActiveGameThenNewestUpdate() {
        let userDefaults = makeUserDefaults()
        let store = TranscriptGameLedgerStore(userDefaults: userDefaults)
        let older = makeLobbyState(gameId: "game-1", rev: 2, roster: ["host", "guest-a"])
        let newer = makeLobbyState(gameId: "game-2", rev: 5, roster: ["host", "guest-b"])

        store.record(state: older, payload: try! encode(older))
        store.record(state: newer, payload: try! encode(newer))
        store.markActiveGame("game-1")

        let recovered = store.recoveredStates()

        XCTAssertEqual(recovered.map(\.state.gameId), ["game-1", "game-2"])
        XCTAssertTrue(recovered.first?.isLastActive == true)
    }

    func testRecordEqualRevisionKeepsLexicographicallyGreatestHash() {
        let userDefaults = makeUserDefaults()
        let store = TranscriptGameLedgerStore(userDefaults: userDefaults)
        let first = makeLobbyState(gameId: "game-1", rev: 3, roster: ["host"])
        let sibling = CoreGameStateV1(
            gameId: first.gameId,
            rev: first.rev,
            prevHash: first.prevHash,
            stateHash: "",
            roster: ["host", "guest"],
            currentPlayer: "host",
            phase: .lobby,
            seed: nil,
            diceRngState: nil,
            resourcesByPlayer: ["host": .zero, "guest": .zero]
        ).rehashed()

        store.record(state: first, payload: try! encode(first))
        store.record(state: sibling, payload: try! encode(sibling))

        XCTAssertEqual(
            store.latestState(for: "game-1")?.stateHash,
            max(first.stateHash, sibling.stateHash)
        )
    }

    func testArchiveRemovesStateAndClearsLastActiveGame() {
        let userDefaults = makeUserDefaults()
        let store = TranscriptGameLedgerStore(userDefaults: userDefaults)
        let state = makeLobbyState(gameId: "game-archive", rev: 1, roster: ["host"])
        store.record(state: state, payload: try! encode(state))
        store.markActiveGame(state.gameId)

        store.archive(gameId: state.gameId)

        XCTAssertNil(store.latestState(for: state.gameId))
        XCTAssertNil(store.lastActiveGameId())
    }

    func testBootstrapRemovesCorruptEntryAndRepairsIndex() {
        let userDefaults = makeUserDefaults()
        userDefaults.set(["corrupt"], forKey: "uls.gameLedger.index")
        userDefaults.set(Data("not-json".utf8), forKey: "uls.gameLedger.corrupt")
        let store = TranscriptGameLedgerStore(userDefaults: userDefaults)

        let snapshot = store.bootstrapSnapshot()

        XCTAssertTrue(snapshot.latestKnownStatesByGameId.isEmpty)
        XCTAssertEqual(userDefaults.stringArray(forKey: "uls.gameLedger.index"), [])
        XCTAssertNil(userDefaults.data(forKey: "uls.gameLedger.corrupt"))
    }

    func testBootstrapMigratesLegacyPayloadRecordToVersionedCanonicalData() throws {
        let userDefaults = makeUserDefaults()
        let state = makeLobbyState(gameId: "legacy", rev: 2, roster: ["host", "guest"])
        let legacyEntry = TranscriptGameLedgerEntry(
            schemaVersion: 1,
            gameId: state.gameId,
            latestStatePayload: try encode(state),
            latestStateRev: state.rev,
            latestStateHash: state.stateHash,
            observedJoiners: ["guest"],
            updatedAt: 42
        )
        userDefaults.set([state.gameId], forKey: "uls.gameLedger.index")
        userDefaults.set(
            try JSONEncoder().encode(legacyEntry),
            forKey: "uls.gameLedger.\(state.gameId)"
        )

        let store = TranscriptGameLedgerStore(userDefaults: userDefaults)
        let snapshot = store.bootstrapSnapshot()
        let migratedData = try XCTUnwrap(
            userDefaults.data(forKey: "uls.gameLedger.\(state.gameId)")
        )
        let migrated = try JSONDecoder().decode(
            TranscriptGameLedgerEntry.self,
            from: migratedData
        )

        XCTAssertEqual(snapshot.latestKnownStatesByGameId[state.gameId], state)
        XCTAssertEqual(migrated.schemaVersion, TranscriptGameLedgerEntry.currentSchemaVersion)
        XCTAssertNotNil(migrated.latestStateData)
        XCTAssertNil(migrated.latestStatePayload)
        XCTAssertEqual(migrated.observedJoiners, ["guest"])
    }

    func testRecordRejectsInvalidCanonicalSnapshot() throws {
        let userDefaults = makeUserDefaults()
        let store = TranscriptGameLedgerStore(userDefaults: userDefaults)
        let state = makeLobbyState(gameId: "invalid", rev: 1, roster: ["host"])
        let invalid = CoreGameStateV1(
            gameId: state.gameId,
            rev: state.rev,
            prevHash: state.prevHash,
            stateHash: "tampered",
            roster: state.roster,
            currentPlayer: state.currentPlayer,
            phase: state.phase,
            seed: state.seed,
            diceRngState: state.diceRngState,
            resourcesByPlayer: state.resourcesByPlayer
        )

        store.record(state: invalid, payload: try encode(invalid))

        XCTAssertNil(store.latestState(for: invalid.gameId))
        XCTAssertTrue(store.recoveredStates().isEmpty)
    }

    func testFinishedGameRetentionKeepsOnlyEightMostRecentResults() throws {
        let userDefaults = makeUserDefaults()
        let store = TranscriptGameLedgerStore(userDefaults: userDefaults)

        for index in 0..<10 {
            let active = makeTurnState(gameId: "finished-\(index)", rev: index + 1)
            let finished = try apply(
                intent: GameLifecycleIntentV1.endGame(anchoredTo: active),
                to: active,
                actor: "host"
            )
            store.record(state: finished, payload: try encode(finished))
        }

        let recovered = store.recoveredStates()

        XCTAssertEqual(recovered.count, 8)
        XCTAssertTrue(recovered.allSatisfy(\.isFinished))
        XCTAssertNil(store.latestState(for: "finished-0"))
        XCTAssertNil(store.latestState(for: "finished-1"))
    }

    func testFinishedPruningDoesNotRemoveActiveGames() throws {
        let userDefaults = makeUserDefaults()
        let store = TranscriptGameLedgerStore(userDefaults: userDefaults)
        let active = makeTurnState(gameId: "active-forever", rev: 1)
        store.record(state: active, payload: try encode(active))

        for index in 0..<10 {
            let turn = makeTurnState(gameId: "ended-\(index)", rev: index + 1)
            let finished = try apply(
                intent: .endGame(anchoredTo: turn),
                to: turn,
                actor: "host"
            )
            store.record(state: finished, payload: try encode(finished))
        }

        XCTAssertEqual(store.latestState(for: active.gameId), active)
        XCTAssertEqual(store.recoveredStates().filter { !$0.isFinished }.count, 1)
        XCTAssertEqual(store.recoveredStates().filter(\.isFinished).count, 8)
    }

    private func makeUserDefaults() -> UserDefaults {
        let suiteName = "TranscriptGameLedgerTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        return defaults
    }

    private func encode(_ state: CoreGameStateV1) throws -> String {
        let data = try JSONEncoder().encode(state)
        guard let payload = String(data: data, encoding: .utf8) else {
            throw NSError(domain: "TranscriptGameLedgerTests", code: 1)
        }
        return payload
    }

    private func makeLobbyState(
        gameId: String,
        rev: Int,
        roster: [String]
    ) -> CoreGameStateV1 {
        CoreGameStateV1(
            gameId: gameId,
            rev: rev,
            prevHash: rev == 0 ? nil : "hash-\(rev - 1)",
            stateHash: "",
            roster: roster,
            currentPlayer: roster.first ?? "host",
            phase: .lobby,
            seed: nil,
            diceRngState: nil,
            resourcesByPlayer: Dictionary(uniqueKeysWithValues: roster.map { ($0, .zero) }),
            boardRules: nil,
            board: nil
        ).rehashed()
    }

    private func makeTurnState(gameId: String, rev: Int) -> CoreGameStateV1 {
        CoreGameStateV1(
            gameId: gameId,
            rev: rev,
            prevHash: "hash-\(rev - 1)",
            stateHash: "",
            roster: ["host", "guest-a", "guest-b"],
            currentPlayer: "host",
            phase: .turn,
            seed: 1,
            diceRngState: 2,
            resourcesByPlayer: [
                "host": .zero,
                "guest-a": .zero,
                "guest-b": .zero,
            ],
            turnState: TurnStateV1(
                step: .afterRoll,
                lastRoll: DiceRollV1(d1: 3, d2: 4)
            )
        ).rehashed()
    }
}
