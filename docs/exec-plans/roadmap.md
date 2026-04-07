# Roadmap

This file is the coarse sequencing surface for work after the current active ExecPlan. It should answer "what comes next" without pretending future phases are already fully planned.

Use the tracked planning surfaces this way:

- use `docs/exec-plans/active/` for live execution state
- use `docs/exec-plans/completed/` for historical reconstructions
- use this file for future phase sequencing
- use `docs/exec-plans/tech-debt-tracker.md` for durable cross-phase debt
- use `CHANGELOG.md` as retrospective evidence, not as the live source of execution truth

Do not put day-to-day execution notes here. If a future phase becomes active, create or move to an ExecPlan under `docs/exec-plans/active/`.

## Current Execution Gate

### Phase 12.7 — Flow Hardening and Real-Device Pass

- Owner: [Phase 12 Plan](/Users/kunalsharda/Documents/Code/UnluckySevens/docs/exec-plans/active/phase-12-gameplay-flows.md)
- Status: active
- Why it is still the gate:
  - real two-device Messages play is not signed off yet
  - same-bubble recovery, board responsiveness, and setup-road ergonomics still need hardening on hardware
  - host start and turn rotation must continue to prove out from real participant identity instead of debug fallback behavior

Do not start the next phase until the remaining 12.7 issues are either closed or explicitly promoted out of 12.7 as follow-on work.

## Sequenced Next Phases

### Phase 13 — Recap, History, Dispute, and Bubble Trust Surfaces

Why this phase exists:

- phase 12 already treats recap/history/dispute UX as the next product slice
- [docs/decisions.md](/Users/kunalsharda/Documents/Code/UnluckySevens/docs/decisions.md) already locks the intended audit-log behavior
- [docs/product-specs/ui-flows.md](/Users/kunalsharda/Documents/Code/UnluckySevens/docs/product-specs/ui-flows.md) already defines the player-facing recap/history/dispute expectations

Scope:

- short last-turn recap in the default UI
- one-round history without overwhelming the main shell
- deliberate dispute mode for full audit inspection
- clearer win-state and final game summary presentation
- transcript bubble readability and trust-surface polish for lobby and in-game states

Not this phase:

- protocol redesign
- Messages host-boundary transport rework
- deep test-architecture cleanup

Entry criteria:

- phase 12 gameplay flows are usable on real devices without relying on debug-first flow advancement

### Phase 14 — Multiplayer Authority and Messages Host Hardening

Why this phase exists:

- the current repo still carries real Messages host-boundary risk around transcript carriers, reopen behavior, and multiplayer authority
- the current debt already clusters around join authority, transport durability, and host-boundary regression coverage

Scope:

- replace device-local pending joins as the primary roster source with transcript-authoritative multiplayer authority
- move away from relying on full-state transcript carriers alone if Messages host fidelity continues to be unstable
- harden same-bubble recovery and product-visible reload behavior if 12.7 does not fully close them
- add an operator-assisted regression harness for the Messages host boundary

Primary debt links:

- [TD-001](/Users/kunalsharda/Documents/Code/UnluckySevens/docs/exec-plans/tech-debt-tracker.md)
- [TD-005](/Users/kunalsharda/Documents/Code/UnluckySevens/docs/exec-plans/tech-debt-tracker.md)
- [TD-006](/Users/kunalsharda/Documents/Code/UnluckySevens/docs/exec-plans/tech-debt-tracker.md)

### Phase 15 — Extension Decomposition, Test Architecture, and Performance Stabilization

Why this phase exists:

- `MessagesExtension` is still too centralized around a few orchestration surfaces
- duplicated-source test architecture is still a structural maintenance tax
- board redraw/update responsiveness is still tightly coupled to feature orchestration

Scope:

- split the extension more cleanly by host lifecycle, transport adaptation, lobby/game orchestration, board coordination, and debug/operator surfaces
- extract shared seams so tests no longer need to duplicate extension sources
- deepen board and bubble visual regression coverage where the substrate already exists but assertions are still shallow
- stabilize any remaining structural board-performance or interaction-ergonomics issues that should not stay buried in feature code

Primary debt links:

- [TD-002](/Users/kunalsharda/Documents/Code/UnluckySevens/docs/exec-plans/tech-debt-tracker.md)
- [TD-003](/Users/kunalsharda/Documents/Code/UnluckySevens/docs/exec-plans/tech-debt-tracker.md)
- [TD-004](/Users/kunalsharda/Documents/Code/UnluckySevens/docs/exec-plans/tech-debt-tracker.md)

## Not Yet Phased

These items should stay out of the main phase sequence until MVP gameplay, host fidelity, and test architecture are stable:

- deferred product items in [docs/product-specs/deferred-prd-items.md](/Users/kunalsharda/Documents/Code/UnluckySevens/docs/product-specs/deferred-prd-items.md)
- presentation extras such as roll animation polish, richer trade suggestions/history tooling, and broader event-animation layers
- non-MVP platform work such as analytics, crash reporting, localization, monetization, or privacy/compliance expansion
- gameplay variants, 2-player support, AI fill-ins, or scenario-map work

## Update Rules

- update this file when future sequencing changes or a new phase becomes concrete enough to name
- update the active ExecPlan when execution status changes
- update the tech-debt tracker when durable debt is discovered, re-scoped, or resolved
- update the changelog when a phase or major slice is actually landed, not while it is still in progress
