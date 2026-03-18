import ULS_CoreGame

enum GameDevCardPanelModelBuilder {
    static func build(
        state: CoreGameStateV1?,
        actingAs: String?
    ) -> GameDevCardPanelModel? {
        guard
            let state,
            state.phase == .turn,
            state.turnState?.step == .afterRoll
        else {
            return nil
        }

        let visibleCards = actingAs.flatMap { actor in
            state.visibleDevCards(for: actor).first(where: { $0.player == actor })
        }
        let playableCounts = counts(from: visibleCards?.revealedPlayable)
        let newCounts = counts(from: visibleCards?.revealedNew)

        guard let actingAs else {
            return GameDevCardPanelModel(
                message: "Development-card actions are unavailable without a local player identity.",
                playableCounts: playableCounts,
                newCounts: newCounts,
                actions: []
            )
        }

        guard actingAs == state.currentPlayer else {
            return GameDevCardPanelModel(
                message: "Waiting for \(shortIdentifier(state.currentPlayer)) to use development cards.",
                playableCounts: playableCounts,
                newCounts: newCounts,
                actions: []
            )
        }

        var actions: [GameDevCardAction] = []

        if DevCardInteractionResolver.draftBuyDevCardIntent(state: state, actingAs: actingAs) != nil {
            actions.append(
                GameDevCardAction(
                    kind: .buyDevCard,
                    title: "Buy Development Card",
                    detail: "Spend sheep, wheat, and ore to draw one card from the remaining deck.",
                    systemImage: "plus.rectangle.on.folder.fill"
                )
            )
        }

        if let knightIntent = DevCardInteractionResolver.draftPlayKnightIntent(state: state, actingAs: actingAs),
           let knightTileID = knightIntent.devCardTileID {
            let victim = knightIntent.devCardVictimPlayer.map(shortIdentifier) ?? "no one"
            actions.append(
                GameDevCardAction(
                    kind: .playKnight,
                    title: "Play Knight",
                    detail: "Use the current default robber move on tile \(knightTileID) and steal from \(victim).",
                    systemImage: "shield.lefthalf.filled"
                )
            )
        }

        if let resource = state.defaultMonopolyResource(for: actingAs),
           DevCardInteractionResolver.draftPlayMonopolyIntent(state: state, actingAs: actingAs) != nil {
            actions.append(
                GameDevCardAction(
                    kind: .playMonopoly,
                    title: "Play Monopoly",
                    detail: "Claim all \(resourceLabel(resource)) from opponents using the current core default.",
                    systemImage: "shippingbox.fill"
                )
            )
        }

        if let selection = state.defaultYearOfPlentyResources(),
           DevCardInteractionResolver.draftPlayYearOfPlentyIntent(state: state, actingAs: actingAs) != nil {
            actions.append(
                GameDevCardAction(
                    kind: .playYearOfPlenty,
                    title: "Play Year Of Plenty",
                    detail: "Take \(resourceLabel(selection.first)) and \(resourceLabel(selection.second)) from the bank.",
                    systemImage: "leaf.fill"
                )
            )
        }

        if let edges = state.defaultRoadBuildingEdges(for: actingAs),
           DevCardInteractionResolver.draftPlayRoadBuildingIntent(state: state, actingAs: actingAs) != nil {
            actions.append(
                GameDevCardAction(
                    kind: .playRoadBuilding,
                    title: "Play Road Building",
                    detail: "Build two connected roads on the current default pair: \(edges.firstEdgeID) and \(edges.secondEdgeID).",
                    systemImage: "road.lanes"
                )
            )
        }

        if DevCardInteractionResolver.draftRevealVictoryPointIntent(state: state, actingAs: actingAs) != nil {
            actions.append(
                GameDevCardAction(
                    kind: .revealVictoryPoint,
                    title: "Reveal Victory Point",
                    detail: "Reveal one hidden victory point card immediately.",
                    systemImage: "star.circle.fill"
                )
            )
        }

        let message: String
        if actions.isEmpty {
            message = "No legal dev-card action is available from the current state."
        } else {
            message = "Pick a compact dev-card action. Current suggestions come from core defaults so the flow stays shallow inside Messages."
        }

        return GameDevCardPanelModel(
            message: message,
            playableCounts: playableCounts,
            newCounts: newCounts,
            actions: actions
        )
    }

    private static func counts(from inventory: DevCardInventoryV1?) -> [GameDevCardCount] {
        guard let inventory else {
            return []
        }

        return [
            GameDevCardCount(title: "Knight", count: inventory.knight),
            GameDevCardCount(title: "Monopoly", count: inventory.monopoly),
            GameDevCardCount(title: "Year of Plenty", count: inventory.yearOfPlenty),
            GameDevCardCount(title: "Road Building", count: inventory.roadBuilding),
            GameDevCardCount(title: "Victory Point", count: inventory.victoryPoint),
        ]
        .filter { $0.count > 0 }
    }

    private static func resourceLabel(_ resource: ResourceV1) -> String {
        switch resource {
        case .wood:
            return "wood"
        case .brick:
            return "brick"
        case .sheep:
            return "sheep"
        case .wheat:
            return "wheat"
        case .ore:
            return "ore"
        case .desert:
            return "desert"
        }
    }

    private static func shortIdentifier(_ value: String) -> String {
        String(value.prefix(8))
    }
}
