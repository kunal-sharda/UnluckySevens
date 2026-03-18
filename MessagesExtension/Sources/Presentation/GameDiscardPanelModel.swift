struct GameDiscardPanelModel: Equatable {
    enum Action: Equatable {
        case publishSuggestedDiscard(requiredCount: Int, suggested: [GameHandChip])
        case sendSuggestedDiscard(requiredCount: Int, suggested: [GameHandChip])
        case applySelectedDiscard(playerDisplay: String, suggested: [GameHandChip])
    }

    let waitingPlayers: [String]
    let action: Action?
}
