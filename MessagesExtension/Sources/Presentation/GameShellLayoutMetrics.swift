import CoreGraphics

struct GameShellLayoutMetrics: Equatable {
    static let maxPhoneLowerRailWidth: CGFloat = 420
    static let maxPadLowerRailWidth: CGFloat = 620
    static let padWidthThreshold: CGFloat = 700
    static let minimumUtilityShelfContentHeight: CGFloat = 68
    static let minimumBoardHeightForUtilityShelf: CGFloat = 280
    static let minimumUtilityShelfScrollHeight: CGFloat = 150

    private static let phoneHeaderRatio: CGFloat = 0.08
    private static let padHeaderRatio: CGFloat = 0.095
    private static let phoneDockRatio: CGFloat = 0.27
    private static let padDockRatio: CGFloat = 0.16
    private static let phoneHeaderMin: CGFloat = 44
    private static let phoneHeaderMax: CGFloat = 58
    private static let padHeaderMin: CGFloat = 68
    private static let padHeaderMax: CGFloat = 94
    private static let phoneDockMin: CGFloat = 168
    private static let phoneDockMax: CGFloat = 218
    private static let padDockMin: CGFloat = 132
    private static let padDockMax: CGFloat = 174
    private static let phoneHandleMin: CGFloat = 22
    private static let phoneHandleMax: CGFloat = 28
    private static let padHandleMin: CGFloat = 52
    private static let padHandleMax: CGFloat = 72
    private static let phoneOverlayHeaderMin: CGFloat = 40
    private static let phoneOverlayHeaderMax: CGFloat = 46
    private static let padOverlayHeaderMin: CGFloat = 44
    private static let padOverlayHeaderMax: CGFloat = 52

    enum OverlayShelfKind: Equatable {
        case utility
        case build
        case devCards
        case forcedFlow
    }

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
        spacing: CGFloat,
        overlayKind: OverlayShelfKind = .utility
    ) -> GameShellLayoutMetrics {
        resolve(
            availableHeight: availableSize.height,
            availableWidth: availableSize.width,
            spacing: spacing,
            overlayKind: overlayKind
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
        let metrics = resolve(
            availableSize: availableSize,
            spacing: spacing,
            overlayKind: .utility
        )
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
        spacing: CGFloat,
        overlayKind: OverlayShelfKind = .utility
    ) -> GameShellLayoutMetrics {
        resolve(
            availableHeight: availableHeight,
            availableWidth: 0,
            spacing: spacing,
            overlayKind: overlayKind
        )
    }

    static func resolve(
        availableHeight: CGFloat,
        availableWidth: CGFloat,
        spacing: CGFloat,
        overlayKind: OverlayShelfKind = .utility
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
        let overlayProfile = overlayProfile(
            for: overlayKind,
            isWideLayout: isWideLayout,
            usesExpandedVerticalProfile: usesExpandedVerticalProfile
        )
        let overlayHeight = boundedHeight(
            usableHeight,
            ratio: overlayProfile.ratio,
            minimum: overlayProfile.minimum,
            maximum: overlayProfile.maximum
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

    private struct OverlayShelfProfile {
        let ratio: CGFloat
        let minimum: CGFloat
        let maximum: CGFloat
    }

    private static func overlayProfile(
        for kind: OverlayShelfKind,
        isWideLayout: Bool,
        usesExpandedVerticalProfile: Bool
    ) -> OverlayShelfProfile {
        if usesExpandedVerticalProfile {
            switch kind {
            case .utility:
                return OverlayShelfProfile(ratio: 0.18, minimum: 172, maximum: 220)
            case .build:
                return OverlayShelfProfile(ratio: 0.21, minimum: 198, maximum: 252)
            case .devCards:
                return OverlayShelfProfile(ratio: 0.25, minimum: 236, maximum: 320)
            case .forcedFlow:
                return OverlayShelfProfile(ratio: 0.29, minimum: 240, maximum: 344)
            }
        }

        if isWideLayout {
            switch kind {
            case .utility:
                return OverlayShelfProfile(ratio: 0.17, minimum: 148, maximum: 188)
            case .build:
                return OverlayShelfProfile(ratio: 0.18, minimum: 160, maximum: 208)
            case .devCards:
                return OverlayShelfProfile(ratio: 0.21, minimum: 188, maximum: 248)
            case .forcedFlow:
                return OverlayShelfProfile(ratio: 0.22, minimum: 176, maximum: 232)
            }
        }

        switch kind {
        case .utility:
            return OverlayShelfProfile(ratio: 0.17, minimum: 156, maximum: 208)
        case .build:
            return OverlayShelfProfile(ratio: 0.18, minimum: 168, maximum: 224)
        case .devCards:
            return OverlayShelfProfile(ratio: 0.24, minimum: 212, maximum: 296)
        case .forcedFlow:
            return OverlayShelfProfile(ratio: 0.22, minimum: 204, maximum: 280)
        }
    }
}
