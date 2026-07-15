import SwiftUI

struct GamePhysicalTurnPropRailView: View {
    let actionDock: GameActionDockModel
    let selectedDockKind: GameActionDockItem.Kind?
    let isHandOpen: Bool
    let hasPendingTrade: Bool
    let playerColor: Color
    let onSelectDock: (GameActionDockItem.Kind) -> Void
    let onToggleHand: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            ForEach(physicalSlots) { slot in
                if slot.isAvailable {
                    propButton(for: slot)
                } else {
                    Color.clear
                        .frame(maxWidth: .infinity, minHeight: 58, maxHeight: 58)
                        .accessibilityHidden(true)
                }
            }
        }
        .frame(maxWidth: 316, maxHeight: .infinity, alignment: .bottom)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("uls.turn.objectRail")
        .accessibilityLabel("Turn objects")
    }

    private var physicalSlots: [GameTurnObjectRailSlot] {
        GameTurnObjectRailModel.build(actionDock: actionDock).slots.filter {
            $0.kind != .devCards
        }
    }

    private func propButton(
        for slot: GameTurnObjectRailSlot
    ) -> some View {
        let isSelected = selectionState(for: slot)
        return Button {
            if slot.kind == .hand {
                onToggleHand()
            } else if let actionKind = slot.actionItem?.kind {
                onSelectDock(actionKind)
            }
        } label: {
            VStack(spacing: GamePhysicalTurnLayout.propLabelGap) {
                prop(for: slot, isSelected: isSelected)
                    .frame(width: 48, height: GamePhysicalTurnLayout.propVisualHeight)
                    .offset(
                        x: opticalHorizontalOffset(for: slot.kind),
                        y: opticalVerticalOffset(for: slot.kind)
                            + (isSelected ? -2 : 0)
                    )
                    .frame(
                        width: 48,
                        height: GamePhysicalTurnLayout.propStageHeight,
                        alignment: .bottom
                    )

                GameTabletopNameTileView(
                    title: title(for: slot.kind),
                    width: nameTileWidth(for: slot.kind),
                    isSelected: isSelected
                )
            }
            .frame(maxWidth: .infinity, minHeight: 58, maxHeight: 58, alignment: .top)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier(accessibilityIdentifier(for: slot))
        .accessibilityLabel(title(for: slot.kind))
        .accessibilityValue(
            slot.kind == .trade && hasPendingTrade
                ? "Pending offer"
                : ""
        )
        .accessibilityHint(isSelected ? "Closes \(title(for: slot.kind))" : "Opens \(title(for: slot.kind))")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    @ViewBuilder
    private func prop(
        for slot: GameTurnObjectRailSlot,
        isSelected: Bool
    ) -> some View {
        switch slot.kind {
        case .hand:
            ZStack {
                GameTabletopPortraitCardView(
                    face: .resource(.wood),
                    size: CGSize(width: 19, height: 26)
                )
                .rotationEffect(.degrees(-14))
                .offset(x: -11, y: 2)

                GameTabletopPortraitCardView(
                    face: .resource(.wheat),
                    size: CGSize(width: 19, height: 26)
                )

                GameTabletopPortraitCardView(
                    face: .resource(.ore),
                    size: CGSize(width: 19, height: 26)
                )
                .rotationEffect(.degrees(14))
                .offset(x: 11, y: 2)
            }
            .frame(width: 44, height: GamePhysicalTurnLayout.propVisualHeight, alignment: .bottom)
            .scaleEffect(0.96, anchor: .bottom)
        case .build:
            GameTabletopPiecePropView(
                kind: .settlement,
                color: playerColor,
                isSelected: isSelected
            )
            .frame(width: 34, height: GamePhysicalTurnLayout.propVisualHeight)
            .scaleEffect(1.23, anchor: .bottom)
        case .trade:
            ZStack(alignment: .topTrailing) {
                GameMerchantShipPropView(isSelected: isSelected)
                    .frame(width: 44, height: GamePhysicalTurnLayout.propVisualHeight)

                if hasPendingTrade {
                    Circle()
                        .fill(GameTheme.surface)
                        .frame(width: 9, height: 9)
                    .overlay(Circle().stroke(GameTheme.ink, lineWidth: 1))
                }
            }
            .scaleEffect(1.00, anchor: .bottom)
        case .devCards:
            ZStack {
                GameTabletopPortraitCardView(
                    face: .ownedDevelopment(.knight),
                    size: CGSize(width: 20, height: 27)
                )
                .rotationEffect(.degrees(-8))
                .offset(x: -7)

                GameTabletopPortraitCardView(
                    face: .ownedDevelopment(.victoryPoint),
                    size: CGSize(width: 20, height: 27)
                )
                .rotationEffect(.degrees(8))
                .offset(x: 7)
            }
            .frame(width: 42, height: 34)
        case .endTurn:
            GameTurnFlagPropView(
                color: playerColor,
                isSelected: isSelected
            )
            .frame(width: 30, height: GamePhysicalTurnLayout.propVisualHeight)
            .scaleEffect(x: 1.08, y: 1.13, anchor: .bottom)
        }
    }

    private func selectionState(for slot: GameTurnObjectRailSlot) -> Bool {
        switch slot.kind {
        case .hand:
            return isHandOpen
        case .build:
            return selectedDockKind == .build
        case .trade:
            return selectedDockKind == .trade
        case .devCards:
            return selectedDockKind == .devCards
        case .endTurn:
            return selectedDockKind == .endTurn
        }
    }

    private func opticalHorizontalOffset(
        for kind: GameTurnObjectRailSlot.Kind
    ) -> CGFloat {
        switch kind {
        case .hand: return 1
        case .build, .trade: return 0
        case .devCards: return -1
        case .endTurn: return -2
        }
    }

    /// The authored props use different transparent bounds. These offsets align
    /// their visible contact edges while preserving a shared SwiftUI stage.
    private func opticalVerticalOffset(
        for kind: GameTurnObjectRailSlot.Kind
    ) -> CGFloat {
        switch kind {
        case .hand: return -3.6
        case .build: return 5.6
        case .trade, .devCards: return 0
        case .endTurn: return 1.3
        }
    }

    private func nameTileWidth(
        for kind: GameTurnObjectRailSlot.Kind
    ) -> CGFloat {
        switch kind {
        case .endTurn: return 38
        case .hand, .build, .trade, .devCards: return 48
        }
    }

    private func title(for kind: GameTurnObjectRailSlot.Kind) -> String {
        switch kind {
        case .hand: return "Hand"
        case .build: return "Build"
        case .trade: return "Trade"
        case .devCards: return "Dev"
        case .endTurn: return "End"
        }
    }

    private func accessibilityIdentifier(for slot: GameTurnObjectRailSlot) -> String {
        switch slot.kind {
        case .hand:
            return "uls.feltTools.hand"
        case .build:
            return "uls.turnObject.build"
        case .trade:
            return "uls.turnObject.trade"
        case .devCards:
            return "uls.turnObject.devCards"
        case .endTurn:
            return "uls.turnObject.endTurn"
        }
    }
}
