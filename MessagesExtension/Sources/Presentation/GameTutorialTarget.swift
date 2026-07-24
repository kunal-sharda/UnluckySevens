import SwiftUI

enum GameTutorialTarget: Hashable {
    case board
    case setupOrder
    case setupSettlementPiece
    case setupRoadPiece
    case rollButton
    case bankRack
    case handSpread
    case buildRoad
    case buildSettlement
    case buildCity
    case tradeGive
    case tradeWant
    case tradeRecipients
    case maritimeOptions
    case tradeClose
    case discardSurface
    case devChooser
    case endTurnConfirmation
    case gameInfo
}

struct GameTutorialTargetPreferenceKey: PreferenceKey {
    static let defaultValue: [GameTutorialTarget: Anchor<CGRect>] = [:]

    static func reduce(
        value: inout [GameTutorialTarget: Anchor<CGRect>],
        nextValue: () -> [GameTutorialTarget: Anchor<CGRect>]
    ) {
        value.merge(nextValue(), uniquingKeysWith: { _, newest in newest })
    }
}

extension View {
    func gameTutorialTarget(_ target: GameTutorialTarget) -> some View {
        anchorPreference(
            key: GameTutorialTargetPreferenceKey.self,
            value: .bounds,
            transform: { [target: $0] }
        )
    }
}
