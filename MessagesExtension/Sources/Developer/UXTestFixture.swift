#if DEBUG
import ULS_CoreGame

struct UXTestFixture: Equatable, Identifiable {
    let id: String
    let title: String
    let detail: String
    let defaultActorID: String
    let state: CoreGameStateV1
    let extraActorIDs: [String]

    init(
        id: String,
        title: String,
        detail: String,
        defaultActorID: String,
        state: CoreGameStateV1,
        extraActorIDs: [String] = []
    ) {
        self.id = id
        self.title = title
        self.detail = detail
        self.defaultActorID = defaultActorID
        self.state = state
        self.extraActorIDs = extraActorIDs
    }

    var actorIDs: [String] {
        var ids = state.roster
        for actorID in extraActorIDs where !ids.contains(actorID) {
            ids.append(actorID)
        }
        return ids
    }
}

enum UXTestFixtures {
    static let host = "host"
    static let alice = "alice"
    static let ben = "ben"

    static let all: [UXTestFixture] = [
        lobbyInvite,
        lobbyReady,
        setupPlacement,
        turnNeedsRoll,
        turnAfterRoll,
        waitingOnAlice,
        pendingDiscard,
        robberMove,
        tradeOffer,
        gameOver,
    ]

    static let defaultFixtureID = turnAfterRoll.id
    static let defaultActorID = host
    static let setupPlacementID = "setup-placement"
    static let tradeOfferID = "trade-offer"

    static func fixture(id: String) -> UXTestFixture {
        all.first { $0.id == id } ?? turnAfterRoll
    }

    static func displayName(for actorID: String) -> String? {
        displayNames[actorID]
    }

    private static let roster = [host, alice, ben]
    private static let displayNames = [
        host: "Kunal",
        alice: "Maya",
        ben: "Theo",
    ]
    private static let boardRules = BoardRulesV1(strategy: .noRedAdjacentV1)
    private static let board = StandardBoardGeneratorV1.generate(
        boardSeed: 70_707,
        rules: boardRules
    )
    private static let fullBank = ResourceHandV1.standardBank
    private static let devDeck = Array(
        repeating: DevCardV1.knight,
        count: 8
    ) + [.roadBuilding, .yearOfPlenty, .monopoly, .victoryPoint]

    private static let lobbyInvite = UXTestFixture(
        id: "lobby-invite",
        title: "Lobby invite",
        detail: "Start here to drive the full table: switch to Maya or Theo, join, then return to Kunal to start.",
        defaultActorID: host,
        state: makeState(
            rev: 0,
            roster: [host],
            currentPlayer: host,
            phase: .lobby,
            seed: nil,
            diceRngState: nil,
            robberRngState: nil,
            resourcesByPlayer: [host: .zero],
            boardRules: nil,
            board: nil
        ),
        extraActorIDs: [alice, ben]
    )

    private static let lobbyReady = UXTestFixture(
        id: "lobby-ready",
        title: "Lobby ready",
        detail: "Three-player lobby with host able to start.",
        defaultActorID: host,
        state: makeState(
            rev: 2,
            phase: .lobby,
            seed: nil,
            diceRngState: nil,
            robberRngState: nil,
            boardRules: nil,
            board: nil
        )
    )

    private static let setupPlacement = UXTestFixture(
        id: setupPlacementID,
        title: "Setup placement",
        detail: "First setup settlement prompt.",
        defaultActorID: host,
        state: makeState(
            rev: 3,
            currentPlayer: host,
            phase: .setup,
            setupState: initializeSetupState(roster: roster)
        )
    )

    private static let turnNeedsRoll = UXTestFixture(
        id: "turn-needs-roll",
        title: "Turn needs roll",
        detail: "Current player before rolling.",
        defaultActorID: host,
        state: makeTurnFixture(
            rev: 8,
            currentPlayer: host,
            turnState: TurnStateV1(step: .needsRoll, lastRoll: nil)
        )
    )

    private static let turnAfterRoll = UXTestFixture(
        id: "turn-after-roll",
        title: "Turn after roll",
        detail: "Main gameplay surface with hand, actions, opponents, and board.",
        defaultActorID: host,
        state: makeTurnFixture(
            rev: 9,
            currentPlayer: host,
            lastTurnRecap: TurnRecapV1(
                actor: alice,
                startRev: 5,
                endRev: 8,
                rollTotal: 6,
                actions: [.buildRoad, .endTurn]
            ),
            turnState: TurnStateV1(
                step: .afterRoll,
                lastRoll: DiceRollV1(d1: 3, d2: 5)
            )
        )
    )

