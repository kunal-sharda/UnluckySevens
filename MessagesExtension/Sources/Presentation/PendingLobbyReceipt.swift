import Messages
import ULS_CoreGame
import ULS_Transport

/// Bounded, process-local quarantine. Never membership evidence before validation.
struct PendingLobbyReceipt {
    let state: CoreGameStateV1
    let envelope: EnvelopeV1
    let message: MSMessage
    let source: TranscriptPayloadSource
}
