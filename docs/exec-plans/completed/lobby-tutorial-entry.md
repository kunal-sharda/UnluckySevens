# Lobby Tutorial Entry

## Purpose and Outcome

Make Game Settings and Tutorial unmistakable destinations in every lobby state without crowding the identity bar. Games opens directly from a compact die affordance; the two below-table destinations use matching navigation rows.

## Execution Settings

- Validation profile: `standard`
- Delivery posture: `direct`
- Rationale: This changes a player-facing lobby journey and approved UI composition, while the user selected the destination and explicitly asked for implementation.

## Context and Boundaries

- [UI flows](../../product-specs/ui-flows.md) owns the lobby journey.
- [Design](../../../DESIGN.md) and [decisions](../../decisions.md) own the approved composition.
- Tutorial stays local-only and continues to use the existing production tutorial destination.
- Settings behavior, typography, board rendering, and the bottom identity/action group do not change.

## Milestones / Plan of Work

1. Replace the ambiguous metadata-only Settings treatment with an explicit Game Settings row and align Tutorial to the same navigation pattern.
2. Replace More with a direct die-shaped Games control and update the lobby journey and owner docs.
3. Generate, run the focused simulator test, inspect its screenshot, obtain fresh review, and run the standard completion gate.

## Verification Contract and Fresh Review

<!-- verification-contract:start -->
| ID | Class | Source | Acceptance | Verification | Evidence | Status | Rationale |
| --- | --- | --- | --- | --- | --- | --- | --- |
| LTE-001 | observable | user request | Explicit Game Settings and Tutorial rows are visible in every lobby state and open their existing destinations | focused Messages XCUITest journey | command:xcodebuild-focused-ui-pass; `/private/tmp/UnluckySevensLobbyTutorialEntry20260803E.xcresult` | pass | Passing journey observes Game Settings and Tutorial, opens each destination, and returns to the lobby |
| LTE-002 | observable | user request | The compact top-right die opens Games directly without an intermediate menu | focused Messages XCUITest journey | command:xcodebuild-focused-ui-pass; `/private/tmp/UnluckySevensLobbyTutorialEntry20260803E.xcresult` | pass | Passing journey taps the lobby Games button and reaches the saved-games library directly |
| LTE-003 | judgment | user request and DESIGN.md | The paired navigation rows look intentional, preserve the board hierarchy, and do not displace the bottom identity/action group | screenshot inspection and product-ux review | file:output/lobby-tutorial-entry-2026-08-03/refined-attachments/F413FFCB-73C7-4E4E-8D11-4BB631E2DA3F.png; report:product-ux-pass | pass | Fresh review found explicit Settings, matched Tutorial navigation, a balanced die control, and intact board and bottom-action hierarchy |
| LTE-004 | mechanical | established UI contract | All three actions use shared typography, clear accessibility names, and at least 44-point targets | source inspection and XCUITest assertions | file:MessagesExtension/Sources/Features/Lobby/LobbyCocktailTableView.swift; command:xcodebuild-focused-ui-pass | pass | Shared GameTheme fonts and semantic labels are present; focused test enforces minimum targets for Games and Tutorial and exercises Settings |
| LTE-005 | mechanical | AGENTS.md | Generation and doc freshness pass before the standard completion gate | prescribed repository commands | command:gen-pass; command:doc-freshness-pass | pass | Canonical generation and owner-doc freshness passed for the superseding refinement |
<!-- verification-contract:end -->

<!-- fresh-review:start -->
| Reviewer | Required | Verdict | Evidence |
| --- | --- | --- | --- |
| constraint-auditor | yes | pass | all superseding LTE constraints and refreshed raw evidence independently inspected; no blockers |
| architecture | no | not-applicable | no module, protocol, or ownership boundary changes |
| behavioral | no | not-applicable | existing Tutorial and Games destinations are unchanged |
| product-ux | yes | pass | refined original-detail capture and scoped diff inspected; no blockers |
<!-- fresh-review:end -->

## Living Record

### Progress

- 2026-08-03: Locked `standard` validation and `direct` delivery before implementation.
- 2026-08-03: Implemented the direct Tutorial action, updated its journey test and owner docs, and passed the focused simulator journey after relaunching Messages against the newly installed build.
- 2026-08-03: Fresh product-UX review passed with no visual, hierarchy, typography, or accessibility blockers. `make doc-freshness` passed.
- 2026-08-03: Fresh constraint-auditor review passed LTE-001 through LTE-005 and cleared the standard completion gate to run.
- 2026-08-03: The standard completion gate passed after rerunning with Tuist cache access; contract, harness audit, diff check, doc freshness, canonical generation, and simulator build all passed.
- 2026-08-03: Implemented the superseding die and paired-row refinement. After clearing the Messages extension cache, the focused journey passed in 209.697 seconds with zero failures and exported five refreshed captures.
- 2026-08-03: `make doc-freshness` passed after updating the design, decision, product-flow, and active execution owners.
- 2026-08-03: Fresh product-UX review passed the superseding refinement with no clarity, hierarchy, typography, clipping, or accessibility blockers.
- 2026-08-03: Fresh constraint-auditor review passed LTE-001 through LTE-005 and cleared the superseding refinement for the standard completion gate.
- 2026-08-03: The standard completion gate passed for the superseding die and paired-row refinement; contract, harness audit, diff check, doc freshness, canonical generation, and simulator build all passed.

### Decisions

- 2026-08-03: Keep the top identity bar compact. Place Tutorial below Game Settings as a visible secondary lobby option; reserve More for Games.
- 2026-08-03: User superseded the prior refinement: replace More with a direct die control, explicitly label Game Settings, and align Tutorial to the same text-row navigation pattern.

### Discoveries

- The ellipsis currently opens Games and Tutorial, not Settings. Game Settings already has a direct, labeled summary-row entry.
- The first focused run reused the previously loaded extension process and therefore rendered the prior UI. Terminating Messages, reinstalling the built host, and rerunning loaded the new extension; the direct Tutorial journey then passed.
- The same Messages host cache behavior recurred for the superseding refinement. Cold-start attempts first missed UX Lab and then rendered the prior extension; explicit terminate, install, and launch loaded the revised build before the passing run.

## Validation and Outcome

The focused Messages XCUITest passed in 209.697 seconds with zero failures. Its refreshed lobby capture is at `output/lobby-tutorial-entry-2026-08-03/refined-attachments/F413FFCB-73C7-4E4E-8D11-4BB631E2DA3F.png`. Fresh constraint-auditor and product-UX reviews passed with no blockers. `make completion-gate PLAN=docs/exec-plans/completed/lobby-tutorial-entry.md` passed under the standard profile.
