import SwiftUI
import ULS_CoreGame

struct GameBottomTrayView: View {
    let layout: GameShellLayoutMetrics.LowerRailMetrics
    let actionDock: GameActionDockModel
    let selectedDockKind: GameActionDockItem.Kind?
    let onSelectDock: (GameActionDockItem.Kind) -> Void
    let onToggleUtilityShelf: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            LowerRailHandleBand(action: onToggleUtilityShelf)
                .frame(maxWidth: .infinity, minHeight: layout.handleBandHeight, maxHeight: layout.handleBandHeight)

            ActionDockView(
                model: actionDock,
                selectedKind: selectedDockKind,
                onSelect: onSelectDock
            )
            .padding(.horizontal, GameTheme.compactPadding)
            .padding(.top, 8)
            .padding(.bottom, GameTheme.compactPadding)
            .frame(maxWidth: .infinity, minHeight: layout.dockHeight, maxHeight: layout.dockHeight, alignment: .top)
        }
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
