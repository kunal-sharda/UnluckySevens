import SwiftUI
import ULS_CoreGame

struct GameBottomTrayView: View {
    let layout: GameShellLayoutMetrics.LowerRailMetrics
    let activeShelf: GameLowerShelf?
    let selectedUtilityShelf: GameLowerShelf?
    let handTray: GameHandTrayModel
    let bankTray: GameBankTrayModel
    let opponents: [GameOpponentSummary]
    let actionDock: GameActionDockModel
    let selectedDockKind: GameActionDockItem.Kind?
    let selectedBuildKind: GameBuildShelfItem.Kind?
    let mode: GameMode
    let setupInstruction: String?
    let discardPanel: GameDiscardPanelModel?
    let tradePanel: GameTradePanelModel?
    let devCardPanel: GameDevCardPanelModel?
    let robberVictimOptions: [GameRobberVictimOption]
    let onSelectDock: (GameActionDockItem.Kind) -> Void
    let onSelectBuild: (GameBuildShelfItem.Kind) -> Void
    let onSelectUtilityShelf: (GameLowerShelf) -> Void
    let onSelectBankResource: (ResourceV1) -> Void
    let onOpenTrade: () -> Void
    let onDiscardAction: () -> Void
    let onTradeAction: (GameTradeActionKind) -> Void
    let onApplySelectedTurnIntent: () -> Void
    let onExecuteTrade: (String) -> Void
    let onDevCardAction: (GameDevCardActionKind) -> Void
    let onConfirmDevCardDraft: () -> Void
    let onResetDevCardDraft: () -> Void
    let onSelectStealVictim: (String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: GameTheme.inlineSpacing) {
            Group {
                if let activeShelf {
                    activeShelfSection(activeShelf)
                } else {
                    utilityStrip
                }
            }
            .frame(maxWidth: .infinity, minHeight: layout.topSectionHeight, maxHeight: layout.topSectionHeight, alignment: .top)

            ActionDockView(
                model: actionDock,
                selectedKind: selectedDockKind,
                onSelect: onSelectDock
            )
            .frame(maxWidth: .infinity, minHeight: layout.dockHeight, maxHeight: layout.dockHeight, alignment: .top)
        }
        .padding(GameTheme.compactPadding)
        .background(
            RoundedRectangle(cornerRadius: GameTheme.largeRadius)
                .fill(GameTheme.surface.opacity(0.97))
                .shadow(color: GameTheme.trayShadow, radius: 12, x: 0, y: -2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: GameTheme.largeRadius)
                .stroke(GameTheme.outline.opacity(0.14), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: GameTheme.largeRadius))
    }

    private var utilityStrip: some View {
        HStack(spacing: GameTheme.inlineSpacing) {
            UtilityShelfButton(
                title: "Hand",
                subtitle: "\(handTray.chips.reduce(into: 0) { $0 += $1.count }) cards",
                systemImage: "shippingbox.fill",
                isSelected: selectedUtilityShelf == .hand
            ) {
                onSelectUtilityShelf(.hand)
            }

            UtilityShelfButton(
                title: "Bank",
                subtitle: "\(bankTray.chips.reduce(into: 0) { $0 += $1.count }) left",
                systemImage: "banknote.fill",
                isSelected: selectedUtilityShelf == .bank
            ) {
                onSelectUtilityShelf(.bank)
            }

            UtilityShelfButton(
                title: "Players",
                subtitle: opponents.isEmpty ? "No roster" : "\(opponents.count) opponents",
                systemImage: "person.2.fill",
                isSelected: selectedUtilityShelf == .players
            ) {
                onSelectUtilityShelf(.players)
            }
        }
    }

    @ViewBuilder
    private func activeShelfSection(_ activeShelf: GameLowerShelf) -> some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: GameTheme.inlineSpacing) {
                switch activeShelf {
                case .hand:
                    HandTrayView(model: handTray)

                    if mode == .trade {
                        modalHost(mode: .trade)
                    } else if tradePanel != nil {
                        Button {
                            onOpenTrade()
                        } label: {
                            Label("Trade", systemImage: "arrow.left.arrow.right")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                    }
                case .bank:
                    BankTrayView(
                        model: bankTray,
                        onSelect: onSelectBankResource
                    )
                case .players:
                    PlayerSummaryStripView(summaries: opponents)
                case .build:
                    BuildShelfRegion(
                        items: actionDock.buildShelfItems,
                        selectedKind: selectedBuildKind,
                        onSelectBuild: onSelectBuild
                    )
                case .devCards:
                    modalHost(mode: mode)

                    if mode == .devCardMonopoly || mode == .devCardYearOfPlenty {
                        BankTrayView(
                            model: bankTray,
                            onSelect: onSelectBankResource
                        )
                    }
                case .forcedFlow:
                    modalHost(mode: mode)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .scrollBounceBehavior(.basedOnSize)
    }

    private func modalHost(mode: GameMode) -> some View {
        GameModalHostView(
            mode: mode,
            setupInstruction: setupInstruction,
            discardPanel: discardPanel,
            tradePanel: tradePanel,
            devCardPanel: devCardPanel,
            robberVictimOptions: robberVictimOptions,
            onDiscardAction: onDiscardAction,
            onTradeAction: onTradeAction,
            onApplySelectedTurnIntent: onApplySelectedTurnIntent,
            onExecuteTrade: onExecuteTrade,
            onDevCardAction: onDevCardAction,
            onConfirmDevCardDraft: onConfirmDevCardDraft,
            onResetDevCardDraft: onResetDevCardDraft,
            onSelectStealVictim: onSelectStealVictim
        )
    }
}

private struct UtilityShelfButton: View {
    let title: String
    let subtitle: String
    let systemImage: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Image(systemName: systemImage)
                        .font(.system(size: 13, weight: .semibold))

                    Text(title)
                        .font(GameTheme.metaFont.weight(.semibold))
                        .lineLimit(1)

                    Spacer(minLength: 0)
                }

                Text(subtitle)
                    .font(GameTheme.metaFont)
                    .foregroundStyle(GameTheme.mutedInk)
                    .lineLimit(1)
                    .minimumScaleFactor(0.82)
            }
            .foregroundStyle(GameTheme.ink)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(background)
            .overlay(
                RoundedRectangle(cornerRadius: GameTheme.smallRadius)
                    .stroke(borderColor, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: GameTheme.smallRadius))
        }
        .buttonStyle(.plain)
    }

    private var background: Color {
        isSelected ? GameTheme.accent.opacity(0.18) : GameTheme.surface.opacity(0.90)
    }

    private var borderColor: Color {
        isSelected ? GameTheme.accent.opacity(0.40) : GameTheme.outline.opacity(0.14)
    }
}

private struct BuildShelfRegion: View {
    let items: [GameBuildShelfItem]
    let selectedKind: GameBuildShelfItem.Kind?
    let onSelectBuild: (GameBuildShelfItem.Kind) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: GameTheme.inlineSpacing) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text("Build")
                    .font(GameTheme.headingFont)
                    .foregroundStyle(GameTheme.ink)

                Text("Choose a build action.")
                    .font(GameTheme.metaFont)
                    .foregroundStyle(GameTheme.mutedInk)
            }

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
                        withAnimation(GameTheme.quickAnimation) {
                            onSelectBuild(item.kind)
                        }
                    }
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
