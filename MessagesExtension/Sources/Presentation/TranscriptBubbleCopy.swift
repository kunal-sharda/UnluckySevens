import ULS_CoreGame

struct TranscriptBubbleCopy: Equatable {
    let caption: String
    let summary: String
}

enum TranscriptBubbleCopyBuilder {
    static func invite(for state: CoreGameStateV1) -> TranscriptBubbleCopy {
        titled("Lobby Invite", summary: "Open this bubble to join the game.")
    }

    static func lobbyJoin(to state: CoreGameStateV1, joiningPlayer: String) -> TranscriptBubbleCopy {
        let joiningName = displayName(for: joiningPlayer, in: state)
        let playerCountCopy = "\(state.roster.count) players are now in the lobby."
        return titled("\(joiningName) Joined", summary: playerCountCopy)
    }

    static func lobbyRename(
        from _: CoreGameStateV1,
        to: CoreGameStateV1,
        player: String,
        previousDisplayName: String
    ) -> TranscriptBubbleCopy {
        let updatedDisplayName = displayName(for: player, in: to)
        if previousDisplayName == updatedDisplayName {
            return titled("Name Updated", summary: "\(updatedDisplayName) updated their lobby name.")
        }

        return titled(
            "Name Updated",
            summary: "\(previousDisplayName) is now \(updatedDisplayName)."
        )
    }

    static func startGame(from _: CoreGameStateV1, to: CoreGameStateV1) -> TranscriptBubbleCopy {
        titled(
            "Game Started",
            summary: "\(to.roster.count) players are entering setup."
        )
    }

    static func setupIntent(
        _ intent: SetupIntentV1,
        resultingState state: CoreGameStateV1,
        actor: String
    ) -> TranscriptBubbleCopy {
        let actorName = displayName(for: actor, in: state)
        if state.phase == .turn {
            return titled(
                "Setup Complete",
                summary: "Opening turn: \(displayName(for: state.currentPlayer, in: state))."
            )
        }

        switch intent {
        case .placeSetupSettlement:
            return titled("Settlement Placed", summary: "\(actorName) placed a setup settlement.")
        case .placeSetupRoad:
            return titled("Road Placed", summary: "\(actorName) placed a setup road.")
        case .placeSetupPair:
            return titled("Setup Placed", summary: "\(actorName) finished a setup placement.")
        }
    }

    static func turnIntent(
        _ intent: TurnIntentV1,
        actor: String,
        resultingState state: CoreGameStateV1
    ) -> TranscriptBubbleCopy {
        if state.phase == .gameOver {
            let winner = displayName(for: state.winnerPlayer, in: state)
            return titled("\(winner) Wins", summary: "Game over at \(state.winningVictoryPoints) points.")
        }

        let actorName = displayName(for: actor, in: state)
        switch intent {
        case .rollDice:
            let rollTotal = state.turnState?.lastRoll.map { $0.d1 + $0.d2 }
            let title = rollTotal.map { "Rolled \($0)" } ?? "Dice Rolled"
            let summary: String
            if rollTotal == 7 {
                summary = "Discards and robber movement are next."
            } else {
                summary = "\(actorName) rolled and play continues."
            }
            return titled(title, summary: summary)
        case .submitDiscard:
            if let nextPending = nextPendingDiscarder(in: state) {
                return titled("Discard Submitted", summary: "Waiting on \(nextPending) to discard.")
            }
            return titled("Discard Submitted", summary: "All required discards are in. Robber movement is next.")
        case .moveRobber:
            if state.turnState?.step == .needsRobberSteal {
                return titled("Robber Moved", summary: "\(actorName) must choose a player to steal from.")
            }
            return titled("Robber Moved", summary: "\(actorName) moved the robber.")
        case let .selectStealVictim(victim):
            return titled(
                "Card Stolen",
                summary: "\(actorName) stole from \(displayName(for: victim, in: state))."
            )
        case .buildRoad:
            return titled("Road Built", summary: "\(actorName) built a road.")
        case .buildSettlement:
            return titled("Settlement Built", summary: "\(actorName) built a settlement.")
        case .buildCity:
            return titled("City Built", summary: "\(actorName) built a city.")
        case let .proposeTrade(_, _, recipients):
            return titled(
                "Trade Offered",
                summary: "\(actorName) offered a trade\(tradeRecipientSummary(for: recipients, in: state))."
            )
        case .acceptTrade:
            return titled("Trade Accepted", summary: "\(actorName) accepted the trade.")
        case .declineTrade:
            return titled("Trade Declined", summary: "\(actorName) declined the trade.")
        case .counterTrade:
            return titled("Counteroffer Sent", summary: "\(actorName) proposed a counteroffer.")
        case .maritimeTrade:
            return titled("Maritime Trade", summary: "\(actorName) traded with the bank.")
        case .buyDevCard:
            return titled("Dev Card Bought", summary: "\(actorName) bought a development card.")
        case .playKnight, .playMonopoly, .playYearOfPlenty, .playRoadBuilding, .revealVictoryPoint:
            return titled(devCardTitle(for: intent), summary: devCardSummary(for: intent, actorName: actorName))
        case .endTurn:
            return titled(
                "Turn Ended",
                summary: "Next turn: \(displayName(for: state.currentPlayer, in: state))."
            )
        }
    }

