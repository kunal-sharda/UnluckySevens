import SwiftUI

struct PlayerSummaryStripView: View {
    let summaries: [GameOpponentSummary]
    let availableHeight: CGFloat
    let selectedPlayerIDs: Set<String>
    let onSelectPlayer: ((String) -> Void)?

    init(
        summaries: [GameOpponentSummary],
        availableHeight: CGFloat,
        selectedPlayerIDs: Set<String> = [],
        onSelectPlayer: ((String) -> Void)? = nil
    ) {
        self.summaries = summaries
        self.availableHeight = availableHeight
        self.selectedPlayerIDs = selectedPlayerIDs
        self.onSelectPlayer = onSelectPlayer
    }

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
                PlayerSummaryRow(
                    summary: summary,
                    isSelected: selectedPlayerIDs.contains(summary.id),
                    action: onSelectPlayer.map { callback in
                        { callback(summary.id) }
                    }
                )
            }
        }
    }
}

private struct PlayerSummaryRow: View {
    static let rowHeight: CGFloat = 42

    let summary: GameOpponentSummary
    let isSelected: Bool
    let action: (() -> Void)?

    var body: some View {
        Group {
            if let action {
                Button(action: action) {
                    rowBody
                }
                .buttonStyle(.plain)
            } else {
                rowBody
            }
        }
        .accessibilityElement(children: .combine)
    }

    private var rowBody: some View {
        HStack(alignment: .center, spacing: GameTheme.inlineSpacing) {
            playerColorSwatch

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

            if isSelected {
                Text("Targeted")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .background(GameTheme.accent)
                    .clipShape(Capsule())
            } else if summary.isCurrentPlayer {
                Text("Current")
                    .font(.system(size: 10, weight: .bold))
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
        .background(isSelected ? GameTheme.surfaceRaised.opacity(0.34) : GameTheme.surface.opacity(0.90))
        .overlay(
            RoundedRectangle(cornerRadius: GameTheme.smallRadius)
                .stroke(isSelected ? GameTheme.accent.opacity(0.45) : GameTheme.outline.opacity(0.15), lineWidth: isSelected ? 2 : 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: GameTheme.smallRadius))
    }

    private var playerColorSwatch: some View {
        Circle()
            .fill(Color(
                red: summary.playerTint.red,
                green: summary.playerTint.green,
                blue: summary.playerTint.blue
            ))
            .frame(width: 14, height: 14)
            .overlay(
                Circle()
                    .stroke(GameTheme.outline.opacity(0.42), lineWidth: 1)
            )
            .accessibilityHidden(true)
    }
}
