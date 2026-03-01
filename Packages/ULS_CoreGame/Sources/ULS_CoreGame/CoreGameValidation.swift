import Foundation

public enum CoreGameError: Error, Equatable {
    case revMismatch
    case prevHashMismatch
    case actorMismatch
    case rosterChanged
    case seedChanged
    case boardRulesChanged
    case boardChanged
    case invalidBoardHash
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

    let expectedStateHash = to.rehashed().stateHash
    guard to.stateHash == expectedStateHash else {
        throw CoreGameError.invalidStateHash
    }
}
