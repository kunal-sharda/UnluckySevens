import SwiftUI
import UIKit
import ULS_CoreGame

struct GameShellFreezeSnapshot {
    let size: CGSize
    let layout: GameShellLayoutMetrics
    let lowerRailWidth: CGFloat
    let shelfBodySize: CGSize
    let isGameOver: Bool
    let headerModel: GameHeaderModel
    let boardModel: GameBoardPlaceholderModel
    let boardRenderModel: GameBoardRenderModel?
    let overlayModel: GameBoardOverlayModel
    let selectionText: String?
    let hintBottomInset: CGFloat
    let boardImage: UIImage?
    let actionDock: GameActionDockModel
    let selectedDockKind: GameActionDockItem.Kind?
    let isHandOpen: Bool
    let tabletopLayoutStyle: GameTabletopLayoutStyle
    let activeLowerShelf: GameLowerShelf?
    let shelfStyle: GameShellFreezeShelfStyle
    let mode: GameMode
    let handTray: GameHandTrayModel
    let bankTray: GameBankTrayModel
    let opponents: [GameOpponentSummary]
    let selectedBuildKind: GameBuildShelfItem.Kind?
    let setupInstruction: String?
    let discardPanel: GameDiscardPanelModel?
    let discardSelectedHandCounts: [ResourceV1: Int]
    let tradePanelModel: GameTradePanelModel?
    let devCardPanel: GameDevCardPanelModel?
    let robberVictimOptions: [GameRobberVictimOption]
    let tradeOverlayRoute: GameTradeOverlayRoute?
    let tradeSelectedHandCounts: [ResourceV1: Int]
    let tradeSelectedRecipients: Set<String>
    let pendingTradeBannerText: String?
}

enum GameShellFreezeShelfStyle {
    case utility(selected: GameLowerShelf)
    case action(shelf: GameLowerShelf)
    case forcedFlow(title: String)
}

struct GameShellFreezeOverlayView: View {
    let snapshot: GameShellFreezeSnapshot

