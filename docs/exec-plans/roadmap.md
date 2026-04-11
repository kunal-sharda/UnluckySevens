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

### Phase 12.8 — Gameplay Product Cohesion

- Owner: [Phase 12 Plan](/Users/kunalsharda/Documents/Code/UnluckySevens/docs/exec-plans/active/phase-12-gameplay-flows.md)
- Status: active
- Why it is still the gate:
  - phase 12.7 closed the authority and severe-lag blockers, but phase 12 still needs one final product-cohesion pass plus device QA before phase 13
  - the game shell now exposes the full turn loop, but the player-facing experience still needs final verification around build/dev-card affordances, consistent player aliases, and simpler turn presentation
  - phase 13 should start only after the current full-match gameplay surface is signed off on hardware, not while phase-12 UX details are still shifting

Do not start phase 13 until the current 12.8 slice is signed off on real devices.

## Sequenced Next Phases

### Phase 12.8 — Gameplay Product Cohesion

Why this phase exists:

- phase 12 now has broad gameplay rule coverage, but the last player-facing details still need to feel intentional before the gameplay phase can close
- the board is the primary interaction surface, so placement trust, idle tap behavior, and turn-shell clarity still matter even when the rules are correct
- the game currently uses opaque participant IDs from Messages, so phase 12 needs a deterministic player-facing naming layer before the shell reads like a real game

Scope:

- finish board interaction correctness and feedback so pan, zoom, tap, and placement feel deterministic and trustworthy across the whole match
- simplify the top-of-shell turn presentation so it shows turn ownership and dice state instead of transport/debug-style context copy
- replace raw participant identifiers with deterministic per-game pseudonyms so the game remains readable across devices without relying on unavailable Messages display names
- reorganize the bottom tray around the common action order: `Roll`, `End Turn`, `Build`, and `Play Dev`, with `Build` opening a compact shelf for legal build/buy choices
- keep `Buy Dev` under `Build`, keep the public bank tray visible near the hand tray, and use that tray as the explicit chooser for Monopoly and Year of Plenty
- keep dev-card timing aligned with the current standard turn flow: playable before or after rolling, but still not on the turn they were acquired unless a Victory Point reveal immediately wins
- replace the old default-driven dev-card shortcuts with staged Knight, Monopoly, Year Of Plenty, and Road Building choice flows that feel like authored product interactions
- keep the current compact trade protocol, but make proposer/respondent state and passive-decline behavior explicit enough that the shell no longer feels like a debug wrapper
- add any minimal end-of-game clarity needed so a full played match does not feel unfinished at the moment of victory
- finish with real-device full-match signoff for the phase-12 gameplay surface

Not this phase:

- transcript durability or compact-token rehydration design
- reload / active-game sync and same-bubble recovery
- transcript collapse / latest-bubble behavior
- multi-game lifecycle, archive/leave/forfeit, or standalone packaging migration
- a custom free-form trade composer, counteroffers, or player-configurable display names

Entry criteria:

- phase 12.7 real-device authority and responsiveness are good enough that the remaining work is product-cohesion polish rather than basic input triage
- the core lobby/setup/turn/robber flows can be exercised on real devices without debug-only advancement

### Phase 13 — Messages Host Stability and Recovery

Why this phase exists:

- phase 12 intentionally leaves reload / active-game sync, transcript collapse behavior, and durable game identity unresolved on the clean branch
- the current repo still carries real Messages host-boundary risk around transcript carriers, reopen behavior, and multiplayer durability
- the active debt already clusters around join authority, transport durability, and host-boundary regression coverage

Scope:

- migrate from the current containing-app development shell to the intended standalone iMessage app packaging/distribution model
- join/lobby responsiveness so join intents resolve back into the known lobby for that game instead of requiring users to reopen a newer bubble just to see updated membership
- turn publication and cross-device responsiveness so normal actions do not feel artificially slow just because each step is waiting on Messages-host round-trip behavior
- reliable reload / active-game sync and same-bubble recovery
- transcript readability / collapse behavior and latest-bubble UX
- transcript-authoritative multiplayer ledger instead of device-local pending joins
- compact-token plus durable rehydration direction if full-state carrier fidelity remains unstable
- explicit multi-game lifecycle UX: identify which game a bubble belongs to, browse active games in the thread, and support leave/archive/forfeit flows instead of assuming one forever-active match
- operator-assisted Messages host-boundary regression harness

Not this phase:

- recap/history/dispute UX
- deep test-architecture cleanup
- broad visual restyling unrelated to host stability

Entry criteria:

- phase 12 gameplay flows are usable on real devices without relying on debug-first flow advancement
- the clean branch is product-safe enough that host-stability work can proceed without debug leakage muddying outcomes

### Phase 14 — Recap, History, Dispute, and Trust Surfaces

Why this phase exists:

- once host stability is in place, the next product slice is recap/history/dispute and clearer trust surfaces
- [docs/decisions.md](/Users/kunalsharda/Documents/Code/UnluckySevens/docs/decisions.md) already locks the intended audit-log behavior
- [docs/product-specs/ui-flows.md](/Users/kunalsharda/Documents/Code/UnluckySevens/docs/product-specs/ui-flows.md) already defines the player-facing recap/history/dispute expectations

Scope:

- short last-turn recap in the default UI
- one-round history without overwhelming the main shell
- deliberate dispute mode for full audit inspection
- clearer win-state and final game summary presentation
- trust-surface polish for lobby and in-game states once the host/recovery layer is stable

Primary debt links:

- [TD-001](/Users/kunalsharda/Documents/Code/UnluckySevens/docs/exec-plans/tech-debt-tracker.md)

### Phase 15 — Extension Decomposition, Test Architecture, and Performance Stabilization

Why this phase exists:

- `MessagesExtension` is still too centralized around a few orchestration surfaces
- duplicated-source test architecture is still a structural maintenance tax
- host-stability and product-safety work will leave behind cleanup that should not stay mixed into feature code

Scope:

- split the extension more cleanly by host lifecycle, transport adaptation, lobby/game orchestration, board coordination, and debug/operator surfaces
- extract shared seams so tests no longer need to duplicate extension sources
- deepen board and bubble visual regression coverage where the substrate already exists but assertions are still shallow
- stabilize any remaining structural board-performance or interaction-ergonomics issues that should not stay buried in feature code

Primary debt links:

- [TD-002](/Users/kunalsharda/Documents/Code/UnluckySevens/docs/exec-plans/tech-debt-tracker.md)
- [TD-003](/Users/kunalsharda/Documents/Code/UnluckySevens/docs/exec-plans/tech-debt-tracker.md)
- [TD-004](/Users/kunalsharda/Documents/Code/UnluckySevens/docs/exec-plans/tech-debt-tracker.md)
- [TD-005](/Users/kunalsharda/Documents/Code/UnluckySevens/docs/exec-plans/tech-debt-tracker.md)
- [TD-006](/Users/kunalsharda/Documents/Code/UnluckySevens/docs/exec-plans/tech-debt-tracker.md)

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
