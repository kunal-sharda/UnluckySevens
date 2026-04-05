# Phase 12 — Core Gameplay Flows

## Summary

Build the first complete player-facing gameplay flows on top of the phase 10 shell and phase 11 board.

This phase exists now because the repo already has the shell, the board surface, the mode system, and the engine-owned legality/query layer. The main missing piece is productized interaction: setup, turn actions, robber flow, trade flow, and dev-card flow still rely on debug-first paths or are not wired at all.

Success means:

- lobby invite, join, and host-start flow are usable without debug-style transcript bookkeeping
- a new game can progress through setup from the real UI
- a normal turn can be completed from the real UI
- robber and discard flows are playable from the real UI
- player trade, maritime trade, and dev-card actions are available from the real UI
- debug controls become fallback tooling rather than the primary way to advance the game

Owner docs for concepts used here:

- [README](/Users/kunalsharda/Documents/Code/UnluckySevens/README.md) for tracked repo entrypoint and commands
- [ARCHITECTURE](/Users/kunalsharda/Documents/Code/UnluckySevens/ARCHITECTURE.md) for runtime boundaries and ownership
- [decisions](/Users/kunalsharda/Documents/Code/UnluckySevens/docs/decisions.md) for locked product and protocol rules
- [MVP Contract](/Users/kunalsharda/Documents/Code/UnluckySevens/docs/product-specs/mvp-contract.md) for the current product promise
- [UI Flows](/Users/kunalsharda/Documents/Code/UnluckySevens/docs/product-specs/ui-flows.md) for setup, turn, trade, and audit expectations
- [QA](/Users/kunalsharda/Documents/Code/UnluckySevens/docs/quality/qa.md) for the current validation gate and device lane
- [Phase 10 Plan](/Users/kunalsharda/Documents/Code/UnluckySevens/docs/exec-plans/completed/phase-10-ui-shell.md) for the shell, mode, and visual-contract decisions this phase must respect
- [Phase 11 Plan](/Users/kunalsharda/Documents/Code/UnluckySevens/docs/exec-plans/completed/phase-11-spritekit-board.md) for the board, hit-testing, and snapshot substrate this phase must build on
- [Tech Debt Tracker](/Users/kunalsharda/Documents/Code/UnluckySevens/docs/exec-plans/tech-debt-tracker.md) for any debt that should not be buried inside stage notes

## Current State

What exists today:

- phase 10 established a board-first shell, compact opponent summaries, a hand tray, an action dock, and easy-but-secondary debug surfaces
- phase 11 replaced placeholder board art with a real SpriteKit board, pan/zoom, typed board hit targets, mode-driven highlights, and snapshot rendering
- stages 12.1 through 12.6 are now landed: lobby join/start is productized, setup placement is playable from the board, the common turn loop can roll, build, buy, and end turn from the product UI, robber/discard flow is wired through the product shell, trade UX is live in the compact modal/shell surfaces, and dev-card actions are available through the compact product panel
- `ULS_CoreGame` already owns legality, viewer-safe projections, and default action selection through [CoreGameViewQueriesV1.swift](/Users/kunalsharda/Documents/Code/UnluckySevens/Packages/ULS_CoreGame/Sources/ULS_CoreGame/CoreGameViewQueriesV1.swift)
- the main integration point is still [LobbyDriverViewModel.swift](/Users/kunalsharda/Documents/Code/UnluckySevens/MessagesExtension/Sources/Features/Lobby/LobbyDriverViewModel.swift), which owns transcript context, debug actions, and shell inputs

What is still missing:

- the main gameplay loop is still not ready for a full two-device signoff without leaning on debug controls

Important constraints already locked in the repo:

- `MessagesExtension` must not invent legality or hidden-information rules
- board taps and modal selections must map into canonical intents, not mutate state directly
- the current shell hierarchy remains board-first with compact, progressive disclosure
- motion should remain restrained and the Messages UI should stay shallow rather than turning into a deep form-based app
- real-device validation matters more than Simulator-only validation for this phase because the user-visible value is Messages-hosted turn-taking

## Target End State

User-visible result:

- invite, join, and start feel like a real game lobby rather than a transcript-debug workflow
- setup feels guided and blocking rather than debug-like
- the common turn loop is compact and legible inside the current shell
- robber flow is obvious and cannot be bypassed accidentally
- trade feels compact and legible through the product modal and shell rather than raw debug buttons
- dev-card actions are available through focused product UI rather than raw debug buttons
- the real UI can carry a live two-device game segment without depending on the debug HUD

Code and docs result:

- gameplay-specific UI orchestration is split into focused feature areas under `MessagesExtension/Sources/Features/`
- lobby participation and host-start handling no longer depend on manual local recording as the primary UX
- board target selection, modal choices, and action-dock taps converge into a small number of intent-drafting paths
- any additive presentation types stay presentation-only and keep legality in `ULS_CoreGame`
- [QA](/Users/kunalsharda/Documents/Code/UnluckySevens/docs/quality/qa.md) is updated with any new permanent simulator or real-device checks discovered during implementation

Acceptance boundary:

- phase 12 ends when lobby join/start, setup, the common turn loop, robber flow, trade flow, and dev-card flow are playable from the product UI
- phase 12 does not need final recap/history/dispute UX polish; that remains phase 13
- phase 12 does not lock final board art or final bubble-card composition as long as the flow substrate is stable

## Implementation Plan

### Stage 12.1 — Lobby Join and Host Start UX

Goal:

- make invite, join, and start work as a real lobby flow rather than a debug transcript routine

Implement:

- immediate send for lobby join actions rather than requiring an extra manual send step
- a lobby participant surface that shows the host, known joiners, and whether the local actor may start
- host-owned start flow that builds the final roster from observed join intents without requiring explicit "Record Join" as the primary product path
- a clear host/non-host distinction in the lobby without introducing a new locked protocol concept unless the implicit inviter-host model proves insufficient

Key files and likely additions:

- [LobbyDriverView.swift](/Users/kunalsharda/Documents/Code/UnluckySevens/MessagesExtension/Sources/Features/Lobby/LobbyDriverView.swift)
- [LobbyDriverViewModel.swift](/Users/kunalsharda/Documents/Code/UnluckySevens/MessagesExtension/Sources/Features/Lobby/LobbyDriverViewModel.swift)
- [MessagesViewController.swift](/Users/kunalsharda/Documents/Code/UnluckySevens/MessagesExtension/Sources/App/MessagesViewController.swift)
- new lobby-focused presentation or feature files under `MessagesExtension/Sources/Features/Lobby/` if needed

Expected observations:

- join no longer feels like "tap action, then manually press Send"
- the host can see who has joined from the product UI
- the host can start from the invite state without local debug bookkeeping being the normal path
- canonical protocol shape stays the same: one invite `STATE`, join `INTENT`s, one start `STATE`

### Stage 12.2 — Setup Placement UX

Goal:

- make initial settlement and road placement playable from the board

Implement:

- a setup-specific guidance surface that clearly tells the player whether they are placing a settlement or a road
- board-tap handling that converts legal `node(NodeID)` and `edge(EdgeID)` targets into setup intents
- setup-specific selection state that clears cleanly after a successful apply
- minimal confirmation only when the interaction would otherwise be ambiguous

Key files and likely additions:

- [GameShellView.swift](/Users/kunalsharda/Documents/Code/UnluckySevens/MessagesExtension/Sources/Features/Game/GameShellView.swift)
- [LobbyDriverViewModel.swift](/Users/kunalsharda/Documents/Code/UnluckySevens/MessagesExtension/Sources/Features/Lobby/LobbyDriverViewModel.swift)
- [GameModalHostView.swift](/Users/kunalsharda/Documents/Code/UnluckySevens/MessagesExtension/Sources/Components/GameModalHostView.swift)
- [BoardContainerView.swift](/Users/kunalsharda/Documents/Code/UnluckySevens/MessagesExtension/Sources/Board/BoardContainerView.swift)
- new setup-focused presentation or feature files under `MessagesExtension/Sources/Features/Setup/` if the flow becomes too large for `GameShellView`

Expected observations:

- the player can complete both setup placements without opening debug tools
- the board only invites the next legal setup action instead of rendering passive clutter
- starting-resource grants appear through the resulting canonical state rather than local UI bookkeeping

