import SwiftUI

struct TranscriptTradeSnapshotView: View {
    let visual: TranscriptTradeVisual
    let assetBundle: Bundle

    var body: some View {
        GameTradeReceiptView(visual: visual, assetBundle: assetBundle)
            .frame(width: TranscriptBubbleImageRenderer.imageSize.width)
            .fixedSize(horizontal: false, vertical: true)
            .background(GameTheme.felt)
            .environment(\.colorScheme, .dark)
            // Fixed text size in artwork; Messages owns scalable caption/summary text.
            .environment(\.dynamicTypeSize, .large)
    }
}
