import SwiftUI

struct ActiveGamesOverlayView: View {
    @ObservedObject var viewModel: LobbyDriverViewModel
    @State private var isExpanded: Bool = false

    var body: some View {
        if viewModel.hasRecoveredGames {
            VStack(alignment: .leading, spacing: 8) {
                Button {
                    withAnimation(GameTheme.quickAnimation) {
                        isExpanded.toggle()
                    }
                } label: {
                    Label(buttonTitle, systemImage: "square.stack.3d.up.fill")
                        .font(GameTheme.metaFont.weight(.semibold))
                        .foregroundStyle(GameTheme.ink)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(
                            Capsule()
                                .fill(GameTheme.surface.opacity(0.96))
                        )
                        .overlay(
                            Capsule()
                                .stroke(GameTheme.outline.opacity(0.14), lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)

                if isExpanded {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Recover Latest Game")
                            .font(GameTheme.headingFont)
                            .foregroundStyle(GameTheme.ink)

                        ForEach(viewModel.recoveredGames) { game in
                            Button {
                                viewModel.resumeRecoveredGame(game.gameId)
                                withAnimation(GameTheme.quickAnimation) {
                                    isExpanded = false
                                }
                            } label: {
                                recoveredGameRow(game)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(12)
                    .frame(maxWidth: 320, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: GameTheme.mediumRadius)
                            .fill(GameTheme.surface.opacity(0.96))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: GameTheme.mediumRadius)
                            .stroke(GameTheme.outline.opacity(0.14), lineWidth: 1)
                    )
                    .shadow(color: GameTheme.sectionShadow, radius: 8, x: 0, y: 2)
                    .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
            .padding(.top, 8)
            .padding(.horizontal, 12)
        }
    }

    private var buttonTitle: String {
        viewModel.recoveredGames.count == 1 ? "Game" : "Games \(viewModel.recoveredGames.count)"
    }

    private func recoveredGameRow(_ game: ActiveGameRecoverySummary) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                Text(game.title)
                    .font(GameTheme.metaFont.weight(.semibold))
                    .foregroundStyle(GameTheme.ink)
                    .lineLimit(1)

                Spacer(minLength: 8)

                if game.isCurrentSelection {
                    badge("Current")
                } else if game.isLastActive {
                    badge("Recent")
                }
            }

            Text(game.subtitle)
                .font(GameTheme.chipFont)
                .foregroundStyle(GameTheme.mutedInk)

            Text(game.detail)
                .font(.system(.caption2, design: .monospaced))
                .foregroundStyle(GameTheme.mutedInk)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: GameTheme.smallRadius)
                .fill(GameTheme.surfaceRaised.opacity(0.28))
        )
        .overlay(
            RoundedRectangle(cornerRadius: GameTheme.smallRadius)
                .stroke(GameTheme.outline.opacity(0.10), lineWidth: 1)
        )
    }

    private func badge(_ text: String) -> some View {
        Text(text)
            .font(GameTheme.chipFont)
            .foregroundStyle(GameTheme.surface)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                Capsule()
                    .fill(GameTheme.accent.opacity(0.92))
            )
    }
}
