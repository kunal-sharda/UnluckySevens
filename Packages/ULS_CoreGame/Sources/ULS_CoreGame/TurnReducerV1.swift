import Foundation

public enum TurnIntentV1: Codable, Equatable {
    case rollDice
    case submitDiscard(player: String, discarded: ResourceHandV1)
    case moveRobber(tileID: Int)
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

        if rollTotal == 7 {
            let requirements = requiredDiscards(for: state.resourcesByPlayer)
            let nextStep: TurnStepV1 = requirements.isEmpty ? .needsRobberMove : .pendingDiscards
            return nextTurnState(
                from: state,
                currentPlayer: state.currentPlayer,
                diceRngState: rng.state,
                board: state.board,
                turnState: TurnStateV1(
                    step: nextStep,
                    lastRoll: DiceRollV1(d1: roll.0, d2: roll.1),
                    discardRequirementsByPlayer: requirements,
                    submittedDiscardsByPlayer: [:]
                )
            )
        }

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
            board: state.board,
            turnState: TurnStateV1(step: .afterRoll, lastRoll: DiceRollV1(d1: roll.0, d2: roll.1)),
            resourcesByPlayer: economy.resourcesByPlayer,
            bankResources: economy.bankResources
        )

    case let .submitDiscard(player, discarded):
        guard turnState.step == .pendingDiscards else {
            throw CoreGameError.turnStepMismatch
        }

        guard let requiredCount = turnState.discardRequirementsByPlayer[player] else {
            throw CoreGameError.discardSubmissionNotRequired
        }

        guard turnState.submittedDiscardsByPlayer[player] == nil else {
            throw CoreGameError.discardAlreadySubmitted
        }

        guard discarded.totalCount == requiredCount else {
            throw CoreGameError.discardCountMismatch
        }

        guard
            discarded.wood >= 0,
            discarded.brick >= 0,
            discarded.sheep >= 0,
            discarded.wheat >= 0,
            discarded.ore >= 0
        else {
            throw CoreGameError.discardCountMismatch
        }

        let playerHand = state.resourcesByPlayer[player] ?? .zero
        guard
            discarded.wood <= playerHand.wood,
            discarded.brick <= playerHand.brick,
            discarded.sheep <= playerHand.sheep,
            discarded.wheat <= playerHand.wheat,
            discarded.ore <= playerHand.ore
        else {
            throw CoreGameError.insufficientResourcesForDiscard
        }

        var updatedResourcesByPlayer = state.resourcesByPlayer
        updatedResourcesByPlayer[player] = ResourceHandV1(
            wood: playerHand.wood - discarded.wood,
            brick: playerHand.brick - discarded.brick,
            sheep: playerHand.sheep - discarded.sheep,
            wheat: playerHand.wheat - discarded.wheat,
            ore: playerHand.ore - discarded.ore
        )

        let updatedBankResources = ResourceHandV1(
            wood: state.bankResources.wood + discarded.wood,
            brick: state.bankResources.brick + discarded.brick,
            sheep: state.bankResources.sheep + discarded.sheep,
            wheat: state.bankResources.wheat + discarded.wheat,
            ore: state.bankResources.ore + discarded.ore
        )

        var submitted = turnState.submittedDiscardsByPlayer
        submitted[player] = discarded
        let allSubmitted = turnState.discardRequirementsByPlayer.keys.allSatisfy { submitted[$0] != nil }

        return nextTurnState(
            from: state,
            currentPlayer: state.currentPlayer,
            diceRngState: state.diceRngState,
            board: state.board,
            turnState: TurnStateV1(
                step: allSubmitted ? .needsRobberMove : .pendingDiscards,
                lastRoll: turnState.lastRoll,
                discardRequirementsByPlayer: turnState.discardRequirementsByPlayer,
                submittedDiscardsByPlayer: submitted
            ),
            resourcesByPlayer: updatedResourcesByPlayer,
            bankResources: updatedBankResources
        )

    case let .moveRobber(tileID):
        guard turnState.step == .needsRobberMove else {
            throw CoreGameError.turnStepMismatch
        }
        guard let board = state.board else {
            throw CoreGameError.boardChanged
        }
        guard tileID >= 0, tileID < board.resourcesByTile.count else {
            throw CoreGameError.invalidRobberTile
        }
        guard tileID != board.robberTile else {
            throw CoreGameError.robberTileUnchanged
        }

        let movedBoard = BoardSetupV1(
            resourcesByTile: board.resourcesByTile,
            numbersByTile: board.numbersByTile,
            portsByIndex: board.portsByIndex,
            robberTile: tileID,
            generator: board.generator,
            boardHash: ""
        ).rehashed()

        return nextTurnState(
            from: state,
            currentPlayer: state.currentPlayer,
            diceRngState: state.diceRngState,
            board: movedBoard,
            turnState: TurnStateV1(step: .afterRoll, lastRoll: turnState.lastRoll)
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
            board: state.board,
            turnState: TurnStateV1(step: .needsRoll, lastRoll: nil)
        )
    }
}

private func nextTurnState(
    from state: CoreGameStateV1,
    currentPlayer: String,
    diceRngState: UInt64?,
    board: BoardSetupV1?,
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
        board: board,
        setupState: nil,
        turnState: turnState
    ).rehashed()
}

private func requiredDiscards(for resourcesByPlayer: [String: ResourceHandV1]) -> [String: Int] {
    var result: [String: Int] = [:]
    for (player, hand) in resourcesByPlayer {
        if hand.totalCount > 7 {
            result[player] = hand.totalCount / 2
        }
    }
    return result
}
