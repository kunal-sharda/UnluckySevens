import ULS_CoreGame
import ULS_Transport

enum LobbyMembershipResolver {
    static func canJoin(
        state: CoreGameStateV1?,
        localParticipant: String?,
        pendingJoiners: [String]
    ) -> Bool {
        guard
            let state,
            state.phase == .lobby,
            let localParticipant
        else {
            return false
        }

        return !state.roster.contains(localParticipant) && !pendingJoiners.contains(localParticipant)
    }

    static func canStart(
        state: CoreGameStateV1?,
        localParticipant: String?,
        pendingJoiners: [String]
    ) -> Bool {
        guard
            let state,
            state.phase == .lobby,
            let inviter = state.roster.first,
            inviter == localParticipant
        else {
            return false
        }

        return finalRoster(state: state, pendingJoiners: pendingJoiners).count >= 2
    }

    static func finalRoster(
        state: CoreGameStateV1?,
        pendingJoiners: [String]
    ) -> [String] {
        guard
            let state,
            state.phase == .lobby,
            let inviter = state.roster.first
        else {
            return []
        }

        var finalRoster: [String] = [inviter]

        for player in state.roster where player != inviter && !finalRoster.contains(player) {
            finalRoster.append(player)
        }

        for joiner in pendingJoiners where joiner != inviter && !finalRoster.contains(joiner) {
            finalRoster.append(joiner)
        }
        return finalRoster
    }

    static func joinedLobbyState(
        state: CoreGameStateV1?,
        localParticipant: String?
    ) -> CoreGameStateV1? {
        guard
            let state,
            state.phase == .lobby,
            let localParticipant,
            !state.roster.contains(localParticipant)
        else {
            return nil
        }

        var roster = state.roster
        roster.append(localParticipant)

        return CoreGameStateV1(
            gameId: state.gameId,
            rev: state.rev + 1,
            prevHash: state.stateHash,
            stateHash: "",
            roster: roster,
            currentPlayer: state.currentPlayer,
            phase: .lobby,
            seed: state.seed,
            diceRngState: state.diceRngState,
            robberRngState: state.robberRngState,
            resourcesByPlayer: state.resourcesByPlayer,
            bankResources: state.bankResources,
            devDeck: state.devDeck,
            devCardsByPlayer: state.devCardsByPlayer,
            newDevCardsByPlayer: state.newDevCardsByPlayer,
            revealedVictoryPointsByPlayer: state.revealedVictoryPointsByPlayer,
            devCardActionPlayedThisTurn: state.devCardActionPlayedThisTurn,
            knightsPlayedByPlayer: state.knightsPlayedByPlayer,
            largestArmyOwner: state.largestArmyOwner,
            largestArmySize: state.largestArmySize,
            longestRoadOwner: state.longestRoadOwner,
            longestRoadLength: state.longestRoadLength,
            winnerPlayer: state.winnerPlayer,
            winningVictoryPoints: state.winningVictoryPoints,
            auditLog: state.auditLog,
            lastTurnRecap: state.lastTurnRecap,
            activeTradeOffer: state.activeTradeOffer,
            tradeResponses: state.tradeResponses,
            settlementsByNode: state.settlementsByNode,
            citiesByNode: state.citiesByNode,
            roadsByEdge: state.roadsByEdge,
            boardRules: state.boardRules,
            board: state.board,
            setupState: state.setupState,
            turnState: state.turnState
        ).rehashed()
    }
}
