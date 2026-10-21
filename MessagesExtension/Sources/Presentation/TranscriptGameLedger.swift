import Foundation
import ULS_CoreGame
@_spi(CompactState) import ULS_Transport

struct TranscriptGameLedgerEntry: Codable, Equatable {
    static let currentSchemaVersion = 5

    let schemaVersion: Int
    let gameId: String
    var latestStateData: Data?
    var latestStatePayload: String?
    var latestStateRev: Int?
    var latestStateHash: String?
    var localActor: String?
    var observedJoiners: [String]
    var lobbyStateDataByHash: [String: Data]
    var convergenceContext: CanonicalStateConvergenceContextV1
    var updatedAt: TimeInterval

    init(
        schemaVersion: Int = Self.currentSchemaVersion,
        gameId: String,
        latestStateData: Data? = nil,
        latestStatePayload: String? = nil,
        latestStateRev: Int? = nil,
        latestStateHash: String? = nil,
        localActor: String? = nil,
        observedJoiners: [String] = [],
        lobbyStateDataByHash: [String: Data] = [:],
        convergenceContext: CanonicalStateConvergenceContextV1 = .init(),
        updatedAt: TimeInterval = Date.now.timeIntervalSince1970
    ) {
        self.schemaVersion = schemaVersion
        self.gameId = gameId
        self.latestStateData = latestStateData
        self.latestStatePayload = latestStatePayload
        self.latestStateRev = latestStateRev
        self.latestStateHash = latestStateHash
        self.localActor = localActor
        self.observedJoiners = observedJoiners
        self.lobbyStateDataByHash = lobbyStateDataByHash
        self.convergenceContext = convergenceContext
        self.updatedAt = updatedAt
    }

    private enum CodingKeys: String, CodingKey {
        case schemaVersion
        case gameId
        case latestStateData
        case latestStatePayload
        case latestStateRev
        case latestStateHash
        case localActor
        case observedJoiners
        case lobbyStateDataByHash
        case convergenceContext
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
        localActor = try values.decodeIfPresent(String.self, forKey: .localActor)
        observedJoiners = try values.decodeIfPresent([String].self, forKey: .observedJoiners) ?? []
        lobbyStateDataByHash = try values.decodeIfPresent(
            [String: Data].self,
            forKey: .lobbyStateDataByHash
        ) ?? [:]
        convergenceContext = try values.decodeIfPresent(
            CanonicalStateConvergenceContextV1.self,
            forKey: .convergenceContext
        ) ?? .init()
        updatedAt = try values.decodeIfPresent(TimeInterval.self, forKey: .updatedAt) ?? 0
    }
}

struct TranscriptGameLedgerSnapshot {
    let latestKnownStatesByGameId: [String: CoreGameStateV1]
    let convergenceContextsByGameId: [String: CanonicalStateConvergenceContextV1]
    let lastActiveGameId: String?
}

struct TranscriptGameLedgerRecoveredState {
    let state: CoreGameStateV1
    let updatedAt: TimeInterval
    let isLastActive: Bool
    let localActor: String?

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
    private let lobbyEvidenceRetentionLimit = 64

    init(userDefaults: UserDefaults) {
        self.userDefaults = userDefaults
    }

