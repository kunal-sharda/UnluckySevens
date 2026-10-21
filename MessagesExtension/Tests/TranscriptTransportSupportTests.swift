import Messages
import UIKit
import XCTest
@testable import MessagesExtensionSupport

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
        XCTAssertEqual(builtURL.host, "ksharda.me")
        XCTAssertEqual(builtURL.path, "/unluckysevens/msg")
        XCTAssertEqual(builtMessage.payloadLength, encodedEnvelope.count)
        XCTAssertEqual(builtMessage.sessionPolicy, .state(gameId: "game-1"))
        XCTAssertEqual(builtMessage.summaryText, "Alex built a road.")
        XCTAssertNil((builtMessage.message.layout as? MSMessageTemplateLayout)?.image)
    }

    func testBuildMessageSetsImageWhenProvided() throws {
        let image = UIGraphicsImageRenderer(size: CGSize(width: 24, height: 16)).image { _ in
            UIColor.red.setFill()
            UIRectFill(CGRect(x: 0, y: 0, width: 24, height: 16))
        }

        let builtMessage = try TranscriptTransportSupport.buildMessage(
            encodedEnvelope: "encoded-payload",
            caption: "Unlucky Sevens: Game Started",
            summaryLabel: "4 players are entering setup.",
            image: image,
            session: MSSession(),
            sessionPolicy: .state(gameId: "game-1")
        )

        let layout = try XCTUnwrap(builtMessage.message.layout as? MSMessageTemplateLayout)
        XCTAssertEqual(layout.image?.size.width ?? 0, 24, accuracy: 0.5)
        XCTAssertEqual(layout.image?.size.height ?? 0, 16, accuracy: 0.5)
    }

    func testDecodePayloadReadsURLQuery() {
        let url = URL(string: "https://ksharda.me/unluckysevens/msg?payload=url-payload")

        let decoded = TranscriptTransportSupport.decodePayload(from: url)

        XCTAssertEqual(decoded?.payload, "url-payload")
        XCTAssertEqual(decoded?.source, .url)
    }

    func testDecodePayloadPreservesPreTestFlightLegacyHostCompatibility() {
        let url = URL(string: "https://unluckysevens.app/msg?payload=legacy-payload")

        let decoded = TranscriptTransportSupport.decodePayload(from: url)

        XCTAssertEqual(decoded?.payload, "legacy-payload")
        XCTAssertEqual(decoded?.source, .url)
    }

    func testDecodePayloadReturnsNilWithoutURLPayload() {
        XCTAssertNil(TranscriptTransportSupport.decodePayload(from: nil))
        XCTAssertNil(TranscriptTransportSupport.decodePayload(from: URL(string: "https://ksharda.me/unluckysevens/msg")))
    }

    func testSelectionSnapshotReportsURLDecodeSource() throws {
        let message = MSMessage(session: MSSession())
        message.url = URL(string: "https://ksharda.me/unluckysevens/msg?payload=state-payload")

        let snapshot = TranscriptTransportSupport.selectionSnapshot(for: message)

        XCTAssertEqual(snapshot.messagePresence, "present")
        XCTAssertEqual(snapshot.payloadQueryPresence, "present")
        XCTAssertEqual(snapshot.payloadLength, "13")
        XCTAssertEqual(snapshot.sessionPresence, "present")
        XCTAssertEqual(snapshot.decodeSource, TranscriptPayloadSource.url.label)
    }

    func testSelectionSnapshotReportsEveryMissingHostBoundaryField() {
        let snapshot = TranscriptTransportSupport.selectionSnapshot(for: nil)

        XCTAssertEqual(snapshot.messagePresence, "missing")
        XCTAssertEqual(snapshot.urlPresence, "missing")
        XCTAssertEqual(snapshot.urlString, "-")
        XCTAssertEqual(snapshot.payloadQueryPresence, "missing")
        XCTAssertEqual(snapshot.payloadLength, "-")
        XCTAssertEqual(snapshot.summaryText, "-")
        XCTAssertEqual(snapshot.layoutCaption, "-")
        XCTAssertEqual(snapshot.sessionPresence, "missing")
        XCTAssertEqual(snapshot.decodeSource, "-")
    }

    func testHostBoundaryDiagnosticCapturesLifecycleSessionPayloadAndIdentity() {
        let message = MSMessage(session: MSSession())
        message.url = URL(string: "https://ksharda.me/unluckysevens/msg?payload=state-payload")

        let diagnostic = TranscriptTransportSupport.hostBoundaryDiagnostic(
            trigger: .didSelect,
            message: message,
            localParticipantIdentifier: "participant-a"
        )

        XCTAssertEqual(
            diagnostic,
            "trigger=didSelect;participant=known;message=present;url=present;payload=present;payloadLength=13;session=present;source=URL"
        )
        XCTAssertFalse(diagnostic.contains("participant-a"))
    }
}
