import CoreGraphics

struct GameShellLayoutMetrics: Equatable {
    struct LowerRailMetrics: Equatable {
        let topSectionHeight: CGFloat
        let dockHeight: CGFloat
    }

    let headerHeight: CGFloat
    let boardHeight: CGFloat
    let trayHeight: CGFloat
    let lowerRail: LowerRailMetrics

    static func resolve(
        availableHeight: CGFloat,
        spacing: CGFloat,
        isShelfPresented: Bool
    ) -> GameShellLayoutMetrics {
        let regionCount = 3
        let usableHeight = max(availableHeight - (spacing * CGFloat(regionCount - 1)), 0)

        if isShelfPresented {
            let headerHeight = usableHeight * 0.10
            let boardHeight = usableHeight * 0.60
            let shelfHeight = usableHeight * 0.18
            let dockHeight = usableHeight * 0.12
            return GameShellLayoutMetrics(
                headerHeight: headerHeight,
                boardHeight: boardHeight,
                trayHeight: shelfHeight + dockHeight,
                lowerRail: LowerRailMetrics(
                    topSectionHeight: shelfHeight,
                    dockHeight: dockHeight
                )
            )
        }

        let headerHeight = usableHeight * 0.12
        let boardHeight = usableHeight * 0.70
        let utilityHeight = usableHeight * 0.06
        let dockHeight = usableHeight * 0.12
        return GameShellLayoutMetrics(
            headerHeight: headerHeight,
            boardHeight: boardHeight,
            trayHeight: utilityHeight + dockHeight,
            lowerRail: LowerRailMetrics(
                topSectionHeight: utilityHeight,
                dockHeight: dockHeight
            )
        )
    }
}
