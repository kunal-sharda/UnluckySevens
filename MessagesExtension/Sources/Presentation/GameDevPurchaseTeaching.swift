import Foundation
import ULS_CoreGame

/// Presentation identity only; purchase eligibility always comes from Core queries.
struct GameDevPurchaseTeachingContext: Equatable {
    let gameID: String
    let turnID: String

    static func make(state: CoreGameStateV1?, actor: String?) -> Self? {
        guard let state, state.phase == .turn, actor == state.currentPlayer,
              state.turnState?.step == .afterRoll, let rollState = state.diceRngState else { return nil }
        // The dice stream advances on a roll, and remains stable through purchases/trades.
        return Self(gameID: state.gameId, turnID: "\(state.currentPlayer):\(rollState)")
    }
}

struct GameDevTeachingRequest: Equatable {
    let context: GameDevPurchaseTeachingContext?
    let canBuy: Bool
    let isBusy: Bool
}
