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
- When to address: phase 14 or 15, depending on how much external testing pressure accumulates after TestFlight starts.
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
- Current cost or risk: slower UI iteration, board redraw churn, and harder reviewability when host-boundary logic and feature logic live in the same places.
- Proposed fix shape: split the extension internally by host lifecycle/context recovery, transport adaptation, lobby/game orchestration, board-scene coordination, and debug/operator surfaces.
- When to address: phase 15.
- Links: [ARCHITECTURE.md](/Users/kunalsharda/Documents/Code/UnluckySevens/ARCHITECTURE.md)

### TD-004 — `MessagesExtensionTests` duplicates selected extension sources

- Area: build/test architecture
- Why it matters: Xcode dependency scanning recognizes that the tests import `MessagesExtension`, but Tuist does not allow a direct unit-test dependency on an iMessage extension target in the current project shape.
- Current cost or risk: the workspace test lane emits a persistent warning, and the duplicated-source setup makes future test architecture changes easier to get wrong.
- Proposed fix shape: extract the testable presentation/board seams into a shared library target the extension and tests can both depend on, then remove the duplicated extension sources from the test target.
- When to address: phase 15.
- Links: [ARCHITECTURE.md](/Users/kunalsharda/Documents/Code/UnluckySevens/ARCHITECTURE.md)

### TD-005 — Lobby roster assembly still depends on observed-join merge

- Area: lobby authority, multiplayer flow
- Why it matters: fresh join now advances canonical lobby `STATE`, but concurrent joins from the same older lobby rev can still arrive as sibling lobby states. The host currently converges those at `Start Game` time by unioning the latest visible lobby roster with the local observed-join ledger.
- Current cost or risk: the lobby can still show an incomplete roster transiently until the host sees both sibling join states or starts from a merged roster.
- Proposed fix shape: replace the remaining observed-join merge with an explicit transcript-authoritative lobby reconciliation model so concurrent joins converge before start, not only at start.
- When to address: phase 14 if real-device concurrency shows visible lobby skew; otherwise later.
- Links: [LobbyDriverViewModel.swift](/Users/kunalsharda/Documents/Code/UnluckySevens/MessagesExtension/Sources/Features/Lobby/LobbyDriverViewModel.swift), [docs/product-specs/ui-flows.md](/Users/kunalsharda/Documents/Code/UnluckySevens/docs/product-specs/ui-flows.md)

### TD-007 — Board and shell render paths rebuild shared inputs on every update

- Area: `MessagesExtension` board rendering, `ULS_CoreGame` query economy, SwiftUI projection churn
- Why it matters: the 2026-04-12 render/perf audit traced observable device lag to a stack of pure rebuilds that happen on every state update, every tap, and every overlay change.
- Current cost or risk: real-device responsiveness will remain worse than necessary until the topology/layout/projection allocations are eliminated, and every new board or shell feature pays the same amplification.
- Proposed fix shape: work the ordered audit list — cache topology/render geometry, precompute layout, memoize render-model building, split debug and render projections, and reduce the published debug surface that the shell does not actually read.
- When to address: phase 15.
- Links: [2026-04-12 render/perf audit](/Users/kunalsharda/Documents/Code/UnluckySevens/docs/quality/audits/2026-04-12-render-performance.md)

### TD-009 — Simultaneous targeted trade accept is still nondeterministic

- Area: trade authority, multiplayer flow
- Why it matters: two targeted recipients can still accept the same live offer from stale copies of the same state before either sees the other's accepted state.
- Current cost or risk: the game should still converge, but which accept wins is currently delivery-order-driven rather than deterministic first-wins.
- Proposed fix shape: add latest-known-state gating before authoring `Accept`, then choose a durable resolution model: deterministic tie-break or explicit serialized authority.
- When to address: phase 16 unless TestFlight exposes it as a material player-facing problem sooner.
- Links: [TradeInteractionResolver.swift](/Users/kunalsharda/Documents/Code/UnluckySevens/MessagesExtension/Sources/Presentation/TradeInteractionResolver.swift), [TranscriptStateSelection.swift](/Users/kunalsharda/Documents/Code/UnluckySevens/MessagesExtension/Sources/Presentation/TranscriptStateSelection.swift)

### TD-010 — Session continuity can still fork after sessionless recovery

- Area: transcript continuity, Messages host integration
- Why it matters: if a publish happens from recovered canonical state with neither a selected same-game session nor a cached session, the transport helper still creates a fresh `MSSession`.
- Current cost or risk: transcript collapse/readability can degrade even though the underlying game state remains valid.
- Proposed fix shape: persist or derive stronger same-game session continuity so recovery-published `STATE` prefers the existing game chain instead of falling back to a fresh session.
- When to address: phase 15 unless real-device TestFlight feedback shows transcript clutter becoming materially confusing sooner.
- Links: [TranscriptTransportSupport.swift](/Users/kunalsharda/Documents/Code/UnluckySevens/MessagesExtension/Sources/Presentation/TranscriptTransportSupport.swift)
