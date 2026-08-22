import XCTest
import ULS_CoreGame
@testable import MessagesExtensionSupport

final class RecoveryStatePublicationResolverTests: XCTestCase {
    func testResolveReturnsByteEquivalentCanonicalStateWithoutAdvancingRevision() throws {
        let state = makeState()

        let resolved = try RecoveryStatePublicationResolver.resolve(
            state: state,
            actor: "host"
        )

        XCTAssertEqual(resolved, state)
        XCTAssertEqual(resolved.rev, state.rev)
        XCTAssertEqual(resolved.stateHash, state.stateHash)
        let encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys
        XCTAssertEqual(try encoder.encode(resolved), try encoder.encode(state))
    }

    func testResolveRejectsNonParticipantAndInvalidHash() {
        let state = makeState()

        XCTAssertThrowsError(
            try RecoveryStatePublicationResolver.resolve(
                state: state,
                actor: "observer"
            )
        ) {
            XCTAssertEqual($0 as? CoreGameError, .actorMismatch)
        }

        let invalid = CoreGameStateV1(
            gameId: state.gameId,
            rev: state.rev,
            prevHash: state.prevHash,
            stateHash: "invalid",
            roster: state.roster,
            currentPlayer: state.currentPlayer,
            phase: state.phase,
            seed: state.seed,
            diceRngState: state.diceRngState,
            resourcesByPlayer: state.resourcesByPlayer,
            turnState: state.turnState
        )
        XCTAssertThrowsError(
            try RecoveryStatePublicationResolver.resolve(
                state: invalid,
                actor: "host"
            )
        ) {
            XCTAssertEqual($0 as? CoreGameError, .invalidStateHash)
        }
    }

    private func makeState() -> CoreGameStateV1 {
        CoreGameStateV1(
            gameId: "recovery-publication",
            rev: 7,
            prevHash: "hash-6",
            stateHash: "",
            roster: ["host", "guest"],
            currentPlayer: "guest",
            phase: .turn,
            seed: 1,
            diceRngState: 2,
            resourcesByPlayer: ["host": .zero, "guest": .zero],
            turnState: TurnStateV1(
                step: .afterRoll,
                lastRoll: DiceRollV1(d1: 3, d2: 4)
            )
        ).rehashed()
    }
}
