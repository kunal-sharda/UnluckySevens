import ULS_CoreGame

enum GameDevCardPanelModelBuilder {
    static func build(
        state: CoreGameStateV1?,
        actingAs: String?,
        mode: GameMode = .playDevCard,
        draft: GameDevCardDraft? = nil
    ) -> GameDevCardPanelModel? {
        guard
            let state,
            state.phase == .turn,
            mode.isDevCardMode,
            state.turnState?.step.allowsDevCardPlay == true
        else {
            return nil
        }

        let visibleCards = actingAs.flatMap { actor in
            state.visibleDevCards(for: actor).first(where: { $0.player == actor })
        }
        let revealedPlayable = visibleCards?.revealedPlayable ?? .zero
        let revealedNew = visibleCards?.revealedNew ?? .zero
        let playActions = actingAs.map { rootActions(state: state, actingAs: $0) } ?? []
        let playableCounts = actionableCounts(
            from: revealedPlayable,
            state: state,
            actingAs: actingAs,
            playActions: playActions
        )
        let heldCounts = heldCounts(
            from: revealedPlayable,
            playableCounts: playableCounts
        )
        let newCounts = counts(from: revealedNew)
        let timingNotes = makeTimingNotes(
            state: state,
            actingAs: actingAs,
            playableCounts: playableCounts,
            heldCounts: heldCounts,
            newCounts: newCounts
        )

        guard let actingAs else {
            return GameDevCardPanelModel(
                message: "Development-card actions are unavailable without a local player identity.",
                playableCounts: playableCounts,
                heldCounts: heldCounts,
                newCounts: newCounts,
                playActions: [],
                timingNotes: timingNotes,
                draftSummary: nil,
                confirmTitle: nil,
                canConfirm: false,
                showsBackButton: false
            )
        }

        guard actingAs == state.currentPlayer else {
            return GameDevCardPanelModel(
                message: waitingMessage(
                    currentPlayer: state.currentPlayer,
                    state: state,
                    playableCounts: playableCounts,
                    heldCounts: heldCounts,
                    newCounts: newCounts
                ),
                playableCounts: playableCounts,
                heldCounts: heldCounts,
                newCounts: newCounts,
                playActions: [],
                timingNotes: timingNotes,
                draftSummary: nil,
                confirmTitle: nil,
                canConfirm: false,
                showsBackButton: false
            )
        }
        switch mode {
        case .playDevCard:
            return GameDevCardPanelModel(
                message: productMessage(
                    state: state,
                    playActions: playActions,
                    playableCounts: playableCounts,
                    heldCounts: heldCounts,
                    newCounts: newCounts
                ),
                playableCounts: playableCounts,
                heldCounts: heldCounts,
                newCounts: newCounts,
                playActions: playActions,
                timingNotes: timingNotes,
                draftSummary: nil,
                confirmTitle: nil,
                canConfirm: false,
                showsBackButton: false
            )
        case .devCardKnightMove:
            return stagedModel(
                message: "Choose the robber's destination tile on the board.",
                playableCounts: playableCounts,
                heldCounts: heldCounts,
                newCounts: newCounts,
                timingNotes: timingNotes,
                draftSummary: draftSummary(for: draft, in: state),
                confirmTitle: nil,
                canConfirm: false
            )
        case .devCardKnightVictim:
            return stagedModel(
                message: "Choose one highlighted victim to steal from.",
                playableCounts: playableCounts,
                heldCounts: heldCounts,
                newCounts: newCounts,
                timingNotes: timingNotes,
                draftSummary: draftSummary(for: draft, in: state),
                confirmTitle: nil,
                canConfirm: false
            )
        case .devCardMonopoly:
            let selectedResource = monopolyResource(from: draft)
            let selectedPreview = state.monopolyPreviews(for: actingAs).first { $0.resource == selectedResource }
            return stagedModel(
                message: "Choose one resource from the bank strip, then confirm the play.",
                playableCounts: playableCounts,
                heldCounts: heldCounts,
                newCounts: newCounts,
                timingNotes: timingNotes,
                draftSummary: selectedPreview.map {
                    "Selected \(resourceLabel($0.resource)). This will claim up to \($0.claimCount) cards."
                },
                confirmTitle: "Play Monopoly",
                canConfirm: selectedResource != nil
            )
        case .devCardYearOfPlenty:
            let selection = yearOfPlentySelection(from: draft)
            return stagedModel(
                message: yearOfPlentyMessage(first: selection.first, second: selection.second),
                playableCounts: playableCounts,
                heldCounts: heldCounts,
                newCounts: newCounts,
                timingNotes: timingNotes,
                draftSummary: yearOfPlentySummary(first: selection.first, second: selection.second),
                confirmTitle: "Play Year Of Plenty",
                canConfirm: selection.first != nil && selection.second != nil
            )
        case .devCardRoadBuildingFirst:
            return stagedModel(
                message: "Choose the first highlighted road on the board.",
                playableCounts: playableCounts,
                heldCounts: heldCounts,
                newCounts: newCounts,
                timingNotes: timingNotes,
                draftSummary: draftSummary(for: draft, in: state),
                confirmTitle: nil,
                canConfirm: false
            )
        case .devCardRoadBuildingSecond:
            return stagedModel(
                message: "Choose the second highlighted road connected to the first.",
                playableCounts: playableCounts,
                heldCounts: heldCounts,
                newCounts: newCounts,
                timingNotes: timingNotes,
                draftSummary: draftSummary(for: draft, in: state),
                confirmTitle: nil,
                canConfirm: false
            )
        case .idle, .setup, .buildRoad, .buildSettlement, .buildCity, .robberMove, .robberVictim, .trade, .discard:
            return nil
        }
    }

