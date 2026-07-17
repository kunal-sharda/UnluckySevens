import SwiftUI
import ULS_CoreGame

struct GameBottomTrayView: View {
    let layout: GameShellLayoutMetrics.LowerRailMetrics
    let handTray: GameHandTrayModel
    let actionDock: GameActionDockModel
    let selectedDockKind: GameActionDockItem.Kind?
    let isHandOpen: Bool
    let hasPendingTrade: Bool
    let presentationStyle: GameTabletopLayoutStyle
    let onSelectDock: (GameActionDockItem.Kind) -> Void
    let onToggleHand: () -> Void

    var body: some View {
        if presentationStyle.usesFeltTools {
            GameFeltToolDockView(
                actionDock: actionDock,
                selectedDockKind: selectedDockKind,
                isHandOpen: isHandOpen,
                hasPendingTrade: hasPendingTrade,
                onSelectDock: onSelectDock,
                onToggleHand: onToggleHand
            )
        } else {
            VStack(spacing: 6) {
                LowerRailHandleBand(
                    isHandOpen: isHandOpen,
                    action: onToggleHand
                )
                .frame(maxWidth: .infinity)
                .frame(height: layout.handleBandHeight)

                if isHandOpen {
                    HStack(alignment: .top, spacing: 8) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Hand")
                                .font(.system(size: 17, weight: .bold))
                                .foregroundStyle(GameTheme.ink)

                            HStack(spacing: 4) {
                                ForEach(handTray.chips) { chip in
                                    TabletopResourceCardView(chip: chip)
                                }
                            }
                        }

                        Rectangle()
                            .fill(GameTheme.outline.opacity(0.18))
                            .frame(width: 1)
                            .padding(.top, 8)

                        VStack(alignment: .center, spacing: 6) {
                            Text("Dev")
                                .font(.system(size: 17, weight: .bold))
                                .foregroundStyle(GameTheme.ink)

                            TabletopDevDeckView()
                        }
                        .frame(width: 50)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    Rectangle()
                        .fill(GameTheme.outline.opacity(0.18))
                        .frame(height: 1)
                }

                TabletopActionDockView(
                    model: actionDock,
                    selectedKind: selectedDockKind,
                    onSelect: onSelectDock
                )
                .frame(maxWidth: .infinity)
            }
            .padding(.horizontal, 12)
            .padding(.top, 0)
            .padding(.bottom, 10)
            .background(
                RoundedRectangle(cornerRadius: GameTheme.largeRadius + 6)
                    .fill(GameTheme.surface)
                    .shadow(color: GameTheme.trayShadow.opacity(0.62), radius: 8, x: 0, y: -2)
            )
            .overlay(
                RoundedRectangle(cornerRadius: GameTheme.largeRadius + 6)
                    .stroke(GameTheme.outline.opacity(0.10), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: GameTheme.largeRadius + 6))
            .contentShape(RoundedRectangle(cornerRadius: GameTheme.largeRadius + 6))
        }
    }
}

struct TabletopResourceCardView: View {
    let chip: GameHandChip

    var body: some View {
        VStack(spacing: 3) {
            Image(chip.resource.tabletopStampAssetName)
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(
                    width: chip.resource.tabletopIconSize.width,
                    height: chip.resource.tabletopIconSize.height
                )
                .foregroundStyle(chip.resource.tabletopInk)
                .accessibilityHidden(true)

            Text("\(chip.count)")
                .font(.system(size: 19, weight: .bold))
                .foregroundStyle(chip.resource.tabletopCountInk)
                .lineLimit(1)
                .minimumScaleFactor(0.82)
        }
        .frame(width: 46, height: 64)
        .background(
            RoundedRectangle(cornerRadius: 7)
                .fill(chip.resource.tabletopCardFill)
        )
        .clipShape(RoundedRectangle(cornerRadius: 7))
        .overlay(
            RoundedRectangle(cornerRadius: 7)
                .strokeBorder(GameTheme.outline.opacity(0.34), lineWidth: 1)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 5)
                .strokeBorder(.white.opacity(0.24), lineWidth: 1)
                .padding(3.5)
        )
        .shadow(color: .black.opacity(0.10), radius: 1.5, x: 0, y: 1)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(chip.shortLabel), \(chip.count)")
    }
}

