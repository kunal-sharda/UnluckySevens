import XCTest
@testable import ULS_CoreGame

final class ScriptedFullMatchesV1Tests: XCTestCase {
    private let topology = StandardBoardTopologyV1.standard()

    func testMatch1SetupPathToWinIsDeterministic() throws {
        let first = try runMatch1SetupToWin()
        let second = try runMatch1SetupToWin()

        assertTerminalState(first, expectedWinner: "A", roster: ["A", "B", "C"])
        assertTerminalState(second, expectedWinner: "A", roster: ["A", "B", "C"])
        assertDeterministicReplay(first, second)
    }

    func testMatch2RoadCityRaceIsDeterministic() throws {
        let first = try runMatch2RoadCityRace()
        let second = try runMatch2RoadCityRace()

        assertTerminalState(first, expectedWinner: "A", roster: ["A", "B", "C", "D"])
        assertTerminalState(second, expectedWinner: "A", roster: ["A", "B", "C", "D"])
        assertDeterministicReplay(first, second)
    }

    func testMatch3DevArmyPathIsDeterministic() throws {
        let first = try runMatch3DevArmyPath()
        let second = try runMatch3DevArmyPath()

        assertTerminalState(first, expectedWinner: "A", roster: ["A", "B", "C"])
        assertTerminalState(second, expectedWinner: "A", roster: ["A", "B", "C"])
        assertDeterministicReplay(first, second)
    }

    func testMatch4TradeMaritimePathIsDeterministic() throws {
        let first = try runMatch4TradeMaritimePath()
        let second = try runMatch4TradeMaritimePath()

        assertTerminalState(first, expectedWinner: "A", roster: ["A", "B", "C", "D"])
        assertTerminalState(second, expectedWinner: "A", roster: ["A", "B", "C", "D"])
        assertDeterministicReplay(first, second)
    }

    func testScriptReplayInvariantAcrossAllFourMatches() throws {
        let run1 = try [
            runMatch1SetupToWin(),
            runMatch2RoadCityRace(),
            runMatch3DevArmyPath(),
            runMatch4TradeMaritimePath(),
        ]

        let run2 = try [
            runMatch1SetupToWin(),
            runMatch2RoadCityRace(),
            runMatch3DevArmyPath(),
            runMatch4TradeMaritimePath(),
        ]

        XCTAssertEqual(run1.map(\.stateHash), run2.map(\.stateHash))
    }

    private func runMatch1SetupToWin() throws -> CoreGameStateV1 {
        let roster = ["A", "B", "C"]
        var state = try makeTurnStateFromSetup(
            gameId: "scripted-match-1",
            roster: roster,
            seed: 1001
        )

        state = preparedTurnSnapshot(
            from: state,
            currentPlayer: "A",
            resourcesByPlayer: [
                "A": ResourceHandV1(wood: 4, brick: 4, sheep: 4, wheat: 4, ore: 4),
                "B": ResourceHandV1(wood: 2, brick: 2, sheep: 2, wheat: 2, ore: 2),
                "C": ResourceHandV1(wood: 2, brick: 2, sheep: 2, wheat: 2, ore: 2),
            ],
            devCardsByPlayer: [
                "A": DevCardInventoryV1(victoryPoint: 1),
                "B": .zero,
                "C": .zero,
            ],
            revealedVPByPlayer: [
                "A": 7,
                "B": 0,
                "C": 0,
            ]
        )

        try performTurn(state: &state, expectedActor: "A")
        try performTurn(state: &state, expectedActor: "B")
        try performTurn(state: &state, expectedActor: "C")
        try performTurn(state: &state, expectedActor: "A") { working in
            try applyTurnIntent(.revealVictoryPoint, state: &working)
        }

        return state
    }