    private static func titled(_ title: String, summary: String) -> TranscriptBubbleCopy {
        TranscriptBubbleCopy(
            caption: "Unlucky Sevens: \(title)",
            summary: summary
        )
    }

    private static func displayName(for playerID: String?, in state: CoreGameStateV1) -> String {
        PlayerPseudonymResolver.displayName(for: playerID, in: state)
    }

    private static func nextPendingDiscarder(in state: CoreGameStateV1) -> String? {
        guard let turnState = state.turnState, turnState.step == .pendingDiscards else {
            return nil
        }

        for player in state.roster {
            guard turnState.discardRequirementsByPlayer[player, default: 0] > 0 else {
                continue
            }
            guard turnState.submittedDiscardsByPlayer[player] == nil else {
                continue
            }
            return displayName(for: player, in: state)
        }

        return nil
    }

    private static func tradeRecipientSummary(
        for recipients: [String],
        in state: CoreGameStateV1
    ) -> String {
        guard !recipients.isEmpty else {
            return "."
        }

        let displayNames = recipients.map { displayName(for: $0, in: state) }
        return " to \(englishList(displayNames))."
    }

    private static func devCardTitle(for intent: TurnIntentV1) -> String {
        switch intent {
        case .playKnight:
            return "Knight Played"
        case .playMonopoly:
            return "Monopoly Played"
        case .playYearOfPlenty:
            return "Year of Plenty"
        case .playRoadBuilding:
            return "Road Building"
        case .revealVictoryPoint:
            return "Victory Point Revealed"
        default:
            return "Dev Card Played"
        }
    }

    private static func devCardSummary(
        for intent: TurnIntentV1,
        actorName: String
    ) -> String {
        switch intent {
        case .playKnight:
            return "\(actorName) played a Knight."
        case .playMonopoly:
            return "\(actorName) played Monopoly."
        case .playYearOfPlenty:
            return "\(actorName) took two resources from the bank."
        case .playRoadBuilding:
            return "\(actorName) placed two roads."
        case .revealVictoryPoint:
            return "\(actorName) revealed a victory point."
        default:
            return "\(actorName) played a development card."
        }
    }

    private static func englishList(_ values: [String]) -> String {
        switch values.count {
        case 0:
            return ""
        case 1:
            return values[0]
        case 2:
            return "\(values[0]) and \(values[1])"
        default:
            return values.dropLast().joined(separator: ", ") + ", and " + (values.last ?? "")
        }
    }
}