    private static let waitingOnAlice = UXTestFixture(
        id: "waiting-on-alice",
        title: "Waiting on another player",
        detail: "Read-only local view while another player owns the turn.",
        defaultActorID: host,
        state: makeTurnFixture(
            rev: 10,
            currentPlayer: alice,
            turnState: TurnStateV1(step: .needsRoll, lastRoll: nil)
        )
    )

    private static let pendingDiscard = UXTestFixture(
        id: "pending-discard",
        title: "Pending discard",
        detail: "Seven was rolled; local player must discard.",
        defaultActorID: host,
        state: makeTurnFixture(
            rev: 11,
            currentPlayer: alice,
            resourcesByPlayer: [
                host: ResourceHandV1(wood: 3, brick: 2, sheep: 2, wheat: 2, ore: 1),
                alice: ResourceHandV1(wood: 2, brick: 1, sheep: 1, wheat: 1, ore: 1),
                ben: ResourceHandV1(wood: 1, brick: 1, sheep: 1),
            ],
            turnState: TurnStateV1(
                step: .pendingDiscards,
                lastRoll: DiceRollV1(d1: 4, d2: 3),
                discardRequirementsByPlayer: [host: 5]
            )
        )
    )

    private static let robberMove = UXTestFixture(
        id: "robber-move",
        title: "Robber move",
        detail: "Current player must move the robber after a seven.",
        defaultActorID: host,
        state: makeTurnFixture(
            rev: 12,
            currentPlayer: host,
            turnState: TurnStateV1(
                step: .needsRobberMove,
                lastRoll: DiceRollV1(d1: 4, d2: 3)
            )
        )
    )

    private static let tradeOffer = UXTestFixture(
        id: "trade-offer",
        title: "Trade offer received",
        detail: "Local player can review another player's offer.",
        defaultActorID: host,
        state: {
            let offer = TradeOfferV1(
                offerHash: "ux-trade-offer-1",
                proposer: alice,
                give: ResourceHandV1(sheep: 2),
                receive: ResourceHandV1(ore: 1),
                recipients: [host, ben],
                createdRev: 13
            )
            return makeTurnFixture(
                rev: 13,
                currentPlayer: alice,
                activeTradeOffer: offer,
                tradeResponses: [
                    TradeResponseV1(
                        respondingPlayer: ben,
                        offerHash: offer.offerHash,
                        kind: .counter,
                        respondedAtRev: 14,
                        counterGive: ResourceHandV1(wheat: 1),
                        counterReceive: ResourceHandV1(brick: 1)
                    )
                ],
                turnState: TurnStateV1(
                    step: .afterRoll,
                    lastRoll: DiceRollV1(d1: 2, d2: 4)
                )
            )
        }()
    )

    private static let gameOver = UXTestFixture(
        id: "game-over",
        title: "Game over",
        detail: "Winner, final score, and recap surface.",
        defaultActorID: host,
        state: makeTurnFixture(
            rev: 18,
            currentPlayer: host,
            phase: .gameOver,
            revealedVictoryPointsByPlayer: [host: 3],
            winnerPlayer: host,
            winningVictoryPoints: 10,
            lastTurnRecap: TurnRecapV1(
                actor: host,
                startRev: 15,
                endRev: 18,
                rollTotal: 8,
                actions: [.rollDice, .buildCity, .endTurn]
            ),
            turnState: TurnStateV1(
                step: .afterRoll,
                lastRoll: DiceRollV1(d1: 5, d2: 3)
            )
        )
    )

    private static func makeTurnFixture(
        rev: Int,
        currentPlayer: String,
        phase: PhaseV1 = .turn,
        resourcesByPlayer: [String: ResourceHandV1] = defaultResources,
        revealedVictoryPointsByPlayer: [String: Int] = [:],
        activeTradeOffer: TradeOfferV1? = nil,
        tradeResponses: [TradeResponseV1] = [],
        winnerPlayer: String? = nil,
        winningVictoryPoints: Int = 0,
        lastTurnRecap: TurnRecapV1? = nil,
        turnState: TurnStateV1
    ) -> CoreGameStateV1 {
        makeState(
            rev: rev,
            currentPlayer: currentPlayer,
            phase: phase,
            resourcesByPlayer: resourcesByPlayer,
            revealedVictoryPointsByPlayer: revealedVictoryPointsByPlayer,
            activeTradeOffer: activeTradeOffer,
            tradeResponses: tradeResponses,
            winnerPlayer: winnerPlayer,
            winningVictoryPoints: winningVictoryPoints,
            lastTurnRecap: lastTurnRecap,
            turnState: turnState
        )
    }

