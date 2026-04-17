import ULS_Transport

enum TurnIntentPublishActorResolver {
    static func resolve(
        _ turnIntent: ULS_Transport.TurnIntentV1,
        localActor: String
    ) -> String {
        switch turnIntent.kind {
        case .acceptTrade, .declineTrade, .counterTrade:
            return turnIntent.actor
        default:
            return localActor
        }
    }
}