private struct TabletopActionDockView: View {
    let model: GameActionDockModel
    let selectedKind: GameActionDockItem.Kind?
    let onSelect: (GameActionDockItem.Kind) -> Void

    var body: some View {
        HStack(spacing: 18) {
            Spacer(minLength: 0)

            ForEach(model.primaryItems) { item in
                TabletopActionPieceButton(
                    item: item,
                    isSelected: selectedKind == item.kind
                ) {
                    guard item.isEnabled else { return }
                    onSelect(item.kind)
                }
            }

            Spacer(minLength: 0)
        }
    }
}

struct TabletopActionPieceButton: View {
    let item: GameActionDockItem
    let isSelected: Bool
    let action: () -> Void

    @Environment(\.accessibilityReduceMotion) private var accessibilityReduceMotion

    var body: some View {
        Button(action: action) {
            Image(systemName: item.systemImage)
                .font(.system(size: 19, weight: .semibold))
                .foregroundStyle(item.isEnabled ? pieceInk : GameTheme.mutedInk.opacity(0.62))
                .frame(width: pieceWidth, height: 44)
                .background(pieceBackground)
                .overlay(pieceOverlay)
                .clipShape(pieceShape)
                .shadow(color: .black.opacity(item.isEnabled ? 0.12 : 0.04), radius: 1.5, x: 0, y: 1)
        }
        .buttonStyle(.plain)
        .disabled(!item.isEnabled)
        .scaleEffect(isSelected ? GameTheme.pressedScale : 1)
        .animation(accessibilityReduceMotion ? nil : GameTheme.quickAnimation, value: isSelected)
        .accessibilityLabel(item.title)
        .accessibilityHint(item.isEnabled ? "Selects \(item.title)" : "\(item.title) is not available")
    }

    private var pieceWidth: CGFloat {
        switch item.kind {
        case .endTurn:
            return 62
        case .build:
            return 52
        case .roll, .trade, .devCards:
            return 44
        }
    }

    private var pieceInk: Color {
        item.kind == .build ? GameTheme.surface.opacity(0.96) : GameTheme.ink
    }

    private var pieceBackground: some View {
        Group {
            if item.kind == .build {
                RoundedRectangle(cornerRadius: 5)
                    .fill(GameTheme.commandAccent.opacity(item.isEnabled ? 0.82 : 0.36))
            } else {
                pieceShape
                    .fill(item.isEnabled ? GameTheme.surfaceRaised.opacity(0.82) : GameTheme.surfaceRaised.opacity(0.35))
            }
        }
    }

    private var pieceOverlay: some View {
        pieceShape
            .stroke(
                isSelected ? GameTheme.accent.opacity(0.85) : GameTheme.outline.opacity(item.isEnabled ? 0.24 : 0.10),
                lineWidth: isSelected ? 2 : 1
            )
    }

    private var pieceShape: AnyShape {
        if item.kind == .roll || item.kind == .trade {
            return AnyShape(Circle())
        }
        return AnyShape(RoundedRectangle(cornerRadius: item.kind == .endTurn ? 6 : 8))
    }
}

struct GameLowerShelfContentView: View {
    let activeShelf: GameLowerShelf
    let availableBodySize: CGSize
    let boardCommitDraft: GameBoardCommitDraft?
    let handTray: GameHandTrayModel
    let bankTray: GameBankTrayModel
    let opponents: [GameOpponentSummary]
    let actionDock: GameActionDockModel
    let selectedBuildKind: GameBuildShelfItem.Kind?
    let presentationStyle: GameTabletopLayoutStyle
    let mode: GameMode
    let setupInstruction: String?
    let discardPanel: GameDiscardPanelModel?
    let devCardPanel: GameDevCardPanelModel?
    let robberVictimOptions: [GameRobberVictimOption]
    let selectedHandCounts: [ResourceV1: Int]
    let onSelectHandResource: ((ResourceV1) -> Void)?
    let selectedRecipients: Set<String>
    let onSelectRecipient: ((String) -> Void)?
    let discardSelectedHandCounts: [ResourceV1: Int]
    let onSelectDiscardResource: ((ResourceV1) -> Void)?
    let onRemoveDiscardResource: ((ResourceV1) -> Void)?
    let onSelectBuild: (GameBuildShelfItem.Kind) -> Void
    let onSelectBankResource: (ResourceV1) -> Void
    let onDiscardAction: () -> Void
    let onDevCardAction: (GameDevCardActionKind) -> Void
    let onConfirmDevCardDraft: () -> Void
    let onResetDevCardDraft: () -> Void
    let onConfirmBoardCommit: () -> Void
    let onCancelBoardCommit: () -> Void
    let onSelectStealVictim: (String) -> Void

