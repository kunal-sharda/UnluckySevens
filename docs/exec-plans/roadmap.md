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

### Phase 12.8 — Full Gameplay Experience

- Owner: [Phase 12 Plan](/Users/kunalsharda/Documents/Code/UnluckySevens/docs/exec-plans/active/phase-12-gameplay-flows.md)
- Status: active
- Why it is still the gate:
  - phase 12.7 closed the authority and severe-lag blockers, but phase 12 still needs one final full-match gameplay pass plus device QA before phase 13
- phase 12 is only complete when a standard base-game Catan match can be started, played, and ended from the Messages UI:
  - invite / join / host start
  - snake-order setup
  - normal turns
  - robber / discard
  - player and maritime trade
  - dev-card play
  - clear winner state
- the board-first overlay-shelf shell is now the gameplay substrate, so the remaining gate is real-device verification that the `Header + Board + Dock` hierarchy, lower-shelf entry, and guided placement/turn affordances hold up for a real match on hardware
  - phase 13 should start only after the full-match gameplay surface is signed off on hardware, not while core match UX is still shifting

Do not start phase 13 until the current 12.8 slice is signed off on real devices.

## Sequenced Next Phases

### Phase 12.8 — Full Gameplay Experience

Why this phase exists:

- phase 12 now has broad gameplay rule coverage, but the last player-facing details still need to close the full standard-match experience before the gameplay phase can end
- the board is the primary interaction surface, so placement trust, idle tap behavior, and turn-shell clarity still matter even when the rules are correct
- the game currently uses opaque participant IDs from Messages, so phase 12 needs a deterministic player-facing naming layer before the shell reads like a real game

Scope:

- finish any remaining player-facing gaps required to complete a standard base-game Catan match in Messages: lobby, setup, turn loop, robber/discard, trade, dev cards, and a clear win state
- finish board interaction correctness and feedback so pan, zoom, tap, and placement feel deterministic and trustworthy across the whole match
- simplify the top-of-shell turn presentation so it shows turn ownership and dice state instead of transport/debug-style context copy
- replace raw participant identifiers with deterministic per-game pseudonyms so the game remains readable across devices without relying on unavailable Messages display names
- reorganize the bottom tray around the common action order: contextual left slot, `End Turn`, `Build`, and `Play Dev`, with `Build` opening a compact shelf for legal build/buy choices
- use the left dock slot contextually so it shows `Roll` before the dice and `Trade` after the roll during normal turn play instead of leaving a spent roll button in place
- keep `Buy Dev` under `Build`, keep bank information quickly accessible through the shared lower shelf, and use the bank shelf as the explicit chooser for Monopoly and Year of Plenty
- keep dev-card timing aligned with the current standard turn flow: playable before or after rolling, but still not on the turn they were acquired unless a Victory Point reveal immediately wins
- replace the old default-driven dev-card shortcuts with staged Knight, Monopoly, Year Of Plenty, and Road Building choice flows that feel like authored product interactions
- keep the current compact trade protocol, but make proposer/respondent state and passive-decline behavior explicit enough that the shell no longer feels like a debug wrapper
- add winner-state and minimal end-of-game clarity so a full played match does not feel unfinished at the moment of victory
- finish with real-device full-match signoff for the phase-12 gameplay surface

Not this phase:

- transcript durability or compact-token rehydration design beyond the temporary one-line fallback bridge
- reload / active-game sync and same-bubble recovery
- transcript collapse / latest-bubble behavior
- multi-game lifecycle, archive/leave/forfeit, or standalone packaging migration
- recap/history/dispute surfaces beyond the minimum winner-state summary
- board-fairness toggles, friendly-robber options, timers, or other non-standard house-rule controls
- broad visual polish unrelated to completing the core base-game loop

Entry criteria:

- phase 12.7 real-device authority and responsiveness are good enough that the remaining work is product-cohesion polish rather than basic input triage
- the core lobby/setup/turn/robber flows can be exercised on real devices without debug-only advancement

### Phase 13 — Messages Host Stability and Release Readiness

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
- execute the [2026-04-13 transport reliability plan](/Users/kunalsharda/Documents/Code/UnluckySevens/docs/quality/audits/2026-04-13-transport-reliability.md) in order — measure, compact board, local cache, delta-encoded STATE, CBOR codec, delete the `summaryText` fallback, and the SMS-fallback resync UX — so `MSMessage.url` is the only data channel and the phase-12 summary mirror can be retired without regressing gameplay
- transcript-authoritative multiplayer ledger instead of device-local pending joins
- explicit multi-game lifecycle UX: identify which game a bubble belongs to, browse active games in the thread, and support leave/archive/forfeit flows instead of assuming one forever-active match
- operator-assisted Messages host-boundary regression harness
- release-readiness hardening for outside testers, including TestFlight-oriented device validation and operator runbooks

Not this phase:

- recap/history/dispute UX beyond what is required to validate release candidates
- deep test-architecture cleanup
- broad visual restyling unrelated to host stability

Entry criteria:

- phase 12 gameplay flows are usable on real devices without relying on debug-first flow advancement
- the clean branch is product-safe enough that host-stability work can proceed without debug leakage muddying outcomes

Primary debt links:

- [TD-006](/Users/kunalsharda/Documents/Code/UnluckySevens/docs/exec-plans/tech-debt-tracker.md)
- [TD-008](/Users/kunalsharda/Documents/Code/UnluckySevens/docs/exec-plans/tech-debt-tracker.md)
- [2026-04-13 transport reliability plan](/Users/kunalsharda/Documents/Code/UnluckySevens/docs/quality/audits/2026-04-13-transport-reliability.md)

Operating rules for this phase:

- The active phase-13 ExecPlan must include an explicit `Assumptions and Evidence Gate` before implementation starts.
- No transport or host-lifecycle path may be treated as canonical unless it is either:
  - documented by Apple as supported for the intended use, or
  - proven on real devices and still labeled provisional until phase acceptance.
- Every host-boundary assumption must record:
  - the assumption
  - the primary-source evidence
  - the device-lane falsification test
  - the fallback if the assumption fails
- Real-device host-lifecycle validation is mandatory before signoff for:
  - send
  - receive
  - bubble selection
  - collapse / latest-bubble behavior
  - reopen after extension restart
  - same-bubble recovery
- Debug-only fallbacks may assist investigation but must not be the reason a product path appears healthy.
- Any new transport path must ship redundantly first when feasible:
  - keep the old path long enough to compare outcomes
  - only remove the fallback after repeated device evidence is strong
- Any use of undocumented framework behavior must be called out immediately in the plan and owner docs as experimental, not silently promoted into architecture.
- Phase 13 should prefer disproving optimistic assumptions early rather than building feature work on top of them.

### Phase 14 — UI Design, Bubble Polish, and Trust Surfaces

Why this phase exists:

- once host stability and release-readiness are in place, the next product slice is broader UI/design polish and clearer trust surfaces
- [docs/decisions.md](/Users/kunalsharda/Documents/Code/UnluckySevens/docs/decisions.md) already locks the intended audit-log behavior
- [docs/product-specs/ui-flows.md](/Users/kunalsharda/Documents/Code/UnluckySevens/docs/product-specs/ui-flows.md) already defines the player-facing recap/history/dispute expectations

Scope:

- transcript bubble presentation polish and board-preview composition
- broader visual coherence across the shell, lower shelf, and game-over surfaces
- motion, turn clarity, and board guidance polish once the substrate is stable
- short last-turn recap in the default UI
- one-round history without overwhelming the main shell
- deliberate dispute mode for full audit inspection
- clearer win-state and final game summary presentation
- trust-surface polish for lobby and in-game states once the host/recovery layer is stable

Primary debt links:

- [TD-001](/Users/kunalsharda/Documents/Code/UnluckySevens/docs/exec-plans/tech-debt-tracker.md)
- [TD-005](/Users/kunalsharda/Documents/Code/UnluckySevens/docs/exec-plans/tech-debt-tracker.md)

### Phase 15 — Extension Decomposition, Test Architecture, and Structural Performance

Why this phase exists:

- `MessagesExtension` is still too centralized around a few orchestration surfaces
- duplicated-source test architecture is still a structural maintenance tax
- host-stability and product-safety work will leave behind cleanup that should not stay mixed into feature code

Scope:

- split the extension more cleanly by host lifecycle, transport adaptation, lobby/game orchestration, board coordination, and debug/operator surfaces
- extract shared seams so tests no longer need to duplicate extension sources
- deepen board and bubble visual regression coverage where the substrate already exists but assertions are still shallow
- add deliberate screen-size and Messages-presentation-size support so the shell and board layout hold up across short, tall, narrow, and larger device classes instead of tuning only for the current primary phone lane
- stabilize any remaining structural board-performance or interaction-ergonomics issues that should not stay buried in feature code

Primary debt links:

- [TD-002](/Users/kunalsharda/Documents/Code/UnluckySevens/docs/exec-plans/tech-debt-tracker.md)
- [TD-003](/Users/kunalsharda/Documents/Code/UnluckySevens/docs/exec-plans/tech-debt-tracker.md)
- [TD-004](/Users/kunalsharda/Documents/Code/UnluckySevens/docs/exec-plans/tech-debt-tracker.md)
- [TD-007](/Users/kunalsharda/Documents/Code/UnluckySevens/docs/exec-plans/tech-debt-tracker.md)
- [2026-04-12 render/perf audit](/Users/kunalsharda/Documents/Code/UnluckySevens/docs/quality/audits/2026-04-12-render-performance.md)

### Phase 16 — Optional Beta-Driven Follow-On

Why this phase exists:

- external testing may surface product gaps that are too real to leave as backlog noise but too specific to hard-code before phases 13 through 15 are complete

Scope:

- only the highest-signal follow-on work discovered through real-world release testing
- backlog items that materially affect MVP completion but cannot be justified until beta evidence exists

Use this phase only if beta feedback makes it necessary. Otherwise skip it and close the milestone after phase 15.

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
