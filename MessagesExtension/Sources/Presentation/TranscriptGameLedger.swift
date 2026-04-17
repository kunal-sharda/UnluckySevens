import Foundation
import ULS_CoreGame

struct TranscriptGameLedgerEntry: Codable, Equatable {
    let gameId: String
    var latestStatePayload: String?
    var latestStateRev: Int?
    var latestStateHash: String?
    var observedJoiners: [String]
    var updatedAt: TimeInterval
}

struct TranscriptGameLedgerSnapshot {
    let latestKnownStatesByGameId: [String: CoreGameStateV1]
    let lastActiveGameId: String?
}

struct TranscriptGameLedgerRecoveredState {
    let state: CoreGameStateV1
    let updatedAt: TimeInterval
    let isLastActive: Bool
}

struct TranscriptGameLedgerStore {
    private let userDefaults: UserDefaults
    private let entryPrefix = "uls.gameLedger."
    private let indexKey = "uls.gameLedger.index"
    private let lastActiveGameIdKey = "uls.gameLedger.lastActiveGameId"

    init(userDefaults: UserDefaults) {
        self.userDefaults = userDefaults
    }

    func bootstrapSnapshot() -> TranscriptGameLedgerSnapshot {
        let gameIds = indexedGameIds()
        var latestKnownStatesByGameId: [String: CoreGameStateV1] = [:]

        for gameId in gameIds {
            if let state = latestState(for: gameId) {
                latestKnownStatesByGameId[gameId] = state
            }
        }

        return TranscriptGameLedgerSnapshot(
            latestKnownStatesByGameId: latestKnownStatesByGameId,
            lastActiveGameId: lastActiveGameId()
        )
    }

    func lastActiveGameId() -> String? {
        userDefaults.string(forKey: lastActiveGameIdKey)
    }

    func latestState(for gameId: String) -> CoreGameStateV1? {
        guard let entry = entry(for: gameId), let payload = entry.latestStatePayload else {
            return nil
        }
        return try? JSONDecoder().decode(CoreGameStateV1.self, from: Data(payload.utf8))
    }

    func mostRecentState() -> CoreGameStateV1? {
        indexedGameIds()
            .compactMap { gameId -> (CoreGameStateV1, TimeInterval)? in
                guard
                    let entry = entry(for: gameId),
                    let state = latestState(for: gameId)
                else {
                    return nil
                }
                return (state, entry.updatedAt)
            }
            .max { lhs, rhs in
                if lhs.0.rev != rhs.0.rev {
                    return lhs.0.rev < rhs.0.rev
                }
                return lhs.1 < rhs.1
            }?
            .0
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

    func record(state: CoreGameStateV1, payload: String) {
        var updatedEntry = entry(for: state.gameId) ?? TranscriptGameLedgerEntry(
            gameId: state.gameId,
            latestStatePayload: nil,
            latestStateRev: nil,
            latestStateHash: nil,
            observedJoiners: [],
            updatedAt: Date().timeIntervalSince1970
        )

        let shouldReplaceLatestState: Bool
        if let existingRev = updatedEntry.latestStateRev {
            if state.rev != existingRev {
                shouldReplaceLatestState = state.rev > existingRev
            } else {
                shouldReplaceLatestState = state.stateHash != updatedEntry.latestStateHash
            }
        } else {
            shouldReplaceLatestState = true
        }

        if shouldReplaceLatestState {
            updatedEntry.latestStatePayload = payload
            updatedEntry.latestStateRev = state.rev
            updatedEntry.latestStateHash = state.stateHash
        }

        updatedEntry.observedJoiners = orderedUnion(
            updatedEntry.observedJoiners,
            state.roster.dropFirst().map { $0 }
        )
        updatedEntry.updatedAt = Date().timeIntervalSince1970
        save(updatedEntry)
    }

    func recordJoin(actor: String, gameId: String) {
        var updatedEntry = entry(for: gameId) ?? TranscriptGameLedgerEntry(
            gameId: gameId,
            latestStatePayload: nil,
            latestStateRev: nil,
            latestStateHash: nil,
            observedJoiners: [],
            updatedAt: Date().timeIntervalSince1970
        )

        updatedEntry.observedJoiners = orderedUnion(updatedEntry.observedJoiners, [actor])
        updatedEntry.updatedAt = Date().timeIntervalSince1970
        save(updatedEntry)
    }

    func clearObservedJoiners(for gameId: String) {
        guard var updatedEntry = entry(for: gameId) else {
            return
        }
        updatedEntry.observedJoiners = []
        updatedEntry.updatedAt = Date().timeIntervalSince1970
        save(updatedEntry)
    }

    func markActiveGame(_ gameId: String?) {
        if let gameId {
            userDefaults.set(gameId, forKey: lastActiveGameIdKey)
        } else {
            userDefaults.removeObject(forKey: lastActiveGameIdKey)
        }
    }

    private func entry(for gameId: String) -> TranscriptGameLedgerEntry? {
        guard
            let data = userDefaults.data(forKey: entryKey(for: gameId)),
            let entry = try? JSONDecoder().decode(TranscriptGameLedgerEntry.self, from: data)
        else {
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

    private func indexedGameIds() -> [String] {
        userDefaults.stringArray(forKey: indexKey) ?? []
    }

    private func entryKey(for gameId: String) -> String {
        "\(entryPrefix)\(gameId)"
    }

    private func orderedUnion<S: Sequence>(
        _ base: [String],
        _ appended: S
    ) -> [String] where S.Element == String {
        var seen = Set<String>()
        var ordered: [String] = []

        for value in base {
            guard seen.insert(value).inserted else {
                continue
            }
            ordered.append(value)
        }

        for value in appended {
            guard seen.insert(value).inserted else {
                continue
            }
            ordered.append(value)
        }

        return ordered
    }
}
