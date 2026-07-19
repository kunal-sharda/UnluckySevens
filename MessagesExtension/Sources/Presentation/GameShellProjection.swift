import ULS_CoreGame

struct GameShellProjection: Equatable {
    var kind: String
    var gameId: String
    var rev: String
    var prevHash: String
    var stateHash: String
    var roster: String
    var currentPlayer: String
    var phase: String
    var seed: String
    var diceRngState: String
    var turnStep: String
    var lastRoll: String
    var pendingDiscardRequirements: String
    var submittedDiscardsStatus: String
    var robberMoveReadiness: String
    var eligibleStealVictims: String
    var remainingPieces: String
    var activeTradeOffer: String
    var tradeResponses: String
    var maritimeTradePreview: String
    var largestArmyStatus: String
    var longestRoadStatus: String
    var victoryPointsSummary: String
    var gameOverSummary: String
    var lastTurnRecapSummary: String
    var boardHash: String
    var boardGenerator: String
    var boardRobberTile: String
    var boardResourcesByTile: String
    var boardNumbersByTile: String
    var boardPortsByIndex: String
    var visibleHands: String
    var bankResources: String
    var devDeckRemaining: String
    var visibleDevCards: String
    var setupPlacement: String
    var turnIntent: String
    var gameScreenModel: GameScreenModel
    var setupPlacementModel: GameSetupPlacementModel?
    var setupGuidanceText: String?
    var discardPanelModel: GameDiscardPanelModel?
    var robberVictimOptions: [GameRobberVictimOption]
    var tradePanelModel: GameTradePanelModel?

    static let empty = GameShellProjection(
        kind: "-",
        gameId: "-",
        rev: "-",
        prevHash: "-",
        stateHash: "-",
        roster: "-",
        currentPlayer: "-",
        phase: "-",
        seed: "-",
        diceRngState: "-",
        turnStep: "-",
        lastRoll: "-",
        pendingDiscardRequirements: "-",
        submittedDiscardsStatus: "-",
        robberMoveReadiness: "-",
        eligibleStealVictims: "-",
        remainingPieces: "-",
        activeTradeOffer: "-",
        tradeResponses: "-",
        maritimeTradePreview: "-",
        largestArmyStatus: "-",
        longestRoadStatus: "-",
        victoryPointsSummary: "-",
        gameOverSummary: "-",
        lastTurnRecapSummary: "-",
        boardHash: "-",
        boardGenerator: "-",
        boardRobberTile: "-",
        boardResourcesByTile: "-",
        boardNumbersByTile: "-",
        boardPortsByIndex: "-",
        visibleHands: "-",
        bankResources: "-",
        devDeckRemaining: "-",
        visibleDevCards: "-",
        setupPlacement: "-",
        turnIntent: "-",
        gameScreenModel: GameScreenModelBuilder.build(
            context: GameScreenContext(
                selectedState: nil,
                actingAs: nil,
                contextBanner: "",
                contextMeta: "",
                actionAvailability: .none,
                modeAvailability: .none
            )
        ),
        setupPlacementModel: nil,
        setupGuidanceText: nil,
        discardPanelModel: nil,
        robberVictimOptions: [],
        tradePanelModel: nil
    )
}

