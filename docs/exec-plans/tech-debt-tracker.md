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
- Proposed fix shape: split the extension internally by host lifecycle/context recovery, transport adaptation, lobby/game orchestration, board-scene coordination, and debug/operator surfaces. Isolate the required Messages selection watch behind a cancellable lifecycle component instead of leaving its manual polling token and scheduling inside `MessagesViewController`, and migrate presentation ownership away from the catch-all `LobbyDriverViewModel` without changing Core or transport authority.
- When to address: phase 15.
- Links: [ARCHITECTURE.md](/Users/kunalsharda/Documents/Code/UnluckySevens/ARCHITECTURE.md), [LobbyDriverViewModel.swift](/Users/kunalsharda/Documents/Code/UnluckySevens/MessagesExtension/Sources/Features/Lobby/LobbyDriverViewModel.swift), [MessagesViewController.swift](/Users/kunalsharda/Documents/Code/UnluckySevens/MessagesExtension/Sources/App/MessagesViewController.swift)

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
- Current cost or risk: real-device responsiveness will remain worse than necessary until the topology/layout/projection allocations are eliminated, and every new board or shell feature pays the same amplification. The current shell projection still mixes product models with a large stringified diagnostic surface, while `LobbyDriverViewModel` retains a writable pass-through facade for those legacy fields.
- Proposed fix shape: work the ordered audit list — cache topology/render geometry, precompute layout, memoize render-model building, split debug and render projections, remove unused writable projection pass-throughs, and keep only diagnostics that have a named DEBUG or operator consumer.
- When to address: phase 15.
- Links: [2026-04-12 render/perf audit](/Users/kunalsharda/Documents/Code/UnluckySevens/docs/quality/audits/2026-04-12-render-performance.md), [GameShellProjection.swift](/Users/kunalsharda/Documents/Code/UnluckySevens/MessagesExtension/Sources/Presentation/GameShellProjection.swift), [LobbyDriverViewModel.swift](/Users/kunalsharda/Documents/Code/UnluckySevens/MessagesExtension/Sources/Features/Lobby/LobbyDriverViewModel.swift)

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

### TD-011 — Core build costs have multiple matching definitions

- Area: `ULS_CoreGame` economy rules and presentation queries
- Why it matters: `CoreBuildCostsV1` now gives presentation a Core-owned cost source, but reducers, validation, and legal-build queries still contain matching literals.
- Current cost or risk: the values agree today, but a future rule adjustment could make displayed costs drift from validation or mutation behavior.
- Proposed fix shape: route reducer, validation, and build-query costs through `CoreBuildCostsV1`, then add one regression test that covers every build and development-card cost consumer.
- When to address: phase 15, before changing economy rules.
- Links: [CoreBuildCostsV1.swift](/Users/kunalsharda/Documents/Code/UnluckySevens/Packages/ULS_CoreGame/Sources/ULS_CoreGame/CoreBuildCostsV1.swift), [ARCHITECTURE.md](/Users/kunalsharda/Documents/Code/UnluckySevens/ARCHITECTURE.md)

### TD-012 — Resolved: ExecPlan terminal-state and flow-narration cleanup

- Area: execution harness and product-plan freshness
- Why it matters: repository audit found two plans with terminal contracts still under `active/`, while the lobby plan retains narration from the pre-Settings/Tutorial learning flow.
- Resolution: terminal branch-maintenance, discard, Settings/Tutorial, and UI-flow-audit plans moved to `completed/`; the lobby plan now links the completed learning-surface work while retaining only its genuinely pending release invite constraints.
- Resolved: 2026-07-25.
- Links: [Discard Screen](completed/discard-screen.md), [Branch Archive and Master Baseline](completed/branch-archive-and-master-baseline.md), [Settings, Rules, and Click-Through Tutorial](completed/settings-rules-tutorial.md), [UI Flow Contract Audit](completed/ui-flow-contract-audit.md), [Lobby Invite Screen](active/lobby-invite-screen.md)

### TD-013 — Superseded UI types remain in the production source target

