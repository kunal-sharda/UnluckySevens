import Foundation
import ULS_CoreGame
@_spi(CompactState) import ULS_Transport

struct TranscriptGameLedgerEntry: Codable, Equatable {
    static let currentSchemaVersion = 2

    let schemaVersion: Int
    let gameId: String
    var latestStateData: Data?
    var latestStatePayload: String?
    var latestStateRev: Int?
    var latestStateHash: String?
    var observedJoiners: [String]
    var updatedAt: TimeInterval

    init(
        schemaVersion: Int = Self.currentSchemaVersion,
        gameId: String,
        latestStateData: Data? = nil,
        latestStatePayload: String? = nil,
        latestStateRev: Int? = nil,
        latestStateHash: String? = nil,
        observedJoiners: [String] = [],
        updatedAt: TimeInterval = Date.now.timeIntervalSince1970
    ) {
        self.schemaVersion = schemaVersion
        self.gameId = gameId
        self.latestStateData = latestStateData
        self.latestStatePayload = latestStatePayload
        self.latestStateRev = latestStateRev
        self.latestStateHash = latestStateHash
        self.observedJoiners = observedJoiners
        self.updatedAt = updatedAt
    }

    private enum CodingKeys: String, CodingKey {
        case schemaVersion
        case gameId
        case latestStateData
        case latestStatePayload
        case latestStateRev
        case latestStateHash
        case observedJoiners
        case updatedAt
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        schemaVersion = try values.decodeIfPresent(Int.self, forKey: .schemaVersion) ?? 1
        gameId = try values.decode(String.self, forKey: .gameId)
        latestStateData = try values.decodeIfPresent(Data.self, forKey: .latestStateData)
        latestStatePayload = try values.decodeIfPresent(String.self, forKey: .latestStatePayload)
        latestStateRev = try values.decodeIfPresent(Int.self, forKey: .latestStateRev)
        latestStateHash = try values.decodeIfPresent(String.self, forKey: .latestStateHash)
        observedJoiners = try values.decodeIfPresent([String].self, forKey: .observedJoiners) ?? []
        updatedAt = try values.decodeIfPresent(TimeInterval.self, forKey: .updatedAt) ?? 0
    }
}

struct TranscriptGameLedgerSnapshot {
    let latestKnownStatesByGameId: [String: CoreGameStateV1]
    let lastActiveGameId: String?
}

struct TranscriptGameLedgerRecoveredState {
    let state: CoreGameStateV1
    let updatedAt: TimeInterval
    let isLastActive: Bool

    var isFinished: Bool {
        state.phase == .gameOver
    }
}

struct TranscriptGameLedgerStore {
    private let userDefaults: UserDefaults
    private let entryPrefix = "uls.gameLedger."
    private let indexKey = "uls.gameLedger.index"
    private let lastActiveGameIdKey = "uls.gameLedger.lastActiveGameId"
    private let finishedGameRetentionLimit = 8

    init(userDefaults: UserDefaults) {
        self.userDefaults = userDefaults
    }

    func bootstrapSnapshot() -> TranscriptGameLedgerSnapshot {
        repairIndexAndPruneFinishedGames()
        let gameIds = indexedGameIds()
        var latestKnownStatesByGameId: [String: CoreGameStateV1] = [:]

        for gameId in gameIds {
            if let state = latestState(for: gameId) {
                latestKnownStatesByGameId[gameId] = state
            }
        }

        let activeGameId = lastActiveGameId()
        return TranscriptGameLedgerSnapshot(
            latestKnownStatesByGameId: latestKnownStatesByGameId,
            lastActiveGameId: activeGameId.flatMap {
                latestKnownStatesByGameId[$0] == nil ? nil : $0
            }
        )
    }

    func lastActiveGameId() -> String? {
        userDefaults.string(forKey: lastActiveGameIdKey)
    }

