import SwiftUI

struct TranscriptTradeCardStackView: View {
    let chip: GameHandChip
    let availableWidth: CGFloat
    let assetBundle: Bundle
    var maximumCardWidth: CGFloat = 60

    var body: some View {
        // Small exchanges show individual cards. Exact quantities below the
        // artwork disambiguate bounded stacks for larger offers.
        let visibleCount = min(max(chip.count, 1), availableWidth >= 80 ? 3 : 1)
        let width = min(maximumCardWidth, max(1, availableWidth - 6) / (1 + 0.9 * CGFloat(visibleCount - 1)))
        HStack(spacing: -width * 0.1) {
            ForEach(0..<visibleCount, id: \.self) { index in
                GameTabletopPortraitCardView(
                    face: .resource(chip.resource),
                    size: CGSize(width: width, height: width * 1.27),
                    assetBundle: assetBundle
                )
                .rotationEffect(.degrees(visibleCount == 1 ? 0 : (Double(index) - Double(visibleCount - 1) / 2) * 7))
            }
        }
        .accessibilityHidden(true)
    }
}
