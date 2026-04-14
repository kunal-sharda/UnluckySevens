# Phase 12 — Core Gameplay Flows

## Summary

Build the first complete player-facing gameplay flows on top of the phase 10 shell and phase 11 board.

This phase exists now because the repo already has the shell, the board surface, the mode system, and the engine-owned legality/query layer. The main missing piece is productized interaction: setup, turn actions, robber flow, trade flow, and dev-card flow still rely on debug-first paths or are not wired at all.

Success means:

- lobby invite, join, and host-start flow are usable without debug-style transcript bookkeeping
- a new game can progress through snake-order setup from the real UI
- a normal turn can be completed from the real UI
- robber and discard flows are playable from the real UI
- player trade, maritime trade, and dev-card actions are available from the real UI
- the game ends with a clear winner state and minimal final summary instead of dropping back into debug-era surfaces
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
- stage 12.8 now includes `Buy Dev` under `Build`, staged Knight/Monopoly/Year Of Plenty/Road Building choice flows, winning-only Victory Point reveal visibility, a board-first shell that collapses hand, bank, player summaries, build actions, and dev-card inventory into a shared lower shelf, plus interaction hardening for setup/build confirmation and Messages-host resize. The shell now fits the current visible host bounds again, the board keeps one committed world reference size, setup/build placements use selection-first confirm semantics, and interactive host drag freezes the board until one settled post-resize update can be applied
- phase 12 currently carries a temporary production transport fallback: canonical payloads still prefer `message.url`, but the extension also mirrors a one-line payload fallback into `summaryText` so real-device gameplay stays end-to-end while phase 13 redesigns transcript rehydration
- `ULS_CoreGame` already owns legality, viewer-safe projections, and default action selection through [CoreGameViewQueriesV1.swift](/Users/kunalsharda/Documents/Code/UnluckySevens/Packages/ULS_CoreGame/Sources/ULS_CoreGame/CoreGameViewQueriesV1.swift)
- the main integration point is still [LobbyDriverViewModel.swift](/Users/kunalsharda/Documents/Code/UnluckySevens/MessagesExtension/Sources/Features/Lobby/LobbyDriverViewModel.swift), which owns transcript context, debug actions, and shell inputs

What is still missing:

- phase 12.7 is closed, but phase 12 still needs the 12.8 product-cohesion device pass before the gameplay phase can be called complete
- the remaining gate is full-match real-device signoff and any small product gaps that still prevent a standard base-game Catan match from being played start to finish in Messages
- the required phase-12 match loop is now explicit:
  - invite / join / host start
  - two-settlement snake-order setup with second-settlement starting resources
  - normal turn play with roll, build, trade, buy/play dev cards, and end turn
  - robber / discard / steal resolution
  - immediate win at 10 VP with clear winner state
- host-stability and transcript-recovery work stay out of the phase-12 success boundary except for the temporary one-line `summaryText` transport bridge needed to keep current gameplay end to end
- phase 13 prep is now explicit: before host-stability work begins, the next active ExecPlan must challenge carrier, session, selection, and recovery assumptions up front through an `Assumptions and Evidence Gate` instead of inheriting them from debug-first behavior

Important constraints already locked in the repo:

- `MessagesExtension` must not invent legality or hidden-information rules
- board taps and modal selections must map into canonical intents, not mutate state directly
- this slice does not change transport or protocol shape; it tightens presentation, choice surfaces, and timing affordances on top of the existing canonical state/intent model
- the temporary one-line `summaryText` payload mirror is acceptable only as a phase-12 product-reliability bridge; phase 13 owns replacing it with compact-token rehydration
- the current shell hierarchy remains board-first with compact, progressive disclosure
- motion should remain restrained and the Messages UI should stay shallow rather than turning into a deep form-based app
- real-device validation matters more than Simulator-only validation for this phase because the user-visible value is Messages-hosted turn-taking
- stale PRD wording that mentions GameKit hand-off does not change current scope; [decisions](/Users/kunalsharda/Documents/Code/UnluckySevens/docs/decisions.md) remains the lockfile and still says no GameKit and no backend
- board-fairness toggles, friendly-robber options, timers, and other house-rule controls are outside the standard-match phase-12 boundary

