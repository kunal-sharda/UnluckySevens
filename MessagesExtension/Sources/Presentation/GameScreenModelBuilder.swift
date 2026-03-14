import ULS_CoreGame

enum GameScreenModelBuilder {
    static func build(context: GameScreenContext) -> GameScreenModel {
        let statusLine = makeStatusLine(context: context)

        return GameScreenModel(
            header: GameHeaderModel(
                statusLine: statusLine,
                metaText: context.contextMeta
            ),
            opponents: makeOpponentSummaries(context: context),
            board: GameBoardPlaceholderModel(
                title: statusLine.title,
                subtitle: context.contextBanner
            ),
            boardRenderModel: GameBoardRenderModelBuilder.build(state: context.selectedState),
            handTray: GameHandTrayModel(
                title: "Your Hand",
                chips: makeHandChips(context: context)
            ),
            actionDock: GameActionDockModel(
                items: makeActionDockItems(context: context)
            ),
            modeAvailability: context.modeAvailability
        )
    }

    private static func makeStatusLine(context: GameScreenContext) -> GameShellStatusLine {
        let currentPlayer = context.selectedState?.currentPlayer
        let currentPlayerDisplay = currentPlayer.map(shortIdentifier) ?? "player"

        return GameShellStatusLineResolver.resolve(
            hasTradePending: context.selectedState?.activeTradeOffer != nil,
            actingAs: context.actingAs,
            currentPlayer: currentPlayer,
            currentPlayerDisplay: currentPlayerDisplay,
            subtitle: context.contextBanner
        )
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
                displayName: shortIdentifier(player),
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

    private static func makeActionDockItems(context: GameScreenContext) -> [GameActionDockItem] {
        [
            GameActionDockItem(
                kind: .roll,
                title: "Roll",
                systemImage: "die.face.5",
                isEnabled: context.actionAvailability.canRoll
            ),
            GameActionDockItem(
                kind: .build,
                title: "Build",
                systemImage: "hammer.fill",
                isEnabled: context.actionAvailability.canBuild
            ),
            GameActionDockItem(
                kind: .trade,
                title: "Trade",
                systemImage: "arrow.left.arrow.right",
                isEnabled: context.actionAvailability.canTrade
            ),
            GameActionDockItem(
                kind: .devCards,
                title: "Dev Cards",
                systemImage: "sparkles.rectangle.stack.fill",
                isEnabled: context.actionAvailability.canUseDevCards
            ),
            GameActionDockItem(
                kind: .endTurn,
                title: "End Turn",
                systemImage: "flag.pattern.checkered",
                isEnabled: context.actionAvailability.canEndTurn
            ),
        ]
    }

    private static func shortIdentifier(_ value: String) -> String {
        String(value.prefix(8))
    }
}
