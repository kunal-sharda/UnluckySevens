import ULS_CoreGame

enum LobbyScreenModelBuilder {
    static func build(context: LobbyScreenContext) -> LobbyScreenModel {
        let warningText = normalizedWarning(context: context)

        if let state = context.selectedState, state.phase == .lobby {
            if shouldShowHostWaitingState(context: context, state: state) {
                return buildInviteWaitingModel(context: context, state: state, warningText: warningText)
            }
            return buildLobbyStateModel(context: context, state: state, warningText: warningText)
        }

        return LobbyScreenModel(
            showsInviteEntryHero: true,
            title: "Invite Players to Unlucky Sevens",
            subtitle: "Send the first bubble into this thread to open a lobby.",
            metaText: context.contextMeta,
            warningText: warningText,
            participantsTitle: "Lobby",
            participants: [],
            participantsEmptyTitle: "No Lobby Selected",
            participantsEmptySystemImage: "person.3.sequence.fill",
            participantsEmptyDescription: "Select an invite bubble or send a new one to open the lobby.",
            inviteButton: context.canInvite
                ? LobbyActionButtonModel(
                    title: "Invite Players",
                    systemImage: "plus.message.fill",
                    isEnabled: true
                )
                : nil,
            joinButton: nil,
            startButton: nil,
            helperText: "The host sends the invite, everyone joins from the bubble, and the host starts when ready."
        )
    }

    private static func buildLobbyStateModel(
        context: LobbyScreenContext,
        state: CoreGameStateV1,
        warningText: String?
    ) -> LobbyScreenModel {
        let host = state.roster.first
        let visiblePlayers = state.roster
        let participants = participantSummaries(for: state, context: context, visiblePlayers: visiblePlayers)
        let joinedCount = participants.count
        let localActor = context.localActor
        let isLocalHost = localActor == host
        let localHasJoined = localActor.map(state.roster.contains) ?? false

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
            helperText = "Joining publishes updated lobby state immediately. The host decides when to start."
        }

        return LobbyScreenModel(
            showsInviteEntryHero: false,
            title: title,
            subtitle: subtitle,
            metaText: context.contextMeta,
            warningText: warningText,
            participantsTitle: "Joined Players",
            participants: participants,
            participantsEmptyTitle: "No Joined Players",
            participantsEmptySystemImage: "person.3.sequence.fill",
            participantsEmptyDescription: "Join from the latest lobby bubble in Messages to appear here.",
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

    private static func normalizedWarning(context: LobbyScreenContext) -> String? {
        if context.staleWarning != "-" {
            return context.staleWarning
        }
        if context.lastError != "-" {
            return context.lastError
        }
        return nil
    }

    private static func displayName(_ actor: String?, gameID: String?, roster: [String]) -> String {
        PlayerPseudonymResolver.displayName(for: actor, gameID: gameID, roster: roster)
    }

    private static func shouldShowHostWaitingState(
        context: LobbyScreenContext,
        state: CoreGameStateV1
    ) -> Bool {
        guard let localActor = context.localActor else {
            return false
        }

        return context.activeContextSource == "lastSentState"
            && state.roster.first == localActor
            && state.roster.count == 1
    }

    private static func buildInviteWaitingModel(
        context: LobbyScreenContext,
        state: CoreGameStateV1,
        warningText: String?
    ) -> LobbyScreenModel {
        LobbyScreenModel(
            showsInviteEntryHero: false,
            title: "Invite Sent",
            subtitle: "Let players join from the bubble in Messages. Reopen the latest lobby bubble when you're ready to start.",
            metaText: context.contextMeta,
            warningText: warningText,
            participantsTitle: "Waiting",
            participants: [],
            participantsEmptyTitle: "Lobby Lives in Messages",
            participantsEmptySystemImage: "ellipsis.message.fill",
            participantsEmptyDescription: "This screen is only the local post-send state. Return to the thread and reopen the latest lobby bubble after players join.",
            inviteButton: nil,
            joinButton: nil,
            startButton: nil,
            helperText: "Do not start from this post-send shell. The real lobby roster and start action only appear from the latest lobby bubble in the conversation."
        )
    }
}
