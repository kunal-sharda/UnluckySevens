enum GamePhysicalTurnHeaderPrompt: String, CaseIterable, Equatable {
    case chooseDevOrRoll
    case choosePiece
    case placeRoad
    case tapAgainToPlace
    case placeSettlement
    case upgradeCity
    case tapAgainToUpgrade
    case chooseTrade
    case makeOffer
    case tradeWithBank
    case waitingForPlayers
    case chooseDevCard
    case moveRobber
    case choosePlayer
    case chooseResource
    case chooseTwoResources
    case chooseOneMore
    case placeFirstRoad
    case placeSecondRoad

    var text: String {
        switch self {
        case .chooseDevOrRoll: return "Choose Dev or Roll"
        case .choosePiece: return "Choose a piece"
        case .placeRoad: return "Place a road"
        case .tapAgainToPlace: return "Tap again to place"
        case .placeSettlement: return "Place a settlement"
        case .upgradeCity: return "Upgrade to a city"
        case .tapAgainToUpgrade: return "Tap again to upgrade"
        case .chooseTrade: return "Choose a trade"
        case .makeOffer: return "Make an offer"
        case .tradeWithBank: return "Trade with the bank"
        case .waitingForPlayers: return "Waiting for players"
        case .chooseDevCard: return "Choose a Dev Card"
        case .moveRobber: return "Move the robber"
        case .choosePlayer: return "Choose a player"
        case .chooseResource: return "Choose a resource"
        case .chooseTwoResources: return "Choose two resources"
        case .chooseOneMore: return "Choose one more"
        case .placeFirstRoad: return "Place first road"
        case .placeSecondRoad: return "Place second road"
        }
    }
}
