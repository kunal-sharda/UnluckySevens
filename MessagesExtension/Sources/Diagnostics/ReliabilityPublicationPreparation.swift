/// Observes local preparation only. It neither sends nor interprets recipient delivery.
enum ReliabilityPublicationPreparation {
    typealias Record = (ReliabilityDiagnosticBuffer.Action, ReliabilityDiagnosticBuffer.Boundary,
                        ReliabilityDiagnosticBuffer.Outcome, Bool?) -> Void

    static func run<Encoded, Session, Message>(
        encode: () throws -> Encoded,
        resolveSession: () throws -> Session,
        buildMessage: (Encoded, Session) throws -> Message,
        record: Record
    ) throws -> (message: Message, session: Session) {
        let encoded: Encoded
        do {
            encoded = try encode()
        } catch {
            record(.publication, .encoding, .failed, nil)
            throw error
        }
        let session: Session
        do {
            session = try resolveSession()
        } catch {
            record(.recovery, .recovery, .unavailable, false)
            throw error
        }
        let message: Message
        do {
            message = try buildMessage(encoded, session)
        } catch {
            record(.publication, .encoding, .failed, true)
            throw error
        }
        record(.publication, .encoding, .accepted, true)
        return (message, session)
    }
}