    var body: some View {
        Group {
            switch activeShelf {
            case .hand:
                handShelf
            case .bank:
                BankTrayView(
                    model: bankTray,
                    density: bankDensity,
                    onSelect: onSelectBankResource
                )
            case .players:
                PlayerSummaryStripView(
                    summaries: opponents,
                    availableHeight: availableBodySize.height,
                    selectedPlayerIDs: selectedRecipients,
                    onSelectPlayer: onSelectRecipient
                )
            case .build:
                BuildShelfRegion(
                    items: actionDock.buildShelfItems,
                    selectedKind: selectedBuildKind,
                    boardCommitDraft: boardCommitDraft,
                    usesFeltTools: presentationStyle.usesFeltTools,
                    onSelectBuild: onSelectBuild,
                    onConfirmBoardCommit: onConfirmBoardCommit,
                    onCancelBoardCommit: onCancelBoardCommit
                )
            case .devCards:
                devCardsShelf
            case .forcedFlow:
                modalHost(mode: mode)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
    }

    private var handShelf: some View {
        HandTrayView(
            model: handTray,
            density: handDensity,
            selectedCountsByResource: selectedHandCounts,
            onSelectResource: onSelectHandResource
        )
    }

    private var devCardsShelf: some View {
        VStack(alignment: .leading, spacing: GameTheme.inlineSpacing) {
            if mode == .devCardMonopoly || mode == .devCardYearOfPlenty,
               let devCardPanel {
                devCardResourceStage(devCardPanel)
            } else {
                modalHost(mode: mode)
            }
        }
    }

    private func devCardResourceStage(_ panel: GameDevCardPanelModel) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            if let selectedCard = panel.cards.first(where: \.isSelected) {
                HStack(spacing: GameTheme.inlineSpacing) {
                    Label(selectedCard.kind.title, systemImage: selectedCard.kind.systemImage)
                        .font(GameTheme.metaFont.weight(.bold))

                    Spacer(minLength: 0)

                    Text(panel.message)
                        .font(GameTheme.metaFont.weight(.semibold))
                }
                .foregroundStyle(GameTheme.ink)
                .padding(.horizontal, GameTheme.compactPadding)
                .frame(maxWidth: .infinity, minHeight: 44)
                .background(GameTheme.surfaceRaised.opacity(0.94))
                .overlay(
                    RoundedRectangle(cornerRadius: GameTheme.mediumRadius)
                        .stroke(GameTheme.accent.opacity(0.42), lineWidth: 2)
                )
                .clipShape(RoundedRectangle(cornerRadius: GameTheme.mediumRadius))
                .accessibilityElement(children: .combine)
                .accessibilityAddTraits(.isSelected)
            }

            BankTrayView(
                model: bankTray,
                density: bankDensity,
                onSelect: onSelectBankResource
            )

            HStack(spacing: GameTheme.inlineSpacing) {
                Button("Back To Cards", action: onResetDevCardDraft)
                    .frame(maxWidth: .infinity, minHeight: 44)
                    .buttonStyle(.bordered)

                if let confirmTitle = panel.confirmTitle {
                    Button(confirmTitle, action: onConfirmDevCardDraft)
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .buttonStyle(.borderedProminent)
                        .disabled(!panel.canConfirm)
                }
            }
        }
    }

    private var handDensity: ResourceChipDensity {
        return ResourceChipDensity.resolve(
            availableWidth: availableBodySize.width,
            availableHeight: availableBodySize.height
        )
    }

    private var bankDensity: ResourceChipDensity {
        ResourceChipDensity.resolve(
            availableWidth: availableBodySize.width,
            availableHeight: availableBodySize.height
        )
    }