    private func runMatch2RoadCityRace() throws -> CoreGameStateV1 {
        let roster = ["A", "B", "C", "D"]
        let base = try makeTurnStateFromSetup(
            gameId: "scripted-match-2",
            roster: roster,
            seed: 2002
        )

        var state = preparedTurnSnapshot(
            from: base,
            currentPlayer: "A",
            resourcesByPlayer: [
                "A": ResourceHandV1(wood: 10, brick: 10, sheep: 5, wheat: 8, ore: 10),
                "B": ResourceHandV1(wood: 3, brick: 3, sheep: 3, wheat: 3, ore: 3),
                "C": ResourceHandV1(wood: 3, brick: 3, sheep: 3, wheat: 3, ore: 3),
                "D": ResourceHandV1(wood: 3, brick: 3, sheep: 3, wheat: 3, ore: 3),
            ],
            devCardsByPlayer: base.devCardsByPlayer,
            revealedVPByPlayer: [
                "A": 6,
                "B": 0,
                "C": 0,
                "D": 0,
            ]
        )

        try performTurn(state: &state, expectedActor: "A") { working in
            let hand = working.resourcesByPlayer["A"] ?? .zero
            if hand.wood >= 1, hand.brick >= 1,
               let firstRoad = firstLegalRoadEdge(for: "A", in: working) {
                try applyTurnIntent(.buildRoad(edgeID: firstRoad), state: &working)
            }

            let firstCity = try require(firstUpgradeableCityNode(for: "A", in: working), "Expected upgradeable city node for A.")
            try applyTurnIntent(.buildCity(nodeID: firstCity), state: &working)
        }

        try performTurn(state: &state, expectedActor: "B")
        try performTurn(state: &state, expectedActor: "C")
        try performTurn(state: &state, expectedActor: "D")
        try performTurn(state: &state, expectedActor: "A") { working in
            let hand = working.resourcesByPlayer["A"] ?? .zero
            if hand.wood >= 1, hand.brick >= 1,
               let secondRoad = firstLegalRoadEdge(for: "A", in: working) {
                try applyTurnIntent(.buildRoad(edgeID: secondRoad), state: &working)
            }

            let secondCity = try require(firstUpgradeableCityNode(for: "A", in: working), "Expected second upgradeable city node for A.")
            try applyTurnIntent(.buildCity(nodeID: secondCity), state: &working)
        }

        return state
    }

    private func runMatch3DevArmyPath() throws -> CoreGameStateV1 {
        let roster = ["A", "B", "C"]
        let base = try makeTurnStateFromSetup(
            gameId: "scripted-match-3",
            roster: roster,
            seed: 3003
        )

        var state = preparedTurnSnapshot(
            from: base,
            currentPlayer: "A",
            resourcesByPlayer: [
                "A": ResourceHandV1(wood: 4, brick: 4, sheep: 4, wheat: 4, ore: 4),
                "B": ResourceHandV1(wood: 4, brick: 4, sheep: 4, wheat: 4, ore: 4),
                "C": ResourceHandV1(wood: 4, brick: 4, sheep: 4, wheat: 4, ore: 4),
            ],
            devCardsByPlayer: [
                "A": DevCardInventoryV1(knight: 3),
                "B": .zero,
                "C": .zero,
            ],
            revealedVPByPlayer: [
                "A": 6,
                "B": 0,
                "C": 0,
            ]
        )

        for _ in 0..<2 {
            try performTurn(state: &state, expectedActor: "A") { working in
                let targetTile = nextRobberTileID(from: working)
                try applyTurnIntent(.playKnight(tileID: targetTile, victimPlayer: nil), state: &working)
            }
            try performTurn(state: &state, expectedActor: "B")
            try performTurn(state: &state, expectedActor: "C")
        }

        try performTurn(state: &state, expectedActor: "A") { working in
            let targetTile = nextRobberTileID(from: working)
            try applyTurnIntent(.playKnight(tileID: targetTile, victimPlayer: nil), state: &working)
        }

        return state
    }

