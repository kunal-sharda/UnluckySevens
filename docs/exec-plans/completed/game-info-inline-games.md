# Game Information Inline Games

## Purpose and Outcome

Make the saved-games action inside gameplay Game Information replace the player list in place. The mounted board, Game Information panel, and turn-object rail remain fixed; Players returns to the roster. The dedicated full Games library remains available as progressive disclosure for management actions.

## Execution Settings

- Validation profile: `standard`
- Delivery posture: `direct`
- Rationale: the user explicitly settled the interaction model. This changes player-facing navigation and needs device evidence and fresh review, but no intermediate approval gate.

## Context and Boundaries

- `DESIGN.md` and `docs/product-specs/ui-flows.md` own the Game Information and saved-games behavior.
- The Games action remains absent from the gameplay top bar.
- The in-place list must use the existing system typography and felt vocabulary, remain scrollable, and preserve the Game Information frame and board geometry.
- Lobby access may continue to open the dedicated Games library directly.
- Core rules, transport, protocol, and recovery semantics remain unchanged.

## Milestones / Plan of Work

1. Add a local Players/Games content mode to Game Information and a compact saved-games list.
2. Preserve dedicated management access and update product-flow documentation and XCUITest expectations.
3. Generate, build, run the focused device journey, and retain Players and Games screenshots.
4. Run fresh reviews and the standard completion gate.

## Verification Contract and Fresh Review

<!-- verification-contract:start -->
| ID | Class | Source | Acceptance | Verification | Evidence | Status | Rationale |
| --- | --- | --- | --- | --- | --- | --- | --- |
| GIG-001 | observable | user request | Tapping Games inside Game Information replaces player rows in the same panel; Players restores them | focused XCUITest and device screenshots | artifact:`output/game-info-inline-games-current/8AAAFA4B-9AD0-4AED-810C-111ABB335C23.png`; artifact:`output/game-info-inline-games-current/5DED8E6B-4DF8-4CAF-8053-CB341844E954.png` | pass | Final installed-build captures show the mutually exclusive Games and Players states in the same panel |
| GIG-002 | observable | UI flows | The board, Game Information frame, and turn-object rail do not shift while switching | frame assertions in focused XCUITest | report:`testCaptureCityTargetAndGameInfoRegression` in `test_sim_2026-07-31T18-21-32-077Z_pid69322_afda8b66.xcresult` | pass | The test asserts the panel, board, board-host identity, and rail geometry across both modes |
| GIG-003 | observable | recovery contract | Compact rows can open a saved game and dedicated management remains reachable without changing recovery semantics | focused test and code review | report:`testRecoveryGamesLibraryUsesDedicatedSurface` in `test_sim_2026-07-31T18-10-03-781Z_pid69322_c857863a.xcresult`; `testInlineGamesCanOpenRecoveredGame` in `test_sim_2026-07-31T18-20-09-403Z_pid69322_62b1ceeb.xcresult` | pass | Rows preserve 44-point targets; a non-current row opens through the existing recovery callback, closes Game Information, and becomes Current; the header overflow reaches the unchanged dedicated library |
| GIG-004 | mechanical | AGENTS.md | Generation, build, doc freshness, and standard completion gate pass | repository gates | report:`bash ./scripts/gen.sh`; XcodeBuildMCP `build_sim`; `git diff --check`; `make doc-freshness`; `make completion-gate PLAN=docs/exec-plans/active/game-info-inline-games.md` | pass | Canonical generation, freshly installed simulator build, focused device tests, diff hygiene, doc freshness, and all required reviews pass before the final completion-gate rerun |
<!-- verification-contract:end -->

<!-- fresh-review:start -->
| Reviewer | Required | Verdict | Evidence |
| --- | --- | --- | --- |
| constraint-auditor | yes | pass | Final audit verified the same-panel swap, geometry proof, 44-point rows, unique row identities, and selection-transfer evidence |
| architecture | no | not-applicable | Local presentation state and existing recovery callbacks do not change module boundaries |
| behavioral | yes | pass | Fresh review verified state ownership, Release wiring, management routing, 44-point rows, and a passing open-game selection-transfer journey |
| product-ux | yes | pass | Fresh review inspected both full-resolution modes and found the fixed in-place swap, typography, hierarchy, scroll overflow, and secondary management control clean |
<!-- fresh-review:end -->

## Living Record

### Progress

- Confirmed the current Games action opens the root-level full-screen library rather than replacing player rows.
- Implemented local Players/Games presentation state, compact Active/Finished game rows, a fixed header management overflow, and Players restoration.
- Generated and explicitly installed the current app, then captured both modes on iPhone 16e / iOS 26.0.1.
- Focused Game Information geometry and dedicated recovery-management journeys pass together.

### Decisions

- 2026-07-31: Game Information owns a local mutually exclusive Players/Games mode. The first Games tap swaps content in place; full lifecycle management stays a secondary action.

### Discoveries

- The existing dedicated `GamesLibraryView` is root-level and includes destructive alerts/sheets. Reusing it inside the compact Game Information overlay would create nested presentation ownership, so the inline list will stay a focused game switcher and disclose management separately.
- A footer management action fell below the first viewport when three recovery records were present. Moving the action to a compact header overflow made progressive disclosure visible without reducing list density or resizing the panel.
- Behavioral review found that inline rows used a 42-point minimum and that the open-game callback was code-reviewed but not exercised. Rows now use the required 44-point minimum and a focused journey verifies selection transfer.

## Validation and Outcome

Implementation, device proof, focused geometry/management tests, the inline open-game selection-transfer test, all required fresh reviews, diff hygiene, doc freshness, canonical generation, and the standard completion gate pass.