## Target End State

User-visible result:

- invite, join, and start feel like a real game lobby rather than a transcript-debug workflow
- setup feels guided and blocking rather than debug-like
- the common turn loop is compact and legible inside the current shell
- robber flow is obvious and cannot be bypassed accidentally
- trade feels coherent and complete enough for a full asynchronous standard match rather than stopping at default-path shortcuts
- dev-card actions feel like real player choices inside the product UI rather than only a thin wrapper over engine defaults
- the real UI can carry a live two-device game segment without depending on the debug HUD
- the game ends with an immediately understandable winner state instead of requiring later recap/history work to explain that the match is over

Code and docs result:

- gameplay-specific UI orchestration is split into focused feature areas under `MessagesExtension/Sources/Features/`
- lobby participation and host-start handling no longer depend on manual local recording as the primary UX
- board target selection, modal choices, and action-dock taps converge into a small number of intent-drafting paths
- lower-shelf utility affordances and dev-card choice surfaces stay obvious enough that the player can understand what the shell can legally do at a glance
- any additive presentation types stay presentation-only and keep legality in `ULS_CoreGame`
- [QA](/Users/kunalsharda/Documents/Code/UnluckySevens/docs/quality/qa.md) is updated with any new permanent simulator or real-device checks discovered during implementation

Acceptance boundary:

- phase 12 ends when a full standard base-game Catan match can be started, played, and ended from the real Messages UI:
  - lobby join/start
  - setup
  - common turn loop
  - robber/discard flow
  - player and maritime trade
  - dev-card flow
  - immediate winner state
- phase 12 does not need transcript recovery, collapse/latest-bubble behavior, or durable rehydration; those move to phase 13
- phase 12 does not need final recap/history/dispute UX polish; that remains phase 14 after host-stability work
- phase 12 does not include house-rule controls, board-fairness toggles, friendly-robber configuration, or timers
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

- make the real gameplay UI authoritative and responsive enough to sign off on real hardware

Implement:

- always request expanded presentation when the extension opens from the drawer or a transcript bubble
- remove remaining debug-first dependencies from product authority, session behavior, and transcript transport on the clean branch
- lock product actions to `local Messages participant ∩ joined game roster`; unresolved identity stays read-only and secrecy-safe
- block host start when the lobby has not yet resolved at least two players on the host device, so phase-12 multiplayer validation cannot silently start from a one-player roster
- reduce board redraw and lifecycle churn so selection polling, overlay changes, and gameplay shell updates no longer make the board feel unplayable on device
- prevent board pan/pinch from competing with the parent shell scroll view
- improve setup-road affordance and hit-testing so endpoint-adjacent taps near the just-placed settlement still produce an understandable legal road selection
- update [qa.md](/Users/kunalsharda/Documents/Code/UnluckySevens/docs/quality/qa.md) with any permanent new checks discovered during the phase
- run the real-device lane against the actual covered flows

Expected observations:

- the joined local participant can act and non-joined / out-of-turn participants stay read-only
- the board can be panned and zoomed without severe hitching on device
- the phase ends with concrete hardware validation, not Simulator-only confidence

### Stage 12.8 — Full-Game Product Cohesion

Goal:

- make the already-landed gameplay systems feel like a coherent end-user game rather than a collection of debug-era surfaces and raw participant IDs

Implement:

- finish board interaction correctness and feedback so pan, zoom, tap, and placement stay trustworthy across the whole match
- simplify the shell header to turn ownership plus dice state instead of transport/debug context copy
- replace raw participant identifiers in player-facing UI with deterministic per-game pseudonyms
- reorganize the bottom tray around the common action order: contextual left slot, `End Turn`, `Build`, `Play Dev`, with `Build` opening a compact shelf for legal build/buy actions and visible bank-aware purchase availability
- use the left dock slot contextually so it shows `Roll` before the dice and `Trade` after the roll during normal turn play instead of keeping a spent roll button visible
- suppress idle board-target selection so nodes, edges, and tiles only highlight when the active mode actually uses them
- clarify the current compact trade protocol with clearer proposer/respondent state, passive-decline language, and execution status without inventing new transport semantics
- align dev-card timing and shell affordances with the intended turn flow instead of leaving them as post-roll-only product shortcuts by accident
- replace hidden-default dev-card shortcuts with choice-driven play for Knight, Monopoly, Year of Plenty, and Road Building
- keep Victory Point reveals hidden unless revealing them would immediately win the game
- lock the shell geometry to a fixed `12%` header, `70%` board, and `18%` dock region so the board never shrinks when shelves open
- split the dock region into a `6%` handle band and `12%` dock row
- replace the always-visible utility strip with a collapsed pull-tab that opens the shared lower shelf for `Hand`, `Bank`, and `Players`
- render the shared lower shelf as an `18%` overlay that stays `6%` visible inside the lower rail and intentionally overlaps only the bottom `12%` of the board
- treat unintended overlap as a defect: utility controls, dock controls, shelf header, board header, and board content must not collide or wrap because of insufficient height
- keep `Trade` in the `Hand` shelf instead of the persistent dock
- make `Hand`, `Bank`, and `Players` content-only utility shelves with no repeated inner titles or subtitles
- keep `Hand`, `Bank`, and `Players` non-scroll in the normal case
- reuse one shared five-chip visual format for `Hand` and `Bank`, adding only minimal bank selection decoration during Monopoly and Year of Plenty
- place a full-width `Trade` action row directly under the hand chips whenever trade is currently available
- keep `Players` shelf-only and public-info-only
- keep the dock row fixed while the overlay shelf animates only opacity and vertical offset, not board or shell geometry
- reserve fixed icon and label slots in the dock row so `End Turn` stays legible on iPad and narrow layouts
- replace the large board HUD with a compact bottom-center in-board hint pill during guided modes
- shrink guided hints to one-line chips that move upward when the overlay shelf is open
- size the shell from the current visible host bounds while freezing the board during interactive host drag so partial collapse does not reintroduce severe lag
- keep board world geometry in a stable reference space so host drag changes viewport/camera behavior without recomputing tile, node, road, or port positions on every intermediate size
- make setup and build placement selection-first so legal node/edge taps do not publish immediately; confirm through the compact surface or by tapping the same selected target twice
- auto-collapse utility shelves when the visible host is too short to render a usable utility body instead of letting the shelf overflow or cut off
- cap lower-rail and overlay-shelf width so hand, bank, and player content keep one intentional reading width across iPhone and iPad instead of stretching with the full host width
- add any minimal end-of-game clarity needed so a full played match does not feel unfinished at the moment of victory

Key files and likely additions:

- [GameShellView.swift](/Users/kunalsharda/Documents/Code/UnluckySevens/MessagesExtension/Sources/Features/Game/GameShellView.swift)
- [BoardSceneView.swift](/Users/kunalsharda/Documents/Code/UnluckySevens/MessagesExtension/Sources/Board/BoardSceneView.swift)
- [GameBoardCameraController.swift](/Users/kunalsharda/Documents/Code/UnluckySevens/MessagesExtension/Sources/Board/GameBoardCameraController.swift)
- [GameModalHostView.swift](/Users/kunalsharda/Documents/Code/UnluckySevens/MessagesExtension/Sources/Components/GameModalHostView.swift)
- [GameTradePanelModelBuilder.swift](/Users/kunalsharda/Documents/Code/UnluckySevens/MessagesExtension/Sources/Presentation/GameTradePanelModelBuilder.swift)
- [TradeInteractionResolver.swift](/Users/kunalsharda/Documents/Code/UnluckySevens/MessagesExtension/Sources/Presentation/TradeInteractionResolver.swift)
- [GameDevCardPanelModelBuilder.swift](/Users/kunalsharda/Documents/Code/UnluckySevens/MessagesExtension/Sources/Presentation/GameDevCardPanelModelBuilder.swift)
- [DevCardInteractionResolver.swift](/Users/kunalsharda/Documents/Code/UnluckySevens/MessagesExtension/Sources/Presentation/DevCardInteractionResolver.swift)
- focused feature files under `MessagesExtension/Sources/Features/Trade/` and `MessagesExtension/Sources/Features/DevCards/` if the interaction surface needs more structure

