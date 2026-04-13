import SwiftUI

struct GameHeaderView: View {
    let model: GameHeaderModel

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(model.statusLine.title)
                .font(.system(size: 22, weight: .bold, design: .serif))
                .foregroundStyle(GameTheme.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.9)

            if !model.statusLine.subtitle.isEmpty {
                Text(model.statusLine.subtitle)
                    .font(GameTheme.metaFont)
                    .foregroundStyle(GameTheme.mutedInk)
                    .lineLimit(1)
                    .minimumScaleFactor(0.88)
            }

            if !model.metaText.isEmpty {
                Label(model.metaText, systemImage: "ellipsis.message")
                    .font(GameTheme.metaFont)
                    .foregroundStyle(GameTheme.mutedInk)
                    .lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, GameTheme.compactPadding)
        .padding(.vertical, 10)
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
