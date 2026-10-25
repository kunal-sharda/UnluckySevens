/// Public-only score data for conversation artwork. Never carries a private hand.
struct TranscriptGameOverScore: Equatable, Identifiable {
    let id: String
    let displayName: String
    let points: Int
}
