import XCTest
import ULS_CoreGame
@testable import MessagesExtensionSupport

final class RecoveryLifecycleActionResolverTests: XCTestCase {
    func testPrepareAllowedActionsProducesCanonicalDrafts() throws {
        let base = makeTurnState()
        let proposed = try ULS_CoreGame.apply(
            intent: .proposeDraw(anchoredTo: base),
            to: base,
            actor: "A"
        )
        let cases: [(name: String, action: RecoveryLifecycleAction, state: CoreGameStateV1, actor: String)] = [
            ("resend", .resend, base, "A"),
            ("resign", .resign, base, "B"),
            ("propose draw", .proposeDraw, base, "B"),
            ("approve draw", .voteOnDraw(approve: true), proposed, "B"),
            ("reject draw", .voteOnDraw(approve: false), proposed, "B"),
            ("host end", .hostEnd, base, "A"),
        ]

        for testCase in cases {
            let draft = try RecoveryLifecycleActionResolver.prepare(
                action: testCase.action,
                state: testCase.state,
                actor: testCase.actor
            )

            XCTAssertEqual(draft.action, testCase.action, testCase.name)
            XCTAssertEqual(draft.fromState, testCase.state, testCase.name)
            XCTAssertEqual(draft.actor, testCase.actor, testCase.name)
            XCTAssertNoThrow(try validateCanonicalSnapshot(draft.resultingState), testCase.name)

            if testCase.action == .resend {
                XCTAssertEqual(draft.resultingState, testCase.state, testCase.name)
                XCTAssertTrue(draft.permitsRecoverySessionStart, testCase.name)
            } else {
                XCTAssertEqual(draft.resultingState.rev, testCase.state.rev + 1, testCase.name)
                XCTAssertFalse(draft.permitsRecoverySessionStart, testCase.name)
                XCTAssertNoThrow(
                    try validateTransition(
                        from: testCase.state,
                        to: draft.resultingState,
                        actor: testCase.actor
                    ),
                    testCase.name
                )
            }
        }

        let resigned = try RecoveryLifecycleActionResolver.prepare(
            action: .resign,
            state: base,
            actor: "B"
        )
        XCTAssertEqual(resigned.resultingState.resignedPlayers, ["B"])

        let hostEnded = try RecoveryLifecycleActionResolver.prepare(
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
        let cases: [(name: String, action: RecoveryLifecycleAction, state: CoreGameStateV1, actor: String, compatible: Bool)] = [
            ("unbound resend", .resend, base, "A", false),
            ("non-player resend", .resend, base, "observer", true),
            ("non-player resign", .resign, base, "observer", true),
            ("second draw proposal", .proposeDraw, proposed, "B", true),
            ("vote without proposal", .voteOnDraw(approve: true), base, "B", true),
            ("non-host end", .hostEnd, base, "B", true),
        ]

        for testCase in cases {
            XCTAssertFalse(
                RecoveryLifecycleActionResolver.isAvailable(
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
            RecoveryLifecycleActionResolver.shouldOfferDrawBeforeHostEnd(state: state)
        )
        XCTAssertFalse(
            RecoveryLifecycleActionResolver.shouldOfferDrawBeforeHostEnd(state: proposed)
        )
        XCTAssertFalse(
            RecoveryLifecycleActionResolver.shouldOfferDrawBeforeHostEnd(state: nil)
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
