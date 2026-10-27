import SwiftUI

/// A private, query-backed new-card tutorial. It cannot purchase, play or reveal a card.
struct GameDevTimingTutorialView: View {
    let panel: GameDevCardPanelModel
    let kind: GameDevCardVisualKind
    let onDismiss: () -> Void
    let onDisableTutorialPopups: () -> Void
    let onDisableTip: () -> Void
    var onEnableTip: () -> Void = {}

    private var newCard: GameDevCardTileModel? {
        guard panel.newCounts.contains(where: { $0.title == kind.title && $0.count > 0 }) else {
            return nil
        }
        return panel.cards.first { $0.kind == kind }
    }

    var body: some View {
        if let card = newCard {
            ViewThatFits(in: .vertical) {
                content(card: card)
                    .padding(20)
                    .fixedSize(horizontal: false, vertical: true)
                ScrollView {
                    content(card: card)
                        .padding(20)
                }
                .scrollBounceBehavior(.basedOnSize)
            }
            .frame(maxWidth: 326)
            .foregroundStyle(GamePhysicalTurnPalette.primaryText)
            .background(GameTheme.felt, in: RoundedRectangle(cornerRadius: 14))
            .overlay {
                RoundedRectangle(cornerRadius: 14)
                    .stroke(GamePhysicalTurnPalette.selectedKeyline.opacity(0.45), lineWidth: 1)
            }
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier("uls.tutorial.devTiming.surface")
        }
    }

    private func content(card: GameDevCardTileModel) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Your new Dev Card")
                .font(GameTheme.titleFont)
                .accessibilityAddTraits(.isHeader)

            HStack(spacing: 16) {
                GameTabletopPortraitCardView(
                    face: .ownedDevelopment(card.kind),
                    size: CGSize(width: 54, height: 68)
                )
                VStack(alignment: .leading, spacing: 4) {
                    Text(card.kind.title)
                        .font(.headline)
                    Text(card.kind == .victoryPoint ? "Counts toward your score" : "Available from your next turn")
                        .font(.subheadline)
                        .foregroundStyle(GamePhysicalTurnPalette.primaryText.opacity(0.85))
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 7) {
                    Text("Hand")
                    Image(systemName: "chevron.right")
                        .font(.caption2.weight(.semibold))
                        .accessibilityHidden(true)
                    Text("Dev Cards")
                }
                .font(.subheadline.weight(.semibold))
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("Find it in Hand, then Dev Cards")

                Text(explanation)
                    .font(GameTheme.bodyFont)
                    .foregroundStyle(GamePhysicalTurnPalette.primaryText.opacity(0.85))
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityIdentifier("uls.tutorial.devTiming.explanation")
            }

            VStack(spacing: 0) {
                Button(action: onDismiss) {
                    Text("Got it")
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity, minHeight: 44)
                }
                .buttonStyle(GameTabletopActionButtonStyle(emphasis: .primary, solidBackground: true))
                .accessibilityIdentifier("uls.tutorial.devTiming.dismiss")

                GameTutorialPreferenceControls(
                    onDisableTip: onDisableTip, onDisableAll: onDisableTutorialPopups,
                    accessibilityPrefix: "uls.tutorial.devTiming",
                    disableAllIdentifier: "uls.tutorial.devTiming.disableTutorials", onEnableTip: onEnableTip
                )
            }
        }
    }

    private var explanation: String {
        if kind == .victoryPoint {
            return "This point counts immediately, even on the turn you buy it. It stays private and reveals automatically when your total reaches 10 on your turn. You never need to play it."
        }
        return "Your card is now in your hand. You cannot play it on the turn you buy it. From your next turn, you may play one action Dev Card per turn, before or after rolling."
    }
}