Expected observations:

- board movement and placement are reliable enough that the main board no longer feels like a hostile control surface
- the shell header, board, handle band, and dock now read as one coherent board-first surface instead of stacked cards leaking protocol/debug state
- shelf open and close no longer force a board resize or other geometry churn that causes visible hitching on device
- the only allowed overlap is the deliberate shelf-over-board band at the bottom edge; accidental collisions between shell regions are gone
- hand and bank now read as the same utility surface instead of two different component systems, and the bank no longer looks like a dead pseudo-button grid during normal viewing
- utility shelves stay compact and content-only instead of spending vertical space on repeated headings or unnecessary scrolling
- Messages-host drag no longer causes severe hitching, the visible shell still fits the actual current host bounds instead of hanging below the viewport, the board freezes during drag, and the board itself no longer visibly re-lays out from the live host size on every drag step
- utility shelves now either fit within the visible shelf body or close; they should never render partially offscreen because the host became shorter
- iPhone and iPad now use width-class lower-rail caps, so hand/bank/player shelves do not balloon into full-width cards on larger hosts
- trade and dev-card flows are compact, but legible enough that a full match no longer relies on raw participant IDs, invisible timing rules, or hidden default-choice shortcuts
- a full match can end without the last steps feeling like placeholder UI

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

Run the validation lane serially. Do not overlap `swift test` and `xcodebuild` commands for this phase; simulator and Messages-host lock contention has already produced false negatives under parallel validation.

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
7. Confirm the default shell reads as header, board, handle band, and dock rather than stacked hand/bank/player cards.
8. Confirm the collapsed lower rail shows only the pull-tab and dock row, with no unintended overlap between utility affordances and dock buttons.
9. Confirm hand, bank, and players expand only after opening the pull-tab, with only one shelf open at a time.
10. Confirm stale-context behavior remains visible and recoverable after gameplay actions.

Real-device checks:

