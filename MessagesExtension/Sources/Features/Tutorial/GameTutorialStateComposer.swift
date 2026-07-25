import ULS_CoreGame

/// Deterministic, local-only states used to render the shipping tutorial.
/// These states are never attached to a Messages conversation or a publishing callback.
enum GameTutorialStateComposer {
    static let localPlayer = "tutorial-you"
    private static let maya = "tutorial-maya"
    private static let theo = "tutorial-theo"
    private static let roster = [localPlayer, maya, theo]

    static func state(for step: GameTutorialStep.ID) -> CoreGameStateV1 {
        switch step {
        case .setupSettlement:
            return setupSettlementState
        case .setupRoad:
            return setupRoadState
        case .rollDice:
            return turnState(step: .needsRoll, lastRoll: nil)
        case .discard:
            return makeState(
                rev: 11,
                currentPlayer: maya,
                resources: [
                    localPlayer: ResourceHandV1(wood: 3, brick: 2, sheep: 2, wheat: 2, ore: 1),
                    maya: ResourceHandV1(wood: 2, brick: 1, sheep: 1, wheat: 1, ore: 1),
                    theo: ResourceHandV1(wood: 1, brick: 1, sheep: 1),
                ],
                turnState: TurnStateV1(
                    step: .pendingDiscards,
                    lastRoll: DiceRollV1(d1: 4, d2: 3),
                    discardRequirementsByPlayer: [localPlayer: 5]
                )
            )
        case .moveRobber:
            return robberMoveState
        case .chooseVictim:
            return robberVictimState
        case .readProduction,
             .useHand,
             .buildCosts,
             .legalPlacement,
             .playerTrade,
             .tradeRecipients,
             .bankTrade,
             .developmentCards,
             .endTurn,
             .strategy:
            return turnState(step: .afterRoll, lastRoll: DiceRollV1(d1: 3, d2: 5))
        }
    }

    private static let boardRules = BoardRulesV1(strategy: .noRedAdjacentV1)
    private static let board = StandardBoardGeneratorV1.generate(
        boardSeed: 70_707,
        rules: boardRules
    )

    private static let setupSettlementState: CoreGameStateV1 = makeState(
        rev: 3,
        phase: .setup,
        resources: Dictionary(uniqueKeysWithValues: roster.map { ($0, .zero) }),
        devCards: [:],
        newDevCards: [:],
        settlements: [:],
        cities: [:],
        roads: [:],
        setupState: initializeSetupState(roster: roster),
        turnState: nil
    )

    private static let setupRoadState: CoreGameStateV1 = {
        guard let node = setupSettlementState.legalSetupSettlementNodes(for: localPlayer).first,
              let state = try? apply(
                intent: .placeSetupSettlement(node: node),
                to: setupSettlementState,
                actor: localPlayer
              )
        else {
            preconditionFailure("Tutorial requires a legal setup settlement.")
        }
        return state
    }()

    private static let robberMoveState = makeState(
        rev: 12,
        turnState: TurnStateV1(
            step: .needsRobberMove,
            lastRoll: DiceRollV1(d1: 4, d2: 3)
        )
    )

    private static let robberVictimState: CoreGameStateV1 = {
        for tileID in robberMoveState.legalRobberMoveTiles(for: localPlayer) {
            guard let moved = try? apply(
                intent: .moveRobber(tileID: tileID),
                to: robberMoveState,
                actor: localPlayer
            ) else { continue }
            if moved.turnState?.step == .needsRobberSteal {
                return moved
            }
        }
        preconditionFailure("Tutorial requires a robber destination beside an opponent.")
    }()

    private static func turnState(
        step: TurnStepV1,
        lastRoll: DiceRollV1?
    ) -> CoreGameStateV1 {
        makeState(
            rev: step == .needsRoll ? 8 : 9,
            turnState: TurnStateV1(step: step, lastRoll: lastRoll)
        )
    }

    private static func makeState(
        rev: Int,
        currentPlayer: String = localPlayer,
        phase: PhaseV1 = .turn,
        resources: [String: ResourceHandV1] = defaultResources,
        devCards: [String: DevCardInventoryV1] = defaultDevCards,
        newDevCards: [String: DevCardInventoryV1] = defaultNewDevCards,
        revealedVictoryPoints: [String: Int] = [:],
        settlements: [NodeID: String] = defaultSettlements,
        cities: [NodeID: String] = defaultCities,
        roads: [EdgeID: String] = defaultRoads,
        setupState: SetupStateV1? = nil,
        turnState: TurnStateV1?
    ) -> CoreGameStateV1 {
        CoreGameStateV1(
            gameId: "tutorial-read-only-game",
            rev: rev,
            prevHash: rev > 0 ? "tutorial-prev-\(rev - 1)" : nil,
            stateHash: "",
            roster: roster,
            currentPlayer: currentPlayer,
            playerDisplayNamesByPlayer: [
                localPlayer: "Kunal",
                maya: "Maya",
                theo: "Theo",
            ],
            phase: phase,
            seed: 9_001,
            diceRngState: 9_002,
            robberRngState: 9_003,
            resourcesByPlayer: resources,
            bankResources: .standardBank,
            devDeck: Array(repeating: .knight, count: 8) + [.roadBuilding, .yearOfPlenty, .monopoly, .victoryPoint],
            devCardsByPlayer: devCards,
            newDevCardsByPlayer: newDevCards,
            revealedVictoryPointsByPlayer: revealedVictoryPoints,
            knightsPlayedByPlayer: [localPlayer: 3, maya: 1],
            largestArmyOwner: localPlayer,
            largestArmySize: 3,
            longestRoadOwner: maya,
            longestRoadLength: 5,
            winnerPlayer: nil,
            winningVictoryPoints: 0,
            lastTurnRecap: nil,
            activeTradeOffer: nil,
            tradeResponses: [],
            settlementsByNode: settlements,
            citiesByNode: cities,
            roadsByEdge: roads,
            boardRules: boardRules,
            board: board,
            setupState: setupState,
            turnState: turnState
        ).rehashed()
    }

    private static let defaultResources = [
        localPlayer: ResourceHandV1(wood: 5, brick: 5, sheep: 5, wheat: 5, ore: 5),
        maya: ResourceHandV1(wood: 1, brick: 2, sheep: 3, wheat: 1, ore: 1),
        theo: ResourceHandV1(wood: 2, brick: 1, sheep: 1, wheat: 3),
    ]

    private static let defaultDevCards = [
        localPlayer: DevCardInventoryV1(
            knight: 1,
            monopoly: 1,
            yearOfPlenty: 1,
            roadBuilding: 1,
            victoryPoint: 1
        ),
        maya: DevCardInventoryV1(knight: 1),
    ]

    private static let defaultNewDevCards = [
        localPlayer: DevCardInventoryV1(victoryPoint: 1),
    ]

    private static let defaultSettlements = [4: localPlayer, 18: maya, 31: theo]
    private static let defaultCities = [8: localPlayer, 25: maya]
    private static let defaultRoads = [2: localPlayer, 3: localPlayer, 4: localPlayer, 17: maya, 18: maya, 29: theo]
}