    private static func rootActions(
        state: CoreGameStateV1,
        actingAs: String
    ) -> [GameDevCardAction] {
        [
            makeKnightAction(state: state, actingAs: actingAs),
            makeMonopolyAction(state: state, actingAs: actingAs),
            makeYearOfPlentyAction(state: state, actingAs: actingAs),
            makeRoadBuildingAction(state: state, actingAs: actingAs),
            makeRevealVictoryPointAction(state: state, actingAs: actingAs),
        ]
        .compactMap { $0 }
    }

    private static func stagedModel(
        message: String,
        playableCounts: [GameDevCardCount],
        heldCounts: [GameDevCardCount],
        newCounts: [GameDevCardCount],
        timingNotes: [String],
        draftSummary: String?,
        confirmTitle: String?,
        canConfirm: Bool
    ) -> GameDevCardPanelModel {
        GameDevCardPanelModel(
            message: message,
            playableCounts: playableCounts,
            heldCounts: heldCounts,
            newCounts: newCounts,
            playActions: [],
            timingNotes: timingNotes,
            draftSummary: draftSummary,
            confirmTitle: confirmTitle,
            canConfirm: canConfirm,
            showsBackButton: true
        )
    }

    private static func makeKnightAction(
        state: CoreGameStateV1,
        actingAs: String
    ) -> GameDevCardAction? {
        guard !state.legalKnightMoveTilesForDevCard(for: actingAs).isEmpty else {
            return nil
        }

        return GameDevCardAction(
            kind: .playKnight,
            title: "Play Knight",
            detail: "Choose a robber tile, then choose a victim only if the new tile has multiple eligible steals.",
            systemImage: "shield.lefthalf.filled"
        )
    }

    private static func makeMonopolyAction(
        state: CoreGameStateV1,
        actingAs: String
    ) -> GameDevCardAction? {
        let previews = state.monopolyPreviews(for: actingAs)
        guard !previews.isEmpty else {
            return nil
        }

        let bestPreview = previews.max { lhs, rhs in
            if lhs.claimCount != rhs.claimCount {
                return lhs.claimCount < rhs.claimCount
            }
            return resourceLabel(lhs.resource) > resourceLabel(rhs.resource)
        }
        let detail: String
        if let bestPreview {
            detail = "Choose any resource from the bank strip. Best current target is \(resourceLabel(bestPreview.resource)) for up to \(bestPreview.claimCount) cards."
        } else {
            detail = "Choose any resource from the bank strip."
        }

        return GameDevCardAction(
            kind: .playMonopoly,
            title: "Play Monopoly",
            detail: detail,
            systemImage: "shippingbox.fill"
        )
    }

