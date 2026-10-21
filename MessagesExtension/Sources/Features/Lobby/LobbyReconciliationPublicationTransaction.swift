import Foundation

struct LobbyReconciliationPublicationAttempt: Equatable {
    let id: UUID
    let gameId: String
    let anchorHash: String
    let targetHash: String
    let frontierDigest: String
}

enum LobbyReconciliationPublicationOutcome: Equatable {
    case succeeded
    case failed
}

enum LobbyReconciliationPublicationCompletion: Equatable {
    case verifyPersistence(LobbyReconciliationPublicationAttempt)
    case commit(LobbyReconciliationPublicationAttempt)
    case retry(LobbyReconciliationPublicationAttempt)
    case ignore
}

struct LobbyReconciliationPublicationTransaction {
    private(set) var activeAttempt: LobbyReconciliationPublicationAttempt?

    var isSending: Bool {
        activeAttempt != nil
    }

    mutating func invalidate() {
        activeAttempt = nil
    }

    mutating func begin(
        gameId: String,
        anchorHash: String,
        targetHash: String,
        frontierDigest: String,
        id: UUID = UUID()
    ) -> LobbyReconciliationPublicationAttempt? {
        guard activeAttempt == nil else {
            return nil
        }
        let attempt = LobbyReconciliationPublicationAttempt(
            id: id,
            gameId: gameId,
            anchorHash: anchorHash,
            targetHash: targetHash,
            frontierDigest: frontierDigest
        )
        activeAttempt = attempt
        return attempt
    }

    mutating func resolveSend(
        attemptID: UUID,
        outcome: LobbyReconciliationPublicationOutcome
    ) -> LobbyReconciliationPublicationCompletion {
        guard let activeAttempt, activeAttempt.id == attemptID else {
            return .ignore
        }
        switch outcome {
        case .succeeded:
            return .verifyPersistence(activeAttempt)
        case .failed:
            self.activeAttempt = nil
            return .retry(activeAttempt)
        }
    }

    mutating func resolvePersistence(
        attemptID: UUID,
        didPersist: Bool
    ) -> LobbyReconciliationPublicationCompletion {
        guard let activeAttempt, activeAttempt.id == attemptID else {
            return .ignore
        }
        self.activeAttempt = nil
        return didPersist ? .commit(activeAttempt) : .retry(activeAttempt)
    }
}

enum LobbyReconciliationStartGate {
    static func allowsStart(
        isBaseEligible: Bool,
        isPublicationInFlight: Bool,
        hasUnresolvedFrontier: Bool
    ) -> Bool {
        isBaseEligible && !isPublicationInFlight && !hasUnresolvedFrontier
    }
}
