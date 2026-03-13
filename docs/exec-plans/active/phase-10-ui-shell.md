# Phase 10 — SwiftUI Shell

## Summary

Build the first real player-facing UI shell inside `MessagesExtension` without changing gameplay rules or transport behavior.

This phase exists to replace the current debug-heavy extension surface with a structured SwiftUI shell that is ready for the SpriteKit board and full gameplay flows in phases 11–13.

Success means:

- the extension renders a real game shell instead of a debug-first screen
- legal actions and visible information come from `ULS_CoreGame` query helpers rather than UI heuristics
- `MessagesExtension` is internally decomposed enough to avoid another monolithic phase
- the board renderer for phase 11 can plug into a stable shell rather than forcing a later UI rewrite
- the shell establishes the product's visual direction: warm tactile tabletop, board-first, playful but not cluttered

Owner docs for concepts used here:

- [README](/Users/kunalsharda/Documents/Code/UnluckySevens/README.md) for tracked repo entrypoint and commands
- [ARCHITECTURE](/Users/kunalsharda/Documents/Code/UnluckySevens/ARCHITECTURE.md) for runtime boundaries and ownership
- [decisions](/Users/kunalsharda/Documents/Code/UnluckySevens/docs/decisions.md) for locked product and protocol rules
- [QA](/Users/kunalsharda/Documents/Code/UnluckySevens/docs/quality/qa.md) for the current validation gate
- [Tech Debt Tracker](/Users/kunalsharda/Documents/Code/UnluckySevens/docs/exec-plans/tech-debt-tracker.md) for phase-10-specific debt pressure

## Current State

What exists today:

- the engine is UI-ready and exposes legality/default action helpers plus viewer-safe projections in [CoreGameViewQueriesV1.swift](/Users/kunalsharda/Documents/Code/UnluckySevens/Packages/ULS_CoreGame/Sources/ULS_CoreGame/CoreGameViewQueriesV1.swift)
- transport, payload-size guards, tests, evals, and CI are already in place
- the extension target now has a first-stage internal split across:
  - [MessagesViewController.swift](/Users/kunalsharda/Documents/Code/UnluckySevens/MessagesExtension/Sources/App/MessagesViewController.swift)
  - [MessagesRootView.swift](/Users/kunalsharda/Documents/Code/UnluckySevens/MessagesExtension/Sources/App/MessagesRootView.swift)
  - [LobbyDriverView.swift](/Users/kunalsharda/Documents/Code/UnluckySevens/MessagesExtension/Sources/Features/Lobby/LobbyDriverView.swift)
  - [LobbyDriverViewModel.swift](/Users/kunalsharda/Documents/Code/UnluckySevens/MessagesExtension/Sources/Features/Lobby/LobbyDriverViewModel.swift)
  - [GameShellView.swift](/Users/kunalsharda/Documents/Code/UnluckySevens/MessagesExtension/Sources/Features/Game/GameShellView.swift)
- debug tooling exists and is useful, but stage 10 still needs to keep it separate from the product shell rather than letting it define the main surface

What is missing:

- a real SwiftUI shell with consistent hierarchy
- a visual system that matches the intended warm tabletop, playful-social tone
- a clean internal folder and type structure inside `MessagesExtension`
- a mode system for setup/build/robber/trade/dev/discard interactions
- product-oriented shell components such as a header, action dock, hand panel, and modal host
- a clear boundary between normal play UI and debug HUD functionality

Constraints already locked in the repo:

- `ULS_CoreGame` remains the owner of gameplay truth, legality, and viewer-safe visibility
- `ULS_Transport` remains the owner of the protocol boundary
- `MessagesExtension` may format and compose, but must not become a second rules engine
- phase 10 does not introduce SpriteKit gameplay interaction yet
- phase 10 does not change protocol fields, validation semantics, or deterministic engine behavior

## Target End State

User-visible result:

- opening a game in Messages shows a board-first shell with a turn/header area, compact opponent summaries, a board container area, a compact always-visible hand tray, an icon+label action dock, and a modal host
- debug controls remain available for development, but they are behind an explicit toggle and are not the default product surface
- the shell reads as a tactile tabletop game rather than a generic app screen

