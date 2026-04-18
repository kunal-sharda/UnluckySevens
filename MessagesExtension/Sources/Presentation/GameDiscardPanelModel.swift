struct GameDiscardPanelModel: Equatable {
    enum Action: Equatable {
        case publishDiscard(requiredCount: Int, availableHand: [GameHandChip])
        case sendDiscard(requiredCount: Int, availableHand: [GameHandChip])
        case applySelectedDiscard(playerDisplay: String, discarded: [GameHandChip])
    }

    let waitingPlayers: [String]
    let action: Action?
}
