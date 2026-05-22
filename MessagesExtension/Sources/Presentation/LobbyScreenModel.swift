struct LobbyScreenModel: Equatable {
    let showsInviteEntryHero: Bool
    let title: String
    let subtitle: String
    let warningText: String?
    let participantsTitle: String
    let participants: [LobbyParticipantSummary]
    let participantsEmptyTitle: String
    let participantsEmptySystemImage: String
    let participantsEmptyDescription: String
    let nameEditor: LobbyNameEditorModel?
    let setupOptions: LobbySetupOptionsModel?
    let inviteButton: LobbyActionButtonModel?
    let joinButton: LobbyActionButtonModel?
    let startButton: LobbyActionButtonModel?
    let helperText: String
}
