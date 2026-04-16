enum GameTradeResponseIntentKind: String, Equatable {
    case accept
    case decline
    case counter
}

enum GameTradeParticipantResponseState: Equatable {
    case watching
    case waiting
    case accepted
    case declined
    case countered
}

struct GameTradeOfferSummary: Equatable {
    let proposerPlayerID: String
    let proposerDisplay: String
    let giveLabel: String
    let give: [GameHandChip]
    let receiveLabel: String
    let receive: [GameHandChip]
    let recipientPlayerIDs: [String]
    let recipientsLabel: String
}

struct GameTradeParticipantStatus: Identifiable, Equatable {
    let playerID: String
    let displayName: String
    let state: GameTradeParticipantResponseState
    let detailText: String
    let isTargeted: Bool
    let counterGive: [GameHandChip]
    let counterReceive: [GameHandChip]

    var id: String { playerID }
}

struct GameTradeSelectedResponseSummary: Equatable {
    let playerID: String
    let displayName: String
    let kind: GameTradeResponseIntentKind
}

struct GameTradeResponderActions: Equatable {
    let canAccept: Bool
    let canDecline: Bool
    let canCounter: Bool
}

struct GameTradeMaritimeOption: Identifiable, Equatable {
    let give: [GameHandChip]
    let receive: [GameHandChip]
    let ratio: Int

    var id: String {
        "\(ratio):\(give.map(\.id).joined(separator: ",")):\(receive.map(\.id).joined(separator: ","))"
    }
}

struct GameTradePanelModel: Equatable {
    let roleTitle: String
    let message: String
    let activeOffer: GameTradeOfferSummary?
    let participantStatuses: [GameTradeParticipantStatus]
    let responderActions: GameTradeResponderActions?
    let selectedResponse: GameTradeSelectedResponseSummary?
    let maritimeOptions: [GameTradeMaritimeOption]
    let pendingBannerText: String?
    let canReplaceOffer: Bool
}
