import ULS_CoreGame

struct LobbyScreenContext: Equatable {
    let selectedState: CoreGameStateV1?
    let localActor: String?
    let activeContextSource: String
    let staleWarning: String
    let lastError: String
    let canInvite: Bool
    let canJoin: Bool
    let canStartGame: Bool
}