    func bootstrapSnapshot() -> TranscriptGameLedgerSnapshot {
        repairIndexAndPruneFinishedGames()
        let gameIds = indexedGameIds()
        var latestKnownStatesByGameId: [String: CoreGameStateV1] = [:]
        var convergenceContextsByGameId: [String: CanonicalStateConvergenceContextV1] = [:]

        for gameId in gameIds {
            if let state = latestState(for: gameId) {
                latestKnownStatesByGameId[gameId] = state
                convergenceContextsByGameId[gameId] = entry(for: gameId)?.convergenceContext ?? .init()
            }
        }

        let activeGameId = lastActiveGameId()
        return TranscriptGameLedgerSnapshot(
            latestKnownStatesByGameId: latestKnownStatesByGameId,
            convergenceContextsByGameId: convergenceContextsByGameId,
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
                    isLastActive: gameId == lastActiveGameId,
                    localActor: entry.localActor.flatMap {
                        state.roster.contains($0) ? $0 : nil
                    }
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

    func lobbyStates(for gameId: String) -> [CoreGameStateV1] {
        guard let entry = entry(for: gameId) else {
            return []
        }
        return entry.lobbyStateDataByHash.values
            .compactMap { try? JSONDecoder().decode(CoreGameStateV1.self, from: $0) }
            .filter { state in
                state.gameId == gameId
                    && state.phase == .lobby
                    && (try? validateCanonicalSnapshot(state)) != nil
            }
            .sorted { lhs, rhs in
                if lhs.rev != rhs.rev {
                    return lhs.rev < rhs.rev
                }
                return lhs.stateHash < rhs.stateHash
            }
    }

    func record(state: CoreGameStateV1, payload _: String, localActor: String? = nil) {
        guard (try? validateCanonicalSnapshot(state)) != nil else {
            return
        }

        let existingState = latestState(for: state.gameId)
        // Start is a causal close barrier. Once any canonical non-lobby state
        // is persisted, no later lobby snapshot may replace it or recreate
        // reconciliation evidence, regardless of revision or hash ordering.
        if let existingState, existingState.phase != .lobby, state.phase == .lobby {
            return
        }
        var updatedEntry = entry(for: state.gameId) ?? TranscriptGameLedgerEntry(gameId: state.gameId)
        var convergenceContext = updatedEntry.convergenceContext
        if let existingState {
            convergenceContext.observe(existingState)
        }
        convergenceContext.observe(state)
        updatedEntry.convergenceContext = convergenceContext
        if
            state.phase == .lobby,
            existingState?.phase == .lobby || existingState == nil,
            let data = try? JSONEncoder().encode(state)
        {
            updatedEntry.lobbyStateDataByHash[state.stateHash] = data
            updatedEntry.lobbyStateDataByHash = boundedLobbyEvidence(
                updatedEntry.lobbyStateDataByHash
            )
            updatedEntry.observedJoiners = orderedUnion(
                updatedEntry.observedJoiners,
                state.roster.dropFirst()
            )
        } else if state.phase != .lobby {
            updatedEntry.lobbyStateDataByHash = [:]
            updatedEntry.observedJoiners = []
        }
        if let localActor, state.roster.contains(localActor) {
            updatedEntry.localActor = localActor
        }

        if let existingState {
            guard shouldReplace(existingState, with: state, context: convergenceContext) else {
                updatedEntry.updatedAt = Date.now.timeIntervalSince1970
                save(updatedEntry)
                return
            }
        }

        updatedEntry = migratedEntry(updatedEntry, state: state)
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
        var lobbyStateDataByHash = entry.lobbyStateDataByHash
        if state.phase == .lobby, let data = try? JSONEncoder().encode(state) {
            lobbyStateDataByHash[state.stateHash] = data
            lobbyStateDataByHash = boundedLobbyEvidence(lobbyStateDataByHash)
        }
        return TranscriptGameLedgerEntry(
            gameId: entry.gameId,
            latestStateData: try? JSONEncoder().encode(state),
            latestStateRev: state.rev,
            latestStateHash: state.stateHash,
            localActor: entry.localActor.flatMap {
                state.roster.contains($0) ? $0 : nil
            },
            observedJoiners: entry.observedJoiners,
            lobbyStateDataByHash: lobbyStateDataByHash,
            convergenceContext: entry.convergenceContext,
            updatedAt: entry.updatedAt
        )
    }

    private func boundedLobbyEvidence(_ evidence: [String: Data]) -> [String: Data] {
        guard evidence.count > lobbyEvidenceRetentionLimit else {
            return evidence
        }
        let ordered = evidence.compactMap { hash, data -> (String, Data, CoreGameStateV1)? in
            guard let state = try? JSONDecoder().decode(CoreGameStateV1.self, from: data) else {
                return nil
            }
            return (hash, data, state)
        }
        .sorted { lhs, rhs in
            if (lhs.2.rev == 0) != (rhs.2.rev == 0) {
                return lhs.2.rev == 0
            }
            if lhs.2.rev != rhs.2.rev {
                return lhs.2.rev > rhs.2.rev
            }
            return lhs.0 > rhs.0
        }
        return Dictionary(
            uniqueKeysWithValues: ordered.prefix(lobbyEvidenceRetentionLimit).map { ($0.0, $0.1) }
        )
    }

    private func shouldReplace(
        _ existingState: CoreGameStateV1,
        with state: CoreGameStateV1,
        context: CanonicalStateConvergenceContextV1
    ) -> Bool {
        CanonicalStatePreferenceV1.prefers(state, over: existingState, context: context)
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
