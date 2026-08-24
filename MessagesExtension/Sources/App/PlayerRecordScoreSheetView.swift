import SwiftUI
import ULS_CoreGame

struct PlayerRecordScoreSheetView: View {
    let stats: PlayerRecordStats

    var body: some View {
        VStack(alignment: .leading, spacing: GameTheme.inlineSpacing) {
            HStack(alignment: .center, spacing: GameTheme.inlineSpacing) {
                Text("Catan Stats")
                    .font(GameTheme.titleFont)
                    .foregroundStyle(GameTheme.ink)
                    .accessibilityAddTraits(.isHeader)

                Spacer(minLength: GameTheme.inlineSpacing)

                resourceStampCluster
            }

            Divider().overlay(GameTheme.outline.opacity(0.18))

            HStack(alignment: .center, spacing: GameTheme.blockSpacing) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(stats.wins)–\(stats.losses)–\(stats.draws)")
                        .font(GameTheme.displayFont)
                        .foregroundStyle(GameTheme.ink)
                        .monospacedDigit()
                    Text("Wins · Losses · Draws")
                        .font(GameTheme.chipFont)
                        .foregroundStyle(GameTheme.mutedInk)
                }

                Spacer(minLength: GameTheme.inlineSpacing)

                Rectangle()
                    .fill(GameTheme.outline.opacity(0.16))
                    .frame(width: 1, height: 54)
                    .accessibilityHidden(true)

                VStack(alignment: .trailing, spacing: 2) {
                    Text(stats.winRateText)
                        .font(GameTheme.titleFont)
                        .foregroundStyle(GameTheme.ink)
                        .monospacedDigit()
                    Text("Win rate")
                        .font(GameTheme.chipFont)
                        .foregroundStyle(GameTheme.mutedInk)
                }
            }

            Divider().overlay(GameTheme.outline.opacity(0.18))

            VStack(alignment: .leading, spacing: 3) {
                if let fastestWinTurns = stats.fastestWinTurns {
                    Text("Fastest win · \(fastestWinTurns) turns")
                }
                if stats.currentWinStreak > 1 {
                    Text("Current streak · \(stats.currentWinStreak) wins")
                }
                if stats.fastestWinTurns == nil, stats.currentWinStreak <= 1 {
                    Text(stats.completedGames == 0
                        ? "Complete a game to start your record."
                        : "Keep playing to build your record.")
                }
            }
            .font(GameTheme.chipFont)
            .foregroundStyle(GameTheme.mutedInk)
            .monospacedDigit()
        }
        .padding(GameTheme.compactPadding + 2)
        .background(GameTheme.surface, in: RoundedRectangle(cornerRadius: GameTheme.smallRadius))
        .overlay {
            RoundedRectangle(cornerRadius: GameTheme.smallRadius)
                .stroke(GameTheme.outline.opacity(0.24), lineWidth: 1)
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("uls.playerRecord.stats")
    }

    private var resourceStampCluster: some View {
        HStack(spacing: -7) {
            ForEach(resourceStampOrder, id: \.self) { resource in
                GameTabletopResourceStampView(
                    resource: resource,
                    size: CGSize(width: 27, height: 24),
                    usesMiniatureAsset: true
                )
                .rotationEffect(.degrees(stampRotation(for: resource)))
                .opacity(stats.mostUsedResource == resource ? 1 : 0.24)
                .zIndex(stats.mostUsedResource == resource ? 1 : 0)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(resourceStampAccessibilityLabel)
    }

    private var resourceStampOrder: [ResourceV1] {
        [.wood, .brick, .sheep, .wheat, .ore]
    }

    private var resourceStampAccessibilityLabel: String {
        guard let resource = stats.mostUsedResource else {
            return "No most-used build resource yet"
        }
        return "Most-used build resource: \(resource.rawValue.capitalized)"
    }

    private func stampRotation(for resource: ResourceV1) -> Double {
        switch resource {
        case .wood: -9
        case .brick: 5
        case .sheep: -4
        case .wheat: 7
        case .ore: -3
        case .desert: 0
        }
    }
}
