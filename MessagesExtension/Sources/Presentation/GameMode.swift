enum GameMode: Equatable {
    case idle
    case setup
    case buildRoad
    case buildSettlement
    case buildCity
    case robberMove
    case robberVictim
    case trade
    case playDevCard
    case devCardKnightMove
    case devCardKnightVictim
    case devCardMonopoly
    case devCardYearOfPlenty
    case devCardRoadBuildingFirst
    case devCardRoadBuildingSecond
    case discard

    var actionKind: GameActionDockItem.Kind? {
        switch self {
        case .buildRoad, .buildSettlement, .buildCity:
            return .build
        case .trade:
            return .trade
        case .playDevCard,
             .devCardKnightMove,
             .devCardKnightVictim,
             .devCardMonopoly,
             .devCardYearOfPlenty,
             .devCardRoadBuildingFirst,
             .devCardRoadBuildingSecond:
            return .devCards
        case .idle, .setup, .robberMove, .robberVictim, .discard:
            return nil
        }
    }

    var buildShelfKind: GameBuildShelfItem.Kind? {
        switch self {
        case .buildRoad:
            return .buildRoad
        case .buildSettlement:
            return .buildSettlement
        case .buildCity:
            return .buildCity
        case .idle,
             .setup,
             .robberMove,
             .robberVictim,
             .trade,
             .playDevCard,
             .devCardKnightMove,
             .devCardKnightVictim,
             .devCardMonopoly,
             .devCardYearOfPlenty,
             .devCardRoadBuildingFirst,
             .devCardRoadBuildingSecond,
             .discard:
            return nil
        }
    }

    var isBuildMode: Bool {
        buildShelfKind != nil
    }

    var isDevCardMode: Bool {
        switch self {
        case .playDevCard,
             .devCardKnightMove,
             .devCardKnightVictim,
             .devCardMonopoly,
             .devCardYearOfPlenty,
             .devCardRoadBuildingFirst,
             .devCardRoadBuildingSecond:
            return true
        default:
            return false
        }
    }

    var title: String {
        switch self {
        case .idle:
            return "Board"
        case .setup:
            return "Setup Placement"
        case .buildRoad:
            return "Build Road"
        case .buildSettlement:
            return "Build Settlement"
        case .buildCity:
            return "Build City"
        case .robberMove:
            return "Move Robber"
        case .robberVictim:
            return "Choose Robber Victim"
        case .trade:
            return "Trade"
        case .playDevCard:
            return "Dev Cards"
        case .devCardKnightMove:
            return "Knight"
        case .devCardKnightVictim:
            return "Knight Victim"
        case .devCardMonopoly:
            return "Monopoly"
        case .devCardYearOfPlenty:
            return "Year of Plenty"
        case .devCardRoadBuildingFirst:
            return "Road Building"
        case .devCardRoadBuildingSecond:
            return "Road Building"
        case .discard:
            return "Discard"
        }
    }

    var subtitle: String {
        ""
    }
}
