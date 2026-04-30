import ULS_CoreGame

enum TradeResponsePublicationMode: Equatable {
    case canonicalState
}

enum TradeResponsePublicationResolver {
    static func resolve(_ draft: TurnActionDraft) -> TradeResponsePublicationMode? {
        resolve(draft.intent)
    }

    static func resolve(_ intent: TurnIntentV1) -> TradeResponsePublicationMode? {
        switch intent {
        case .acceptTrade, .declineTrade, .counterTrade:
            return .canonicalState
        default:
            return nil
        }
    }
}