- Area: `MessagesExtension` source hygiene
- Why it matters: rejected or replaced implementations should leave the shipping source graph once their successor is established, otherwise future searches and refactors cannot distinguish current UI from historical scaffolding.
- Current cost or risk: `ActionDockView`, `LobbyGameSettingsSheet`, and `GameDevCardChimneyMarkView` have no source references outside their declarations but are still compiled into the extension target through the broad source glob.
- Proposed fix shape: delete the three unreferenced types, regenerate through the canonical script, build the Messages target, and add a lightweight orphan-type/reference scan to structural-cleanup reviews rather than creating permanent tooling for a three-file deletion.
- When to address: immediately; this is a small direct cleanup that does not need to wait for phase 15.
- Links: [ActionDockView.swift](/Users/kunalsharda/Documents/Code/UnluckySevens/MessagesExtension/Sources/Components/ActionDockView.swift), [LobbyGameSettingsSheet.swift](/Users/kunalsharda/Documents/Code/UnluckySevens/MessagesExtension/Sources/Features/Lobby/LobbyGameSettingsSheet.swift), [GameDevCardChimneyMarkView.swift](/Users/kunalsharda/Documents/Code/UnluckySevens/MessagesExtension/Sources/Components/GameDevCardChimneyMarkView.swift)

### TD-014 — Legacy tabletop presentation branches coexist with Physical Props

- Area: gameplay UI architecture, visual-system migration
- Why it matters: the extension still carries `framedShelf`, `framelessShelf`, `feltTools`, and `physicalProps` presentation families plus parallel tray, modal, trade, and freeze-overlay implementations.
- Current cost or risk: every gameplay change must reason about multiple visual systems, legacy branches can survive only because DEBUG comparison controls still exercise them, and release states not yet migrated can silently preserve an older product language.
- Proposed fix shape: inventory the release routes that still resolve to the old stack, finish or explicitly defer their product migration, keep approved comparison fixtures under DEBUG only, and then remove unreachable legacy bodies and layout modes with focused route and installed-host coverage.
- When to address: start at phase 14 closeout and finish as an early phase 15 slice; do not bulk-delete until remaining release routes are mapped.
- Links: [GameTabletopLayoutStyle.swift](/Users/kunalsharda/Documents/Code/UnluckySevens/MessagesExtension/Sources/Presentation/GameTabletopLayoutStyle.swift), [GameShellView.swift](/Users/kunalsharda/Documents/Code/UnluckySevens/MessagesExtension/Sources/Features/Game/GameShellView.swift), [GameModalHostView.swift](/Users/kunalsharda/Documents/Code/UnluckySevens/MessagesExtension/Sources/Components/GameModalHostView.swift)

### TD-015 — Local game ledger has no retention or schema lifecycle

- Area: transcript recovery, local persistence
- Why it matters: `TranscriptGameLedgerStore` persists a complete canonical-state payload for every indexed game in `UserDefaults`, but has no record version, retention bound, or corrupt-entry cleanup.
- Current cost or risk: long-running beta installs can accumulate stale payloads indefinitely, and decode or encode failures currently fail soft without removing the bad entry or preserving an actionable recovery diagnostic.
- Proposed fix shape: version the stored record, cap retained inactive games using a documented policy, remove or quarantine corrupt entries, expose a useful recovery failure signal, and add migration, pruning, and corruption tests.
- When to address: phase 15 before broad beta accumulation; pull forward if TestFlight recovery diagnostics show ledger growth or decode failures.
- Links: [TranscriptGameLedger.swift](/Users/kunalsharda/Documents/Code/UnluckySevens/MessagesExtension/Sources/Presentation/TranscriptGameLedger.swift), [Messages host lessons](/Users/kunalsharda/Documents/Code/UnluckySevens/docs/quality/messages-host.md)

### TD-016 — Board-art owner docs and runtime asset usage disagree

- Area: board assets, design source of truth, repository hygiene
- Why it matters: `DESIGN.md` and the durable cleanup receipt identify `BoardTiles` as production terrain assets, while the current runtime renderer loads `BoardStamps` and `BoardMiniStamps`; the six `tile_*` images have no discovered runtime reference.
- Current cost or risk: agents cannot safely decide whether the binary tiles are protected production inputs or superseded baggage, so cleanup can either delete approved art or preserve unused assets and stale documentation indefinitely.
- Proposed fix shape: make one explicit design decision based on the installed production board: either restore `BoardTiles` as the renderer input, or declare the stamp-based board canonical, update `DESIGN.md` and the cleanup receipt, and remove superseded tile and uncolored merchant-ship assets after reference and installed-bundle verification.
- When to address: immediately after the current visual checkpoint, before aggressive asset cleanup or phase 15 decomposition.
- Links: [DESIGN.md](/Users/kunalsharda/Documents/Code/UnluckySevens/DESIGN.md), [GameBoardTileArt.swift](/Users/kunalsharda/Documents/Code/UnluckySevens/MessagesExtension/Sources/Board/GameBoardTileArt.swift), [cleanup receipt](/Users/kunalsharda/Documents/Code/UnluckySevens/docs/design/cleanup-receipt.md)
