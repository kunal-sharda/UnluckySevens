import XCTest
@testable import ULS_CoreGame

final class SetupStateMachineV1Tests: XCTestCase {
    private let topology = StandardBoardTopologyV1.standard()

    func testSnakeOrderForThreePlayers() {
        let order = makeSetupOrder(roster: ["A", "B", "C"])
        XCTAssertEqual(order, ["A", "B", "C", "C", "B", "A"])
    }

    func testSetupSequenceAdvancesStepAndTurnAndFillsSlots() throws {
        var state = makeSetupPhaseState(roster: ["A", "B", "C"])
        let firstRoundActors = ["A", "B", "C"]
        var occupiedNodes = Set<NodeID>()
        var occupiedEdges = Set<EdgeID>()

        for (index, actor) in firstRoundActors.enumerated() {
            let settlement = try firstLegalSettlementNode(occupiedNodes: occupiedNodes)
            state = try apply(intent: .placeSetupSettlement(node: settlement), to: state, actor: actor)

            XCTAssertEqual(state.setupState?.step, .placeRoad)
            XCTAssertEqual(state.setupState?.turnIndex, index)
            XCTAssertEqual(state.currentPlayer, actor)
            occupiedNodes.insert(settlement)

            let road = try firstIncidentEdge(for: settlement, occupiedEdges: occupiedEdges)
            state = try apply(intent: .placeSetupRoad(edge: road), to: state, actor: actor)

            occupiedEdges.insert(road)
            XCTAssertEqual(state.setupState?.step, .placeSettlement)
            XCTAssertEqual(state.setupState?.turnIndex, index + 1)
            XCTAssertEqual(state.setupState?.placements[actor]?.settlement1, settlement)
            XCTAssertEqual(state.setupState?.placements[actor]?.road1, road)
        }

        XCTAssertEqual(state.currentPlayer, "C")
    }

    func testRoadBeforeSettlementThrows() {
        let roster = ["A", "B"]
        let setup = SetupStateV1(
            order: makeSetupOrder(roster: roster),
            turnIndex: 0,
            step: .placeRoad,
            placements: [:],
            lastPlacedSettlementNode: nil
        )
        let state = makeState(
            roster: roster,
            currentPlayer: "A",
            setupState: setup
        )
        guard let validEdge = topology.edges.indices.first else {
            XCTFail("Expected topology with at least one edge.")
            return
        }

        XCTAssertThrowsError(try apply(intent: .placeSetupRoad(edge: validEdge), to: state, actor: "A")) { error in
            XCTAssertEqual(error as? CoreGameError, .roadBeforeSettlement)
        }
    }

    func testSetupCompletionTransitionsToTurnAndResetsCurrentPlayer() throws {
        let roster = ["A", "B"]
        var state = makeSetupPhaseState(roster: roster)
        var occupiedNodes = Set<NodeID>()
        var occupiedEdges = Set<EdgeID>()

        for actor in makeSetupOrder(roster: roster) {
            let settlement = try firstLegalSettlementNode(occupiedNodes: occupiedNodes)
            state = try apply(intent: .placeSetupSettlement(node: settlement), to: state, actor: actor)
            occupiedNodes.insert(settlement)

            let road = try firstIncidentEdge(for: settlement, occupiedEdges: occupiedEdges)
            state = try apply(intent: .placeSetupRoad(edge: road), to: state, actor: actor)
            occupiedEdges.insert(road)
        }

        XCTAssertEqual(state.phase, .turn)
        XCTAssertEqual(state.currentPlayer, "A")
        XCTAssertNil(state.setupState)
    }

    func testDistanceRuleRejectsAdjacentSettlement() throws {
        guard let edgeID = topology.edges.indices.first else {
            XCTFail("Expected topology with at least one edge.")
            return
        }

        let edge = topology.edges[edgeID]
        var state = makeSetupPhaseState(roster: ["A", "B"])
        state = try apply(intent: .placeSetupSettlement(node: edge.a), to: state, actor: "A")
        let incident = try firstIncidentEdge(for: edge.a, occupiedEdges: [])
        state = try apply(intent: .placeSetupRoad(edge: incident), to: state, actor: "A")

        XCTAssertThrowsError(try apply(intent: .placeSetupSettlement(node: edge.b), to: state, actor: "B")) { error in
            XCTAssertEqual(error as? CoreGameError, .distanceRuleViolation)
        }
    }

    func testDistanceRuleAllowsNonAdjacentSettlement() throws {
        guard let edgeID = topology.edges.indices.first else {
            XCTFail("Expected topology with at least one edge.")
            return
        }

        let edge = topology.edges[edgeID]
        var state = makeSetupPhaseState(roster: ["A", "B"])
        state = try apply(intent: .placeSetupSettlement(node: edge.a), to: state, actor: "A")
        let incident = try firstIncidentEdge(for: edge.a, occupiedEdges: [])
        state = try apply(intent: .placeSetupRoad(edge: incident), to: state, actor: "A")

        let candidate = try firstNonAdjacentNode(to: edge.a, occupiedNodes: [edge.a])
        XCTAssertNoThrow(try apply(intent: .placeSetupSettlement(node: candidate), to: state, actor: "B"))
    }

