# Tech Debt Tracker

Track only durable debt that is worth revisiting. Do not use this file for scratch tasks or ephemeral cleanup notes.

Use [roadmap.md](/Users/kunalsharda/Documents/Code/UnluckySevens/docs/exec-plans/roadmap.md) for sequencing. Use this file for debt that should survive the current phase even if the exact implementation plan is not active yet.

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
- When to address: phase 13.
- Links: [QA](/Users/kunalsharda/Documents/Code/UnluckySevens/docs/quality/qa.md)

### TD-002 — Production board visual assertions are still shallow

- Area: board UI, transcript bubble rendering
- Why it matters: the snapshot substrate exists, but the current assertions still do not protect enough real gameplay board states, bubble variants, or device-sized board compositions.
- Current cost or risk: visual regressions can still slip through even when engine tests and focused extension tests are green.
- Proposed fix shape: deepen snapshot fixtures and visual assertions around production gameplay states, transcript-bubble variants, and device-sized board surfaces.
- When to address: phase 15, unless an urgent visual regression forces an earlier slice.
- Links: [Phase 11 Plan](/Users/kunalsharda/Documents/Code/UnluckySevens/docs/exec-plans/completed/phase-11-spritekit-board.md), [QA](/Users/kunalsharda/Documents/Code/UnluckySevens/docs/quality/qa.md)

### TD-003 — `MessagesExtension` still needs feature-level internal decomposition

- Area: UI architecture
- Why it matters: the engine boundaries are clean, but the extension target is still vulnerable to becoming monolithic and mixing product authority, transcript recovery, board update coordination, and debug tooling.
- Current cost or risk: slower UI iteration, board redraw churn, product gating that can accidentally depend on debug fallbacks, and harder reviewability when host-boundary logic and feature logic live in the same places.
- Proposed fix shape: split the extension internally by host lifecycle/context recovery, transport adaptation, lobby/game orchestration, board-scene coordination, and debug/operator surfaces so debug-only fallbacks cannot leak back into product flow.
- When to address: phase 15.
- Links: [ARCHITECTURE.md](/Users/kunalsharda/Documents/Code/UnluckySevens/ARCHITECTURE.md)

### TD-004 — `MessagesExtensionTests` duplicates selected extension sources

- Area: build/test architecture
- Why it matters: Xcode dependency scanning recognizes that the tests import `MessagesExtension`, but Tuist does not allow a direct unit-test dependency on an iMessage extension target in the current project shape.
- Current cost or risk: the workspace test lane emits a persistent warning, and the duplicated-source setup makes future test architecture changes easier to get wrong.
- Proposed fix shape: extract the testable presentation/board seams into a shared library target the extension and tests can both depend on, then remove the duplicated extension sources from the test target.
- When to address: phase 15.
- Links: [ARCHITECTURE.md](/Users/kunalsharda/Documents/Code/UnluckySevens/ARCHITECTURE.md), [Phase 12 Plan](/Users/kunalsharda/Documents/Code/UnluckySevens/docs/exec-plans/active/phase-12-gameplay-flows.md)

### TD-005 — Lobby roster assembly still depends on device-local pending joins

- Area: lobby authority, multiplayer flow
- Why it matters: host start and early turn ownership should derive from observed join intents, but the current lobby still assembles pending joiners from device-local `UserDefaults`.
- Current cost or risk: a host can see stale or incomplete join state, start a one-player game accidentally, and end up with setup and turn rotation that never include the actual guest.
- Proposed fix shape: replace the local pending-join cache as the primary roster source with a durable transcript-authoritative join ledger, then treat local cache only as temporary recovery aid.
- When to address: phase 13.
- Links: [Phase 12 Plan](/Users/kunalsharda/Documents/Code/UnluckySevens/docs/exec-plans/active/phase-12-gameplay-flows.md), [LobbyDriverViewModel.swift](/Users/kunalsharda/Documents/Code/UnluckySevens/MessagesExtension/Sources/Features/Lobby/LobbyDriverViewModel.swift)

### TD-006 — Full-state transcript transport still depends on unstable Messages carriers