    private static func makeYearOfPlentyAction(
        state: CoreGameStateV1,
        actingAs: String
    ) -> GameDevCardAction? {
        let options = state.yearOfPlentyBankOptions(for: actingAs)
        guard canChooseYearOfPlenty(from: options) else {
            return nil
        }

        return GameDevCardAction(
            kind: .playYearOfPlenty,
            title: "Play Year Of Plenty",
            detail: "Choose two resources from the bank strip. The same resource can be picked twice only when the bank still has two.",
            systemImage: "leaf.fill"
        )
    }

    private static func makeRoadBuildingAction(
        state: CoreGameStateV1,
        actingAs: String
    ) -> GameDevCardAction? {
        guard !state.legalRoadBuildingFirstEdges(for: actingAs).isEmpty else {
            return nil
        }

        return GameDevCardAction(
            kind: .playRoadBuilding,
            title: "Play Road Building",
            detail: "Choose a first road, then a connected second road. The action only appears when a full two-road pair is legal.",
            systemImage: "road.lanes"
        )
    }

    private static func makeRevealVictoryPointAction(
        state: CoreGameStateV1,
        actingAs: String
    ) -> GameDevCardAction? {
        guard state.canRevealVictoryPoint(for: actingAs) else {
            return nil
        }

        return GameDevCardAction(
            kind: .revealVictoryPoint,
            title: "Reveal Victory Point",
            detail: "Reveal one hidden Victory Point now because this reveal reaches the win goal.",
            systemImage: "star.circle.fill"
        )
    }

    private static func productMessage(
        state: CoreGameStateV1,
        playActions: [GameDevCardAction],
        playableCounts: [GameDevCardCount],
        heldCounts: [GameDevCardCount],
        newCounts: [GameDevCardCount]
    ) -> String {
        if state.devCardActionPlayedThisTurn {
            if playActions.contains(where: { $0.kind == .revealVictoryPoint }) {
                return "You already used a non-Victory Point development-card action this turn. Winning Victory Point reveals may still be available."
            }
            return "You already used a non-Victory Point development-card action this turn."
        }

        if playActions.isEmpty {
            if playableCounts.isEmpty, heldCounts.isEmpty, newCounts.isEmpty {
                return "You do not have any development cards available right now."
            }
            return "No legal development-card play is available from the current state."
        }

        return "Choose one of your legal development cards to begin a board or bank selection flow."
    }

    private static func waitingMessage(
        currentPlayer: String,
        state: CoreGameStateV1,
        playableCounts: [GameDevCardCount],
        heldCounts: [GameDevCardCount],
        newCounts: [GameDevCardCount]
    ) -> String {
        if playableCounts.isEmpty, heldCounts.isEmpty, newCounts.isEmpty {
            return "Waiting for \(playerName(currentPlayer, in: state)) to use development cards."
        }

        return "You can review your development cards here, but only \(playerName(currentPlayer, in: state)) can act right now."
    }

    private static func makeTimingNotes(
        state: CoreGameStateV1,
        actingAs: String?,
        playableCounts: [GameDevCardCount],
        heldCounts: [GameDevCardCount],
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

        if victoryPointCount(in: newCounts) > 0 ||
            victoryPointCount(in: playableCounts) > 0 ||
            victoryPointCount(in: heldCounts) > 0
        {
            notes.append("Victory Point cards only reveal when the reveal would immediately win the game.")
        }

        if !heldCounts.isEmpty {
            notes.append("Held cards listed outside Playable stay hidden until their timing and legality requirements are met.")
        }

        return notes
    }