    func testRoadMustTouchLastSettlement() throws {
        var state = makeSetupPhaseState(roster: ["A", "B"])
        let settlement = try firstLegalSettlementNode(occupiedNodes: [])
        state = try apply(intent: .placeSetupSettlement(node: settlement), to: state, actor: "A")
        let nonIncident = try firstNonIncidentEdge(for: settlement, occupiedEdges: [])

        XCTAssertThrowsError(try apply(intent: .placeSetupRoad(edge: nonIncident), to: state, actor: "A")) { error in
            XCTAssertEqual(error as? CoreGameError, .roadNotAdjacentToLastSettlement)
        }
    }

    func testRoadCanBePlacedOnIncidentEdge() throws {
        var state = makeSetupPhaseState(roster: ["A", "B"])
        let settlement = try firstLegalSettlementNode(occupiedNodes: [])
        state = try apply(intent: .placeSetupSettlement(node: settlement), to: state, actor: "A")
        let incident = try firstIncidentEdge(for: settlement, occupiedEdges: [])

        XCTAssertNoThrow(try apply(intent: .placeSetupRoad(edge: incident), to: state, actor: "A"))
    }

    func testNodeOccupiedThrows() {
        guard let edgeID = topology.edges.indices.first else {
            XCTFail("Expected topology with at least one edge.")
            return
        }

        let occupiedNode = topology.edges[edgeID].a
        let setup = SetupStateV1(
            order: makeSetupOrder(roster: ["A", "B"]),
            turnIndex: 1,
            step: .placeSettlement,
            placements: ["A": PlayerSetupPlacementsV1(settlement1: occupiedNode)],
            lastPlacedSettlementNode: nil
        )
        let state = makeState(
            roster: ["A", "B"],
            currentPlayer: "B",
            setupState: setup
        )

        XCTAssertThrowsError(try apply(intent: .placeSetupSettlement(node: occupiedNode), to: state, actor: "B")) { error in
            XCTAssertEqual(error as? CoreGameError, .nodeOccupied)
        }
    }

    func testEdgeOccupiedThrows() {
        guard let edgeID = topology.edges.indices.first else {
            XCTFail("Expected topology with at least one edge.")
            return
        }

        let edge = topology.edges[edgeID]
        let setup = SetupStateV1(
            order: makeSetupOrder(roster: ["A", "B"]),
            turnIndex: 1,
            step: .placeRoad,
            placements: [
                "A": PlayerSetupPlacementsV1(road1: edgeID),
                "B": PlayerSetupPlacementsV1(settlement1: edge.a),
            ],
            lastPlacedSettlementNode: edge.a
        )
        let state = makeState(
            roster: ["A", "B"],
            currentPlayer: "B",
            setupState: setup
        )

        XCTAssertThrowsError(try apply(intent: .placeSetupRoad(edge: edgeID), to: state, actor: "B")) { error in
            XCTAssertEqual(error as? CoreGameError, .edgeOccupied)
        }
    }

    private func makeSetupPhaseState(roster: [String]) -> CoreGameStateV1 {
        let setup = initializeSetupState(roster: roster)
        return makeState(
            roster: roster,
            currentPlayer: setup.order[0],
            setupState: setup
        )
    }

    private func makeState(
        roster: [String],
        currentPlayer: String,
        setupState: SetupStateV1
    ) -> CoreGameStateV1 {
        CoreGameStateV1(
            gameId: "game-setup",
            rev: 1,
            prevHash: "hash-0",
            stateHash: "",
            roster: roster,
            currentPlayer: currentPlayer,
            phase: .setup,
            seed: 1,
            diceRngState: 2,
            boardRules: nil,
            board: nil,
            setupState: setupState
        ).rehashed()
    }

    private func firstLegalSettlementNode(occupiedNodes: Set<NodeID>) throws -> NodeID {
        for node in 0..<topology.nodesCount {
            if occupiedNodes.contains(node) {
                continue
            }

            let adjacent = Set(topology.nodes(adjacentTo: node))
            if adjacent.isDisjoint(with: occupiedNodes) {
                return node
            }
        }

        throw XCTSkip("No legal settlement node available for this test state.")
    }

    private func firstIncidentEdge(for node: NodeID, occupiedEdges: Set<EdgeID>) throws -> EdgeID {
        for edgeID in topology.edges(incidentTo: node) where !occupiedEdges.contains(edgeID) {
            return edgeID
        }

        throw XCTSkip("No legal incident edge available for node \(node).")
    }

    private func firstNonIncidentEdge(for node: NodeID, occupiedEdges: Set<EdgeID>) throws -> EdgeID {
        for edgeID in topology.edges.indices where !occupiedEdges.contains(edgeID) {
            let edge = topology.edges[edgeID]
            if edge.a != node && edge.b != node {
                return edgeID
            }
        }

        throw XCTSkip("No non-incident edge available for node \(node).")
    }

    private func firstNonAdjacentNode(to node: NodeID, occupiedNodes: Set<NodeID>) throws -> NodeID {
        let adjacent = Set(topology.nodes(adjacentTo: node))
        for candidate in 0..<topology.nodesCount {
            if candidate == node || adjacent.contains(candidate) || occupiedNodes.contains(candidate) {
                continue
            }

            let candidateAdjacent = Set(topology.nodes(adjacentTo: candidate))
            if candidateAdjacent.isDisjoint(with: occupiedNodes) {
                return candidate
            }
        }

        throw XCTSkip("No non-adjacent node available for node \(node).")
    }
}
