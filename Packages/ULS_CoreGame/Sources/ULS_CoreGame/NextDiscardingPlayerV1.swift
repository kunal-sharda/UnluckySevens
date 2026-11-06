public extension CoreGameStateV1 {
    /// The same ordered obligation used by the discard reducer.
    var nextDiscardingPlayer: String? {
        guard let turnState, turnState.step == .pendingDiscards else { return nil }
        return nextPendingDiscardPlayer(roster: roster, turnState: turnState)
    }
}
