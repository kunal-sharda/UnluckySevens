import Foundation
import ULS_CoreGame

/// Holds a proposed snapshot until Messages accepts the local handoff.
/// A successful handoff is not evidence of delivery to another participant.
struct StatePublicationTransaction {
    struct Attempt {
        let id: UUID
        let state: CoreGameStateV1
    }

    private(set) var attempt: Attempt?
    var isSending: Bool { attempt != nil }

    mutating func begin(state: CoreGameStateV1) -> Attempt? {
        guard attempt == nil else { return nil }
        let next = Attempt(id: UUID(), state: state)
        attempt = next
        return next
    }

    mutating func finish(id: UUID, accepted: Bool) -> CoreGameStateV1? {
        guard let pending = attempt, pending.id == id else { return nil }
        attempt = nil
        return accepted ? pending.state : nil
    }

    mutating func invalidate() { attempt = nil }
}
