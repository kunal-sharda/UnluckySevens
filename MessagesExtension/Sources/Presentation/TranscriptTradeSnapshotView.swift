import SwiftUI

struct TranscriptTradeSnapshotView: View {
    let visual: TranscriptTradeVisual
    let assetBundle: Bundle

    var body: some View {
        ZStack {
            Color(uiColor: GameBoardPalette.sceneBackground)

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
    }
}
