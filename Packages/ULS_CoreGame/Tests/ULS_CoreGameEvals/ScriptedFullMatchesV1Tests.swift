import XCTest
@testable import ULS_CoreGame

final class ScriptedFullMatchesV1Tests: XCTestCase {
    private let topology = StandardBoardTopologyV1.standard()
    private let resources: [ResourceV1] = [.wood, .brick, .sheep, .wheat, .ore]

    private enum PlayerPolicyV1 {
        case balanced
        case tradeHeavy
        case devHeavy
        case maritimeHeavy
        case conservative
    }

    private struct MatchConfigV1 {
        let gameId: String
        let roster: [String]
        let seed: UInt64
        let policyByPlayer: [String: PlayerPolicyV1]
        let maxTurns: Int
        let requiredActions: [AuditActionV1]
        let requiredAnyActions: [AuditActionV1]
        let expectedWinner: String?
    }

    private struct MatchResultV1 {
        let finalState: CoreGameStateV1
        let turnsByPlayer: [String: Int]
    }

    func testMatch1BalancedSetupToWinIsDeterministic() throws {
        let config = MatchConfigV1(
            gameId: "full-sim-match-1",
            roster: ["A", "B", "C"],
            seed: 6101,
            policyByPlayer: [:],
            maxTurns: 260,
            requiredActions: [.buildRoad, .buildSettlement, .buildCity],
            requiredAnyActions: [.buyDevCard, .maritimeTrade, .proposeTrade],
            expectedWinner: nil
        )
        let result = try runMatch(config)
        assertTerminalState(result, roster: config.roster, expectedWinner: config.expectedWinner)
        assertActionsObserved(result.finalState, required: config.requiredActions, anyOf: config.requiredAnyActions)
    }

    func testMatch2TradeHeavyFourPlayerIsDeterministic() throws {
        let roster = ["A", "B", "C", "D"]
        let config = MatchConfigV1(
            gameId: "full-sim-match-2",
            roster: roster,
            seed: 6202,
            policyByPlayer: Dictionary(uniqueKeysWithValues: roster.map { ($0, .tradeHeavy) }),
            maxTurns: 300,
            requiredActions: [.proposeTrade, .acceptTrade],
            requiredAnyActions: [.buildRoad, .buildSettlement],
            expectedWinner: nil
        )
        let result = try runMatch(config)
        assertTerminalState(result, roster: config.roster, expectedWinner: config.expectedWinner)
        assertActionsObserved(result.finalState, required: config.requiredActions, anyOf: config.requiredAnyActions)
    }

    func testMatch3DevHeavyThreePlayerIsDeterministic() throws {
        let roster = ["A", "B", "C"]
        let config = MatchConfigV1(
            gameId: "full-sim-match-3",
            roster: roster,
            seed: 6303,
            policyByPlayer: Dictionary(uniqueKeysWithValues: roster.map { ($0, .devHeavy) }),
            maxTurns: 220,
            requiredActions: [.buyDevCard],
            requiredAnyActions: [.playKnight, .playMonopoly, .playYearOfPlenty, .revealVictoryPoint],
            expectedWinner: nil
        )
        let result = try runMatch(config)
        assertTerminalState(result, roster: config.roster, expectedWinner: config.expectedWinner)
        assertActionsObserved(result.finalState, required: config.requiredActions, anyOf: config.requiredAnyActions)
    }

    func testMatch4MaritimeHeavyFourPlayerIsDeterministic() throws {
        let roster = ["A", "B", "C", "D"]
        let config = MatchConfigV1(
            gameId: "full-sim-match-4",
            roster: roster,
            seed: 6404,
            policyByPlayer: Dictionary(uniqueKeysWithValues: roster.map { ($0, .maritimeHeavy) }),
            maxTurns: 280,
            requiredActions: [.maritimeTrade],
            requiredAnyActions: [.buildRoad, .buildSettlement, .buildCity],
            expectedWinner: nil
        )
        let result = try runMatch(config)
        assertTerminalState(result, roster: config.roster, expectedWinner: config.expectedWinner)
        assertActionsObserved(result.finalState, required: config.requiredActions, anyOf: config.requiredAnyActions)
    }

    func testMatch5NonAWinnerPathIsDeterministic() throws {
        let config = MatchConfigV1(
            gameId: "full-sim-match-5",
            roster: ["A", "B", "C"],
            seed: 6505,
            policyByPlayer: [
                "A": .conservative,
                "B": .tradeHeavy,
                "C": .conservative,
            ],
            maxTurns: 260,
            requiredActions: [.submitDiscard, .moveRobber],
            requiredAnyActions: [.buildCity, .revealVictoryPoint, .playKnight],
            expectedWinner: "B"
        )
        let result = try runMatch(config)
        assertTerminalState(result, roster: config.roster, expectedWinner: config.expectedWinner)
        assertActionsObserved(result.finalState, required: config.requiredActions, anyOf: config.requiredAnyActions)
    }

