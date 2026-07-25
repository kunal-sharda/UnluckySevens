import SwiftUI
import UIKit

@MainActor
enum TranscriptTradeSnapshotRenderer {
    static func render(
        visual: TranscriptTradeVisual,
        assetBundle: Bundle = .main
    ) -> UIImage? {
        let renderer = ImageRenderer(
            content: TranscriptTradeSnapshotView(
                visual: visual,
                assetBundle: assetBundle
            )
        )
        renderer.proposedSize = ProposedViewSize(
            TranscriptBubbleImageRenderer.imageSize
        )
        renderer.scale = 3
        return renderer.uiImage
    }
}
