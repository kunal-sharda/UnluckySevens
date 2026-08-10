# Player Screen Capture Regression Follow-up

## Purpose and Outcome

Reproduce the questionable city-target and Game Information screenshots from a clean generated simulator build. If either defect remains, refine the narrowest shared presentation component and replace the affected device evidence without changing gameplay rules, board geometry, or the locked typography contract.

## Execution Settings

- Validation profile: `standard`
- Delivery posture: `direct`
- Rationale: the user explicitly requested a clean retry and authorized refinement only when the same visual defects reproduce.

## Context and Boundaries

- `DESIGN.md` owns the approved Physical Props language and SF Pro typography contract.
- The board-number token remains the sole approved serif exception.
- Games remains a labeled destination inside Players and Game Information, not a gameplay top-bar item.
- `ULS_CoreGame`, `ULS_Transport`, protocol fields, rules, and validation semantics are out of scope.
- Existing dirty-worktree changes belong to the user and must be preserved.

## Milestones / Plan of Work

1. Generate through `bash ./scripts/gen.sh`, build/install the latest app, and rerun the focused normal-turn XCUITest capture.
2. Extract and visually inspect the city-target and Game Information screenshots.
3. If either defect reproduces, refine the narrowest responsible SwiftUI component and repeat the focused capture once.
4. Run focused tests, standard completion validation, fresh review, and documentation freshness.

## Verification Contract and Fresh Review

<!-- verification-contract:start -->
| ID | Class | Source | Acceptance | Verification | Evidence | Status | Rationale |
| --- | --- | --- | --- | --- | --- | --- | --- |
| PCR-001 | observable | user request | A clean current-build capture establishes whether the prior city-target and Game Information defects reproduce | focused XCUITest plus extracted screenshot inspection | artifact:/tmp/uls-player-capture-retry/82D4651B-0697-4F22-82E2-571226C3C2D1.png; artifact:/tmp/uls-player-capture-retry/34E217BD-4937-4F77-834C-0036E57B4EF1.png | pass | Clean retry reproduced the board-covering city hint; the stale oversized Your Games action did not reproduce |
| PCR-002 | judgment | DESIGN.md and user request | Any reproduced treatment is refined to preserve board primacy, compact tabletop hierarchy, and the approved Games placement | direct screenshot inspection against approved visual language | artifact:/tmp/uls-player-capture-final-refined/926810C0-D32B-499B-B998-FD472F09B9E2.png; artifact:/tmp/uls-player-capture-final-refined/5E7ABE86-7AD6-4112-8670-2472A529C972.png | pass | Fresh product/UX re-review confirms the city board is unobstructed and Game Information shows complete player summaries and recap with compact Games placement |
| PCR-003 | mechanical | DESIGN.md | Typography remains SF Pro outside the locked board-number exception | existing typography guard and focused build/test | report:scripts.tests.test_harness_audit 21 of 21 pass; report:scripts/check-harness.py pass; report:Impeccable detector returned no findings | pass | The refinement adds no typography API and the repository guard remains green |
| PCR-004 | observable | docs/quality/qa.md | The final focused journey renders current source and retains stable turn geometry | focused XCUITest journey | report:XcodeBuildMCP testCaptureCityTargetAndGameInfoRegression passed in 57.973s | pass | Focused journey asserts complete visible player and recap containment plus the unobstructed city board |
<!-- verification-contract:end -->

<!-- fresh-review:start -->
| Reviewer | Required | Verdict | Evidence |
| --- | --- | --- | --- |
| constraint-auditor | yes | pass | report:re-review opened updated plan, diff, docs, and both refined PNGs; PCR-001 through PCR-004 pass with no blocker |
| architecture | no | not-applicable | Presentation-only scope does not change boundaries |
| behavioral | no | not-applicable | No rules or state-transition change intended |
| product-ux | yes | pass | report:re-review opened both refined PNGs and updated source; board primacy, visible Game Information content, Games placement, and typography pass |
<!-- fresh-review:end -->

## Living Record

### Progress

- Clean reproduction, both bounded refinement passes, focused regression coverage, fresh reviews, and completion validation are complete.

### Decisions

- 2026-07-30: Lock `standard` validation and `direct` delivery. Refinement is conditional on current-build device evidence.
- 2026-07-30: Keep the legacy board-hint capsule available to non-Physical layouts, but suppress it for Physical Props build-target modes because the fixed header already owns both initial and repeat-tap guidance.

### Discoveries

- The stale oversized `Your Games` treatment did not reproduce after explicit installation of the latest app bundle.
- The city-target banner did reproduce and was a current shared board hint, not stale simulator state.
- Fresh product/UX review found the corrected Game Information header still constrained to the shallow action-well height, leaving player information unusable; this is now a blocking refinement item.
- Game Information now derives an overlay height from its bounded three-to-four-player content, expands upward without remounting the board, and has observable assertions for a complete local-player row and recap.
- Fresh constraint and product/UX re-reviews pass after the second refinement. The pictured fixture has three players; source budgets a fourth row inside the same bounded scrollable overlay.
- The broader normal-turn catalog test reaches and captures both corrected states but later fails on the pre-existing Trade composer containment assertion; a narrow regression test now isolates and passes the requested states.

## Validation and Outcome

- `bash ./scripts/gen.sh`: pass after the final source change.
- `testCaptureCityTargetAndGameInfoRegression`: pass on iPhone 16e, iOS 26.0, in 57.973 seconds after the Game Information height refinement.
- Final second-round screenshots were extracted from the passing `.xcresult` and inspected directly.
- Broader `testOpenMessagesExtensionAndCaptureTurnGameplaySlice`: requested captures and new assertions pass before a later unrelated Trade composer containment failure.
- `python3 -m unittest scripts.tests.test_harness_audit`: 21/21 pass.
- `python3 scripts/check-harness.py`: pass with expected notices for unrelated active plans and pending fresh reviews in this plan.
- Impeccable detector: no findings.
- `make doc-freshness`: pass.
- Fresh constraint-auditor review: pass.
- Fresh product/UX review: pass.
- `make completion-gate PLAN=docs/exec-plans/active/player-screen-capture-regression-followup.md`: pass after granting Tuist/Xcode cache access; MessagesExtension simulator build succeeded.
