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
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(GamePhysicalTurnPalette.primaryText)
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .overlay {
                    RoundedRectangle(cornerRadius: 7)
                        .stroke(GamePhysicalTurnPalette.nameTileEdge, lineWidth: 1)
                }

                Button(role: .destructive, action: onConfirm) {
                    Text("End Turn")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(GamePhysicalTurnPalette.primaryText)
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .overlay {
                    RoundedRectangle(cornerRadius: 7)
                        .stroke(GamePhysicalTurnPalette.selectedKeyline, lineWidth: 1.5)
                }
            }
        }
        .padding(.horizontal, 18)
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("uls.turn.endConfirmation")
        .accessibilityLabel("End turn confirmation")
    }
}
