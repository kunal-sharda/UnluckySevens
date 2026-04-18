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
        ZStack(alignment: .bottom) {
            VStack(alignment: .leading, spacing: GameTheme.sectionSpacing) {
                GameHeaderView(model: snapshot.headerModel)
                    .frame(height: snapshot.layout.headerHeight, alignment: .topLeading)

                BoardContainerView(
                    model: snapshot.boardModel,
                    renderModel: snapshot.boardRenderModel,
                    overlayModel: snapshot.overlayModel,
                    interactionMode: snapshot.mode,
                    selectionText: snapshot.selectionText,
                    hintBottomInset: snapshot.hintBottomInset,
                    frozenBoardImage: snapshot.boardImage,
                    reloadToken: 0,
                    onInteractionChanged: nil,
                    onDiagnosticsChanged: nil,
                    onGestureEvent: nil,
                    onResizeFreezeChanged: nil,
                    onFreezeRecoveryReloadRequested: nil,
                    onTargetTap: nil
                )
                .frame(height: snapshot.layout.boardHeight, alignment: .top)
                .clipped()

                if !snapshot.isGameOver {
                    GameBottomTrayView(
                        layout: snapshot.layout.lowerRail,
                        actionDock: snapshot.actionDock,
                        selectedDockKind: snapshot.selectedDockKind,
                        onSelectDock: { _ in },
                        onToggleUtilityShelf: {}
                    )
                    .frame(height: snapshot.layout.trayHeight, alignment: .top)
                    .frame(maxWidth: snapshot.lowerRailWidth)
                    .frame(maxWidth: .infinity, alignment: .center)
                }
            }
            .padding(GameTheme.shellPadding)
            .frame(
                width: snapshot.size.width,
                height: snapshot.size.height,
                alignment: .topLeading
            )

            if !snapshot.isGameOver, let activeLowerShelf = snapshot.activeLowerShelf {
                FrozenOverlayShelfCard(snapshot: snapshot, activeLowerShelf: activeLowerShelf)
                    .frame(height: snapshot.layout.overlayShelf.totalHeight, alignment: .top)
                    .frame(maxWidth: snapshot.lowerRailWidth)
                    .padding(.horizontal, GameTheme.shellPadding)
                    .padding(.bottom, GameTheme.shellPadding + snapshot.layout.lowerRail.dockHeight)
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
}

private struct FrozenOverlayShelfCard: View {
    let snapshot: GameShellFreezeSnapshot
    let activeLowerShelf: GameLowerShelf

    var body: some View {
        VStack(spacing: 0) {
            header
                .frame(
                    maxWidth: .infinity,
                    minHeight: snapshot.layout.overlayShelf.headerHeight,
                    maxHeight: snapshot.layout.overlayShelf.headerHeight
                )

            Divider()
                .overlay(GameTheme.outline.opacity(0.10))

            GameLowerShelfContentView(
                activeShelf: activeLowerShelf,
                availableBodySize: snapshot.shelfBodySize,
                boardCommitDraft: nil,
                handTray: snapshot.handTray,
                bankTray: snapshot.bankTray,
                opponents: snapshot.opponents,
                actionDock: snapshot.actionDock,
                selectedBuildKind: snapshot.selectedBuildKind,
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
                onApplySelectedTurnIntent: {},
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
            minHeight: snapshot.layout.overlayShelf.totalHeight,
            maxHeight: snapshot.layout.overlayShelf.totalHeight,
            alignment: .top
        )
        .background(
            RoundedRectangle(cornerRadius: GameTheme.largeRadius)
                .fill(GameTheme.surface.opacity(0.985))
                .shadow(color: GameTheme.trayShadow.opacity(0.86), radius: 14, x: 0, y: -3)
        )
        .overlay(
            RoundedRectangle(cornerRadius: GameTheme.largeRadius)
                .stroke(GameTheme.outline.opacity(0.14), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: GameTheme.largeRadius))
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
                    .foregroundStyle(GameTheme.ink)
                    .lineLimit(1)

                Spacer(minLength: 0)
            }
            .padding(.horizontal, GameTheme.compactPadding)
        case let .forcedFlow(title):
            HStack(spacing: GameTheme.inlineSpacing) {
                Label(title, systemImage: "arrow.triangle.2.circlepath")
                    .font(GameTheme.metaFont.weight(.semibold))
                    .foregroundStyle(GameTheme.ink)
                    .lineLimit(1)

                Spacer(minLength: 0)
            }
            .padding(.horizontal, GameTheme.compactPadding)
        }
    }

    private var contentPadding: CGFloat {
        switch snapshot.shelfStyle {
        case .utility:
            return GameTheme.inlineSpacing
        case .action, .forcedFlow:
            return GameTheme.compactPadding
        }
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
