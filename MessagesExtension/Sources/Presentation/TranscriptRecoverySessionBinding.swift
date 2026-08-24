enum TranscriptGameSessionBinding: Equatable {
    case new
    case cached
    case selectedMessage
    case unbound

    static func resolve(
        policy: TranscriptSessionPolicy,
        selectedMessageGameId: String?,
        hasSelectedMessageSession: Bool,
        hasCachedSession: Bool
    ) -> TranscriptGameSessionBinding {
        guard case let .state(gameId) = policy else {
            return .new
        }

        if selectedMessageGameId == gameId, hasSelectedMessageSession {
            return .selectedMessage
        }
        if hasCachedSession {
            return .cached
        }
        return .unbound
    }
}