enum GameShellProjectionBuilder {
    static func build(
        state: CoreGameStateV1?,
        actingAs: String?,
        actionAvailability: GameActionAvailability = .none,
        modeAvailability: GameModeAvailability = .none,
        contextBanner: String = "Active Context: none",
        contextMeta: String = ""
    ) -> GameShellProjection {
        let screenModel = GameScreenModelBuilder.build(
            context: GameScreenContext(
                selectedState: state,
                actingAs: actingAs,
                contextBanner: contextBanner,
                contextMeta: contextMeta,
                actionAvailability: actionAvailability,
                modeAvailability: modeAvailability
            )
        )

        guard let state else {
            return GameShellProjection(
                kind: "-",
                gameId: "-",
                rev: "-",
                prevHash: "-",
                stateHash: "-",
                roster: "-",
                currentPlayer: "-",
                phase: "-",
                seed: "-",
                diceRngState: "-",
                turnStep: "-",
                lastRoll: "-",
                pendingDiscardRequirements: "-",
                submittedDiscardsStatus: "-",
                robberMoveReadiness: "-",
                eligibleStealVictims: "-",
                remainingPieces: "-",
                activeTradeOffer: "-",
                tradeResponses: "-",
                maritimeTradePreview: "-",
                largestArmyStatus: "-",
                longestRoadStatus: "-",
                victoryPointsSummary: "-",
                gameOverSummary: "-",
                lastTurnRecapSummary: "-",
                boardHash: "-",
                boardGenerator: "-",
                boardRobberTile: "-",
                boardResourcesByTile: "-",
                boardNumbersByTile: "-",
                boardPortsByIndex: "-",
                visibleHands: "-",
                bankResources: "-",
                devDeckRemaining: "-",
                visibleDevCards: "-",
                setupPlacement: "-",
                turnIntent: "-",
                gameScreenModel: screenModel,
                setupPlacementModel: nil,
                setupGuidanceText: nil,
                discardPanelModel: nil,
                robberVictimOptions: [],
                tradePanelModel: nil
            )
        }

        return GameShellProjection(
            kind: "STATE",
            gameId: state.gameId,
            rev: String(state.rev),
            prevHash: state.prevHash ?? "nil",
            stateHash: state.stateHash,
            roster: state.roster.joined(separator: ", "),
            currentPlayer: state.currentPlayer,
            phase: state.phase.rawValue,
            seed: state.seed.map(String.init) ?? "nil",
            diceRngState: state.diceRngState.map(String.init) ?? "nil",
            turnStep: state.turnState?.step.rawValue ?? "nil",
            lastRoll: state.turnState?.lastRoll.map { "\($0.d1)+\($0.d2)" } ?? "nil",
            pendingDiscardRequirements: discardRequirementsSummary(for: state.turnState),
            submittedDiscardsStatus: discardSubmissionSummary(for: state.turnState),
            robberMoveReadiness: robberReadinessSummary(for: state.turnState),
            eligibleStealVictims: stealVictimsSummary(for: state.turnState),
            remainingPieces: remainingPiecesSummary(for: state),
            activeTradeOffer: activeTradeOfferSummary(for: state),
            tradeResponses: tradeResponsesSummary(for: state),
            maritimeTradePreview: maritimeTradeSummary(for: state, actingAs: actingAs),
            largestArmyStatus: largestArmySummary(for: state),
            longestRoadStatus: longestRoadSummary(for: state),
            victoryPointsSummary: vpSummary(for: state),
            gameOverSummary: gameOverStateSummary(for: state),
            lastTurnRecapSummary: recapSummary(for: state),
            boardHash: state.board?.boardHash ?? "-",
            boardGenerator: state.board?.generator.rawValue ?? "-",
            boardRobberTile: state.board.map { String($0.robberTile) } ?? "-",
            boardResourcesByTile: state.board?.resourcesByTile.enumerated()
                .map { "\($0.offset): \($0.element.rawValue)" }
                .joined(separator: ", ") ?? "-",
            boardNumbersByTile: state.board?.numbersByTile.enumerated()
                .map { "\($0.offset): \($0.element.map(String.init) ?? "nil")" }
                .joined(separator: ", ") ?? "-",
            boardPortsByIndex: state.board?.portsByIndex.enumerated()
                .map { "\($0.offset): \(portKindDescription($0.element))" }
                .joined(separator: ", ") ?? "-",
            visibleHands: visibleHandsSummary(for: state, actingAs: actingAs),
            bankResources: resourceHandDescription(state.bankResources),
            devDeckRemaining: String(state.devDeck.count),
            visibleDevCards: visibleDevCardsSummary(for: state, actingAs: actingAs),
            setupPlacement: "-",
            turnIntent: "-",
            gameScreenModel: screenModel,
            setupPlacementModel: GameSetupPlacementModelBuilder.build(
                state: state,
                actingAs: actingAs,
                players: screenModel.gameInfo.players
            ),
            setupGuidanceText: SetupInteractionResolver.guidanceText(
                state: state,
                actingAs: actingAs
            ),
            discardPanelModel: GameDiscardPanelModelBuilder.build(
                state: state,
                actingAs: actingAs
            ),
            robberVictimOptions: GameRobberVictimOptionBuilder.build(
                state: state,
                actingAs: actingAs
            ),
            tradePanelModel: GameTradePanelModelBuilder.build(
                state: state,
                actingAs: actingAs
            )
        )
    }