    private static func actionableCounts(
        from inventory: DevCardInventoryV1,
        state: CoreGameStateV1,
        actingAs: String?,
        playActions: [GameDevCardAction]
    ) -> [GameDevCardCount] {
        guard
            let actingAs,
            actingAs == state.currentPlayer,
            state.turnState?.step.allowsDevCardPlay == true,
            !state.devCardActionPlayedThisTurn
        else {
            return []
        }

        let actionKinds = Set(playActions.map(\.kind))
        let actionableInventory = DevCardInventoryV1(
            knight: actionKinds.contains(.playKnight) ? inventory.knight : 0,
            monopoly: actionKinds.contains(.playMonopoly) ? inventory.monopoly : 0,
            yearOfPlenty: actionKinds.contains(.playYearOfPlenty) ? inventory.yearOfPlenty : 0,
            roadBuilding: actionKinds.contains(.playRoadBuilding) ? inventory.roadBuilding : 0,
            victoryPoint: 0
        )

        return counts(from: actionableInventory)
    }

    private static func heldCounts(
        from inventory: DevCardInventoryV1,
        playableCounts: [GameDevCardCount]
    ) -> [GameDevCardCount] {
        let heldInventory = DevCardInventoryV1(
            knight: inventory.knight - count(for: "Knight", in: playableCounts),
            monopoly: inventory.monopoly - count(for: "Monopoly", in: playableCounts),
            yearOfPlenty: inventory.yearOfPlenty - count(for: "Year of Plenty", in: playableCounts),
            roadBuilding: inventory.roadBuilding - count(for: "Road Building", in: playableCounts),
            victoryPoint: inventory.victoryPoint
        )

        return counts(from: heldInventory)
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

    private static func count(for title: String, in counts: [GameDevCardCount]) -> Int {
        counts.first(where: { $0.title == title })?.count ?? 0
    }

    private static func canChooseYearOfPlenty(from options: [BankResourceOptionV1]) -> Bool {
        let totalCards = options.reduce(0) { $0 + $1.remainingCount }
        return totalCards >= 2
    }

    private static func monopolyResource(from draft: GameDevCardDraft?) -> ResourceV1? {
        guard case let .monopoly(resource) = draft else {
            return nil
        }
        return resource
    }

    private static func yearOfPlentySelection(from draft: GameDevCardDraft?) -> (first: ResourceV1?, second: ResourceV1?) {
        guard case let .yearOfPlenty(first, second) = draft else {
            return (nil, nil)
        }
        return (first, second)
    }

    private static func yearOfPlentyMessage(first: ResourceV1?, second: ResourceV1?) -> String {
        if first == nil {
            return "Choose the first resource from the bank strip."
        }
        if second == nil {
            return "Choose the second resource from the bank strip."
        }
        return "Confirm the selected resource pair."
    }

    private static func yearOfPlentySummary(first: ResourceV1?, second: ResourceV1?) -> String? {
        guard let first else {
            return nil
        }
        if let second {
            return "Selected \(resourceLabel(first)) and \(resourceLabel(second))."
        }
        return "First pick: \(resourceLabel(first))."
    }

    private static func draftSummary(for draft: GameDevCardDraft?, in state: CoreGameStateV1) -> String? {
        guard let draft else {
            return nil
        }

        switch draft {
        case let .knight(tileID, victimPlayer):
            if let victimPlayer {
                return "Steal from \(playerName(victimPlayer, in: state))."
            }
            if let tileID {
                return "Robber tile \(tileID) selected."
            }
            return nil
        case let .roadBuilding(firstEdgeID, secondEdgeID):
            if let secondEdgeID {
                return "Selected roads \(firstEdgeID ?? -1) and \(secondEdgeID)."
            }
            if let firstEdgeID {
                return "First road \(firstEdgeID) selected."
            }
            return nil
        case let .monopoly(resource):
            return resource.map { "Selected \(resourceLabel($0))." }
        case let .yearOfPlenty(first, second):
            return yearOfPlentySummary(first: first, second: second)
        }
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
