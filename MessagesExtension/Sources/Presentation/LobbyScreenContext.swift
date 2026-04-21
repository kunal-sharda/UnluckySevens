import ULS_CoreGame
import ULS_Transport

struct LobbyScreenContext: Equatable {
    let selectedState: CoreGameStateV1?
    let selectedJoinIntent: JoinIntentV1?
    let localActor: String?
    let activeContextSource: String
    let contextMeta: String
    let staleWarning: String
    let lastError: String
    let canInvite: Bool
    let canJoin: Bool
    let canStartGame: Bool
}