    func testMatch6RandomizedThreePlayerDevRaceIsDeterministic() throws {
        let config = MatchConfigV1(
            gameId: "full-sim-match-6",
            roster: ["A", "B", "C"],
            seed: 7606,
            policyByPlayer: [
                "A": .devHeavy,
                "B": .balanced,
                "C": .tradeHeavy,
            ],
            maxTurns: 260,
            requiredActions: [.buyDevCard, .playKnight],
            requiredAnyActions: [.playMonopoly, .playYearOfPlenty, .revealVictoryPoint],
            expectedWinner: nil
        )
        let result = try runMatch(config)
        assertTerminalState(result, roster: config.roster, expectedWinner: config.expectedWinner)
        assertActionsObserved(result.finalState, required: config.requiredActions, anyOf: config.requiredAnyActions)
    }

    func testMatch7RandomizedFourPlayerMixedEconomyWithDevIsDeterministic() throws {
        let config = MatchConfigV1(
            gameId: "full-sim-match-7",
            roster: ["A", "B", "C", "D"],
            seed: 7707,
            policyByPlayer: [
                "A": .devHeavy,
                "B": .maritimeHeavy,
                "C": .tradeHeavy,
                "D": .balanced,
            ],
            maxTurns: 320,
            requiredActions: [.buyDevCard, .proposeTrade, .maritimeTrade],
            requiredAnyActions: [.playKnight, .playMonopoly, .playYearOfPlenty, .revealVictoryPoint, .buildCity],
            expectedWinner: nil
        )
        let result = try runMatch(config)
        assertTerminalState(result, roster: config.roster, expectedWinner: config.expectedWinner)
        assertActionsObserved(result.finalState, required: config.requiredActions, anyOf: config.requiredAnyActions)
    }

    func testDeterministicReplayForRepresentativeMatches() throws {
        let threePlayer = allConfigs()[0]
        let nonAWinner = allConfigs()[4]

        let threeA = try runMatch(threePlayer).finalState
        let threeB = try runMatch(threePlayer).finalState
        assertDeterministicReplay(threeA, threeB)

        let nonAA = try runMatch(nonAWinner).finalState
        let nonAB = try runMatch(nonAWinner).finalState
        assertDeterministicReplay(nonAA, nonAB)
    }

    func testDeterministicReplayForRandomizedMatches6And7() throws {
        let randomizedThreePlayer = allConfigs()[5]
        let randomizedFourPlayer = allConfigs()[6]

        let threeA = try runMatch(randomizedThreePlayer).finalState
        let threeB = try runMatch(randomizedThreePlayer).finalState
        assertDeterministicReplay(threeA, threeB)

        let fourA = try runMatch(randomizedFourPlayer).finalState
        let fourB = try runMatch(randomizedFourPlayer).finalState
        assertDeterministicReplay(fourA, fourB)
    }

    func testLiveStateInvariantViolationsAreRejected() throws {
        var state = try makeTurnStateFromSetup(
            gameId: "full-sim-violations",
            roster: ["A", "B", "C"],
            seed: 7777
        )
        let actor = state.currentPlayer
        let other = try require(state.roster.first(where: { $0 != actor }), "Expected non-actor in roster.")

        try assertRejectedTurnIntent(
            state: state,
            intent: .endTurn,
            actor: actor,
            expected: .turnStepMismatch
        )
        try assertRejectedTurnIntent(
            state: state,
            intent: .rollDice,
            actor: other,
            expected: .actorMismatch
        )

        try applyTurnIntent(.rollDice, state: &state)
        try resolveTurnSubflowAfterRoll(state: &state)
        guard state.phase == .turn else {
            XCTFail("Unexpected game over before violation checks.")
            return
        }

        try assertRejectedTurnIntent(
            state: state,
            intent: .rollDice,
            actor: actor,
            expected: .turnStepMismatch
        )

        if let plan = firstTradePlan(for: state) {
            let proposed = TurnIntentV1.proposeTrade(give: plan.give, receive: plan.receive, recipients: [plan.acceptor])
            try applyTurnIntent(proposed, state: &state)
            try assertRejectedTurnIntent(
                state: state,
                intent: .acceptTrade(acceptingPlayer: plan.acceptor, offerHash: "bad-anchor"),
                actor: plan.acceptor,
                expected: .tradeOfferAnchorMismatch
            )
        }

        let from = state
        let valid = try apply(intent: .endTurn, to: from, actor: from.currentPlayer)
        try validateTransition(from: from, to: valid, actor: from.currentPlayer)

        let tampered = copiedState(from: valid, bankResources: valid.bankResources.adding(1, for: .wood)).rehashed()
        XCTAssertThrowsError(try validateTransition(from: from, to: tampered, actor: from.currentPlayer)) { error in
            XCTAssertEqual(error as? CoreGameError, .bankResourcesInvalid)
        }
    }

