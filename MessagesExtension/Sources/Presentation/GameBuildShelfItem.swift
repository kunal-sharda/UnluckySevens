import ULS_CoreGame

struct GameBuildShelfItem: Identifiable, Equatable {
    enum Kind: String, Identifiable {
        case buildRoad
        case buildSettlement
        case buildCity

        var id: String { rawValue }
    }

    let kind: Kind
    let title: String
    let systemImage: String
    let cost: ResourceHandV1
    let placementInstruction: String
    let isEnabled: Bool

    var id: Kind { kind }
}
