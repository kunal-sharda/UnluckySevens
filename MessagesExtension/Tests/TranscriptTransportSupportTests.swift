import Messages
import ULS_Transport
import XCTest
@testable import MessagesExtension

final class TranscriptTransportSupportTests: XCTestCase {
    func testBuildMessageIncludesPayloadQueryAndPreservesSessionPolicy() throws {
        let intent = JoinIntentV1(
            gameId: "game-1",
            anchorRev: 0,
            anchorHash: "hash-0",
            actor: "actor-1"
        )
        let payload = try jsonString(intent)
        let envelope = EnvelopeV1(kind: .intent, body: .intent(payload: payload))
        let encodedEnvelope = try encode(envelope)
        let session = MSSession()

        let builtMessage = try TranscriptTransportSupport.buildMessage(
            encodedEnvelope: encodedEnvelope,
            caption: "ULS INTENT join",
            summaryLabel: "INTENT actor=actor-1 kind=join a=r0",
            session: session,
            sessionPolicy: .state(gameId: "game-1"),
            summaryPayloadPrefix: "ulsenv:",
            includeSummaryPayloadMirror: false
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
        XCTAssertEqual(builtMessage.mirroredPayloadLength, 0)
        XCTAssertEqual(builtMessage.sessionPolicy, .state(gameId: "game-1"))
        XCTAssertEqual(builtMessage.summaryText, "INTENT actor=actor-1 kind=join a=r0")
    }

    func testBuildMessageMirrorsPayloadIntoMultilineSummaryWhenRequested() throws {
        let intent = JoinIntentV1(
            gameId: "game-1",
            anchorRev: 0,
            anchorHash: "hash-0",
            actor: "actor-1"
        )
        let payload = try jsonString(intent)
        let envelope = EnvelopeV1(kind: .intent, body: .intent(payload: payload))
        let encodedEnvelope = try encode(envelope)

        let builtMessage = try TranscriptTransportSupport.buildMessage(
            encodedEnvelope: encodedEnvelope,
            caption: "ULS INTENT join",
            summaryLabel: "INTENT actor=actor-1 kind=join a=r0",
            session: MSSession(),
            sessionPolicy: .new,
            summaryPayloadPrefix: "ulsenv:",
            includeSummaryPayloadMirror: true
        )

        XCTAssertEqual(
            builtMessage.summaryText,
            "INTENT actor=actor-1 kind=join a=r0\nulsenv:\(encodedEnvelope)"
        )
        XCTAssertEqual(builtMessage.mirroredPayloadLength, encodedEnvelope.count)
    }

    func testDecodePayloadOnlyUsesSummaryFallbackWhenExplicitlyAllowed() {
        let encodedEnvelope = try! encodedJoinEnvelope()
        let summaryText = "ulsenv:\(encodedEnvelope) INTENT actor=actor-1 kind=join a=r0"

        let disabledFallback = TranscriptTransportSupport.decodePayload(
            from: nil,
            summaryText: summaryText,
            summaryPayloadPrefix: "ulsenv:",
            allowSummaryFallback: false
        )
        let enabledFallback = TranscriptTransportSupport.decodePayload(
            from: nil,
            summaryText: summaryText,
            summaryPayloadPrefix: "ulsenv:",
            allowSummaryFallback: true
        )

        XCTAssertNil(disabledFallback)
        XCTAssertEqual(enabledFallback?.payload, encodedEnvelope)
        XCTAssertEqual(enabledFallback?.source, .summaryFallback)
    }

    func testDecodePayloadPrefersURLWhenSummaryMirrorAlsoExists() {
        let url = URL(string: "https://unluckysevens.app/msg?payload=url-payload")

        let decoded = TranscriptTransportSupport.decodePayload(
            from: url,
            summaryText: "STATE r0 p=lobby ulsenv:summary-payload",
            summaryPayloadPrefix: "ulsenv:",
            allowSummaryFallback: true
        )

        XCTAssertEqual(decoded?.payload, "url-payload")
        XCTAssertEqual(decoded?.source, .url)
    }

    func testDecodePayloadStillSupportsOlderMultilineSummaryMirror() {
        let encodedEnvelope = try! encodedJoinEnvelope()
        let decoded = TranscriptTransportSupport.decodePayload(
            from: nil,
            summaryText: "STATE r0 p=lobby\nulsenv:\(encodedEnvelope)",
            summaryPayloadPrefix: "ulsenv:",
            allowSummaryFallback: true
        )

        XCTAssertEqual(decoded?.payload, encodedEnvelope)
        XCTAssertEqual(decoded?.source, .summaryFallback)
    }

    func testDecodePayloadTrimsAppendedSummaryLabelFromMirroredPayload() throws {
        let encodedEnvelope = try encodedJoinEnvelope()

        let decoded = TranscriptTransportSupport.decodePayload(
            from: nil,
            summaryText: "ulsenv:\(encodedEnvelope) INTENT actor=actor-1 kind=join a=r0",
            summaryPayloadPrefix: "ulsenv:",
            allowSummaryFallback: true
        )

        XCTAssertEqual(decoded?.payload, encodedEnvelope)
        XCTAssertEqual(decoded?.source, .summaryFallback)
    }

    func testDecodePayloadIgnoresWhitespaceInsertedIntoMirroredSummaryPayload() throws {
        let intent = JoinIntentV1(
            gameId: "game-1",
            anchorRev: 0,
            anchorHash: "hash-0",
            actor: "actor-1"
        )
        let payload = try jsonString(intent)
        let envelope = EnvelopeV1(kind: .intent, body: .intent(payload: payload))
        let encodedEnvelope = try encode(envelope)
        let midpoint = encodedEnvelope.index(encodedEnvelope.startIndex, offsetBy: encodedEnvelope.count / 2)
        let spacedPayload = String(encodedEnvelope[..<midpoint]) + " \n" + String(encodedEnvelope[midpoint...])

        let decoded = TranscriptTransportSupport.decodePayload(
            from: nil,
            summaryText: "ulsenv:\(spacedPayload) INTENT actor=actor-1 kind=join a=r0",
            summaryPayloadPrefix: "ulsenv:",
            allowSummaryFallback: true
        )

        XCTAssertEqual(decoded?.payload, encodedEnvelope)
        XCTAssertEqual(decoded?.source, .summaryFallback)
    }

    func testResolveSessionPolicyLeavesRequestedPolicyAloneWhenDebugOverrideDisabled() {
        let policy = TranscriptTransportSupport.resolveSessionPolicy(
            requestedPolicy: .new,
            envelopeKind: .intent,
            useSingleSessionDebug: false,
            currentGameId: "game-1"
        )

        XCTAssertEqual(policy, .new)
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

    private func jsonString<T: Encodable>(_ value: T) throws -> String {
        let data = try JSONEncoder().encode(value)
        guard let string = String(data: data, encoding: .utf8) else {
            XCTFail("Expected UTF-8 JSON string")
            throw TestError.invalidJSONString
        }
        return string
    }

    private func encodedJoinEnvelope() throws -> String {
        let intent = JoinIntentV1(
            gameId: "game-1",
            anchorRev: 0,
            anchorHash: "hash-0",
            actor: "actor-1"
        )
        let payload = try jsonString(intent)
        let envelope = EnvelopeV1(kind: .intent, body: .intent(payload: payload))
        return try encode(envelope)
    }

    private enum TestError: Error {
        case invalidJSONString
    }
}