### Stage 12.3 — Core Turn Loop and Build/Buy Actions

Goal:

- make a standard non-robber turn playable through the shell

Implement:

- a clear `needsRoll` action path
- post-roll action availability for build, buy dev card, trade entry, and end turn
- build flows for road, settlement, and city using board-tap selection
- a buy-dev-card path that uses current engine legality and resulting state updates

Key files and likely additions:

- [ActionDockView.swift](/Users/kunalsharda/Documents/Code/UnluckySevens/MessagesExtension/Sources/Components/ActionDockView.swift)
- [GameModalHostView.swift](/Users/kunalsharda/Documents/Code/UnluckySevens/MessagesExtension/Sources/Components/GameModalHostView.swift)
- [GameModeResolver.swift](/Users/kunalsharda/Documents/Code/UnluckySevens/MessagesExtension/Sources/Presentation/GameModeResolver.swift)
- [GameBoardOverlayModelBuilder.swift](/Users/kunalsharda/Documents/Code/UnluckySevens/MessagesExtension/Sources/Presentation/GameBoardOverlayModelBuilder.swift)
- feature-specific helpers under `MessagesExtension/Sources/Features/Turn/` if the turn flow outgrows the shell

Expected observations:

- one non-robber turn can be completed end to end without debug controls
- the common turn actions stay shallow and fit the current board-first shell
- build mode feels mode-driven rather than ad hoc

### Stage 12.4 — Robber and Discard UX

Goal:

- make seven and robber flow forced, obvious, and safe

Implement:

- discard UI for players over the limit
- blocking status and modal behavior while required discards are outstanding
- robber move mode on the board using tile targets
- victim selection after robber placement using compact, count-safe UI
- clear waiting/status copy across the forced flow

Key files and likely additions:

- [GameModalHostView.swift](/Users/kunalsharda/Documents/Code/UnluckySevens/MessagesExtension/Sources/Components/GameModalHostView.swift)
- [GameShellStatusLineResolver.swift](/Users/kunalsharda/Documents/Code/UnluckySevens/MessagesExtension/Sources/Presentation/GameShellStatusLineResolver.swift)
- [GameBoardOverlayModelBuilder.swift](/Users/kunalsharda/Documents/Code/UnluckySevens/MessagesExtension/Sources/Presentation/GameBoardOverlayModelBuilder.swift)
- [LobbyDriverViewModel.swift](/Users/kunalsharda/Documents/Code/UnluckySevens/MessagesExtension/Sources/Features/Lobby/LobbyDriverViewModel.swift)
- new robber-specific or discard-specific files under `MessagesExtension/Sources/Features/Turn/` or `MessagesExtension/Sources/Features/Robber/` if that keeps orchestration cleaner

Expected observations:

- a rolled seven blocks unrelated actions until the forced flow is complete
- robber movement and victim selection are legible without debug text
- state transitions remain engine-driven and deterministic

### Stage 12.5 — Trade UX

Goal:

- make player trade and maritime trade usable without turning the shell into a form-heavy app

Implement:

- a compact trade modal that suggests player-trade and maritime-trade actions for the current player
- accept-intent entry points for non-current players
- selected accept-intent application and execute flow for the current player
- trade status that stays visible in the shell while the offer is pending
- expiry behavior that feels explicit rather than silently disappearing

Key files and likely additions:

- [GameModalHostView.swift](/Users/kunalsharda/Documents/Code/UnluckySevens/MessagesExtension/Sources/Components/GameModalHostView.swift)
- [HandTrayView.swift](/Users/kunalsharda/Documents/Code/UnluckySevens/MessagesExtension/Sources/Components/HandTrayView.swift)
- [GameScreenModelBuilder.swift](/Users/kunalsharda/Documents/Code/UnluckySevens/MessagesExtension/Sources/Presentation/GameScreenModelBuilder.swift)
- new files under `MessagesExtension/Sources/Features/Trade/`

Expected observations:

- a player trade can be proposed, responded to, executed, or expired from the real UI
- maritime trade feels distinct from player trade rather than like the same form with different wording
- shell status remains readable while a trade is pending
- current-player trade suggestions stay compact inside the modal and shell rather than expanding into a dense form

### Stage 12.6 — Dev Card UX

