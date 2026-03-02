import Foundation

private let validationTopology = StandardBoardTopologyV1.standard()

public enum CoreGameError: Error, Equatable {
    case revMismatch
    case prevHashMismatch
    case actorMismatch
    case rosterChanged
    case seedChanged
    case boardRulesChanged
    case boardChanged
    case invalidBoardHash
    case setupStateMissing
    case setupTurnIndexOutOfRange
    case setupCurrentPlayerMismatch
    case setupStepMismatch
    case roadBeforeSettlement
    case setupPlacementSlotUnavailable
    case invalidNode
    case invalidEdge
    case nodeOccupied
    case edgeOccupied
    case distanceRuleViolation
    case roadNotAdjacentToLastSettlement
    case resourcesByPlayerInvalid
    case invalidStateHash
    case gameIdMismatch
}

public func validateTransition(from: CoreGameStateV1, to: CoreGameStateV1, actor: String) throws {
    guard to.gameId == from.gameId else {
        throw CoreGameError.gameIdMismatch
    }

    guard to.rev == from.rev + 1 else {
        throw CoreGameError.revMismatch
    }

    guard to.prevHash == from.stateHash else {
        throw CoreGameError.prevHashMismatch
    }

    guard actor == from.currentPlayer else {
        throw CoreGameError.actorMismatch
    }

    if let board = to.board {
        guard board.boardHash == board.rehashed().boardHash else {
            throw CoreGameError.invalidBoardHash
        }
    }

    if to.phase == .setup {
        guard let setupState = to.setupState else {
            throw CoreGameError.setupStateMissing
        }

        guard setupState.turnIndex >= 0, setupState.turnIndex < setupState.order.count else {
            throw CoreGameError.setupTurnIndexOutOfRange
        }

        guard to.currentPlayer == setupState.order[setupState.turnIndex] else {
            throw CoreGameError.setupCurrentPlayerMismatch
        }
    } else {
        guard to.setupState == nil else {
            throw CoreGameError.setupStateMissing
        }
    }

    let isStartTransition = from.phase == .lobby && to.phase == .setup
    if !isStartTransition {
        guard to.roster == from.roster else {
            throw CoreGameError.rosterChanged
        }

        guard to.seed == from.seed else {
            throw CoreGameError.seedChanged
        }

        guard to.boardRules == from.boardRules else {
            throw CoreGameError.boardRulesChanged
        }

        guard to.board == from.board else {
            throw CoreGameError.boardChanged
        }
    }

    let expectedResourcesByPlayer = expectedResourcesByPlayerAfterTransition(
        from: from,
        to: to,
        actor: actor,
        isStartTransition: isStartTransition
    )
    guard to.resourcesByPlayer == expectedResourcesByPlayer else {
        throw CoreGameError.resourcesByPlayerInvalid
    }

    let expectedStateHash = to.rehashed().stateHash
    guard to.stateHash == expectedStateHash else {
        throw CoreGameError.invalidStateHash
    }
}

private func expectedResourcesByPlayerAfterTransition(
    from: CoreGameStateV1,
    to: CoreGameStateV1,
    actor: String,
    isStartTransition: Bool
) -> [String: ResourceHandV1] {
    if isStartTransition {
        return Dictionary(uniqueKeysWithValues: to.roster.map { ($0, .zero) })
    }

    guard
        from.phase == .setup,
        let setupState = from.setupState,
        setupState.step == .placeRoad,
        let placement = setupState.placements[actor],
        placement.road1 != nil,
        placement.road2 == nil,
        let settlement2 = placement.settlement2,
        let board = from.board
    else {
        return from.resourcesByPlayer
    }

    var expectedResourcesByPlayer = from.resourcesByPlayer
    var hand = expectedResourcesByPlayer[actor] ?? .zero
    for tileID in validationTopology.tiles(adjacentToNode: settlement2) {
        guard tileID >= 0, tileID < board.resourcesByTile.count else {
            continue
        }
        if tileID == board.robberTile {
            continue
        }
        hand = hand.addingOne(for: board.resourcesByTile[tileID])
    }

    expectedResourcesByPlayer[actor] = hand
    return expectedResourcesByPlayer
}