Code result:

- `MessagesExtension` is internally organized by responsibility
- SwiftUI views consume presentation models rather than fishing through raw state
- interaction state is explicit through a mode system
- a stable board container API exists for the phase 11 SpriteKit renderer
- the shell already encodes the later bubble direction: a hybrid status-forward card with a compact board snapshot

Acceptance boundary:

- phase 10 is complete when the shell is real, stable, and wired to core queries
- phase 10 does not include real board hit-testing, legal board overlays, full gameplay-flow polish, or audit-log UX

## Implementation Plan

### Stage 10.1 — Visual System and Shell Hierarchy

Goal:

- lock the product direction before more UI structure lands

Define the shell's visual rules up front:

- warm tactile tabletop palette
- stronger typography for headings and status
- restrained motion only
- board-first hierarchy
- compact always-visible hand tray
- icon+label primary action dock
- compact opponent strip that shows only:
  - player color
  - name
  - VP
  - hand count
  - current-turn marker when relevant

Layout rules to lock in this stage:

- board first
- hand second
- status third
- actions always visible but not visually dominant
- opponent summaries compact and secondary
- progressive disclosure for everything deeper than the common turn actions

Bubble direction to lock for later phases:

- hybrid bubble
- strong status line first, compact board snapshot second
- examples:
  - `Your turn`
  - `Waiting on <player>`
  - `Trade pending`

Expected observations:

- phase 10 implementation stops making ad hoc visual decisions file by file
- later phases inherit a stable UI hierarchy instead of reopening core product decisions

### Stage 10.2 — Internal Extension Decomposition

Goal:

- stop future UI work from collapsing back into a monolithic extension target

Create internal structure under `MessagesExtension/Sources/`:

- `App/`
- `Features/Lobby/`
- `Features/Game/`
- `Presentation/`
- `Components/`
- `Board/`
- `Debug/`

Initial file targets:

- `MessagesExtension/Sources/App/MessagesRootView.swift`
- `MessagesExtension/Sources/Features/Game/GameScreenView.swift`
- `MessagesExtension/Sources/Presentation/GameScreenModel.swift`
- `MessagesExtension/Sources/Presentation/GameMode.swift`
- `MessagesExtension/Sources/Presentation/GameModalState.swift`
- `MessagesExtension/Sources/Presentation/ActionAvailability.swift`
- `MessagesExtension/Sources/Components/GameHeaderView.swift`
- `MessagesExtension/Sources/Components/ActionDockView.swift`
- `MessagesExtension/Sources/Components/HandPanelView.swift`
- `MessagesExtension/Sources/Components/PlayerSummaryStripView.swift`
- `MessagesExtension/Sources/Board/BoardContainerView.swift`
- `MessagesExtension/Sources/Debug/DebugHUDView.swift`

Key execution notes:

- move code incrementally so the extension still builds after each slice
- prefer one type per file
- keep `MessagesViewController` focused on host/extension lifecycle glue only

Expected observations:

- `LobbyDriverViewModel.swift` shrinks materially
- product UI composition no longer depends on one giant file

### Stage 10.3 — Presentation Layer and Screen Model

Goal:

- define the UI-facing contract inside `MessagesExtension`

Add presentation models for:

- turn/header state
- visible opponent summaries with only VP and hand count
- visible hand and development-card state for the local viewer
- primary action availability
- current mode
- active modal
- recap snippet
- board container state
- shell theme and layout state where needed

Primary inputs:

- canonical game state
- local viewing or acting player
- outputs from [CoreGameViewQueriesV1.swift](/Users/kunalsharda/Documents/Code/UnluckySevens/Packages/ULS_CoreGame/Sources/ULS_CoreGame/CoreGameViewQueriesV1.swift)

Rules:

- presentation types may derive labels, grouping, and visual sections
- presentation types must not invent legality or hidden-information rules
- presentation types should optimize for compact Messages layout rather than desktop-style information density

Expected observations:

- SwiftUI views render from `GameScreenModel`-style inputs
- engine-owned legality and secrecy decisions remain centralized

