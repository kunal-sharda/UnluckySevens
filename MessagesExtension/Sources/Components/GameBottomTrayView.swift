import SwiftUI
import ULS_CoreGame

struct GameBottomTrayView: View {
    let layout: GameShellLayoutMetrics.LowerRailMetrics
    let handTray: GameHandTrayModel
    let actionDock: GameActionDockModel
    let selectedDockKind: GameActionDockItem.Kind?
    let onSelectDock: (GameActionDockItem.Kind) -> Void
    let onToggleUtilityShelf: () -> Void

    var body: some View {
        VStack(spacing: 8) {
            LowerRailHandleBand(action: onToggleUtilityShelf)
                .frame(maxWidth: .infinity)
                .frame(height: layout.handleBandHeight)

            HStack(alignment: .top, spacing: 10) {
                VStack(alignment: .leading, spacing: 7) {
                    Text("Hand")
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundStyle(GameTheme.ink)

                    HStack(spacing: 7) {
                        ForEach(handTray.chips) { chip in
                            TabletopResourceCardView(chip: chip)
                        }
                    }
                }

                Rectangle()
                    .fill(GameTheme.outline.opacity(0.18))
                    .frame(width: 1)
                    .padding(.top, 5)

                VStack(alignment: .center, spacing: 7) {
                    Text("Dev")
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundStyle(GameTheme.ink)

                    TabletopDevDeckView()
                }
                .frame(width: 54)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Rectangle()
                .fill(GameTheme.outline.opacity(0.18))
                .frame(height: 1)

            TabletopActionDockView(
                model: actionDock,
                selectedKind: selectedDockKind,
                onSelect: onSelectDock
            )
            .frame(maxWidth: .infinity)
        }
        .padding(.horizontal, 14)
        .padding(.top, 4)
        .padding(.bottom, 12)
        .background(
            RoundedRectangle(cornerRadius: GameTheme.largeRadius)
                .fill(GameTheme.surface.opacity(0.97))
                .shadow(color: GameTheme.trayShadow.opacity(0.82), radius: 10, x: 0, y: -1)
        )
        .overlay(
            RoundedRectangle(cornerRadius: GameTheme.largeRadius)
                .stroke(GameTheme.outline.opacity(0.14), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: GameTheme.largeRadius))
        .contentShape(RoundedRectangle(cornerRadius: GameTheme.largeRadius))
    }
}

private struct TabletopResourceCardView: View {
    let chip: GameHandChip

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            VStack(spacing: 3) {
                Image(systemName: chip.resource.tabletopSymbolName)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(chip.resource.tabletopInk)
                    .frame(height: 17)

                Text("\(chip.count)")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(GameTheme.ink)
            }
            .frame(maxWidth: .infinity, minHeight: 56)
            .padding(.horizontal, 5)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 7)
                    .fill(chip.resource.tabletopCardFill)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 7)
                    .stroke(GameTheme.outline.opacity(0.36), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.16), radius: 2, x: 0, y: 1)

            RoundedRectangle(cornerRadius: 6)
                .stroke(.white.opacity(0.25), lineWidth: 1)
                .padding(4)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(chip.shortLabel), \(chip.count)")
    }
}

private struct TabletopDevDeckView: View {
    var body: some View {
        ZStack {
            ForEach(0..<3, id: \.self) { index in
                RoundedRectangle(cornerRadius: 7)
                    .fill(Color(red: 0.05, green: 0.33, blue: 0.52))
                    .overlay(
                        RoundedRectangle(cornerRadius: 7)
                            .stroke(Color(red: 0.62, green: 0.78, blue: 0.82).opacity(0.50), lineWidth: 1)
                    )
                    .offset(x: CGFloat(index) * -1.8, y: CGFloat(index) * 1.8)
            }

            Image(systemName: "sparkle")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(GameTheme.surface)
        }
        .frame(width: 46, height: 58)
        .shadow(color: .black.opacity(0.20), radius: 3, x: 0, y: 2)
        .accessibilityLabel("Development cards")
    }
}

private struct TabletopActionDockView: View {
    let model: GameActionDockModel
    let selectedKind: GameActionDockItem.Kind?
    let onSelect: (GameActionDockItem.Kind) -> Void

    var body: some View {
        HStack(spacing: 16) {
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

private struct TabletopActionPieceButton: View {
    let item: GameActionDockItem
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: item.systemImage)
                .font(.system(size: 19, weight: .semibold))
                .foregroundStyle(item.isEnabled ? pieceInk : GameTheme.mutedInk.opacity(0.62))
                .frame(width: pieceWidth, height: 36)
                .background(pieceBackground)
                .overlay(pieceOverlay)
                .clipShape(pieceShape)
                .shadow(color: .black.opacity(item.isEnabled ? 0.18 : 0.05), radius: 2, x: 0, y: 1)
        }
        .buttonStyle(.plain)
        .disabled(!item.isEnabled)
        .scaleEffect(isSelected ? GameTheme.pressedScale : 1)
        .animation(GameTheme.quickAnimation, value: isSelected)
        .accessibilityLabel(item.title)
        .accessibilityHint(item.isEnabled ? "Selects \(item.title)" : "\(item.title) is not available")
    }

