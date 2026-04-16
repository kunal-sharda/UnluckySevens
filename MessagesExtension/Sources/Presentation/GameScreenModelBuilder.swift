import ULS_CoreGame

enum GameScreenModelBuilder {
    static func build(context: GameScreenContext) -> GameScreenModel {
        let statusLine = makeStatusLine(context: context)
        let actionAvailability = resolvedActionAvailability(context: context)

        return GameScreenModel(
            header: GameHeaderModel(
                statusLine: statusLine,
                metaText: makeMetaText(context: context)
            ),
            opponents: makeOpponentSummaries(context: context),
            board: GameBoardPlaceholderModel(
                title: statusLine.title,
                subtitle: statusLine.subtitle
            ),
            boardRenderModel: GameBoardRenderModelBuilder.build(state: context.selectedState),
            handTray: GameHandTrayModel(
                title: "Your Hand",
                chips: makeHandChips(context: context)
            ),
            actionDock: makeActionDockModel(
                actionAvailability: actionAvailability,
                modeAvailability: context.modeAvailability
            ),
            modeAvailability: context.modeAvailability
        )
    }

    private static func makeStatusLine(context: GameScreenContext) -> GameShellStatusLine {
        let state = context.selectedState
        let currentPlayer = state?.currentPlayer
        let currentPlayerDisplay = currentPlayer.map {
            PlayerPseudonymResolver.displayName(for: $0, gameID: state?.gameId, roster: state?.roster ?? [])
        } ?? "player"
        let winnerDisplay = state?.winnerPlayer.map {
            PlayerPseudonymResolver.displayName(for: $0, gameID: state?.gameId, roster: state?.roster ?? [])
        }

        return GameShellStatusLineResolver.resolve(
            actingAs: context.actingAs,
            currentPlayer: currentPlayer,
            currentPlayerDisplay: currentPlayerDisplay,
            subtitle: makeSubtitle(context: context),
            phase: state?.phase,
            winnerDisplay: winnerDisplay,
            didLocalPlayerWin: context.actingAs == state?.winnerPlayer
        )
    }

    private static func makeSubtitle(context: GameScreenContext) -> String {
        guard let state = context.selectedState else {
            return "Open a game bubble to continue."
        }

        if state.phase == .gameOver {
            return finalScoreSummary(for: state)
        }

        if state.phase == .turn, let roll = state.turnState?.lastRoll {
            return "Roll: \(roll.d1) + \(roll.d2) = \(roll.d1 + roll.d2)"
        }

        if state.phase == .turn {
            return "Roll pending"
        }

        return ""
    }

    private static func makeMetaText(context: GameScreenContext) -> String {
        guard let state = context.selectedState, state.phase == .gameOver else {
            return ""
        }

        return recapSummary(for: state) ?? ""
    }

    private static func makeOpponentSummaries(context: GameScreenContext) -> [GameOpponentSummary] {
        guard let state = context.selectedState else {
            return []
        }

        let handCounts = Dictionary(
            uniqueKeysWithValues: state.visibleResourceHands(for: context.actingAs).map { ($0.player, $0.totalCount) }
        )
        let victoryPoints = victoryPointsByPlayer(in: state)

        return state.roster.compactMap { player in
            if player == context.actingAs {
                return nil
            }

            return GameOpponentSummary(
                id: player,
                displayName: PlayerPseudonymResolver.displayName(for: player, gameID: state.gameId, roster: state.roster),
                victoryPoints: victoryPoints[player] ?? 0,
                handCount: handCounts[player] ?? 0,
                isCurrentPlayer: player == state.currentPlayer
            )
        }
    }

    private static func makeHandChips(context: GameScreenContext) -> [GameHandChip] {
        guard
            let state = context.selectedState,
            let localActor = context.actingAs,
            let revealedHand = state
                .visibleResourceHands(for: localActor)
                .first(where: { $0.player == localActor })?
                .revealedHand
        else {
            return []
        }

        return [
            GameHandChip(resource: .wood, count: revealedHand.wood),
            GameHandChip(resource: .brick, count: revealedHand.brick),
            GameHandChip(resource: .sheep, count: revealedHand.sheep),
            GameHandChip(resource: .wheat, count: revealedHand.wheat),
            GameHandChip(resource: .ore, count: revealedHand.ore),
        ]
    }

    private static func resolvedActionAvailability(context: GameScreenContext) -> GameActionAvailability {
        if context.selectedState?.phase == .gameOver {
            return .none
        }

        return context.actionAvailability
    }