    var body: some View {
        // Mirror the live shell's clearance for the 44-point tray handle.
        let reservedTrayHeight = snapshot.tabletopLayoutStyle.usesFeltTools
            ? snapshot.layout.trayHeight
            : snapshot.layout.expandedTrayHeight + 6
        let baseBoardPresentationHeight = visibleBoardHeight(
            layout: snapshot.layout,
            bottomTrayHeight: reservedTrayHeight
        )
        let feltToolSurfaceHeight = GameFeltToolSurfaceLayout.height(
            for: snapshot.lowerRailWidth
        )
        let feltToolSurfaceReservation = snapshot.tabletopLayoutStyle.usesFeltTools
            ? feltToolSurfaceHeight + GameTheme.sectionSpacing
            : 0
        let boardPresentationHeight = max(
            baseBoardPresentationHeight - feltToolSurfaceReservation,
            0
        )
        let overlayShelfLayout = snapshot.tabletopLayoutStyle.usesFeltTools
            ? snapshot.layout.overlayShelf.fittedToTabletopSurface(
                height: feltToolSurfaceHeight
            )
            : snapshot.layout.overlayShelf

        ZStack(alignment: .bottom) {
            VStack(alignment: .leading, spacing: GameTheme.sectionSpacing) {
                GameHeaderView(model: snapshot.headerModel)
                    .frame(height: snapshot.layout.headerHeight, alignment: .topLeading)

                BoardContainerView(
                    model: snapshot.boardModel,
                    renderModel: snapshot.boardRenderModel,
                    overlayModel: snapshot.overlayModel,
                    interactionMode: snapshot.mode,
                    bankTray: snapshot.bankTray,
                    showsTabletopRack: true,
                    showsBankCounts: true,
                    isBankOpen: snapshot.activeLowerShelf == .bank,
                    devDeckCount: 0,
                    isDevDeckEnabled: snapshot.actionDock.primaryItems.contains {
                        $0.kind == .devCards && $0.isEnabled
                    },
                selectionText: snapshot.selectionText,
                hintBottomInset: snapshot.hintBottomInset,
                showsCreamFrame: snapshot.tabletopLayoutStyle.showsCreamBoardFrame,
                boardContentVerticalOffset: 0,
                frozenBoardImage: snapshot.boardImage,
                    reloadToken: 0,
                    onInteractionChanged: nil,
                    onResizeFreezeChanged: nil,
                    onFreezeRecoveryReloadRequested: nil,
                    onTargetTap: nil,
                    onOpenBank: {},
                    onOpenDevCards: {}
                )
                .frame(height: boardPresentationHeight, alignment: .top)
                .clipped()
            }
            .padding(GameTheme.shellPadding)
            .frame(
                width: snapshot.size.width,
                height: snapshot.size.height,
                alignment: .topLeading
            )

            if !snapshot.isGameOver {
                GameBottomTrayView(
                    layout: snapshot.layout.lowerRail,
                    handTray: snapshot.handTray,
                    actionDock: snapshot.actionDock,
                    selectedDockKind: snapshot.selectedDockKind,
                    isHandOpen: snapshot.isHandOpen,
                    hasPendingTrade: snapshot.pendingTradeBannerText != nil,
                    presentationStyle: snapshot.tabletopLayoutStyle,
                    onSelectDock: { _ in },
                    onToggleHand: {}
                )
                .frame(
                    height: snapshot.tabletopLayoutStyle.usesFeltTools
                        ? snapshot.layout.trayHeight
                        : (snapshot.isHandOpen ? snapshot.layout.expandedTrayHeight : snapshot.layout.trayHeight),
                    alignment: snapshot.tabletopLayoutStyle.usesFeltTools ? .bottom : .top
                )
                .frame(maxWidth: snapshot.lowerRailWidth)
                .padding(.horizontal, GameTheme.shellPadding)
                .padding(.bottom, GameTheme.shellPadding)
            }

            if !snapshot.isGameOver,
               snapshot.tabletopLayoutStyle.usesFeltTools,
               snapshot.isHandOpen {
                GameFeltHandOverlayView(
                    handTray: snapshot.handTray,
                    ownedDevCards: []
                )
                    .frame(
                        height: feltToolSurfaceHeight,
                        alignment: .bottom
                    )
                    .frame(maxWidth: snapshot.lowerRailWidth)
                    .padding(.horizontal, GameTheme.shellPadding)
                    .padding(
                        .bottom,
                        GameTheme.shellPadding
                            + snapshot.layout.trayHeight
                    )
            }

            if !snapshot.isGameOver, let activeLowerShelf = snapshot.activeLowerShelf {
                FrozenOverlayShelfCard(
                    snapshot: snapshot,
                    activeLowerShelf: activeLowerShelf,
                    layout: overlayShelfLayout
                )
                    .frame(height: overlayShelfLayout.totalHeight, alignment: .top)
                    .frame(maxWidth: snapshot.lowerRailWidth)
                    .padding(.horizontal, GameTheme.shellPadding)
                    .padding(
                        .bottom,
                        GameTheme.shellPadding
                            + (snapshot.tabletopLayoutStyle.usesFeltTools
                                ? snapshot.layout.trayHeight
                                : snapshot.layout.lowerRail.dockHeight)
                    )
            }

            if !snapshot.isGameOver,
               snapshot.tradeOverlayRoute == nil,
               let pendingTradeBannerText = snapshot.pendingTradeBannerText {
                GameTradePendingBannerView(text: pendingTradeBannerText) {}
                    .frame(maxWidth: snapshot.lowerRailWidth)
                    .padding(.horizontal, GameTheme.shellPadding)
                    .padding(
                        .bottom,
                        GameTheme.shellPadding
                            + snapshot.layout.trayHeight
                            + (snapshot.activeLowerShelf == nil ? 0 : snapshot.layout.overlayShelf.overlapIntoBoardHeight)
                            + GameTradeOverlayLayout.verticalSpacing
                    )
            }

            if !snapshot.isGameOver,
               let tradeOverlayRoute = snapshot.tradeOverlayRoute {
                FrozenTradeOverlayCard(snapshot: snapshot, route: tradeOverlayRoute)
                    .frame(
                        height: GameTradeOverlayLayout.panelHeight(
                            for: snapshot.lowerRailWidth,
                            route: tradeOverlayRoute
                        ),
                        alignment: .top
                    )
                    .frame(maxWidth: snapshot.lowerRailWidth)
                    .padding(.horizontal, GameTheme.shellPadding)
                    .padding(
                        .bottom,
                        GameTheme.shellPadding
                            + snapshot.layout.trayHeight
                            + (snapshot.activeLowerShelf == nil ? 0 : snapshot.layout.overlayShelf.overlapIntoBoardHeight)
                            + GameTradeOverlayLayout.verticalSpacing
                    )
            }
        }
        .frame(width: snapshot.size.width, height: snapshot.size.height, alignment: .topLeading)
        .allowsHitTesting(false)
    }