    private static func maritimeTradeSummary(
        for state: CoreGameStateV1,
        actingAs: String?
    ) -> String {
        guard
            state.phase == .turn,
            state.turnState?.step == .afterRoll,
            let actor = actingAs,
            actor == state.currentPlayer,
            let maritime = state.defaultMaritimeTrade(for: actor)
        else {
            return "none"
        }
        return "give: \(resourceHandDescription(maritime.give)) receive: \(resourceHandDescription(maritime.receive)) ratio: \(maritime.ratio):1"
    }

    private static func visibleHandsSummary(
        for state: CoreGameStateV1,
        actingAs: String?
    ) -> String {
        state.visibleResourceHands(for: actingAs)
            .map { playerView in
                if let revealedHand = playerView.revealedHand {
                    return "\(playerView.player): \(resourceHandDescription(revealedHand))"
                }
                return "\(playerView.player): \(playerView.totalCount)"
            }
            .joined(separator: " | ")
    }

    private static func visibleDevCardsSummary(
        for state: CoreGameStateV1,
        actingAs: String?
    ) -> String {
        state.visibleDevCards(for: actingAs)
            .map { playerView in
                if let playable = playerView.revealedPlayable,
                   let newCards = playerView.revealedNew
                {
                    return "\(playerView.player): \(devCardInventoryDescription(playable))/new:\(devCardInventoryDescription(newCards))"
                }
                return "\(playerView.player): \(playerView.totalCount)"
            }
            .joined(separator: " | ")
    }

    private static func resourceHandDescription(_ hand: ResourceHandV1) -> String {
        "w:\(hand.wood), b:\(hand.brick), s:\(hand.sheep), wh:\(hand.wheat), o:\(hand.ore)"
    }

    private static func devCardInventoryDescription(_ inventory: DevCardInventoryV1) -> String {
        "k:\(inventory.knight), m:\(inventory.monopoly), yop:\(inventory.yearOfPlenty), rb:\(inventory.roadBuilding), vp:\(inventory.victoryPoint)"
    }

    private static func discardRequirementsSummary(for turnState: TurnStateV1?) -> String {
        guard let turnState else {
            return "-"
        }
        if turnState.discardRequirementsByPlayer.isEmpty {
            return "none"
        }
        return turnState.discardRequirementsByPlayer.keys.sorted().map { player in
            "\(player):\(turnState.discardRequirementsByPlayer[player] ?? 0)"
        }.joined(separator: ", ")
    }

    private static func discardSubmissionSummary(for turnState: TurnStateV1?) -> String {
        guard let turnState else {
            return "-"
        }
        let requiredCount = turnState.discardRequirementsByPlayer.count
        let submittedCount = turnState.submittedDiscardsByPlayer.count
        if requiredCount == 0 {
            return "0/0"
        }
        let submittedPlayers = turnState.submittedDiscardsByPlayer.keys.sorted().joined(separator: ",")
        return "\(submittedCount)/\(requiredCount) [\(submittedPlayers)]"
    }

