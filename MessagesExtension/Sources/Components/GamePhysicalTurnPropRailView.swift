import SwiftUI

struct GamePhysicalTurnPropRailView: View {
    let actionDock: GameActionDockModel
    let selectedDockKind: GameActionDockItem.Kind?
    let isHandOpen: Bool
    let handCount: Int
    let hasPendingTrade: Bool
    let playerColor: Color
    let centersAvailableProps: Bool
    let isHandInteractive: Bool
    let onSelectDock: (GameActionDockItem.Kind) -> Void
    let onToggleHand: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            ForEach(layoutSlots) { slot in
                if slot.isAvailable {
                    propButton(for: slot)
                        .frame(width: GamePhysicalTurnLayout.propSlotWidth)
                } else {
                    Color.clear
                        .frame(
                            width: GamePhysicalTurnLayout.propSlotWidth,
                            height: 58
                        )
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

    private var layoutSlots: [GameTurnObjectRailSlot] {
        centersAvailableProps
            ? physicalSlots.filter(\.isAvailable)
            : physicalSlots
    }

    @ViewBuilder
    private func propButton(
        for slot: GameTurnObjectRailSlot
    ) -> some View {
        let isSelected = selectionState(for: slot)
        if slot.kind == .hand, !isHandInteractive {
            propLabel(for: slot, isSelected: false)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(accessibilityLabel(for: slot.kind))
                .accessibilityValue("Available after the required action")
                .accessibilityRespondsToUserInteraction(false)
                .allowsHitTesting(false)
        } else {
            Button {
                if slot.kind == .hand {
                    onToggleHand()
                } else if let actionKind = slot.actionItem?.kind {
                    onSelectDock(actionKind)
                }
            } label: {
                propLabel(for: slot, isSelected: isSelected)
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier(accessibilityIdentifier(for: slot))
            .accessibilityLabel(accessibilityLabel(for: slot.kind))
            .accessibilityValue(accessibilityValue(for: slot.kind))
            .accessibilityHint(isSelected ? "Closes \(title(for: slot.kind))" : "Opens \(title(for: slot.kind))")
            .accessibilityAddTraits(isSelected ? .isSelected : [])
        }
    }

    private func propLabel(
        for slot: GameTurnObjectRailSlot,
        isSelected: Bool
    ) -> some View {
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
                title: visibleTitle(for: slot.kind),
                width: nameTileWidth(for: slot.kind),
                isSelected: isSelected
            )
        }
        .frame(maxWidth: .infinity, minHeight: 58, maxHeight: 58, alignment: .top)
        .contentShape(Rectangle())
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

                Text("\(handCount)")
                    .font(.caption2.weight(.bold))
                    .monospacedDigit()
                    .foregroundStyle(GamePhysicalTurnPalette.cardCountInk)
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
                    .padding(.horizontal, 3)
                    .frame(minWidth: 16, minHeight: 16)
                    .background {
                        Capsule()
                            .fill(GameTheme.surface)
                            .overlay {
                                Capsule()
                                    .stroke(GameTheme.outline.opacity(0.78), lineWidth: 0.8)
                            }
                    }
                    .offset(x: 14, y: -8)
                    .accessibilityHidden(true)
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
            GameMerchantShipPropView(isSelected: isSelected)
                .frame(width: 44, height: GamePhysicalTurnLayout.propVisualHeight)
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
        if kind == .trade && hasPendingTrade {
            return 56
        }

        switch kind {
        case .endTurn: return 38
        case .hand, .build, .trade, .devCards: return 48
        }
    }

    private func visibleTitle(for kind: GameTurnObjectRailSlot.Kind) -> String {
        kind == .trade && hasPendingTrade
            ? "Pending"
            : title(for: kind)
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

    private func accessibilityValue(
        for kind: GameTurnObjectRailSlot.Kind
    ) -> String {
        switch kind {
        case .trade where hasPendingTrade:
            return "Pending offer"
        case .hand, .build, .trade, .devCards, .endTurn:
            return ""
        }
    }

    private func accessibilityLabel(
        for kind: GameTurnObjectRailSlot.Kind
    ) -> String {
        kind == .hand
            ? "Hand, \(handCount) resource cards"
            : title(for: kind)
    }

    private func accessibilityIdentifier(for slot: GameTurnObjectRailSlot) -> String {
        switch slot.kind {
        case .hand:
            return "uls.physicalProps.hand"
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