    private func visibleBoardHeight(
        layout: GameShellLayoutMetrics,
        bottomTrayHeight: CGFloat
    ) -> CGFloat {
        let additionalTrayHeight = max(bottomTrayHeight - layout.trayHeight, 0)
        return max(layout.boardHeight - additionalTrayHeight, 0)
    }
}

private struct FrozenOverlayShelfCard: View {
    let snapshot: GameShellFreezeSnapshot
    let activeLowerShelf: GameLowerShelf
    let layout: GameShellLayoutMetrics.OverlayShelfMetrics

    var body: some View {
        VStack(spacing: 0) {
            header
                .frame(
                    maxWidth: .infinity,
                    minHeight: layout.headerHeight,
                    maxHeight: layout.headerHeight
                )

            Divider()
                .overlay(GameTheme.outline.opacity(0.10))
                .opacity(snapshot.tabletopLayoutStyle.usesFeltTools ? 0 : 1)

            GameLowerShelfContentView(
                activeShelf: activeLowerShelf,
                availableBodySize: snapshot.shelfBodySize,
                boardCommitDraft: nil,
                handTray: snapshot.handTray,
                bankTray: snapshot.bankTray,
                opponents: snapshot.opponents,
                actionDock: snapshot.actionDock,
                selectedBuildKind: snapshot.selectedBuildKind,
                presentationStyle: snapshot.tabletopLayoutStyle,
                mode: snapshot.mode,
                setupInstruction: snapshot.setupInstruction,
                discardPanel: snapshot.discardPanel,
                devCardPanel: snapshot.devCardPanel,
                robberVictimOptions: snapshot.robberVictimOptions,
                selectedHandCounts: snapshot.tradeSelectedHandCounts,
                onSelectHandResource: nil,
                selectedRecipients: snapshot.tradeSelectedRecipients,
                onSelectRecipient: nil,
                discardSelectedHandCounts: snapshot.discardSelectedHandCounts,
                onSelectDiscardResource: nil,
                onRemoveDiscardResource: nil,
                onSelectBuild: { _ in },
                onSelectBankResource: { _ in },
                onDiscardAction: {},
                onDevCardAction: { _ in },
                onConfirmDevCardDraft: {},
                onResetDevCardDraft: {},
                onConfirmBoardCommit: {},
                onCancelBoardCommit: {},
                onSelectStealVictim: { _ in }
            )
            .padding(contentPadding)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .clipped()
        }
        .frame(
            maxWidth: .infinity,
            minHeight: layout.totalHeight,
            maxHeight: layout.totalHeight,
            alignment: .top
        )
        .background(panelBackground)
        .overlay(panelOverlay)
        .clipShape(panelShape)
    }

    @ViewBuilder
    private var header: some View {
        switch snapshot.shelfStyle {
        case let .utility(selected):
            HStack(spacing: GameTheme.inlineSpacing) {
                ForEach([GameLowerShelf.hand, .bank, .players], id: \.rawValue) { shelf in
                    FrozenUtilityHeaderTabButton(
                        title: shelf.title,
                        isSelected: selected == shelf
                    )
                }
            }
            .padding(.horizontal, GameTheme.compactPadding)
        case let .action(shelf):
            HStack(spacing: GameTheme.inlineSpacing) {
                Label(shelf.title, systemImage: shelf.systemImage)
                    .font(GameTheme.metaFont.weight(.semibold))
                    .foregroundStyle(panelInk)
                    .lineLimit(1)

                Spacer(minLength: 0)
            }
            .padding(.horizontal, GameTheme.compactPadding)
        case let .forcedFlow(title):
            HStack(spacing: GameTheme.inlineSpacing) {
                Label(title, systemImage: "arrow.triangle.2.circlepath")
                    .font(GameTheme.metaFont.weight(.semibold))
                    .foregroundStyle(panelInk)
                    .lineLimit(1)

                Spacer(minLength: 0)
            }
            .padding(.horizontal, GameTheme.compactPadding)
        }
    }

