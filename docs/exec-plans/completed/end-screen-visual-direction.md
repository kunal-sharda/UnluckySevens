# End Screen Visual Direction

> Superseded 2026-07-26 by [Recovery and Terminal Lifecycle — Pass 2 UI Polish](recovery-terminal-lifecycle-pass-2-ui-polish.md). The rejected experiments and their evidence remain here as historical calibration; no direction from this plan was productionized.

## Purpose and Outcome

Create a dedicated game-over composition that preserves the final live board, clearly names the winner, shows every final score, and retains the last-turn recap. The first slice is a DEBUG-only Physical Props candidate using the existing deterministic game-over fixture; production routing waits for user approval.

## Execution Settings

- Validation profile: `standard`
- Delivery posture: `checkpointed`
- Rationale: The required information is settled in [UI flows](../../product-specs/ui-flows.md), but the visual hierarchy and proportion are a new judgment-heavy direction.

## Context and Boundaries

- [UI flows](../../product-specs/ui-flows.md) owns the required final board, winner, score summary, and recap behavior.
- [Design](../../../DESIGN.md) owns the compact Physical Props language and requires the final-score treatment not to obscure the board result.
- Core and query outputs remain the only source of winner, score, awards, and recap data.
- SpriteKit continues to own one live board; the end screen must not create, snapshot, or remount a second board.
- No new gameplay action, transport field, or protocol behavior is in scope.
- Existing dirty lobby work is unrelated and must remain untouched.

## Milestones / Plan of Work

1. Add a pure end-screen presentation model derived from the existing game-over projection.
2. Build one compact Physical Props result rail that names the winner, ranks final scores, and includes the recap.
3. Route the candidate only through the DEBUG Physical Props game-over fixture and add focused model/layout assertions.
4. Generate the project, build, run the focused game-over UX Lab capture, inspect one representative normal-size still, and pause for user approval.
5. After approval, production-route the composition, add accessibility-size evidence, run required fresh reviews, and execute the completion gate.

## Approval Gate

Authority: user.

Proof: one freshly installed normal-size game-over capture using the real board and deterministic three-player fixture. The board, winner, every score, and recap must all be visible. Two visual rounds are available by default.

Stop rule: while approval is pending, do not route the end screen in Release, run fresh specialist review, or run the completion gate.

## Verification Contract and Fresh Review

<!-- verification-contract:start -->
| ID | Class | Source | Acceptance | Verification | Evidence | Status | Rationale |
| --- | --- | --- | --- | --- | --- | --- | --- |
| END-001 | mechanical | Core and query ownership | Winner, final scores, awards, and recap are derived from the selected canonical state with no UI-owned rules | focused presentation tests and code inspection | command:GameScreenModelBuilderTests-11-pass | pass | The end model is projected from canonical state plus the existing secrecy-safe game-info projection |
| END-002 | observable | UI flows | One final live board remains visible with winner, all final scores, and last-turn recap | focused UX Lab journey and inspected still | report:pending-round-two | pending | Round-one proof was mechanically valid but its visual direction was rejected |
| END-003 | observable | accessibility | The result does not rely on color alone and remains readable at supported accessibility sizes | focused labels and accessibility-size capture | report:pending | pending | Runs after visual approval |
| END-004 | judgment | user | The compact result composition is strong enough to productionize | explicit user verdict after capture | report:pending | pending | Approval gate |
<!-- verification-contract:end -->

<!-- fresh-review:start -->
| Reviewer | Required | Verdict | Evidence |
| --- | --- | --- | --- |
| constraint-auditor | yes | pending | report:pending |
| architecture | no | not-applicable | Presentation-only projection and composition |
| behavioral | no | not-applicable | No gameplay or transport behavior change |
| product-ux | yes | pending | Runs after user-approved production routing |
<!-- fresh-review:end -->

## Living Record

### Progress

- [x] Existing game-over projection, fixture, shell routing, and unused score-strip baseline inspected.
- [x] Standard validation profile and checkpointed delivery posture locked.
- [x] DEBUG Physical Props candidate implemented and captured.
- [ ] Tutorial-placard round-two candidate implemented and captured.
- [ ] User approval recorded.
- [ ] Approved direction production-routed and verified.

### Decisions

- 2026-07-26: The candidate keeps the final board as the dominant object and uses the former lower action area for results instead of placing a centered modal over the island.
- 2026-07-26: The first checkpoint is the existing representative three-player game-over fixture; alternate winners, a four-player stress state, and accessibility sizes follow only after the core hierarchy is approved.
- 2026-07-26: The user rejected the lower beige score rail as “back to the form builder.” It is invalid visual evidence and must not be productionized.
- 2026-07-26: Round two uses the tutorial Strategy composition as its explicit reference: one deliberate centered tabletop placard over a dimmed live board, without a segmented scoreboard or form-like player cells.
- 2026-07-26: The user also rejected the tutorial Strategy card as Claude/Codex-generated. The shared failure is now explicit: no large cream rounded container, no repeated icon-title-paragraph rows, and no evenly segmented score cells. The proposed replacement is board-specific tabletop storytelling: the tutorial uses three real lesson props directly on felt, while game over uses one shared 0–10 victory track with labeled player markers and a winner flag.
- 2026-07-26: User calibration retained the card metaphor but changed its register: it should look like a physical player-aid or cheat-sheet card from the game box, not an application card. Round two may use one printed stock object with restrained corners, diagram-led information, terse rule copy, and asymmetric print composition; it must avoid stacked feature rows and generic modal-card styling. The end state should feel like the reverse or result side of the same tabletop artifact.

### Discoveries

- The existing game-over route suppresses actions and preserves the live board, but falls back to the legacy command shell.
- `GameFinalScoreStripView` exists but is not connected to the game shell and accepts only an opaque score string.
- The deterministic `game-over` UX Lab fixture already contains a winner and last-turn recap suitable for the checkpoint.
- The first candidate capture exposed a stale fixture total: its declared 10-point winner projected only 8 points. The DEBUG fixture was corrected before checkpoint evidence was accepted.
- The first geometric assertion treated the full teal board host as the island and rejected the intentional lower-zone overlap. The corrected assertion proves that the result rail stays below the board midpoint and below one third of its height; direct inspection confirms no tile or piece is obscured.
- The tutorial does not contain a true game-over state. Its final `Strategy` step is the remembered visual: a single centered cream editorial placard over the dimmed production table. The deterministic tutorial checkpoint now boots from a clean lobby fixture and passes.
- The tutorial and rejected end rail share the same generic component grammar even though their placement differs. Reusing the tutorial card’s shell would preserve the problem rather than solve it.

## Validation and Outcome

Rejected round-one validation:

- `bash ./scripts/gen.sh`: passed.
- Debug Messages simulator build: passed.
- Focused `GameScreenModelBuilderTests`: 11 tests, 0 failures.
- Freshly installed focused end-screen XCUITest: 1 test, 0 failures.
- Rejected still: `/private/tmp/UnluckySevensEndScreenCandidate/end-screen-candidate.jpg`.
- `git diff --check`: passed.
- `make doc-freshness`: passed with this active plan updated; Tier 1 owners remain unchanged because the candidate implements their existing end-state contract and is not production-routed.

Reference validation:

- Deterministic tutorial Strategy checkpoint XCUITest: 1 test, 0 failures.
- Inspected reference: `/private/tmp/UnluckySevensEndScreenCandidate/tutorial-strategy-reference.jpg`.

Round-two evidence, user approval, Release routing, accessibility-size evidence, fresh review, and the completion gate remain pending by design.
