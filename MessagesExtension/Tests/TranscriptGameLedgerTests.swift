import XCTest
import ULS_CoreGame
@testable import MessagesExtension

final class TranscriptGameLedgerTests: XCTestCase {
    func testRecordStateBootstrapsLatestKnownStateAndLastActiveGame() {
        let userDefaults = makeUserDefaults()
        var store = TranscriptGameLedgerStore(userDefaults: userDefaults)
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
}
