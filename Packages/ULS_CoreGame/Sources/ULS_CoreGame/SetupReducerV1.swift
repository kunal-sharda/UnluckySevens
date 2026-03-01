import Foundation

public enum SetupIntentV1: Codable, Equatable {
    case placeSetupSettlement(node: Int)
    case placeSetupRoad(edge: Int)
}

public func apply(intent: SetupIntentV1, to state: CoreGameStateV1, actor: String) throws -> CoreGameStateV1 {
    guard state.phase == .setup, var setupState = state.setupState else {
        throw CoreGameError.setupStateMissing
    }

    guard actor == state.currentPlayer else {
        throw CoreGameError.actorMismatch
    }

    guard setupState.turnIndex >= 0, setupState.turnIndex < setupState.order.count else {
        throw CoreGameError.setupTurnIndexOutOfRange
    }

    guard setupState.order[setupState.turnIndex] == state.currentPlayer else {
        throw CoreGameError.setupCurrentPlayerMismatch
    }

    let player = state.currentPlayer

    switch intent {
    case let .placeSetupSettlement(node):
        guard setupState.step == .placeSettlement else {
            throw CoreGameError.setupStepMismatch
        }

        var playerPlacements = setupState.placements[player] ?? PlayerSetupPlacementsV1()
        if playerPlacements.settlement1 == nil {
            playerPlacements = PlayerSetupPlacementsV1(
                settlement1: node,
                road1: playerPlacements.road1,
                settlement2: playerPlacements.settlement2,
                road2: playerPlacements.road2
            )
        } else if playerPlacements.settlement2 == nil {
            playerPlacements = PlayerSetupPlacementsV1(
                settlement1: playerPlacements.settlement1,
                road1: playerPlacements.road1,
                settlement2: node,
                road2: playerPlacements.road2
            )
        } else {
            throw CoreGameError.setupPlacementSlotUnavailable
        }

        setupState = SetupStateV1(
            order: setupState.order,
            turnIndex: setupState.turnIndex,
            step: .placeRoad,
            placements: setupState.placements.merging([player: playerPlacements]) { _, new in new },
            lastPlacedSettlementNode: node
        )

        return nextState(
            from: state,
            currentPlayer: player,
            phase: .setup,
            setupState: setupState
        )

    case let .placeSetupRoad(edge):
        guard setupState.step == .placeRoad else {
            throw CoreGameError.setupStepMismatch
        }

        guard setupState.lastPlacedSettlementNode != nil else {
            throw CoreGameError.roadBeforeSettlement
        }

        var playerPlacements = setupState.placements[player] ?? PlayerSetupPlacementsV1()
        if playerPlacements.road1 == nil {
            guard playerPlacements.settlement1 != nil else {
                throw CoreGameError.roadBeforeSettlement
            }
            playerPlacements = PlayerSetupPlacementsV1(
                settlement1: playerPlacements.settlement1,
                road1: edge,
                settlement2: playerPlacements.settlement2,
                road2: playerPlacements.road2
            )
        } else if playerPlacements.road2 == nil {
            guard playerPlacements.settlement2 != nil else {
                throw CoreGameError.roadBeforeSettlement
            }
            playerPlacements = PlayerSetupPlacementsV1(
                settlement1: playerPlacements.settlement1,
                road1: playerPlacements.road1,
                settlement2: playerPlacements.settlement2,
                road2: edge
            )
        } else {
            throw CoreGameError.setupPlacementSlotUnavailable
        }

        let advancedTurnIndex = setupState.turnIndex + 1
        let updatedPlacements = setupState.placements.merging([player: playerPlacements]) { _, new in new }

        if advancedTurnIndex >= setupState.order.count {
            guard let firstPlayer = state.roster.first else {
                throw CoreGameError.setupTurnIndexOutOfRange
            }

            return nextState(
                from: state,
                currentPlayer: firstPlayer,
                phase: .turn,
                setupState: nil
            )
        }

        let advancedSetup = SetupStateV1(
            order: setupState.order,
            turnIndex: advancedTurnIndex,
            step: .placeSettlement,
            placements: updatedPlacements,
            lastPlacedSettlementNode: nil
        )

        return nextState(
            from: state,
            currentPlayer: advancedSetup.order[advancedSetup.turnIndex],
            phase: .setup,
            setupState: advancedSetup
        )
    }
}

private func nextState(
    from state: CoreGameStateV1,
    currentPlayer: String,
    phase: PhaseV1,
    setupState: SetupStateV1?
) -> CoreGameStateV1 {
    CoreGameStateV1(
        gameId: state.gameId,
        rev: state.rev + 1,
        prevHash: state.stateHash,
        stateHash: "",
        roster: state.roster,
        currentPlayer: currentPlayer,
        phase: phase,
        seed: state.seed,
        diceRngState: state.diceRngState,
        boardRules: state.boardRules,
        board: state.board,
        setupState: setupState
    ).rehashed()
}
