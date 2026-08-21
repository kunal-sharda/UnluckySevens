enum TranscriptRecoverySessionBinding: Equatable {
    case cached
    case selectedMessage
    case unbound

    static func resolve(
        gameId: String,
        selectedMessageGameId: String?,
        hasSelectedMessageSession: Bool,
        hasCachedSession: Bool
    ) -> TranscriptRecoverySessionBinding {
        if selectedMessageGameId == gameId, hasSelectedMessageSession {
            return .selectedMessage
        }
        if hasCachedSession {
            return .cached
        }
        return .unbound
    }

    static func permitsNewSession(
        isMarkedRecoveryUnbound: Bool,
        isExplicitReconnect: Bool
    ) -> Bool {
        !isMarkedRecoveryUnbound || isExplicitReconnect
    }
}
