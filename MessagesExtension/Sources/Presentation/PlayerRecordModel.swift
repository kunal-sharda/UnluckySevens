import Foundation
import ULS_CoreGame

struct PlayerRecordStats: Equatable {
    let completedGames: Int
    let wins: Int
    let losses: Int
    let draws: Int
    let resignations: Int
    let fastestWinTurns: Int?
    let currentWinStreak: Int
    let longestRoadRecord: Int?
    let longestRoadTitles: Int
    let largestArmyRecord: Int?
    let largestArmyTitles: Int
    let sevenRolls: Int

    var winRateText: String {
        let decidedGames = wins + losses + draws
        guard decidedGames > 0 else { return "—" }
        return "\(Int((Double(wins) / Double(decidedGames) * 100).rounded()))%"
    }

    static let empty = PlayerRecordStats(
        completedGames: 0,
        wins: 0,
        losses: 0,
        draws: 0,
        resignations: 0,
        fastestWinTurns: nil,
        currentWinStreak: 0,
        longestRoadRecord: nil,
        longestRoadTitles: 0,
        largestArmyRecord: nil,
        largestArmyTitles: 0,
        sevenRolls: 0
    )
}

enum PlayerRecordOutcomeKind: Equatable {
    case inProgress
    case win
    case loss
    case draw
    case resigned
    case ended
    case unidentified
}

struct PlayerRecordGame: Identifiable, Equatable {
    let id: String
    let playersText: String
    let outcomeText: String
    let scoreText: String?
    let updatedText: String
    let isFinished: Bool
    let outcomeKind: PlayerRecordOutcomeKind
}

struct PlayerRecordStanding: Identifiable, Equatable {
    let id: String
    let displayName: String
    let wins: Int
    let isLocalPlayer: Bool
    let colorIndex: Int
}

struct PlayerRecordSection: Equatable {
    let stats: PlayerRecordStats
    let games: [PlayerRecordGame]
    let unidentifiedGameCount: Int
}

struct PlayerRecordModel: Equatable {
    let overall: PlayerRecordSection
    let withCurrentGroup: PlayerRecordSection
    let hasCurrentGroup: Bool
    let currentGroupNamesText: String
    let currentGroupStandings: [PlayerRecordStanding]
    let localPlayerColorIndex: Int

    static let empty = PlayerRecordModel(
        overall: PlayerRecordSection(stats: .empty, games: [], unidentifiedGameCount: 0),
        withCurrentGroup: PlayerRecordSection(stats: .empty, games: [], unidentifiedGameCount: 0),
        hasCurrentGroup: false,
        currentGroupNamesText: "These Players",
        currentGroupStandings: [],
        localPlayerColorIndex: 0
    )
}

enum PlayerRecordModelBuilder {
    static func build(
        from recoveredStates: [TranscriptGameLedgerRecoveredState],
        currentParticipantIDs: Set<String>
    ) -> PlayerRecordModel {
        let records = recoveredStates.map(Record.init)
        let groupRecords = currentParticipantIDs.isEmpty
            ? []
            : records.filter { Set($0.state.roster) == currentParticipantIDs }

        return PlayerRecordModel(
            overall: section(from: records),
            withCurrentGroup: section(from: groupRecords),
            hasCurrentGroup: !currentParticipantIDs.isEmpty,
            currentGroupNamesText: groupNames(from: groupRecords),
            currentGroupStandings: standings(from: groupRecords),
            localPlayerColorIndex: localPlayerColorIndex(in: records)
        )
    }

    private static func section(from records: [Record]) -> PlayerRecordSection {
        let identified = records.filter { $0.localActor != nil }
        let completed = identified.filter { $0.state.phase == .gameOver || $0.didResign }
        let decided = completed.filter { $0.didWin || $0.didLose || $0.didDraw }
        let roadTitles = completed.filter(\.hasLongestRoad).count
        let armyTitles = completed.filter(\.hasLargestArmy).count

        return PlayerRecordSection(
            stats: PlayerRecordStats(
                completedGames: completed.count,
                wins: completed.filter(\.didWin).count,
                losses: completed.filter(\.didLose).count,
                draws: completed.filter(\.didDraw).count,
                resignations: completed.filter(\.didResign).count,
                fastestWinTurns: completed.compactMap(\.winTurnCount).min(),
                currentWinStreak: currentWinStreak(in: decided),
                longestRoadRecord: completed.compactMap(\.longestRoadRecord).max(),
                longestRoadTitles: roadTitles,
                largestArmyRecord: completed.compactMap(\.largestArmyRecord).max(),
                largestArmyTitles: armyTitles,
                sevenRolls: identified.reduce(0) { $0 + $1.sevenRolls }
            ),
            games: records.map(makeGame),
            unidentifiedGameCount: records.count - identified.count
        )
    }

    private static func currentWinStreak(in records: [Record]) -> Int {
        records
            .sorted { $0.updatedAt > $1.updatedAt }
            .prefix { $0.didWin }
            .count
    }

