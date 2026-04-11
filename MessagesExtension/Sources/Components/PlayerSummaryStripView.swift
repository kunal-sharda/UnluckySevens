import SwiftUI

struct PlayerSummaryStripView: View {
    let summaries: [GameOpponentSummary]

    var body: some View {
        if summaries.isEmpty {
            EmptyView()
        } else {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: GameTheme.inlineSpacing) {
                    ForEach(summaries) { summary in
                        PlayerSummaryCard(summary: summary)
                    }
                }
            }
        }
    }
}

private struct PlayerSummaryCard: View {
    let summary: GameOpponentSummary

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Circle()
                    .fill(summary.isCurrentPlayer ? GameTheme.accent : GameTheme.outline.opacity(0.35))
                    .frame(width: 10, height: 10)

                Text(summary.displayName)
                    .font(GameTheme.headingFont)
                    .foregroundStyle(GameTheme.ink)
                    .lineLimit(1)
            }

            HStack(spacing: GameTheme.inlineSpacing) {
                Label("\(summary.victoryPoints)", systemImage: "flag.fill")
                Label("\(summary.handCount)", systemImage: "shippingbox.fill")
            }
            .font(GameTheme.metaFont)
            .foregroundStyle(GameTheme.mutedInk)

            Spacer(minLength: 0)
        }
        .padding(GameTheme.compactPadding)
        .frame(width: 156, alignment: .leading)
        .frame(minHeight: 78, alignment: .leading)
        .background(GameTheme.surface.opacity(0.90))
        .overlay(
            RoundedRectangle(cornerRadius: GameTheme.smallRadius)
                .stroke(GameTheme.outline.opacity(0.15), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: GameTheme.smallRadius))
        .accessibilityElement(children: .combine)
    }
}
