import SwiftUI

struct GameEndCompactScoreView: View {
    let player: GameEndScorePlayer

    var body: some View {
        VStack(spacing: GameTheme.chipSpacing) {
            HStack(spacing: GameTheme.chipSpacing) {
                Circle()
                    .fill(playerColor)
                    .frame(width: 9, height: 9)
                    .overlay {
                        Circle()
                            .stroke(
                                GamePhysicalTurnPalette.nameTileInk.opacity(0.56),
                                lineWidth: 1
                            )
                    }
                    .accessibilityHidden(true)

                Text(player.displayName)
                    .font(GameTheme.metaFont)
                    .bold()
                    .lineLimit(1)

                if player.isWinner {
                    Image(systemName: "seal.fill")
                        .foregroundStyle(GameTheme.accent)
                        .accessibilityHidden(true)
                }
            }

            HStack(alignment: .firstTextBaseline, spacing: GameTheme.chipSpacing) {
                Text("\(player.victoryPoints)")
                    .font(GameTheme.titleFont)
                    .monospacedDigit()

                Text("points")
                    .font(GameTheme.metaFont)
            }
        }
        .foregroundStyle(GamePhysicalTurnPalette.nameTileInk)
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityIdentifier("uls.endScreen.player.\(player.id)")
    }

    private var playerColor: Color {
        Color(
            red: player.playerTint.red,
            green: player.playerTint.green,
            blue: player.playerTint.blue
        )
    }

    private var accessibilityLabel: String {
        [
            player.displayName,
            player.isLocalPlayer ? "you" : nil,
            "\(player.victoryPoints) victory points",
            player.awardLabels.isEmpty ? nil : player.awardLabels.joined(separator: ", "),
        ]
        .compactMap { $0 }
        .joined(separator: ", ")
    }
}
