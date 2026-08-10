# Full Player Screen Catalog Rerun

## Purpose and Outcome

Rerun the complete simulator catalog from a newly generated and explicitly installed build, retain the earlier 20-screen comparison set plus every additional named state now emitted by those canonical journeys, inspect every player-facing capture, and replace the local review PDF with current evidence.

## Execution Settings

- Validation profile: `standard`
- Delivery posture: `direct`
- Rationale: this is a settled repeatable validation/capture task. Product code changes are out of scope unless the canonical harness itself is stale or a reproduced player-screen defect blocks the catalog.

## Context and Boundaries

- The catalog must cover setup, start of turn, active-turn board and nested actions, build targets, Game Information, active/pending/incoming trade roles, ordinary waiting, discard roles, and game over. The earlier 20 states are the minimum, not a cap.
- Evidence must come from the installed Messages extension on the iPhone 16e iOS 26 simulator.
- Generate only with `bash ./scripts/gen.sh` and use the checked-in XCUITest/UX Lab routes.
- Preserve all unrelated dirty-worktree changes.

## Milestones / Plan of Work

1. Generate, build, explicitly install, and launch the current app bundle.
2. Run every canonical catalog XCUITest route serially.
3. Extract named screenshot attachments, verify the 20-screen manifest, and inspect each full-resolution image.
4. Rebuild and render the local PDF/contact sheet, then run final mechanical and documentation checks.

## Verification Contract and Fresh Review

<!-- verification-contract:start -->
| ID | Class | Source | Acceptance | Verification | Evidence | Status | Rationale |
| --- | --- | --- | --- | --- | --- | --- | --- |
| FSC-001 | mechanical | AGENTS.md and QA | The current app is generated canonically, built, and explicitly installed for capture | generation and simulator build/install logs | report:`bash ./scripts/gen.sh`; XcodeBuildMCP build/test on iPhone 16e `444E5D9E-DDE5-4EFD-89A2-673CE380CB25`; explicit `simctl install`, Messages host restart, and installed-container query retained in `output/player-screen-catalog/validation-summary.md` | pass | Current Messages extension was generated and built for the final passing test, then explicitly reinstalled and verified in the simulator container while Messages relaunched successfully |
| FSC-002 | observable | user request | All 20 catalog screens are captured from canonical installed-host journeys | serial XCUITest routes plus attachment manifest | artifact:`output/player-screen-catalog/contact-sheet.png`; 27 deduplicated named attachments; `output/player-screen-catalog/validation-summary.md` | pass | Earlier 20-state minimum plus seven additional canonical states are present; all ten routes have passing evidence |
| FSC-003 | judgment | DESIGN.md | Every retained screenshot is visually inspected and no blocking layout, typography, stale-state, or debug-chrome defect remains | full-resolution image review and rendered PDF review | artifact:`output/pdf/unlucky-sevens-player-screen-catalog.pdf`; 15 rendered PDF pages under `tmp/pdfs/player-catalog-render-final/` | pass | All 27 captures and the rendered catalog were inspected; the robber-selection outlier was refined and pages 7-8 are clean |
| FSC-004 | mechanical | AGENTS.md | Standard completion and doc-freshness gates pass for any resulting repository changes | focused tests, completion gate, and doc freshness | report:`git diff --check`; `make doc-freshness`; `make completion-gate PLAN=docs/exec-plans/active/full-player-screen-catalog-rerun.md` | pass | Diff and documentation checks pass; contract statuses and all required fresh-review verdicts are pass before the final completion-gate rerun |
<!-- verification-contract:end -->

<!-- fresh-review:start -->
| Reviewer | Required | Verdict | Evidence |
| --- | --- | --- | --- |
| constraint-auditor | yes | pass | Final audit verified canonical generation, explicit install/host launch, all 27 captures across ten passing routes, and the rendered 15-page artifact |
| architecture | no | not-applicable | Capture-only scope does not change boundaries |
| behavioral | yes | pass | Fresh review verified DEBUG-only route isolation, fixture reset behavior, current Trade assertions, and passing evidence for all ten canonical routes |
| product-ux | yes | pass | Fresh review inspected all 27 states plus full-resolution robber, city, and Game Information captures; no blocking layout, typography, debug-chrome, or legacy-component outlier remains |
<!-- fresh-review:end -->

## Living Record

### Progress

- Generated, built, installed, and launched the current app on the iPhone 16e iOS 26 simulator.
- Captured 27 named player-facing states across the ten canonical journeys.
- Rebuilt the PDF catalog and contact sheet, rendered all 15 PDF pages, and inspected the complete contact sheet plus the prior city-target and Game Information problem screens at full resolution.

### Decisions

- 2026-07-31: Retain the earlier 20-screen comparison set and include the seven additional setup/dev/end/draw-pile captures now emitted by the same canonical journeys, rather than hiding current nested-state coverage.
- 2026-07-31: Promote the pre-roll Dev Card chooser into a DEBUG-only direct UX Lab route because the embedded Messages XCTest host reports an invalid accessibility hit point for the otherwise visible control.

### Discoveries

- The normal-turn journey still contained two stale containment assertions from before the approved full-size Trade composer and expanded Game Information overlay. The product behavior already matches `DESIGN.md`; the catalog harness was updated to assert on-screen containment, stable board geometry, complete player summaries, and recap visibility instead of the retired shallow-action-well constraint.
- The active-turn capture still expected a legacy text `Cancel` action in the physical Trade composer and the pending-offer route still expected the retired `uls.physicalTrade.advance` control. Both assertions now target the current physical controls (`uls.physicalTrade.close` and `uls.physicalTrade.composerPanel`).
- Adding another item to the long iOS debug menu made lower menu actions inaccessible to XCTest. `Start Dev` is now a direct DEBUG chrome control and `Pending` is ordered above the menu visibility cutoff.
- The two screens previously called out as the seventh/eighth anomalies are not legacy-component regressions in the current build: city placement is a board-native target ring with fixed header guidance, and Game Information is a complete player/game overlay anchored above the object rail.
- A later full-catalog review found one actual legacy presentation on the Dev Card Knight route: the board-wide `Tap tile` capsule duplicated the fixed `Move the Robber` header and obscured the board. Physical Props now keeps target guidance in the fixed header for all board-target modes; the refreshed page 7 capture verifies that the capsule is gone.

## Validation and Outcome

The complete 27-state catalog is captured and visually reviewed. All ten canonical routes have passing evidence. Diff hygiene, doc freshness, all required fresh reviews, canonical regeneration, the Messages-extension simulator build, and the standard profile-aware completion gate pass.
