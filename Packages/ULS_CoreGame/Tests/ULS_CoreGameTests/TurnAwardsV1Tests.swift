import XCTest
@testable import ULS_CoreGame

final class TurnAwardsV1Tests: XCTestCase {
    private let topology = StandardBoardTopologyV1.standard()

    func testLargestArmyThresholdAndTransfer() throws {
        let stateForThreshold = makeState(
            currentPlayer: "A",
            resourcesByPlayer: [
                "A": .zero,
                "B": .zero,
            ],
            devCardsByPlayer: [
                "A": DevCardInventoryV1(knight: 1),
                "B": .zero,
            ],
            knightsPlayedByPlayer: [
                "A": 2,
                "B": 1,
            ],
            largestArmyOwner: nil,
            largestArmySize: 0
        )

        let thresholdReached = try apply(intent: .playKnight(tileID: 0, victimPlayer: nil), to: stateForThreshold, actor: "A")
        XCTAssertEqual(thresholdReached.largestArmyOwner, "A")
        XCTAssertEqual(thresholdReached.largestArmySize, 3)
        XCTAssertNoThrow(try validateTransition(from: stateForThreshold, to: thresholdReached, actor: "A"))

        let stateForTransfer = makeState(
            currentPlayer: "B",
            resourcesByPlayer: [
                "A": .zero,
                "B": .zero,
            ],
            devCardsByPlayer: [
                "A": .zero,
                "B": DevCardInventoryV1(knight: 1),
            ],
            knightsPlayedByPlayer: [
                "A": 3,
                "B": 3,
            ],
            largestArmyOwner: "A",
            largestArmySize: 3
        )

        let transferred = try apply(intent: .playKnight(tileID: 0, victimPlayer: nil), to: stateForTransfer, actor: "B")
        XCTAssertEqual(transferred.largestArmyOwner, "B")
        XCTAssertEqual(transferred.largestArmySize, 4)
        XCTAssertNoThrow(try validateTransition(from: stateForTransfer, to: transferred, actor: "B"))
    }

    func testLongestRoadThresholdAndTieRetention() throws {
        let aPath = try XCTUnwrap(findRoadPath(length: 6, avoiding: []))
        let bPath = try XCTUnwrap(findRoadPath(length: 5, avoiding: Set(aPath)))

        let stateForThreshold = makeState(
            currentPlayer: "A",
            resourcesByPlayer: [
                "A": ResourceHandV1(wood: 3, brick: 3),
                "B": .zero,
            ],
            settlementsByNode: [pathStartNode(aPath): "A"],
            roadsByEdge: Dictionary(uniqueKeysWithValues: aPath.prefix(4).map { ($0, "A") })
        )

        let thresholdReached = try apply(intent: .buildRoad(edgeID: aPath[4]), to: stateForThreshold, actor: "A")
        XCTAssertEqual(thresholdReached.longestRoadOwner, "A")
        XCTAssertEqual(thresholdReached.longestRoadLength, 5)
        XCTAssertNoThrow(try validateTransition(from: stateForThreshold, to: thresholdReached, actor: "A"))

        var tieRoads = Dictionary(uniqueKeysWithValues: aPath.prefix(5).map { ($0, "A") })
        for edge in bPath.prefix(4) {
            tieRoads[edge] = "B"
        }
        let stateForTie = makeState(
            currentPlayer: "B",
            resourcesByPlayer: [
                "A": .zero,
                "B": ResourceHandV1(wood: 2, brick: 2),
            ],
            settlementsByNode: [
                pathStartNode(aPath): "A",
                pathStartNode(bPath): "B",
            ],
            roadsByEdge: tieRoads,
            longestRoadOwner: "A",
            longestRoadLength: 5
        )

        let tied = try apply(intent: .buildRoad(edgeID: bPath[4]), to: stateForTie, actor: "B")
        XCTAssertEqual(tied.longestRoadLength, 5)
        XCTAssertEqual(tied.longestRoadOwner, "A")
        XCTAssertNoThrow(try validateTransition(from: stateForTie, to: tied, actor: "B"))
    }

    func testAwardComputationIsDeterministicForSameBuildTransition() throws {
        let path = try XCTUnwrap(findRoadPath(length: 6, avoiding: []))
        let initial = makeState(
            currentPlayer: "A",
            resourcesByPlayer: [
                "A": ResourceHandV1(wood: 2, brick: 2),
                "B": .zero,
            ],
            settlementsByNode: [pathStartNode(path): "A"],
            roadsByEdge: Dictionary(uniqueKeysWithValues: path.prefix(5).map { ($0, "A") }),
            longestRoadOwner: "A",
            longestRoadLength: 5
        )

        let first = try apply(intent: .buildRoad(edgeID: path[5]), to: initial, actor: "A")
        let second = try apply(intent: .buildRoad(edgeID: path[5]), to: initial, actor: "A")

        XCTAssertEqual(first.longestRoadOwner, second.longestRoadOwner)
        XCTAssertEqual(first.longestRoadLength, second.longestRoadLength)
        XCTAssertEqual(first.largestArmyOwner, second.largestArmyOwner)
        XCTAssertEqual(first.largestArmySize, second.largestArmySize)
        XCTAssertEqual(first, second)
    }

