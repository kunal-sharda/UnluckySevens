struct GameTradeOfferSummary: Equatable {
    let proposerDisplay: String
    let giveLabel: String
    let give: [GameHandChip]
    let receiveLabel: String
    let receive: [GameHandChip]
}

enum GameTradeActionKind: String, Equatable {
    case publishSuggestedOffer
    case publishSuggestedMaritime
    case sendAcceptOffer
    case applySelectedAccept
}

struct GameTradeAction: Identifiable, Equatable {
    let kind: GameTradeActionKind
    let title: String
    let detail: String
    let giveLabel: String
    let give: [GameHandChip]
    let receiveLabel: String
    let receive: [GameHandChip]

    var id: String { kind.rawValue + ":" + title }
}

struct GameTradeExecuteOption: Identifiable, Equatable {
    let playerID: String
    let displayName: String

    var id: String { playerID }
}

struct GameTradePanelModel: Equatable {
    let message: String
    let activeOffer: GameTradeOfferSummary?
    let actions: [GameTradeAction]
    let acceptedPlayers: [String]
    let executeOptions: [GameTradeExecuteOption]
}
