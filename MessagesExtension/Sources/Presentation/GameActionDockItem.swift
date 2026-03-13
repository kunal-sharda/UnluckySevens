struct GameActionDockItem: Identifiable, Equatable {
    enum Kind: String, Identifiable {
        case roll
        case build
        case trade
        case devCards
        case endTurn

        var id: String {
            rawValue
        }
    }

    let kind: Kind
    let title: String
    let systemImage: String
    let isEnabled: Bool

    var id: Kind {
        kind
    }
}
