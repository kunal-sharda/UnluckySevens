# City upgrade at settlement limit — #58

## Purpose and Outcome

Investigate [#58](https://github.com/kunal-sharda/UnluckySevens/issues/58): a player reports being unable to build another city after five settlements and one city. The player clarified on 2026-11-17: select City, then double-tap an existing settlement, with five settlements and one city currently on the board. The original Core-only investigation did not reproduce a rules failure; the rapid-tap UI baseline now reproduces selection without upgrade.

## Execution Settings

- Validation profile: `standard`
- Delivery posture: `direct`
- Rationale: renewed UI interaction investigation after the player clarified that double tapping did nothing. Production changes require a demonstrated defect; the prior Core evidence does not prove touch delivery.

## Context and Boundaries

Core owns legality and piece accounting; Messages consumes its queries. Existing unrelated build-guide work must remain untouched. Rules, protocol and validation semantics are unchanged. Source inspection covers Core queries/reducer/transition validator plus LobbyDriverViewModel availability, GameScreenModelBuilder, TurnInteractionResolver and GameModeResolver.

## Milestones / Plan of Work

1. Preserve Core boundary evidence for available/exhausted city stock and settlement return.
2. Reproduce rapid-tap behavior through production controls; implement explicit city double-tap confirmation with unchanged Core checks.
3. Prove the confirmed five-settlement/one-city state via rapid tapping and preserve separated-tap city behavior. Run scoped unit tests, fresh review and final gates; record scope and limitations on #58.

## Verification Contract and Fresh Review

Locked final proof: `GameBoardCommitCoordinatorTests` through xcodebuild after canonical generation; two isolated journeys in `scripts/ui-city-double-tap-catalog.txt` via the canonical iPhone runner; inspect before/after canonical evidence and screenshot; fresh constraint/behavior review; doc freshness and standard completion gate. Earlier Core tests remain valid because no rules code changes. The total UI budget is initial attempt plus two diagnosed reruns: baseline attempt 1, exact-fixture navigation attempt 2, and corrected final attempt 3. Stop/report if attempt 3 fails. Simulator use must be cleaned up. No device/TestFlight claim is made.

<!-- verification-contract:start -->
| ID | Class | Source | Acceptance | Verification | Evidence | Status | Rationale |
| --- | --- | --- | --- | --- | --- | --- | --- |
| CITY-001 | mechanical | #58 | Both reported-count interpretations permit city upgrade with resources and city stock, returning the settlement | focused Core query/blocker/reducer/validator tests | report:/tmp/uls-city-limit-tests-r1.log | pass | Diagnostic coverage, not proof of friend's failure |
| CITY-002 | mechanical | existing Core rules | Four cities block further upgrades independently of settlement stock | focused Core test | report:/tmp/uls-city-limit-tests-r1.log | pass | Preserve city limit |
| CITY-003 | mechanical | AGENTS.md | Record investigation and preserve unrelated work and owner contracts | source/diff review and doc freshness | report:source-and-diff-review; report:/tmp/uls-city-doc-freshness.log | pass | Unrelated edits preserved; product tap contract updated; rules/protocol unchanged |
| CITY-004 | observable | Player clarification 2026-11-17 | Trace rapid double tap through live city target selection and canonical commit; report failures honestly | isolated city rapid-double-tap XCUITest with before/after diagnostic and inspected artifacts | report:output/ui-screenshot-harness/20261118T034458Z-iphone | pass | Exact-count rapid and existing separated city journeys both pass; canonical evidence and stills inspected |
| CITY-005 | mechanical | Existing tap-again contract | City double tap confirms one legal normalized target; single taps still select then confirm; invalid targets cannot confirm | GameBoardCommitCoordinatorTests | report:/tmp/uls-city-tap-unit.log | pass | 7 focused coordinator tests pass |
<!-- verification-contract:end -->

<!-- fresh-review:start -->
| Reviewer | Required | Verdict | Evidence |
| --- | --- | --- | --- |
| constraint-auditor | yes | pass | report:city-constraint-review-2026-11-17 |
| architecture | no | not-applicable | No ownership or protocol changes |
| behavioral | yes | pass | report:city-constraint-review-2026-11-17 |
| product-ux | no | not-applicable | Existing city tap-again interaction retained; no layout/art/copy redesign |
<!-- fresh-review:end -->

## Living Record

2026-11-11: city query, purchase blocker, reducer and transition validator check city stock independently of settlement stock. Presentation availability and draft paths consume the city query. No root cause established. Plan locked before test edits.

## Validation and Outcome

2026-11-12: focused suite passes 7/7, including both new boundary tests (`/tmp/uls-city-limit-tests-r1.log`). Initial attempt failed before tests because sandbox-exec denied Swift manifest compilation; the authorized retry passed. No engine defect reproduced: query/blocker/reducer/transition validation all allow the reported counts with resources and available cities. City stock exhaustion remains enforced. Doc freshness and whitespace checks pass. The original diagnostic slice changed only test coverage and this active execution record; architecture, product, decisions, design and QA owners intentionally unaffected. No historical cleanup or device validation requested by this diagnostic slice. Issue remains open unless a demonstrated defect is corrected.

Original 2026-11-12 evidence gap: affected app build and actual game snapshot were unavailable. The later clarification resolves selected mode, target and piece counts; physical-device/build provenance remains unverified. At that original diagnostic checkpoint production code was unchanged. The 2026-11-17 implementation below supersedes that status; #58 remains open pending final evidence.

Completion gate attempted and blocked by unrelated pre-existing workbench residue: `docs/design/workbench/ipad/stamp-originals.zip`, `tree-and-road.png`, `tree-and-road.pdf`, `stamps-and-drawing-ideas.zip` (log `/tmp/uls-city-limit-gate.log`). Selected contract check passed; harness audit failed before the lightweight profile could finish. Do not delete or claim ownership of these unrelated artifacts. The targeted tests and independent doc freshness passed, but this slice has no completion claim while the gate is blocked. No simulators were used for that original Core-only slice.

## Double-tap investigation — 2026-11-17

Initial intake reported double tapping did nothing; the follow-up clarification below resolves mode, target and counts. App build and actual snapshot remain unknown. Lock a standard/direct diagnostic slice before editing: add one rapid-double-tap city journey using the existing canonical post-roll fixture and real board coordinates. Run it with `bash ./scripts/run-ui-screenshot-catalog.sh iphone scripts/ui-city-double-tap-catalog.txt`; initial attempt plus two diagnosed retries. Inspect canonical before/after evidence and screenshot. Follow any reproduced failure into the production interaction; amend the contract before a behavioral fix. If rapid tapping works, retain that limited result and request the missing player state instead of inventing a fix. Required final checks: fresh constraint audit, `make doc-freshness`, and selected completion gate (which includes baseline build if structural checks pass). Existing workbench artifacts remain unrelated and must not be removed.

2026-11-17 clarification: player selected City and double-tapped an existing settlement on the board while owning five settlements and one city. Mode/target/count ambiguity is resolved. Extend CITY-004 proof to a dedicated synthetic DEBUG fixture with those exact on-board counts, after the baseline rapid-tap run. Preserve legality/transition validation and inspect before/after piece counts. The first sandbox command failed at CoreSimulator access before generation or tests; rerun with authorized simulator access. This is infrastructure, not product evidence.

Rapid-tap baseline attempt 1 (`output/ui-screenshot-harness/20261118T033550Z-iphone`) reproduced no canonical revision change. Failure still inspected: existing settlement is highlighted and header reads “Tap Again to Upgrade”, so the tap sequence selected but did not commit. This uses the old shared fixture, not yet the exact count fixture. Next attempt uses the now-confirmed five-settlement/one-city fixture to verify the same symptom before production correction. Initial test failure is product-interaction evidence, not a piece-limit failure; source has only a single-tap recognizer. Exact UIKit gesture symbol docs are consulted before selecting a correction.

Production amendment before implementation: baseline CITY-004 failure justifies explicit city-only double-tap recognition. Apple symbol docs [UITapGestureRecognizer.numberOfTapsRequired](https://developer.apple.com/documentation/uikit/uitapgesturerecognizer/numberoftapsrequired) and [UIGestureRecognizer.require(toFail:)](https://developer.apple.com/documentation/uikit/uigesturerecognizer/require(tofail:)) describe tap-count recognition and single/double failure dependencies. Install a two-tap recognizer enabled only in City mode, require its failure before a single tap, and forward its count to a single coordinator decision. Keep Core legality and publication unchanged. Lock proof: exact-count rapid-tap route plus existing separated-tap city route, focused GameBoardCommitCoordinatorTests, fresh constraint/behavior review, doc freshness, completion gate. The total initial-plus-two UI retry budget applies to this slice, including the final correction run. No platform quirk or repo-wide workaround is asserted.

Exact-count attempt 2 (`20261118T034004Z-iphone`) failed before City selection: inspected failure still shows the automatic Buy a Dev Card teaching sheet, and the test omitted the dismissal already used by the shared post-roll helper. Correct that fixture navigation; no additional product defect inferred. Attempt 3 tests the explicit double-tap correction plus the existing separated-tap city route. The total initial-plus-two test-run budget remains binding; stop if this final run fails.

Final attempt 3 passed both isolated city journeys (`output/ui-screenshot-harness/20261118T034458Z-iphone`). Exact-count rapid evidence: rev9→10, remaining pieces R15/S0/C3→R15/S1/C2, wheat5→3/ore5→2, Published city upgrade, no errors; inspected still shows four settlements/two cities. Separated-tap route likewise rev9→10, correct cost and returned settlement. Focused coordinator tests pass 7/7 (`/tmp/uls-city-tap-unit.log`). `make doc-freshness` and diff hygiene pass. Product owner `ui-flows.md` documents rapid/separated confirmation; architecture, locked decisions, design and QA owners intentionally unaffected. No historical cleanup or device/TestFlight validation performed. Fresh independent constraint-auditor and behavioral review both pass after inspecting task diff, unit log, final canonical attachments/stills and manifest. Test simulator shut down; booted-device inventory empty. Completion gate selected contract passes, but harness audit is blocked by the same four unrelated workbench files listed above (`/tmp/uls-city-completion-gate.log`); do not rerun or delete them. Run the already-required standard `make build` independently to retain its evidence, without claiming the blocked gate passed.

Standard `make build` passed independently (`/tmp/uls-city-standard-build.log`), including canonical generation and doc freshness. Final status: implemented and scoped tests/reviews pass; full completion gate remains blocked solely by unrelated workbench ownership audit. No release/TestFlight upload or physical-device proof. Simulator application closed and test device shut down; no booted simulators remain. Implementation and evidence were committed and pushed as `47e708b` on `beta-1.2`; #58 records the tested fix and remains open with the gate limitation. Only the pre-existing unrelated build-guide files remain dirty.
