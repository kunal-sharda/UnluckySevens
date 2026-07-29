import ULS_CoreGame

struct TranscriptBubbleCopy: Equatable {
    let caption: String
    let summary: String
    let visual: TranscriptBubbleVisual
}

enum TranscriptBubbleVisual: Equatable {
    case none
    case lobby(LobbyScreenModel)
    case board(TranscriptBoardVisual)
    case trade(TranscriptTradeVisual)
    case gameOver(TranscriptGameOverVisual)
}

struct TranscriptBoardVisual: Equatable {
    let renderModel: GameBoardRenderModel
    let showsNumberTokens: Bool
}

enum TranscriptBubbleCopyBuilder {
    static func invite(for state: CoreGameStateV1) -> TranscriptBubbleCopy {
        titled(
            "Game Invite",
            summary: "Open this bubble to join the game.",
            visual: lobbyVisual(for: state)
        )
    }

    static func lobbyJoin(to state: CoreGameStateV1, joiningPlayer: String) -> TranscriptBubbleCopy {
        let joiningName = displayName(for: joiningPlayer, in: state)
        let count = state.roster.count
        let playerCountCopy = count == 1 ? "1 player at the table." : "\(count) players at the table."
        return titled(
            "\(joiningName) Joined",
            summary: playerCountCopy,
            visual: lobbyVisual(for: state)
        )
    }

    static func lobbyRename(
        from _: CoreGameStateV1,
        to: CoreGameStateV1,
        player: String,
        previousDisplayName: String
    ) -> TranscriptBubbleCopy {
        let updatedDisplayName = displayName(for: player, in: to)
        if previousDisplayName == updatedDisplayName {
            return titled(
                "Name Updated",
                summary: "\(updatedDisplayName) updated their display name.",
                visual: lobbyVisual(for: to)
            )
        }

        return titled(
            "Name Updated",
            summary: "\(previousDisplayName) is now \(updatedDisplayName).",
            visual: lobbyVisual(for: to)
        )
    }

    static func startGame(from _: CoreGameStateV1, to: CoreGameStateV1) -> TranscriptBubbleCopy {
        boardTitled(
            "Game Started",
            summary: "\(to.roster.count) players are entering setup.",
            state: to,
            showsNumberTokens: false
        )
    }

    static func setupIntent(
        _ intent: SetupIntentV1,
        resultingState state: CoreGameStateV1,
        actor: String
    ) -> TranscriptBubbleCopy {
        let actorName = displayName(for: actor, in: state)
        if state.phase == .turn {
            return boardTitled(
                "Setup Complete",
                summary: "Opening turn: \(displayName(for: state.currentPlayer, in: state)).",
                state: state,
                showsNumberTokens: true
            )
        }

        switch intent {
        case .placeSetupSettlement:
            return boardTitled(
                "Settlement Placed",
                summary: "\(actorName) placed a setup settlement.",
                state: state,
                showsNumberTokens: false
            )
        case .placeSetupRoad:
            return boardTitled(
                "Road Placed",
                summary: "\(actorName) placed a setup road.",
                state: state,
                showsNumberTokens: false
            )
        case .placeSetupPair:
            return boardTitled(
                "Setup Placed",
                summary: "\(actorName) finished a setup placement.",
                state: state,
                showsNumberTokens: false
            )
        }
    }

