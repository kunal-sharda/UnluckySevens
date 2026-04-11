import ULS_CoreGame

enum GameDevCardPanelModelBuilder {
    static func build(
        state: CoreGameStateV1?,
        actingAs: String?
    ) -> GameDevCardPanelModel? {
        guard
            let state,
            state.phase == .turn,
            state.turnState?.step.allowsDevCardPlay == true
        else {
            return nil
        }

        let visibleCards = actingAs.flatMap { actor in
            state.visibleDevCards(for: actor).first(where: { $0.player == actor })
        }
        let playableCounts = counts(from: visibleCards?.revealedPlayable)
        let newCounts = counts(from: visibleCards?.revealedNew)
        let timingNotes = makeTimingNotes(
            state: state,
            actingAs: actingAs,
            playableCounts: playableCounts,
            newCounts: newCounts
        )

        guard let actingAs else {
            return GameDevCardPanelModel(
                message: "Development-card actions are unavailable without a local player identity.",
                playableCounts: playableCounts,
                newCounts: newCounts,
                buyAction: nil,
                playActions: [],
                timingNotes: timingNotes
            )
        }

        guard actingAs == state.currentPlayer else {
            return GameDevCardPanelModel(
                message: waitingMessage(
                    currentPlayer: state.currentPlayer,
                    state: state,
                    playableCounts: playableCounts,
                    newCounts: newCounts
                ),
                playableCounts: playableCounts,
                newCounts: newCounts,
                buyAction: nil,
                playActions: [],
                timingNotes: timingNotes
            )
        }

        let canBuyDevCard = DevCardInteractionResolver.draftBuyDevCardIntent(state: state, actingAs: actingAs) != nil
        let playActions = [
            makeKnightAction(state: state, actingAs: actingAs),
            makeMonopolyAction(state: state, actingAs: actingAs),
            makeYearOfPlentyAction(state: state, actingAs: actingAs),
            makeRoadBuildingAction(state: state, actingAs: actingAs),
            makeRevealVictoryPointAction(state: state, actingAs: actingAs),
        ]
        .compactMap { $0 }

        return GameDevCardPanelModel(
            message: productMessage(
                state: state,
                canBuyDevCard: canBuyDevCard,
                playActions: playActions,
                playableCounts: playableCounts,
                newCounts: newCounts
            ),
            playableCounts: playableCounts,
            newCounts: newCounts,
            buyAction: nil,
            playActions: playActions,
            timingNotes: timingNotes
        )
    }

    private static func makeKnightAction(
        state: CoreGameStateV1,
        actingAs: String
    ) -> GameDevCardAction? {
        guard let knightIntent = DevCardInteractionResolver.draftPlayKnightIntent(state: state, actingAs: actingAs),
              let knightTileID = knightIntent.devCardTileID else {
            return nil
        }

        let victimDetail: String
        if let victim = knightIntent.devCardVictimPlayer {
            victimDetail = " and steal from \(playerName(victim, in: state))"
        } else {
            victimDetail = ""
        }

        return GameDevCardAction(
            kind: .playKnight,
            title: "Play Knight",
            detail: "Current product path uses the core default: move the robber to tile \(knightTileID)\(victimDetail).",
            systemImage: "shield.lefthalf.filled"
        )
    }

    private static func makeMonopolyAction(
        state: CoreGameStateV1,
        actingAs: String
    ) -> GameDevCardAction? {
        guard let resource = state.defaultMonopolyResource(for: actingAs),
              DevCardInteractionResolver.draftPlayMonopolyIntent(state: state, actingAs: actingAs) != nil else {
            return nil
        }

        let total = state.roster
            .filter { $0 != actingAs }
            .reduce(0) { partialResult, player in
                partialResult + (state.resourcesByPlayer[player] ?? .zero).count(for: resource)
            }

        return GameDevCardAction(
            kind: .playMonopoly,
            title: "Play Monopoly",
            detail: "Current best default is \(resourceLabel(resource)); it would claim up to \(total) cards from opponents.",
            systemImage: "shippingbox.fill"
        )
    }