    private func allConfigs() -> [MatchConfigV1] {
        [
            MatchConfigV1(
                gameId: "full-sim-match-1",
                roster: ["A", "B", "C"],
                seed: 6101,
                policyByPlayer: [:],
                maxTurns: 260,
                requiredActions: [.buildRoad, .buildSettlement, .buildCity],
                requiredAnyActions: [.buyDevCard, .maritimeTrade, .proposeTrade],
                expectedWinner: nil
            ),
            MatchConfigV1(
                gameId: "full-sim-match-2",
                roster: ["A", "B", "C", "D"],
                seed: 6202,
                policyByPlayer: ["A": .tradeHeavy, "B": .tradeHeavy, "C": .tradeHeavy, "D": .tradeHeavy],
                maxTurns: 300,
                requiredActions: [.proposeTrade, .acceptTrade],
                requiredAnyActions: [.buildRoad, .buildSettlement],
                expectedWinner: nil
            ),
            MatchConfigV1(
                gameId: "full-sim-match-3",
                roster: ["A", "B", "C"],
                seed: 6303,
                policyByPlayer: ["A": .devHeavy, "B": .devHeavy, "C": .devHeavy],
                maxTurns: 220,
                requiredActions: [.buyDevCard],
                requiredAnyActions: [.playKnight, .playMonopoly, .playYearOfPlenty, .revealVictoryPoint],
                expectedWinner: nil
            ),
            MatchConfigV1(
                gameId: "full-sim-match-4",
                roster: ["A", "B", "C", "D"],
                seed: 6404,
                policyByPlayer: ["A": .maritimeHeavy, "B": .maritimeHeavy, "C": .maritimeHeavy, "D": .maritimeHeavy],
                maxTurns: 280,
                requiredActions: [.maritimeTrade],
                requiredAnyActions: [.buildRoad, .buildSettlement, .buildCity],
                expectedWinner: nil
            ),
            MatchConfigV1(
                gameId: "full-sim-match-5",
                roster: ["A", "B", "C"],
                seed: 6505,
                policyByPlayer: ["A": .conservative, "B": .tradeHeavy, "C": .conservative],
                maxTurns: 260,
                requiredActions: [.submitDiscard, .moveRobber],
                requiredAnyActions: [.buildCity, .revealVictoryPoint, .playKnight],
                expectedWinner: "B"
            ),
            MatchConfigV1(
                gameId: "full-sim-match-6",
                roster: ["A", "B", "C"],
                seed: 7606,
                policyByPlayer: ["A": .devHeavy, "B": .balanced, "C": .tradeHeavy],
                maxTurns: 260,
                requiredActions: [.buyDevCard, .playKnight],
                requiredAnyActions: [.playMonopoly, .playYearOfPlenty, .revealVictoryPoint],
                expectedWinner: nil
            ),
            MatchConfigV1(
                gameId: "full-sim-match-7",
                roster: ["A", "B", "C", "D"],
                seed: 7707,
                policyByPlayer: ["A": .devHeavy, "B": .maritimeHeavy, "C": .tradeHeavy, "D": .balanced],
                maxTurns: 320,
                requiredActions: [.buyDevCard, .proposeTrade, .maritimeTrade],
                requiredAnyActions: [.playKnight, .playMonopoly, .playYearOfPlenty, .revealVictoryPoint, .buildCity],
                expectedWinner: nil
            ),
        ]
    }

    private func runMatch(_ config: MatchConfigV1) throws -> MatchResultV1 {
        var state = try makeTurnStateFromSetup(
            gameId: config.gameId,
            roster: config.roster,
            seed: config.seed
        )
        var turnsByPlayer = Dictionary(uniqueKeysWithValues: config.roster.map { ($0, 0) })
        var turns = 0

        while state.phase == .turn, turns < config.maxTurns {
            turns += 1
            let actor = state.currentPlayer
            turnsByPlayer[actor, default: 0] += 1

            if turns == 1 || turns % 8 == 0 {
                if let nonActor = config.roster.first(where: { $0 != actor }) {
                    try assertRejectedTurnIntent(
                        state: state,
                        intent: .rollDice,
                        actor: nonActor,
                        expected: .actorMismatch
                    )
                }
                try assertRejectedTurnIntent(
                    state: state,
                    intent: .endTurn,
                    actor: actor,
                    expected: .turnStepMismatch
                )
            }

            try applyTurnIntent(.rollDice, state: &state)
            try resolveTurnSubflowAfterRoll(state: &state)
            if state.phase == .gameOver {
                break
            }

            guard state.turnState?.step == .afterRoll else {
                XCTFail("Expected afterRoll after subflow resolution.")
                break
            }

            if turns == 1 || turns % 8 == 0 {
                try assertRejectedTurnIntent(
                    state: state,
                    intent: .rollDice,
                    actor: actor,
                    expected: .turnStepMismatch
                )
            }

            var actions = 0
            while state.phase == .turn, state.turnState?.step == .afterRoll, actions < 6 {
                let policy = effectivePolicy(for: state.currentPlayer, turn: turns, config: config)
                if try !performPolicyAction(policy: policy, state: &state) {
                    break
                }
                actions += 1
            }

            if state.phase == .gameOver {
                break
            }

            try applyTurnIntent(.endTurn, state: &state)
        }

        XCTAssertEqual(
            state.phase,
            .gameOver,
            "Simulation stalled before game over for gameId=\(config.gameId), seed=\(config.seed), turns=\(turns)."
        )
        return MatchResultV1(finalState: state, turnsByPlayer: turnsByPlayer)
    }

    private func effectivePolicy(for player: String, turn: Int, config: MatchConfigV1) -> PlayerPolicyV1 {
        let base = config.policyByPlayer[player] ?? .balanced
        let sprintThreshold = (config.maxTurns * 3) / 4
        guard turn >= sprintThreshold else {
            return base
        }

        if let expected = config.expectedWinner {
            return player == expected ? .balanced : .conservative
        }
        return .balanced
    }

