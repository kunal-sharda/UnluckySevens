import Foundation

// Development-card transition validation remains independent from reducer play logic.
func validateDevCardTransition(
    from: CoreGameStateV1,
    to: CoreGameStateV1,
    isStartTransition: Bool
) throws {
    if isStartTransition {
        return
    }

    let devStateUnchanged =
        from.devDeck == to.devDeck &&
        from.devCardsByPlayer == to.devCardsByPlayer &&
        from.newDevCardsByPlayer == to.newDevCardsByPlayer &&
        from.revealedVictoryPointsByPlayer == to.revealedVictoryPointsByPlayer &&
        from.devCardActionPlayedThisTurn == to.devCardActionPlayedThisTurn &&
        from.knightsPlayedByPlayer == to.knightsPlayedByPlayer

    let turnLikeTransition = from.phase == .turn && (to.phase == .turn || to.phase == .gameOver)
    if !turnLikeTransition {
        guard devStateUnchanged else {
            throw CoreGameError.devDeckInvalid
        }
        return
    }

    if to.phase == .turn, from.currentPlayer != to.currentPlayer {
        try validateEndTurnDevCardCarryover(from: from, to: to)
        return
    }
    guard from.currentPlayer == to.currentPlayer else {
        throw CoreGameError.devDeckInvalid
    }

    if devStateUnchanged {
        return
    }

    if to.phase == .turn {
        guard isDevCardPlayWindowStep(from.turnState?.step), isDevCardPlayWindowStep(to.turnState?.step) else {
            throw CoreGameError.devDeckInvalid
        }
    } else {
        guard isDevCardPlayWindowStep(from.turnState?.step), to.turnState == nil else {
            throw CoreGameError.devDeckInvalid
        }
    }

    if to.devDeck != from.devDeck {
        guard to.devDeck.count == from.devDeck.count - 1 else {
            throw CoreGameError.devDeckInvalid
        }
        guard Array(from.devDeck.dropFirst()) == to.devDeck else {
            throw CoreGameError.devDeckInvalid
        }
        guard to.devCardActionPlayedThisTurn == from.devCardActionPlayedThisTurn else {
            throw CoreGameError.devDeckInvalid
        }
    }

    let current = from.currentPlayer
    for player in from.roster where player != current {
        guard to.devCardsByPlayer[player] == from.devCardsByPlayer[player] else {
            throw CoreGameError.devDeckInvalid
        }
        guard to.newDevCardsByPlayer[player] == from.newDevCardsByPlayer[player] else {
            throw CoreGameError.devDeckInvalid
        }
        guard to.revealedVictoryPointsByPlayer[player] == from.revealedVictoryPointsByPlayer[player] else {
            throw CoreGameError.devDeckInvalid
        }
        guard to.knightsPlayedByPlayer[player] == from.knightsPlayedByPlayer[player] else {
            throw CoreGameError.devDeckInvalid
        }
    }

    let fromCurrentInventory = from.devCardsByPlayer[current] ?? .zero
    let toCurrentInventory = to.devCardsByPlayer[current] ?? .zero
    let fromCurrentNewInventory = from.newDevCardsByPlayer[current] ?? .zero
    let toCurrentNewInventory = to.newDevCardsByPlayer[current] ?? .zero
    guard isNonNegativeInventory(toCurrentInventory), isNonNegativeInventory(toCurrentNewInventory) else {
        throw CoreGameError.devDeckInvalid
    }

    if to.devDeck == from.devDeck {
        guard fromCurrentInventory.totalCount + fromCurrentNewInventory.totalCount >= toCurrentInventory.totalCount + toCurrentNewInventory.totalCount else {
            throw CoreGameError.devDeckInvalid
        }
    }

    guard (to.revealedVictoryPointsByPlayer[current] ?? 0) >= (from.revealedVictoryPointsByPlayer[current] ?? 0) else {
        throw CoreGameError.devDeckInvalid
    }
    guard (to.knightsPlayedByPlayer[current] ?? 0) >= (from.knightsPlayedByPlayer[current] ?? 0) else {
        throw CoreGameError.devDeckInvalid
    }

    if from.devCardActionPlayedThisTurn {
        guard to.devCardActionPlayedThisTurn else {
            throw CoreGameError.devDeckInvalid
        }
    }
}

private func validateEndTurnDevCardCarryover(from: CoreGameStateV1, to: CoreGameStateV1) throws {
    guard to.devDeck == from.devDeck else {
        throw CoreGameError.devDeckInvalid
    }

    let endingPlayer = from.currentPlayer
    for player in from.roster {
        if player == endingPlayer {
            let expectedPlayable = mergeDevInventoriesForValidation(
                from.devCardsByPlayer[player] ?? .zero,
                from.newDevCardsByPlayer[player] ?? .zero
            )
            guard to.devCardsByPlayer[player] == expectedPlayable else {
                throw CoreGameError.devDeckInvalid
            }
            guard to.newDevCardsByPlayer[player] == .zero else {
                throw CoreGameError.devDeckInvalid
            }
        } else {
            guard to.devCardsByPlayer[player] == from.devCardsByPlayer[player] else {
                throw CoreGameError.devDeckInvalid
            }
            guard to.newDevCardsByPlayer[player] == from.newDevCardsByPlayer[player] else {
                throw CoreGameError.devDeckInvalid
            }
        }

        guard to.revealedVictoryPointsByPlayer[player] == from.revealedVictoryPointsByPlayer[player] else {
            throw CoreGameError.devDeckInvalid
        }
        guard to.knightsPlayedByPlayer[player] == from.knightsPlayedByPlayer[player] else {
            throw CoreGameError.devDeckInvalid
        }
    }

    guard to.devCardActionPlayedThisTurn == false else {
        throw CoreGameError.devDeckInvalid
    }
}