### Stage 10.4 — Mode System

Goal:

- make interaction state explicit and phase-11-ready

Add a mode system covering at least:

- `idle`
- `setup`
- `buildRoad`
- `buildSettlement`
- `buildCity`
- `robberMove`
- `robberVictim`
- `trade`
- `playDevCard`
- `discard`

Rules:

- entering or leaving a mode must not mutate canonical game state
- mode only changes selection, affordances, and intent drafting
- mode availability is constrained by core query outputs

Expected observations:

- UI actions have one clear interpretation based on current mode
- later board hit-testing can map taps into mode-driven selections without changing shell architecture

### Stage 10.5 — SwiftUI Shell Components

Goal:

- build the stable visual frame for the game screen

Implement:

- `Header`
- `ActionDock`
- `HandPanel`
- `ModalHost`
- `GameScreen`
- `BoardContainer` placeholder
- compact player summary strip

Shell behavior requirements:

- the current player and current step are obvious
- the action dock exposes only legal high-level flows
- opponent hands remain count-only
- the board area is visually reserved even before the SpriteKit renderer lands
- the hand tray stays visible in compact form and expands only when deeper interaction is needed
- the action dock uses icon+label buttons rather than text-only or tab-like controls
- the shell feels tactile and warm rather than flat or hyper-minimal
- motion stays restrained: simple transitions, no ambient motion noise

Expected observations:

- a selected `STATE` renders into an intentional layout rather than a debug control panel
- UI hierarchy remains readable in the compact Messages extension context

### Stage 10.6 — Debug HUD Separation and Phase-End Hardening

Goal:

- preserve debugging power without making it the main product UX, and end the phase with a stable shell base

Implement:

- a debug HUD toggle
- a separate debug surface for transcript/context inspection
- a clear visual distinction between normal game actions and debug actions

Wire:

- transcript-selected canonical state into the presentation layer
- action dock items into mode changes or intent drafting
- modal host into mode-driven flows
- hand panel into viewer-safe projections
- debug HUD toggle into the existing debug tooling

Do not implement the real board yet.

Instead:

- land a board container placeholder with a stable API surface for phase 11
- define any placeholder board state needed to avoid churn when SpriteKit arrives

Expected observations:

- the shell is functional and stable
- phase 11 can focus on board rendering and hit-testing instead of shell rescue work
- development workflows still work because debug access stays easy before launch
- product UI is understandable without reading debug labels

## Validation

### Automated

Run the standard repo gate:

```bash
bash ./scripts/gen.sh
swift test --package-path Packages/ULS_CoreGame --skip ULS_CoreGameEvals
swift test --package-path Packages/ULS_CoreGame --filter ULS_CoreGameEvals
swift test --package-path Packages/ULS_Transport
xcodebuild -workspace UnluckySevens.xcworkspace -scheme MessagesExtension -destination 'generic/platform=iOS Simulator' build
```

Additional expectations during implementation:

- add focused tests for any non-trivial presentation or mode logic that can be exercised without UI hosting
- keep `ULS_CoreGame` and `ULS_Transport` tests unchanged unless a real regression is found

### Manual

Simulator smoke script for the phase end:

1. Generate the workspace and build the Messages extension.
2. Launch Messages in Simulator and open Unlucky Sevens from the app drawer.
3. Select a recent canonical `STATE`.
4. Confirm the shell renders a header, player summaries, board container area, hand panel, and action dock.
5. Confirm opponent hands show only counts and not composition.
6. Confirm only legal high-level actions are surfaced.
7. Toggle the debug HUD on and off and verify it does not replace the main shell.
8. Change modes and confirm the shell updates without mutating state by itself.
9. Confirm stale or invalid contexts still fail safely instead of surfacing illegal actions.

### Deferred Validation

Deferred by design in phase 10:

- transcript-level automated Messages UI harnesses
- real SpriteKit board interaction and legal highlights
- physical-device Messages smoke on iPhone and iPad

Reason for deferral:

- those validations are better aligned with phase 11 board work and later UI-flow work, and they should build on a stable shell rather than precede it

