import ULS_CoreGame

enum GameEndScreenModelBuilder {
    static func build(
        state: CoreGameStateV1?,
        gameInfo: GameInfoModel,
        winnerTitle: String
    ) -> GameEndScreenModel? {
        guard
            let state,
            state.phase == .gameOver,
            let result = state.gameResult
        else {
            return nil
        }
        let winnerIDs = Set(result.winnerPlayers)

        let rosterOrder = Dictionary(
            uniqueKeysWithValues: state.roster.enumerated().map { ($0.element, $0.offset) }
        )
        let players = gameInfo.players
            .map { player in
                GameEndScorePlayer(
                    id: player.id,
                    displayName: player.displayName,
                    playerTint: player.playerTint,
                    victoryPoints: player.victoryPoints,
                    isWinner: winnerIDs.contains(player.id),
                    isLocalPlayer: player.isLocalPlayer,
                    awardLabels: player.awardLabels,
                    scoreBreakdown: scoreBreakdown(for: player.id, in: state)
                )
            }
            .sorted { lhs, rhs in
                if lhs.isWinner != rhs.isWinner {
                    return lhs.isWinner
                }
                if lhs.victoryPoints != rhs.victoryPoints {
                    return lhs.victoryPoints > rhs.victoryPoints
                }
                return rosterOrder[lhs.id, default: .max]
                    < rosterOrder[rhs.id, default: .max]
            }
        let localPlayerID = players.first(where: \.isLocalPlayer)?.id

        return GameEndScreenModel(
            winnerTitle: winnerTitle,
            winningScoreText: winningScoreText(for: result, players: players),
            resultDetail: resultDetail(for: result, in: state),
            players: players,
            localDevelopmentCardGroups: localPlayerID.map {
                playedDevelopmentCards(for: $0, in: state)
            } ?? [],
            recapText: closingSummary(
                for: result,
                in: state,
                localPlayerID: localPlayerID
            )
        )
    }

    private static func winningScoreText(
        for result: GameResultV1,
        players: [GameEndScorePlayer]
    ) -> String? {
        guard result.reason == .victory else {
            return nil
        }
        let winningScore = players
            .filter(\.isWinner)
            .map(\.victoryPoints)
            .max() ?? 0
        return "\(winningScore) points"
    }

    private static func playedDevelopmentCards(
        for player: String,
        in state: CoreGameStateV1
    ) -> [GameEndDevelopmentCardGroup] {
        let playerActions = state.auditLog
            .filter { $0.actor == player }
            .map(\.action)
        let auditCounts = Dictionary(
            grouping: playerActions.compactMap(developmentCardKind(for:)),
            by: \.self
        )
        .mapValues(\.count)
        let counts: [(GameDevCardVisualKind, Int)] = [
            (
                .knight,
                max(
                    auditCounts[.knight, default: 0],
                    state.knightsPlayedByPlayer[player, default: 0]
                )
            ),
            (.monopoly, auditCounts[.monopoly, default: 0]),
            (.yearOfPlenty, auditCounts[.yearOfPlenty, default: 0]),
            (.roadBuilding, auditCounts[.roadBuilding, default: 0]),
            (
                .victoryPoint,
                max(
                    auditCounts[.victoryPoint, default: 0],
                    state.revealedVictoryPointsByPlayer[player, default: 0]
                )
            ),
        ]

        return counts.compactMap { kind, count in
            guard count > 0 else { return nil }
            return GameEndDevelopmentCardGroup(kind: kind, count: count)
        }
    }

    private static func scoreBreakdown(
        for player: String,
        in state: CoreGameStateV1
    ) -> GameEndScoreBreakdown {
        let settlementPoints = state.settlementsByNode.values.filter { $0 == player }.count
        let cityPoints = state.citiesByNode.values.filter { $0 == player }.count * 2
        return GameEndScoreBreakdown(
            buildingPoints: settlementPoints + cityPoints,
            developmentCardPoints: state.revealedVictoryPointsByPlayer[player, default: 0],
            largestArmyPoints: state.largestArmyOwner == player ? 2 : 0,
            longestRoadPoints: state.longestRoadOwner == player ? 2 : 0
        )
    }

    private static func closingSummary(
        for result: GameResultV1,
        in state: CoreGameStateV1,
        localPlayerID: String?
    ) -> String? {
        guard result.reason == .victory else {
            return resultDetail(for: result, in: state)
        }
        guard result.winnerPlayers.count == 1, let winner = result.winnerPlayers.first else {
            return result.winnerPlayers.isEmpty ? nil : "The game finished in a tie."
        }

        guard
            let recap = state.lastTurnRecap,
            recap.actor == winner,
            let decisiveAction = recap.actions.reversed().first(where: isDecisiveAction)
        else {
            return nil
        }

        let noun = decisiveNoun(for: decisiveAction)
        if winner == localPlayerID {
            let localNoun = noun.prefix(1).uppercased() + String(noun.dropFirst())
            return "\(localNoun) sealed the win."
        }
        let winnerName = PlayerPseudonymResolver.displayName(for: winner, in: state)
        return "\(winnerName)'s \(noun) sealed the win."
    }

    private static func isDecisiveAction(_ action: AuditActionV1) -> Bool {
        switch action {
        case .buildCity, .buildSettlement, .revealVictoryPoint, .playKnight, .buildRoad:
            return true
        default:
            return false
        }
    }

    private static func decisiveNoun(for action: AuditActionV1) -> String {
        switch action {
        case .buildCity:
            return "city"
        case .buildSettlement:
            return "settlement"
        case .revealVictoryPoint:
            return "victory point"
        case .playKnight:
            return "Knight"
        case .buildRoad:
            return "road"
        default:
            return "final turn"
        }
    }

    private static func developmentCardKind(
        for action: AuditActionV1
    ) -> GameDevCardVisualKind? {
        switch action {
        case .playKnight:
            return .knight
        case .playMonopoly:
            return .monopoly
        case .playYearOfPlenty:
            return .yearOfPlenty
        case .playRoadBuilding:
            return .roadBuilding
        case .revealVictoryPoint:
            return .victoryPoint
        default:
            return nil
        }
    }

    private static func resultDetail(
        for result: GameResultV1,
        in state: CoreGameStateV1
    ) -> String? {
        switch result.reason {
        case .victory:
            return nil
        case .draw:
            return "Draw agreed by all active players"
        case .hostEnded:
            guard let host = result.endedByPlayer else {
                return "Game ended by host"
            }
            return "Ended by \(PlayerPseudonymResolver.displayName(for: host, in: state))"
        }
    }
}