    private func runMatch4TradeMaritimePath() throws -> CoreGameStateV1 {
        let roster = ["A", "B", "C", "D"]
        let base = try makeTurnStateFromSetup(
            gameId: "scripted-match-4",
            roster: roster,
            seed: 4004
        )

        var state = preparedTurnSnapshot(
            from: base,
            currentPlayer: "A",
            resourcesByPlayer: [
                "A": ResourceHandV1(wood: 10, brick: 0, sheep: 2, wheat: 2, ore: 2),
                "B": ResourceHandV1(wood: 1, brick: 4, sheep: 1, wheat: 1, ore: 1),
                "C": ResourceHandV1(wood: 2, brick: 2, sheep: 2, wheat: 2, ore: 2),
                "D": ResourceHandV1(wood: 2, brick: 2, sheep: 2, wheat: 2, ore: 2),
            ],
            devCardsByPlayer: [
                "A": DevCardInventoryV1(victoryPoint: 1),
                "B": .zero,
                "C": .zero,
                "D": .zero,
            ],
            revealedVPByPlayer: [
                "A": 7,
                "B": 0,
                "C": 0,
                "D": 0,
            ]
        )

        try performTurn(state: &state, expectedActor: "A") { working in
            let give = ResourceHandV1(wood: 1)
            let receive = ResourceHandV1(brick: 1)
            try applyTurnIntent(.proposeTrade(give: give, receive: receive), state: &working)

            let offerHash = try require(working.activeTradeOffer?.offerHash, "Expected active offer hash after propose.")
            try applyTurnIntent(.acceptTrade(acceptingPlayer: "B", offerHash: offerHash), state: &working)
            try applyTurnIntent(.executeTrade(acceptingPlayer: "B", offerHash: offerHash), state: &working)

            let ratio = bestMaritimeTradeRatio(
                player: "A",
                giveResource: .wood,
                board: try require(working.board, "Expected board for maritime trade."),
                settlementsByNode: working.settlementsByNode,
                citiesByNode: working.citiesByNode
            )
            try applyTurnIntent(
                .maritimeTrade(
                    give: ResourceHandV1(wood: ratio),
                    receive: ResourceHandV1(ore: 1)
                ),
                state: &working
            )
        }

        try performTurn(state: &state, expectedActor: "B")
        try performTurn(state: &state, expectedActor: "C")
        try performTurn(state: &state, expectedActor: "D")
        try performTurn(state: &state, expectedActor: "A") { working in
            try applyTurnIntent(.revealVictoryPoint, state: &working)
        }

        return state
    }

    private func makeTurnStateFromSetup(
        gameId: String,
        roster: [String],
        seed: UInt64
    ) throws -> CoreGameStateV1 {
        let rules = BoardRulesV1(strategy: .randomV1)
        let seedDeriver = SeedDeriver(masterSeed: seed)
        let board = StandardBoardGeneratorV1.generate(
            boardSeed: seedDeriver.seed(for: .board),
            rules: rules
        )

        var state = CoreGameStateV1(
            gameId: gameId,
            rev: 0,
            prevHash: nil,
            stateHash: "",
            roster: roster,
            currentPlayer: roster[0],
            phase: .setup,
            seed: seed,
            diceRngState: seedDeriver.seed(for: .dice),
            robberRngState: seedDeriver.seed(for: .robber),
            resourcesByPlayer: Dictionary(uniqueKeysWithValues: roster.map { ($0, .zero) }),
            bankResources: .standardBank,
            devDeck: makeDeterministicDevDeck(masterSeed: seed),
            boardRules: rules,
            board: board,
            setupState: initializeSetupState(roster: roster),
            turnState: nil
        ).rehashed()

        while state.phase == .setup {
            guard let setup = state.setupState else {
                XCTFail("Expected setup state while in setup phase.")
                break
            }

            switch setup.step {
            case .placeSettlement:
                let occupiedNodes = occupiedSettlementNodes(from: setup.placements)
                let occupiedEdges = occupiedRoadEdges(from: setup.placements)
                let settlement = try firstLegalSetupSettlementNode(occupiedNodes: occupiedNodes)
                let road = try firstIncidentSetupEdge(for: settlement, occupiedEdges: occupiedEdges)
                try applySetupIntent(.placeSetupPair(settlementNode: settlement, roadEdge: road), state: &state)
            case .placeRoad:
                guard let lastNode = setup.lastPlacedSettlementNode else {
                    throw XCTSkip("No last settlement available for setup road placement.")
                }
                let occupiedEdges = occupiedRoadEdges(from: setup.placements)
                let road = try firstIncidentSetupEdge(for: lastNode, occupiedEdges: occupiedEdges)
                try applySetupIntent(.placeSetupRoad(edge: road), state: &state)
            case .done:
                XCTFail("Setup step .done should not appear in active setup flow.")
            }
        }

        XCTAssertEqual(state.phase, .turn)
        XCTAssertEqual(state.turnState?.step, .needsRoll)
        return state
    }

