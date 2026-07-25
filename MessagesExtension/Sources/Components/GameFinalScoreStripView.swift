import SwiftUI

struct GameFinalScoreStripView: View {
    let winnerTitle: String
    let scoreLine: String

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            Image(systemName: "trophy.fill")
                .font(.title3)
                .foregroundStyle(GamePhysicalTurnPalette.selectedKeyline)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text(winnerTitle)
                    .font(.headline)
                    .foregroundStyle(GameTheme.ink)
                    .lineLimit(1)

                Text(scoreLine)
                    .font(.caption)
                    .foregroundStyle(GameTheme.mutedInk)
                    .lineLimit(1)
                    .minimumScaleFactor(0.82)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(GameTheme.surface.opacity(0.94))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay {
            RoundedRectangle(cornerRadius: 12)
                .stroke(GameTheme.outline.opacity(0.22), lineWidth: 1)
        }
        .accessibilityElement(children: .combine)
    }
}
