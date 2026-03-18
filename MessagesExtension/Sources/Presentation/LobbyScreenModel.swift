struct LobbyScreenModel: Equatable {
    let title: String
    let subtitle: String
    let metaText: String
    let warningText: String?
    let participantsTitle: String
    let participants: [LobbyParticipantSummary]
    let inviteButton: LobbyActionButtonModel?
    let joinButton: LobbyActionButtonModel?
    let startButton: LobbyActionButtonModel?
    let helperText: String
}