    private var pieceWidth: CGFloat {
        switch item.kind {
        case .endTurn:
            return 58
        case .build:
            return 46
        case .roll, .trade, .devCards:
            return 40
        }
    }

    private var pieceInk: Color {
        item.kind == .build ? Color(red: 0.05, green: 0.30, blue: 0.58) : GameTheme.ink
    }

    private var pieceBackground: some View {
        Group {
            if item.kind == .build {
                RoundedRectangle(cornerRadius: 5)
                    .fill(Color(red: 0.08, green: 0.47, blue: 0.78))
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
        return AnyShape(RoundedRectangle(cornerRadius: item.kind == .endTurn ? 5 : 7))
    }
}

private extension ResourceV1 {
    var tabletopSymbolName: String {
        switch self {
        case .wood:
            return "tree.fill"
        case .brick:
            return "cube.fill"
        case .sheep:
            return "cloud.fill"
        case .wheat:
            return "leaf.fill"
        case .ore:
            return "mountain.2.fill"
        case .desert:
            return "circle.dotted"
        }
    }

    var tabletopCardFill: Color {
        switch self {
        case .wood:
            return Color(red: 0.43, green: 0.30, blue: 0.15)
        case .brick:
            return Color(red: 0.73, green: 0.31, blue: 0.20)
        case .sheep:
            return Color(red: 0.56, green: 0.66, blue: 0.31)
        case .wheat:
            return Color(red: 0.86, green: 0.64, blue: 0.18)
        case .ore:
            return Color(red: 0.39, green: 0.43, blue: 0.43)
        case .desert:
            return Color(red: 0.68, green: 0.55, blue: 0.34)
        }
    }

    var tabletopInk: Color {
        switch self {
        case .ore:
            return GameTheme.surface.opacity(0.90)
        default:
            return GameTheme.ink.opacity(0.86)
        }
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
                    onSelectBuild: onSelectBuild
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
            modalHost(mode: mode)

            if mode == .devCardMonopoly || mode == .devCardYearOfPlenty {
                BankTrayView(
                    model: bankTray,
                    density: bankDensity,
                    onSelect: onSelectBankResource
                )
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
    let action: () -> Void

    var body: some View {
        HStack {
            Spacer(minLength: 0)

            Button(action: action) {
                HStack(spacing: 8) {
                    Capsule()
                        .fill(GameTheme.outline.opacity(0.25))
                        .frame(width: 22, height: 4)

                    Image(systemName: "chevron.up")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(GameTheme.mutedInk)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(GameTheme.surface.opacity(0.88))
                .overlay(
                    Capsule()
                        .stroke(GameTheme.outline.opacity(0.14), lineWidth: 1)
                )
                .clipShape(Capsule())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Open shelf")

            Spacer(minLength: 0)
        }
        .padding(.horizontal, GameTheme.compactPadding)
    }
}

private struct BuildShelfRegion: View {
    let items: [GameBuildShelfItem]
    let selectedKind: GameBuildShelfItem.Kind?
    let onSelectBuild: (GameBuildShelfItem.Kind) -> Void

    var body: some View {
        LazyVGrid(
            columns: Array(
                repeating: GridItem(.flexible(minimum: 0), spacing: GameTheme.chipSpacing),
                count: max(items.count, 1)
            ),
            spacing: GameTheme.chipSpacing
        ) {
            ForEach(items) { item in
                BuildShelfTile(
                    item: item,
                    isSelected: selectedKind == item.kind
                ) {
                    guard item.isEnabled else { return }
                    onSelectBuild(item.kind)
                }
            }
        }
        .padding(GameTheme.compactPadding)
        .background(GameTheme.surface.opacity(0.92))
        .overlay(
            RoundedRectangle(cornerRadius: GameTheme.mediumRadius)
                .stroke(GameTheme.outline.opacity(0.14), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: GameTheme.mediumRadius))
    }
}

private struct BuildShelfTile: View {
    let item: GameBuildShelfItem
    let isSelected: Bool
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
            .background(background)
            .overlay(
                RoundedRectangle(cornerRadius: GameTheme.mediumRadius)
                    .stroke(borderColor, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: GameTheme.mediumRadius))
        }
        .buttonStyle(.plain)
        .disabled(!item.isEnabled)
    }

    private var background: Color {
        isSelected ? GameTheme.accent.opacity(0.18) : GameTheme.surfaceRaised.opacity(item.isEnabled ? 0.9 : 0.72)
    }

    private var borderColor: Color {
        isSelected ? GameTheme.accent.opacity(0.40) : GameTheme.outline.opacity(0.12)
    }
}