## Progress

- [x] Stage 10.1 — Visual System and Shell Hierarchy
- [x] Stage 10.2 — Internal Extension Decomposition
- [x] Stage 10.3 — Presentation Layer and Screen Model
- [ ] Stage 10.4 — Mode System
- [ ] Stage 10.5 — SwiftUI Shell Components
- [ ] Stage 10.6 — Debug HUD Separation and Phase-End Hardening

Update this section during execution with dates, brief milestone notes, how each milestone was reached, and any places where execution looped or got stuck.

- 2026-03-13: Stages 10.1 and 10.2 landed together through a parallel-shell migration. Added theme tokens, a new `MessagesRootView`, a game-shell placeholder path, and the initial `MessagesExtension` folder decomposition while keeping `LobbyDriverView` accessible as the debug HUD. The main loop during execution was deciding whether to keep the lobby driver visible inline or move it into a separate debug surface; the separate debug sheet won because it preserved current tooling without cluttering the shell.
- 2026-03-13: Validation for the stage-10.1 slice finished green. `bash ./scripts/gen.sh`, `swift test --package-path Packages/ULS_CoreGame --skip ULS_CoreGameEvals`, `swift test --package-path Packages/ULS_CoreGame --filter ULS_CoreGameEvals`, `swift test --package-path Packages/ULS_Transport`, `xcodebuild -workspace UnluckySevens.xcworkspace -scheme MessagesExtension -destination 'generic/platform=iOS Simulator' build`, and `xcodebuild -workspace UnluckySevens.xcworkspace -scheme UnluckySevens-Workspace -destination 'platform=iOS Simulator,name=iPhone 15' test` all passed. The eval lane remained the long pole at about 311 seconds, which matches its role as the deterministic full-match harness rather than the fast inner-loop test.
- 2026-03-13: Stage 10.3 landed as a pure presentation extraction. Added `GameScreenContext`, `GameActionAvailability`, wrapper presentation models, and a pure `GameScreenModelBuilder`; `GameShellView` now renders from a single `GameScreenModel`, and `LobbyDriverViewModel` only assembles raw shell inputs plus grouped action availability. Validation stayed green through `bash ./scripts/gen.sh`, the workspace test action, the MessagesExtension build, transport tests, the fast CoreGame lane, and the deterministic eval lane. The main execution loop here was choosing whether to introduce a new screen view model; that was rejected in favor of pure builders so stage 10.4 can add modes without a second ownership layer.

## Decisions and Discoveries

Initial decisions already locked for this phase:

- keep presentation logic inside `MessagesExtension` rather than introducing a new package
- keep gameplay legality and viewer-safe visibility in `ULS_CoreGame`
- treat the board renderer as a phase 11 dependency, not a phase 10 deliverable
- keep `README.md` as the tracked human entrypoint and `AGENTS.md` as local-only agent guidance
- use a warm tactile tabletop direction with stronger typography rather than a flat default SwiftUI look
- keep the board as the visual hero with a compact always-visible hand tray below it
- use icon+label primary actions and restrained motion
- keep debug access easy before launch, but visually separate from the product shell
- keep presentation ownership in pure builders/types under `Presentation/`, with `LobbyDriverViewModel` remaining the Messages/context integration point rather than adding a separate screen view model in phase 10

Record here during execution:

- folder or file naming adjustments
- shell hierarchy changes
- modal strategy changes
- any facts discovered about Messages extension sizing or lifecycle that materially affect the shell

- Stage 10.1/10.2 implementation chose a parallel-shell migration instead of an immediate root swap. `MessagesRootView` now routes lobby contexts to the existing driver and non-lobby contexts to a new `GameShellView`.
- The shell uses a compact always-visible hand tray and icon+label dock now, but keeps action handling intentionally shallow until the mode system lands in stage 10.4.
- The existing debug driver moved behind `DebugHUDView` as a sheet instead of staying inline. This keeps debug access easy pre-launch while making the product shell visually legible.

## Outcome

Not started.

When phase 10 is complete, replace this section with:

- what landed
- what did not land
- which follow-on tasks move directly into phase 11
