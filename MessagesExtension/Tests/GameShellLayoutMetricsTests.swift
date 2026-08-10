import XCTest
@testable import MessagesExtension

final class GameShellLayoutMetricsTests: XCTestCase {
    func testPhoneLayoutUsesBoundedMetrics() {
        let metrics = GameShellLayoutMetrics.resolve(
            availableSize: CGSize(width: 390, height: 1000),
            spacing: 0
        )

        XCTAssertEqual(metrics.headerHeight, 70, accuracy: 0.001)
        XCTAssertEqual(metrics.boardHeight, 818, accuracy: 0.001)
        XCTAssertEqual(metrics.trayHeight, 112, accuracy: 0.001)
        XCTAssertEqual(metrics.expandedTrayHeight, 214, accuracy: 0.001)
        XCTAssertEqual(metrics.lowerRail.handleBandHeight, 24, accuracy: 0.001)
        XCTAssertEqual(metrics.lowerRail.dockHeight, 88, accuracy: 0.001)
        XCTAssertEqual(metrics.overlayShelf.totalHeight, 170, accuracy: 0.001)
        XCTAssertEqual(metrics.overlayShelf.visibleInLowerRailHeight, 24, accuracy: 0.001)
        XCTAssertEqual(metrics.overlayShelf.overlapIntoBoardHeight, 146, accuracy: 0.001)
    }

