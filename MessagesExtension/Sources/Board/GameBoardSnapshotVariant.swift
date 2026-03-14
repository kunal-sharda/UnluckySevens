import CoreGraphics

enum GameBoardSnapshotVariant: Equatable {
    case bubbleCompact
    case transcriptPreview

    var canvasSize: CGSize {
        switch self {
        case .bubbleCompact:
            return CGSize(width: 240, height: 180)
        case .transcriptPreview:
            return CGSize(width: 360, height: 260)
        }
    }
}
