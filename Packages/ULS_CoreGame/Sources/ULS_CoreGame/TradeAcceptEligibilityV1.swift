import Foundation

public enum TradeAcceptEligibilityV1: String, Equatable {
    case eligible
    case turnUnavailable
    case offerMissing
    case responderInvalid
    case responderNotTargeted
    case responderAlreadyResponded
    case offerNoLongerFunded
    case responderInsufficientResources
}

public extension CoreGameStateV1 {
    func tradeAcceptEligibility(for respondingPlayer: String) -> TradeAcceptEligibilityV1 {
        guard phase == .turn, turnState?.step == .afterRoll else {
            return .turnUnavailable
        }
        guard let offer = activeTradeOffer else {
            return .offerMissing
        }
        guard respondingPlayer != currentPlayer, isActivePlayer(respondingPlayer) else {
            return .responderInvalid
        }
        guard offer.recipients.contains(respondingPlayer) else {
            return .responderNotTargeted
        }
        guard !tradeResponses.contains(where: { $0.respondingPlayer == respondingPlayer }) else {
            return .responderAlreadyResponded
        }
        guard TurnRulesPrimitivesV1.canAfford(
            hand: resourcesByPlayer[currentPlayer] ?? .zero,
            cost: offer.give
        ) else {
            return .offerNoLongerFunded
        }
        guard TurnRulesPrimitivesV1.canAfford(
            hand: resourcesByPlayer[respondingPlayer] ?? .zero,
            cost: offer.receive
        ) else {
            return .responderInsufficientResources
        }
        return .eligible
    }
}