    private func preparedTurnSnapshot(
        from state: CoreGameStateV1,
        currentPlayer: String,
        resourcesByPlayer: [String: ResourceHandV1],
        devCardsByPlayer: [String: DevCardInventoryV1],
        revealedVPByPlayer: [String: Int]
    ) -> CoreGameStateV1 {
        CoreGameStateV1(
            gameId: state.gameId,
            rev: state.rev,
            prevHash: state.prevHash,
            stateHash: "",
            roster: state.roster,
            currentPlayer: currentPlayer,
            phase: .turn,
            seed: state.seed,
            diceRngState: state.diceRngState,
            robberRngState: state.robberRngState,
            resourcesByPlayer: resourcesByPlayer,
            bankResources: state.bankResources,
            devDeck: state.devDeck,
            devCardsByPlayer: devCardsByPlayer,
            newDevCardsByPlayer: Dictionary(uniqueKeysWithValues: state.roster.map { ($0, .zero) }),
            revealedVictoryPointsByPlayer: revealedVPByPlayer,
            devCardActionPlayedThisTurn: false,
            knightsPlayedByPlayer: Dictionary(uniqueKeysWithValues: state.roster.map { ($0, 0) }),
            largestArmyOwner: nil,
            largestArmySize: 0,
            longestRoadOwner: nil,
            longestRoadLength: 0,
            winnerPlayer: nil,
            winningVictoryPoints: 0,
            auditLog: [],
            lastTurnRecap: nil,
            activeTradeOffer: nil,
            pendingTradeAccepts: [],
            settlementsByNode: state.settlementsByNode,
            citiesByNode: state.citiesByNode,
            roadsByEdge: state.roadsByEdge,
            boardRules: state.boardRules,
            board: state.board,
            setupState: nil,
            turnState: TurnStateV1(step: .needsRoll, lastRoll: nil)
        ).rehashed()
    }

    private func performTurn(
        state: inout CoreGameStateV1,
        expectedActor: String,
        actions: (inout CoreGameStateV1) throws -> Void = { _ in }
    ) throws {
        XCTAssertEqual(state.currentPlayer, expectedActor)
        XCTAssertEqual(state.phase, .turn)

        try applyTurnIntent(.rollDice, state: &state)
        try resolveTurnSubflowAfterRoll(state: &state)
        try actions(&state)

        if state.phase == .gameOver {
            return
        }
        try applyTurnIntent(.endTurn, state: &state)
    }