    private static func makeYearOfPlentyAction(
        state: CoreGameStateV1,
        actingAs: String
    ) -> GameDevCardAction? {
        guard let selection = state.defaultYearOfPlentyResources(),
              DevCardInteractionResolver.draftPlayYearOfPlentyIntent(state: state, actingAs: actingAs) != nil else {
            return nil
        }

        return GameDevCardAction(
            kind: .playYearOfPlenty,
            title: "Play Year Of Plenty",
            detail: "Take \(resourceLabel(selection.first)) and \(resourceLabel(selection.second)) from the bank using the core default.",
            systemImage: "leaf.fill"
        )
    }

    private static func makeRoadBuildingAction(
        state: CoreGameStateV1,
        actingAs: String
    ) -> GameDevCardAction? {
        guard let edges = state.defaultRoadBuildingEdges(for: actingAs),
              DevCardInteractionResolver.draftPlayRoadBuildingIntent(state: state, actingAs: actingAs) != nil else {
            return nil
        }

        return GameDevCardAction(
            kind: .playRoadBuilding,
            title: "Play Road Building",
            detail: "The current product path uses the default connected pair: \(edges.firstEdgeID) and \(edges.secondEdgeID).",
            systemImage: "road.lanes"
        )
    }

    private static func makeRevealVictoryPointAction(
        state: CoreGameStateV1,
        actingAs: String
    ) -> GameDevCardAction? {
        guard DevCardInteractionResolver.draftRevealVictoryPointIntent(state: state, actingAs: actingAs) != nil else {
            return nil
        }

        let newVictoryPoints = (state.newDevCardsByPlayer[actingAs] ?? .zero).victoryPoint
        let detail: String
        if newVictoryPoints > 0 {
            detail = "Reveal one hidden victory point now. Newly bought victory points can be revealed immediately."
        } else {
            detail = "Reveal one hidden victory point now to convert it into visible score."
        }

        return GameDevCardAction(
            kind: .revealVictoryPoint,
            title: "Reveal Victory Point",
            detail: detail,
            systemImage: "star.circle.fill"
        )
    }

    private static func productMessage(
        state: CoreGameStateV1,
        canBuyDevCard: Bool,
        playActions: [GameDevCardAction],
        playableCounts: [GameDevCardCount],
        newCounts: [GameDevCardCount]
    ) -> String {
        if state.devCardActionPlayedThisTurn {
            if playActions.contains(where: { $0.kind == .revealVictoryPoint }) {
                return "You already used a development-card action this turn. Victory Point reveals may still be available."
            }
            return "You already used a development-card action this turn."
        }

        if !canBuyDevCard, playActions.isEmpty {
            if playableCounts.isEmpty, newCounts.isEmpty {
                return "You do not have any development-card actions available right now."
            }
            return "No legal development-card action is available from the current state."
        }

        if !playActions.isEmpty {
            return "Choose one of the legal cards already available to you."
        }

        return "No legal development-card play is available right now."
    }

    private static func waitingMessage(
        currentPlayer: String,
        state: CoreGameStateV1,
        playableCounts: [GameDevCardCount],
        newCounts: [GameDevCardCount]
    ) -> String {
        if playableCounts.isEmpty, newCounts.isEmpty {
            return "Waiting for \(playerName(currentPlayer, in: state)) to use development cards."
        }

        return "You can review your development cards here, but only \(playerName(currentPlayer, in: state)) can act right now."
    }

    private static func makeTimingNotes(
        state: CoreGameStateV1,
        actingAs: String?,
        playableCounts: [GameDevCardCount],
        newCounts: [GameDevCardCount]
    ) -> [String] {
        var notes: [String] = []

        if !newCounts.isEmpty {
            notes.append("Newly bought non-Victory Point development cards stay locked until your next turn.")
        }

        if let actingAs, state.devCardActionPlayedThisTurn, actingAs == state.currentPlayer {
            notes.append("Only one non-Victory Point development-card action can be played per turn.")
        } else if !playableCounts.isEmpty {
            notes.append("Only one non-Victory Point development-card action can be played per turn.")
        }

        if victoryPointCount(in: newCounts) > 0 || victoryPointCount(in: playableCounts) > 0 {
            notes.append("Victory Point cards can be revealed immediately, including the turn they were bought.")
        }

        return notes
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

    private static func victoryPointCount(in counts: [GameDevCardCount]) -> Int {
        counts.first(where: { $0.title == "Victory Point" })?.count ?? 0
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

    private static func playerName(_ playerID: String, in state: CoreGameStateV1) -> String {
        PlayerPseudonymResolver.displayName(for: playerID, gameID: state.gameId, roster: state.roster)
    }

}
