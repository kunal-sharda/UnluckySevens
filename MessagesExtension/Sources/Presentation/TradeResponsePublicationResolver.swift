import ULS_Transport

enum TradeResponsePublicationMode: Equatable {
    case canonicalState
    case responderEnvelope
}

enum TradeResponsePublicationResolver {
    static func resolve(_ turnIntent: ULS_Transport.TurnIntentV1) -> TradeResponsePublicationMode? {
        switch turnIntent.kind {
        case .acceptTrade:
            return .canonicalState
        case .declineTrade, .counterTrade:
            return .responderEnvelope
        default:
            return nil
        }
    }
}
