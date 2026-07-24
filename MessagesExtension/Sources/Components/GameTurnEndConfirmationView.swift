import SwiftUI

struct GameTurnEndConfirmationView: View {
    let onCancel: () -> Void
    let onConfirm: () -> Void

    var body: some View {
        VStack(spacing: 8) {
            Text("End your turn?")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(GamePhysicalTurnPalette.primaryText)

            HStack(spacing: 10) {
                Button(action: onCancel) {
                    Text("Keep Playing")
                }
                .buttonStyle(GameTabletopActionButtonStyle(emphasis: .secondary))

                Button(role: .destructive, action: onConfirm) {
                    Text("End Turn")
                }
                .buttonStyle(GameTabletopActionButtonStyle(emphasis: .primary))
            }
        }
        .padding(.horizontal, 18)
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("uls.turn.endConfirmation")
        .accessibilityLabel("End turn confirmation")
        .gameTutorialTarget(.endTurnConfirmation)
    }
}
