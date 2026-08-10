enum GameTabletopLayoutStyle: String, CaseIterable {
    case physicalProps

    var showsCreamBoardFrame: Bool {
        false
    }

    var usesFeltTools: Bool {
        true
    }

    var usesPhysicalProps: Bool {
        true
    }
}
