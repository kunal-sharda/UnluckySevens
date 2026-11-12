# City upgrade at settlement limit — #58

## Purpose and Outcome

Investigate [#58](https://github.com/kunal-sharda/UnluckySevens/issues/58): a player reports being unable to build another city after five settlements and one city. Counts may mean cumulative builds or current pieces. Preserve the report as unconfirmed until a failure is reproduced.

## Execution Settings

- Validation profile: `lightweight`
- Delivery posture: `direct`
- Rationale: bounded diagnostic regression coverage only; no production change is justified by current source inspection. Promote to standard and lock new proof before any behavioral fix.

## Context and Boundaries

Core owns legality and piece accounting; Messages consumes its queries. Existing unrelated build-guide work must remain untouched. Rules, protocol and validation semantics are unchanged. Source inspection covers Core queries/reducer/transition validator plus LobbyDriverViewModel availability, GameScreenModelBuilder, TurnInteractionResolver and GameModeResolver.

## Milestones / Plan of Work

1. Test four and five current settlements plus one city, covering cumulative and on-board readings; verify successful upgrade returns a settlement, consumes resources and validates.
2. Test city stock exhaustion independently of settlement stock.
3. Record evidence on the issue. If no failure reproduces, leave the bug open pending actual game state/build and observed failure; do not invent a fix.

## Verification Contract and Fresh Review

Locked proof: `swift test --package-path Packages/ULS_CoreGame --filter TurnBuildRulesV1Tests`, doc freshness, lightweight completion gate. No UI source or runtime changes; no simulator use. Initial attempt plus at most two diagnosed retries. A production defect requires a dated contract amendment before implementation.

<!-- verification-contract:start -->
| ID | Class | Source | Acceptance | Verification | Evidence | Status | Rationale |
| --- | --- | --- | --- | --- | --- | --- | --- |
| CITY-001 | mechanical | #58 | Both reported-count interpretations permit city upgrade with resources and city stock, returning the settlement | focused Core query/blocker/reducer/validator tests | report:/tmp/uls-city-limit-tests-r1.log | pass | Diagnostic coverage, not proof of friend's failure |
| CITY-002 | mechanical | existing Core rules | Four cities block further upgrades independently of settlement stock | focused Core test | report:/tmp/uls-city-limit-tests-r1.log | pass | Preserve city limit |
| CITY-003 | mechanical | AGENTS.md | Record investigation and preserve unrelated work and owner contracts | source/diff review and doc freshness | report:source-and-diff-review; command:make-doc-freshness | pass | No production behavior changes |
<!-- verification-contract:end -->

<!-- fresh-review:start -->
| Reviewer | Required | Verdict | Evidence |
| --- | --- | --- | --- |
| constraint-auditor | no | not-applicable | Narrow diagnostic tests; no production change |
| architecture | no | not-applicable | No ownership or protocol changes |
| behavioral | no | not-applicable | Diagnostic coverage of unchanged rules |
| product-ux | no | not-applicable | No UI changes |
<!-- fresh-review:end -->

## Living Record

2026-11-11: city query, purchase blocker, reducer and transition validator check city stock independently of settlement stock. Presentation availability and draft paths consume the city query. No root cause established. Plan locked before test edits.

## Validation and Outcome

2026-11-12: focused suite passes 7/7, including both new boundary tests (`/tmp/uls-city-limit-tests-r1.log`). Initial attempt failed before tests because sandbox-exec denied Swift manifest compilation; the authorized retry passed. No engine defect reproduced: query/blocker/reducer/transition validation all allow the reported counts with resources and available cities. City stock exhaustion remains enforced. Doc freshness and whitespace checks pass. Only diagnostic test coverage and this active execution record change; architecture, product, decisions, design and QA owners intentionally unaffected. No historical cleanup or device validation requested by this diagnostic slice. Issue remains open unless a demonstrated defect is corrected.

Remaining issue evidence: affected app build, actual selected game snapshot or diagnostic report, player turn/resources and whether City was disabled, target taps failed, or publication showed an error. No Messages-host or physical-device reproduction is claimed. Production code is deliberately unchanged; #58 remains open.

Completion gate attempted and blocked by unrelated pre-existing workbench residue: `docs/design/workbench/ipad/stamp-originals.zip`, `tree-and-road.png`, `tree-and-road.pdf`, `stamps-and-drawing-ideas.zip` (log `/tmp/uls-city-limit-gate.log`). Selected contract check passed; harness audit failed before the lightweight profile could finish. Do not delete or claim ownership of these unrelated artifacts. The targeted tests and independent doc freshness passed, but this slice has no completion claim while the gate is blocked. No simulators were started or used.
