import XCTest
@testable import ULS_CoreGame

final class CoreBuildCostConsistencyV1Tests: XCTestCase {
    private let topology = StandardBoardTopologyV1.standard()

    func testEveryBuildCostDrivesQueriesReducerValidationAndBankRepayment() throws {
        for scenario in buildScenarios() {
            let state = makeState(for: scenario.kind, hand: scenario.cost)

            XCTAssertTrue(scenario.hasLegalTarget(state), "Expected a legal target for \(scenario.name) at its exact Core-owned cost.")

            let next = try apply(intent: scenario.intent, to: state, actor: "A")

            XCTAssertEqual(next.resourcesByPlayer["A"], .zero, "Expected \(scenario.name) to deduct its exact Core-owned cost.")
            XCTAssertEqual(next.bankResources, adding(scenario.cost, to: state.bankResources))
            XCTAssertNoThrow(try validateTransition(from: state, to: next, actor: "A"))
        }
    }

    func testEveryBuildCostRejectsEachRequiredResourceWhenOneShort() {
        for scenario in buildScenarios() {
            for resource in requiredResources(in: scenario.cost) {
                let insufficientHand = scenario.cost.subtracting(1, for: resource)
                let state = makeState(for: scenario.kind, hand: insufficientHand)

                XCTAssertFalse(
                    scenario.hasLegalTarget(state),
                    "Expected no legal \(scenario.name) target when one \(resource.rawValue) short."
                )
                XCTAssertThrowsError(try apply(intent: scenario.intent, to: state, actor: "A")) { error in
                    XCTAssertEqual(error as? CoreGameError, .buildInsufficientResources)
                }
            }
        }
    }

    func testDevelopmentCardCostDrivesReducerValidationAndBankRepayment() throws {
        let cost = CoreBuildCostsV1.developmentCard
        let state = makeState(for: .developmentCard, hand: cost)

        let next = try apply(intent: .buyDevCard, to: state, actor: "A")

        XCTAssertEqual(next.resourcesByPlayer["A"], .zero)
        XCTAssertEqual(next.bankResources, adding(cost, to: state.bankResources))
        XCTAssertEqual(next.devDeck, [])
        XCTAssertNoThrow(try validateTransition(from: state, to: next, actor: "A"))
    }

    func testDevelopmentCardCostRejectsEachRequiredResourceWhenOneShort() {
        let cost = CoreBuildCostsV1.developmentCard

        for resource in requiredResources(in: cost) {
            let state = makeState(
                for: .developmentCard,
                hand: cost.subtracting(1, for: resource)
            )

            XCTAssertThrowsError(try apply(intent: .buyDevCard, to: state, actor: "A")) { error in
                XCTAssertEqual(error as? CoreGameError, .devCardPurchaseInsufficientResources)
            }
        }
    }

    private func buildScenarios() -> [BuildScenario] {
        let targets = buildTargets()
        return [
            BuildScenario(
                name: "road",
                kind: .road,
                cost: CoreBuildCostsV1.road,
                intent: .buildRoad(edgeID: targets.road),
                hasLegalTarget: { $0.legalBuildRoadEdges(for: "A").contains(targets.road) }
            ),
            BuildScenario(
                name: "settlement",
                kind: .settlement,
                cost: CoreBuildCostsV1.settlement,
                intent: .buildSettlement(nodeID: targets.settlement),
                hasLegalTarget: { $0.legalBuildSettlementNodes(for: "A").contains(targets.settlement) }
            ),
            BuildScenario(
                name: "city",
                kind: .city,
                cost: CoreBuildCostsV1.city,
                intent: .buildCity(nodeID: targets.city),
                hasLegalTarget: { $0.legalBuildCityNodes(for: "A").contains(targets.city) }
            ),
        ]
    }