    private func performPolicyAction(policy: PlayerPolicyV1, state: inout CoreGameStateV1) throws -> Bool {
        switch policy {
        case .balanced:
            if try attemptRevealVictoryPoint(state: &state) { return true }
            if try attemptBuildCity(state: &state) { return true }
            if try attemptBuildSettlement(state: &state) { return true }
            if try attemptPlayDevCard(state: &state) { return true }
            if try attemptBuildRoad(state: &state) { return true }
            if try attemptAdvanceTrade(state: &state) { return true }
            if try attemptMaritimeTrade(state: &state) { return true }
            if try attemptBuyDevCard(state: &state) { return true }
            return false
        case .tradeHeavy:
            if try attemptRevealVictoryPoint(state: &state) { return true }
            if try attemptBuildCity(state: &state) { return true }
            if try attemptBuildSettlement(state: &state) { return true }
            if try attemptBuildRoad(state: &state) { return true }
            if try attemptAdvanceTrade(state: &state) { return true }
            if try attemptMaritimeTrade(state: &state) { return true }
            if try attemptPlayDevCard(state: &state) { return true }
            if try attemptBuyDevCard(state: &state) { return true }
            return false
        case .devHeavy:
            if try attemptRevealVictoryPoint(state: &state) { return true }
            if try attemptPlayDevCard(state: &state) { return true }
            if try attemptBuyDevCard(state: &state) { return true }
            if try attemptBuildCity(state: &state) { return true }
            if try attemptBuildSettlement(state: &state) { return true }
            if try attemptBuildRoad(state: &state) { return true }
            if try attemptMaritimeTrade(state: &state) { return true }
            if try attemptAdvanceTrade(state: &state) { return true }
            return false
        case .maritimeHeavy:
            if try attemptRevealVictoryPoint(state: &state) { return true }
            if try attemptBuildCity(state: &state) { return true }
            if try attemptBuildSettlement(state: &state) { return true }
            if try attemptBuildRoad(state: &state) { return true }
            if try attemptMaritimeTrade(state: &state) { return true }
            if try attemptAdvanceTrade(state: &state) { return true }
            if try attemptPlayDevCard(state: &state) { return true }
            if try attemptBuyDevCard(state: &state) { return true }
            return false
        case .conservative:
            if try attemptRevealVictoryPoint(state: &state) { return true }
            return false
        }
    }

    private func attemptRevealVictoryPoint(state: inout CoreGameStateV1) throws -> Bool {
        try tryApplyIfLegal(.revealVictoryPoint, state: &state)
    }

    private func attemptBuildCity(state: inout CoreGameStateV1) throws -> Bool {
        let player = state.currentPlayer
        let nodes = state.settlementsByNode
            .filter { $0.value == player }
            .map(\.key)
            .sorted()
        for node in nodes {
            if try tryApplyIfLegal(.buildCity(nodeID: node), state: &state) {
                return true
            }
        }
        return false
    }

    private func attemptBuildSettlement(state: inout CoreGameStateV1) throws -> Bool {
        let player = state.currentPlayer
        for node in candidateSettlementNodes(for: player, in: state) {
            if try tryApplyIfLegal(.buildSettlement(nodeID: node), state: &state) {
                return true
            }
        }
        return false
    }

    private func attemptBuildRoad(state: inout CoreGameStateV1) throws -> Bool {
        let player = state.currentPlayer
        for edge in candidateRoadEdges(for: player, in: state) {
            if try tryApplyIfLegal(.buildRoad(edgeID: edge), state: &state) {
                return true
            }
        }
        return false
    }

    private func attemptBuyDevCard(state: inout CoreGameStateV1) throws -> Bool {
        try tryApplyIfLegal(.buyDevCard, state: &state)
    }

    private func attemptPlayDevCard(state: inout CoreGameStateV1) throws -> Bool {
        let player = state.currentPlayer
        let inventory = state.devCardsByPlayer[player] ?? .zero
        if inventory.knight > 0 {
            if let intent = bestKnightIntent(for: state) {
                return try tryApplyIfLegal(intent, state: &state)
            }
        }
        if inventory.monopoly > 0 {
            if let resource = bestMonopolyResource(for: player, in: state) {
                return try tryApplyIfLegal(.playMonopoly(resource: resource), state: &state)
            }
        }
        if inventory.yearOfPlenty > 0 {
            if let (first, second) = bestYearOfPlentyPair(for: state) {
                return try tryApplyIfLegal(.playYearOfPlenty(first: first, second: second), state: &state)
            }
        }
        return false
    }

    private func attemptAdvanceTrade(state: inout CoreGameStateV1) throws -> Bool {
        if let offer = state.activeTradeOffer {
            if state.tradeResponses.isEmpty {
                let acceptors = state.roster
                    .filter { state.activeTradeOffer?.recipients.contains($0) == true }
                    .sorted()
                for acceptor in acceptors {
                    let hand = state.resourcesByPlayer[acceptor] ?? .zero
                    if canAfford(hand: hand, cost: offer.receive) {
                        if try tryApplyIfLegal(
                            .acceptTrade(acceptingPlayer: acceptor, offerHash: offer.offerHash),
                            state: &state
                        ) {
                            return true
                        }
                    }
                }
                return false
            }
            return false
        }

        if let plan = firstTradePlan(for: state) {
            return try tryApplyIfLegal(
                .proposeTrade(give: plan.give, receive: plan.receive, recipients: [plan.acceptor]),
                state: &state
            )
        }
        return false
    }