    static func turnIntent(
        _ intent: TurnIntentV1,
        actor: String,
        resultingState state: CoreGameStateV1
    ) -> TranscriptBubbleCopy {
        if state.phase == .gameOver {
            let winner = winnerNames(in: state)
            return titled(
                "\(winner) Wins",
                summary: "Game over at \(state.winningVictoryPoints) points.",
                visual: gameOverVisual(for: state, winnerTitle: "\(winner) won")
            )
        }

        let actorName = displayName(for: actor, in: state)
        switch intent {
        case .rollDice:
            let rollTotal = state.turnState?.lastRoll.map { $0.d1 + $0.d2 }
            let title = rollTotal.map { "Rolled \($0)" } ?? "Dice Rolled"
            let summary: String
            if rollTotal == 7 {
                summary = "Players discard, then the robber moves."
            } else {
                summary = "\(actorName) rolled and play continues."
            }
            return boardTitled(
                title,
                summary: summary,
                state: state
            )
        case .submitDiscard:
            if let nextPending = nextPendingDiscarder(in: state) {
                return boardTitled(
                    "Discard Submitted",
                    summary: "Waiting on \(nextPending) to discard.",
                    state: state
                )
            }
            return boardTitled(
                "Discard Submitted",
                summary: "All required discards are in. Robber movement is next.",
                state: state
            )
        case .moveRobber:
            if state.turnState?.step == .needsRobberSteal {
                return boardTitled(
                    "Robber Moved",
                    summary: "\(actorName) must choose a player to steal from.",
                    state: state
                )
            }
            return boardTitled(
                "Robber Moved",
                summary: "\(actorName) moved the robber.",
                state: state
            )
        case let .selectStealVictim(victim):
            return boardTitled(
                "Card Stolen",
                summary: "\(actorName) stole from \(displayName(for: victim, in: state)).",
                state: state
            )
        case .buildRoad:
            return boardTitled("Road Built", summary: "\(actorName) built a road.", state: state)
        case .buildSettlement:
            return boardTitled(
                "Settlement Built",
                summary: "\(actorName) built a settlement.",
                state: state
            )
        case .buildCity:
            return boardTitled("City Built", summary: "\(actorName) built a city.", state: state)
        case let .proposeTrade(_, _, recipients):
            return titled(
                "Trade Offered",
                summary: "\(actorName) offered a trade\(tradeRecipientSummary(for: recipients, in: state)).",
                visual: liveTradeVisual(for: state)
            )
        case .acceptTrade:
            return boardTitled("Trade Accepted", summary: "\(actorName) accepted the trade.", state: state)
        case .declineTrade:
            return titled(
                "Trade Declined",
                summary: "\(actorName) declined the trade.",
                visual: state.activeTradeOffer == nil
                    ? boardVisual(for: state, showsNumberTokens: true)
                    : liveTradeVisual(for: state)
            )
        case .counterTrade:
            return titled(
                "Counteroffer Sent",
                summary: "\(actorName) proposed a counteroffer.",
                visual: liveTradeVisual(for: state)
            )
        case .maritimeTrade:
            return boardTitled(
                "Bank or Port Trade",
                summary: "\(actorName) completed a Bank or Port trade.",
                state: state
            )
        case .buyDevCard:
            return boardTitled("Dev Card Bought", summary: "\(actorName) bought a development card.", state: state)
        case .playKnight, .playMonopoly, .playYearOfPlenty, .playRoadBuilding, .revealVictoryPoint:
            return boardTitled(
                devCardTitle(for: intent),
                summary: devCardSummary(for: intent, actorName: actorName),
                state: state
            )
        case .endTurn:
            return boardTitled(
                "Turn Ended",
                summary: "Next turn: \(displayName(for: state.currentPlayer, in: state)).",
                state: state
            )
        }
    }

    static func resignation(
        resultingState state: CoreGameStateV1,
        actor: String
    ) -> TranscriptBubbleCopy {
        let actorName = displayName(for: actor, in: state)
        return boardTitled(
            "\(actorName) Resigned",
            summary: "\(actorName) left the game. \(displayName(for: state.currentPlayer, in: state)) has the turn.",
            state: state,
            showsNumberTokens: state.phase == .turn
        )
    }

    static func drawProposed(
        resultingState state: CoreGameStateV1,
        actor: String
    ) -> TranscriptBubbleCopy {
        let actorName = displayName(for: actor, in: state)
        return boardTitled(
            "Draw Proposed",
            summary: "\(actorName) proposed a draw. Every active player must agree.",
            state: state,
            showsNumberTokens: state.phase == .turn
        )
    }

    static func drawVote(
        resultingState state: CoreGameStateV1,
        actor: String,
        approved: Bool
    ) -> TranscriptBubbleCopy {
        let actorName = displayName(for: actor, in: state)
        if state.phase == .gameOver {
            return titled(
                "Draw Agreed",
                summary: "All active players agreed to a draw.",
                visual: gameOverVisual(for: state, winnerTitle: "Draw")
            )
        }
        if approved {
            let approvals = state.drawVote?.approvals.count ?? 0
            return boardTitled(
                "Draw Vote",
                summary: "\(actorName) agreed · \(approvals) of \(state.activePlayers.count) approvals.",
                state: state,
                showsNumberTokens: state.phase == .turn
            )
        }
        return boardTitled(
            "Draw Declined",
            summary: "\(actorName) declined the draw. Play continues.",
            state: state,
            showsNumberTokens: state.phase == .turn
        )
    }