    private func modalHost(mode: GameMode) -> some View {
        GameModalHostView(
            mode: mode,
            setupInstruction: setupInstruction,
            boardCommitDraft: boardCommitDraft,
            discardPanel: discardPanel,
            devCardPanel: devCardPanel,
            robberVictimOptions: robberVictimOptions,
            discardSelectedHandCounts: discardSelectedHandCounts,
            onSelectDiscardResource: onSelectDiscardResource,
            onRemoveDiscardResource: onRemoveDiscardResource,
            onDiscardAction: onDiscardAction,
            onDevCardAction: onDevCardAction,
            onConfirmDevCardDraft: onConfirmDevCardDraft,
            onResetDevCardDraft: onResetDevCardDraft,
            onConfirmBoardCommit: onConfirmBoardCommit,
            onCancelBoardCommit: onCancelBoardCommit,
            onSelectStealVictim: onSelectStealVictim
        )
    }
}

private struct LowerRailHandleBand: View {
    let isHandOpen: Bool
    let action: () -> Void

    var body: some View {
        HStack {
            Spacer(minLength: 0)

            Button(action: action) {
                Image(systemName: isHandOpen ? "arrow.down" : "arrow.up")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(GameTheme.mutedInk)
                    .frame(width: 44, height: 44)
                    .background(GameTheme.surfaceRaised.opacity(0.26))
                    .overlay(
                        Capsule()
                            .stroke(GameTheme.outline.opacity(0.14), lineWidth: 1)
                    )
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("uls.lowerRail.handle")
            .accessibilityLabel(isHandOpen ? "Collapse hand" : "Open hand")

            Spacer(minLength: 0)
        }
        .padding(.horizontal, GameTheme.compactPadding)
    }
}

private struct BuildShelfRegion: View {
    let items: [GameBuildShelfItem]
    let selectedKind: GameBuildShelfItem.Kind?
    let boardCommitDraft: GameBoardCommitDraft?
    let usesFeltTools: Bool
    let onSelectBuild: (GameBuildShelfItem.Kind) -> Void
    let onConfirmBoardCommit: () -> Void
    let onCancelBoardCommit: () -> Void

    var body: some View {
        Group {
            if let selectedItem {
                BuildTargetSelectionView(
                    item: selectedItem,
                    boardCommitDraft: boardCommitDraft,
                    usesFeltTools: usesFeltTools,
                    onConfirmBoardCommit: onConfirmBoardCommit,
                    onCancelBoardCommit: onCancelBoardCommit
                )
            } else {
                LazyVGrid(
                    columns: Array(
                        repeating: GridItem(.flexible(minimum: 0), spacing: GameTheme.chipSpacing),
                        count: max(items.count, 1)
                    ),
                    spacing: GameTheme.chipSpacing
                ) {
                    ForEach(items) { item in
                        BuildShelfTile(item: item) {
                            guard item.isEnabled else { return }
                            onSelectBuild(item.kind)
                        }
                    }
                }
                .accessibilityIdentifier("uls.turn.build.choices")
            }
        }
        .padding(usesFeltTools ? 0 : GameTheme.compactPadding)
        .background(usesFeltTools ? Color.clear : GameTheme.surface.opacity(0.92))
        .overlay(
            RoundedRectangle(cornerRadius: GameTheme.mediumRadius)
                .stroke(
                    usesFeltTools ? Color.clear : GameTheme.outline.opacity(0.14),
                    lineWidth: 1
                )
        )
        .clipShape(RoundedRectangle(cornerRadius: GameTheme.mediumRadius))
    }

    private var selectedItem: GameBuildShelfItem? {
        guard let selectedKind else { return nil }
        return items.first { $0.kind == selectedKind }
    }
}

private struct BuildShelfTile: View {
    let item: GameBuildShelfItem
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: item.systemImage)
                    .font(.system(size: 13, weight: .semibold))

                Text(item.title)
                    .font(GameTheme.metaFont.weight(.semibold))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.82)
            }
            .foregroundStyle(item.isEnabled ? GameTheme.ink : GameTheme.mutedInk)
            .frame(maxWidth: .infinity, minHeight: 52)
            .padding(.horizontal, 6)
            .padding(.vertical, 4)
            .background(GameTheme.surfaceRaised.opacity(0.9))
            .overlay(
                RoundedRectangle(cornerRadius: GameTheme.mediumRadius)
                    .stroke(GameTheme.outline.opacity(0.12), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: GameTheme.mediumRadius))
        }
        .buttonStyle(.plain)
        .disabled(!item.isEnabled)
        .accessibilityLabel(item.title)
        .accessibilityHint("Shows placement targets for \(item.title)")
    }
}

