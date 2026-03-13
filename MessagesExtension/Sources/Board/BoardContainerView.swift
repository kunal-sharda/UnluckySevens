import SwiftUI

struct BoardContainerView: View {
    let title: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: GameTheme.inlineSpacing) {
            Label("Board", systemImage: "hexagon")
                .font(GameTheme.headingFont)
                .foregroundStyle(GameTheme.ink)

            Spacer(minLength: 0)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(GameTheme.titleFont)
                    .foregroundStyle(GameTheme.ink)
                    .lineLimit(2)

                Text(subtitle)
                    .font(GameTheme.metaFont)
                    .foregroundStyle(GameTheme.mutedInk)
                    .lineLimit(3)
            }
        }
        .padding(GameTheme.shellPadding)
        .frame(maxWidth: .infinity, minHeight: 220, alignment: .topLeading)
        .background(
            LinearGradient(
                colors: [
                    GameTheme.surfaceRaised.opacity(0.95),
                    GameTheme.surface.opacity(0.92),
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .overlay(
            RoundedRectangle(cornerRadius: GameTheme.largeRadius)
                .stroke(GameTheme.outline.opacity(0.18), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: GameTheme.largeRadius))
    }
}