    static func hostEnded(
        resultingState state: CoreGameStateV1,
        actor: String
    ) -> TranscriptBubbleCopy {
        let actorName = displayName(for: actor, in: state)
        return titled(
            "Game Ended",
            summary: "\(actorName) ended the game as host. No winner was declared.",
            visual: gameOverVisual(for: state, winnerTitle: "Game ended")
        )
    }

    static func recoveryResend(
        state: CoreGameStateV1,
        actor: String
    ) -> TranscriptBubbleCopy {
        let actorName = displayName(for: actor, in: state)
        let visual: TranscriptBubbleVisual
        switch state.phase {
        case .lobby:
            visual = lobbyVisual(for: state)
        case .setup:
            visual = boardVisual(for: state, showsNumberTokens: false)
        case .turn:
            visual = boardVisual(for: state, showsNumberTokens: true)
        case .gameOver:
            let title: String
            switch state.gameResult?.reason {
            case .victory:
                title = "\(winnerNames(in: state)) won"
            case .draw:
                title = "Draw"
            case .hostEnded:
                title = "Game ended"
            case nil:
                title = "Game over"
            }
            visual = gameOverVisual(for: state, winnerTitle: title)
        }
        return titled(
            "Game Restored",
            summary: "\(actorName) resent the latest game state.",
            visual: visual
        )
    }

    private static func titled(
        _ title: String,
        summary: String,
        visual: TranscriptBubbleVisual = .none
    ) -> TranscriptBubbleCopy {
        TranscriptBubbleCopy(
            caption: "Unlucky Sevens: \(title)",
            summary: summary,
            visual: visual
        )
    }

    private static func boardTitled(
        _ title: String,
        summary: String,
        state: CoreGameStateV1,
        showsNumberTokens: Bool = true
    ) -> TranscriptBubbleCopy {
        titled(
            title,
            summary: summary,
            visual: boardVisual(for: state, showsNumberTokens: showsNumberTokens)
        )
    }

    private static func lobbyVisual(for state: CoreGameStateV1) -> TranscriptBubbleVisual {
        .lobby(LobbyScreenModelBuilder.transcriptSnapshot(state: state))
    }

    private static func liveTradeVisual(for state: CoreGameStateV1) -> TranscriptBubbleVisual {
        guard
            let panel = GameTradePanelModelBuilder.build(state: state, actingAs: nil),
            let offer = panel.activeOffer
        else {
            return boardVisual(for: state, showsNumberTokens: true)
        }

        let allEligibleRecipients = Set(state.roster.filter { $0 != offer.proposerPlayerID })
        let recipientScopeLabel = Set(offer.recipientPlayerIDs) == allEligibleRecipients
            ? "To everyone"
            : offer.recipientsLabel

        return .trade(
            TranscriptTradeVisual(
                offer: offer,
                participantStatuses: panel.participantStatuses.filter(\.isTargeted),
                recipientScopeLabel: recipientScopeLabel
            )
        )
    }

    private static func gameOverVisual(
        for state: CoreGameStateV1,
        winnerTitle: String
    ) -> TranscriptBubbleVisual {
        guard let renderModel = GameBoardRenderModelBuilder.build(state: state) else {
            return .none
        }

        let scoreLine = state.roster
            .map {
                "\(displayName(for: $0, in: state)) \(victoryPoints(for: $0, in: state))"
            }
            .joined(separator: " · ")
        return .gameOver(
            TranscriptGameOverVisual(
                renderModel: renderModel,
                winnerTitle: winnerTitle,
                scoreLine: scoreLine
            )
        )
    }

    private static func boardVisual(
        for state: CoreGameStateV1,
        showsNumberTokens: Bool
    ) -> TranscriptBubbleVisual {
        guard let renderModel = GameBoardRenderModelBuilder.build(state: state) else {
            return .none
        }

        return .board(
            TranscriptBoardVisual(
                renderModel: renderModel,
                showsNumberTokens: showsNumberTokens
            )
        )
    }

    private static func displayName(for playerID: String?, in state: CoreGameStateV1) -> String {
        PlayerPseudonymResolver.displayName(for: playerID, in: state)
    }

    private static func winnerNames(in state: CoreGameStateV1) -> String {
        let names = state.gameResult?.winnerPlayers.map {
            displayName(for: $0, in: state)
        } ?? state.winnerPlayer.map { [displayName(for: $0, in: state)] } ?? []
        return englishList(names)
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
