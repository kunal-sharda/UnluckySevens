import ULS_Transport

enum ResponderTurnMessageKind: Equatable {
    case discardResponse
    case tradeResponse
}

enum TurnIntentTransportRole: Equatable {
    case responderMessage(ResponderTurnMessageKind)
    case legacyIntent
}

enum TurnIntentTransportRoleResolver {
    static func resolve(_ turnIntent: ULS_Transport.TurnIntentV1) -> TurnIntentTransportRole {
        switch turnIntent.kind {
        case .submitDiscard:
            return .responderMessage(.discardResponse)
        case .acceptTrade, .declineTrade, .counterTrade:
            return .responderMessage(.tradeResponse)
        default:
            return .legacyIntent
        }
    }
}
