import XCTest
@testable import MessagesExtension

final class GameShellLayoutMetricsTests: XCTestCase {
    func testCollapsedLayoutUsesWholeNumberRatios() {
        let metrics = GameShellLayoutMetrics.resolve(
            availableHeight: 1000,
            spacing: 0,
            isShelfPresented: false
        )

        XCTAssertEqual(metrics.headerHeight, 120, accuracy: 0.001)
        XCTAssertEqual(metrics.boardHeight, 700, accuracy: 0.001)
        XCTAssertEqual(metrics.trayHeight, 180, accuracy: 0.001)
        XCTAssertEqual(metrics.lowerRail.topSectionHeight, 60, accuracy: 0.001)
        XCTAssertEqual(metrics.lowerRail.dockHeight, 120, accuracy: 0.001)
    }

    func testExpandedLayoutUsesWholeNumberRatios() {
        let metrics = GameShellLayoutMetrics.resolve(
            availableHeight: 1000,
            spacing: 0,
            isShelfPresented: true
        )

        XCTAssertEqual(metrics.headerHeight, 100, accuracy: 0.001)
        XCTAssertEqual(metrics.boardHeight, 600, accuracy: 0.001)
        XCTAssertEqual(metrics.trayHeight, 300, accuracy: 0.001)
        XCTAssertEqual(metrics.lowerRail.topSectionHeight, 180, accuracy: 0.001)
        XCTAssertEqual(metrics.lowerRail.dockHeight, 120, accuracy: 0.001)
    }
}
