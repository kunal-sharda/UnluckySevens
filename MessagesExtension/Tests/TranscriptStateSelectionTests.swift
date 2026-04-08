import ULS_CoreGame
import XCTest
@testable import MessagesExtension

final class TranscriptStateSelectionTests: XCTestCase {
    func testResolvePromotesNewerIncomingState() {
        let stateV1 = makeTurnState(rev: 1)
        let stateV2 = makeTurnState(rev: 2)

        let result = TranscriptStateSelection.resolve(
            decodedState: stateV2,
            latestKnownStatesByGameId: ["state-selection": stateV2],
            activeState: stateV1,
            activeSource: .selectedBubble,
            source: .url,
            trigger: .didReceive
        )

        XCTAssertEqual(result.preferredState.rev, 2)
        XCTAssertTrue(result.shouldActivate)
        XCTAssertEqual(result.selectionStatus, "Decoded STATE rev2 via URL")
        XCTAssertTrue(result.shouldShowLatestUpdateNotice)
        XCTAssertFalse(result.redirectedToLatestKnown)
    }

    func testResolveRedirectsOlderBubbleSelectionToLatestKnownState() {
        let stateV1 = makeTurnState(rev: 1)
        let stateV2 = makeTurnState(rev: 2)

        let result = TranscriptStateSelection.resolve(
            decodedState: stateV1,
            latestKnownStatesByGameId: ["state-selection": stateV2],
            activeState: stateV2,
            activeSource: .selectedBubble,
            source: .summaryFallback,
            trigger: .didSelect
        )

        XCTAssertEqual(result.preferredState.rev, 2)
        XCTAssertFalse(result.shouldActivate)
        XCTAssertEqual(result.selectionStatus, "Opened latest STATE rev2 via summary fallback")
        XCTAssertTrue(result.shouldShowLatestUpdateNotice)
        XCTAssertTrue(result.redirectedToLatestKnown)
    }

    func testRecordingKeepsNewestKnownStateByRevision() {
        let stateV1 = makeTurnState(rev: 1)
        let stateV3 = makeTurnState(rev: 3)

        let recorded = TranscriptStateSelection.recording(
            stateV3,
            in: ["state-selection": stateV1]
        )

        XCTAssertEqual(recorded["state-selection"]?.rev, 3)
    }

    private func makeTurnState(rev: Int) -> CoreGameStateV1 {
        CoreGameStateV1(
            gameId: "state-selection",
            rev: rev,
            prevHash: rev == 0 ? nil : "hash-\(rev - 1)",
            stateHash: "",
            roster: ["host-player", "guest-player"],
            currentPlayer: rev.isMultiple(of: 2) ? "guest-player" : "host-player",
            phase: .turn,
            seed: 1,
            diceRngState: UInt64(rev),
            robberRngState: UInt64(rev + 10),
            resourcesByPlayer: [
                "host-player": .zero,
                "guest-player": .zero,
            ],
            turnState: TurnStateV1(step: .afterRoll, lastRoll: DiceRollV1(d1: 3, d2: 4))
        ).rehashed()
    }
}
