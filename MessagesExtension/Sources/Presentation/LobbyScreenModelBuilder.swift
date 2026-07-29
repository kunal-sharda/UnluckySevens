import ULS_CoreGame

enum LobbyScreenModelBuilder {
    static func transcriptSnapshot(state: CoreGameStateV1) -> LobbyScreenModel {
        build(
            context: LobbyScreenContext(
                selectedState: state,
                localActor: nil,
                activeContextSource: "transcriptSnapshot",
                staleWarning: "-",
                lastError: "-",
                canInvite: false,
                canJoin: false,
                canStartGame: false
            )
        )
    }

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
            title: "Start an Unlucky Sevens Game",
            subtitle: "",
            warningText: warningText,
            participantsTitle: "Players",
            participants: [],
            participantsEmptyTitle: "Start a Game",
            participantsEmptySystemImage: "person.3.sequence.fill",
            participantsEmptyDescription: "Send an invite to this chat.",
            nameEditor: buildInviteEntryNameEditor(context: context),
            inviteButton: context.canInvite
                ? LobbyActionButtonModel(
                    title: "Send Invite",
                    systemImage: "plus.message.fill",
                    isEnabled: true
                )
                : nil,
            joinButton: nil,
            startButton: nil,
            helperText: ""
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
        let localActor = context.localActor
        let isLocalHost = localActor == host
        let localHasJoined = localActor.map(state.roster.contains) ?? false
        let nameEditor = buildNameEditor(context: context, state: state)

        let title: String
        let subtitle: String
        let helperText: String

        if context.canStartGame {
            title = "Ready to Start"
            subtitle = ""
            helperText = ""
        } else if isLocalHost {
            title = "Waiting for Players"
            subtitle = ""
            helperText = ""
        } else if localHasJoined {
            title = "You're In"
            subtitle = "Waiting for \(displayName(host, state: state)) to start."
            helperText = ""
        } else {
            title = "Join the Table"
            subtitle = "\(displayName(host, state: state)) invited you to play Unlucky Sevens."
            helperText = ""
        }

        return LobbyScreenModel(
            showsInviteEntryHero: false,
            title: title,
            subtitle: subtitle,
            warningText: warningText,
            participantsTitle: "Players",
            participants: participants,
            participantsEmptyTitle: "No Joined Players",
            participantsEmptySystemImage: "person.3.sequence.fill",
            participantsEmptyDescription: "Players appear here as they join.",
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
                title: "Display Name",
                placeholder: alias,
                helperText: "",
                saveButton: LobbyActionButtonModel(
                    title: "Save Name",
                    systemImage: "checkmark.circle.fill",
                    isEnabled: true
                )
            )
        }

        if context.canJoin {
            return LobbyNameEditorModel(
                title: "Display Name",
                placeholder: alias,
                helperText: "",
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
            title: "Display Name",
            placeholder: "Name",
            helperText: "",
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
            subtitle: "Return to the chat. Reopen the latest invite to see who joined.",
            warningText: warningText,
            participantsTitle: "Players",
            participants: participantSummaries(for: state, context: context, visiblePlayers: state.roster),
            participantsEmptyTitle: "Waiting for Players",
            participantsEmptySystemImage: "ellipsis.message.fill",
            participantsEmptyDescription: "Players appear here as they join.",
            nameEditor: nil,
            inviteButton: nil,
            joinButton: nil,
            startButton: nil,
            helperText: ""
        )
    }
}
