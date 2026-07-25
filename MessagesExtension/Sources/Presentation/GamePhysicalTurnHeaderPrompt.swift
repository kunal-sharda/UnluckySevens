enum GamePhysicalTurnHeaderPrompt: String, CaseIterable, Equatable {
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
    case answerTradeOffer
    case waitingForDiscard
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
        case .choosePiece: return "Choose a Piece"
        case .placeRoad: return "Place a Road"
        case .tapAgainToPlace: return "Tap Again to Build"
        case .placeSettlement: return "Place a Settlement"
        case .upgradeCity: return "Upgrade to a City"
        case .tapAgainToUpgrade: return "Tap Again to Upgrade"
        case .chooseTrade: return "Choose How to Trade"
        case .makeOffer: return "Make an Offer"
        case .tradeWithBank: return "Trade with Bank or Port"
        case .waitingForPlayers: return "Waiting for Replies"
        case .answerTradeOffer: return "Review the Offer"
        case .waitingForDiscard: return "Waiting for Other Players"
        case .chooseDevCard: return "Choose a Dev Card"
        case .moveRobber: return "Move the Robber"
        case .choosePlayer: return "Choose a Player"
        case .chooseResource: return "Choose a Resource"
        case .chooseTwoResources: return "Choose Two Resources"
        case .chooseOneMore: return "Choose One More"
        case .placeFirstRoad: return "Place the First Road"
        case .placeSecondRoad: return "Place the Second Road"
        }
    }
}
