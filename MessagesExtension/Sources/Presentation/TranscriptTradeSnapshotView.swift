import SwiftUI

struct TranscriptTradeSnapshotView: View {
    let visual: TranscriptTradeVisual
    let assetBundle: Bundle

    var body: some View {
        ZStack {
            GameTheme.felt

            GameTradeReceiptView(
                visual: visual,
                assetBundle: assetBundle
            )
        }
        .frame(
            width: TranscriptBubbleImageRenderer.imageSize.width,
            height: TranscriptBubbleImageRenderer.imageSize.height
        )
        .environment(\.colorScheme, .dark)
        // Fixed-size artwork; Messages owns scalable caption and summary text.
        .environment(\.dynamicTypeSize, .large)
    }
}
