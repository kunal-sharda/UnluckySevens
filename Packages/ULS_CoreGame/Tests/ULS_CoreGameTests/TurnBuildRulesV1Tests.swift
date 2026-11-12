import XCTest
@testable import ULS_CoreGame

final class TurnBuildRulesV1Tests: XCTestCase {
    private let topology = StandardBoardTopologyV1.standard()

    func testLegalRoadBuildDeductsCostAndUpdatesOwnership() throws {
        let settlementNode = topology.tiles[0].nodes[0]
        let initialRoad = topology.edges(incidentTo: settlementNode)[0]
        let newRoad = topology.edges(incidentTo: settlementNode)[1]
        let state = makeState(
            resourcesByPlayer: [
                "A": ResourceHandV1(wood: 3, brick: 3),
                "B": .zero,
            ],
            settlementsByNode: [settlementNode: "A"],
            roadsByEdge: [initialRoad: "A"]
        )

        let built = try apply(intent: .buildRoad(edgeID: newRoad), to: state, actor: "A")

        XCTAssertEqual(built.roadsByEdge[newRoad], "A")
        XCTAssertEqual(built.resourcesByPlayer["A"], ResourceHandV1(wood: 2, brick: 2))
        XCTAssertEqual(built.bankResources.wood, state.bankResources.wood + 1)
        XCTAssertEqual(built.bankResources.brick, state.bankResources.brick + 1)
        XCTAssertNoThrow(try validateTransition(from: state, to: built, actor: "A"))
    }

    func testIllegalSettlementDistanceRuleRejectsWithoutMutation() throws {
        let settlementNode = topology.tiles[0].nodes[0]
        let adjacentNode = topology.nodes(adjacentTo: settlementNode)[0]
        let road = topology.edges(incidentTo: settlementNode)[0]
        let state = makeState(
            resourcesByPlayer: [
                "A": ResourceHandV1(wood: 4, brick: 4, sheep: 4, wheat: 4),
                "B": .zero,
            ],
            settlementsByNode: [settlementNode: "A"],
            roadsByEdge: [road: "A"]
        )
        let snapshot = state

        XCTAssertThrowsError(try apply(intent: .buildSettlement(nodeID: adjacentNode), to: state, actor: "A")) { error in
            XCTAssertEqual(error as? CoreGameError, .distanceRuleViolation)
        }
        XCTAssertEqual(state, snapshot)
    }

    func testBuildRoadWithInsufficientResourcesRejectsWithoutMutation() throws {
        let settlementNode = topology.tiles[0].nodes[0]
        let initialRoad = topology.edges(incidentTo: settlementNode)[0]
        let newRoad = topology.edges(incidentTo: settlementNode)[1]
        let state = makeState(
            resourcesByPlayer: [
                "A": ResourceHandV1(wood: 1),
                "B": .zero,
            ],
            settlementsByNode: [settlementNode: "A"],
            roadsByEdge: [initialRoad: "A"]
        )
        let snapshot = state

        XCTAssertThrowsError(try apply(intent: .buildRoad(edgeID: newRoad), to: state, actor: "A")) { error in
            XCTAssertEqual(error as? CoreGameError, .buildInsufficientResources)
        }
        XCTAssertEqual(state, snapshot)
    }

    func testBuildCityDeductsCostAndUpgradesSettlement() throws {
        let settlementNode = topology.tiles[0].nodes[0]
        let state = makeState(
            resourcesByPlayer: [
                "A": ResourceHandV1(wheat: 3, ore: 4),
                "B": .zero,
            ],
            settlementsByNode: [settlementNode: "A"]
        )

        let built = try apply(intent: .buildCity(nodeID: settlementNode), to: state, actor: "A")

        XCTAssertNil(built.settlementsByNode[settlementNode])
        XCTAssertEqual(built.citiesByNode[settlementNode], "A")
        XCTAssertEqual(built.resourcesByPlayer["A"], ResourceHandV1(wheat: 1, ore: 1))
        XCTAssertEqual(built.bankResources.wheat, state.bankResources.wheat + 2)
        XCTAssertEqual(built.bankResources.ore, state.bankResources.ore + 3)
        XCTAssertNoThrow(try validateTransition(from: state, to: built, actor: "A"))
    }