    func testPadLayoutUsesExpandedBoundedMetrics() {
        let metrics = GameShellLayoutMetrics.resolve(
            availableSize: CGSize(width: 834, height: 1000),
            spacing: 0
        )

        XCTAssertEqual(metrics.headerHeight, 90, accuracy: 0.001)
        XCTAssertEqual(metrics.boardHeight, 792, accuracy: 0.001)
        XCTAssertEqual(metrics.trayHeight, 118, accuracy: 0.001)
        XCTAssertEqual(metrics.expandedTrayHeight, 160, accuracy: 0.001)
        XCTAssertEqual(metrics.lowerRail.handleBandHeight, 52, accuracy: 0.001)
        XCTAssertEqual(metrics.lowerRail.dockHeight, 66, accuracy: 0.001)
        XCTAssertEqual(metrics.overlayShelf.totalHeight, 180, accuracy: 0.001)
        XCTAssertEqual(metrics.overlayShelf.visibleInLowerRailHeight, 52, accuracy: 0.001)
        XCTAssertEqual(metrics.overlayShelf.headerHeight, 44, accuracy: 0.001)
        XCTAssertEqual(metrics.overlayShelf.contentHeight, 136, accuracy: 0.001)
        XCTAssertEqual(metrics.overlayShelf.overlapIntoBoardHeight, 128, accuracy: 0.001)
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

        XCTAssertEqual(metrics.headerHeight, 42, accuracy: 0.001)
        XCTAssertEqual(metrics.trayHeight, 92, accuracy: 0.001)
        XCTAssertEqual(metrics.expandedTrayHeight, 132, accuracy: 0.001)
        XCTAssertEqual(metrics.lowerRail.handleBandHeight, 24, accuracy: 0.001)
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

    func testFeltOverlayFitsEntirelyWithinToolSurface() {
        let metrics = GameShellLayoutMetrics.resolve(
            availableSize: CGSize(width: 390, height: 760),
            spacing: 16,
            overlayKind: .build
        )
        let surfaceHeight = GameShellLayoutMetrics.normalTurnActionWellHeight(for: 390)
        let fitted = metrics.overlayShelf.fittedToTabletopSurface(height: surfaceHeight)

        XCTAssertEqual(fitted.totalHeight, 184, accuracy: 0.001)
        XCTAssertEqual(fitted.headerHeight, 34, accuracy: 0.001)
        XCTAssertEqual(fitted.contentHeight, 149, accuracy: 0.001)
        XCTAssertEqual(fitted.overlapIntoBoardHeight, 0, accuracy: 0.001)
    }

    func testTurnActionWellUsesStablePhoneAndPadHeights() {
        XCTAssertEqual(GameShellLayoutMetrics.normalTurnActionWellHeight(for: 390), 184)
        XCTAssertEqual(GameShellLayoutMetrics.normalTurnActionWellHeight(for: 834), 220)
    }

    func testPhysicalPropsLayoutUsesClampedResponsiveZones() {
        let compact = GamePhysicalTurnLayout.resolve(
            availableSize: CGSize(width: 375, height: 667)
        )
        let tall = GamePhysicalTurnLayout.resolve(
            availableSize: CGSize(width: 430, height: 932)
        )

        XCTAssertEqual(GamePhysicalTurnLayout.topBarHeight, 40)
        XCTAssertEqual(compact.hostProfile, .narrow)
        XCTAssertEqual(tall.hostProfile, .narrow)
        XCTAssertEqual(compact.contentScale, 1, accuracy: 0.001)
        XCTAssertEqual(compact.publicRailHeight, 52, accuracy: 0.001)
        XCTAssertEqual(compact.actionSpreadHeight, 72, accuracy: 0.001)
        XCTAssertEqual(compact.propRailHeight, 56, accuracy: 0.001)
        XCTAssertEqual(compact.interZoneSpacing, 12, accuracy: 0.001)
        XCTAssertEqual(compact.boardHorizontalOverflow, 9.375, accuracy: 0.001)
        XCTAssertEqual(compact.boardFrameHorizontalMaskInset, 9.375, accuracy: 0.001)
        XCTAssertEqual(compact.boardFrameVerticalInset, 4, accuracy: 0.001)
        XCTAssertEqual(compact.boardFrameVerticalOffset, 4, accuracy: 0.001)

        XCTAssertEqual(tall.publicRailHeight, 56, accuracy: 0.001)
        XCTAssertEqual(tall.actionSpreadHeight, 76, accuracy: 0.001)
        XCTAssertEqual(tall.propRailHeight, 62, accuracy: 0.001)
        XCTAssertEqual(tall.interZoneSpacing, 14, accuracy: 0.001)
        XCTAssertEqual(tall.boardHorizontalOverflow, 10.75, accuracy: 0.001)
        XCTAssertEqual(tall.boardFrameHorizontalMaskInset, 10.75, accuracy: 0.001)
        XCTAssertEqual(GamePhysicalTurnLayout.publicObjectGap, 28, accuracy: 0.001)
        XCTAssertEqual(GamePhysicalTurnLayout.publicLabelGap, 8, accuracy: 0.001)
        XCTAssertEqual(GamePhysicalTurnLayout.publicBankCardGap, 2, accuracy: 0.001)
        XCTAssertEqual(
            GamePhysicalTurnLayout.portraitCardSize,
            CGSize(width: 38, height: 47)
        )
    }

    func testHostProfilesResolveFromContainerRatherThanDeviceIdentity() {
        XCTAssertEqual(
            MessagesHostLayoutProfile.resolve(
                availableSize: CGSize(width: 320, height: 568)
            ),
            .narrow
        )
        XCTAssertEqual(
            MessagesHostLayoutProfile.resolve(
                availableSize: CGSize(width: 430, height: 932)
            ),
            .narrow
        )
        XCTAssertEqual(
            MessagesHostLayoutProfile.resolve(
                availableSize: CGSize(width: 540, height: 980)
            ),
            .narrow
        )
        XCTAssertEqual(
            MessagesHostLayoutProfile.resolve(
                availableSize: CGSize(width: 660, height: 980)
            ),
            .standard
        )
        XCTAssertEqual(
            MessagesHostLayoutProfile.resolve(
                availableSize: CGSize(width: 834, height: 500)
            ),
            .wideShort
        )
        XCTAssertEqual(
            MessagesHostLayoutProfile.resolve(
                availableSize: CGSize(width: 834, height: 1000)
            ),
            .wide
        )
    }

    func testPhysicalPropsScaleObjectsWithoutScalingWholeShell() {
        let narrow = GamePhysicalTurnLayout.resolve(
            availableSize: CGSize(width: 540, height: 980)
        )
        let standard = GamePhysicalTurnLayout.resolve(
            availableSize: CGSize(width: 660, height: 980)
        )
        let wide = GamePhysicalTurnLayout.resolve(
            availableSize: CGSize(width: 834, height: 1000)
        )

        XCTAssertEqual(narrow.contentScale, 1, accuracy: 0.001)
        XCTAssertEqual(standard.contentScale, 1.08, accuracy: 0.001)
        XCTAssertEqual(wide.contentScale, 1.14, accuracy: 0.001)
        XCTAssertGreaterThan(standard.publicRailHeight, narrow.publicRailHeight)
        XCTAssertGreaterThan(wide.actionSpreadHeight, standard.actionSpreadHeight)
        XCTAssertGreaterThan(wide.propRailHeight, standard.propRailHeight)
    }

    func testPhysicalPropsCorrectsMeasuredIslandToDisplayMidpoint() {
        let layout = GamePhysicalTurnLayout.resolve(
            availableSize: CGSize(width: 430, height: 932)
        )
        let displayFrame = CGRect(x: 0, y: 14, width: 430, height: 932)
        let boardFrame = CGRect(x: 0, y: 144, width: 430, height: 520)
        let correction = layout.boardCenteringCorrection(
            boardGlobalFrame: boardFrame,
            displayGlobalFrame: displayFrame
        )

        let centeredIsland = boardFrame.minY
            + (boardFrame.height * GamePhysicalTurnLayout.canonicalIslandCenterYFraction)
            + correction
        XCTAssertEqual(
            centeredIsland,
            displayFrame.midY,
            accuracy: 1.0 / 3.0
        )
    }
}
