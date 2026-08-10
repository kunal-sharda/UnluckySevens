# Tutorial Piece Validity

## Purpose and Outcome

Make every shipping tutorial fixture use a legal Catan piece position. Setup placement must continue through the real reducer, later screens must derive their pieces from a completed legal setup plus legal build actions, and regression coverage must reject disconnected roads, distance violations, impossible post-setup piece counts, and award claims unsupported by the rendered roads.

## Execution Settings

- Validation profile: `standard`
- Delivery posture: `direct`
- Rationale: The defect is concrete and the requested correction is settled, but it changes the player-visible tutorial board and therefore needs focused unit, simulator, and fresh-review evidence.

## Context and Boundaries

- `ULS_CoreGame` remains the sole owner of setup and build legality.
- The tutorial composer remains local-only and never publishes its fixture states.
- The generated resource/number board and locked board-number typography remain unchanged.
- The fix must preserve all seventeen tutorial routes and existing production component composition.
- [UI flows](../../product-specs/ui-flows.md), [Design](../../../DESIGN.md), and [QA](../../quality/qa.md) remain the owner documents.

## Milestones / Plan of Work

1. Replace the disconnected static piece maps with a deterministic position derived through Core setup and build reducers.
2. Add fixture-level assertions for every tutorial step, including topology, ownership connectivity, setup completeness, and award consistency.
3. Generate canonically, run focused tests, capture all tutorial screens, inspect representative changed boards, obtain fresh review, and pass the standard completion gate.

## Verification Contract and Fresh Review

<!-- verification-contract:start -->
| ID | Class | Source | Acceptance | Verification | Evidence | Status | Rationale |
| --- | --- | --- | --- | --- | --- | --- | --- |
| TPV-001 | mechanical | user request and Core rules | Every tutorial fixture has in-range, non-overlapping buildings; legal settlement distance; and every owned road component anchored to an owned building | focused MessagesExtension unit tests over all tutorial steps | `GameTutorialStateComposerTests` 4 tests passed again in `/private/tmp/UnluckySevensTutorialValidityRefresh20260805.xcresult`; file:MessagesExtension/Tests/GameTutorialStateComposerTests.swift | pass | All sixteen lesson states pass topology and ownership traversal assertions |
| TPV-002 | mechanical | user clarification | Every post-setup tutorial fixture is derived from a completed legal setup and has award metadata supported by its rendered pieces | focused composer provenance and invariant tests | file:MessagesExtension/Sources/Features/Tutorial/GameTutorialStateComposer.swift; `/private/tmp/UnluckySevensTutorialPieceUnit-20260803-final.xcresult` | pass | Tests expose the exact completed Core setup, verify the Core-built road/city deltas, and prove both award fields against piece and knight counts |
| TPV-003 | mechanical | AGENTS.md boundary | Tutorial composition delegates setup and build legality to ULS_CoreGame without adding a second gameplay rules engine | scoped diff and focused tests | scoped diff inspection; Core setup and turn `apply` calls; focused test run passed | pass | Production code selects only from Core legal queries and applies Core intents |
| TPV-004 | observable | existing tutorial flow | All seventeen tutorial screens remain navigable and render the corrected production board without a crash or missing lesson screen | full tutorial XCUITest capture and screenshot inspection | passing `testCaptureEveryTutorialScreen`; file:output/tutorial-piece-validity-2026-08-05/manifest.json | pass | Fresh-device rerun captured Navigation plus all sixteen lessons; full-resolution inspection covered settlement, connected road, midgame build, robber move, and victim frames |
| TPV-005 | mechanical | repository workflow | Generation, build, diff hygiene, and documentation freshness pass | repository commands | `bash ./scripts/gen.sh`; escalated `make build`; `git diff --check`; `make doc-freshness` | pass | Canonical generation and generic simulator build passed; diff and documentation gates are clean |
<!-- verification-contract:end -->

<!-- fresh-review:start -->
| Reviewer | Required | Verdict | Evidence |
| --- | --- | --- | --- |
| constraint-auditor | yes | pass | Fresh Terra re-audit opened the final unit/UI result bundles, all seventeen attachment records, representative frames, current diff, and tests; TPV-001 through TPV-004 passed with no implementation blocker |
| architecture | no | not-applicable | No module or protocol boundary change planned |
| behavioral | yes | pass | Fresh Terra re-review independently inspected the four-test result bundle and verified exact completed-setup provenance, Core build deltas, award consistency, and honest two-victim robber state |
| product-ux | yes | pass | Fresh Terra review inspected all seventeen exact PNGs and confirmed deliberate connected pieces, visible build and robber targets, consistent typography, and no legacy fallback; one transient image-tool crop was disproven by reopening the exact complete 1206×2622 Trade PNG |
<!-- fresh-review:end -->

## Living Record

### Progress

- [x] Validation profile and delivery posture locked.
- [x] Legal fixture position implemented.
- [x] Regression tests passed.
- [x] Tutorial capture inspected.
- [x] Fresh reviews passed.
- [x] Completion gate passed.

### Decisions

- 2026-08-03: Treat reducer provenance as the acceptance boundary, not merely valid numeric node and edge IDs.
- 2026-08-03: Preserve the generated board seed and visual system; this slice changes only tutorial fixture pieces and matching public award state.
- 2026-08-05: Reconfirmed the existing reducer-derived fixture after the Game Information refresh; no tutorial piece or board-number changes were required.

### Discoveries

- The prior default fixture used legal building spacing but gave Maya and Theo road components that did not touch their buildings.
- `validateCanonicalSnapshot` validates hash and phase structure but does not prove piece geometry or historical reachability, so the tutorial needs focused fixture assertions.
- The initial all-screen UI run opened a stale/non-DEBUG Messages extension without the UX Lab toggle. After explicitly booting the target simulator, installing the current generated app, and restarting Messages, the identical journey passed and exported all seventeen frames.
- The 2026-08-05 refresh again passed all four legality tests and the full seventeen-screen capture on iPhone 16e. The retained readable PNG set is `output/tutorial-piece-validity-2026-08-05/screens/`.

## Validation and Outcome

- `bash ./scripts/gen.sh` — passed after the final source edit.
- Focused `GameTutorialStateComposerTests` — 4 tests passed, 0 failures across reducer provenance, geometry, completed setup counts, build choices, both award fields, and the two-victim robber state.
- `MessagesExtensionDesignSliceUITests/testCaptureEveryTutorialScreen` — passed on iPhone 17 after explicit current-app installation; 17 attachments exported and representative changed boards inspected at original resolution.
- `make build` — passed after the sandboxed attempt failed only because Tuist could not write its external cache; the escalated rerun completed canonical generation and the generic simulator MessagesExtension build.
- `git diff --check` and `make doc-freshness` — passed.
- Fresh constraint, behavioral, and product/UX reviews — passed.
- `make completion-gate PLAN=docs/exec-plans/active/tutorial-piece-validity.md` — passed under the standard profile, including contract validation, harness audit, diff hygiene, doc freshness, canonical generation, and generic simulator build.
- Remaining work: none for this slice.
