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
        let participants = participantSummaries(for: state, context: context)
        let joinedCount = participants.count
        let localActor = context.localActor
        let localHasJoined = localActor.map { actor in
            state.roster.contains(actor) || context.pendingJoiners.contains(actor)
        } ?? false

        let title: String
        let subtitle: String
        let helperText: String

        if context.canStartGame {
            title = joinedCount > 1 ? "Ready to Start" : "Invite Friends"
            subtitle = joinedCount > 1
                ? "\(joinedCount) players are ready. Start when you want to lock the roster."
                : "Share the invite and start when enough players have joined."
            helperText = "Starting publishes the setup state and locks the roster."
        } else if localHasJoined {
            title = "Joined Lobby"
            subtitle = "Waiting for \(displayName(host)) to start the game."
            helperText = "You are in the pending roster for this lobby."
        } else {
            title = "Join This Game"
            subtitle = "Join now and wait for \(displayName(host)) to start."
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
            : "\(displayName(joinIntent.actor)) joined the lobby and is waiting for the host."

        return LobbyScreenModel(
            title: title,
            subtitle: subtitle,
            metaText: context.contextMeta,
            warningText: warningText,
            participantsTitle: "Recent Join",
            participants: [
                LobbyParticipantSummary(
                    id: joinIntent.actor,
                    displayName: displayName(joinIntent.actor),
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
        context: LobbyScreenContext
    ) -> [LobbyParticipantSummary] {
        let host = state.roster.first
        let orderedPlayers = uniquePlayers(
            state.roster + context.pendingJoiners.filter { !state.roster.contains($0) }
        )

        return orderedPlayers.map { player in
            LobbyParticipantSummary(
                id: player,
                displayName: displayName(player),
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

    private static func displayName(_ actor: String?) -> String {
        guard let actor else {
            return "the host"
        }
        return String(actor.prefix(8))
    }
}