    private func makeState(for kind: ConsumerKind, hand: ResourceHandV1) -> CoreGameStateV1 {
        let targets = buildTargets()
        let board = BoardSetupV1(
            resourcesByTile: [.wood] + Array(repeating: .desert, count: topology.tiles.count - 1),
            numbersByTile: [5] + Array(repeating: nil, count: topology.tiles.count - 1),
            portsByIndex: topology.ports.map(\.kind),
            robberTile: topology.tiles.count - 1,
            generator: .randomV1,
            boardHash: ""
        ).rehashed()

        let settlements: [NodeID: String]
        let roads: [EdgeID: String]
        switch kind {
        case .road:
            settlements = [targets.city: "A"]
            roads = [targets.initialRoad: "A"]
        case .settlement:
            settlements = [targets.city: "A"]
            roads = [targets.initialRoad: "A", targets.settlementReachRoad: "A"]
        case .city:
            settlements = [targets.city: "A"]
            roads = [:]
        case .developmentCard:
            settlements = [:]
            roads = [:]
        }

        return CoreGameStateV1(
            gameId: "build-cost-consistency",
            rev: 30,
            prevHash: "hash-29",
            stateHash: "",
            roster: ["A", "B"],
            currentPlayer: "A",
            phase: .turn,
            seed: 123,
            diceRngState: 456,
            robberRngState: 789,
            resourcesByPlayer: ["A": hand, "B": .zero],
            bankResources: .standardBank,
            devDeck: kind == .developmentCard ? [.knight] : [],
            settlementsByNode: settlements,
            citiesByNode: [:],
            roadsByEdge: roads,
            boardRules: BoardRulesV1(strategy: .randomV1),
            board: board,
            setupState: nil,
            turnState: TurnStateV1(step: .afterRoll, lastRoll: DiceRollV1(d1: 3, d2: 4))
        ).rehashed()
    }

    private func buildTargets() -> BuildTargets {
        let homeNode = topology.tiles[0].nodes[0]
        let initialRoad = topology.edges(incidentTo: homeNode)[0]
        let road = topology.edges(incidentTo: homeNode)[1]
        let initialRoadEdge = topology.edges[initialRoad]
        let intermediateNode = initialRoadEdge.a == homeNode ? initialRoadEdge.b : initialRoadEdge.a
        let settlementReachRoad = topology.edges(incidentTo: intermediateNode).first { edgeID in
            guard edgeID != initialRoad else { return false }
            let edge = topology.edges[edgeID]
            let farNode = edge.a == intermediateNode ? edge.b : edge.a
            return farNode != homeNode && !topology.nodes(adjacentTo: homeNode).contains(farNode)
        }!
        let reachEdge = topology.edges[settlementReachRoad]
        let settlement = reachEdge.a == intermediateNode ? reachEdge.b : reachEdge.a

        return BuildTargets(
            road: road,
            settlement: settlement,
            city: homeNode,
            initialRoad: initialRoad,
            settlementReachRoad: settlementReachRoad
        )
    }

    private func requiredResources(in cost: ResourceHandV1) -> [ResourceV1] {
        [.wood, .brick, .sheep, .wheat, .ore].filter { cost.count(for: $0) > 0 }
    }

    private func adding(_ cost: ResourceHandV1, to hand: ResourceHandV1) -> ResourceHandV1 {
        ResourceHandV1(
            wood: hand.wood + cost.wood,
            brick: hand.brick + cost.brick,
            sheep: hand.sheep + cost.sheep,
            wheat: hand.wheat + cost.wheat,
            ore: hand.ore + cost.ore
        )
    }
}

private struct BuildScenario {
    let name: String
    let kind: ConsumerKind
    let cost: ResourceHandV1
    let intent: TurnIntentV1
    let hasLegalTarget: (CoreGameStateV1) -> Bool
}

private struct BuildTargets {
    let road: EdgeID
    let settlement: NodeID
    let city: NodeID
    let initialRoad: EdgeID
    let settlementReachRoad: EdgeID
}

private enum ConsumerKind {
    case road
    case settlement
    case city
    case developmentCard
}
