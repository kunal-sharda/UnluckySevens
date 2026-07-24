struct GameDiceRollCompletionGate: Equatable {
    private(set) var hasCompleted = false

    mutating func complete(_ action: () -> Void) {
        guard !hasCompleted else { return }
        hasCompleted = true
        action()
    }
}
