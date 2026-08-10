import SwiftUI

struct GameTurnGameInfoView: View {
    /// A non-zero renderer signal keeps the SpriteKit-owned modal veil active.
    /// The centered panel no longer reserves or covers a bottom-board region.
    static let boardClearanceHeight: CGFloat = 1

    let model: GameInfoModel
    let games: [ActiveGameRecoverySummary]
    let onOpenGame: (String) -> Void
    let onManageGamesTap: () -> Void
    let onClose: () -> Void
    @State private var contentMode: ContentMode = .players

    private enum ContentMode {
        case players
        case games
    }

    static func preferredHeight(for model: GameInfoModel) -> CGFloat {
        let visiblePlayerCount = min(model.players.count, 4)
        let playerRowsHeight = CGFloat(visiblePlayerCount) * 44
        let playerSpacingHeight = CGFloat(max(visiblePlayerCount - 1, 0)) * 6
        let recapHeight: CGFloat = model.recapText?.isEmpty == false ? 22 : 0

        return 44 + 8 + playerRowsHeight + playerSpacingHeight + recapHeight + 12
    }

    var body: some View {
        ZStack {
            GameTheme.felt.opacity(0.98)

            VStack(alignment: .leading, spacing: 8) {
                ZStack {
                    if contentMode == .players {
                        Text("Players")
                            .font(.headline)
                            .foregroundStyle(GamePhysicalTurnPalette.primaryText)
                            .frame(maxWidth: .infinity)
                    } else {
                        Button(action: onManageGamesTap) {
                            Text("Your Games")
                                .font(.headline)
                                .foregroundStyle(GamePhysicalTurnPalette.primaryText)
                                .frame(maxWidth: .infinity, minHeight: 44)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .accessibilityHint("Opens recovery and lifecycle actions")
                        .accessibilityIdentifier("uls.gameInfo.manageGames")
                    }

                    HStack {
                        Button(
                            contentMode == .players ? "Games" : "Players",
                            systemImage: contentMode == .players
                                ? "die.face.5.fill"
                                : "person.2.fill"
                        ) {
                            withAnimation(GameTheme.quickAnimation) {
                                contentMode = contentMode == .players ? .games : .players
                            }
                        }
                        .labelStyle(.iconOnly)
                        .font(.headline)
                        .foregroundStyle(GamePhysicalTurnPalette.secondaryText)
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                        .buttonStyle(.plain)
                        .accessibilityHint(
                            contentMode == .players
                                ? "Replaces the player list with saved games"
                                : "Returns to player and game information"
                        )
                        .accessibilityIdentifier(
                            contentMode == .players
                                ? "uls.gameInfo.games"
                                : "uls.gameInfo.players"
                        )

                        Spacer(minLength: 0)

                        Button(
                            "Close game information",
                            systemImage: "xmark",
                            action: onClose
                        )
                        .labelStyle(.iconOnly)
                        .font(.headline)
                        .foregroundStyle(GamePhysicalTurnPalette.secondaryText)
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                        .buttonStyle(.plain)
                        .accessibilityIdentifier("uls.gameInfo.close")
                    }
                }

                ScrollView(.vertical, showsIndicators: true) {
                    Group {
                        switch contentMode {
                        case .players:
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
                            .accessibilityIdentifier("uls.gameInfo.playerList")
                        case .games:
                            GameTurnSavedGamesList(
                                games: games,
                                onOpenGame: onOpenGame
                            )
                        }
                    }
                    .transition(.opacity)
                }
                .scrollBounceBehavior(.basedOnSize)
            }
            .padding(14)
        }
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay {
            RoundedRectangle(cornerRadius: 14)
                .stroke(GamePhysicalTurnPalette.selectedKeyline.opacity(0.74), lineWidth: 1.5)
        }
        .shadow(color: .black.opacity(0.30), radius: 8, y: 3)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("uls.turn.gameInfo")
        .gameTutorialTarget(.gameInfo)
    }
}

private struct GameTurnSavedGamesList: View {
    let games: [ActiveGameRecoverySummary]
    let onOpenGame: (String) -> Void

    private var activeGames: [ActiveGameRecoverySummary] {
        games.filter { !$0.isFinished }
    }

    private var finishedGames: [ActiveGameRecoverySummary] {
        games.filter(\.isFinished)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: GameTheme.inlineSpacing) {
            if games.isEmpty {
                Label("No saved games", systemImage: "die.face.5")
                    .font(GameTheme.metaFont.weight(.semibold))
                    .foregroundStyle(GameTheme.surface.opacity(0.76))
                    .frame(maxWidth: .infinity, minHeight: 52, alignment: .center)
            } else {
                gamesSection(title: "Active", games: activeGames)
                gamesSection(title: "Finished", games: finishedGames)
            }
        }
    }

    @ViewBuilder
    private func gamesSection(
        title: String,
        games: [ActiveGameRecoverySummary]
    ) -> some View {
        if !games.isEmpty {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(GameTheme.surface.opacity(0.68))
                    .textCase(.uppercase)
                    .accessibilityAddTraits(.isHeader)

                ForEach(games) { game in
                    Button {
                        onOpenGame(game.gameId)
                    } label: {
                        HStack(spacing: GameTheme.inlineSpacing) {
                            Image(systemName: game.isFinished ? "checkmark.seal.fill" : "play.circle.fill")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(game.isCurrentSelection ? GameTheme.accent : GameTheme.surface.opacity(0.68))

                            VStack(alignment: .leading, spacing: 1) {
                                Text(game.title)
                                    .font(.caption.weight(.bold))
                                    .lineLimit(1)

                                Text(game.subtitle)
                                    .font(.caption2.weight(.semibold))
                                    .foregroundStyle(GameTheme.surface.opacity(0.72))
                                    .lineLimit(1)
                            }

                            Spacer(minLength: 4)

                            if game.isCurrentSelection {
                                Text("Current")
                                    .font(.caption2.weight(.bold))
                                    .foregroundStyle(GameTheme.accent)
                            } else {
                                Image(systemName: "chevron.right")
                                    .font(.caption2.weight(.bold))
                                    .foregroundStyle(GameTheme.surface.opacity(0.56))
                            }
                        }
                        .foregroundStyle(GameTheme.surface)
                        .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("uls.gameInfo.open.\(game.gameId)")
                    .accessibilityLabel(
                        [
                            game.title,
                            game.subtitle,
                            game.isCurrentSelection ? "Current game" : "Open game",
                        ]
                        .joined(separator: ", ")
                    )

                    if game.id != games.last?.id {
                        Divider()
                            .overlay(GameTheme.surface.opacity(0.14))
                    }
                }
            }
        }
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