1. Run `Real Device Shell Smoke` from [QA](/Users/kunalsharda/Documents/Code/UnluckySevens/docs/quality/qa.md) after the first substantial gameplay UI stage lands.
2. Run `Real Device Lobby Smoke` after any lobby join/start change, explicitly confirming the host sees both players before start and the guest join uses the real local Messages identity.
3. Run `Real Device Turn-Taking Smoke` after each gameplay-flow stage, explicitly verifying that non-current players cannot publish current-player actions.
4. Run `Real Device UX Hardening` after any change to board responsiveness or setup-road interaction.
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
- [x] Stage 12.7 — Flow Hardening and Real-Device Pass
- [ ] Stage 12.8 — Full-Game Product Cohesion

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
- Follow-up UX audit after stages 12.5 and 12.6 showed an important boundary mistake: both slices landed real product entry points, but they still stop at narrow default-path interactions rather than fully expressing the player choice space for trade and dev cards. Stage 12.8 exists to close that gap instead of pretending phase 12 is done once the rules are merely reachable from the shell.
- Stage 12.6 validation stayed inside the MessagesExtension-focused lane: `bash ./scripts/gen.sh`, `xcodebuild -workspace UnluckySevens.xcworkspace -scheme MessagesExtension -destination 'generic/platform=iOS Simulator' build`, the focused dev-card tests, and `xcodebuild -workspace UnluckySevens.xcworkspace -scheme UnluckySevens-Workspace -destination 'platform=iOS Simulator,name=iPhone 15' test -only-testing:MessagesExtensionTests`, with `68` MessagesExtension tests green after the dev-card slice landed.
- Stage 12.7 automated validation is green across the full repo gate: `bash ./scripts/gen.sh`, `swift test --package-path Packages/ULS_CoreGame --skip ULS_CoreGameEvals`, `swift test --package-path Packages/ULS_CoreGame --filter ULS_CoreGameEvals`, `swift test --package-path Packages/ULS_Transport`, `xcodebuild -workspace UnluckySevens.xcworkspace -scheme MessagesExtension -destination 'generic/platform=iOS Simulator' build`, and `xcodebuild -workspace UnluckySevens.xcworkspace -scheme UnluckySevens-Workspace -destination 'platform=iOS Simulator,name=iPhone 15' test`, with the eval lane passing `10` tests in about `140s`.
- 2026-04-05: real-device transport triage exposed a hardware-only failure signature during invite validation. Selecting a just-sent invite bubble on iPad and iPhone could leave the shell in `No Lobby Selected`, and the debug HUD reported `Selected message has no transport payload` even though the transcript bubble existed.
- 2026-04-05: Stage 12.7 keeps URL transport canonical instead of changing protocol shape. The fix direction is to instrument selected-message transport facts in the debug HUD, repair the documented debug-build `summaryText` fallback, and route transcript publication through a dedicated publish helper so real-device send behavior can be adjusted without spreading transport logic across the view model.
- 2026-04-05: transport hardening now routes message building through a pure helper, records outbound publish diagnostics, records per-trigger selection diagnostics for `didSelect`, `didReceive`, reload, and selection polling, and shows transport metadata inline in the debug HUD so device failures produce a concrete repro snapshot instead of only the empty-state shell.
- 2026-04-05: follow-up hardware feedback showed insertion-style publish broke the expected auto-send invite flow and still did not make cross-device invite decode reliable. The current fix keeps the publish helper but uses `conversation.send(...)` again, then continues selection polling after `didSelect` and `didReceive` so Messages-hosted bubbles that arrive with delayed URL/session metadata still get re-read before the shell gives up.
- 2026-04-05: screenshots from the iPhone+iPad lane showed a selected invite bubble with `message`, `session`, `layoutCaption`, and short `summaryText` present but `message.url` missing on hardware. The current debug-build hardening therefore broadens the existing `summaryText` mirror/fallback beyond simulator so device builds have a second recoverable transport carrier while the Messages-host behavior is still under investigation.
- 2026-04-05: local reopen behavior on the sending device can still momentarily lose transcript selection even when publish succeeded. Stage 12.7 now keeps a short-lived cached copy of the last published `STATE` for sender-side recovery only so the shell does not immediately blank to `No Lobby Selected` while still treating transcript transport as the only cross-device source of truth.
- 2026-04-05: follow-up invite triage showed a second lobby-layer bug: `canJoin` and lobby-local identity were reading the debug `actingAs` fallback instead of the real `localParticipantIdentifier`, so a receiver could look like the inviter and lose `Join Game` despite decoding the invite payload correctly. Stage 12.7 now surfaces participant-identity diagnostics and uses the real local participant for lobby join/start gating.
- 2026-04-05: follow-up device join testing exposed a third authority bug in the same area: the guest `Join` action was still authoring `JoinIntent.actor` from the debug fallback path, so the host could record the inviter twice and never derive a real two-player roster. Stage 12.7 now authors join intents from `activeConversation.localParticipantIdentifier` and keeps the derived lobby roster keyed to real participant identity instead of debug impersonation state.
- 2026-04-05: follow-up multiplayer audit showed host start still assembled the launch roster from device-local pending joins. Stage 12.7 now blocks `Start Game` unless the host device sees at least two players in the derived lobby roster, while the deeper fix for transcript-authoritative join aggregation is tracked as follow-up debt instead of being hidden behind local cache behavior.
- 2026-04-05: Apple’s `selectedMessage` contract and current forum reports both support treating transcript selection as an unstable host boundary rather than a full-fidelity persistence layer. Stage 12.7 therefore keeps the current payload shape for debug validation, but the longer-term product-safe direction is to move toward compact transcript tokens plus durable rehydration instead of relying on full-state URL roundtrip alone.
- 2026-04-05: post-fix automated validation reran the full repo gate cleanly: `bash ./scripts/gen.sh`, `swift test --package-path Packages/ULS_CoreGame --skip ULS_CoreGameEvals`, `swift test --package-path Packages/ULS_CoreGame --filter ULS_CoreGameEvals`, `swift test --package-path Packages/ULS_Transport`, `xcodebuild -workspace UnluckySevens.xcworkspace -scheme MessagesExtension -destination 'generic/platform=iOS Simulator' build`, and `xcodebuild -workspace UnluckySevens.xcworkspace -scheme UnluckySevens-Workspace -destination 'platform=iOS Simulator,name=iPhone 15' test`, with `110` non-eval core tests, `10` eval tests, `44` transport tests, and `72` MessagesExtension tests all green after the transport helper, debug-build fallback, and sender recovery hardening landed.
- 2026-04-06: follow-up real-device UX testing exposed three remaining 12.7 hardening gaps that belong in the active plan rather than in future-phase debt by default: staying in the same selected bubble does not reliably promote newer received state, board redraw/update latency is high enough to be player-visible on both devices, and setup-road hit-testing still feels unnatural near the just-placed settlement endpoint.
- 2026-04-06: Stage 12.7 now requests expanded presentation on every extension open path, promotes newest known `STATE` for the current game over stale selected bubbles, adds a product-visible reload action in the game shell, splits board base rendering from overlay-only updates, and makes setup-road taps near the freshly placed settlement endpoint resolve the intended legal edge instead of forcing a tiny mid-edge target.
- 2026-04-06: latest-state hardening is now covered by focused pure selection tests instead of view-model-only behavior, so the simulator lane verifies both same-bubble auto-follow and stale-bubble redirect without needing a direct test dependency on the iMessage extension target.
- 2026-04-08: Stage 12.7 is now intentionally narrowed to two exit metrics: product authority and severe lag. The clean branch no longer treats summary-mirrored payloads, runtime debug toggles, cached published-state recovery, or product-visible reload affordances as phase-12 solutions; those host-stability concerns move to the next phase instead of continuing to contaminate the product path.
- 2026-04-08: product authority on the clean branch is now `local Messages participant ∩ joined game roster`. Debug impersonation no longer participates in gameplay publication, legality gating, or hidden-information projection, and unresolved identity is explicitly read-only.
- 2026-04-08: the first lag pass now targets lifecycle churn before deeper board refactors: selection polling self-cancels once a stable selection is observed, product cache keys stop changing on every relative-age tick, diagnostics no longer publish the large transport/debug field set on the gameplay hot path, and active board gestures disable the parent shell scroll view so pan/pinch no longer fight vertical scrolling.
- 2026-04-08: Stage 12.7 is closed by the real-device authority and responsiveness pass. Reload / active-game sync, transcript collapse behavior, and deeper Messages-host durability are explicitly promoted into the next roadmap phase instead of stretching phase 12 further.
- 2026-04-10: Stage 12.8 narrows the “product cohesion” goal to the actual phase-12 blockers: remove raw participant IDs from the player-facing shell, simplify the turn header to ownership plus dice state, stop idle board taps from highlighting arbitrary targets, move dev-card purchase into the build shelf, keep public bank counts quickly accessible through the lower shelf, and allow legal dev-card play before or after the dice roll as long as the card was not bought that turn.
- 2026-04-10: Stage 12.8 deliberately does not invent new trade or naming protocol. The trade panel is still compact and protocol-constrained, but it now states proposer/respondent status, passive decline, and execute/end-turn expiry behavior clearly enough for a full asynchronous match without pretending there is already a custom composer, cancel bubble, or counteroffer flow.
- 2026-04-10: deterministic player aliases now come from a per-game pseudonym resolver seeded by `gameId` plus roster membership. The intended product constraint is consistency across devices and transcript reopens, not exposing real Messages contact names that the framework does not provide.
- 2026-04-10: dev-card timing is now aligned end to end through `TurnStepV1.allowsDevCardPlay`, the reducer, validation, and the Messages shell, so legal non-purchase dev cards can be played pre-roll or post-roll while buy-dev-card remains an after-roll action.
- 2026-04-10: Stage 12.8 replaces hidden-default dev-card shortcuts with explicit staged choice flows for Knight, Monopoly, Year of Plenty, and Road Building. Victory Point cards stay hidden as inventory until a reveal would immediately win, and Road Building still publishes as one canonical two-edge intent rather than inventing new transport shape.
- 2026-04-10: Stage 12.8 automated validation is green across the full repo gate after the cohesion pass landed: `bash ./scripts/gen.sh`, `swift test --package-path Packages/ULS_CoreGame --skip ULS_CoreGameEvals`, `swift test --package-path Packages/ULS_CoreGame --filter ULS_CoreGameEvals`, `swift test --package-path Packages/ULS_Transport`, `xcodebuild -workspace UnluckySevens.xcworkspace -scheme MessagesExtension -destination 'generic/platform=iOS Simulator' build`, and `xcodebuild -workspace UnluckySevens.xcworkspace -scheme UnluckySevens-Workspace -destination 'platform=iOS Simulator,name=iPhone 15' test`, with `115` non-eval core tests, `10` eval tests, `44` transport tests, and `111` MessagesExtension tests all green.
- 2026-04-10: Stage 12.8 shell consolidation removes the always-open hand tray, bank tray, and opponent cards from the default screen. The normal shell is now `Header + Board + Handle Band + Dock`, while build, dev cards, hand, bank, and players all route through one shared lower shelf instead of competing stacked cards.
- 2026-04-12: the final 12.8 utility cleanup keeps `Hand`, `Bank`, and `Players` content-only and non-scroll, makes the bank reuse the hand chip geometry in normal viewing, places `Trade` as a full-width row inside the hand shelf, and hardens the dock button layout so `End Turn` stays visible on iPad.
- 2026-04-10: the layout contract is now explicit in code and tests rather than informal view tweaking: the shell stays locked to `12% / 70% / 18%`, the lower rail splits into a `6%` handle band and `12%` dock row, the overlay shelf provides the only intentional overlap, the board clips strictly to its slot, and the board hint sits bottom-center inside the ocean margin rather than as a large translucent HUD.
- 2026-04-12: device feedback showed that freezing the entire shell to a larger host size fixed lag but broke the visible layout contract: shelves could be cut off and the board/shelf boundary could drift when the Messages host became smaller. Stage 12.8 now keeps the shell fitted to the current visible host bounds, leaves the expensive board path on the throttled/no-rebuild resize route, auto-collapses utility shelves that cannot fit a usable body, and still caps the lower-rail width so hand, bank, and player shelves keep a consistent reading width across iPhone and iPad.
- `MessagesExtensionTests` still emits an Xcode dependency-scan warning because Tuist does not support a direct unit-test dependency on an iMessage extension target in this project shape. The current workaround remains compiling selected extension source files into the test target; capture any future cleanup under the tech-debt tracker rather than forcing a larger restructure into this phase.
- Real-device validation is expected to drive at least some late-stage UX adjustments; do not treat Simulator-only behavior as sufficient signoff for Messages-hosted gameplay.
- If setup, trade, or dev-card orchestration starts overwhelming `GameShellView` or `LobbyDriverViewModel`, split it into feature-local helpers rather than growing more shared conditionals.
- Lobby join/start should preserve the current authority model unless there is an explicit product request to change it: one invite `STATE`, join `INTENT`s, one host-published start `STATE`.

## Outcome

Planned result:

- the lobby and core gameplay loop are playable from the product UI
- trade and dev-card flows are compact but coherent enough that a full match does not rely on raw IDs, hidden timing assumptions, or stacked debug-era shell affordances as the primary product behavior
- board taps, shell modes, and modal choices map cleanly into canonical intents
- once the current device QA closes stage 12.8, the repo is ready for a narrower phase 13 focused on Messages-host stability, transcript recovery, and durability instead of still using phase 12 to finish basic gameplay UX

What remains after this phase by design:

- Messages-host stability, reload/active-game sync, and transcript collapse/readability work
- multi-game lifecycle, archive/leave/forfeit, and durable game identity work
- recap/history/dispute UX
- final bubble composition polish
- any visual restyling that does not change the gameplay-flow substrate
