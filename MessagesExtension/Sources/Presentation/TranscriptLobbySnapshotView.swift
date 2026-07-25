import SwiftUI

struct TranscriptLobbySnapshotView: View {
    let model: LobbyScreenModel

    var body: some View {
        ZStack {
            LobbyPalette.background

            LobbySeatTableView(model: model)
                .padding(.horizontal, 18)
                .padding(.vertical, 16)
        }
        .frame(
            width: TranscriptBubbleImageRenderer.imageSize.width,
            height: TranscriptBubbleImageRenderer.imageSize.height
        )
        .environment(\.colorScheme, .dark)
    }
}
