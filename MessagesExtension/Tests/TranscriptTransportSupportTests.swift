import Messages
import XCTest
@testable import MessagesExtension

final class TranscriptTransportSupportTests: XCTestCase {
    func testBuildMessageIncludesPayloadQueryAndPreservesSessionPolicy() throws {
        let encodedEnvelope = "encoded-payload"
        let session = MSSession()

        let builtMessage = try TranscriptTransportSupport.buildMessage(
            encodedEnvelope: encodedEnvelope,
            caption: "Unlucky Sevens: Road built",
            summaryLabel: "Alex built a road.",
            session: session,
            sessionPolicy: .state(gameId: "game-1")
        )

        let payloadQuery = try XCTUnwrap(
            URLComponents(string: builtMessage.urlString)?
                .queryItems?
                .first(where: { $0.name == "payload" })?
                .value
        )
        let builtURL = try XCTUnwrap(URL(string: builtMessage.urlString))
        XCTAssertEqual(payloadQuery, encodedEnvelope)
        XCTAssertEqual(builtURL.scheme, "https")
        XCTAssertEqual(builtURL.host, "unluckysevens.app")
        XCTAssertEqual(builtURL.path, "/msg")
        XCTAssertEqual(builtMessage.payloadLength, encodedEnvelope.count)
        XCTAssertEqual(builtMessage.sessionPolicy, .state(gameId: "game-1"))
        XCTAssertEqual(builtMessage.summaryText, "Alex built a road.")
    }

    func testDecodePayloadReadsURLQuery() {
        let url = URL(string: "https://unluckysevens.app/msg?payload=url-payload")

        let decoded = TranscriptTransportSupport.decodePayload(from: url)

        XCTAssertEqual(decoded?.payload, "url-payload")
        XCTAssertEqual(decoded?.source, .url)
    }

    func testDecodePayloadReturnsNilWithoutURLPayload() {
        XCTAssertNil(TranscriptTransportSupport.decodePayload(from: nil))
        XCTAssertNil(TranscriptTransportSupport.decodePayload(from: URL(string: "https://unluckysevens.app/msg")))
    }

    func testPreferredStateSessionUsesSelectedBubbleSessionForMatchingGame() {
        let selectedSession = MSSession()
        let cachedSession = MSSession()
        let selectedMessage = MSMessage(session: selectedSession)

        let resolvedSession = TranscriptTransportSupport.preferredStateSession(
            gameId: "game-1",
            selectedMessage: selectedMessage,
            selectedGameId: "game-1",
            cachedSession: cachedSession
        )

        XCTAssertEqual(resolvedSession, selectedSession)
    }

    func testPreferredStateSessionFallsBackToCachedSessionWhenSelectedGameDoesNotMatch() {
        let selectedSession = MSSession()
        let cachedSession = MSSession()
        let selectedMessage = MSMessage(session: selectedSession)

        let resolvedSession = TranscriptTransportSupport.preferredStateSession(
            gameId: "game-1",
            selectedMessage: selectedMessage,
            selectedGameId: "game-2",
            cachedSession: cachedSession
        )

        XCTAssertEqual(resolvedSession, cachedSession)
    }

    func testSelectionSnapshotReportsURLDecodeSource() throws {
        let message = MSMessage(session: MSSession())
        message.url = URL(string: "https://unluckysevens.app/msg?payload=state-payload")

        let snapshot = TranscriptTransportSupport.selectionSnapshot(for: message)

        XCTAssertEqual(snapshot.messagePresence, "present")
        XCTAssertEqual(snapshot.payloadQueryPresence, "present")
        XCTAssertEqual(snapshot.payloadLength, "13")
        XCTAssertEqual(snapshot.decodeSource, TranscriptPayloadSource.url.label)
    }
}
