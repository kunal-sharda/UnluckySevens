import SwiftUI

struct GameTradePendingBannerView: View {
    let text: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(alignment: .center, spacing: GameTheme.inlineSpacing) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Pending trade")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(GamePhysicalTurnPalette.selectedKeyline)

                    Text(text)
                        .font(GameTheme.metaFont.weight(.semibold))
                        .foregroundStyle(GamePhysicalTurnPalette.primaryText)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                }

                Spacer(minLength: 0)

                Text("Review")
                    .font(GameTheme.metaFont.weight(.semibold))
                    .foregroundStyle(GamePhysicalTurnPalette.selectedKeyline)
            }
            .padding(.horizontal, GameTheme.compactPadding)
            .padding(.vertical, 9)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: GameTheme.mediumRadius)
                    .fill(GameTheme.feltRaised.opacity(0.98))
            )
            .clipShape(RoundedRectangle(cornerRadius: GameTheme.mediumRadius))
            .overlay(
                RoundedRectangle(cornerRadius: GameTheme.mediumRadius)
                    .stroke(
                        GamePhysicalTurnPalette.selectedKeyline.opacity(0.78),
                        lineWidth: 1.5
                    )
            )
            .shadow(color: GameTheme.trayShadow, radius: 7, x: 0, y: 3)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(text)
        .accessibilityHint("Opens the pending trade")
        .accessibilityIdentifier("uls.trade.pendingBanner")
    }
}