    private func makeState(
        currentPlayer: String,
        resourcesByPlayer: [String: ResourceHandV1],
        devCardsByPlayer: [String: DevCardInventoryV1] = [:],
        settlementsByNode: [NodeID: String] = [:],
        roadsByEdge: [EdgeID: String] = [:],
        knightsPlayedByPlayer: [String: Int] = [:],
        largestArmyOwner: String? = nil,
        largestArmySize: Int = 0,
        longestRoadOwner: String? = nil,
        longestRoadLength: Int = 0
    ) -> CoreGameStateV1 {
        let board = BoardSetupV1(
            resourcesByTile: [.wood] + Array(repeating: .desert, count: 18),
            numbersByTile: [5] + Array(repeating: nil, count: 18),
            portsByIndex: topology.ports.map(\.kind),
            robberTile: 1,
            generator: .randomV1,
            boardHash: ""
        ).rehashed()

        return CoreGameStateV1(
            gameId: "game-awards",
            rev: 80,
            prevHash: "hash-79",
            stateHash: "",
            roster: ["A", "B"],
            currentPlayer: currentPlayer,
            phase: .turn,
            seed: 12,
            diceRngState: 34,
            robberRngState: 56,
            resourcesByPlayer: resourcesByPlayer,
            bankResources: .standardBank,
            devDeck: [],
            devCardsByPlayer: devCardsByPlayer,
            newDevCardsByPlayer: [:],
            revealedVictoryPointsByPlayer: [:],
            devCardActionPlayedThisTurn: false,
            knightsPlayedByPlayer: knightsPlayedByPlayer,
            largestArmyOwner: largestArmyOwner,
            largestArmySize: largestArmySize,
            longestRoadOwner: longestRoadOwner,
            longestRoadLength: longestRoadLength,
            settlementsByNode: settlementsByNode,
            citiesByNode: [:],
            roadsByEdge: roadsByEdge,
            boardRules: BoardRulesV1(strategy: .randomV1),
            board: board,
            setupState: nil,
            turnState: TurnStateV1(step: .afterRoll, lastRoll: DiceRollV1(d1: 4, d2: 3))
        ).rehashed()
    }

    private func findRoadPath(length: Int, avoiding forbiddenEdges: Set<EdgeID>) -> [EdgeID]? {
        guard length > 0 else {
            return nil
        }

        let allEdges = Set(topology.edges.indices).subtracting(forbiddenEdges)
        for startEdge in allEdges.sorted() {
            var visited: Set<EdgeID> = [startEdge]
            if let path = dfsRoadPath(
                currentEdge: startEdge,
                remaining: length - 1,
                visited: &visited,
                allowedEdges: allEdges
            ) {
                return [startEdge] + path
            }
        }
        return nil
    }

    private func dfsRoadPath(
        currentEdge: EdgeID,
        remaining: Int,
        visited: inout Set<EdgeID>,
        allowedEdges: Set<EdgeID>
    ) -> [EdgeID]? {
        if remaining == 0 {
            return []
        }

        let edge = topology.edges[currentEdge]
        let incident = Set(topology.edges(incidentTo: edge.a) + topology.edges(incidentTo: edge.b))
            .intersection(allowedEdges)
            .subtracting([currentEdge])
            .sorted()

        for nextEdge in incident where !visited.contains(nextEdge) {
            visited.insert(nextEdge)
            if let tail = dfsRoadPath(
                currentEdge: nextEdge,
                remaining: remaining - 1,
                visited: &visited,
                allowedEdges: allowedEdges
            ) {
                return [nextEdge] + tail
            }
            visited.remove(nextEdge)
        }
        return nil
    }

    private func pathStartNode(_ path: [EdgeID]) -> NodeID {
        guard let firstEdgeID = path.first else {
            return 0
        }
        let first = topology.edges[firstEdgeID]
        guard path.count > 1 else {
            return first.a
        }
        let second = topology.edges[path[1]]
        let sharedNodes = Set([first.a, first.b]).intersection([second.a, second.b])
        if sharedNodes.contains(first.a) {
            return first.b
        }
        return first.a
    }
}
