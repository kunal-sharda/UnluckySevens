import SwiftUI

struct PlayerRecordGroupLedgerView: View {
    let model: PlayerRecordModel

    var body: some View {
        VStack(alignment: .leading, spacing: GameTheme.blockSpacing) {
            Text("Games With \(model.currentGroupNamesText)")
                .font(GameTheme.headingFont)
                .foregroundStyle(GameTheme.surface)
                .frame(maxWidth: .infinity, alignment: .center)
                .multilineTextAlignment(.center)
                .accessibilityAddTraits(.isHeader)

            if model.hasCurrentGroup {
                VStack(spacing: 0) {
                    if !model.currentGroupStandings.isEmpty {
                        HStack(alignment: .top, spacing: GameTheme.chipSpacing) {
                            ForEach(model.currentGroupStandings) { standing in
                                VStack(spacing: 3) {
                                    GameTabletopPiecePropView(
                                        kind: .settlement,
                                        color: playerColor(for: standing.colorIndex),
                                        isSelected: standing.isLocalPlayer
                                    )
                                    .frame(width: 30, height: 30)

                                    Text(standing.isLocalPlayer ? "You" : standing.displayName)
                                        .font(GameTheme.chipFont)
                                        .lineLimit(1)
                                    Text("\(standing.wins) win\(standing.wins == 1 ? "" : "s")")
                                        .font(.footnote)
                                        .foregroundStyle(GameTheme.mutedInk)
                                        .monospacedDigit()
                                }
                                .foregroundStyle(GameTheme.ink)
                                .frame(maxWidth: .infinity)
                                .accessibilityElement(children: .combine)
                            }
                        }
                        .padding(GameTheme.compactPadding)

                        Divider().overlay(GameTheme.outline.opacity(0.18))
                    }

                    if model.withCurrentGroup.games.isEmpty {
                        Text("No games with this group yet.")
                            .font(GameTheme.metaFont)
                            .foregroundStyle(GameTheme.surface.opacity(0.78))
                            .frame(maxWidth: .infinity, minHeight: 64, alignment: .center)
                            .padding(.horizontal, GameTheme.compactPadding)
                    } else {
                        ForEach(model.withCurrentGroup.games) { game in
                            HStack(alignment: .top, spacing: GameTheme.inlineSpacing) {
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(game.outcomeKind == .inProgress ? "In progress" : game.outcomeText)
                                        .font(GameTheme.metaFont.bold())
                                        .foregroundStyle(outcomeColor(for: game.outcomeKind))
                                    if game.outcomeKind == .inProgress {
                                        Text("Continue from its game bubble")
                                            .font(GameTheme.chipFont)
                                            .foregroundStyle(GameTheme.mutedInk)
                                            .lineLimit(1)
                                    }
                                }

                                Spacer(minLength: GameTheme.inlineSpacing)

                                VStack(alignment: .trailing, spacing: 3) {
                                    if let scoreText = game.scoreText {
                                        Text(scoreText)
                                            .font(GameTheme.chipFont)
                                            .foregroundStyle(GameTheme.ink)
                                            .monospacedDigit()
                                    }
                                    Text(game.updatedText)
                                        .font(.footnote)
                                        .foregroundStyle(GameTheme.mutedInk)
                                }
                            }
                            .padding(GameTheme.compactPadding)
                            .accessibilityElement(children: .combine)
                            .accessibilityLabel(game.accessibilityLabel)
                            .accessibilityIdentifier("uls.playerRecord.game.\(game.id)")

                            if game.id != model.withCurrentGroup.games.last?.id {
                                Divider().overlay(GameTheme.outline.opacity(0.14))
                            }
                        }
                    }
                }
                .background {
                    if !model.withCurrentGroup.games.isEmpty || !model.currentGroupStandings.isEmpty {
                        RoundedRectangle(cornerRadius: GameTheme.smallRadius)
                            .fill(GameTheme.surface)
                    }
                }
                .overlay {
                    if !model.withCurrentGroup.games.isEmpty || !model.currentGroupStandings.isEmpty {
                        RoundedRectangle(cornerRadius: GameTheme.smallRadius)
                            .stroke(GameTheme.outline.opacity(0.24), lineWidth: 1)
                    }
                }
            } else {
                Text("Open Player Record from a Messages conversation to compare games with that exact player group.")
                    .font(GameTheme.metaFont)
                    .foregroundStyle(GameTheme.surface.opacity(0.78))
                    .frame(maxWidth: .infinity, minHeight: 88, alignment: .center)
                    .multilineTextAlignment(.center)
            }
        }
        .accessibilityIdentifier("uls.playerRecord.recentGames")
    }

    private func playerColor(for index: Int) -> Color {
        let colors: [Color] = [
            Color(red: 0.72, green: 0.18, blue: 0.16),
            Color(red: 0.18, green: 0.42, blue: 0.70),
            Color(red: 0.91, green: 0.88, blue: 0.78),
            Color(red: 0.78, green: 0.48, blue: 0.13),
        ]
        return colors[index % colors.count]
    }

    private func outcomeColor(for outcome: PlayerRecordOutcomeKind) -> Color {
        switch outcome {
        case .win:
            GameTheme.feltRaised
        case .inProgress:
            GameTheme.commandAccent
        case .loss, .resigned:
            GameTheme.brick
        case .draw, .ended, .unidentified:
            GameTheme.mutedInk
        }
    }
}
