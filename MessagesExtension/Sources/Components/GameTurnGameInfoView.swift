import SwiftUI

struct GameTurnGameInfoView: View {
    let model: GameInfoModel
    let onClose: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label("Game", systemImage: "list.clipboard.fill")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(GameTheme.surface)

                Spacer()

                Button("Close game information", systemImage: "xmark", action: onClose)
                    .labelStyle(.iconOnly)
                    .frame(width: 44, height: 44)
                    .foregroundStyle(GameTheme.surface)
                    .buttonStyle(.plain)
            }

            ScrollView(.vertical, showsIndicators: true) {
                VStack(spacing: 6) {
                    ForEach(model.players) { player in
                        GameTurnGameInfoPlayerRow(player: player)
                    }

                    if let recapText = model.recapText, !recapText.isEmpty {
                        Label(recapText, systemImage: "clock.arrow.circlepath")
                            .font(.caption)
                            .foregroundStyle(GameTheme.surface.opacity(0.82))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.top, 2)
                    }
                }
            }
            .scrollBounceBehavior(.basedOnSize)
        }
        .padding(.horizontal, 12)
        .padding(.top, 4)
        .padding(.bottom, 8)
        .background(GameTheme.feltRaised.opacity(0.72))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("uls.turn.gameInfo")
    }
}

private struct GameTurnGameInfoPlayerRow: View {
    let player: GameInfoPlayerSummary

    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(
                    Color(
                        red: player.playerTint.red,
                        green: player.playerTint.green,
                        blue: player.playerTint.blue
                    )
                )
                .frame(width: 12, height: 12)
                .overlay(Circle().stroke(GameTheme.surface.opacity(0.55), lineWidth: 1))

            VStack(alignment: .leading, spacing: 1) {
                Text(player.displayName + (player.isLocalPlayer ? " · You" : ""))
                    .font(.caption.weight(.bold))
                    .foregroundStyle(GameTheme.surface)

                if !player.awardLabels.isEmpty {
                    Text(player.awardLabels.joined(separator: " · "))
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(GameTheme.surface.opacity(0.74))
                }
            }

            Spacer()

            Text("\(player.victoryPoints) VP")
                .font(.caption.weight(.bold))
                .foregroundStyle(GameTheme.surface)
                .monospacedDigit()

            Text("\(player.resourceCardCount) hand · \(player.developmentCardCount) dev")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(GameTheme.surface.opacity(0.76))
                .monospacedDigit()

            if player.isCurrentPlayer {
                Image(systemName: "circle.inset.filled")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(GameTheme.surface)
                    .accessibilityLabel("Current turn")
            }
        }
        .padding(.horizontal, 8)
        .frame(minHeight: 34)
        .overlay {
            RoundedRectangle(cornerRadius: 8)
                .stroke(GameTheme.surface.opacity(player.isCurrentPlayer ? 0.42 : 0.14), lineWidth: player.isCurrentPlayer ? 2 : 1)
        }
    }
}
