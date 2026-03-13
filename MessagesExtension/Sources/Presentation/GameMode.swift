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
    case discard

    var actionKind: GameActionDockItem.Kind? {
        switch self {
        case .buildRoad, .buildSettlement, .buildCity:
            return .build
        case .trade:
            return .trade
        case .playDevCard:
            return .devCards
        case .idle, .setup, .robberMove, .robberVictim, .discard:
            return nil
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
        case .discard:
            return "Discard"
        }
    }

    var subtitle: String {
        switch self {
        case .idle:
            return ""
        case .setup:
            return "Setup is active. Placement selection will plug into board interaction in a later stage."
        case .buildRoad:
            return "Road-building mode is active. Edge selection will plug in during the board stage."
        case .buildSettlement:
            return "Settlement-building mode is active. Node selection will plug in during the board stage."
        case .buildCity:
            return "City-upgrade mode is active. Eligible city selection will plug in during the board stage."
        case .robberMove:
            return "Robber movement is required before turn play can continue."
        case .robberVictim:
            return "Robber victim selection is required before turn play can continue."
        case .trade:
            return "Trade mode is active. Offer and accept flows will plug in during the gameplay UX stage."
        case .playDevCard:
            return "Dev-card mode is active. Card-specific flows will plug in during the gameplay UX stage."
        case .discard:
            return "Discard resolution is required before robber handling can continue."
        }
    }
}
