import SwiftUI

struct GameTurnEndConfirmationView: View {
    let onCancel: () -> Void
    let onConfirm: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            Label("End your turn?", systemImage: "flag.fill")
                .font(.headline.weight(.bold))
                .foregroundStyle(GameTheme.surface)

            Text("Other legal actions will remain available if you keep playing.")
                .font(.caption)
                .foregroundStyle(GameTheme.surface.opacity(0.78))
                .multilineTextAlignment(.center)

            HStack(spacing: 10) {
                Button(action: onCancel) {
                    Text("Keep Playing")
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .contentShape(Rectangle())
                }
                    .buttonStyle(.bordered)
                    .tint(GameTheme.surface)

                Button(role: .destructive, action: onConfirm) {
                    Text("End Turn")
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .contentShape(Rectangle())
                }
                    .buttonStyle(.borderedProminent)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(GameTheme.feltRaised.opacity(0.72))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("uls.turn.endConfirmation")
    }
}
