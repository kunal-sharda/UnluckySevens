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

    func testPortAnchorsStayWithinVisibleBoardFrame() {
        let size = CGSize(width: 320, height: 280)
        let topology = StandardBoardTopologyV1.standard()
        let ports = topology.ports.enumerated().map { index, port in
            GameBoardPortRenderModel(slotIndex: index, edgeID: port.edge, kind: port.kind)
        }
        let layout = GameBoardLayout(
            size: size,
            geometry: StandardBoardTopologyV1.renderGeometry()
        )

        for port in ports {
            let anchor = layout.portAnchor(for: port, topology: topology)
            XCTAssertGreaterThanOrEqual(anchor.x, 14, "Port anchor should stay inside the visible board width.")
            XCTAssertLessThanOrEqual(anchor.x, size.width - 14, "Port anchor should stay inside the visible board width.")
            XCTAssertGreaterThanOrEqual(anchor.y, 14, "Port anchor should stay inside the visible board height.")
            XCTAssertLessThanOrEqual(anchor.y, size.height - 14, "Port anchor should stay inside the visible board height.")
        }
    }

    func testPortAnchorsUseDistinctCanonicalSlots() {
        let topology = StandardBoardTopologyV1.standard()
        let ports = topology.ports.enumerated().map { index, port in
            GameBoardPortRenderModel(slotIndex: index, edgeID: port.edge, kind: port.kind)
        }
        let layout = GameBoardLayout(
            size: CGSize(width: 320, height: 280),
            geometry: StandardBoardTopologyV1.renderGeometry()
        )
        var anchors: [CGPoint] = []

        for port in ports {
            let anchor = layout.portAnchor(for: port, topology: topology)
            anchors.append(anchor)
        }

        for (index, anchor) in anchors.enumerated() where index < anchors.count - 1 {
            for other in anchors[(index + 1)..<anchors.count] {
                XCTAssertGreaterThan(
                    hypot(anchor.x - other.x, anchor.y - other.y),
                    layout.tileRadius * 1.2,
                    "Each harbor should occupy a distinct fixed slot around the island."
                )
            }
        }
    }

    func testPortAnchorsExtendPastTheirCoastalEdge() {
        let topology = StandardBoardTopologyV1.standard()
        let ports = topology.ports.enumerated().map { index, port in
            GameBoardPortRenderModel(slotIndex: index, edgeID: port.edge, kind: port.kind)
        }
        let layout = GameBoardLayout(
            size: CGSize(width: 320, height: 280),
            geometry: StandardBoardTopologyV1.renderGeometry()
        )

        for port in ports {
            let anchor = layout.portAnchor(for: port, topology: topology)
            let midpoint = layout.edgeMidpoint(for: port.edgeID, topology: topology)
            let edgeLength = layout.edgeLength(for: port.edgeID, topology: topology)
            let offset = hypot(anchor.x - midpoint.x, anchor.y - midpoint.y)

            XCTAssertGreaterThan(
                offset,
                edgeLength * 0.45,
                "Port anchor should sit a meaningful distance into the sea beyond its coastal edge."
            )
            XCTAssertLessThan(
                offset,
                edgeLength * 1.15,
                "Port anchor should stay visually tied to its coastal edge instead of floating far away."
            )
        }
    }

    func testPortAnchorsStayCenteredOnTheirOwningCoastalEdge() {
        let topology = StandardBoardTopologyV1.standard()
        let ports = topology.ports.enumerated().map { index, port in
            GameBoardPortRenderModel(slotIndex: index, edgeID: port.edge, kind: port.kind)
        }
        let layout = GameBoardLayout(
            size: CGSize(width: 320, height: 280),
            geometry: StandardBoardTopologyV1.renderGeometry()
        )

        for port in ports {
            let edge = layout.edgeLine(for: port.edgeID, topology: topology)
            let anchor = layout.portAnchor(for: port, topology: topology)
            let startDistance = hypot(anchor.x - edge.start.x, anchor.y - edge.start.y)
            let endDistance = hypot(anchor.x - edge.end.x, anchor.y - edge.end.y)

            XCTAssertEqual(
                startDistance,
                endDistance,
                accuracy: max(layout.tileRadius * 0.08, 1.4),
                "Port anchor should stay on the perpendicular bisector of its owning coastal edge."
            )
        }
    }
}
