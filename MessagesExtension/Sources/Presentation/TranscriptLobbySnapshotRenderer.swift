import SwiftUI

@MainActor
enum TranscriptLobbySnapshotRenderer {
    static func render(model: LobbyScreenModel) -> UIImage? {
        let renderer = ImageRenderer(
            content: TranscriptLobbySnapshotView(model: model)
        )
        renderer.scale = 2
        renderer.proposedSize = ProposedViewSize(TranscriptBubbleImageRenderer.imageSize)
        return renderer.uiImage
    }
}
