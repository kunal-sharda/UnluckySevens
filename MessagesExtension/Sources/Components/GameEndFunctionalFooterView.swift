import SwiftUI

struct GameEndFunctionalFooterView: View {
    let model: GameEndScreenModel
    let onNewGame: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                Text(model.winnerTitle)
                    .font(.headline)
                    .foregroundStyle(GameTheme.surface)

                Spacer(minLength: 8)

                Button("New Game", systemImage: "plus", action: onNewGame)
                    .buttonStyle(.borderedProminent)
                    .tint(GameTheme.commandAccent)
                    .accessibilityIdentifier("uls.endScreen.newGame")
            }

            if let resultDetail = model.resultDetail {
                Text(resultDetail)
                    .font(.caption)
                    .foregroundStyle(GameTheme.surface.opacity(0.82))
            }

            Text(scoreLine)
                .font(.caption.weight(.semibold))
                .foregroundStyle(GameTheme.surface)
                .lineLimit(2)

            if let recapText = model.recapText, !recapText.isEmpty {
                Text(recapText)
                    .font(.caption2)
                    .foregroundStyle(GameTheme.surface.opacity(0.72))
                    .lineLimit(1)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(GameTheme.feltRaised.opacity(0.96))
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("uls.endScreen.functional")
    }

    private var scoreLine: String {
        model.players
            .map { "\($0.displayName) \($0.victoryPoints)" }
            .joined(separator: " · ")
    }
}
