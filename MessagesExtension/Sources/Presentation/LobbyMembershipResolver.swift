import ULS_CoreGame

enum LobbyMembershipResolver {
    static func targetPlayerCount(for state: CoreGameStateV1) -> Int {
        state.targetPlayerCount ?? CoreGameStateV1.defaultTargetPlayerCount
    }

    private static func joinLimit(for state: CoreGameStateV1) -> Int {
        state.targetPlayerCount ?? CoreGameStateV1.supportedTargetPlayerCounts.upperBound
    }

    private static func rosterIsReadyToStart(_ state: CoreGameStateV1) -> Bool {
        if let targetPlayerCount = state.targetPlayerCount {
            return state.roster.count == targetPlayerCount
        }
        return state.roster.count >= CoreGameStateV1.supportedTargetPlayerCounts.lowerBound
    }

    static func canJoin(
        state: CoreGameStateV1?,
        localParticipant: String?
    ) -> Bool {
        guard
            let state,
            state.phase == .lobby,
            let localParticipant
        else {
            return false
        }

        return !state.roster.contains(localParticipant) &&
            state.roster.count < joinLimit(for: state)
    }

    static func canStart(
        state: CoreGameStateV1?,
        localParticipant: String?
    ) -> Bool {
        guard
            let state,
            state.phase == .lobby,
            let inviter = state.roster.first,
            inviter == localParticipant
        else {
            return false
        }

        return rosterIsReadyToStart(state)
    }

    static func joinedLobbyState(
        state: CoreGameStateV1?,
        localParticipant: String?,
        displayName: String? = nil
    ) -> CoreGameStateV1? {
        guard
            let state,
            state.phase == .lobby,
            let localParticipant,
            !state.roster.contains(localParticipant),
            state.roster.count < joinLimit(for: state)
        else {
            return nil
        }

        var roster = state.roster
        roster.append(localParticipant)
        var playerDisplayNamesByPlayer = state.playerDisplayNamesByPlayer
        if let normalizedName = CoreGameStateV1.normalizedPlayerDisplayName(displayName) {
            playerDisplayNamesByPlayer[localParticipant] = normalizedName
        }

        return CoreGameStateV1(
            gameId: state.gameId,
            rev: state.rev + 1,
            prevHash: state.stateHash,
            stateHash: "",
            roster: roster,
            currentPlayer: state.currentPlayer,
            targetPlayerCount: state.targetPlayerCount,
            playerDisplayNamesByPlayer: playerDisplayNamesByPlayer,
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

    static func renamedLobbyState(
        state: CoreGameStateV1?,
        localParticipant: String?,
        displayName: String?
    ) -> CoreGameStateV1? {
        guard
            let state,
            state.phase == .lobby,
            let localParticipant,
            state.roster.contains(localParticipant),
            let normalizedName = CoreGameStateV1.normalizedPlayerDisplayName(displayName),
            state.playerDisplayNamesByPlayer[localParticipant] != normalizedName
        else {
            return nil
        }

        var playerDisplayNamesByPlayer = state.playerDisplayNamesByPlayer
        playerDisplayNamesByPlayer[localParticipant] = normalizedName

        return CoreGameStateV1(
            gameId: state.gameId,
            rev: state.rev + 1,
            prevHash: state.stateHash,
            stateHash: "",
            roster: state.roster,
            currentPlayer: state.currentPlayer,
            targetPlayerCount: state.targetPlayerCount,
            playerDisplayNamesByPlayer: playerDisplayNamesByPlayer,
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
