import ULS_CoreGame
import ULS_Transport

enum LobbyScreenModelBuilder {
    static func build(context: LobbyScreenContext) -> LobbyScreenModel {
        let warningText = normalizedWarning(context: context)

        if let state = context.selectedState, state.phase == .lobby {
            return buildLobbyStateModel(context: context, state: state, warningText: warningText)
        }

        if let joinIntent = context.selectedJoinIntent {
            return buildJoinIntentModel(context: context, joinIntent: joinIntent, warningText: warningText)
        }

        return LobbyScreenModel(
            title: "Start a New Game",
            subtitle: "Send an invite into the thread to open a lobby.",
            metaText: context.contextMeta,
            warningText: warningText,
            participantsTitle: "Lobby",
            participants: [],
            inviteButton: context.canInvite
                ? LobbyActionButtonModel(
                    title: "Invite New Game",
                    systemImage: "plus.message.fill",
                    isEnabled: true
                )
                : nil,
            joinButton: nil,
            startButton: nil,
            helperText: "The host creates the lobby, other players join, and the host starts when ready."
        )
    }

    private static func buildLobbyStateModel(
        context: LobbyScreenContext,
        state: CoreGameStateV1,
        warningText: String?
    ) -> LobbyScreenModel {
        let host = state.roster.first
        let visiblePlayers = uniquePlayers(
            state.roster + context.pendingJoiners.filter { !state.roster.contains($0) }
        )
        let participants = participantSummaries(for: state, context: context, visiblePlayers: visiblePlayers)
        let joinedCount = participants.count
        let localActor = context.localActor
        let isLocalHost = localActor == host
        let localHasJoined = localActor.map { actor in
            state.roster.contains(actor) || context.pendingJoiners.contains(actor)
        } ?? false

        let title: String
        let subtitle: String
        let helperText: String

        if context.canStartGame {
            title = "Ready to Start"
            subtitle = "\(joinedCount) players are ready. Start when you want to lock the roster."
            helperText = "Starting publishes the setup state and locks the roster."
        } else if isLocalHost {
            title = "Invite Friends"
            subtitle = "Share the invite and wait for at least one guest to join."
            helperText = "Starting stays disabled until at least two players appear in the lobby."
        } else if localHasJoined {
            title = "Joined Lobby"
            subtitle = "Waiting for \(displayName(host, gameID: state.gameId, roster: visiblePlayers)) to start the game."
            helperText = "You are in the pending roster for this lobby."
        } else {
            title = "Join This Game"
            subtitle = "Join now and wait for \(displayName(host, gameID: state.gameId, roster: visiblePlayers)) to start."
            helperText = "Joining sends a join intent immediately. The host decides when to start."
        }

        return LobbyScreenModel(
            title: title,
            subtitle: subtitle,
            metaText: context.contextMeta,
            warningText: warningText,
            participantsTitle: "Joined Players",
            participants: participants,
            inviteButton: nil,
            joinButton: context.canJoin
                ? LobbyActionButtonModel(
                    title: "Join Game",
                    systemImage: "person.badge.plus.fill",
                    isEnabled: true
                )
                : nil,
            startButton: context.canStartGame
                ? LobbyActionButtonModel(
                    title: "Start Game",
                    systemImage: "play.fill",
                    isEnabled: true
                )
                : nil,
            helperText: helperText
        )
    }

    private static func buildJoinIntentModel(
        context: LobbyScreenContext,
        joinIntent: JoinIntentV1,
        warningText: String?
    ) -> LobbyScreenModel {
        let isLocalJoin = context.localActor == joinIntent.actor
        let title = isLocalJoin ? "Join Sent" : "Join Intent"
        let subtitle = isLocalJoin
            ? "Waiting for the host to start from the invite state."
            : "\(displayName(joinIntent.actor, gameID: joinIntent.gameId, roster: lobbyRoster(context: context, joinIntent: joinIntent))) joined the lobby and is waiting for the host."

        return LobbyScreenModel(
            title: title,
            subtitle: subtitle,
            metaText: context.contextMeta,
            warningText: warningText,
            participantsTitle: "Recent Join",
            participants: [
                LobbyParticipantSummary(
                    id: joinIntent.actor,
                    displayName: displayName(joinIntent.actor, gameID: joinIntent.gameId, roster: lobbyRoster(context: context, joinIntent: joinIntent)),
                    detailText: isLocalJoin ? "You joined" : "Joined",
                    isHost: false,
                    isLocalActor: isLocalJoin
                )
            ],
            inviteButton: nil,
            joinButton: nil,
            startButton: nil,
            helperText: "Open the invite bubble to view the lobby and start the game once everyone is ready."
        )
    }

    private static func participantSummaries(
        for state: CoreGameStateV1,
        context: LobbyScreenContext,
        visiblePlayers: [String]
    ) -> [LobbyParticipantSummary] {
        let host = state.roster.first

        return visiblePlayers.map { player in
            LobbyParticipantSummary(
                id: player,
                displayName: displayName(player, gameID: state.gameId, roster: visiblePlayers),
                detailText: player == host ? "Host" : "Joined",
                isHost: player == host,
                isLocalActor: player == context.localActor
            )
        }
    }

    private static func uniquePlayers(_ players: [String]) -> [String] {
        var seen: Set<String> = []
        var result: [String] = []

        for player in players where seen.insert(player).inserted {
            result.append(player)
        }

        return result
    }

    private static func normalizedWarning(context: LobbyScreenContext) -> String? {
        if context.staleWarning != "-" {
            return context.staleWarning
        }
        if context.lastError != "-" {
            return context.lastError
        }
        return nil
    }

    private static func lobbyRoster(context: LobbyScreenContext, joinIntent: JoinIntentV1) -> [String] {
        uniquePlayers([joinIntent.actor, context.localActor] + context.pendingJoiners.map(Optional.some))
    }

    private static func displayName(_ actor: String?, gameID: String?, roster: [String]) -> String {
        PlayerPseudonymResolver.displayName(for: actor, gameID: gameID, roster: roster)
    }

    private static func uniquePlayers(_ players: [String?]) -> [String] {
        var seen: Set<String> = []
        var result: [String] = []

        for player in players.compactMap({ $0 }) where seen.insert(player).inserted {
            result.append(player)
        }

        return result
    }
}