    func latestState(for gameId: String) -> CoreGameStateV1? {
        guard var entry = entry(for: gameId) else {
            return nil
        }
        guard let state = decodedState(from: entry) else {
            removeEntry(gameId)
            return nil
        }

        if entry.schemaVersion != TranscriptGameLedgerEntry.currentSchemaVersion
            || entry.latestStateData == nil
            || entry.latestStatePayload != nil
        {
            entry = migratedEntry(entry, state: state)
            save(entry)
        }
        return state
    }

    func mostRecentState() -> CoreGameStateV1? {
        recoveredStates()
            .max { lhs, rhs in
                if lhs.state.rev != rhs.state.rev {
                    return lhs.state.rev < rhs.state.rev
                }
                return lhs.updatedAt < rhs.updatedAt
            }?
            .state
    }

    func recoveredStates() -> [TranscriptGameLedgerRecoveredState] {
        let lastActiveGameId = lastActiveGameId()

        return indexedGameIds()
            .compactMap { gameId -> TranscriptGameLedgerRecoveredState? in
                guard
                    let entry = entry(for: gameId),
                    let state = latestState(for: gameId)
                else {
                    return nil
                }

                return TranscriptGameLedgerRecoveredState(
                    state: state,
                    updatedAt: entry.updatedAt,
                    isLastActive: gameId == lastActiveGameId
                )
            }
            .sorted { lhs, rhs in
                if lhs.isFinished != rhs.isFinished {
                    return !lhs.isFinished && rhs.isFinished
                }
                if lhs.isLastActive != rhs.isLastActive {
                    return lhs.isLastActive && !rhs.isLastActive
                }
                if lhs.updatedAt != rhs.updatedAt {
                    return lhs.updatedAt > rhs.updatedAt
                }
                return lhs.state.rev > rhs.state.rev
            }
    }

    func observedJoiners(for gameId: String) -> [String] {
        entry(for: gameId)?.observedJoiners ?? []
    }

    func record(state: CoreGameStateV1, payload _: String) {
        guard (try? validateCanonicalSnapshot(state)) != nil else {
            return
        }

        if let existingState = latestState(for: state.gameId) {
            guard shouldReplace(existingState, with: state) else {
                return
            }
        }
        var updatedEntry = entry(for: state.gameId) ?? TranscriptGameLedgerEntry(gameId: state.gameId)

        updatedEntry = migratedEntry(updatedEntry, state: state)
        updatedEntry.observedJoiners = orderedUnion(
            updatedEntry.observedJoiners,
            state.roster.dropFirst()
        )
        updatedEntry.updatedAt = Date.now.timeIntervalSince1970
        save(updatedEntry)
        pruneFinishedGames()
    }

    func recordJoin(actor: String, gameId: String) {
        var updatedEntry = entry(for: gameId) ?? TranscriptGameLedgerEntry(gameId: gameId)
        updatedEntry.observedJoiners = orderedUnion(updatedEntry.observedJoiners, [actor])
        updatedEntry.updatedAt = Date.now.timeIntervalSince1970
        save(updatedEntry)
    }

    func clearObservedJoiners(for gameId: String) {
        guard var updatedEntry = entry(for: gameId) else {
            return
        }
        updatedEntry.observedJoiners = []
        updatedEntry.updatedAt = Date.now.timeIntervalSince1970
        save(updatedEntry)
    }

    func archive(gameId: String) {
        removeEntry(gameId)
    }

    func markActiveGame(_ gameId: String?) {
        if let gameId {
            userDefaults.set(gameId, forKey: lastActiveGameIdKey)
        } else {
            userDefaults.removeObject(forKey: lastActiveGameIdKey)
        }
    }

    private func decodedState(from entry: TranscriptGameLedgerEntry) -> CoreGameStateV1? {
        let decoded: CoreGameStateV1?
        if let data = entry.latestStateData {
            decoded = try? JSONDecoder().decode(CoreGameStateV1.self, from: data)
        } else if let payload = entry.latestStatePayload {
            decoded = try? CompactStateTransport.decode(payload)
        } else {
            decoded = nil
        }

        guard let decoded, decoded.gameId == entry.gameId else {
            return nil
        }
        guard (try? validateCanonicalSnapshot(decoded)) != nil else {
            return nil
        }
        return decoded
    }

