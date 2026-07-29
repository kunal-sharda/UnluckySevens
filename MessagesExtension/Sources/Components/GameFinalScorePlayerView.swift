import SwiftUI

struct GameFinalScorePlayerView: View {
    let player: GameEndScorePlayer

    var body: some View {
        VStack(spacing: 2) {
            HStack(spacing: 4) {
                Circle()
                    .fill(
                        Color(
                            red: player.playerTint.red,
                            green: player.playerTint.green,
                            blue: player.playerTint.blue
                        )
                    )
                    .frame(width: 8, height: 8)
                    .overlay(Circle().stroke(GameTheme.outline.opacity(0.28), lineWidth: 1))
                    .accessibilityHidden(true)

                Text(player.displayName + (player.isLocalPlayer ? " · You" : ""))
                    .font(.caption2.weight(player.isWinner ? .bold : .semibold))
                    .foregroundStyle(GameTheme.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
            }

            Text("\(player.victoryPoints) VP")
                .font(.subheadline.weight(.bold))
                .foregroundStyle(GameTheme.ink)
                .monospacedDigit()

            if !player.awardLabels.isEmpty {
                Text(player.awardLabels.joined(separator: " · "))
                    .font(.caption2)
                    .foregroundStyle(GameTheme.mutedInk)
                    .lineLimit(1)
                    .minimumScaleFactor(0.68)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 40)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(
            [
                player.displayName,
                player.isLocalPlayer ? "you" : nil,
                player.isWinner ? "winner" : nil,
                "\(player.victoryPoints) victory points",
                player.awardLabels.isEmpty ? nil : player.awardLabels.joined(separator: ", "),
            ]
            .compactMap { $0 }
            .joined(separator: ", ")
        )
        .accessibilityIdentifier("uls.endScreen.player.\(player.id)")
    }
}
