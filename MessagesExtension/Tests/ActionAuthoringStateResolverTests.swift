import ULS_CoreGame
import XCTest
@testable import MessagesExtension

final class ActionAuthoringStateResolverTests: XCTestCase {
    func testResolvePrefersLatestKnownStateWhenItIsNewer() {
        let selectedState = makeTurnState(rev: 4, currentPlayer: "host-player")
        let latestState = makeTurnState(rev: 5, currentPlayer: "guest-player")

        let resolution = ActionAuthoringStateResolver.resolve(
            gameId: selectedState.gameId,
            selectedState: selectedState,
            latestKnownStatesByGameId: [selectedState.gameId: latestState],
            localLedgerState: nil
        )

        XCTAssertEqual(resolution.state?.rev, latestState.rev)
        XCTAssertEqual(resolution.state?.stateHash, latestState.stateHash)
        XCTAssertEqual(resolution.source, .latestKnownState)
        XCTAssertTrue(resolution.prefersRecoveredState)
    }

    func testResolvePrefersLatestKnownStateWhenRevisionMatchesButHashDiffers() {
        let firstSibling = makeTurnState(rev: 5, currentPlayer: "host-player")
        let secondSibling = makeTurnState(rev: 5, currentPlayer: "guest-player")
        let selectedState = firstSibling.stateHash < secondSibling.stateHash
            ? firstSibling
            : secondSibling
        let latestState = firstSibling.stateHash > secondSibling.stateHash
            ? firstSibling
            : secondSibling

        let resolution = ActionAuthoringStateResolver.resolve(
            gameId: selectedState.gameId,
            selectedState: selectedState,
            latestKnownStatesByGameId: [selectedState.gameId: latestState],
            localLedgerState: nil
        )

        XCTAssertEqual(resolution.state?.rev, latestState.rev)
        XCTAssertEqual(resolution.state?.stateHash, latestState.stateHash)
        XCTAssertEqual(resolution.source, .latestKnownState)
        XCTAssertTrue(resolution.prefersRecoveredState)
    }

    func testResolveKeepsSelectedStateWhenItIsNewest() {
        let selectedState = makeTurnState(rev: 6, currentPlayer: "host-player")
        let olderLatest = makeTurnState(rev: 5, currentPlayer: "guest-player")
        let olderLocal = makeTurnState(rev: 4, currentPlayer: "guest-player")

        let resolution = ActionAuthoringStateResolver.resolve(
            gameId: selectedState.gameId,
            selectedState: selectedState,
            latestKnownStatesByGameId: [selectedState.gameId: olderLatest],
            localLedgerState: olderLocal
        )

        XCTAssertEqual(resolution.state?.rev, selectedState.rev)
        XCTAssertEqual(resolution.state?.stateHash, selectedState.stateHash)
        XCTAssertEqual(resolution.source, .selectedState)
        XCTAssertFalse(resolution.prefersRecoveredState)
    }

    func testResolveFallsBackToLocalLedgerState() {
        let localLedgerState = makeTurnState(rev: 3, currentPlayer: "guest-player")

        let resolution = ActionAuthoringStateResolver.resolve(
            gameId: localLedgerState.gameId,
            selectedState: nil,
            latestKnownStatesByGameId: [:],
            localLedgerState: localLedgerState
        )

        XCTAssertEqual(resolution.state?.rev, localLedgerState.rev)
        XCTAssertEqual(resolution.state?.stateHash, localLedgerState.stateHash)
        XCTAssertEqual(resolution.source, .localLedgerState)
        XCTAssertTrue(resolution.prefersRecoveredState)
    }

    private func makeTurnState(rev: Int, currentPlayer: String) -> CoreGameStateV1 {
        CoreGameStateV1(
            gameId: "action-authoring-state",
            rev: rev,
            prevHash: rev == 0 ? nil : "hash-\(rev - 1)",
            stateHash: "",
            roster: ["host-player", "guest-player"],
            currentPlayer: currentPlayer,
            phase: .turn,
            seed: 1,
            diceRngState: UInt64(rev),
            robberRngState: UInt64(rev + 10),
            resourcesByPlayer: [
                "host-player": ResourceHandV1(wood: rev),
                "guest-player": .zero,
            ],
            turnState: TurnStateV1(step: .afterRoll, lastRoll: DiceRollV1(d1: 3, d2: 4))
        ).rehashed()
    }
}
