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

### TD-003 — Resolved: `MessagesExtension` feature responsibilities are isolated

- Area: UI architecture
- Resolution: the controller now delegates through a narrow host runtime; selection watching is lifecycle-cancellable and generation-gated; GameShell trade/draft presentation, lobby recovery policy, production projection, DEBUG diagnostics, and fixture registry responsibilities have focused seams. The lobby and shell types remain intentional state-owner/orchestration facades, while Core and Transport stay authoritative.
- Resolved: 2026-08-21.
- Links: [ARCHITECTURE.md](/Users/kunalsharda/Documents/Code/UnluckySevens/ARCHITECTURE.md), [LobbyDriverViewModel.swift](/Users/kunalsharda/Documents/Code/UnluckySevens/MessagesExtension/Sources/Features/Lobby/LobbyDriverViewModel.swift), [MessagesViewController.swift](/Users/kunalsharda/Documents/Code/UnluckySevens/MessagesExtension/Sources/App/MessagesViewController.swift)

### TD-004 — Resolved: extension and tests share one compiled support module

- Area: build/test architecture
- Resolution: extension implementation sources compile once in the static, extension-safe `MessagesExtensionSupport` target. The shipping target keeps only Apple host glue and the custom resize shield; tests import support and compile no production source paths. Release packaging embeds no support framework and the former undeclared dependency warning is absent.
- Resolved: 2026-08-21.
- Links: [ARCHITECTURE.md](/Users/kunalsharda/Documents/Code/UnluckySevens/ARCHITECTURE.md)

### TD-005 — Lobby roster assembly still depends on observed-join merge

- Area: lobby authority, multiplayer flow
- Why it matters: fresh join now advances canonical lobby `STATE`, but concurrent joins from the same older lobby rev can still arrive as sibling lobby states. The host currently converges those at `Start Game` time by unioning the latest visible lobby roster with the local observed-join ledger.
- Current cost or risk: the lobby can still show an incomplete roster transiently until the host sees both sibling join states or starts from a merged roster.
- Proposed fix shape: replace the remaining observed-join merge with an explicit transcript-authoritative lobby reconciliation model so concurrent joins converge before start, not only at start.
- When to address: phase 14 if real-device concurrency shows visible lobby skew; otherwise later.
- Links: [LobbyDriverViewModel.swift](/Users/kunalsharda/Documents/Code/UnluckySevens/MessagesExtension/Sources/Features/Lobby/LobbyDriverViewModel.swift), [docs/product-specs/ui-flows.md](/Users/kunalsharda/Documents/Code/UnluckySevens/docs/product-specs/ui-flows.md)

### TD-007 — Remaining board and shell render paths rebuild shared inputs on every update

- Area: `MessagesExtension` board rendering, `ULS_CoreGame` query economy, SwiftUI projection churn
- Why it matters: the 2026-04-12 render/perf audit traced observable device lag to a stack of pure rebuilds that happen on every state update, every tap, and every overlay change.
- Current cost or risk: remaining SpriteKit node construction, render-model rebuilding, adjacency walks, and query amplification still need device profiling and targeted optimization. This slice does not claim measured device-latency improvement.
- Progress: F1, F2, F6, F7, and the repeated bounds work in F17 were resolved on 2026-08-21. Topology/render geometry share one lazy cache; `GameBoardLayout` precomputes immutable geometry once; production projection is separate from DEBUG diagnostics; the writable diagnostic pass-through facade is gone.
- Proposed fix shape: continue with measured work only: F3–F5, F8–F16, and F18–F21 remain candidates, led by render-model memoization, adjacency/query economy, and SpriteKit layer diffing where profiling confirms value.
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
- Current policy: recovery-published `STATE` prefers the selected same-game session, then an in-memory cached session, and deliberately creates a fresh `Game Restored` bubble when neither survives. Persisted `MSSession` data is not trusted by assumption.
- Proposed fix shape: run the locked secure-archive/restart experiment on two connected devices and retain persistence only if the restored session replaces/collapses the original game bubble on both devices.
- When to address: the release-critical TestFlight pass; the 2026-07-26 Pass 1 attempt found all available iPhone/iPad hardware offline.
- Links: [TranscriptTransportSupport.swift](/Users/kunalsharda/Documents/Code/UnluckySevens/MessagesExtension/Sources/Presentation/TranscriptTransportSupport.swift)

### TD-011 — Resolved: Core build costs have one production definition