    func testCityUpgradeWithFiveSettlementsBuiltAndOneCity() throws {
        // Four remaining settlements represents five built with one upgraded;
        // five remaining settlements represents a returned piece built again.
        let nodes = separatedNodes(count: 6)
        for settlementCount in [4, 5] {
            let settlements = Dictionary(uniqueKeysWithValues: nodes.prefix(settlementCount).map { ($0, "A") })
            let state = makeState(
                resourcesByPlayer: ["A": ResourceHandV1(wood: 1, brick: 1, sheep: 1, wheat: 3, ore: 3), "B": .zero],
                settlementsByNode: settlements,
                citiesByNode: [nodes[5]: "A"]
            )

            XCTAssertEqual(state.legalBuildCityNodes(for: "A"), settlements.keys.sorted())
            XCTAssertNil(state.purchaseBlocker(for: .city, viewer: "A"))
            if settlementCount == 5 {
                XCTAssertEqual(state.purchaseBlocker(for: .settlement, viewer: "A"), .noPieces)
            }
            let built = try apply(intent: .buildCity(nodeID: nodes[0]), to: state, actor: "A")
            XCTAssertNil(built.settlementsByNode[nodes[0]])
            XCTAssertEqual(built.settlementsByNode.count, settlementCount - 1)
            XCTAssertEqual(built.citiesByNode.count, 2)
            XCTAssertEqual(built.citiesByNode[nodes[0]], "A")
            XCTAssertEqual(built.resourcesByPlayer["A"], ResourceHandV1(wood: 1, brick: 1, sheep: 1, wheat: 1))
            XCTAssertEqual(built.bankResources.wheat, state.bankResources.wheat + 2)
            XCTAssertEqual(built.bankResources.ore, state.bankResources.ore + 3)
            XCTAssertNoThrow(try validateTransition(from: state, to: built, actor: "A"))
        }
    }

    func testCityPieceLimitStillBlocksUpgradeWithSettlementAvailable() {
        let nodes = separatedNodes(count: 5)
        let state = makeState(
            resourcesByPlayer: ["A": CoreBuildCostsV1.city, "B": .zero],
            settlementsByNode: [nodes[0]: "A"],
            citiesByNode: Dictionary(uniqueKeysWithValues: nodes.dropFirst().map { ($0, "A") })
        )
        XCTAssertTrue(state.legalBuildCityNodes(for: "A").isEmpty)
        XCTAssertEqual(state.purchaseBlocker(for: .city, viewer: "A"), .noPieces)
        XCTAssertThrowsError(try apply(intent: .buildCity(nodeID: nodes[0]), to: state, actor: "A")) { error in
            XCTAssertEqual(error as? CoreGameError, .buildPieceLimitReached)
        }
    }

    private func separatedNodes(count: Int) -> [NodeID] {
        var nodes: [NodeID] = []
        for node in 0 ..< topology.nodesCount where nodes.count < count {
            if Set(topology.nodes(adjacentTo: node)).isDisjoint(with: nodes) {
                nodes.append(node)
            }
        }
        XCTAssertEqual(nodes.count, count)
        return nodes
    }

    func testRoadPieceLimitEnforced() {
        var roads: [EdgeID: String] = [:]
        for edge in 0 ..< 15 {
            roads[edge] = "A"
        }
        let state = makeState(
            resourcesByPlayer: [
                "A": ResourceHandV1(wood: 5, brick: 5),
                "B": .zero,
            ],
            settlementsByNode: [topology.tiles[0].nodes[0]: "A"],
            roadsByEdge: roads
        )

        XCTAssertThrowsError(try apply(intent: .buildRoad(edgeID: 15), to: state, actor: "A")) { error in
            XCTAssertEqual(error as? CoreGameError, .buildPieceLimitReached)
        }
    }

    private func makeState(
        resourcesByPlayer: [String: ResourceHandV1],
        settlementsByNode: [NodeID: String],
        roadsByEdge: [EdgeID: String] = [:],
        citiesByNode: [NodeID: String] = [:]
    ) -> CoreGameStateV1 {
        let board = BoardSetupV1(
            resourcesByTile: [.wood] + Array(repeating: .desert, count: 18),
            numbersByTile: [5] + Array(repeating: nil, count: 18),
            portsByIndex: topology.ports.map(\.kind),
            robberTile: 18,
            generator: .randomV1,
            boardHash: ""
        ).rehashed()

        return CoreGameStateV1(
            gameId: "game-build-rules",
            rev: 30,
            prevHash: "hash-29",
            stateHash: "",
            roster: ["A", "B"],
            currentPlayer: "A",
            phase: .turn,
            seed: 123,
            diceRngState: 456,
            robberRngState: 789,
            resourcesByPlayer: resourcesByPlayer,
            bankResources: .standardBank,
            settlementsByNode: settlementsByNode,
            citiesByNode: citiesByNode,
            roadsByEdge: roadsByEdge,
            boardRules: BoardRulesV1(strategy: .randomV1),
            board: board,
            setupState: nil,
            turnState: TurnStateV1(step: .afterRoll, lastRoll: DiceRollV1(d1: 3, d2: 4))
        ).rehashed()
    }
}