    private struct TradePlanV1 {
        let give: ResourceHandV1
        let receive: ResourceHandV1
        let acceptor: String
    }

    private func firstTradePlan(for state: CoreGameStateV1) -> TradePlanV1? {
        guard state.activeTradeOffer == nil else {
            return nil
        }
        let proposer = state.currentPlayer
        let proposerHand = state.resourcesByPlayer[proposer] ?? .zero

        let giveCandidates = resources
            .filter { proposerHand.count(for: $0) > 0 }
            .sorted { lhs, rhs in
                let lc = proposerHand.count(for: lhs)
                let rc = proposerHand.count(for: rhs)
                if lc == rc {
                    return lhs.rawValue < rhs.rawValue
                }
                return lc > rc
            }

        for acceptor in state.roster.filter({ $0 != proposer }).sorted() {
            let acceptorHand = state.resourcesByPlayer[acceptor] ?? .zero
            let receiveCandidates = resources
                .filter { acceptorHand.count(for: $0) > 0 }
                .sorted { lhs, rhs in
                    let lc = acceptorHand.count(for: lhs)
                    let rc = acceptorHand.count(for: rhs)
                    if lc == rc {
                        return lhs.rawValue < rhs.rawValue
                    }
                    return lc > rc
                }

            for give in giveCandidates {
                for receive in receiveCandidates where give != receive {
                    return TradePlanV1(
                        give: singleResourceHand(give, amount: 1),
                        receive: singleResourceHand(receive, amount: 1),
                        acceptor: acceptor
                    )
                }
            }
        }
        return nil
    }

    private func attemptMaritimeTrade(state: inout CoreGameStateV1) throws -> Bool {
        guard let board = state.board else {
            return false
        }
        let player = state.currentPlayer
        let hand = state.resourcesByPlayer[player] ?? .zero

        let giveCandidates = resources.sorted { lhs, rhs in
            let lc = hand.count(for: lhs)
            let rc = hand.count(for: rhs)
            if lc == rc {
                return lhs.rawValue < rhs.rawValue
            }
            return lc > rc
        }

        for give in giveCandidates {
            let ratio = bestMaritimeTradeRatio(
                player: player,
                giveResource: give,
                board: board,
                settlementsByNode: state.settlementsByNode,
                citiesByNode: state.citiesByNode
            )
            guard hand.count(for: give) >= ratio else {
                continue
            }

            let receiveCandidates = resources.sorted { lhs, rhs in
                let lc = hand.count(for: lhs)
                let rc = hand.count(for: rhs)
                if lc == rc {
                    return lhs.rawValue < rhs.rawValue
                }
                return lc < rc
            }

            for receive in receiveCandidates where receive != give {
                guard state.bankResources.count(for: receive) >= 1 else {
                    continue
                }
                if try tryApplyIfLegal(
                    .maritimeTrade(
                        give: singleResourceHand(give, amount: ratio),
                        receive: singleResourceHand(receive, amount: 1)
                    ),
                    state: &state
                ) {
                    return true
                }
            }
        }
        return false
    }

    private func bestKnightIntent(for state: CoreGameStateV1) -> TurnIntentV1? {
        guard let board = state.board, !board.resourcesByTile.isEmpty else {
            return nil
        }
        for offset in 1..<board.resourcesByTile.count {
            let tile = (board.robberTile + offset) % board.resourcesByTile.count
            return .playKnight(tileID: tile, victimPlayer: nil)
        }
        return nil
    }

    private func bestMonopolyResource(for player: String, in state: CoreGameStateV1) -> ResourceV1? {
        var bestResource: ResourceV1?
        var bestCount = 0
        for resource in resources {
            var total = 0
            for other in state.roster where other != player {
                total += (state.resourcesByPlayer[other] ?? .zero).count(for: resource)
            }
            if total > bestCount {
                bestCount = total
                bestResource = resource
            }
        }
        return bestCount > 0 ? bestResource : nil
    }

    private func bestYearOfPlentyPair(for state: CoreGameStateV1) -> (ResourceV1, ResourceV1)? {
        let priority: [ResourceV1] = [.ore, .wheat, .brick, .wood, .sheep]
        var picks: [ResourceV1] = []

        for resource in priority {
            if state.bankResources.count(for: resource) > 0 {
                picks.append(resource)
                break
            }
        }
        guard let first = picks.first else {
            return nil
        }

        if state.bankResources.count(for: first) > 1 {
            return (first, first)
        }

        for resource in priority where resource != first {
            if state.bankResources.count(for: resource) > 0 {
                return (first, resource)
            }
        }
        return nil
    }

    private func candidateSettlementNodes(for player: String, in state: CoreGameStateV1) -> [Int] {
        var nodes: Set<Int> = []
        for (edgeID, owner) in state.roadsByEdge where owner == player {
            guard edgeID >= 0, edgeID < topology.edges.count else {
                continue
            }
            let edge = topology.edges[edgeID]
            nodes.insert(edge.a)
            nodes.insert(edge.b)
        }
        return nodes.sorted()
    }