Goal:

- make dev cards feel integrated into the turn flow rather than buried in debug actions

Implement:

- buy-dev-card follow-through into visible local dev-card state
- play-dev-card entry points only when legal
- focused flows for:
  - knight
  - road building
  - year of plenty
  - monopoly
- safe handling of hidden dev-card information and current-turn timing rules

Key files and likely additions:

- [GameModalHostView.swift](/Users/kunalsharda/Documents/Code/UnluckySevens/MessagesExtension/Sources/Components/GameModalHostView.swift)
- [GameBoardOverlayModelBuilder.swift](/Users/kunalsharda/Documents/Code/UnluckySevens/MessagesExtension/Sources/Presentation/GameBoardOverlayModelBuilder.swift)
- [GameScreenModelBuilder.swift](/Users/kunalsharda/Documents/Code/UnluckySevens/MessagesExtension/Sources/Presentation/GameScreenModelBuilder.swift)
- new files under `MessagesExtension/Sources/Features/DevCards/`

Expected observations:

- all playable dev-card actions can be completed through the real UI
- board-based dev-card flows reuse existing mode and selection machinery instead of duplicating interaction logic
- local hidden dev-card detail remains local-only

### Stage 12.7 — Flow Hardening and Real-Device Pass

Goal:

- make the real gameplay UI the primary path and validate it on hardware

Implement:

- remove or demote remaining debug-first dependencies for the covered flows
- tighten stale-context, empty-state, and interrupted-flow behavior
- add a transport sanity check before lobby join/start so selected invite bubbles must decode via URL on both sender and receiver before gameplay validation continues
- update [qa.md](/Users/kunalsharda/Documents/Code/UnluckySevens/docs/quality/qa.md) with any permanent new checks discovered during the phase
- run the real-device lane against the actual covered flows

Expected observations:

- the app can carry a meaningful two-device gameplay segment through the product UI
- debug UI is still available, but no longer required for the main flow
- the phase ends with concrete hardware validation, not Simulator-only confidence

## Validation

### Automated

Run the full repo gate for each substantial stage landing:

```bash
bash ./scripts/gen.sh
swift test --package-path Packages/ULS_CoreGame --skip ULS_CoreGameEvals
swift test --package-path Packages/ULS_CoreGame --filter ULS_CoreGameEvals
swift test --package-path Packages/ULS_Transport
xcodebuild -workspace UnluckySevens.xcworkspace -scheme MessagesExtension -destination 'generic/platform=iOS Simulator' build
xcodebuild -workspace UnluckySevens.xcworkspace -scheme UnluckySevens-Workspace -destination 'platform=iOS Simulator,name=iPhone 15' test
```

Add phase-12-specific tests where practical:

- presentation tests for setup, turn, trade, and dev-card screen-state derivation
- targeted unit tests around intent-drafting helpers if new pure helpers are introduced
- regression tests for board-target-to-intent mapping where that logic can be made pure

### Manual

Simulator checks:

1. Send an invite, join from another participant path, and start the game from the product UI.
2. Complete setup through the product UI.
3. Play one normal non-robber turn through roll, build or buy, and end turn.
4. Trigger or reach a seven flow and complete discard, robber move, and victim selection.
5. Propose one player trade and one maritime trade.
6. Buy and play at least one dev card through the real UI.
7. Confirm stale-context behavior remains visible and recoverable after gameplay actions.

Real-device checks:

1. Run `Real Device Shell Smoke` from [QA](/Users/kunalsharda/Documents/Code/UnluckySevens/docs/quality/qa.md) after the first substantial gameplay UI stage lands.
2. Before lobby join/start validation, send an invite `STATE`, select it on both devices, and confirm the debug HUD reports a selected bubble with a URL `payload` query that decodes active context from URL.
3. Run `Real Device Messages Lifecycle` after the lobby join/start stage and after any later stage that changes transcript, bubble, or context behavior.
4. Run `Real Device Turn-Taking Smoke` after each gameplay-flow stage.
5. Before calling phase 12 complete, run at least one real two-device gameplay segment covering join, host start, setup completion, one standard turn, and one cross-device response.

### Deferred Validation

Deferred by design in phase 12:

