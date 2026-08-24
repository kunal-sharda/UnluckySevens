import XCTest
import ULS_CoreGame
@testable import MessagesExtensionSupport

final class GameLifecycleActionResolverTests: XCTestCase {
    func testPrepareAllowedActionsProducesCanonicalDrafts() throws {
        let base = makeTurnState()
        let proposed = try ULS_CoreGame.apply(
            intent: .proposeDraw(anchoredTo: base),
            to: base,
            actor: "A"
        )
        let cases: [(name: String, action: GameLifecycleAction, state: CoreGameStateV1, actor: String)] = [
            ("resign", .resign, base, "B"),
            ("propose draw", .proposeDraw, base, "B"),
            ("approve draw", .voteOnDraw(approve: true), proposed, "B"),
            ("reject draw", .voteOnDraw(approve: false), proposed, "B"),
            ("host end", .hostEnd, base, "A"),
        ]

        for testCase in cases {
            let draft = try GameLifecycleActionResolver.prepare(
                action: testCase.action,
                state: testCase.state,
                actor: testCase.actor
            )

            XCTAssertEqual(draft.action, testCase.action, testCase.name)
            XCTAssertEqual(draft.fromState, testCase.state, testCase.name)
            XCTAssertEqual(draft.actor, testCase.actor, testCase.name)
            XCTAssertNoThrow(try validateCanonicalSnapshot(draft.resultingState), testCase.name)

            XCTAssertEqual(draft.resultingState.rev, testCase.state.rev + 1, testCase.name)
            XCTAssertNoThrow(
                try validateTransition(
                    from: testCase.state,
                    to: draft.resultingState,
                    actor: testCase.actor
                ),
                testCase.name
            )
        }

        let resigned = try GameLifecycleActionResolver.prepare(
            action: .resign,
            state: base,
            actor: "B"
        )
        XCTAssertEqual(resigned.resultingState.resignedPlayers, ["B"])

        let hostEnded = try GameLifecycleActionResolver.prepare(
            action: .hostEnd,
            state: base,
            actor: "A"
        )
        XCTAssertEqual(hostEnded.resultingState.gameResult?.reason, .hostEnded)
    }

    func testAvailabilityDeniesIncompatibleConversationAndIllegalActions() throws {
        let base = makeTurnState()
        let proposed = try ULS_CoreGame.apply(
            intent: .proposeDraw(anchoredTo: base),
            to: base,
            actor: "A"
        )
        let cases: [(name: String, action: GameLifecycleAction, state: CoreGameStateV1, actor: String, compatible: Bool)] = [
            ("non-player resign", .resign, base, "observer", true),
            ("second draw proposal", .proposeDraw, proposed, "B", true),
            ("vote without proposal", .voteOnDraw(approve: true), base, "B", true),
            ("non-host end", .hostEnd, base, "B", true),
        ]

        for testCase in cases {
            XCTAssertFalse(
                GameLifecycleActionResolver.isAvailable(
                    action: testCase.action,
                    state: testCase.state,
                    actor: testCase.actor,
                    hasCompatibleActiveConversation: testCase.compatible
                ),
                testCase.name
            )
        }
    }

    func testDrawOfferPromptOnlyAppearsBeforeAnyDrawAttempt() throws {
        let state = makeTurnState()
        let proposed = try ULS_CoreGame.apply(
            intent: .proposeDraw(anchoredTo: state),
            to: state,
            actor: "A"
        )

        XCTAssertTrue(
            GameLifecycleActionResolver.shouldOfferDrawBeforeHostEnd(state: state)
        )
        XCTAssertFalse(
            GameLifecycleActionResolver.shouldOfferDrawBeforeHostEnd(state: proposed)
        )
        XCTAssertFalse(
            GameLifecycleActionResolver.shouldOfferDrawBeforeHostEnd(state: nil)
        )
    }

    private func makeTurnState() -> CoreGameStateV1 {
        CoreGameStateV1(
            gameId: "recovery-lifecycle",
            rev: 7,
            prevHash: "hash-6",
            stateHash: "",
            roster: ["A", "B", "C"],
            currentPlayer: "A",
            phase: .turn,
            seed: 1,
            diceRngState: 2,
            resourcesByPlayer: ["A": .zero, "B": .zero, "C": .zero],
            turnState: TurnStateV1(
                step: .afterRoll,
                lastRoll: DiceRollV1(d1: 3, d2: 4)
            )
        ).rehashed()
    }
}