    private func candidateRoadEdges(for player: String, in state: CoreGameStateV1) -> [Int] {
        var anchorNodes: Set<Int> = []
        for (node, owner) in state.settlementsByNode where owner == player {
            anchorNodes.insert(node)
        }
        for (node, owner) in state.citiesByNode where owner == player {
            anchorNodes.insert(node)
        }
        for (edgeID, owner) in state.roadsByEdge where owner == player {
            guard edgeID >= 0, edgeID < topology.edges.count else {
                continue
            }
            let edge = topology.edges[edgeID]
            anchorNodes.insert(edge.a)
            anchorNodes.insert(edge.b)
        }

        var candidates: Set<Int> = []
        for node in anchorNodes {
            for edgeID in topology.edges(incidentTo: node) where state.roadsByEdge[edgeID] == nil {
                candidates.insert(edgeID)
            }
        }
        return candidates.sorted()
    }

    private func tryApplyIfLegal(_ intent: TurnIntentV1, state: inout CoreGameStateV1) throws -> Bool {
        let from = state
        let actor: String
        switch intent {
        case let .acceptTrade(acceptingPlayer, _):
            actor = acceptingPlayer
        case let .declineTrade(decliningPlayer, _):
            actor = decliningPlayer
        case let .counterTrade(counteringPlayer, _, _, _):
            actor = counteringPlayer
        default:
            actor = from.currentPlayer
        }
        guard let next = try? apply(intent: intent, to: from, actor: actor) else {
            return false
        }
        guard (try? validateTransition(from: from, to: next, actor: actor)) != nil else {
            return false
        }
        state = next
        assertStateInvariants(state)
        return true
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
        assertStateInvariants(state)

        while state.phase == .setup {
            guard let setup = state.setupState else {
                XCTFail("Expected setup state while in setup phase.")
                break
            }

            switch setup.step {
            case .placeSettlement:
                let occupiedNodes = occupiedSettlementNodes(from: setup.placements)
                let occupiedEdges = occupiedRoadEdges(from: setup.placements)
                let settlement = try bestLegalSetupSettlementNode(
                    in: state,
                    occupiedNodes: occupiedNodes
                )
                let road = try firstIncidentSetupEdge(
                    for: settlement,
                    occupiedEdges: occupiedEdges
                )
                try applySetupIntent(
                    .placeSetupPair(settlementNode: settlement, roadEdge: road),
                    state: &state
                )
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

    private func resolveTurnSubflowAfterRoll(state: inout CoreGameStateV1) throws {
        var guardCounter = 0
        while state.phase == .turn, let step = state.turnState?.step, step != .afterRoll {
            guardCounter += 1
            if guardCounter > 32 {
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
                    try applyTurnIntent(
                        .submitDiscard(player: player, discarded: discarded),
                        state: &state
                    )
                }
            case .needsRobberMove:
                let tileID = try chooseRobberTileForSubflow(from: state)
                try applyTurnIntent(.moveRobber(tileID: tileID), state: &state)
            case .needsRobberSteal:
                guard let victim = state.turnState?.eligibleStealVictims.sorted().first else {
                    XCTFail("Missing eligible victim during robber steal step.")
                    return
                }
                try applyTurnIntent(.selectStealVictim(victimPlayer: victim), state: &state)
            case .needsRoll, .afterRoll:
                return
            }
        }
    }

    private func chooseRobberTileForSubflow(from state: CoreGameStateV1) throws -> Int {
        let board = try require(state.board, "Expected board for robber move.")
        let tileCount = board.resourcesByTile.count
        guard tileCount > 1 else {
            return 0
        }

        for offset in 1..<tileCount {
            let tile = (board.robberTile + offset) % tileCount
            if !eligibleVictims(for: tile, in: state).isEmpty {
                return tile
            }
        }
        return (board.robberTile + 1) % tileCount
    }

    private func eligibleVictims(for tileID: Int, in state: CoreGameStateV1) -> [String] {
        guard tileID >= 0, tileID < topology.tiles.count else {
            return []
        }
        var victims: Set<String> = []
        for node in topology.tiles[tileID].nodes {
            if let cityOwner = state.citiesByNode[node],
               cityOwner != state.currentPlayer,
               (state.resourcesByPlayer[cityOwner] ?? .zero).totalCount > 0
            {
                victims.insert(cityOwner)
                continue
            }
            if let settlementOwner = state.settlementsByNode[node],
               settlementOwner != state.currentPlayer,
               (state.resourcesByPlayer[settlementOwner] ?? .zero).totalCount > 0
            {
                victims.insert(settlementOwner)
            }
        }
        return victims.sorted()
    }

    private func applySetupIntent(_ intent: SetupIntentV1, state: inout CoreGameStateV1) throws {
        let from = state
        let actor = from.currentPlayer
        let to = try apply(intent: intent, to: from, actor: actor)
        try validateTransition(from: from, to: to, actor: actor)
        state = to
        assertStateInvariants(state)
    }

    private func applyTurnIntent(_ intent: TurnIntentV1, state: inout CoreGameStateV1) throws {
        let from = state
        let actor: String
        switch intent {
        case let .submitDiscard(player, _):
            actor = player
        case let .acceptTrade(acceptingPlayer, _):
            actor = acceptingPlayer
        case let .declineTrade(decliningPlayer, _):
            actor = decliningPlayer
        case let .counterTrade(counteringPlayer, _, _, _):
            actor = counteringPlayer
        default:
            actor = from.currentPlayer
        }
        let to = try apply(intent: intent, to: from, actor: actor)
        try validateTransition(from: from, to: to, actor: actor)
        state = to
        assertStateInvariants(state)
    }

    private func assertRejectedTurnIntent(
        state: CoreGameStateV1,
        intent: TurnIntentV1,
        actor: String,
        expected: CoreGameError
    ) throws {
        let snapshot = state
        XCTAssertThrowsError(try apply(intent: intent, to: state, actor: actor)) { error in
            XCTAssertEqual(error as? CoreGameError, expected)
        }
        XCTAssertEqual(state, snapshot)
    }

    private func copiedState(
        from state: CoreGameStateV1,
        stateHash: String? = nil,
        bankResources: ResourceHandV1? = nil
    ) -> CoreGameStateV1 {
        CoreGameStateV1(
            gameId: state.gameId,
            rev: state.rev,
            prevHash: state.prevHash,
            stateHash: stateHash ?? state.stateHash,
            roster: state.roster,
            currentPlayer: state.currentPlayer,
            phase: state.phase,
            seed: state.seed,
            diceRngState: state.diceRngState,
            robberRngState: state.robberRngState,
            resourcesByPlayer: state.resourcesByPlayer,
            bankResources: bankResources ?? state.bankResources,
            devDeck: state.devDeck,
            devCardsByPlayer: state.devCardsByPlayer,
            newDevCardsByPlayer: state.newDevCardsByPlayer,
            revealedVictoryPointsByPlayer: state.revealedVictoryPointsByPlayer,
            devCardActionPlayedThisTurn: state.devCardActionPlayedThisTurn,
            knightsPlayedByPlayer: state.knightsPlayedByPlayer,
            largestArmyOwner: state.largestArmyOwner,
            largestArmySize: state.largestArmySize,
            longestRoadOwner: state.longestRoadOwner,
            longestRoadLength: state.longestRoadLength,
            winnerPlayer: state.winnerPlayer,
            winningVictoryPoints: state.winningVictoryPoints,
            auditLog: state.auditLog,
            lastTurnRecap: state.lastTurnRecap,
            activeTradeOffer: state.activeTradeOffer,
            tradeResponses: state.tradeResponses,
            settlementsByNode: state.settlementsByNode,
            citiesByNode: state.citiesByNode,
            roadsByEdge: state.roadsByEdge,
            boardRules: state.boardRules,
            board: state.board,
            setupState: state.setupState,
            turnState: state.turnState
        )
    }

    private func singleResourceHand(_ resource: ResourceV1, amount: Int) -> ResourceHandV1 {
        ResourceHandV1.zero.adding(amount, for: resource)
    }

    private func canAfford(hand: ResourceHandV1, cost: ResourceHandV1) -> Bool {
        hand.wood >= cost.wood &&
            hand.brick >= cost.brick &&
            hand.sheep >= cost.sheep &&
            hand.wheat >= cost.wheat &&
            hand.ore >= cost.ore
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

    private func deterministicDiscard(required: Int, hand: ResourceHandV1) -> ResourceHandV1 {
        var remaining = required
        var discarded = ResourceHandV1.zero
        for resource in resources {
            let amount = min(hand.count(for: resource), remaining)
            discarded = discarded.adding(amount, for: resource)
            remaining -= amount
        }
        XCTAssertEqual(remaining, 0)
        return discarded
    }

    private func bestLegalSetupSettlementNode(
        in state: CoreGameStateV1,
        occupiedNodes: Set<NodeID>
    ) throws -> NodeID {
        let board = try require(state.board, "Expected board while computing setup settlement.")
        var bestNode: NodeID?
        var bestScore = Int.min

        for node in 0..<topology.nodesCount {
            if occupiedNodes.contains(node) {
                continue
            }
            let adjacent = Set(topology.nodes(adjacentTo: node))
            if !adjacent.isDisjoint(with: occupiedNodes) {
                continue
            }

            var score = 0
            for tileID in 0..<topology.tiles.count where topology.tiles[tileID].nodes.contains(node) {
                let resource = board.resourcesByTile[tileID]
                guard resource != .desert else {
                    continue
                }
                if let number = board.numbersByTile[tileID] {
                    score += pipScore(number)
                }
            }

            if score > bestScore || (score == bestScore && (bestNode == nil || node < bestNode!)) {
                bestScore = score
                bestNode = node
            }
        }

        return try require(bestNode, "No legal setup settlement node found.")
    }

    private func pipScore(_ number: Int) -> Int {
        switch number {
        case 6, 8:
            return 5
        case 5, 9:
            return 4
        case 4, 10:
            return 3
        case 3, 11:
            return 2
        case 2, 12:
            return 1
        default:
            return 0
        }
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

    private func assertStateInvariants(_ state: CoreGameStateV1, file: StaticString = #filePath, line: UInt = #line) {
        assertNonNegativeHand(state.bankResources, file: file, line: line)
        var total = state.bankResources
        for player in state.roster {
            let hand = state.resourcesByPlayer[player] ?? .zero
            assertNonNegativeHand(hand, file: file, line: line)
            total = addHands(total, hand)
        }
        XCTAssertEqual(total.wood, 19, file: file, line: line)
        XCTAssertEqual(total.brick, 19, file: file, line: line)
        XCTAssertEqual(total.sheep, 19, file: file, line: line)
        XCTAssertEqual(total.wheat, 19, file: file, line: line)
        XCTAssertEqual(total.ore, 19, file: file, line: line)

        for player in state.roster {
            let roads = state.roadsByEdge.values.filter { $0 == player }.count
            let settlements = state.settlementsByNode.values.filter { $0 == player }.count
            let cities = state.citiesByNode.values.filter { $0 == player }.count
            XCTAssertLessThanOrEqual(roads, 15, file: file, line: line)
            XCTAssertLessThanOrEqual(settlements, 5, file: file, line: line)
            XCTAssertLessThanOrEqual(cities, 4, file: file, line: line)
        }

        for node in state.citiesByNode.keys {
            XCTAssertNil(state.settlementsByNode[node], file: file, line: line)
        }

        let revealedVP = state.revealedVictoryPointsByPlayer.values.reduce(0, +)
        XCTAssertLessThanOrEqual(revealedVP, 5, file: file, line: line)

        let deckKnights = state.devDeck.filter { $0 == .knight }.count
        let handKnights = state.roster.reduce(0) { partial, player in
            let dev = state.devCardsByPlayer[player] ?? .zero
            let new = state.newDevCardsByPlayer[player] ?? .zero
            return partial + dev.knight + new.knight
        }
        let playedKnights = state.roster.reduce(0) { $0 + (state.knightsPlayedByPlayer[$1] ?? 0) }
        XCTAssertEqual(deckKnights + handKnights + playedKnights, 14, file: file, line: line)

        let deckVP = state.devDeck.filter { $0 == .victoryPoint }.count
        let handVP = state.roster.reduce(0) { partial, player in
            let dev = state.devCardsByPlayer[player] ?? .zero
            let new = state.newDevCardsByPlayer[player] ?? .zero
            return partial + dev.victoryPoint + new.victoryPoint
        }
        XCTAssertEqual(deckVP + handVP + revealedVP, 5, file: file, line: line)
    }

    private func assertNonNegativeHand(_ hand: ResourceHandV1, file: StaticString, line: UInt) {
        XCTAssertGreaterThanOrEqual(hand.wood, 0, file: file, line: line)
        XCTAssertGreaterThanOrEqual(hand.brick, 0, file: file, line: line)
        XCTAssertGreaterThanOrEqual(hand.sheep, 0, file: file, line: line)
        XCTAssertGreaterThanOrEqual(hand.wheat, 0, file: file, line: line)
        XCTAssertGreaterThanOrEqual(hand.ore, 0, file: file, line: line)
    }

    private func addHands(_ lhs: ResourceHandV1, _ rhs: ResourceHandV1) -> ResourceHandV1 {
        ResourceHandV1(
            wood: lhs.wood + rhs.wood,
            brick: lhs.brick + rhs.brick,
            sheep: lhs.sheep + rhs.sheep,
            wheat: lhs.wheat + rhs.wheat,
            ore: lhs.ore + rhs.ore
        )
    }

    private func require<T>(_ value: T?, _ message: String) throws -> T {
        guard let value else {
            XCTFail(message)
            throw XCTSkip(message)
        }
        return value
    }

    private func assertTerminalState(
        _ result: MatchResultV1,
        roster: [String],
        expectedWinner: String?
    ) {
        let state = result.finalState
        XCTAssertEqual(state.phase, .gameOver)
        if let expectedWinner {
            XCTAssertEqual(state.winnerPlayer, expectedWinner)
        } else {
            XCTAssertTrue(roster.contains(state.winnerPlayer ?? ""))
        }
        XCTAssertGreaterThanOrEqual(state.winningVictoryPoints, 10)

        let rollActors = Set(
            state.auditLog
                .filter { $0.action == .rollDice }
                .map(\.actor)
        )
        XCTAssertEqual(rollActors, Set(roster))

        for player in roster {
            XCTAssertGreaterThan(result.turnsByPlayer[player, default: 0], 0)
        }
    }

    private func assertActionsObserved(
        _ state: CoreGameStateV1,
        required: [AuditActionV1],
        anyOf: [AuditActionV1]
    ) {
        for action in required {
            XCTAssertGreaterThan(
                actionCount(action, in: state),
                0,
                "Expected action \(action.rawValue) to appear in audit log."
            )
        }
        if !anyOf.isEmpty {
            let observed = anyOf.contains { actionCount($0, in: state) > 0 }
            XCTAssertTrue(observed, "Expected at least one action from \(anyOf.map(\.rawValue)).")
        }
    }

    private func actionCount(_ action: AuditActionV1, in state: CoreGameStateV1) -> Int {
        state.auditLog.reduce(0) { partial, entry in
            partial + (entry.action == action ? 1 : 0)
        }
    }

    private func assertDeterministicReplay(_ lhs: CoreGameStateV1, _ rhs: CoreGameStateV1) {
        XCTAssertEqual(lhs.stateHash, rhs.stateHash)
        XCTAssertEqual(lhs.auditLog, rhs.auditLog)
        XCTAssertEqual(lhs.lastTurnRecap, rhs.lastTurnRecap)
        XCTAssertEqual(lhs.winnerPlayer, rhs.winnerPlayer)
        XCTAssertEqual(lhs.winningVictoryPoints, rhs.winningVictoryPoints)
    }
}