    private func migratedEntry(
        _ entry: TranscriptGameLedgerEntry,
        state: CoreGameStateV1
    ) -> TranscriptGameLedgerEntry {
        TranscriptGameLedgerEntry(
            gameId: entry.gameId,
            latestStateData: try? JSONEncoder().encode(state),
            latestStateRev: state.rev,
            latestStateHash: state.stateHash,
            observedJoiners: entry.observedJoiners,
            updatedAt: entry.updatedAt
        )
    }

    private func shouldReplace(
        _ existingState: CoreGameStateV1,
        with state: CoreGameStateV1
    ) -> Bool {
        if state.rev != existingState.rev {
            return state.rev > existingState.rev
        }
        return state.stateHash > existingState.stateHash
    }

    private func entry(for gameId: String) -> TranscriptGameLedgerEntry? {
        guard let data = userDefaults.data(forKey: entryKey(for: gameId)) else {
            return nil
        }
        guard let entry = try? JSONDecoder().decode(TranscriptGameLedgerEntry.self, from: data) else {
            removeEntry(gameId)
            return nil
        }
        return entry
    }

    private func save(_ entry: TranscriptGameLedgerEntry) {
        guard let data = try? JSONEncoder().encode(entry) else {
            return
        }

        userDefaults.set(data, forKey: entryKey(for: entry.gameId))

        var gameIds = indexedGameIds()
        if !gameIds.contains(entry.gameId) {
            gameIds.append(entry.gameId)
            userDefaults.set(gameIds, forKey: indexKey)
        }
    }

    private func repairIndexAndPruneFinishedGames() {
        let validGameIds = indexedGameIds().filter { gameId in
            guard entry(for: gameId) != nil, latestState(for: gameId) != nil else {
                userDefaults.removeObject(forKey: entryKey(for: gameId))
                return false
            }
            return true
        }
        userDefaults.set(validGameIds, forKey: indexKey)

        if
            let lastActiveGameId = lastActiveGameId(),
            !validGameIds.contains(lastActiveGameId)
        {
            markActiveGame(nil)
        }
        pruneFinishedGames()
    }

    private func pruneFinishedGames() {
        let finished = indexedGameIds()
            .compactMap { gameId -> (String, TimeInterval)? in
                guard
                    let entry = entry(for: gameId),
                    let state = decodedState(from: entry),
                    state.phase == .gameOver
                else {
                    return nil
                }
                return (gameId, entry.updatedAt)
            }
            .sorted { lhs, rhs in
                if lhs.1 != rhs.1 {
                    return lhs.1 > rhs.1
                }
                return lhs.0 > rhs.0
            }

        for (gameId, _) in finished.dropFirst(finishedGameRetentionLimit) {
            removeEntry(gameId)
        }
    }

    private func removeEntry(_ gameId: String) {
        userDefaults.removeObject(forKey: entryKey(for: gameId))
        let remaining = indexedGameIds().filter { $0 != gameId }
        userDefaults.set(remaining, forKey: indexKey)
        if lastActiveGameId() == gameId {
            markActiveGame(nil)
        }
    }

    private func indexedGameIds() -> [String] {
        var seen = Set<String>()
        return (userDefaults.stringArray(forKey: indexKey) ?? []).filter {
            seen.insert($0).inserted
        }
    }

    private func entryKey(for gameId: String) -> String {
        "\(entryPrefix)\(gameId)"
    }

    private func orderedUnion<S: Sequence>(
        _ base: [String],
        _ appended: S
    ) -> [String] where S.Element == String {
        var seen = Set<String>()
        return (base + Array(appended)).filter { seen.insert($0).inserted }
    }
}