private struct BuildTargetSelectionView: View {
    let item: GameBuildShelfItem
    let boardCommitDraft: GameBoardCommitDraft?
    let usesFeltTools: Bool
    let onConfirmBoardCommit: () -> Void
    let onCancelBoardCommit: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: GameTheme.inlineSpacing) {
            HStack(spacing: GameTheme.inlineSpacing) {
                Label(item.title, systemImage: item.systemImage)
                    .font(GameTheme.headingFont)
                    .foregroundStyle(primaryTextColor)

                Spacer(minLength: 0)

                BuildCostView(cost: item.cost)
            }

            if let boardCommitDraft {
                Text(boardCommitDraft.message)
                    .font(GameTheme.metaFont)
                    .foregroundStyle(secondaryTextColor)
                    .fixedSize(horizontal: false, vertical: true)

                Text(boardCommitDraft.summaryText)
                    .font(GameTheme.metaFont.weight(.semibold))
                    .foregroundStyle(GameTheme.accent)
                    .lineLimit(1)

                HStack(spacing: GameTheme.inlineSpacing) {
                    cancelButton

                    Button(action: onConfirmBoardCommit) {
                        Text(boardCommitDraft.confirmTitle)
                            .frame(maxWidth: .infinity, minHeight: 44)
                            .contentShape(Rectangle())
                    }
                        .buttonStyle(.borderedProminent)
                        .accessibilityIdentifier("uls.turn.build.confirm")
                }
            } else {
                Text(item.placementInstruction)
                    .font(GameTheme.metaFont)
                    .foregroundStyle(secondaryTextColor)
                    .fixedSize(horizontal: false, vertical: true)

                cancelButton
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityIdentifier("uls.turn.build.selection")
    }

    private var cancelButton: some View {
        Button(action: onCancelBoardCommit) {
            Text("Cancel")
                .frame(maxWidth: .infinity, minHeight: 44)
                .contentShape(Rectangle())
        }
            .buttonStyle(.bordered)
            .tint(usesFeltTools ? GameTheme.surface : GameTheme.accent)
            .accessibilityIdentifier("uls.turn.build.cancel")
    }

    private var primaryTextColor: Color {
        usesFeltTools ? GameTheme.surface : GameTheme.ink
    }

    private var secondaryTextColor: Color {
        usesFeltTools ? GameTheme.surface.opacity(0.82) : GameTheme.mutedInk
    }
}

private struct BuildCostView: View {
    let cost: ResourceHandV1

    private static let resources: [ResourceV1] = [.wood, .brick, .sheep, .wheat, .ore]

    var body: some View {
        HStack(spacing: 4) {
            Text("Cost")
                .font(GameTheme.metaFont.weight(.semibold))

            ForEach(costChips) { chip in
                HStack(spacing: 2) {
                    Image(chip.resource.tabletopStampAssetName)
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 14, height: 14)
                        .foregroundStyle(chip.resource.tabletopInk)
                        .accessibilityHidden(true)

                    Text("\(chip.count)")
                        .font(GameTheme.metaFont.weight(.bold))
                }
            }
        }
        .foregroundStyle(GameTheme.ink)
        .padding(.horizontal, 8)
        .frame(minHeight: 30)
        .background(GameTheme.surfaceRaised.opacity(0.9))
        .overlay(
            Capsule()
                .stroke(GameTheme.outline.opacity(0.14), lineWidth: 1)
        )
        .clipShape(Capsule())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(costAccessibilityLabel)
    }

    private var costChips: [GameHandChip] {
        Self.resources.compactMap { resource in
            let count = cost.count(for: resource)
            guard count > 0 else { return nil }
            return GameHandChip(resource: resource, count: count)
        }
    }

    private var costAccessibilityLabel: String {
        let resourceText = costChips
            .map { "\($0.count) \($0.shortLabel)" }
            .joined(separator: ", ")
        return "Cost: \(resourceText)"
    }
}
