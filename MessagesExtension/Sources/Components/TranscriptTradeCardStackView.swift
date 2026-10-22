import SwiftUI

struct TranscriptTradeCardStackView: View {
    let chip: GameHandChip
    let cardWidth: CGFloat
    let showsIndividualCards: Bool
    let assetBundle: Bundle

    var body: some View {
        // A small exchange reads as physical cards; exact labels also describe
        // larger quantities represented by a bounded stack or a single card.
        let visibleCount = showsIndividualCards ? min(max(chip.count, 1), 3) : 1
        HStack(spacing: -cardWidth * 0.25) {
            ForEach(0..<visibleCount, id: \.self) { index in
                GameTabletopPortraitCardView(
                    face: .resource(chip.resource),
                    size: CGSize(width: cardWidth, height: cardWidth * 1.27),
                    assetBundle: assetBundle
                )
                .rotationEffect(.degrees(visibleCount == 1 ? 0 : (Double(index) - Double(visibleCount - 1) / 2) * 7))
            }
        }
        .padding(.vertical, showsIndividualCards ? 5 : 0)
        .accessibilityHidden(true)
    }
}
