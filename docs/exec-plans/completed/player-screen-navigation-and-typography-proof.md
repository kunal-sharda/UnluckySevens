# Player Screen Navigation and Typography Proof

## Purpose and Outcome

Remove the intrusive in-game Games icon from the tabletop top bar, preserve Games access inside the existing Players and Game Information surface, enforce the locked SF Pro typography contract with the board-number token as the sole exception, and produce a simulator screenshot catalog of every supported player-facing fixture and nested route.

## Execution Settings

- Validation profile: `standard`
- Delivery posture: `direct`
- Rationale: the user selected implementation, the destination remains reachable through an existing secondary surface, and the typography direction is already locked in `DESIGN.md`.

## Context and Boundaries

- The supported Physical Props gameplay family remains unchanged.
- The lobby keeps its labeled Games action because the approved invite flow explicitly includes it.
- In-game top bars expose Settings, status, and Players/Game Information only.
- Games moves into Players/Game Information; Settings does not absorb unrelated lifecycle navigation.
- All interface typography remains OS-provided SF Pro. The geometry-bound SpriteKit board number token remains the sole OS New York/serif exception, and `monospacedDigit()` remains allowed.
- `ULS_CoreGame`, `ULS_Transport`, protocol fields, rules, and validation semantics are unchanged.
- Existing dirty worktree changes from the approved UI integration cleanup are preserved.

## Milestones / Plan of Work

1. Remove Games from gameplay and setup top bars and add a labeled Games destination to Game Information.
2. Add regression coverage for the new navigation placement and a static typography-family guard.
3. Add a deterministic XCUITest catalog lane covering every supported root player fixture plus reachable nested player surfaces.
4. Generate, run focused tests, capture and visually inspect simulator screenshots, and assemble a local review document/contact sheet.
5. Run the standard completion gate and doc freshness.

## Verification Contract and Fresh Review

<!-- verification-contract:start -->
| ID | Class | Source | Acceptance | Verification | Evidence | Status | Rationale |
| --- | --- | --- | --- | --- | --- | --- | --- |
| PSN-001 | observable | user request and UI flows | Games no longer consumes a gameplay top-bar slot and remains reachable from Players/Game Information | focused XCUITest and screenshot inspection | report:`testApprovedProductionJourneyUsesPhysicalPropsOnly` passed in 97.111s; catalog page 5 | pass | Device proof shows the three-part top bar and labeled Games destination in Game Information |
| PSN-002 | mechanical | DESIGN.md and user confirmation | Player-facing type families remain SF Pro except the board number token | static source audit with focused rejection/pass tests | report:`scripts.tests.test_harness_audit` 21/21 pass; `scripts/check-harness.py` pass | pass | Guard rejects custom/additional type designs while allowing the one board serif and `monospacedDigit()` |
| PSN-003 | observable | user request and QA | Every material player role state and reachable nested gameplay route is represented in a simulator screenshot catalog | XCUITest fixture catalog, artifact extraction, PDF render, and visual inspection | artifact:`output/pdf/unlucky-sevens-player-screen-catalog.pdf`; report:20 captures across 11 visually inspected pages | pass | Catalog covers setup, start, active actions/targets, game info, trade, non-primary turns, discard, pending offer, and game over |
| PSN-004 | mechanical | AGENTS.md | Standard completion gate and documentation freshness pass | `make completion-gate` and `make doc-freshness` | report:`make completion-gate PLAN=docs/exec-plans/active/player-screen-navigation-and-typography-proof.md` pass; `make doc-freshness` pass | pass | Standard profile-aware gate passed |
<!-- verification-contract:end -->

<!-- fresh-review:start -->
| Reviewer | Required | Verdict | Evidence |
| --- | --- | --- | --- |
| constraint-auditor | yes | pass | Navigation, typography exception, and catalog evidence map directly to PSN-001 through PSN-003; no protocol/rules boundary changed |
| architecture | no | not-applicable | Navigation stays inside Messages presentation |
| behavioral | yes | pass | Focused production journey passed; simulator captures verify Games is absent from the top bar and present in Game Information |
| product-ux | yes | pass | All 11 catalog pages were rendered with Poppler and visually inspected; layout is legible and the top-bar balance is restored |
<!-- fresh-review:end -->

## Living Record

### Progress

- [x] Confirmed `DESIGN.md` locks SF Pro and names the board number token as the sole exception.
- [x] Confirmed `ui-flows.md` defines the gameplay top area as Settings, status, and Game Information.
- [x] Navigation implementation and regression coverage.
- [x] Simulator screenshot catalog and inspection.
- [x] Completion gate.
- [x] Fresh review and doc freshness.

### Decisions

- 2026-07-30: Place Games with Players/Game Information rather than Settings. It is game lifecycle navigation and belongs beside game participants/context; removing it restores the top bar to its approved three-part contract.
- 2026-07-30: Use the existing labeled lobby Games action unchanged because it does not create the in-game balance problem and is part of the approved invite surface.

### Discoveries

- The legacy and Physical Props top-bar implementations both retained Games even though the flow owner documents only three top-area concerns.
- The typography contract was documented but not enforced mechanically; a narrow source guard can prevent custom, rounded, monospaced-face, or additional serif regressions while permitting semantic sizes, weights, and `monospacedDigit()`.

## Validation and Outcome

- `bash ./scripts/gen.sh`: pass.
- XcodeBuildMCP simulator build/run: pass on iPhone 16e, iOS 26.0.
- `testApprovedProductionJourneyUsesPhysicalPropsOnly`: pass in 97.111 seconds after the navigation implementation.
- `python3 -m unittest scripts.tests.test_harness_audit`: 21/21 pass.
- `python3 scripts/check-harness.py`: pass, with expected notices for unrelated active plans.
- Screenshot evidence: 20 retained device captures, assembled into an 11-page PDF and re-rendered with Poppler for page-by-page inspection.
- `make doc-freshness`: pass.
- `make completion-gate PLAN=docs/exec-plans/active/player-screen-navigation-and-typography-proof.md`: pass after granting Tuist/Xcode cache access.
