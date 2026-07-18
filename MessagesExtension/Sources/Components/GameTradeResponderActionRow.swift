import SwiftUI

struct GameTradeResponderActionRow: View {
    let actions: GameTradeResponderActions
    let usesPhysicalProps: Bool
    let onAccept: () -> Void
    let onDecline: () -> Void
    let onCounter: () -> Void

    var body: some View {
        if usesPhysicalProps {
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
        } else {
            HStack(spacing: GameTheme.inlineSpacing) {
                Button("Accept", action: onAccept)
                    .frame(maxWidth: .infinity, minHeight: 44)
                    .buttonStyle(.borderedProminent)
                    .disabled(!actions.canAccept)
                    .accessibilityHint("Accepts this trade offer")

                Button("Decline", action: onDecline)
                    .frame(maxWidth: .infinity, minHeight: 44)
                    .buttonStyle(.bordered)
                    .disabled(!actions.canDecline)
                    .accessibilityHint("Declines this trade offer")

                Button("Counter", action: onCounter)
                    .frame(maxWidth: .infinity, minHeight: 44)
                    .buttonStyle(.bordered)
                    .disabled(!actions.canCounter)
                    .accessibilityHint("Creates a counteroffer")
            }
        }
    }
}
