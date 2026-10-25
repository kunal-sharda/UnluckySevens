struct TranscriptGameOverVisual: Equatable {
    let renderModel: GameBoardRenderModel
    let winnerTitle: String
    let scores: [TranscriptGameOverScore]

    var scoreLine: String {
        scores.map { "\($0.displayName) \($0.points)" }.joined(separator: " · ")
    }
}
