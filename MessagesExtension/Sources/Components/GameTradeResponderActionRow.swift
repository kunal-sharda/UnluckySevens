import SwiftUI

struct GameTradeResponderActionRow: View {
    let actions: GameTradeResponderActions
    let onAccept: () -> Void
    let onDecline: () -> Void
    let onCounter: () -> Void

    var body: some View {
        HStack(spacing: GameTheme.inlineSpacing) {
            Button("Accept", action: onAccept)
                .buttonStyle(GameTabletopActionButtonStyle(emphasis: .primary))
                .disabled(!actions.canAccept)
                .accessibilityHint("Accepts this trade offer")

            Button("Decline", action: onDecline)
                .buttonStyle(GameTabletopActionButtonStyle(emphasis: .secondary))
                .disabled(!actions.canDecline)
                .accessibilityHint("Declines this trade offer")

            Button("Counter", action: onCounter)
                .buttonStyle(GameTabletopActionButtonStyle(emphasis: .secondary))
                .disabled(!actions.canCounter)
                .accessibilityHint("Creates a counteroffer")
        }
    }
}
