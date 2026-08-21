import SwiftUI
import ULS_CoreGame

struct GameTradeOverlayView: View {
    let route: GameTradeOverlayRoute
    let panelModel: GameTradePanelModel
    let bankChips: [GameBankChip]
    let handChips: [GameHandChip]
    let recipientSummaries: [GameOpponentSummary]
    let tutorialScrollTarget: GameTutorialTarget?
    @Binding var showsRecipients: Bool
    let recipientScrimTopInset: CGFloat
    let onClose: () -> Void
    let onChoosePlayerTrade: () -> Void
    let onChooseMaritimeTrade: () -> Void
    let onReplaceOffer: () -> Void
    let onStartCounterDraft: () -> Void
    let onSendDraft: () -> Void
    let onBackDraftStep: () -> Void
    let onAddGiveResource: (ResourceV1) -> Void
    let onRemoveGiveResource: (ResourceV1) -> Void
    let onAddWantResource: (ResourceV1) -> Void
    let onRemoveWantResource: (ResourceV1) -> Void
    let onToggleRecipient: (String) -> Void
    let onAcceptOffer: () -> Void
    let onDeclineOffer: () -> Void
    let onSendMaritimeTrade: (GameTradeMaritimeOption) -> Void

    var body: some View {
        GamePhysicalTradeSurfaceView(
            route: route,
            panelModel: panelModel,
            bankChips: bankChips,
            handChips: handChips,
            recipientSummaries: recipientSummaries,
            tutorialTarget: tutorialScrollTarget,
            showsRecipients: $showsRecipients,
            recipientScrimTopInset: recipientScrimTopInset,
            onClose: onClose,
            onChoosePlayerTrade: onChoosePlayerTrade,
            onChooseMaritimeTrade: onChooseMaritimeTrade,
            onReplaceOffer: onReplaceOffer,
            onStartCounterDraft: onStartCounterDraft,
            onSendDraft: onSendDraft,
            onBack: onBackDraftStep,
            onAddGiveResource: onAddGiveResource,
            onRemoveGiveResource: onRemoveGiveResource,
            onAddWantResource: onAddWantResource,
            onRemoveWantResource: onRemoveWantResource,
            onToggleRecipient: onToggleRecipient,
            onAcceptOffer: onAcceptOffer,
            onDeclineOffer: onDeclineOffer,
            onSendMaritimeTrade: onSendMaritimeTrade
        )
        .transition(.opacity)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("uls.turn.tradeSurface")
    }
}
