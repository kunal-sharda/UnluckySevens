import CoreGraphics
import ULS_CoreGame
import XCTest

final class GameBoardLayoutTests: XCTestCase {
    func testTileRadiusMatchesNearestRenderedCornerDistance() {
        let layout = GameBoardLayout(
            size: CGSize(width: 320, height: 280),
            geometry: StandardBoardTopologyV1.renderGeometry()
        )

        let distances = (0..<layout.geometry.tileCenters.count).compactMap { tileID in
            let center = layout.tileCenter(for: tileID)
            return (0..<layout.geometry.nodePositions.count)
                .map { nodeID in
                    let nodePoint = layout.nodePoint(for: nodeID)
                    return hypot(nodePoint.x - center.x, nodePoint.y - center.y)
                }
                .filter { $0 > 0.001 }
                .min()
        }

        let averageDistance = distances.reduce(0, +) / CGFloat(distances.count)
        XCTAssertEqual(layout.tileRadius, averageDistance, accuracy: 0.5)
    }
}
