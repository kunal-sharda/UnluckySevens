import XCTest
@testable import ULS_CoreGame

final class BoardGraphV1Tests: XCTestCase {
    private let board = StandardBoardTopologyV1.standard()

    func testStandardCountsAreCorrect() {
        XCTAssertEqual(board.tiles.count, 19)
        XCTAssertEqual(board.nodesCount, 54)
        XCTAssertEqual(board.edges.count, 72)
        XCTAssertEqual(board.ports.count, 9)
    }

    func testTileNodeEdgeShapeAndRanges() {
        for tile in board.tiles {
            XCTAssertEqual(tile.nodes.count, 6)
            XCTAssertEqual(tile.edges.count, 6)
            XCTAssertEqual(Set(tile.nodes).count, 6)
            XCTAssertEqual(Set(tile.edges).count, 6)

            for node in tile.nodes {
                XCTAssertTrue((0..<board.nodesCount).contains(node))
            }

            for edge in tile.edges {
                XCTAssertTrue((0..<board.edges.count).contains(edge))
            }
        }
    }

    func testNodeDegreeAtMostThree() {
        for node in 0..<board.nodesCount {
            XCTAssertLessThanOrEqual(board.edges(incidentTo: node).count, 3)
        }
    }

    func testEdgeTileAdjacencyAndPortConstraints() {
        for edgeID in 0..<board.edges.count {
            let adjacentTiles = board.tiles(adjacentToEdge: edgeID)
            XCTAssertTrue(adjacentTiles.count == 1 || adjacentTiles.count == 2)
        }

        let portEdges = board.ports.map(\.edge)
        XCTAssertEqual(Set(portEdges).count, board.ports.count)

        for edge in portEdges {
            XCTAssertTrue(board.isCoastal(edge: edge))
        }
    }

    func testAdjacencyHelperConsistency() {
        for node in 0..<board.nodesCount {
            let incidentEdges = board.edges(incidentTo: node)
            for edgeID in incidentEdges {
                let edge = board.edges[edgeID]
                XCTAssertTrue(edge.a == node || edge.b == node)
            }

            let adjacentNodes = board.nodes(adjacentTo: node)
            for adjacent in adjacentNodes {
                XCTAssertTrue(board.nodes(adjacentTo: adjacent).contains(node))
            }

            let helperTiles = board.tiles(adjacentToNode: node)
            let scannedTiles = board.tiles.enumerated()
                .filter { _, tile in tile.nodes.contains(node) }
                .map(\.offset)
                .sorted()
            XCTAssertEqual(helperTiles, scannedTiles)
        }

        for edgeID in 0..<board.edges.count {
            let helperTiles = board.tiles(adjacentToEdge: edgeID)
            let scannedTiles = board.tiles.enumerated()
                .filter { _, tile in tile.edges.contains(edgeID) }
                .map(\.offset)
                .sorted()
            XCTAssertEqual(helperTiles, scannedTiles)
        }
    }

    func testPortsAreOnCanonicalFrameSlots() {
        let expected = StandardBoardTopologyV1.canonicalFramePortEdgesForStandard()
        let actual = board.ports.map(\.edge)

        XCTAssertEqual(actual, expected)
    }

    func testPortsFollowCanonicalTwoTwoThreePerimeterSpacing() {
        let cycle = StandardBoardTopologyV1.coastalEdgeCycleForStandard()
        let edgeIndices = Dictionary(uniqueKeysWithValues: cycle.enumerated().map { ($1, $0) })
        let actual = board.ports.compactMap { edgeIndices[$0.edge] }

        XCTAssertEqual(actual, [0, 3, 6, 10, 13, 16, 20, 23, 26])

        let wrappedActual = actual + [actual[0] + cycle.count]
        let stepPattern = zip(wrappedActual, wrappedActual.dropFirst()).map { $1 - $0 }
        XCTAssertEqual(stepPattern, [3, 3, 4, 3, 3, 4, 3, 3, 4])
    }

    func testPortKindAtNodeMatchesPortEdges() {
        for port in board.ports {
            let edge = board.edges[port.edge]
            XCTAssertEqual(board.portKind(at: edge.a), port.kind)
            XCTAssertEqual(board.portKind(at: edge.b), port.kind)
        }
    }
}
