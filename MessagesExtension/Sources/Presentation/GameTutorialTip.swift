/// Stable device-local categories for implemented contextual tutorials.
enum GameTutorialTip: String, CaseIterable, Identifiable {
    case buildCosts
    case devPurchase
    case actionCardTiming
    case victoryPointScoring

    var id: String { rawValue }

    var title: String {
        switch self {
        case .buildCosts: "Building costs"
        case .devPurchase: "Buying Dev Cards"
        case .actionCardTiming: "When to play Dev Cards"
        case .victoryPointScoring: "Victory Point cards"
        }
    }

    static func newCard(_ kind: GameDevCardVisualKind) -> Self {
        kind == .victoryPoint ? .victoryPointScoring : .actionCardTiming
    }
}
