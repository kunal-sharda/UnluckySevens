struct GameOwnedDevCardSummary: Identifiable, Equatable {
    let kind: GameDevCardVisualKind
    let playableCount: Int
    let newCount: Int

    var id: GameDevCardVisualKind { kind }
    var totalCount: Int { playableCount + newCount }
}
