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
            return "Year Of Plenty"
        case .devCardRoadBuildingFirst:
            return "Road Building"
        case .devCardRoadBuildingSecond:
            return "Road Building"
        case .discard:
            return "Discard"
        }
    }

    var subtitle: String {
        switch self {
        case .idle:
            return ""
        case .setup:
            return "Tap the highlighted road connected to the settlement you just placed."
        case .buildRoad:
            return "Tap a highlighted edge to build a road."
        case .buildSettlement:
            return "Tap a highlighted node to build a settlement."
        case .buildCity:
            return "Tap a highlighted settlement to upgrade it into a city."
        case .robberMove:
            return "Robber movement is required before turn play can continue."
        case .robberVictim:
            return "Robber victim selection is required before turn play can continue."
        case .trade:
            return "Trade mode is active. Offer and accept flows will plug in during the gameplay UX stage."
        case .playDevCard:
            return "Choose a development card to play."
        case .devCardKnightMove:
            return "Tap a highlighted tile to move the robber."
        case .devCardKnightVictim:
            return "Tap a highlighted victim to steal."
        case .devCardMonopoly:
            return "Choose the resource to claim from every opponent."
        case .devCardYearOfPlenty:
            return "Choose two resources from the bank."
        case .devCardRoadBuildingFirst:
            return "Tap the first highlighted road."
        case .devCardRoadBuildingSecond:
            return "Tap the second highlighted road."
        case .discard:
            return "Discard resolution is required before robber handling can continue."
        }
    }
}
