import SwiftUI

struct GameOwnedDevCardStripView: View {
    let cards: [GameOwnedDevCardSummary]

    var body: some View {
        HStack(spacing: 6) {
            if cards.isEmpty {
                Text("No development cards")
                    .font(.caption)
                    .foregroundStyle(GameTheme.surface.opacity(0.70))
            } else {
                ForEach(cards) { card in
                    VStack(spacing: 3) {
                        Image(systemName: card.kind.systemImage)
                            .font(.system(size: 14, weight: .semibold))

                        Text("\(card.totalCount)")
                            .font(.caption.weight(.bold))
                            .monospacedDigit()

                        if card.newCount > 0 {
                            Text("\(card.newCount) new")
                                .font(.system(size: 8, weight: .semibold))
                        }
                    }
                    .foregroundStyle(GameTheme.surface)
                    .frame(width: 48, height: 58)
                    .background(
                        RoundedRectangle(cornerRadius: 7)
                            .fill(Color(red: 0.05, green: 0.33, blue: 0.52))
                    )
                    .overlay {
                        RoundedRectangle(cornerRadius: 7)
                            .stroke(GameTheme.surface.opacity(card.newCount > 0 ? 0.72 : 0.28), lineWidth: card.newCount > 0 ? 2 : 1)
                    }
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel(accessibilityLabel(for: card))
                }
            }
        }
    }

    private func accessibilityLabel(for card: GameOwnedDevCardSummary) -> String {
        var parts = ["\(card.totalCount) \(card.kind.title)"]
        if card.playableCount > 0 { parts.append("\(card.playableCount) playable") }
        if card.newCount > 0 { parts.append("\(card.newCount) new") }
        return parts.joined(separator: ", ")
    }
}
