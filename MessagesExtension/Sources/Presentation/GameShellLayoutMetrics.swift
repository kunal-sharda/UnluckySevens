import CoreGraphics

struct GamePhysicalTurnLayout: Equatable {
    static let topBarHeight: CGFloat = 40
    static let portraitCardSize = CGSize(width: 38, height: 47)
    static let handCardSize = CGSize(width: 46, height: 57)
    static let centeredHandOffset: CGFloat = 8
    static let propStageHeight: CGFloat = 36
    static let propVisualHeight: CGFloat = 32
    static let propLabelGap: CGFloat = 3
    static let publicObjectGap: CGFloat = 28
    static let publicLabelGap: CGFloat = 8
    static let publicBankCardGap: CGFloat = 2

    // The authored port ring sits just above the SpriteKit host's geometric
    // midpoint. This renderer-owned ratio remains stable as the host scales.
    private static let canonicalIslandCenterYFraction: CGFloat = 0.494

    let publicRailHeight: CGFloat
    let actionSpreadHeight: CGFloat
    let propRailHeight: CGFloat
    let interZoneSpacing: CGFloat
    let boardHorizontalOverflow: CGFloat
    let boardFrameHorizontalMaskInset: CGFloat
    let boardFrameVerticalInset: CGFloat
    let boardFrameVerticalOffset: CGFloat
    let bottomRailPadding: CGFloat

    static func resolve(availableSize: CGSize) -> Self {
        let height = max(availableSize.height, 0)
        return Self(
            publicRailHeight: bounded(height * 0.066, minimum: 52, maximum: 56),
            actionSpreadHeight: bounded(height * 0.092, minimum: 72, maximum: 76),
            propRailHeight: bounded(height * 0.070, minimum: 56, maximum: 62),
            interZoneSpacing: bounded(height * 0.017, minimum: 12, maximum: 14),
            boardHorizontalOverflow: bounded(availableSize.width * 0.025, minimum: 8, maximum: 12),
            boardFrameHorizontalMaskInset: bounded(
                availableSize.width * 0.025,
                minimum: 8,
                maximum: 12
            ),
            boardFrameVerticalInset: 4,
            boardFrameVerticalOffset: 4,
            bottomRailPadding: 0
        )
    }

    func boardCenteringCorrection(
        boardGlobalFrame: CGRect,
        displayHeight: CGFloat
    ) -> CGFloat {
        guard boardGlobalFrame.height > 0, displayHeight > 0 else { return 0 }
        let renderedIslandCenter = boardGlobalFrame.minY
            + (boardGlobalFrame.height * Self.canonicalIslandCenterYFraction)
        return (displayHeight / 2) - renderedIslandCenter
    }

    private static func bounded(
        _ value: CGFloat,
        minimum: CGFloat,
        maximum: CGFloat
    ) -> CGFloat {
        min(max(value, minimum), maximum)
    }
}

struct GameShellLayoutMetrics: Equatable {
    static let maxPhoneLowerRailWidth: CGFloat = 420
    static let maxPadLowerRailWidth: CGFloat = 620
    static let padWidthThreshold: CGFloat = 700
    static let minimumUtilityShelfContentHeight: CGFloat = 68
    static let minimumBoardHeightForUtilityShelf: CGFloat = 280
    static let minimumUtilityShelfScrollHeight: CGFloat = 150
    static let phoneNormalTurnActionWellHeight: CGFloat = 184
    static let padNormalTurnActionWellHeight: CGFloat = 220

    private static let phoneHeaderRatio: CGFloat = 0.083
    private static let padHeaderRatio: CGFloat = 0.090
    private static let phoneDockRatio: CGFloat = 0.255
    private static let padDockRatio: CGFloat = 0.16
    private static let phoneCollapsedTrayRatio: CGFloat = 0.112
    private static let padCollapsedTrayRatio: CGFloat = 0.118
    private static let phoneHeaderMin: CGFloat = 58
    private static let phoneHeaderMax: CGFloat = 70
    private static let padHeaderMin: CGFloat = 68
    private static let padHeaderMax: CGFloat = 94
    private static let phoneDockMin: CGFloat = 150
    private static let phoneDockMax: CGFloat = 214
    private static let padDockMin: CGFloat = 132
    private static let padDockMax: CGFloat = 174
    private static let phoneCollapsedTrayMin: CGFloat = 92
    private static let phoneCollapsedTrayMax: CGFloat = 118
    private static let padCollapsedTrayMin: CGFloat = 104
    private static let padCollapsedTrayMax: CGFloat = 132
    private static let phoneHandleMin: CGFloat = 20
    private static let phoneHandleMax: CGFloat = 24
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

        func fittedToTabletopSurface(height: CGFloat) -> Self {
            let resolvedHeight = max(height, 0)
            let resolvedHeaderHeight = min(
                min(max(resolvedHeight * 0.32, 28), 34),
                resolvedHeight
            )

            return Self(
                totalHeight: resolvedHeight,
                visibleInLowerRailHeight: resolvedHeight,
                overlapIntoBoardHeight: 0,
                headerHeight: resolvedHeaderHeight,
                contentHeight: max(resolvedHeight - resolvedHeaderHeight - 1, 0)
            )
        }
    }

    let headerHeight: CGFloat
    let boardHeight: CGFloat
    let trayHeight: CGFloat
    let expandedTrayHeight: CGFloat
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

    static func normalTurnActionWellHeight(for availableWidth: CGFloat) -> CGFloat {
        availableWidth >= padWidthThreshold
            ? padNormalTurnActionWellHeight
            : phoneNormalTurnActionWellHeight
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
        let compactHeaderMin = isWideLayout ? 42 : phoneHeaderMin
        let compactDockMin = isWideLayout ? 132 : phoneDockMin

        let headerHeight = boundedHeight(
            usableHeight,
            ratio: usesExpandedVerticalProfile ? padHeaderRatio : phoneHeaderRatio,
            minimum: usesExpandedVerticalProfile ? padHeaderMin : compactHeaderMin,
            maximum: usesExpandedVerticalProfile ? padHeaderMax : phoneHeaderMax
        )
        let expandedTrayHeight = boundedHeight(
            usableHeight,
            ratio: usesExpandedVerticalProfile ? padDockRatio : phoneDockRatio,
            minimum: usesExpandedVerticalProfile ? padDockMin : compactDockMin,
            maximum: usesExpandedVerticalProfile ? padDockMax : phoneDockMax
        )
        let collapsedTrayHeight = boundedHeight(
            usableHeight,
            ratio: usesExpandedVerticalProfile ? padCollapsedTrayRatio : phoneCollapsedTrayRatio,
            minimum: usesExpandedVerticalProfile ? padCollapsedTrayMin : phoneCollapsedTrayMin,
            maximum: usesExpandedVerticalProfile ? padCollapsedTrayMax : phoneCollapsedTrayMax
        )
        let boardHeight = max(usableHeight - headerHeight - collapsedTrayHeight, 0)
        let handleBandHeight = boundedHeight(
            collapsedTrayHeight,
            ratio: usesExpandedVerticalProfile ? 0.34 : 0.33,
            minimum: usesExpandedVerticalProfile ? padHandleMin : phoneHandleMin,
            maximum: usesExpandedVerticalProfile ? padHandleMax : phoneHandleMax
        )
        let dockHeight = max(collapsedTrayHeight - handleBandHeight, 0)
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
            trayHeight: collapsedTrayHeight,
            expandedTrayHeight: max(expandedTrayHeight, collapsedTrayHeight),
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
