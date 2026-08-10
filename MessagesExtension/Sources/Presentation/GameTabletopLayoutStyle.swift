enum GameTabletopLayoutStyle: String, CaseIterable {
    case physicalProps

    static let uxTestingDefaultsKey = "uls.uxLab.tabletopLayoutStyle"

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

enum GameTabletopLayoutStyleResolver {
    static func resolve(
        isNormalPostRollTurn: Bool,
        isNormalPreRollTurn: Bool = false,
        hasNotPrimaryPlayerContext: Bool,
        isSetupPlacement: Bool = false,
        isForcedDiscard: Bool = false,
        testingStyle: GameTabletopLayoutStyle? = nil
    ) -> GameTabletopLayoutStyle {
        .physicalProps
    }
}
