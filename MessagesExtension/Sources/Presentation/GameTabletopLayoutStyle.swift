enum GameTabletopLayoutStyle: String, CaseIterable {
    case framedShelf
    case framelessShelf
    case feltTools
    case physicalProps

    static let uxTestingDefaultsKey = "uls.uxLab.tabletopLayoutStyle"

    var showsCreamBoardFrame: Bool {
        self == .framedShelf
    }

    var usesFeltTools: Bool {
        self == .feltTools || self == .physicalProps
    }

    var usesPhysicalProps: Bool {
        self == .physicalProps
    }
}
