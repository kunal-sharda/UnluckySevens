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
            title: "Invite friends to play",
            subtitle: "Set up a Catan-style game in this Messages chat.",
            warningText: warningText,
            participantsTitle: "Lobby",
            participants: [],
            participantsEmptyTitle: "No Lobby Selected",
            participantsEmptySystemImage: "person.3.sequence.fill",
            participantsEmptyDescription: "Select an invite bubble or send a new one to open the lobby.",
            nameEditor: buildInviteEntryNameEditor(context: context),
            inviteButton: context.canInvite
                ? LobbyActionButtonModel(
                    title: "Create Invite",
                    systemImage: "plus.message.fill",
                    isEnabled: true
                )
                : nil,
            joinButton: nil,
            startButton: nil,
            helperText: "Everyone joins from the Messages bubble. The host starts once the table is ready."
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
        let nameEditor = buildNameEditor(context: context, state: state)

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
            subtitle = "Waiting for \(displayName(host, state: state)) to start the game."
            helperText = "You are in the pending roster for this lobby."
        } else {
            title = "Join This Game"
            subtitle = "Join now and wait for \(displayName(host, state: state)) to start."
            helperText = "Joining publishes updated lobby state immediately. The host decides when to start."
        }

        return LobbyScreenModel(
            showsInviteEntryHero: false,
            title: title,
            subtitle: subtitle,
            warningText: warningText,
            participantsTitle: "Joined Players",
            participants: participants,
            participantsEmptyTitle: "No Joined Players",
            participantsEmptySystemImage: "person.3.sequence.fill",
            participantsEmptyDescription: "Join from the latest lobby bubble in Messages to appear here.",
            nameEditor: nameEditor,
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
                displayName: displayName(player, state: state),
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

    private static func displayName(_ actor: String?, state: CoreGameStateV1) -> String {
        PlayerPseudonymResolver.displayName(for: actor, in: state)
    }

    private static func aliasFallbackName(_ actor: String, state: CoreGameStateV1) -> String {
        PlayerPseudonymResolver.displayName(
            for: actor,
            gameID: state.gameId,
            roster: state.roster,
            customNames: [:]
        )
    }

    private static func buildNameEditor(
        context: LobbyScreenContext,
        state: CoreGameStateV1
    ) -> LobbyNameEditorModel? {
        guard let localActor = context.localActor else {
            return nil
        }

        let alias = aliasFallbackName(localActor, state: state)
        if state.roster.contains(localActor) {
            return LobbyNameEditorModel(
                title: "Your Name",
                placeholder: alias,
                helperText: "Save a custom name for this table. Leave it empty to keep your alias.",
                saveButton: LobbyActionButtonModel(
                    title: "Save Name",
                    systemImage: "checkmark.circle.fill",
                    isEnabled: true
                )
            )
        }

        if context.canJoin {
            return LobbyNameEditorModel(
                title: "Your Name",
                placeholder: alias,
                helperText: "Optional. If you set a name before joining, it will publish with your join.",
                saveButton: nil
            )
        }

        return nil
    }

    private static func buildInviteEntryNameEditor(
        context: LobbyScreenContext
    ) -> LobbyNameEditorModel? {
        guard context.canInvite, context.localActor != nil else {
            return nil
        }

        return LobbyNameEditorModel(
            title: "Your name",
            placeholder: "Name at the table",
            helperText: "Shown on this table and remembered for the next invite.",
            saveButton: nil
        )
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
            warningText: warningText,
            participantsTitle: "Waiting",
            participants: [],
            participantsEmptyTitle: "Lobby Lives in Messages",
            participantsEmptySystemImage: "ellipsis.message.fill",
            participantsEmptyDescription: "This screen is only the local post-send state. Return to the thread and reopen the latest lobby bubble after players join.",
            nameEditor: nil,
            inviteButton: nil,
            joinButton: nil,
            startButton: nil,
            helperText: "Do not start from this post-send shell. The real lobby roster and start action only appear from the latest lobby bubble in the conversation."
        )
    }
}
