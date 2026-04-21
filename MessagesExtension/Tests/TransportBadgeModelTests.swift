import XCTest
@testable import MessagesExtension

final class TransportBadgeModelTests: XCTestCase {
    func testBuildUsesURLToneWhenURLPayloadDecodes() {
        let badge = TransportBadgeModel.build(
            triggerLabel: TranscriptSelectionTrigger.didSelect.label,
            snapshot: TranscriptSelectionSnapshot(
                messagePresence: "present",
                urlPresence: "present",
                urlString: "https://unluckysevens.app/msg?payload=abc",
                payloadQueryPresence: "present",
                payloadLength: "3",
                summaryText: "-",
                layoutCaption: "-",
                sessionPresence: "present",
                decodeSource: TranscriptPayloadSource.url.label
            )
        )

        XCTAssertEqual(badge.text, "URL · didSelect")
        XCTAssertEqual(badge.tone, .url)
    }

    func testBuildUsesSummaryToneWhenSummaryFallbackDecodes() {
        let badge = TransportBadgeModel.build(
            triggerLabel: TranscriptSelectionTrigger.didReceive.label,
            snapshot: TranscriptSelectionSnapshot(
                messagePresence: "present",
                urlPresence: "missing",
                urlString: "-",
                payloadQueryPresence: "missing",
                payloadLength: "12",
                summaryText: "STATE ulsenv:payload",
                layoutCaption: "-",
                sessionPresence: "present",
                decodeSource: TranscriptPayloadSource.summaryFallback.label
            )
        )

        XCTAssertEqual(badge.text, "SUMMARY · didReceive")
        XCTAssertEqual(badge.tone, .summary)
    }

    func testBuildUsesMissingToneWhenNoPayloadIsAvailable() {
        let badge = TransportBadgeModel.build(
            triggerLabel: TranscriptSelectionTrigger.selectionPoll.label,
            snapshot: TranscriptSelectionSnapshot(
                messagePresence: "present",
                urlPresence: "missing",
                urlString: "-",
                payloadQueryPresence: "missing",
                payloadLength: "-",
                summaryText: "-",
                layoutCaption: "-",
                sessionPresence: "present",
                decodeSource: "-"
            )
        )

        XCTAssertEqual(badge.text, "MISSING · selectionPoll")
        XCTAssertEqual(badge.tone, .missing)
    }
}
