import SwiftUI

struct GameEndOutcomeHeaderView: View {
    let model: GameEndScreenModel

    var body: some View {
        VStack(alignment: .leading, spacing: GameTheme.chipSpacing) {
            Text(model.winnerTitle)
                .font(GameTheme.titleFont)
                .foregroundStyle(GamePhysicalTurnPalette.primaryText)
                .lineLimit(1)

            if let winningScoreText = model.winningScoreText {
                Text(winningScoreText)
                    .font(GameTheme.headingFont)
                    .foregroundStyle(GameTheme.accent)
                    .lineLimit(1)
            }

            if let recapText = model.recapText, !recapText.isEmpty {
                Text(recapText)
                    .font(GameTheme.metaFont)
                    .foregroundStyle(GamePhysicalTurnPalette.secondaryText)
                    .lineLimit(2)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isHeader)
        .accessibilityIdentifier("uls.endScreen.title")
    }

}
