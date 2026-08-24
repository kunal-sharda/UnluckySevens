enum TranscriptGameSessionBinding: Equatable {
    case cached
    case selectedMessage
    case unbound

    static func resolve(
        gameId: String,
        selectedMessageGameId: String?,
        hasSelectedMessageSession: Bool,
        hasCachedSession: Bool
    ) -> TranscriptGameSessionBinding {
        if selectedMessageGameId == gameId, hasSelectedMessageSession {
            return .selectedMessage
        }
        if hasCachedSession {
            return .cached
        }
        return .unbound
    }
}
