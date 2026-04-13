import SwiftUI

struct PlayerSummaryStripView: View {
    let summaries: [GameOpponentSummary]
    let availableHeight: CGFloat

    var body: some View {
        if summaries.isEmpty {
            EmptyView()
        } else {
            Group {
                if needsScroll {
                    ScrollView(.vertical, showsIndicators: false) {
                        rows
                    }
                    .scrollBounceBehavior(.basedOnSize)
                } else {
                    rows
                }
            }
        }
    }

    private var needsScroll: Bool {
        let totalHeight = (CGFloat(summaries.count) * PlayerSummaryRow.rowHeight)
            + (CGFloat(max(summaries.count - 1, 0)) * GameTheme.inlineSpacing)
        return totalHeight > availableHeight
    }

    private var rows: some View {
        VStack(spacing: GameTheme.inlineSpacing) {
            ForEach(summaries) { summary in
                PlayerSummaryRow(summary: summary)
            }
        }
    }
}

private struct PlayerSummaryRow: View {
    static let rowHeight: CGFloat = 42

    let summary: GameOpponentSummary

    var body: some View {
        HStack(alignment: .center, spacing: GameTheme.inlineSpacing) {
            Circle()
                .fill(summary.isCurrentPlayer ? GameTheme.accent : GameTheme.outline.opacity(0.35))
                .frame(width: 10, height: 10)

            Text(summary.displayName)
                .font(GameTheme.headingFont)
                .foregroundStyle(GameTheme.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.82)

            Spacer(minLength: 0)

            HStack(spacing: 10) {
                Label("\(summary.victoryPoints)", systemImage: "flag.fill")
                Label("\(summary.handCount)", systemImage: "shippingbox.fill")
            }
            .font(GameTheme.metaFont)
            .foregroundStyle(GameTheme.mutedInk)

            if summary.isCurrentPlayer {
                Text("Current")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .background(GameTheme.accent)
                    .clipShape(Capsule())
            }
        }
        .padding(.horizontal, GameTheme.compactPadding)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, minHeight: Self.rowHeight, alignment: .leading)
        .background(GameTheme.surface.opacity(0.90))
        .overlay(
            RoundedRectangle(cornerRadius: GameTheme.smallRadius)
                .stroke(GameTheme.outline.opacity(0.15), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: GameTheme.smallRadius))
        .accessibilityElement(children: .combine)
    }
}
