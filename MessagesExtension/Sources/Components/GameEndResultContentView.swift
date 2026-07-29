import SwiftUI

struct GameEndResultContentView: View {
    let model: GameEndScreenModel
    let onNewGame: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: GameTheme.inlineSpacing) {
            ViewThatFits(in: .horizontal) {
                HStack(spacing: GameTheme.inlineSpacing) {
                    GameEndResultHeadingView()

                    Spacer(minLength: GameTheme.inlineSpacing)

                    GameEndNewGameButton(action: onNewGame)
                }

                VStack(alignment: .leading, spacing: GameTheme.chipSpacing) {
                    GameEndResultHeadingView()

                    GameEndNewGameButton(action: onNewGame)
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
}
