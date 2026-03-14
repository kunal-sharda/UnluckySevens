import XCTest
@testable import ULS_CoreGame

final class BoardRenderGeometryV1Tests: XCTestCase {
    func testStandardRenderGeometryMatchesTopologyCountsAndIsDeterministic() {
        let topology = StandardBoardTopologyV1.standard()
        let geometry = StandardBoardTopologyV1.renderGeometry()

        XCTAssertEqual(geometry.tileCenters.count, topology.tiles.count)
        XCTAssertEqual(geometry.nodePositions.count, topology.nodesCount)
        XCTAssertEqual(Set(geometry.nodePositions).count, topology.nodesCount)
        XCTAssertEqual(geometry, StandardBoardTopologyV1.renderGeometry())
    }

    func testStandardRenderGeometryUsesRegularEdgeLengths() {
        let topology = StandardBoardTopologyV1.standard()
        let geometry = StandardBoardTopologyV1.renderGeometry()

        let edgeLengths = topology.edges.map { edge in
            let a = geometry.nodePositions[edge.a]
            let b = geometry.nodePositions[edge.b]
            return hypot(a.x - b.x, a.y - b.y)
        }

        let minimum = try! XCTUnwrap(edgeLengths.min())
        let maximum = try! XCTUnwrap(edgeLengths.max())

        XCTAssertEqual(minimum, maximum, accuracy: 0.000_000_1)
        XCTAssertEqual(minimum, 1.0, accuracy: 0.000_000_1)
    }
}
