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
}
