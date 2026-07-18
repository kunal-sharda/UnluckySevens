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

enum GameTabletopLayoutStyleResolver {
    static func resolve(
        isNormalPostRollTurn: Bool,
        hasNotPrimaryPlayerContext: Bool,
        testingStyle: GameTabletopLayoutStyle? = nil
    ) -> GameTabletopLayoutStyle {
        if let testingStyle, testingStyle != .framedShelf {
            return testingStyle
        }

        return isNormalPostRollTurn || hasNotPrimaryPlayerContext
            ? .physicalProps
            : .framedShelf
    }
}
