import SwiftUI

struct GameEndResultContentView: View {
    let model: GameEndScreenModel
    let onNewGame: () -> Void
    var onSettings: (() -> Void)? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: GameTheme.inlineSpacing) {
            ViewThatFits(in: .horizontal) {
                HStack(spacing: GameTheme.inlineSpacing) {
                    GameEndResultHeadingView()

                    Spacer(minLength: GameTheme.inlineSpacing)

                    resultActions
                }

                VStack(alignment: .leading, spacing: GameTheme.chipSpacing) {
                    GameEndResultHeadingView()

                    resultActions
                }
            }

            Rectangle()
                .fill(GamePhysicalTurnPalette.nameTileInk.opacity(0.24))
                .frame(height: 1)
                .accessibilityHidden(true)

            GameEndScoreLedgerView(players: model.players)
        }
        .padding(.horizontal, GameTheme.compactPadding)
        .padding(.vertical, GameTheme.inlineSpacing)
    }

    private var resultActions: some View {
        HStack(spacing: GameTheme.inlineSpacing) {
            GameEndNewGameButton(action: onNewGame)
            if let onSettings {
                Button("Settings", systemImage: "gearshape", action: onSettings)
                    .labelStyle(.iconOnly)
                    .font(.headline)
                    .foregroundStyle(GamePhysicalTurnPalette.nameTileInk)
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("uls.endScreen.settings")
            }
        }
    }

}
