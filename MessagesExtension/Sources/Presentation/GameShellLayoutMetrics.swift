import CoreGraphics

struct GameShellLayoutMetrics: Equatable {
    static let maxPhoneLowerRailWidth: CGFloat = 420
    static let maxPadLowerRailWidth: CGFloat = 620
    static let padWidthThreshold: CGFloat = 700
    static let minimumUtilityShelfContentHeight: CGFloat = 68
    static let minimumBoardHeightForUtilityShelf: CGFloat = 280
    static let minimumUtilityShelfScrollHeight: CGFloat = 150

    private static let phoneHeaderRatio: CGFloat = 0.11
    private static let padHeaderRatio: CGFloat = 0.095
    private static let phoneDockRatio: CGFloat = 0.18
    private static let padDockRatio: CGFloat = 0.16
    private static let phoneOverlayRatio: CGFloat = 0.22
    private static let padOverlayRatio: CGFloat = 0.29

    private static let phoneHeaderMin: CGFloat = 58
    private static let phoneHeaderMax: CGFloat = 80
    private static let padHeaderMin: CGFloat = 68
    private static let padHeaderMax: CGFloat = 94
    private static let phoneDockMin: CGFloat = 116
    private static let phoneDockMax: CGFloat = 144
    private static let padDockMin: CGFloat = 132
    private static let padDockMax: CGFloat = 174
    private static let phoneHandleMin: CGFloat = 48
    private static let phoneHandleMax: CGFloat = 62
    private static let padHandleMin: CGFloat = 52
    private static let padHandleMax: CGFloat = 72
    private static let phoneOverlayMin: CGFloat = 204
    private static let phoneOverlayMax: CGFloat = 280
    private static let padOverlayMin: CGFloat = 240
    private static let padOverlayMax: CGFloat = 344
    private static let wideCompactOverlayMin: CGFloat = 176
    private static let wideCompactOverlayMax: CGFloat = 232
    private static let phoneOverlayHeaderMin: CGFloat = 40
    private static let phoneOverlayHeaderMax: CGFloat = 46
    private static let padOverlayHeaderMin: CGFloat = 44
    private static let padOverlayHeaderMax: CGFloat = 52

    struct LowerRailMetrics: Equatable {
        let handleBandHeight: CGFloat
        let dockHeight: CGFloat
    }

    struct OverlayShelfMetrics: Equatable {
        let totalHeight: CGFloat
        let visibleInLowerRailHeight: CGFloat
        let overlapIntoBoardHeight: CGFloat
        let headerHeight: CGFloat
        let contentHeight: CGFloat
    }

    let headerHeight: CGFloat
    let boardHeight: CGFloat
    let trayHeight: CGFloat
    let lowerRail: LowerRailMetrics
    let overlayShelf: OverlayShelfMetrics

    static func resolve(
        availableSize: CGSize,
        spacing: CGFloat
    ) -> GameShellLayoutMetrics {
        resolve(
            availableHeight: availableSize.height,
            availableWidth: availableSize.width,
            spacing: spacing
        )
    }

    static func lowerRailWidth(for availableWidth: CGFloat) -> CGFloat {
        let widthCap = availableWidth >= padWidthThreshold
            ? maxPadLowerRailWidth
            : maxPhoneLowerRailWidth
        return min(max(availableWidth, 0), widthCap)
    }

    static func supportsUtilityShelf(
        availableSize: CGSize,
        spacing: CGFloat
    ) -> Bool {
        let metrics = resolve(availableSize: availableSize, spacing: spacing)
        return metrics.boardHeight >= minimumBoardHeightForUtilityShelf
            && metrics.overlayShelf.contentHeight >= minimumUtilityShelfContentHeight
    }

    static func supportsUtilityShelf(
        availableHeight: CGFloat,
        spacing: CGFloat
    ) -> Bool {
        supportsUtilityShelf(
            availableSize: CGSize(width: 0, height: availableHeight),
            spacing: spacing
        )
    }

