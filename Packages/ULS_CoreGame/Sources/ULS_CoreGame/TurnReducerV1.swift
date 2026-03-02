import Foundation

public enum TurnIntentV1: Codable, Equatable {
    case rollDice
    case endTurn
}

public func apply(intent: TurnIntentV1, to state: CoreGameStateV1, actor: String) throws -> CoreGameStateV1 {
    guard state.phase == .turn, let turnState = state.turnState else {
        throw CoreGameError.turnStateMissing
    }

    guard actor == state.currentPlayer else {
        throw CoreGameError.actorMismatch
    }

    switch intent {
    case .rollDice:
        guard turnState.step == .needsRoll else {
            throw CoreGameError.turnStepMismatch
        }

        guard let diceRngState = state.diceRngState else {
            throw CoreGameError.missingDiceRngState
        }

        var rng = DeterministicRNG(seed: diceRngState)
        let roll = rng.rollDice()
        let rollTotal = roll.0 + roll.1
        let economy = applyProductionPayout(
            rollTotal: rollTotal,
            board: state.board,
            settlementsByNode: state.settlementsByNode,
            citiesByNode: state.citiesByNode,
            resourcesByPlayer: state.resourcesByPlayer,
            bankResources: state.bankResources
        )

        return nextTurnState(
            from: state,
            currentPlayer: state.currentPlayer,
            diceRngState: rng.state,
            turnState: TurnStateV1(step: .afterRoll, lastRoll: DiceRollV1(d1: roll.0, d2: roll.1)),
            resourcesByPlayer: economy.resourcesByPlayer,
            bankResources: economy.bankResources
        )

    case .endTurn:
        guard turnState.step == .afterRoll else {
            throw CoreGameError.turnStepMismatch
        }

        guard let currentIndex = state.roster.firstIndex(of: state.currentPlayer), !state.roster.isEmpty else {
            throw CoreGameError.turnCurrentPlayerNotInRoster
        }

        let nextIndex = state.roster.index(after: currentIndex)
        let wrappedIndex = nextIndex == state.roster.endIndex ? state.roster.startIndex : nextIndex
        let nextPlayer = state.roster[wrappedIndex]

        return nextTurnState(
            from: state,
            currentPlayer: nextPlayer,
            diceRngState: state.diceRngState,
            turnState: TurnStateV1(step: .needsRoll, lastRoll: nil)
        )
    }
}

private func nextTurnState(
    from state: CoreGameStateV1,
    currentPlayer: String,
    diceRngState: UInt64?,
    turnState: TurnStateV1,
    resourcesByPlayer: [String: ResourceHandV1]? = nil,
    bankResources: ResourceHandV1? = nil
) -> CoreGameStateV1 {
    CoreGameStateV1(
        gameId: state.gameId,
        rev: state.rev + 1,
        prevHash: state.stateHash,
        stateHash: "",
        roster: state.roster,
        currentPlayer: currentPlayer,
        phase: .turn,
        seed: state.seed,
        diceRngState: diceRngState,
        resourcesByPlayer: resourcesByPlayer ?? state.resourcesByPlayer,
        bankResources: bankResources ?? state.bankResources,
        settlementsByNode: state.settlementsByNode,
        citiesByNode: state.citiesByNode,
        roadsByEdge: state.roadsByEdge,
        boardRules: state.boardRules,
        board: state.board,
        setupState: nil,
        turnState: turnState
    ).rehashed()
}
