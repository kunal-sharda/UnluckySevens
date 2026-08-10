import SwiftUI

struct GameLifecycleConfirmationView: View {
    let title: String
    let message: String
    let destructiveTitle: String
    let showsProposeDraw: Bool
    let onKeepPlaying: () -> Void
    let onProposeDraw: () -> Void
    let onConfirm: () -> Void

    var body: some View {
        ZStack {
            GamePhysicalTurnPalette.focusVeil
                .opacity(0.8)
                .ignoresSafeArea()
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 14) {
                Text(title)
                    .font(GameTheme.titleFont)
                    .foregroundStyle(GamePhysicalTurnPalette.primaryText)
                    .accessibilityAddTraits(.isHeader)

                Text(message)
                    .font(GameTheme.bodyFont)
                    .foregroundStyle(GamePhysicalTurnPalette.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)

                Rectangle()
                    .fill(GamePhysicalTurnPalette.nameTileEdge.opacity(0.72))
                    .frame(height: 1)
                    .accessibilityHidden(true)

                VStack(spacing: 8) {
                    if showsProposeDraw {
                        Button("Propose Draw", action: onProposeDraw)
                            .buttonStyle(GameTabletopActionButtonStyle(emphasis: .primary))
                            .accessibilityIdentifier("uls.games.proposeDraw")
                    }

                    Button("Keep Playing", action: onKeepPlaying)
                        .buttonStyle(GameTabletopActionButtonStyle(emphasis: .secondary))
                        .accessibilityIdentifier("uls.games.keepPlaying")

                    Button(role: .destructive, action: onConfirm) {
                        Text(destructiveTitle)
                    }
                    .buttonStyle(GameTabletopActionButtonStyle(emphasis: .destructive))
                    .accessibilityIdentifier(
                        destructiveTitle == "Resign"
                            ? "uls.games.confirmResign"
                            : "uls.games.endAnyway"
                    )
                }
            }
            .padding(16)
            .frame(maxWidth: 346)
            .background(GameTheme.felt.opacity(0.98), in: RoundedRectangle(cornerRadius: 14))
            .overlay {
                RoundedRectangle(cornerRadius: 14)
                    .stroke(GamePhysicalTurnPalette.selectedKeyline.opacity(0.74), lineWidth: 1.5)
            }
            .shadow(color: .black.opacity(0.30), radius: 8, y: 3)
            .padding(.horizontal, 20)
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier("uls.games.lifecycleConfirmation")
        }
    }
}
