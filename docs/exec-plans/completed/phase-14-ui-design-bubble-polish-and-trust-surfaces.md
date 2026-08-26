# Phase 14 — UI Design, Bubble Polish, and Trust Surfaces

> Closed 2026-08-26: the parent phase landed through its completed child plans and subsequent release work. The old unresolved invitation comparison was superseded by the production invite flow shipped in Build `1.0 (8)` and its focused publication/rollback tests.

> 2026-07-23 resolution: P14-004's overstated nested Trade visual coverage was corrected and explicitly approved through [Physical Trade Surface Correction](../completed/physical-trade-surface-correction.md). Earlier rejected Trade evidence remains invalid.

## Purpose and Outcome

Phase 14 improves the player-facing trust surfaces around lobby entry, transcript bubbles, tabletop gameplay, and repeatable visual validation. The durable goal is a compact, tactile, trustworthy Messages experience whose canonical state survives reopen and device handoff, whose transcript reads like a game rather than a transport log, and whose board remains visually primary.

This is the phase-level parent. Independently deliverable or judgment-heavy work belongs in focused child plans instead of extending this file with iteration chronology.

## Execution Settings

- Validation profile: `standard`
- Delivery posture: `checkpointed`
- Rationale: The phase contains meaningful product and UI work. Settled implementation slices may run directly in child plans, but unresolved visual directions require explicit approval gates and focused observable evidence.

## Context and Boundaries

Owner docs hold current truth:

- [UI flows](../../product-specs/ui-flows.md) owns player-facing behavior.
- [Design](../../../DESIGN.md) owns current visual language and calibrated taste.
- [Architecture](../../../ARCHITECTURE.md) and [decisions](../../decisions.md) own module and protocol boundaries.
- [QA](../../quality/qa.md), [UX Lab](../../quality/ux-lab.md), and [Messages host lessons](../../quality/messages-host.md) own validation and durable platform knowledge.

Locked boundaries:

- `MSMessage.url` remains the canonical payload carrier; transcript copy and images are presentation metadata and fail soft.
- Canonical display names live in shared state; device-local preferred-name storage is prefill convenience only.
- Core owns rules and action legality. Messages presentation must not become a second rules engine.
- SpriteKit owns the live board and SwiftUI owns surrounding chrome. Action-surface changes must not remount or resize the board.
- Ordinary screenshots, result bundles, and rejected iterations stay outside Git.

## Milestones / Plan of Work

Completed phase outcomes:

1. Canonical lobby display names, transport round-trip, rename publishing, and same-device preferred-name prefill.
2. Product-oriented transcript copy and optional presentation-only invite/action graphics.
3. Pre-TestFlight removal of legacy transcript/runtime and shipped debug surfaces.
4. Standalone Messages-only packaging and extension-scoped icon wiring through the canonical generator.
5. DEBUG-only UX Lab fixtures, dummy-player flow support, clean-shot controls, and repeatable XCUITest/simulator capture lanes.
6. First tabletop shell and saved production board art, with numbered design passes removed after durable lessons were promoted.
7. Core validation hardening for ordered forced discard, lobby transitions, and hidden Victory Point reveal eligibility.

Remaining focused slices:

- The reusable [Tabletop UI System](../../design/tabletop-ui-system.md) is approved and is the starting reference for later screen plans.
- Refine the first invite into the board-game rules/setup-card direction already described in [UI flows](../../product-specs/ui-flows.md).
- Establish and approve the dedicated [Initial Setup Placement Screen](../completed/initial-setup-placement-screen.md) before making its physical-table composition the production default.
- The approved Physical Props pre-roll ritual is productionized and verified through [Start-of-Turn visual direction](../completed/start-of-turn-visual-direction.md).
- The approved Physical Props post-roll Turn Screen is productionized and verified through [Turn Screen visual direction](../completed/turn-screen-visual-direction.md).
- The approved shared-table waiting and responder states are productionized and verified through [Not Primary Player visual direction](../completed/not-primary-player-visual-direction.md).
- Continue later Phase 14 polish through separate child plans when a slice is independently deliverable or judgment-heavy.

## Approval Gate

Phase-level visual approval is delegated to focused child plans. No unresolved visual child may productionize beyond its declared comparison boundary or inherit a prior implementation as approval.

## Verification Contract and Fresh Review

