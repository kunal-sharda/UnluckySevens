import SwiftUI

enum GameFeltToolSurfaceLayout {
    static func height(for availableWidth: CGFloat) -> CGFloat {
        GameShellLayoutMetrics.normalTurnActionWellHeight(
            for: availableWidth
        )
    }
}

struct GameFeltToolDockView: View {
    let actionDock: GameActionDockModel
    let selectedDockKind: GameActionDockItem.Kind?
    let isHandOpen: Bool
    let hasPendingTrade: Bool
    let onSelectDock: (GameActionDockItem.Kind) -> Void
    let onToggleHand: () -> Void

    var body: some View {
        actionRow
        .padding(.horizontal, 8)
        .padding(.bottom, 6)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        .contentShape(Rectangle())
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("uls.turn.objectRail")
        .accessibilityLabel("Turn actions")
    }

    private var actionRow: some View {
        HStack(spacing: 4) {
            ForEach(GameTurnObjectRailModel.build(actionDock: actionDock).slots) { slot in
                if slot.kind == .hand {
                    GameTurnObjectButton(
                        title: "Hand",
                        systemImage: "hand.raised.fill",
                        isSelected: isHandOpen,
                        statusText: nil,
                        accessibilityHint: isHandOpen ? "Closes your hand" : "Shows your hand",
                        action: onToggleHand
                    )
                    .accessibilityIdentifier("uls.physicalProps.hand")
                } else if let item = slot.actionItem {
                    actionObject(item)
                } else {
                    Color.clear
                        .frame(maxWidth: .infinity, minHeight: 62)
                        .accessibilityHidden(true)
                }
            }
        }
    }

    private func actionObject(_ item: GameActionDockItem) -> some View {
        GameTurnObjectButton(
            title: item.title,
            systemImage: item.systemImage,
            isSelected: selectedDockKind == item.kind,
            statusText: item.kind == .trade && hasPendingTrade ? "Pending" : shortLabel(for: item.kind),
            accessibilityHint: selectedDockKind == item.kind ? "Closes \(item.title)" : "Opens \(item.title)"
        ) {
            onSelectDock(item.kind)
        }
        .accessibilityIdentifier("uls.turnObject.\(item.kind.rawValue)")
    }

    private func shortLabel(for kind: GameActionDockItem.Kind) -> String {
        switch kind {
        case .devCards: return "Dev"
        case .endTurn: return "End"
        case .build: return "Build"
        case .trade: return "Trade"
        case .roll: return "Roll"
        }
    }
}
