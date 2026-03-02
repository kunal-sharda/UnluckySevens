import XCTest
@testable import ULS_CoreGame

final class SetupStartingResourcesV1Tests: XCTestCase {
    private let topology = StandardBoardTopologyV1.standard()

    func testStartingResourcesGrantedAfterSecondRoadPlacement() throws {
        let roster = ["A", "B"]
        let boardRules = BoardRulesV1(strategy: .randomV1)
        let boardSeed = SeedDeriver(masterSeed: 0x0123456789ABCDEF).seed(for: .board)
        let board = StandardBoardGeneratorV1.generate(boardSeed: boardSeed, rules: boardRules, topology: topology)

        var state = CoreGameStateV1(
            gameId: "game-starting-resources",
            rev: 1,
            prevHash: "hash-0",
            stateHash: "",
            roster: roster,
            currentPlayer: "A",
            phase: .setup,
            seed: 0x0123456789ABCDEF,
            diceRngState: 123,
            resourcesByPlayer: [
                "A": .zero,
                "B": .zero,
            ],
            boardRules: boardRules,
            board: board,
            setupState: initializeSetupState(roster: roster)
        ).rehashed()

        let (aSettlement1, aRoad1) = try firstLegalPair(in: state)
        state = try apply(intent: .placeSetupPair(settlementNode: aSettlement1, roadEdge: aRoad1), to: state, actor: "A")

        let (bSettlement1, bRoad1) = try firstLegalPair(in: state)
        state = try apply(intent: .placeSetupPair(settlementNode: bSettlement1, roadEdge: bRoad1), to: state, actor: "B")
        XCTAssertEqual(state.resourcesByPlayer["A"], .zero)
        XCTAssertEqual(state.resourcesByPlayer["B"], .zero)

        let (bSettlement2, bRoad2) = try firstLegalPair(in: state)
        state = try apply(intent: .placeSetupPair(settlementNode: bSettlement2, roadEdge: bRoad2), to: state, actor: "B")

        let placementsB = try XCTUnwrap(state.setupState?.placements["B"])
        XCTAssertEqual(placementsB.settlement2, bSettlement2)
        XCTAssertEqual(placementsB.road2, bRoad2)

        let expectedB = expectedStartingResources(settlementNode: bSettlement2, board: board)
        XCTAssertEqual(state.resourcesByPlayer["B"], expectedB)
        XCTAssertEqual(state.resourcesByPlayer["A"], .zero)
    }

    func testStartingResourcesGrantedAfterSecondRoadPlacement_twoStepFlow() throws {
        let roster = ["A", "B"]
        let boardRules = BoardRulesV1(strategy: .randomV1)
        let boardSeed = SeedDeriver(masterSeed: 0x0123456789ABCDEF).seed(for: .board)
        let board = StandardBoardGeneratorV1.generate(boardSeed: boardSeed, rules: boardRules, topology: topology)

        var state = CoreGameStateV1(
            gameId: "game-starting-resources-two-step",
            rev: 1,
            prevHash: "hash-0",
            stateHash: "",
            roster: roster,
            currentPlayer: "A",
            phase: .setup,
            seed: 0x0123456789ABCDEF,
            diceRngState: 123,
            resourcesByPlayer: [
                "A": .zero,
                "B": .zero,
            ],
            boardRules: boardRules,
            board: board,
            setupState: initializeSetupState(roster: roster)
        ).rehashed()

        let (aSettlement1, aRoad1) = try firstLegalPair(in: state)
        state = try apply(intent: .placeSetupPair(settlementNode: aSettlement1, roadEdge: aRoad1), to: state, actor: "A")

        let (bSettlement1, bRoad1) = try firstLegalPair(in: state)
        state = try apply(intent: .placeSetupPair(settlementNode: bSettlement1, roadEdge: bRoad1), to: state, actor: "B")

        let (bSettlement2, bRoad2) = try firstLegalPair(in: state)
        state = try apply(intent: .placeSetupSettlement(node: bSettlement2), to: state, actor: "B")
        XCTAssertEqual(state.resourcesByPlayer["B"], .zero)

        state = try apply(intent: .placeSetupRoad(edge: bRoad2), to: state, actor: "B")

        let expectedB = expectedStartingResources(settlementNode: bSettlement2, board: board)
        XCTAssertEqual(state.resourcesByPlayer["B"], expectedB)
        XCTAssertEqual(state.resourcesByPlayer["A"], .zero)
    }

    private func firstLegalPair(in state: CoreGameStateV1) throws -> (NodeID, EdgeID) {
        let occupiedNodes = occupiedSettlementNodes(from: state.setupState?.placements ?? [:])
        let occupiedEdges = occupiedRoadEdges(from: state.setupState?.placements ?? [:])

        for node in 0..<topology.nodesCount {
            if occupiedNodes.contains(node) {
                continue
            }

            let adjacentNodes = Set(topology.nodes(adjacentTo: node))
            if !adjacentNodes.isDisjoint(with: occupiedNodes) {
                continue
            }

            if let edge = topology.edges(incidentTo: node).first(where: { !occupiedEdges.contains($0) }) {
                return (node, edge)
            }
        }

        throw XCTSkip("No legal setup settlement+road pair available for current topology/state.")
    }

    private func expectedStartingResources(settlementNode: NodeID, board: BoardSetupV1) -> ResourceHandV1 {
        var hand = ResourceHandV1.zero
        for tileID in topology.tiles(adjacentToNode: settlementNode) {
            if tileID == board.robberTile {
                continue
            }
            hand = hand.addingOne(for: board.resourcesByTile[tileID])
        }
        return hand
    }

    private func occupiedSettlementNodes(from placements: [String: PlayerSetupPlacementsV1]) -> Set<NodeID> {
        var nodes = Set<NodeID>()
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
        var edges = Set<EdgeID>()
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
}
