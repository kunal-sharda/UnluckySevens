import ULS_CoreGame

struct GameHandChip: Identifiable, Equatable {
    let resource: ResourceV1
    let count: Int

    var id: String {
        resource.rawValue
    }

    var shortLabel: String {
        switch resource {
        case .wood:
            return "Wood"
        case .brick:
            return "Brick"
        case .sheep:
            return "Sheep"
        case .wheat:
            return "Wheat"
        case .ore:
            return "Ore"
        case .desert:
            return "Desert"
        }
    }
}