    static func resolve(
        availableHeight: CGFloat,
        spacing: CGFloat
    ) -> GameShellLayoutMetrics {
        resolve(
            availableHeight: availableHeight,
            availableWidth: 0,
            spacing: spacing
        )
    }

    static func resolve(
        availableHeight: CGFloat,
        availableWidth: CGFloat,
        spacing: CGFloat
    ) -> GameShellLayoutMetrics {
        let regionCount = 3
        let usableHeight = max(availableHeight - (spacing * CGFloat(regionCount - 1)), 0)
        let isWideLayout = availableWidth >= padWidthThreshold
        let usesExpandedVerticalProfile = availableWidth >= padWidthThreshold
            && usableHeight >= (padHeaderMin + padDockMin + minimumBoardHeightForUtilityShelf)

        let headerHeight = boundedHeight(
            usableHeight,
            ratio: usesExpandedVerticalProfile ? padHeaderRatio : phoneHeaderRatio,
            minimum: usesExpandedVerticalProfile ? padHeaderMin : phoneHeaderMin,
            maximum: usesExpandedVerticalProfile ? padHeaderMax : phoneHeaderMax
        )
        let dockRegionHeight = boundedHeight(
            usableHeight,
            ratio: usesExpandedVerticalProfile ? padDockRatio : phoneDockRatio,
            minimum: usesExpandedVerticalProfile ? padDockMin : phoneDockMin,
            maximum: usesExpandedVerticalProfile ? padDockMax : phoneDockMax
        )
        let boardHeight = max(usableHeight - headerHeight - dockRegionHeight, 0)
        let handleBandHeight = boundedHeight(
            dockRegionHeight,
            ratio: usesExpandedVerticalProfile ? 0.34 : 0.33,
            minimum: usesExpandedVerticalProfile ? padHandleMin : phoneHandleMin,
            maximum: usesExpandedVerticalProfile ? padHandleMax : phoneHandleMax
        )
        let dockHeight = max(dockRegionHeight - handleBandHeight, 0)
        let compactOverlayMinimum = isWideLayout
            ? wideCompactOverlayMin
            : phoneOverlayMin
        let compactOverlayMaximum = isWideLayout
            ? wideCompactOverlayMax
            : phoneOverlayMax
        let overlayHeight = boundedHeight(
            usableHeight,
            ratio: usesExpandedVerticalProfile ? padOverlayRatio : phoneOverlayRatio,
            minimum: usesExpandedVerticalProfile ? padOverlayMin : compactOverlayMinimum,
            maximum: usesExpandedVerticalProfile ? padOverlayMax : compactOverlayMaximum
        )
        let overlayVisibleInLowerRailHeight = handleBandHeight
        let overlayOverlapIntoBoardHeight = max(overlayHeight - overlayVisibleInLowerRailHeight, 0)
        let overlayHeaderHeight = boundedHeight(
            overlayHeight,
            ratio: usesExpandedVerticalProfile ? 0.20 : 0.24,
            minimum: usesExpandedVerticalProfile ? padOverlayHeaderMin : phoneOverlayHeaderMin,
            maximum: usesExpandedVerticalProfile ? padOverlayHeaderMax : phoneOverlayHeaderMax
        )
        return GameShellLayoutMetrics(
            headerHeight: headerHeight,
            boardHeight: boardHeight,
            trayHeight: dockRegionHeight,
            lowerRail: LowerRailMetrics(
                handleBandHeight: handleBandHeight,
                dockHeight: dockHeight
            ),
            overlayShelf: OverlayShelfMetrics(
                totalHeight: overlayHeight,
                visibleInLowerRailHeight: overlayVisibleInLowerRailHeight,
                overlapIntoBoardHeight: overlayOverlapIntoBoardHeight,
                headerHeight: overlayHeaderHeight,
                contentHeight: max(overlayHeight - overlayHeaderHeight, 0)
            )
        )
    }

    private static func boundedHeight(
        _ availableHeight: CGFloat,
        ratio: CGFloat,
        minimum: CGFloat,
        maximum: CGFloat
    ) -> CGFloat {
        min(max(availableHeight * ratio, minimum), maximum)
    }
}