- Area: transport, Messages host integration
- Why it matters: the current transcript helper still relies on full payloads surviving in `message.url` and, during the temporary phase-12 production fallback, a one-line mirrored `summaryText`, even though real-device selection has already shown carrier loss and delayed metadata.
- Current cost or risk: cross-device state recovery can succeed or fail depending on Messages host behavior rather than only on app logic, making signoff fragile and regressions hard to localize.
- Proposed fix shape: move toward compact transcript tokens plus durable rehydration, with URL and summary integrity checks during the transition, instead of treating transcript selection as full-fidelity state persistence. The concrete working plan now lives in [TD-008](#td-008--transport-reliability-plan-for-msmessageurl) and the 2026-04-13 audit it links.
- When to address: phase 13.
- Links: [docs/decisions.md](/Users/kunalsharda/Documents/Code/UnluckySevens/docs/decisions.md), [Phase 12 Plan](/Users/kunalsharda/Documents/Code/UnluckySevens/docs/exec-plans/active/phase-12-gameplay-flows.md), [TD-008](#td-008--transport-reliability-plan-for-msmessageurl)

### TD-007 — Board and shell render paths rebuild shared inputs on every update

- Area: `MessagesExtension` board rendering, `ULS_CoreGame` query economy, SwiftUI projection churn
- Why it matters: the 2026-04-12 render/perf audit traced observable device lag to a stack of pure rebuilds that happen on every state update, every tap, and every overlay change. `StandardBoardTopologyV1.standard()` and `.renderGeometry()` are plain functions called repeatedly from every legal-move query, `GameBoardLayout` re-derives every tile/node position on every property access, `GameBoardRenderModelBuilder` has no memoization, and `GameShellProjection` bundles ~36 debug strings alongside the render model so `removeDuplicates()` walks all of them on every publish. `LobbyDriverViewModel` also still declares 29 `@Published` fields, most of which are debug telemetry.
- Current cost or risk: phase 12.8 has been compensating with board freezes, watchdogs, snapshot fallbacks, and an `SKView` host wrapper. Those fixes mask the amplification but do not remove it. Real-device responsiveness will remain worse than necessary until the topology/layout/projection allocations are eliminated, and every new board or shell feature pays the same amplifier.
- Proposed fix shape: work the audit's ordered list — cache `StandardBoardTopologyV1.standard` and `.renderGeometry` as `static let`, precompute `GameBoardLayout` in `init`, add adjacency tables to `BoardGraphV1`, memoize `GameBoardRenderModelBuilder` by `state.stateHash`, split debug and render projections, and reduce `LobbyDriverViewModel`'s `@Published` surface to the fields the shell actually reads.
- When to address: phase 15 — structural performance and decomposition. `F1` in the audit (`static let` topology) is a one-line change and can be pulled forward into phase 12.8 if real-device device QA still feels chunky after the current freeze/shield hardening; the rest of the list belongs with the structural decomposition slice.
- Links: [2026-04-12 render/perf audit](/Users/kunalsharda/Documents/Code/UnluckySevens/docs/quality/audits/2026-04-12-render-performance.md), [Phase 12 Plan](/Users/kunalsharda/Documents/Code/UnluckySevens/docs/exec-plans/active/phase-12-gameplay-flows.md)

### TD-008 — Transport reliability plan for `MSMessage.url`

- Area: `ULS_Transport`, `MessagesExtension` transcript support, Messages host integration
- Why it matters: the 2026-04-13 transport-reliability plan documents the full channel inventory on `MSMessage` and confirms that `MSMessage.url` is the only real data channel. Everything else is either user-visible (leak risk) or not a data channel at all. The current system is either leaky (when the `summaryText` mirror is on) or broken (when it is off) past the ~1–2 KB size cliff seen on real devices.
- Current cost or risk: every phase-12 transport fix so far has been incremental hardening on top of the same unreliable carrier. Cross-device reliability, pruned-bubble recovery, and SMS-fallback behavior cannot be solved with one more carrier-level tweak; they need the shrinkage program and the local cache together.
- Proposed fix shape: execute the seven-phase plan in order — Phase 1 measure → Phase 2 compact board → Phase 5 persistent local cache → Phase 3 delta-encode STATE → Phase 4 CBOR codec → Phase 6 delete `summaryText` fallback → Phase 7 SMS-fallback detection plus resync UX. Do not skip Phase 1; optimize against the measured baseline rather than intuition.
- When to address: phase 13. This replaces the vague "compact transcript tokens plus durable rehydration" phase-13 scope bullet with a concrete pre-plan that already has acceptance criteria per phase.
- Links: [2026-04-13 transport reliability plan](/Users/kunalsharda/Documents/Code/UnluckySevens/docs/quality/audits/2026-04-13-transport-reliability.md), [2026-04-12 render/perf audit](/Users/kunalsharda/Documents/Code/UnluckySevens/docs/quality/audits/2026-04-12-render-performance.md), [docs/decisions.md](/Users/kunalsharda/Documents/Code/UnluckySevens/docs/decisions.md), [Phase 12 Plan](/Users/kunalsharda/Documents/Code/UnluckySevens/docs/exec-plans/active/phase-12-gameplay-flows.md), [TD-006](#td-006--full-state-transcript-transport-still-depends-on-unstable-messages-carriers)
