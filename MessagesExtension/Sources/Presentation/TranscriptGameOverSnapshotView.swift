import SwiftUI

struct TranscriptGameOverSnapshotView: View {
    let visual: TranscriptGameOverVisual
    let boardImage: UIImage

    var body: some View {
        ZStack(alignment: .bottom) {
            Image(uiImage: boardImage)
                .resizable()
                .scaledToFill()

            LinearGradient(
                colors: [.clear, .black.opacity(0.48)],
                startPoint: .center,
                endPoint: .bottom
            )

            GameFinalScoreStripView(
                winnerTitle: visual.winnerTitle,
                scoreLine: visual.scoreLine
            )
            .padding(10)
        }
        .frame(
            width: TranscriptBubbleImageRenderer.imageSize.width,
            height: TranscriptBubbleImageRenderer.imageSize.height
        )
        .clipped()
    }
}
