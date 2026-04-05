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
        XCTAssertEqual(payloadQuery, encodedEnvelope)
        XCTAssertEqual(builtMessage.payloadLength, encodedEnvelope.count)
        XCTAssertEqual(builtMessage.sessionPolicy, .state(gameId: "game-1"))
        XCTAssertEqual(builtMessage.summaryText, "INTENT actor=actor-1 kind=join a=r0")
    }

    func testBuildMessageMirrorsPayloadIntoSummaryWhenRequested() throws {
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

        XCTAssertEqual(builtMessage.summaryText, "ulsenv:\(encodedEnvelope)")
    }

    func testDecodePayloadOnlyUsesSummaryFallbackWhenExplicitlyAllowed() {
        let summaryText = "ulsenv:{\"kind\":\"STATE\"}"

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
        XCTAssertEqual(enabledFallback?.payload, "{\"kind\":\"STATE\"}")
        XCTAssertEqual(enabledFallback?.source, .summaryFallback)
    }

    private func jsonString<T: Encodable>(_ value: T) throws -> String {
        let data = try JSONEncoder().encode(value)
        guard let string = String(data: data, encoding: .utf8) else {
            XCTFail("Expected UTF-8 JSON string")
            throw TestError.invalidJSONString
        }
        return string
    }

    private enum TestError: Error {
        case invalidJSONString
    }
}
