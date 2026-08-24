import Foundation

struct InvitePublicationAttempt: Equatable {
    let id: UUID
    let gameId: String
}

enum InvitePublicationOutcome: Equatable {
    case succeeded
    case failed
}

enum InvitePublicationResolution: Equatable {
    case commit(InvitePublicationAttempt)
    case rollback(InvitePublicationAttempt)
    case ignore
}

struct InvitePublicationTransaction {
    private(set) var activeAttempt: InvitePublicationAttempt?

    var isSending: Bool {
        activeAttempt != nil
    }

    mutating func begin(
        gameId: String,
        id: UUID = UUID()
    ) -> InvitePublicationAttempt? {
        guard activeAttempt == nil else { return nil }

        let attempt = InvitePublicationAttempt(id: id, gameId: gameId)
        activeAttempt = attempt
        return attempt
    }

    mutating func resolve(
        attemptID: UUID,
        outcome: InvitePublicationOutcome
    ) -> InvitePublicationResolution {
        guard let attempt = activeAttempt, attempt.id == attemptID else {
            return .ignore
        }

        activeAttempt = nil
        switch outcome {
        case .succeeded:
            return .commit(attempt)
        case .failed:
            return .rollback(attempt)
        }
    }

    @discardableResult
    mutating func invalidate() -> InvitePublicationAttempt? {
        defer { activeAttempt = nil }
        return activeAttempt
    }
}