    private static func robberReadinessSummary(for turnState: TurnStateV1?) -> String {
        guard let turnState else {
            return "-"
        }
        switch turnState.step {
        case .needsRobberMove:
            return "ready"
        case .pendingDiscards:
            return "waiting"
        default:
            return "n/a"
        }
    }

    private static func stealVictimsSummary(for turnState: TurnStateV1?) -> String {
        guard let turnState else {
            return "-"
        }
        if turnState.eligibleStealVictims.isEmpty {
            return "none"
        }
        return turnState.eligibleStealVictims.sorted().joined(separator: ", ")
    }

    private static func remainingPiecesSummary(for state: CoreGameStateV1) -> String {
        state.roster.map { player in
            let roadsUsed = state.roadsByEdge.values.filter { $0 == player }.count
            let settlementsUsed = state.settlementsByNode.values.filter { $0 == player }.count
            let citiesUsed = state.citiesByNode.values.filter { $0 == player }.count
            return "\(player):R\(max(0, 15 - roadsUsed))/S\(max(0, 5 - settlementsUsed))/C\(max(0, 4 - citiesUsed))"
        }.joined(separator: " | ")
    }

    private static func activeTradeOfferSummary(for state: CoreGameStateV1) -> String {
        guard let offer = state.activeTradeOffer else {
            return "none"
        }
        let shortHash = String(offer.offerHash.prefix(8))
        let recipients = offer.recipients.joined(separator: ",")
        return "\(offer.proposer) \(resourceHandDescription(offer.give)) -> \(resourceHandDescription(offer.receive)) to [\(recipients)] [\(shortHash)]"
    }

    private static func tradeResponsesSummary(for state: CoreGameStateV1) -> String {
        if state.tradeResponses.isEmpty {
            return "none"
        }
        return state.tradeResponses
            .sorted { lhs, rhs in
                if lhs.respondingPlayer == rhs.respondingPlayer {
                    return lhs.kind.rawValue < rhs.kind.rawValue
                }
                return lhs.respondingPlayer < rhs.respondingPlayer
            }
            .map { response in
                let base = "\(response.respondingPlayer):\(response.kind.rawValue)"
                guard response.kind == .counter else {
                    return base
                }
                return "\(base)(\(resourceHandDescription(response.counterGive ?? .zero))->\(resourceHandDescription(response.counterReceive ?? .zero)))"
            }
            .joined(separator: ", ")
    }

    private static func largestArmySummary(for state: CoreGameStateV1) -> String {
        let owner = state.largestArmyOwner ?? "none"
        return "\(owner) (\(state.largestArmySize))"
    }

    private static func longestRoadSummary(for state: CoreGameStateV1) -> String {
        let owner = state.longestRoadOwner ?? "none"
        return "\(owner) (\(state.longestRoadLength))"
    }

    private static func vpSummary(for state: CoreGameStateV1) -> String {
        state.roster
            .map { "\($0):\(victoryPoints(for: $0, in: state))" }
            .joined(separator: " | ")
    }

    private static func gameOverStateSummary(for state: CoreGameStateV1) -> String {
        guard state.phase == .gameOver else {
            return "no"
        }
        let winner = state.winnerPlayer ?? "none"
        return "winner: \(winner) vp: \(state.winningVictoryPoints)"
    }

    private static func recapSummary(for state: CoreGameStateV1) -> String {
        guard let recap = state.lastTurnRecap else {
            return "none"
        }
        let actions = recap.actions.map(\.rawValue).joined(separator: "->")
        let roll = recap.rollTotal.map(String.init) ?? "n/a"
        return "actor: \(recap.actor) rev: \(recap.startRev)-\(recap.endRev) roll: \(roll) actions: \(actions)"
    }

    private static func portKindDescription(_ kind: PortKindV1) -> String {
        switch kind {
        case .threeToOne:
            return "3:1"
        case let .twoToOne(resource):
            return "2:1 \(resource.rawValue)"
        }
    }

}