    private static func makeActionDockModel(
        actionAvailability: GameActionAvailability,
        modeAvailability: GameModeAvailability
    ) -> GameActionDockModel {
        let shouldShowTradeInPrimarySlot = !actionAvailability.canRoll && (
            actionAvailability.canTrade
                || actionAvailability.canEndTurn
                || actionAvailability.canBuild
                || actionAvailability.canBuyDevCard
                || actionAvailability.canPlayDevCards
        )
        let leadingPrimaryItem = GameActionDockItem(
            kind: shouldShowTradeInPrimarySlot ? .trade : .roll,
            title: shouldShowTradeInPrimarySlot ? "Trade" : "Roll",
            systemImage: shouldShowTradeInPrimarySlot ? "arrow.left.arrow.right" : "die.face.5",
            isEnabled: shouldShowTradeInPrimarySlot ? actionAvailability.canTrade : actionAvailability.canRoll
        )

        return GameActionDockModel(
            primaryItems: [
                leadingPrimaryItem,
                GameActionDockItem(
                    kind: .endTurn,
                    title: "End Turn",
                    systemImage: "flag.fill",
                    isEnabled: actionAvailability.canEndTurn
                ),
                GameActionDockItem(
                    kind: .build,
                    title: "Build",
                    systemImage: "hammer.fill",
                    isEnabled: actionAvailability.canBuild || actionAvailability.canBuyDevCard
                ),
                GameActionDockItem(
                    kind: .devCards,
                    title: "Play Dev",
                    systemImage: "sparkles.rectangle.stack.fill",
                    isEnabled: actionAvailability.canPlayDevCards
                ),
            ],
            utilityItems: [],
            buildShelfItems: [
                GameBuildShelfItem(
                    kind: .buildRoad,
                    title: "Road",
                    systemImage: "road.lanes",
                    isEnabled: modeAvailability.canBuildRoad
                ),
                GameBuildShelfItem(
                    kind: .buildSettlement,
                    title: "Settlement",
                    systemImage: "house.fill",
                    isEnabled: modeAvailability.canBuildSettlement
                ),
                GameBuildShelfItem(
                    kind: .buildCity,
                    title: "City",
                    systemImage: "building.2.fill",
                    isEnabled: modeAvailability.canBuildCity
                ),
                GameBuildShelfItem(
                    kind: .buyDevCard,
                    title: "Buy Dev",
                    systemImage: "plus.rectangle.on.folder.fill",
                    isEnabled: actionAvailability.canBuyDevCard
                ),
            ].filter(\.isEnabled)
        )
    }

    private static func finalScoreSummary(for state: CoreGameStateV1) -> String {
        let scoreLine = state.roster
            .map { "\(PlayerPseudonymResolver.displayName(for: $0, gameID: state.gameId, roster: state.roster)) \(victoryPoints(for: $0, in: state))" }
            .joined(separator: " | ")
        return "Final score: \(scoreLine)"
    }

    private static func recapSummary(for state: CoreGameStateV1) -> String? {
        guard let recap = state.lastTurnRecap else {
            return nil
        }

        var parts: [String] = []
        if let rollTotal = recap.rollTotal {
            parts.append("rolled \(rollTotal)")
        }

        let actionText = recap.actions
            .prefix(3)
            .map(actionLabel)
            .joined(separator: ", ")
        if !actionText.isEmpty {
            parts.append(actionText)
        }

        guard !parts.isEmpty else {
            return nil
        }

        return "Last turn: \(PlayerPseudonymResolver.displayName(for: recap.actor, gameID: state.gameId, roster: state.roster)) \(parts.joined(separator: ", "))"
    }

    private static func actionLabel(_ action: AuditActionV1) -> String {
        switch action {
        case .rollDice:
            return "rolled"
        case .submitDiscard:
            return "discarded"
        case .moveRobber:
            return "moved robber"
        case .selectStealVictim:
            return "stole"
        case .buildRoad:
            return "built road"
        case .buildSettlement:
            return "built settlement"
        case .buildCity:
            return "built city"
        case .proposeTrade:
            return "offered trade"
        case .acceptTrade:
            return "accepted trade"
        case .declineTrade:
            return "declined trade"
        case .counterTrade:
            return "countered trade"
        case .executeTrade:
            return "executed trade"
        case .maritimeTrade:
            return "maritime trade"
        case .buyDevCard:
            return "bought dev card"
        case .playKnight:
            return "played knight"
        case .playMonopoly:
            return "played monopoly"
        case .playYearOfPlenty:
            return "played year of plenty"
        case .playRoadBuilding:
            return "played road building"
        case .revealVictoryPoint:
            return "revealed VP"
        case .endTurn:
            return "ended turn"
        }
    }
}