    private func resolveTurnSubflowAfterRoll(state: inout CoreGameStateV1) throws {
        var guardCounter = 0
        while state.phase == .turn, let step = state.turnState?.step, step != .afterRoll {
            guardCounter += 1
            if guardCounter > 20 {
                XCTFail("Exceeded subflow guard while resolving roll.")
                break
            }

            switch step {
            case .pendingDiscards:
                guard let turnState = state.turnState else {
                    XCTFail("Missing turn state during discard subflow.")
                    return
                }
                for player in turnState.discardRequirementsByPlayer.keys.sorted() {
                    guard turnState.submittedDiscardsByPlayer[player] == nil else {
                        continue
                    }
                    let required = turnState.discardRequirementsByPlayer[player] ?? 0
                    let hand = state.resourcesByPlayer[player] ?? .zero
                    let discarded = deterministicDiscard(required: required, hand: hand)
                    try applyTurnIntent(.submitDiscard(player: player, discarded: discarded), state: &state)
                }
            case .needsRobberMove:
                let robberTile = try require(state.board?.robberTile, "Expected board robber tile for robber move.")
                let boardCount = try require(state.board?.resourcesByTile.count, "Expected board resources for robber move.")
                let nextTile = (robberTile + 1) % max(1, boardCount)
                try applyTurnIntent(.moveRobber(tileID: nextTile), state: &state)
            case .needsRobberSteal:
                let victim = try require(state.turnState?.eligibleStealVictims.sorted().first, "Expected eligible robber steal victim.")
                try applyTurnIntent(.selectStealVictim(victimPlayer: victim), state: &state)
            case .needsRoll, .afterRoll:
                return
            }
        }
    }

    private func applySetupIntent(_ intent: SetupIntentV1, state: inout CoreGameStateV1) throws {
        let from = state
        let actor = from.currentPlayer
        let to = try apply(intent: intent, to: from, actor: actor)
        try validateTransition(from: from, to: to, actor: actor)
        state = to
    }

    private func applyTurnIntent(_ intent: TurnIntentV1, state: inout CoreGameStateV1) throws {
        let from = state
        let actor = from.currentPlayer
        let to = try apply(intent: intent, to: from, actor: actor)
        try validateTransition(from: from, to: to, actor: actor)
        state = to
    }

    private func firstLegalRoadEdge(for player: String, in state: CoreGameStateV1) -> Int? {
        for edgeID in topology.edges.indices where state.roadsByEdge[edgeID] == nil {
            let edge = topology.edges[edgeID]
            let nodes = [edge.a, edge.b]
            for node in nodes {
                if state.settlementsByNode[node] == player || state.citiesByNode[node] == player {
                    return edgeID
                }
                if state.settlementsByNode[node] != nil || state.citiesByNode[node] != nil {
                    continue
                }
                for adjacentEdge in topology.edges(incidentTo: node) where adjacentEdge != edgeID {
                    if state.roadsByEdge[adjacentEdge] == player {
                        return edgeID
                    }
                }
            }
        }
        return nil
    }

    private func firstUpgradeableCityNode(for player: String, in state: CoreGameStateV1) -> Int? {
        state.settlementsByNode
            .filter { $0.value == player }
            .map(\.key)
            .sorted()
            .first
    }

    private func deterministicDiscard(required: Int, hand: ResourceHandV1) -> ResourceHandV1 {
        var remaining = required
        var discarded = ResourceHandV1.zero

        let wood = min(hand.wood, remaining)
        discarded = discarded.adding(wood, for: .wood)
        remaining -= wood

        let brick = min(hand.brick, remaining)
        discarded = discarded.adding(brick, for: .brick)
        remaining -= brick

        let sheep = min(hand.sheep, remaining)
        discarded = discarded.adding(sheep, for: .sheep)
        remaining -= sheep

        let wheat = min(hand.wheat, remaining)
        discarded = discarded.adding(wheat, for: .wheat)
        remaining -= wheat

        let ore = min(hand.ore, remaining)
        discarded = discarded.adding(ore, for: .ore)
        remaining -= ore

        XCTAssertEqual(remaining, 0)
        return discarded
    }

    private func nextRobberTileID(from state: CoreGameStateV1) -> Int {
        guard let board = state.board, !board.resourcesByTile.isEmpty else {
            return 0
        }
        return (board.robberTile + 1) % board.resourcesByTile.count
    }

