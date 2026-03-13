import SwiftUI

struct GameHeaderView: View {
    let statusLine: GameShellStatusLine
    let metaText: String

    var body: some View {
        VStack(alignment: .leading, spacing: GameTheme.chipSpacing) {
            Text(statusLine.title)
                .font(GameTheme.titleFont)
                .foregroundStyle(GameTheme.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.9)

            Text(statusLine.subtitle)
                .font(GameTheme.bodyFont)
                .foregroundStyle(GameTheme.mutedInk)
                .lineLimit(2)

            if !metaText.isEmpty {
                Label(metaText, systemImage: "ellipsis.message")
                    .font(GameTheme.metaFont)
                    .foregroundStyle(GameTheme.mutedInk)
                    .lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(GameTheme.compactPadding)
        .background(GameTheme.surface.opacity(0.88))
        .overlay(
            RoundedRectangle(cornerRadius: GameTheme.mediumRadius)
                .stroke(GameTheme.outline.opacity(0.18), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: GameTheme.mediumRadius))
        .shadow(color: GameTheme.sectionShadow, radius: 8, x: 0, y: 2)
        .accessibilityElement(children: .combine)
    }
}
