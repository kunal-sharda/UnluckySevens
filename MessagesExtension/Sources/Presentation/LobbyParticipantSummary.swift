struct LobbyParticipantSummary: Identifiable, Equatable {
    let id: String
    let displayName: String
    let detailText: String
    let isHost: Bool
    let isLocalActor: Bool
}