<!-- verification-contract:start -->
| ID | Class | Source | Acceptance | Verification | Evidence | Status | Rationale |
| --- | --- | --- | --- | --- | --- | --- | --- |
| P14-001 | mechanical | product and architecture owner docs | Canonical names, presentation-only bubble media, standalone Messages packaging, and Core-owned legality remain the durable implementation boundaries | owner-doc and focused test evidence retained in phase history | file:docs/product-specs/ui-flows.md; file:ARCHITECTURE.md; file:docs/decisions.md | pass | Landed outcomes are now owned outside this plan |
| P14-002 | observable | QA owner docs | UX Lab and simulator capture paths remain repeatable design evidence lanes without replacing real-device release validation | owner-doc inspection | file:docs/quality/ux-lab.md; file:docs/quality/device-runbooks.md | pass | Durable harness behavior is documented in its owners |
| P14-003 | judgment | UI flows | Invite surface reaches the approved rules/setup-card direction | focused child comparison and user approval | report:pending | pending | Remaining Phase 14 slice |
| P14-004 | judgment | user direction | Post-roll Turn Screen metaphor and nested Physical Props surfaces are visually approved before further productionization | corrective checkpointed child plan | file:docs/exec-plans/completed/physical-trade-surface-correction.md; report:physical-trade-owner-approval-2026-07-23 | pass | The corrected production Trade family was approved after final three-state inspection |
| P14-005 | judgment | user direction | Pre-roll Start-of-Turn ritual is visually approved before production routing | checkpointed child plan | file:docs/exec-plans/completed/start-of-turn-visual-direction.md | pass | User approved the direction and authorized productionization on 2026-07-18 |
| P14-006 | judgment | user direction | Out-of-turn waiting and responder states reuse the approved shared table without exposing unavailable active-player actions | checkpointed child plan | file:docs/exec-plans/completed/not-primary-player-visual-direction.md | pass | User approved the corrected direction on 2026-07-18 and its standard completion gate passed |
<!-- verification-contract:end -->

<!-- fresh-review:start -->
| Reviewer | Required | Verdict | Evidence |
| --- | --- | --- | --- |
| constraint-auditor | yes | pending | report:pending-active-phase |
| architecture | no | not-applicable | Route per focused child when boundaries change |
| behavioral | no | not-applicable | Route per focused child when behavior changes |
| product-ux | no | not-applicable | User owns pending visual approval; final specialist review is child-routed |
<!-- fresh-review:end -->

## Living Record

### Progress

- [x] Player-facing typography standardized on the OS-provided SF Pro family across SwiftUI, SpriteKit board tokens, transcript rendering, and DEBUG chrome; the durable contract lives in `DESIGN.md`.
- [x] Lobby identity, transcript, packaging, UX Lab, board-art, and tabletop-foundation outcomes landed.
- [x] Durable platform, QA, architecture, product, and design lessons promoted to owner docs.
- [ ] Invite rules/setup-card direction approved and productionized.
- [x] Post-roll Turn Screen direction approved; the nested Trade correction was productionized and verified through its focused child plan.
- [x] Start-of-Turn direction approved, production-routed, and verified through its child plan.
- [x] Not Primary Player direction approved, productionized, and verified through its child plan.

### Decisions

- 2026-07-17: Unlucky Sevens uses SF Pro through system APIs as its sole interface type family. Hierarchy comes from semantic size and weight rather than mixing serif, rounded, monospaced, or custom families; `monospacedDigit()` remains permitted for stable numeric widths.
- 2026-07-11: Historical build and screenshot receipts were removed from this active parent after durable lessons were confirmed in owner docs. Active plans retain current intent, unresolved work, locked decisions, and concise proof—not every iteration.
- 2026-07-11: The previously implemented post-roll Turn Screen is an implementation baseline only. It does not count as visual approval and must not bias the checkpointed comparison budget.
- 2026-07-11: Focused visual children use user approval by default; product/UX review is advisory on demand and otherwise runs once after productionization.

### Discoveries

- Messages XCTest attachments may corrupt embedded compositor surfaces even when the settled simulator is correct. Use XCUITest for deterministic navigation/assertions and direct `simctl` stills for visual judgment when needed.
- Simulator screenshots can show stale extension UI after a successful build. Reinstall the current app and terminate Messages before treating a capture as evidence.
- The canonical generation path is `bash ./scripts/gen.sh`; raw Tuist generation misses required standalone Messages packaging adjustments.

## Validation and Outcome

Completed outcomes are summarized in [CHANGELOG](../CHANGELOG.md) and owned by the linked current docs. Phase 14 remains active because the invite refinement is unresolved; the completed setup, Turn Screen, Start-of-Turn, and Not Primary Player children retain their closeout evidence. Each child records its own commands, evidence, reviewer verdicts, and completion receipt.