    private static func makeState(
        rev: Int,
        roster: [String] = roster,
        currentPlayer: String = host,
        phase: PhaseV1,
        seed: UInt64? = 9_001,
        diceRngState: UInt64? = 9_002,
        robberRngState: UInt64? = 9_003,
        resourcesByPlayer: [String: ResourceHandV1] = defaultResources,
        revealedVictoryPointsByPlayer: [String: Int] = [:],
        activeTradeOffer: TradeOfferV1? = nil,
        tradeResponses: [TradeResponseV1] = [],
        settlementsByNode: [NodeID: String] = defaultSettlements,
        citiesByNode: [NodeID: String] = defaultCities,
        roadsByEdge: [EdgeID: String] = defaultRoads,
        boardRules: BoardRulesV1? = boardRules,
        board: BoardSetupV1? = board,
        setupState: SetupStateV1? = nil,
        winnerPlayer: String? = nil,
        winningVictoryPoints: Int = 0,
        lastTurnRecap: TurnRecapV1? = nil,
        turnState: TurnStateV1? = nil
    ) -> CoreGameStateV1 {
        CoreGameStateV1(
            gameId: "ux-single-device-game",
            rev: rev,
            prevHash: rev > 0 ? "ux-prev-\(rev - 1)" : nil,
            stateHash: "",
            roster: roster,
            currentPlayer: currentPlayer,
            playerDisplayNamesByPlayer: displayNames,
            phase: phase,
            seed: seed,
            diceRngState: diceRngState,
            robberRngState: robberRngState,
            resourcesByPlayer: resourcesByPlayer,
            bankResources: fullBank,
            devDeck: devDeck,
            devCardsByPlayer: [
                host: DevCardInventoryV1(
                    knight: 1,
                    monopoly: 1,
                    yearOfPlenty: 1,
                    roadBuilding: 1,
                    victoryPoint: 1
                ),
                alice: DevCardInventoryV1(knight: 1),
            ],
            newDevCardsByPlayer: [
                host: DevCardInventoryV1(victoryPoint: 1),
            ],
            revealedVictoryPointsByPlayer: revealedVictoryPointsByPlayer,
            knightsPlayedByPlayer: [host: 2, alice: 1],
            largestArmyOwner: host,
            largestArmySize: 2,
            longestRoadOwner: alice,
            longestRoadLength: 5,
            winnerPlayer: winnerPlayer,
            winningVictoryPoints: winningVictoryPoints,
            lastTurnRecap: lastTurnRecap,
            activeTradeOffer: activeTradeOffer,
            tradeResponses: tradeResponses,
            settlementsByNode: settlementsByNode,
            citiesByNode: citiesByNode,
            roadsByEdge: roadsByEdge,
            boardRules: boardRules,
            board: board,
            setupState: setupState,
            turnState: turnState
        ).rehashed()
    }

    private static let defaultResources = [
        host: ResourceHandV1(wood: 5, brick: 5, sheep: 5, wheat: 5, ore: 5),
        alice: ResourceHandV1(wood: 1, brick: 2, sheep: 3, wheat: 1, ore: 1),
        ben: ResourceHandV1(wood: 2, brick: 1, sheep: 1, wheat: 3),
    ]

    private static let defaultSettlements = [
        4: host,
        18: alice,
        31: ben,
    ]

    private static let defaultCities = [
        8: host,
        25: alice,
    ]

    private static let defaultRoads: [EdgeID: String] = {
        let topology = StandardBoardTopologyV1.standard()
        let startNode = 4
        let occupiedNodes: Set<NodeID> = [4, 8, 18, 25, 31]
        var queue: [NodeID] = [startNode]
        var visited: Set<NodeID> = [startNode]
        var previous: [NodeID: (node: NodeID, edge: EdgeID)] = [:]
        var targetNode: NodeID?

        while !queue.isEmpty, targetNode == nil {
            let node = queue.removeFirst()
            for edgeID in topology.edges(incidentTo: node).sorted() {
                let edge = topology.edges[edgeID]
                let nextNode = edge.a == node ? edge.b : edge.a
                guard !visited.contains(nextNode) else { continue }
                guard nextNode == startNode || !occupiedNodes.contains(nextNode) else { continue }

                visited.insert(nextNode)
                previous[nextNode] = (node, edgeID)
                queue.append(nextNode)

                let adjacent = Set(topology.nodes(adjacentTo: nextNode))
                if !occupiedNodes.contains(nextNode),
                   adjacent.isDisjoint(with: occupiedNodes) {
                    targetNode = nextNode
                    break
                }
            }
        }

        var result: [EdgeID: String] = [:]
        var cursor = targetNode
        while let node = cursor, node != startNode, let step = previous[node] {
            result[step.edge] = host
            cursor = step.node
        }

        for (edge, owner) in [(17, alice), (18, alice), (29, ben)] where result[edge] == nil {
            result[edge] = owner
        }
        return result
    }()
}
#endif
