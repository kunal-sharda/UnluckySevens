# Physical Trade Surface Correction

## Purpose and Outcome

Correct the overstated Physical Props trade closure. Player composition, recipient selection, maritime trading, and live/pending offers now use the production tabletop language while preserving the mounted board, normal Hand geometry, and existing trade behavior. Tutorial composes those production controls on the actual board without publishing state.

This plan corrects the trade claim in [Turn Screen Visual Direction](turn-screen-visual-direction.md) and resolves the affected dependency in [Settings, Rules, and Click-Through Tutorial](settings-rules-tutorial.md). Behavior is owned by [UI Flows](../../product-specs/ui-flows.md); visual language is owned by [Design](../../../DESIGN.md) and the [Tabletop UI System](../../design/tabletop-ui-system.md).

## Execution Settings

- Validation profile: `standard`
- Delivery posture: `checkpointed`
- Rationale: trade behavior was settled, but the nested physical composition required owner approval before production routing.

## Context and Boundaries

- Preserve legal options, draft state, targeting, cancellation, countering, maritime ratios, publication, and fixed tabletop geometry.
- Use the actual production components and callbacks. Tutorial adds no trade mock, parallel state, or publication path.
- Keep full-size content and 44-point controls; trade overlays may cover the board but may not resize, shift, freeze, or remount it.
- Do not change `ULS_CoreGame`, `ULS_Transport`, protocol fields, hashes, or game rules.
- Preserve unrelated user worktree changes.

## Milestones / Plan of Work

1. Replace legacy nested trade presentation with card-native Give/Get composition, centered recipient selection, complete maritime exchanges, and physical live/pending states.
2. Reuse those production controls in Tutorial and add focused geometry, quantity, accessibility, and route assertions.
3. Capture exactly three representative states, inspect them, and stop for owner approval.
4. After approval, enable the corrected family in production, update owner docs, run fresh review, and pass the standard completion gate.

## Approval Gate

- Authority: user.
- Proof: exactly three inspected installed Messages-host states in `/tmp/unluckysevens-trade-maritime-navigation-candidate`: player Give/Get, recipient selection, and maritime exchange.
- Supersession: every earlier player-trade or maritime capture was rejected or superseded and is not approval evidence.
- Verdict: approved by the user on 2026-07-23: “okay this is perfect, let's close this out again.”
- Authorization used: production routing, owner-doc updates, fresh review, and completion validation.

## Verification Contract and Fresh Review

<!-- verification-contract:start -->
| ID | Class | Source | Acceptance | Verification | Evidence | Status | Rationale |
| --- | --- | --- | --- | --- | --- | --- | --- |
| PTC-001 | mechanical | UI Flows trade contract | Existing legal options, callbacks, cancellation, targeting, countering, and publication remain unchanged | focused model/intent tests and source diff | test:`Test-UnluckySevens-Workspace-2026.07.23_23-46-42--0700.xcresult`; report:behavior-review-2026-07-23 | pass | Focused MessagesExtension selection passed 25 tests; production routing changes presentation only |
| PTC-002 | observable | UI Flows and tabletop geometry contract | Composer, recipient, maritime, and live/pending routes keep the board mounted and all controls within the host | installed UI journey with frame and containment assertions | ui:`test_sim_2026-07-24T06-41-00-027Z_pid28397_a03d88b5.xcresult` | pass | Tutorial, production geometry, and live-route tests passed 3/3 |
| PTC-003 | observable | Design and Tabletop UI System | Physical Props routes use card/prop hierarchy without clipped, shrunk, legacy, or debug-looking trade controls | three installed captures, direct inspection, and production-source inspection | artifact:`/tmp/unluckysevens-trade-maritime-navigation-candidate`; report:product-ux-review-2026-07-23 | pass | Current three-state set was inspected and explicitly approved; full component family is no longer DEBUG-gated |
| PTC-004 | observable | Tutorial contract | Tutorial composes production trade controls on the real board and publishes no state/messages | installed tutorial journey plus callback/source inspection | ui:`testCapturePhysicalTradeCorrectionTutorialCheckpoint`; report:behavior-review-2026-07-23 | pass | Tutorial drives frozen local state through production views; publication callbacks remain absent |
| PTC-005 | observable | accessibility contract | Trade controls are at least 44 points, expose consistent quantities, remain on screen, and do not rely on color alone | UI assertions and accessibility review | ui:`testPhysicalTradeCorrectionProductionGeometry`; report:accessibility-review-2026-07-23 | pass | Card add/remove, close, recipients, Cancel, Send Offer, paging, and confirmation targets pass; selected rows expose text/selection state |
| PTC-006 | judgment | user direction | Corrected trade reads as part of the approved Physical Props game | explicit owner verdict | report:owner-approval-2026-07-23 | pass | User approved the final three inspected states and requested closeout |
| PTC-007 | mechanical | repository boundaries | Core, transport, protocol, hashes, and game rules remain unchanged | path diff inspection | command:`git diff --name-only -- Packages/ULS_CoreGame Packages/ULS_Transport` | pass | Command returned no paths |
<!-- verification-contract:end -->

