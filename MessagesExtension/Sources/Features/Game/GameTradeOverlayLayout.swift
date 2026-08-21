import SwiftUI

enum GameTradeOverlayLayout {
    static func panelHeight(
        for availableWidth: CGFloat,
        route: GameTradeOverlayRoute?
    ) -> CGFloat {
        let isWide = availableWidth >= 520
        switch route {
        case .chooser, nil:
            return isWide ? 220 : 236
        case .maritime:
            return isWide ? 264 : 292
        case .liveOffer:
            return isWide ? 300 : 336
        case .playerDraft:
            return isWide ? 364 : 408
        }
    }

    static let bannerHeight: CGFloat = 44
    static let verticalSpacing: CGFloat = 10
}
