import ULS_CoreGame

struct TurnActionDraft: Equatable {
    let intent: TurnIntentV1
    let actor: String
    let anchorGameId: String
    let anchorRev: Int
    let anchorHash: String

    init(intent: TurnIntentV1, actor: String, state: CoreGameStateV1) {
        self.intent = intent
        self.actor = actor
        anchorGameId = state.gameId
        anchorRev = state.rev
        anchorHash = state.stateHash
    }

    func matches(_ state: CoreGameStateV1) -> Bool {
        anchorGameId == state.gameId
            && anchorRev == state.rev
            && anchorHash == state.stateHash
    }
}