<!-- fresh-review:start -->
| Reviewer | Required | Verdict | Evidence |
| --- | --- | --- | --- |
| constraint-auditor | yes | pass | report:constraint-review-2026-07-23; all PTC acceptance rows mapped to required evidence classes with no pending token |
| behavioral | yes | pass | report:behavior-review-2026-07-23; 25 focused model/intent tests plus live installed pending/incoming/counter route journey passed |
| product-ux | yes | pass | report:product-ux-review-2026-07-23; final three-state inspection found no clipping, contradictory values, callout boxes, or debug chrome; owner approved |
| accessibility | yes | pass | report:accessibility-review-2026-07-23; 44-point, containment, synchronized-value, paging-state, and non-color selection assertions passed |
| architecture | no | not-applicable | Presentation-only correction; no module-boundary, protocol, or ownership change |
<!-- fresh-review:end -->

## Living Record

### Progress

- [x] Confirmed and scoped the false nested-trade completion claim.
- [x] Implemented the production component family behind checkpoint routing.
- [x] Rejected superseded captures and inspected the final exact three-state set.
- [x] Received owner approval.
- [x] Enabled the approved family on production Physical Props routes.
- [x] Added production/tutorial UI assertions and live-route coverage.
- [x] Updated product and design owner docs and completed fresh review.
- [x] Passed the selected completion gate; this record is ready for completed-plan history.

### Decisions

- 2026-07-22: Full-size Give/Get and maritime content may overlay the mounted board; it must never be shrunk into the action well.
- 2026-07-22: Resource cards own add/remove quantity state. Recipient selection uses a centered, full-bottom veil and actual counter-recipient semantics.
- 2026-07-22: Tutorial-specific trade boxes, green strips, swipe helpers, and internal fractions were rejected. The shared amber-underlined board prompt remains `Trade`.
- 2026-07-23: Maritime presents one complete legal exchange at a time, keeps the canonical Hand spread visible, exposes quiet unboxed 44-point previous/next controls with `N of M`, and requires `Confirm Trade`. Ports determine the best engine-owned ratio rather than separate destinations.
- 2026-07-23: The production family was enabled only after explicit owner approval.

### Discoveries

- Messages sometimes does not export nested SwiftUI identifiers through the host accessibility tree. Assertions use stable visible labels plus frame/value checks where that host limitation applies.
- Tutorial and production must share the same root proposal; extending only the recipient scrim beyond the safe area preserves exact board and Hand frames.
- A stale installed Messages host can display old extension UI after a source build; the documented fresh build/install journey is required before visual evidence.

## Validation and Outcome

- Generation: `bash ./scripts/gen.sh` passed after an initial sandbox-denied Tuist cache write was rerun with approved escalation.
- Build: `make build` passed. The first sandboxed attempt stopped at the same Tuist cache permission boundary; the approved rerun succeeded.
- Focused behavior: 25 tests passed in `Test-UnluckySevens-Workspace-2026.07.23_23-46-42--0700.xcresult`, covering panel models, offer/accept/decline/counter/maritime intents, publication, projection, and non-primary trade context.
- Focused installed journey: 3 tests passed in `test_sim_2026-07-24T06-41-00-027Z_pid28397_a03d88b5.xcresult`: tutorial checkpoint, production geometry, and live pending/incoming/counter routes.
- UI assertion correction history: nested host identifiers for pending, incoming, and counter panels were not exported. Assertions were corrected to the exported outer production surface plus visible route controls; subsequent runs passed.
- Visual evidence: exactly three final captures in `/tmp/unluckysevens-trade-maritime-navigation-candidate` were inspected at original resolution and approved. All earlier captures remain rejected/superseded.
- Repository: `git diff --check` passed; Core/Transport path diff returned empty.
- Completion gate: `make completion-gate PLAN=docs/exec-plans/active/physical-trade-surface-correction.md` passed on 2026-07-23, including verification-contract validation, harness audit, `git diff --check`, doc freshness, canonical generation, and the standard MessagesExtension simulator build.
- Post-gate closeout: this record was archived; final doc freshness, diff, boundary, and harness checks passed. Simulator `444E5D9E-DDE5-4EFD-89A2-673CE380CB25` was shut down and its final state read back as `Shutdown`.