- Area: `ULS_CoreGame` economy rules and presentation queries
- Resolution: reducers, transition validation, legal-build queries, development-card drafting, and lobby purchase availability now converge on `CoreBuildCostsV1`; table-driven Core and extension tests cover exact-cost deductions, bank repayment, validation, legal queries, and one-short rejection.
- Resolved: 2026-08-21.
- Links: [CoreBuildCostsV1.swift](/Users/kunalsharda/Documents/Code/UnluckySevens/Packages/ULS_CoreGame/Sources/ULS_CoreGame/CoreBuildCostsV1.swift), [ARCHITECTURE.md](/Users/kunalsharda/Documents/Code/UnluckySevens/ARCHITECTURE.md)

### TD-012 — Resolved: ExecPlan terminal-state and flow-narration cleanup

- Area: execution harness and product-plan freshness
- Why it matters: repository audit found two plans with terminal contracts still under `active/`, while the lobby plan retains narration from the pre-Settings/Tutorial learning flow.
- Resolution: terminal branch-maintenance, discard, Settings/Tutorial, and UI-flow-audit plans moved to `completed/`; the lobby plan now links the completed learning-surface work while retaining only its genuinely pending release invite constraints.
- Resolved: 2026-07-25.
- Links: [Discard Screen](completed/discard-screen.md), [Branch Archive and Master Baseline](completed/branch-archive-and-master-baseline.md), [Settings, Rules, and Click-Through Tutorial](completed/settings-rules-tutorial.md), [UI Flow Contract Audit](completed/ui-flow-contract-audit.md), [Lobby Invite Screen](completed/lobby-invite-screen.md)

### TD-013 — Resolved: superseded standalone UI types removed

- Area: `MessagesExtension` source hygiene
- Why it mattered: rejected or replaced implementations obscured the shipping source graph because the broad source glob continued compiling declarations with no call sites.
- Resolution: the final cohesion pass removed `ActionDockView`, `LobbyGameSettingsSheet`, `GameDevCardChimneyMarkView`, and the likewise unreferenced `GameFinalScorePlayerView` after source, test, and harness searches confirmed they had no consumers.
- Resolved: 2026-08-10.
- Links: [Final UI cohesion and legacy removal](completed/final-ui-cohesion-and-legacy-removal.md)

### TD-014 — Resolved: legacy tabletop presentation branches removed

- Area: gameplay UI architecture, visual-system migration
- Why it mattered: parallel lower-tray, shelf, alternate-header, embedded board-rack, modal, and shell resize-snapshot implementations allowed stale visual language to reappear during otherwise canonical play.
- Resolution: production and UX Lab route searches established Physical Props as the sole supported shell. The final cohesion slice removed the obsolete lobby comparisons, game tray/shelf route, alternate headers, embedded rack, duplicate modal/player strip, and shell-level freeze overlay; the live board retains only its board-owned continuity mechanism.
- Resolved: 2026-08-10.
- Links: [Final UI cohesion and legacy removal](completed/final-ui-cohesion-and-legacy-removal.md), [GameShellView.swift](/Users/kunalsharda/Documents/Code/UnluckySevens/MessagesExtension/Sources/Features/Game/GameShellView.swift)

### TD-015 — Resolved: local game ledger retention and schema lifecycle

- Area: transcript recovery, local persistence
- Resolution: ledger schema v2 stores canonical state data independently of compact transport, migrates valid legacy records, removes corrupt records and repairs the index, keeps active games until local archive, and retains the eight most recent finished games.
- Evidence: migration, corruption, deterministic sibling, pruning, active-retention, and archive tests in `TranscriptGameLedgerTests`.
- Resolved: 2026-07-26.
- Links: [TranscriptGameLedger.swift](/Users/kunalsharda/Documents/Code/UnluckySevens/MessagesExtension/Sources/Presentation/TranscriptGameLedger.swift), [Messages host lessons](/Users/kunalsharda/Documents/Code/UnluckySevens/docs/quality/messages-host.md)

### TD-016 — Resolved: superseded board-art assets removed

- Area: board assets, design source of truth, repository hygiene
- Resolution: source and generated-catalog searches found no runtime consumer for `BoardTiles` or the uncolored `merchant_ship`; the renderer uses `BoardStamps`/`BoardMiniStamps` and `merchant_ship_colored`. The six tile imagesets and uncolored ship imageset were removed from the extension catalog after the installed-bundle/reference audit.
- Resolved: 2026-08-21.
- Links: [GameBoardTileArt.swift](/Users/kunalsharda/Documents/Code/UnluckySevens/MessagesExtension/Sources/Board/GameBoardTileArt.swift), [cleanup receipt](/Users/kunalsharda/Documents/Code/UnluckySevens/docs/design/cleanup-receipt.md), [maintainability forgiveness program](completed/maintainability-forgiveness-program.md)
