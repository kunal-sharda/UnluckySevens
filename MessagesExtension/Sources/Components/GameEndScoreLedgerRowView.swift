import SwiftUI

struct GameEndScoreLedgerRowView: View {
    let player: GameEndScorePlayer

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 5) {
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
                    .bold(player.isWinner)
                    .lineLimit(1)

                if !player.isWinner, !player.awardLabels.isEmpty {
                    Text(player.awardLabels.joined(separator: ", "))
                        .font(.caption2)
                        .foregroundStyle(
                            GamePhysicalTurnPalette.nameTileInk.opacity(0.72)
                        )
                        .lineLimit(1)
                }

                Spacer(minLength: 6)

                if player.isWinner {
                    Image(systemName: "seal.fill")
                        .foregroundStyle(GameTheme.accent)
                        .accessibilityHidden(true)
                }

                Text("\(player.victoryPoints)")
                    .font(.headline)
                    .bold()
                    .monospacedDigit()
            }
            .font(.caption)
            .foregroundStyle(
                player.isWinner
                    ? GamePhysicalTurnPalette.nameTileInk
                    : GamePhysicalTurnPalette.nameTileInk.opacity(0.72)
            )

        }
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
            player.isWinner ? "winner" : nil,
            "\(player.victoryPoints) victory points",
            player.awardLabels.isEmpty ? nil : player.awardLabels.joined(separator: ", "),
            player.scoreBreakdown.parts.isEmpty
                ? nil
                : player.scoreBreakdown.parts.joined(separator: ", "),
        ]
        .compactMap { $0 }
        .joined(separator: ", ")
    }
}
