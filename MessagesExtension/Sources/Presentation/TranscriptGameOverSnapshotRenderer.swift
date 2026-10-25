import SwiftUI
import UIKit

@MainActor
enum TranscriptGameOverSnapshotRenderer {
    static func render(visual: TranscriptGameOverVisual) -> UIImage? {
        guard let boardImage = GameBoardSnapshotRenderer.render(
            renderModel: visual.renderModel,
            variant: .transcriptPreview
        ) else {
            return nil
        }

        let renderer = ImageRenderer(
            content: TranscriptGameOverSnapshotView(
                visual: visual,
                boardImage: boardImage
            )
        )
        renderer.proposedSize = ProposedViewSize(
            width: TranscriptBubbleImageRenderer.imageSize.width, height: nil
        )
        renderer.scale = 3
        return renderer.uiImage
    }
}
