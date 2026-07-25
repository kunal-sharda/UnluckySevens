import SpriteKit
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
            ownedDevCards: makeOwnedDevCards(context: context),
            gameInfo: makeGameInfo(context: context),
            devDeckCount: context.selectedState?.devDeck.count ?? 0,
            canBuyDevCard: actionAvailability.canBuyDevCard,
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
            PlayerPseudonymResolver.displayName(for: $0, in: state)
        } ?? "player"
        let winnerDisplay = state?.winnerPlayer.map {
            PlayerPseudonymResolver.displayName(for: $0, in: state)
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
                displayName: PlayerPseudonymResolver.displayName(for: player, in: state),
                playerTint: playerTint(for: player, roster: state.roster),
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

    private static func makeOwnedDevCards(context: GameScreenContext) -> [GameOwnedDevCardSummary] {
        guard
            let state = context.selectedState,
            let actor = context.actingAs,
            let visible = state.visibleDevCards(for: actor).first(where: { $0.player == actor }),
            let playable = visible.revealedPlayable,
            let newCards = visible.revealedNew
        else {
            return []
        }

        return GameDevCardVisualKind.allCases.compactMap { kind in
            let playableCount = devCardCount(kind, in: playable)
            let newCount = devCardCount(kind, in: newCards)
            guard playableCount + newCount > 0 else { return nil }
            return GameOwnedDevCardSummary(
                kind: kind,
                playableCount: playableCount,
                newCount: newCount
            )
        }
    }

    private static func makeGameInfo(context: GameScreenContext) -> GameInfoModel {
        guard let state = context.selectedState else { return .empty }
        let resourceCounts = Dictionary(
            uniqueKeysWithValues: state.visibleResourceHands(for: context.actingAs).map { ($0.player, $0.totalCount) }
        )
        let devCounts = Dictionary(
            uniqueKeysWithValues: state.visibleDevCards(for: context.actingAs).map { ($0.player, $0.totalCount) }
        )

        let players = state.roster.map { player in
            var awards: [String] = []
            if state.longestRoadOwner == player { awards.append("Longest Road") }
            if state.largestArmyOwner == player { awards.append("Largest Army") }
            return GameInfoPlayerSummary(
                id: player,
                displayName: PlayerPseudonymResolver.displayName(for: player, in: state),
                playerTint: playerTint(for: player, roster: state.roster),
                victoryPoints: victoryPoints(for: player, in: state),
                resourceCardCount: resourceCounts[player] ?? 0,
                developmentCardCount: devCounts[player] ?? 0,
                isCurrentPlayer: state.currentPlayer == player,
                isLocalPlayer: context.actingAs == player,
                awardLabels: awards
            )
        }

        return GameInfoModel(players: players, recapText: recapSummary(for: state))
    }

    private static func devCardCount(
        _ kind: GameDevCardVisualKind,
        in inventory: DevCardInventoryV1
    ) -> Int {
        switch kind {
        case .knight: return inventory.knight
        case .monopoly: return inventory.monopoly
        case .yearOfPlenty: return inventory.yearOfPlenty
        case .roadBuilding: return inventory.roadBuilding
        case .victoryPoint: return inventory.victoryPoint
        }
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
                    isEnabled: actionAvailability.canBuild
                ),
                GameActionDockItem(
                    kind: .devCards,
                    title: "Dev Cards",
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
                    cost: CoreBuildCostsV1.road,
                    placementInstruction: "Tap a highlighted edge, then tap it again to build.",
                    isEnabled: modeAvailability.canBuildRoad
                ),
                GameBuildShelfItem(
                    kind: .buildSettlement,
                    title: "Settlement",
                    systemImage: "house.fill",
                    cost: CoreBuildCostsV1.settlement,
                    placementInstruction: "Tap a highlighted corner, then tap it again to build.",
                    isEnabled: modeAvailability.canBuildSettlement
                ),
                GameBuildShelfItem(
                    kind: .buildCity,
                    title: "City",
                    systemImage: "building.2.fill",
                    cost: CoreBuildCostsV1.city,
                    placementInstruction: "Tap one of your highlighted settlements, then tap it again to upgrade.",
                    isEnabled: modeAvailability.canBuildCity
                ),
            ].filter(\.isEnabled)
        )
    }

    private static func finalScoreSummary(for state: CoreGameStateV1) -> String {
        let scoreLine = state.roster
            .map { "\(PlayerPseudonymResolver.displayName(for: $0, in: state)) \(victoryPoints(for: $0, in: state))" }
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

        return "Last turn: \(PlayerPseudonymResolver.displayName(for: recap.actor, in: state)) \(parts.joined(separator: ", "))"
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
        case .maritimeTrade:
            return "Bank or Port trade"
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

    private static func playerTint(for player: String, roster: [String]) -> GamePlayerTint {
        let color = GameBoardPalette.playerColor(owner: player, playerOrder: roster)
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        color.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        return GamePlayerTint(
            red: Double(red),
            green: Double(green),
            blue: Double(blue)
        )
    }
}
