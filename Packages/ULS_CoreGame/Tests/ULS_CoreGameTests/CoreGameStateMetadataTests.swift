import XCTest
@testable import ULS_CoreGame

final class CoreGameStateMetadataTests: XCTestCase {
    func testPlayerDisplayNamesAreNormalizedAndAffectCanonicalHash() {
        let base = makeLobbyState(playerDisplayNamesByPlayer: [:]).rehashed()
        let renamed = makeLobbyState(
            playerDisplayNamesByPlayer: ["host": "  Kunal   Sharma  "]
        ).rehashed()

        XCTAssertEqual(renamed.playerDisplayNamesByPlayer["host"], "Kunal Sharma")
        XCTAssertNotEqual(base.stateHash, renamed.stateHash)
    }

    private func makeLobbyState(playerDisplayNamesByPlayer: [String: String]) -> CoreGameStateV1 {
        CoreGameStateV1(
            gameId: "core-state-metadata",
            rev: 0,
            prevHash: nil,
            stateHash: "",
            roster: ["host"],
            currentPlayer: "host",
            playerDisplayNamesByPlayer: playerDisplayNamesByPlayer,
            phase: .lobby,
            seed: nil,
            diceRngState: nil,
            resourcesByPlayer: ["host": .zero],
            boardRules: nil,
            board: nil
        )
    }
}
