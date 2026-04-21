import XCTest
@testable import MessagesExtension

final class GameShellLayoutMetricsTests: XCTestCase {
    func testPhoneLayoutUsesBoundedMetrics() {
        let metrics = GameShellLayoutMetrics.resolve(
            availableSize: CGSize(width: 390, height: 1000),
            spacing: 0
        )

        XCTAssertEqual(metrics.headerHeight, 80, accuracy: 0.001)
        XCTAssertEqual(metrics.boardHeight, 776, accuracy: 0.001)
        XCTAssertEqual(metrics.trayHeight, 144, accuracy: 0.001)
        XCTAssertEqual(metrics.lowerRail.handleBandHeight, 48, accuracy: 0.001)
        XCTAssertEqual(metrics.lowerRail.dockHeight, 96, accuracy: 0.001)
        XCTAssertEqual(metrics.overlayShelf.totalHeight, 170, accuracy: 0.001)
        XCTAssertEqual(metrics.overlayShelf.visibleInLowerRailHeight, 48, accuracy: 0.001)
        XCTAssertEqual(metrics.overlayShelf.overlapIntoBoardHeight, 122, accuracy: 0.001)
    }

    func testPadLayoutUsesExpandedBoundedMetrics() {
        let metrics = GameShellLayoutMetrics.resolve(
            availableSize: CGSize(width: 834, height: 1000),
            spacing: 0
        )

        XCTAssertEqual(metrics.headerHeight, 94, accuracy: 0.001)
        XCTAssertEqual(metrics.boardHeight, 746, accuracy: 0.001)
        XCTAssertEqual(metrics.trayHeight, 160, accuracy: 0.001)
        XCTAssertEqual(metrics.lowerRail.handleBandHeight, 54.4, accuracy: 0.001)
        XCTAssertEqual(metrics.lowerRail.dockHeight, 105.6, accuracy: 0.001)
        XCTAssertEqual(metrics.overlayShelf.totalHeight, 180, accuracy: 0.001)
        XCTAssertEqual(metrics.overlayShelf.visibleInLowerRailHeight, 54.4, accuracy: 0.001)
        XCTAssertEqual(metrics.overlayShelf.headerHeight, 44, accuracy: 0.001)
        XCTAssertEqual(metrics.overlayShelf.contentHeight, 136, accuracy: 0.001)
        XCTAssertEqual(metrics.overlayShelf.overlapIntoBoardHeight, 125.6, accuracy: 0.001)
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
                availableSize: CGSize(width: 390, height: 400),
                spacing: 16
            )
        )
        XCTAssertTrue(
            GameShellLayoutMetrics.supportsUtilityShelf(
                availableSize: CGSize(width: 834, height: 700),
                spacing: 16
            )
        )
    }

    func testWideShortViewportFallsBackToCompactVerticalMetrics() {
        let metrics = GameShellLayoutMetrics.resolve(
            availableSize: CGSize(width: 834, height: 500),
            spacing: 16
        )

        XCTAssertEqual(metrics.headerHeight, 58, accuracy: 0.001)
        XCTAssertEqual(metrics.trayHeight, 116, accuracy: 0.001)
        XCTAssertEqual(metrics.lowerRail.handleBandHeight, 48, accuracy: 0.001)
        XCTAssertEqual(metrics.overlayShelf.totalHeight, 148, accuracy: 0.001)
        XCTAssertTrue(
            GameShellLayoutMetrics.supportsUtilityShelf(
                availableSize: CGSize(width: 834, height: 500),
                spacing: 16
            )
        )
    }

    func testDevCardShelfUsesTallerProfileThanUtilityShelf() {
        let utilityMetrics = GameShellLayoutMetrics.resolve(
            availableSize: CGSize(width: 390, height: 760),
            spacing: 16,
            overlayKind: .utility
        )
        let devMetrics = GameShellLayoutMetrics.resolve(
            availableSize: CGSize(width: 390, height: 760),
            spacing: 16,
            overlayKind: .devCards
        )

        XCTAssertGreaterThan(devMetrics.overlayShelf.totalHeight, utilityMetrics.overlayShelf.totalHeight)
        XCTAssertGreaterThan(devMetrics.overlayShelf.contentHeight, utilityMetrics.overlayShelf.contentHeight)
    }
}
