import SwiftUI
import ULS_CoreGame

struct PlayerRecordScoreSheetView: View {
    let stats: PlayerRecordStats

    var body: some View {
        ZStack(alignment: .topTrailing) {
            HStack(spacing: -14) {
                GameTabletopResourceStampView(
                    resource: .wood,
                    size: CGSize(width: 48, height: 42),
                    usesMiniatureAsset: true
                )
                .rotationEffect(.degrees(-10))
                GameTabletopResourceStampView(
                    resource: .wheat,
                    size: CGSize(width: 48, height: 42),
                    usesMiniatureAsset: true
                )
                .rotationEffect(.degrees(7))
                GameTabletopResourceStampView(
                    resource: .ore,
                    size: CGSize(width: 48, height: 42),
                    usesMiniatureAsset: true
                )
                .rotationEffect(.degrees(-4))
            }
            .opacity(0.12)
            .offset(x: 8, y: -2)
            .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: GameTheme.inlineSpacing) {
                HStack(alignment: .firstTextBaseline) {
                    Text("Catan Stats")
                        .font(GameTheme.titleFont)
                        .foregroundStyle(GameTheme.ink)
                        .accessibilityAddTraits(.isHeader)
                    Spacer()
                    Text("\(stats.completedGames) recorded")
                        .font(GameTheme.chipFont)
                        .foregroundStyle(GameTheme.mutedInk)
                        .monospacedDigit()
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
                        Text("More game history will reveal your table patterns.")
                    }
                }
                .font(GameTheme.chipFont)
                .foregroundStyle(GameTheme.mutedInk)
                .monospacedDigit()
            }
            .padding(GameTheme.compactPadding + 2)
        }
        .background(GameTheme.surface, in: RoundedRectangle(cornerRadius: GameTheme.mediumRadius))
        .shadow(color: GameTheme.trayShadow, radius: 6, x: 0, y: 3)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("uls.playerRecord.stats")
    }
}