    private var contentPadding: CGFloat {
        if snapshot.tabletopLayoutStyle.usesFeltTools {
            return 4
        }

        switch snapshot.shelfStyle {
        case .utility:
            return GameTheme.inlineSpacing
        case .action, .forcedFlow:
            return GameTheme.compactPadding
        }
    }

    private var panelInk: Color {
        snapshot.tabletopLayoutStyle.usesFeltTools ? GameTheme.surface : GameTheme.ink
    }

    @ViewBuilder
    private var panelBackground: some View {
        if snapshot.tabletopLayoutStyle.usesFeltTools {
            Color.clear
        } else {
            RoundedRectangle(cornerRadius: GameTheme.largeRadius)
                .fill(GameTheme.surface.opacity(0.985))
                .shadow(color: GameTheme.trayShadow.opacity(0.86), radius: 14, x: 0, y: -3)
        }
    }

    @ViewBuilder
    private var panelOverlay: some View {
        if snapshot.tabletopLayoutStyle.usesFeltTools {
            Color.clear
        } else {
            RoundedRectangle(cornerRadius: GameTheme.largeRadius)
                .stroke(GameTheme.outline.opacity(0.14), lineWidth: 1)
        }
    }

    private var panelShape: AnyShape {
        if snapshot.tabletopLayoutStyle.usesFeltTools {
            return AnyShape(Rectangle())
        }
        return AnyShape(RoundedRectangle(cornerRadius: GameTheme.largeRadius))
    }
}

private struct FrozenTradeOverlayCard: View {
    let snapshot: GameShellFreezeSnapshot
    let route: GameTradeOverlayRoute

    var body: some View {
        if let panelModel = snapshot.tradePanelModel {
            GameTradeOverlayView(
                route: route,
                panelModel: panelModel,
                usesFixedActionWell: snapshot.tabletopLayoutStyle.usesFeltTools,
                usesPhysicalProps: snapshot.tabletopLayoutStyle.usesPhysicalProps,
                availableWidth: snapshot.lowerRailWidth,
                bankChips: snapshot.bankTray.chips,
                handChips: snapshot.handTray.chips,
                recipientSummaries: snapshot.opponents,
                onClose: {},
                onChoosePlayerTrade: {},
                onChooseMaritimeTrade: {},
                onReplaceOffer: {},
                onStartCounterDraft: {},
                onSendDraft: {},
                onBackDraftStep: {},
                onAddGiveResource: { _ in },
                onRemoveGiveResource: { _ in },
                onAddWantResource: { _ in },
                onRemoveWantResource: { _ in },
                onToggleRecipient: { _ in },
                onAcceptOffer: {},
                onDeclineOffer: {},
                onSendMaritimeTrade: { _ in }
            )
        }
    }
}

private struct FrozenUtilityHeaderTabButton: View {
    let title: String
    let isSelected: Bool

    var body: some View {
        Text(title)
            .font(GameTheme.metaFont.weight(.semibold))
            .foregroundStyle(isSelected ? GameTheme.ink : GameTheme.mutedInk)
            .lineLimit(1)
            .minimumScaleFactor(0.82)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 8)
            .padding(.vertical, 7)
            .background(
                Capsule()
                    .fill(isSelected ? GameTheme.surfaceRaised.opacity(0.55) : GameTheme.surface.opacity(0.01))
            )
            .overlay(
                Capsule()
                    .stroke(
                        isSelected ? GameTheme.outline.opacity(0.18) : GameTheme.outline.opacity(0.08),
                        lineWidth: 1
                    )
            )
    }
}
