import ULS_Transport

enum TradeResponsePublicationMode: Equatable {
    case canonicalState
}

enum TradeResponsePublicationResolver {
    static func resolve(_ turnIntent: ULS_Transport.TurnIntentV1) -> TradeResponsePublicationMode? {
        switch turnIntent.kind {
        case .acceptTrade, .declineTrade, .counterTrade:
            return .canonicalState
        default:
            return nil
        }
    }
}
