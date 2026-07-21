import CoreGraphics
import XCTest
@testable import MessagesExtension

final class RobberPieceGeometryTests: XCTestCase {
    func testGeometryUsesRequestedHeightAndCentersArtwork() {
        let paths = RobberPieceGeometry.paths(center: CGPoint(x: 40, y: 60), height: 98)
        let bounds = [paths.head, paths.body, paths.base]
            .map(\.boundingBoxOfPath)
            .reduce(CGRect.null) { $0.union($1) }

        XCTAssertEqual(bounds.height, 98, accuracy: 0.01)
        XCTAssertEqual(bounds.midX, 40, accuracy: 0.01)
        XCTAssertEqual(bounds.midY, 60, accuracy: 0.01)
    }

    func testMaskEyesAndSevenStayInsidePieceBounds() {
        let paths = RobberPieceGeometry.paths(center: .zero, height: 98)
        let pieceBounds = [paths.head, paths.body, paths.base]
            .map(\.boundingBoxOfPath)
            .reduce(CGRect.null) { $0.union($1) }

        XCTAssertTrue(pieceBounds.contains(paths.mask.boundingBoxOfPath))
        XCTAssertTrue(pieceBounds.contains(paths.eyes.boundingBoxOfPath))
        XCTAssertTrue(pieceBounds.contains(paths.seven.boundingBoxOfPath))
        XCTAssertGreaterThan(paths.sevenLineWidth, 0)
    }
}