    private static func groupNames(from records: [Record]) -> String {
        guard let latest = records.max(by: { $0.updatedAt < $1.updatedAt }) else {
            return "These Players"
        }
        let otherPlayers = latest.state.roster.filter { $0 != latest.localActor }
        let names = otherPlayers.map {
            PlayerPseudonymResolver.displayName(for: $0, in: latest.state)
        }
        return names.isEmpty ? "These Players" : joinedNames(names)
    }

    private static func standings(from records: [Record]) -> [PlayerRecordStanding] {
        guard let latest = records.max(by: { $0.updatedAt < $1.updatedAt }) else {
            return []
        }
        let winsByPlayer = records.reduce(into: [String: Int]()) { counts, record in
            for winner in record.state.gameResult?.winnerPlayers ?? [] {
                counts[winner, default: 0] += 1
            }
        }
        return latest.state.roster.enumerated().map { index, player in
            PlayerRecordStanding(
                id: player,
                displayName: PlayerPseudonymResolver.displayName(for: player, in: latest.state),
                wins: winsByPlayer[player, default: 0],
                isLocalPlayer: player == latest.localActor,
                colorIndex: index
            )
        }
    }

    private static func localPlayerColorIndex(in records: [Record]) -> Int {
        guard
            let latest = records
                .filter({ $0.localActor != nil })
                .max(by: { $0.updatedAt < $1.updatedAt }),
            let localActor = latest.localActor,
            let index = latest.state.roster.firstIndex(of: localActor)
        else {
            return 0
        }
        return index
    }

    private static func makeGame(from record: Record) -> PlayerRecordGame {
        let state = record.state
        let names = state.roster.map { PlayerPseudonymResolver.displayName(for: $0, in: state) }
        let outcome: String
        let outcomeKind: PlayerRecordOutcomeKind
        if record.didResign {
            outcome = state.phase == .gameOver ? "Resigned" : "Resigned · game continues"
            outcomeKind = .resigned
        } else if state.phase != .gameOver {
            outcome = "In progress · open its game bubble to continue"
            outcomeKind = .inProgress
        } else if record.localActor == nil {
            outcome = "Finished · player identity unavailable"
            outcomeKind = .unidentified
        } else if record.didWin {
            outcome = "Win"
            outcomeKind = .win
        } else if record.didDraw {
            outcome = "Draw"
            outcomeKind = .draw
        } else if record.didLose {
            outcome = "Loss"
            outcomeKind = .loss
        } else {
            outcome = "Game ended"
            outcomeKind = .ended
        }

        return PlayerRecordGame(
            id: state.gameId,
            playersText: joinedNames(names),
            outcomeText: outcome,
            scoreText: record.localScore.map { "\($0) VP" },
            updatedText: Date(timeIntervalSince1970: record.updatedAt)
                .formatted(date: .abbreviated, time: .omitted),
            isFinished: state.phase == .gameOver,
            outcomeKind: outcomeKind
        )
    }

    private static func joinedNames(_ names: [String]) -> String {
        switch names.count {
        case 0: "Unknown players"
        case 1: names[0]
        case 2: "\(names[0]) & \(names[1])"
        default: "\(names.dropLast().joined(separator: ", ")) & \(names.last ?? "")"
        }
    }

    private struct Record {
        let state: CoreGameStateV1
        let updatedAt: TimeInterval
        let localActor: String?

        init(_ recovered: TranscriptGameLedgerRecoveredState) {
            state = recovered.state
            updatedAt = recovered.updatedAt
            localActor = recovered.localActor
        }

        var localScore: Int? {
            guard let localActor else { return nil }
            return state.gameResult?.finalScoresByPlayer[localActor]
                ?? (state.phase == .gameOver || didResign
                    ? victoryPoints(for: localActor, in: state)
                    : nil)
        }

        var didWin: Bool {
            guard let localActor else { return false }
            return state.gameResult?.winnerPlayers.contains(localActor) == true
        }

        var didDraw: Bool {
            state.gameResult?.reason == .draw
        }

        var didLose: Bool {
            guard let localActor else { return false }
            if didResign { return true }
            guard state.gameResult?.reason == .victory else { return false }
            return state.gameResult?.winnerPlayers.contains(localActor) == false
        }

        var didResign: Bool {
            guard let localActor else { return false }
            return state.resignedPlayers.contains(localActor)
        }

        var winTurnCount: Int? {
            guard didWin, !state.auditLog.isEmpty else { return nil }
            let completedTurns = state.auditLog.filter { $0.action == .endTurn }.count
            return completedTurns + (state.auditLog.last?.action == .endTurn ? 0 : 1)
        }

        var hasLongestRoad: Bool {
            localActor == state.longestRoadOwner
        }

        var longestRoadRecord: Int? {
            hasLongestRoad ? state.longestRoadLength : nil
        }

        var hasLargestArmy: Bool {
            localActor == state.largestArmyOwner
        }

        var largestArmyRecord: Int? {
            hasLargestArmy ? state.largestArmySize : nil
        }

        var sevenRolls: Int {
            guard let localActor else { return 0 }
            return state.auditLog.filter {
                $0.actor == localActor && $0.action == .rollDice && $0.rollTotal == 7
            }.count
        }
    }
}
