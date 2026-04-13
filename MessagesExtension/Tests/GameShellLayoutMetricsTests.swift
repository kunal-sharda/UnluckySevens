import XCTest
@testable import MessagesExtension

final class GameShellLayoutMetricsTests: XCTestCase {
    func testCollapsedLayoutUsesWholeNumberRatios() {
        let metrics = GameShellLayoutMetrics.resolve(
            availableHeight: 1000,
            spacing: 0
        )

        XCTAssertEqual(metrics.headerHeight, 120, accuracy: 0.001)
        XCTAssertEqual(metrics.boardHeight, 700, accuracy: 0.001)
        XCTAssertEqual(metrics.trayHeight, 180, accuracy: 0.001)
        XCTAssertEqual(metrics.lowerRail.handleBandHeight, 60, accuracy: 0.001)
        XCTAssertEqual(metrics.lowerRail.dockHeight, 120, accuracy: 0.001)
        XCTAssertEqual(metrics.overlayShelf.totalHeight, 180, accuracy: 0.001)
        XCTAssertEqual(metrics.overlayShelf.visibleInLowerRailHeight, 60, accuracy: 0.001)
        XCTAssertEqual(metrics.overlayShelf.overlapIntoBoardHeight, 120, accuracy: 0.001)
    }

    func testOverlayShelfUsesFixedCompactHeader() {
        let metrics = GameShellLayoutMetrics.resolve(
            availableHeight: 1000,
            spacing: 0
        )

        XCTAssertGreaterThanOrEqual(metrics.overlayShelf.headerHeight, 40)
        XCTAssertLessThanOrEqual(metrics.overlayShelf.headerHeight, 46)
        XCTAssertEqual(
            metrics.overlayShelf.contentHeight,
            metrics.overlayShelf.totalHeight - metrics.overlayShelf.headerHeight,
            accuracy: 0.001
        )
    }

    func testLowerRailWidthCapsOnWideLayouts() {
        XCTAssertEqual(GameShellLayoutMetrics.lowerRailWidth(for: 380), 380, accuracy: 0.001)
        XCTAssertEqual(
            GameShellLayoutMetrics.lowerRailWidth(for: 900),
            GameShellLayoutMetrics.maxPadLowerRailWidth,
            accuracy: 0.001
        )
    }

    func testSupportsUtilityShelfRejectsTooShortViewport() {
        XCTAssertFalse(
            GameShellLayoutMetrics.supportsUtilityShelf(
                availableHeight: 400,
                spacing: 16
            )
        )
        XCTAssertTrue(
            GameShellLayoutMetrics.supportsUtilityShelf(
                availableHeight: 700,
                spacing: 16
            )
        )
    }
}
