struct GameEndDevelopmentCardGroup: Identifiable, Equatable {
    let kind: GameDevCardVisualKind
    let count: Int

    var id: GameDevCardVisualKind { kind }
}