- final recap/history/dispute UX polish
- automated transcript-level Messages UI testing
- final bubble-card composition beyond using the existing snapshot substrate

## Progress

- [x] Stage 12.1 — Lobby Join and Host Start UX
- [x] Stage 12.2 — Setup Placement UX
- [x] Stage 12.3 — Core Turn Loop and Build/Buy Actions
- [x] Stage 12.4 — Robber and Discard UX
- [x] Stage 12.5 — Trade UX
- [x] Stage 12.6 — Dev Card UX
- [ ] Stage 12.7 — Flow Hardening and Real-Device Pass

## Decisions and Discoveries

- Stage 12.1 landed as a product lobby shell rather than another expansion of the debug view. The lobby now auto-sends join actions, derives pending participants from observed join intents plus the local pending-join cache, and keeps host start as the single canonical transition into setup.
- Stage 12.2 uses board taps to draft and immediately publish canonical setup `STATE`s for the current player. That keeps setup aligned with the repo rule that only the current player publishes canonical state while still leaving legality in `ULS_CoreGame`.
- Setup highlights are back only because setup placement is now actionable. They are no longer passive debug clutter; they reflect the legal node or edge targets for the current setup step.
- Stage 12.3 keeps the common turn loop shallow by treating roll, buy-dev-card, and end-turn as direct canonical state publications while build actions stay board-driven. That avoids introducing a second turn view model while still moving the real UI ahead of the debug path.
- Dev-card dock presentation now distinguishes a pure buy action from later play-dev-card work. When purchase is legal but play is not, the dock presents `Buy Dev` instead of suggesting the full dev-card surface already exists.
- Stage 12.4 keeps the robber/discard flow within the locked authority model instead of relaxing it: the current player still publishes canonical turn state, while non-current players use a product discard panel that auto-sends a discard `INTENT` the current player can apply from the selected transcript bubble.
- Stage 12.4 also tightens shell guidance so forced steps show `Discard required`, `Move the robber`, or `Steal a card` in the header rather than falling back to generic turn ownership copy.
- Stage 12.5 moves trade into a compact modal and shell-visible status path: current players see suggested player-trade and maritime-trade actions, non-current players can send accept intents, and the current player can apply a selected accept bubble and execute with accepted players without losing the pending-trade context in the shell.
- Stage 12.1 through 12.5 validation ran through the MessagesExtension-focused lane: `bash ./scripts/gen.sh`, `xcodebuild -workspace UnluckySevens.xcworkspace -scheme MessagesExtension -destination 'generic/platform=iOS Simulator' build`, and `xcodebuild -workspace UnluckySevens.xcworkspace -scheme UnluckySevens-Workspace -destination 'platform=iOS Simulator,name=iPhone 15' test -only-testing:MessagesExtensionTests`, with `49` MessagesExtension tests green after the robber/discard slice landed and trade UX stayed within the product shell.
- Stage 12.6 keeps dev-card UX compact instead of introducing a new full-screen flow: the shell opens a focused dev-card panel, buy/play actions stay default-driven through pure `GameDevCardPanelModelBuilder` and `DevCardInteractionResolver` seams, and the current player publishes the resulting canonical state transitions directly from the product UI.
- Knight default selection cannot reuse the robber-move legality query because knight play happens from normal turn state rather than `needsRobberMove`; the resolver now prefers a non-current robber tile with a default steal target, then falls back to the first legal non-current robber tile.
- Stage 12.6 validation stayed inside the MessagesExtension-focused lane: `bash ./scripts/gen.sh`, `xcodebuild -workspace UnluckySevens.xcworkspace -scheme MessagesExtension -destination 'generic/platform=iOS Simulator' build`, the focused dev-card tests, and `xcodebuild -workspace UnluckySevens.xcworkspace -scheme UnluckySevens-Workspace -destination 'platform=iOS Simulator,name=iPhone 15' test -only-testing:MessagesExtensionTests`, with `68` MessagesExtension tests green after the dev-card slice landed.
- Stage 12.7 automated validation is green across the full repo gate: `bash ./scripts/gen.sh`, `swift test --package-path Packages/ULS_CoreGame --skip ULS_CoreGameEvals`, `swift test --package-path Packages/ULS_CoreGame --filter ULS_CoreGameEvals`, `swift test --package-path Packages/ULS_Transport`, `xcodebuild -workspace UnluckySevens.xcworkspace -scheme MessagesExtension -destination 'generic/platform=iOS Simulator' build`, and `xcodebuild -workspace UnluckySevens.xcworkspace -scheme UnluckySevens-Workspace -destination 'platform=iOS Simulator,name=iPhone 15' test`, with the eval lane passing `10` tests in about `140s`.
- 2026-04-05: real-device transport triage exposed a hardware-only failure signature during invite validation. Selecting a just-sent invite bubble on iPad and iPhone could leave the shell in `No Lobby Selected`, and the debug HUD reported `Selected message has no transport payload` even though the transcript bubble existed.
- 2026-04-05: Stage 12.7 keeps URL transport canonical instead of changing protocol shape. The fix direction is to instrument selected-message transport facts in the debug HUD, repair the documented simulator-only `summaryText` fallback, and route transcript publication through a dedicated publish helper so real-device send behavior can be adjusted without spreading transport logic across the view model.
- 2026-04-05: transport hardening now routes message building through a pure helper, records outbound publish diagnostics, records per-trigger selection diagnostics for `didSelect`, `didReceive`, reload, and selection polling, and shows transport metadata inline in the debug HUD so device failures produce a concrete repro snapshot instead of only the empty-state shell.
- 2026-04-05: follow-up hardware feedback showed insertion-style publish broke the expected auto-send invite flow and still did not make cross-device invite decode reliable. The current fix keeps the publish helper but uses `conversation.send(...)` again, then continues selection polling after `didSelect` and `didReceive` so Messages-hosted bubbles that arrive with delayed URL/session metadata still get re-read before the shell gives up.
- 2026-04-05: post-fix automated validation reran the full repo gate cleanly: `bash ./scripts/gen.sh`, `swift test --package-path Packages/ULS_CoreGame --skip ULS_CoreGameEvals`, `swift test --package-path Packages/ULS_CoreGame --filter ULS_CoreGameEvals`, `swift test --package-path Packages/ULS_Transport`, `xcodebuild -workspace UnluckySevens.xcworkspace -scheme MessagesExtension -destination 'generic/platform=iOS Simulator' build`, and `xcodebuild -workspace UnluckySevens.xcworkspace -scheme UnluckySevens-Workspace -destination 'platform=iOS Simulator,name=iPhone 15' test`, with `110` non-eval core tests, `10` eval tests, `44` transport tests, and `71` MessagesExtension tests all green after the transport helper and diagnostics landed.
- The remaining unclosed part of Stage 12.7 is hardware signoff. Simulator and automated lanes are now strong enough to support the phase, but they do not replace the required iPhone+iPad Messages pass described in [QA](/Users/kunalsharda/Documents/Code/UnluckySevens/docs/quality/qa.md).
- `MessagesExtensionTests` still emits an Xcode dependency-scan warning because Tuist does not support a direct unit-test dependency on an iMessage extension target in this project shape. The current workaround remains compiling selected extension source files into the test target; capture any future cleanup under the tech-debt tracker rather than forcing a larger restructure into this phase.
- Real-device validation is expected to drive at least some late-stage UX adjustments; do not treat Simulator-only behavior as sufficient signoff for Messages-hosted gameplay.
- If setup, trade, or dev-card orchestration starts overwhelming `GameShellView` or `LobbyDriverViewModel`, split it into feature-local helpers rather than growing more shared conditionals.
- Lobby join/start should preserve the current authority model unless there is an explicit product request to change it: one invite `STATE`, join `INTENT`s, one host-published start `STATE`.

## Outcome

Planned result:

- the lobby and core gameplay loop are playable from the product UI
- trade is compact and readable in the product UI, with accept and execute flows staying visible in the shell
- board taps, shell modes, and modal choices map cleanly into canonical intents
- the repo is ready for a narrower phase 13 focused on recap, history, dispute mode, and final trust surfaces rather than basic playability gaps

What remains after this phase by design:

- flow hardening and real-device signoff
- recap/history/dispute UX
- final bubble composition polish
- any visual restyling that does not change the gameplay-flow substrate
