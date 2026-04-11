struct GameBuildShelfItem: Identifiable, Equatable {
    enum Kind: String, Identifiable {
        case buildRoad
        case buildSettlement
        case buildCity
        case buyDevCard

        var id: String { rawValue }
    }

    let kind: Kind
    let title: String
    let systemImage: String
    let isEnabled: Bool

    var id: Kind { kind }
}
