import SwiftUI

struct TranscriptTradeCardStackView: View {
    let chip: GameHandChip
    let availableWidth: CGFloat
    let assetBundle: Bundle

    var body: some View {
        // Small exchanges show individual cards. Exact quantities below the
        // artwork disambiguate bounded stacks for larger offers.
        let visibleCount = min(max(chip.count, 1), availableWidth >= 80 ? 3 : 1)
        let width = min(52, availableWidth / (1 + 0.78 * CGFloat(visibleCount - 1)))
        HStack(spacing: -width * 0.22) {
            ForEach(0..<visibleCount, id: \.self) { _ in
                GameTabletopPortraitCardView(
                    face: .resource(chip.resource),
                    size: CGSize(width: width, height: width * 1.27),
                    assetBundle: assetBundle
                )
            }
        }
        .accessibilityHidden(true)
    }
}
