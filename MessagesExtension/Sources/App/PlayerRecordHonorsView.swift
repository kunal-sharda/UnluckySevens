import SwiftUI

struct PlayerRecordHonorsView: View {
    let stats: PlayerRecordStats
    let playerColorIndex: Int

    private var playerColor: Color {
        let colors: [Color] = [
            Color(red: 0.72, green: 0.18, blue: 0.16),
            Color(red: 0.18, green: 0.42, blue: 0.70),
            Color(red: 0.91, green: 0.88, blue: 0.78),
            Color(red: 0.78, green: 0.48, blue: 0.13),
        ]
        return colors[playerColorIndex % colors.count]
    }

    var body: some View {
        VStack(alignment: .leading, spacing: GameTheme.blockSpacing) {
            Text("Table Honors")
                .font(GameTheme.headingFont)
                .foregroundStyle(GameTheme.surface)
                .frame(maxWidth: .infinity, alignment: .center)
                .accessibilityAddTraits(.isHeader)

            HStack(alignment: .top, spacing: GameTheme.chipSpacing) {
                VStack(spacing: 4) {
                    GameTabletopPiecePropView(
                        kind: .road,
                        color: playerColor,
                        isSelected: false
                    )
                    .frame(width: 66, height: 48)

                    Text(stats.longestRoadRecord.map(String.init) ?? "—")
                        .font(GameTheme.titleFont)
                        .monospacedDigit()
                    Text("Longest road")
                        .font(GameTheme.chipFont)
                    Text("\(stats.longestRoadTitles) win\(stats.longestRoadTitles == 1 ? "" : "s")")
                        .font(.footnote)
                        .foregroundStyle(GameTheme.surface.opacity(0.72))
                }
                .frame(maxWidth: .infinity)
                .accessibilityElement(children: .combine)

                Rectangle()
                    .fill(GameTheme.surface.opacity(0.14))
                    .frame(width: 1, height: 112)
                    .accessibilityHidden(true)

                VStack(spacing: 4) {
                    GameTabletopPortraitCardView(
                        face: .ownedDevelopment(.knight),
                        size: CGSize(width: 40, height: 50),
                        stackDepth: max(min(stats.largestArmyTitles, 2), 1)
                    )
                    .frame(height: 48)

                    Text(stats.largestArmyRecord.map(String.init) ?? "—")
                        .font(GameTheme.titleFont)
                        .monospacedDigit()
                    Text("Largest army")
                        .font(GameTheme.chipFont)
                    Text("\(stats.largestArmyTitles) win\(stats.largestArmyTitles == 1 ? "" : "s")")
                        .font(.footnote)
                        .foregroundStyle(GameTheme.surface.opacity(0.72))
                }
                .frame(maxWidth: .infinity)
                .accessibilityElement(children: .combine)

                Rectangle()
                    .fill(GameTheme.surface.opacity(0.14))
                    .frame(width: 1, height: 112)
                    .accessibilityHidden(true)

                VStack(spacing: 4) {
                    ZStack(alignment: .trailing) {
                        RobberIdentityMark()
                            .frame(width: 28, height: 48)
                            .opacity(0.64)
                            .offset(x: 16)

                        HStack(spacing: 4) {
                            GamePhysicalDieView(value: 3, size: 30)
                                .rotationEffect(.degrees(-7))
                            GamePhysicalDieView(value: 4, size: 30)
                                .rotationEffect(.degrees(8))
                        }
                        .offset(x: -8, y: 5)
                    }
                    .frame(width: 72, height: 48)
                    .accessibilityHidden(true)

                    Text("\(stats.sevenRolls)")
                        .font(GameTheme.titleFont)
                        .monospacedDigit()
                    Text("Sevens rolled")
                        .font(GameTheme.chipFont)
                    Text("All games")
                        .font(.footnote)
                        .foregroundStyle(GameTheme.surface.opacity(0.72))
                }
                .frame(maxWidth: .infinity)
                .accessibilityElement(children: .combine)
            }
            .foregroundStyle(GameTheme.surface)
        }
        .accessibilityIdentifier("uls.playerRecord.honors")
    }
}