    private func bestMaritimeTradeRatio(
        player: String,
        giveResource: ResourceV1,
        board: BoardSetupV1,
        settlementsByNode: [NodeID: String],
        citiesByNode: [NodeID: String]
    ) -> Int {
        var hasThreeToOne = false
        var hasMatchingTwoToOne = false

        for portIndex in board.portsByIndex.indices {
            guard portIndex < topology.ports.count else {
                continue
            }
            let port = topology.ports[portIndex]
            let edge = topology.edges[port.edge]
            let ownsPort =
                settlementsByNode[edge.a] == player ||
                settlementsByNode[edge.b] == player ||
                citiesByNode[edge.a] == player ||
                citiesByNode[edge.b] == player
            if !ownsPort {
                continue
            }

            switch board.portsByIndex[portIndex] {
            case .threeToOne:
                hasThreeToOne = true
            case let .twoToOne(resource):
                if resource == giveResource {
                    hasMatchingTwoToOne = true
                }
            }
        }

        if hasMatchingTwoToOne {
            return 2
        }
        if hasThreeToOne {
            return 3
        }
        return 4
    }

    private func firstLegalSetupSettlementNode(occupiedNodes: Set<NodeID>) throws -> NodeID {
        for node in 0..<topology.nodesCount {
            if occupiedNodes.contains(node) {
                continue
            }
            let adjacent = Set(topology.nodes(adjacentTo: node))
            if adjacent.isDisjoint(with: occupiedNodes) {
                return node
            }
        }
        throw XCTSkip("No legal setup settlement node found.")
    }

    private func firstIncidentSetupEdge(for node: NodeID, occupiedEdges: Set<EdgeID>) throws -> EdgeID {
        for edgeID in topology.edges(incidentTo: node) where !occupiedEdges.contains(edgeID) {
            return edgeID
        }
        throw XCTSkip("No legal setup edge found for node \(node).")
    }

    private func occupiedSettlementNodes(from placements: [String: PlayerSetupPlacementsV1]) -> Set<NodeID> {
        var nodes: Set<NodeID> = []
        for placement in placements.values {
            if let settlement1 = placement.settlement1 {
                nodes.insert(settlement1)
            }
            if let settlement2 = placement.settlement2 {
                nodes.insert(settlement2)
            }
        }
        return nodes
    }

    private func occupiedRoadEdges(from placements: [String: PlayerSetupPlacementsV1]) -> Set<EdgeID> {
        var edges: Set<EdgeID> = []
        for placement in placements.values {
            if let road1 = placement.road1 {
                edges.insert(road1)
            }
            if let road2 = placement.road2 {
                edges.insert(road2)
            }
        }
        return edges
    }

    private func require<T>(_ value: T?, _ message: String) throws -> T {
        guard let value else {
            XCTFail(message)
            throw XCTSkip(message)
        }
        return value
    }

    private func assertTerminalState(
        _ state: CoreGameStateV1,
        expectedWinner: String,
        roster: [String]
    ) {
        XCTAssertEqual(state.phase, .gameOver)
        XCTAssertEqual(state.winnerPlayer, expectedWinner)
        XCTAssertGreaterThanOrEqual(state.winningVictoryPoints, 10)

        let rollActors = Set(
            state.auditLog
                .filter { $0.action == .rollDice }
                .map(\.actor)
        )
        XCTAssertEqual(rollActors, Set(roster))
    }

    private func assertDeterministicReplay(_ lhs: CoreGameStateV1, _ rhs: CoreGameStateV1) {
        XCTAssertEqual(lhs.stateHash, rhs.stateHash)
        XCTAssertEqual(lhs.auditLog, rhs.auditLog)
        XCTAssertEqual(lhs.lastTurnRecap, rhs.lastTurnRecap)
    }
}
