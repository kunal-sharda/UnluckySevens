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
    let draftTargetPlayerCount: Int
    let draftBoardStrategy: BoardGenStrategyV1
    let draftDesertPlacement: BoardDesertPlacementV1

    init(
        selectedState: CoreGameStateV1?,
        localActor: String?,
        activeContextSource: String,
        staleWarning: String,
        lastError: String,
        canInvite: Bool,
        canJoin: Bool,
        canStartGame: Bool,
        draftTargetPlayerCount: Int = BoardStrategyDefaults.targetPlayerCount,
        draftBoardStrategy: BoardGenStrategyV1 = BoardStrategyDefaults.newGame,
        draftDesertPlacement: BoardDesertPlacementV1 = BoardStrategyDefaults.desertPlacement
    ) {
        self.selectedState = selectedState
        self.localActor = localActor
        self.activeContextSource = activeContextSource
        self.staleWarning = staleWarning
        self.lastError = lastError
        self.canInvite = canInvite
        self.canJoin = canJoin
        self.canStartGame = canStartGame
        self.draftTargetPlayerCount = CoreGameStateV1.normalizedTargetPlayerCount(draftTargetPlayerCount)
            ?? BoardStrategyDefaults.targetPlayerCount
        self.draftBoardStrategy = draftBoardStrategy
        self.draftDesertPlacement = draftDesertPlacement
    }
}
