import CoreGraphics

struct GameShellLayoutMetrics: Equatable {
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
        availableHeight: CGFloat,
        spacing: CGFloat
    ) -> GameShellLayoutMetrics {
        let regionCount = 3
        let usableHeight = max(availableHeight - (spacing * CGFloat(regionCount - 1)), 0)

        let headerHeight = usableHeight * 0.12
        let boardHeight = usableHeight * 0.70
        let handleBandHeight = usableHeight * 0.06
        let dockHeight = usableHeight * 0.12
        let overlayHeight = usableHeight * 0.18
        let overlayVisibleInLowerRailHeight = handleBandHeight
        let overlayOverlapIntoBoardHeight = max(overlayHeight - overlayVisibleInLowerRailHeight, 0)
        let overlayHeaderHeight = min(max(overlayHeight * 0.24, 40), 46)
        return GameShellLayoutMetrics(
            headerHeight: headerHeight,
            boardHeight: boardHeight,
            trayHeight: handleBandHeight + dockHeight,
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
}
