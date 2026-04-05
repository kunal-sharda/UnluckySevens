# Tech Debt Tracker

Track only durable debt that is worth revisiting. Do not use this file for scratch tasks or ephemeral cleanup notes.

## Format

- `ID`
- `Title`
- `Area`
- `Why it matters`
- `Current cost or risk`
- `Proposed fix shape`
- `When to address`
- `Links`

## Open Debt

### TD-001 — No Messages host-boundary regression harness

- Area: `MessagesExtension`, QA
- Why it matters: the engine is well covered, but transcript selection, payload-carrier loss, delayed selection metadata, reopen/lifecycle behavior, and participant identity still rely on manual smoke checks.
- Current cost or risk: regressions at the Messages host boundary can break real-device gameplay even while simulator and engine tests stay green.
- Proposed fix shape: add simulator transcript-selection and reopen harnesses plus an operator-assisted device lane that captures payload source, selection lifecycle, session, and identity diagnostics.
- When to address: phase 10 or immediately after the first real UI shell lands.
- Links: [QA](/Users/kunalsharda/Documents/Code/UnluckySevens/docs/quality/qa.md)

### TD-002 — No production board snapshot coverage yet

- Area: board UI, transcript bubble rendering
- Why it matters: the bubble is a first-class product surface, but there is no stable snapshot regression layer for the future board renderer yet.
- Current cost or risk: visual regressions may slip through even when engine tests are green.
- Proposed fix shape: add snapshot fixtures and snapshot-oriented harnesses alongside the SpriteKit board work.
- When to address: phase 11.
- Links: [README](/Users/kunalsharda/Documents/Code/UnluckySevens/README.md)

### TD-003 — `MessagesExtension` still needs feature-level internal decomposition

- Area: UI architecture
- Why it matters: the engine boundaries are clean, but the extension target is still vulnerable to becoming monolithic and mixing product authority, transcript recovery, and debug tooling.
- Current cost or risk: slower UI iteration, duplicated presentation logic, product gating that can accidentally depend on debug fallbacks, and harder reviewability.
- Proposed fix shape: split the extension internally by feature, presentation, board, transport adaptation, context coordination, and debug/operator surfaces so debug-only fallbacks cannot leak back into product flow.
- When to address: phase 10.
- Links: [ARCHITECTURE.md](/Users/kunalsharda/Documents/Code/UnluckySevens/ARCHITECTURE.md)

### TD-004 — `MessagesExtensionTests` duplicates selected extension sources

- Area: build/test architecture
- Why it matters: Xcode dependency scanning recognizes that the tests import `MessagesExtension`, but Tuist does not allow a direct unit-test dependency on an iMessage extension target in the current project shape.
- Current cost or risk: the workspace test lane emits a persistent warning, and the duplicated-source setup makes future test architecture changes easier to get wrong.
- Proposed fix shape: extract the testable presentation/board seams into a shared library target the extension and tests can both depend on, then remove the duplicated extension sources from the test target.
- When to address: after phase 12 gameplay flows are stable, before deeper UI expansion makes the duplicated-source pattern more expensive.
- Links: [ARCHITECTURE.md](/Users/kunalsharda/Documents/Code/UnluckySevens/ARCHITECTURE.md), [Phase 12 Plan](/Users/kunalsharda/Documents/Code/UnluckySevens/docs/exec-plans/active/phase-12-gameplay-flows.md)

### TD-005 — Lobby roster assembly still depends on device-local pending joins

- Area: lobby authority, multiplayer flow
- Why it matters: host start and early turn ownership should derive from observed join intents, but the current lobby still assembles pending joiners from device-local `UserDefaults`.
- Current cost or risk: a host can see stale or incomplete join state, start a one-player game accidentally, and end up with setup and turn rotation that never include the actual guest.
- Proposed fix shape: replace the local pending-join cache as the primary roster source with a durable transcript-authoritative join ledger, then treat local cache only as temporary recovery aid.
- When to address: immediately after phase 12.7 hardening, before trusting real-device multiplayer signoff.
- Links: [Phase 12 Plan](/Users/kunalsharda/Documents/Code/UnluckySevens/docs/exec-plans/active/phase-12-gameplay-flows.md), [LobbyDriverViewModel.swift](/Users/kunalsharda/Documents/Code/UnluckySevens/MessagesExtension/Sources/Features/Lobby/LobbyDriverViewModel.swift)

### TD-006 — Full-state transcript transport still depends on unstable Messages carriers

- Area: transport, Messages host integration
- Why it matters: the current transcript helper still relies on full payloads surviving in `message.url` and, in debug, `summaryText`, even though real-device selection has already shown carrier loss and delayed metadata.
- Current cost or risk: cross-device state recovery can succeed or fail depending on Messages host behavior rather than only on app logic, making signoff fragile and regressions hard to localize.
- Proposed fix shape: move toward compact transcript tokens plus durable rehydration, with URL and summary integrity checks during the transition, instead of treating transcript selection as full-fidelity state persistence.
- When to address: after phase 12.7 multiplayer hardening, before expanding transcript-dependent flows further.
- Links: [docs/decisions.md](/Users/kunalsharda/Documents/Code/UnluckySevens/docs/decisions.md), [Phase 12 Plan](/Users/kunalsharda/Documents/Code/UnluckySevens/docs/exec-plans/active/phase-12-gameplay-flows.md)
