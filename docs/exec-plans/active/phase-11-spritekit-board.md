# Phase 11 — SpriteKit Board

## Summary

Replace the phase-10 board placeholder with a real SpriteKit board surface that is stable enough for setup, build, robber, and later gameplay flows.

This phase exists now because phase 10 already established the shell, mode system, and presentation boundaries. The next bottleneck is no longer shell structure; it is the lack of a real board surface that can render canonical state, map taps back to board IDs, and generate the compact board snapshot the bubble experience needs.

Success means:

- `MessagesExtension` renders a real board instead of placeholder art
- the board can map taps to `TileID`, `NodeID`, and `EdgeID` deterministically
- pan and zoom feel sane inside the Messages extension without fighting the surrounding shell
- shell modes can drive board affordances and highlight overlays without the board deciding legality
- the phase produces a reusable snapshot renderer for the board so the bubble can become board-backed rather than status-only

Owner docs for concepts used here:

- [README](/Users/kunalsharda/Documents/Code/UnluckySevens/README.md) for tracked repo entrypoint and commands
- [ARCHITECTURE](/Users/kunalsharda/Documents/Code/UnluckySevens/ARCHITECTURE.md) for runtime boundaries and ownership
- [decisions](/Users/kunalsharda/Documents/Code/UnluckySevens/docs/decisions.md) for locked product and protocol rules
- [UI Flows](/Users/kunalsharda/Documents/Code/UnluckySevens/docs/product-specs/ui-flows.md) for setup/turn/trade flow expectations
- [QA](/Users/kunalsharda/Documents/Code/UnluckySevens/docs/quality/qa.md) for the current validation gate and device lane
- [Phase 2 Plan](/Users/kunalsharda/Documents/Code/UnluckySevens/docs/exec-plans/completed/phase-2-determinism-and-board.md) for the deterministic board and topology substrate this phase builds on
- [UI Hardening Plan](/Users/kunalsharda/Documents/Code/UnluckySevens/docs/exec-plans/completed/phase-ui-hardening.md) for the readiness work that moved legality and secrecy-safe queries into the engine
- [Phase 10 Plan](/Users/kunalsharda/Documents/Code/UnluckySevens/docs/exec-plans/completed/phase-10-ui-shell.md) for the shell and mode contracts phase 11 must respect

## Current State

What exists today:

- phase 10 is complete: the Messages extension now has a board-first shell, persistent hand-and-action tray, shell mode system, and a secondary debug surface
- the shell already reserves a board container and uses `GameMode` plus `GameModeAvailability` as the interaction contract
- the engine already owns legality, visibility, and default action selection through [CoreGameViewQueriesV1.swift](/Users/kunalsharda/Documents/Code/UnluckySevens/Packages/ULS_CoreGame/Sources/ULS_CoreGame/CoreGameViewQueriesV1.swift)
- the canonical board topology already exists in [BoardGraphV1.swift](/Users/kunalsharda/Documents/Code/UnluckySevens/Packages/ULS_CoreGame/Sources/ULS_CoreGame/BoardGraphV1.swift) and [StandardBoardTopologyV1.swift](/Users/kunalsharda/Documents/Code/UnluckySevens/Packages/ULS_CoreGame/Sources/ULS_CoreGame/StandardBoardTopologyV1.swift)
- the current board UI is still placeholder-only:
  - [BoardContainerView.swift](/Users/kunalsharda/Documents/Code/UnluckySevens/MessagesExtension/Sources/Board/BoardContainerView.swift)
  - [BoardPlaceholderArtView.swift](/Users/kunalsharda/Documents/Code/UnluckySevens/MessagesExtension/Sources/Board/BoardPlaceholderArtView.swift)

What is missing:

- a real board renderer
- a deterministic mapping from board topology IDs to screen-space hit targets
- mode-driven highlights for setup/build/robber interactions
- pan and zoom tuned for compact Messages real estate
- a board snapshot renderer for future bubble output

Important constraints already in the repo:

- the board must remain a consumer of core legality and visibility, not a second rules engine
- no gameplay or transport semantics should change in this phase
- the board surface must fit inside the current shell rather than forcing a shell rewrite
- the current player and hidden-information rules are already owned by the engine and presentation layers
- device validation matters more here than in ordinary SwiftUI work because Messages-hosted interaction is flakier in Simulator than on hardware

## Target End State

User-visible result:

- the game screen shows a real board with tactile tiles, settlements, cities, roads, ports, and robber position
- the user can pan and zoom the board without losing shell usability
- the board responds visually to the active shell mode:
  - setup modes emphasize legal placement targets
  - build modes emphasize legal edges or nodes
  - robber modes emphasize legal tiles and possible victims
- the shell still reads as warm tabletop and board-first rather than turning into a generic SpriteKit canvas embedded inside a utility app

Code and docs result:

- the board stack under `MessagesExtension/Sources/Board/` owns rendering, camera control, hit-testing, and snapshot rendering
- the board stack exposes a clear surface back to SwiftUI:
  - current render model
  - selected board target
  - hit callbacks
  - snapshot image generation
- shell modes stay owned by the SwiftUI shell, while the board only reflects them
- any additive geometry helpers introduced in `ULS_CoreGame` are limited to deterministic board-layout support and do not alter gameplay semantics

Acceptance boundary:

- phase 11 ends when the board is real, tappable, highlight-capable, and snapshot-capable
- phase 11 does not complete player-facing setup/build/robber/trade/dev-card UX flows; those remain phase 12 work
- phase 11 does not yet replace the shell’s inline deferred-flow host with full flow-specific sheets or action composers
- phase 11 does not lock final art direction for tiles, pieces, ports, robber iconography, or snapshot styling; visual redesign remains intentionally possible after the interaction substrate is stable

## Implementation Plan

### Stage 11.1 — Board Layout Contract and Scene Bridge

Goal:

- define the deterministic contract between topology IDs and the rendered board

Implement:

- a board layout model that maps canonical `TileID`, `NodeID`, and `EdgeID` to renderable positions
- a `SpriteView` bridge inside `BoardContainerView`
- a thin SwiftUI-to-SpriteKit integration layer that can accept:
  - board setup
  - current placements
  - robber tile
  - active shell mode
  - current selection

Key files and likely additions:

- `MessagesExtension/Sources/Board/BoardSceneView.swift`
- `MessagesExtension/Sources/Board/GameBoardScene.swift`
- `MessagesExtension/Sources/Board/GameBoardLayout.swift`
- `MessagesExtension/Sources/Board/GameBoardRenderModel.swift`
- additive helper only if needed in `ULS_CoreGame` for stable exported board geometry

Commands:

```bash
bash ./scripts/gen.sh
xcodebuild -workspace UnluckySevens.xcworkspace -scheme MessagesExtension -destination 'generic/platform=iOS Simulator' build
```

Expected observations:

- the placeholder art is no longer the only board path
- a deterministic board render model exists before SpriteKit styling grows
- topology IDs have one canonical mapping into view-space

### Stage 11.2 — Board Rendering and Piece Layers

Goal:

- render the actual board state with clear layer separation

Implement:

- tile rendering for the current board setup
- token/value rendering for tile numbers
- ports
- settlements and cities
- roads
- robber marker

Rendering rules:

- warm tactile look, not photorealistic wood-shop mimicry
- pieces must read clearly at Messages extension size
- roads, settlements, and cities must prioritize legibility over ornament
- opponent ownership must be visible without requiring heavy labels

Key files:

- `MessagesExtension/Sources/Board/GameBoardScene.swift`
- `MessagesExtension/Sources/Board/GameBoardNodeFactory.swift`
- `MessagesExtension/Sources/Board/GameBoardPalette.swift` if a board-local palette helper is needed

Commands:

```bash
xcodebuild -workspace UnluckySevens.xcworkspace -scheme MessagesExtension -destination 'generic/platform=iOS Simulator' build
xcodebuild -workspace UnluckySevens.xcworkspace -scheme UnluckySevens-Workspace -destination 'platform=iOS Simulator,name=iPhone 15' test
```

Expected observations:

- the board visually carries the product surface instead of the placeholder card doing all the work
- rendering still fits the current shell and bottom tray without crowding

### Stage 11.3 — Camera, Pan/Zoom, and Hit-Testing

Goal:

- make the board navigable and interactive without collapsing the shell

Implement:

- camera bounds
- sensible zoom floor and ceiling
- pan behavior that cooperates with the surrounding shell
- hit-testing for:
  - tile taps
  - node taps
  - edge taps
- a typed board-target abstraction such as `tile(TileID)`, `node(NodeID)`, `edge(EdgeID)`

Key files:

- `MessagesExtension/Sources/Board/GameBoardCameraController.swift`
- `MessagesExtension/Sources/Board/GameBoardTarget.swift`
- `MessagesExtension/Sources/Board/GameBoardScene.swift`
- `MessagesExtension/Sources/Features/Game/GameShellView.swift` for callback wiring

Commands:

```bash
xcodebuild -workspace UnluckySevens.xcworkspace -scheme UnluckySevens-Workspace -destination 'platform=iOS Simulator,name=iPhone 15' test
```

Expected observations:

- board taps round-trip to canonical IDs
- pan/zoom feels stable on device and in Simulator
- the board remains usable without hiding the shell

### Stage 11.4 — Mode-Driven Highlights and Selection Plumbing

Goal:

- make the board reflect current shell mode and current selection clearly

Implement:

- overlays/highlights keyed off `GameMode`
- selected-target emphasis
- legal-target emphasis using engine query outputs and mode-specific availability

Rules:

- the board may highlight based on legality inputs, but it must not decide legality on its own
- highlights must be visually obvious but restrained
- forced modes such as `setup`, `discard`, `robberMove`, and `robberVictim` should feel blocking and unambiguous

Likely additive work:

- extend presentation types if the board needs richer highlight inputs than phase 10 exposes today
- if the current core query surface is insufficient for highlight fidelity, add additive query helpers to `ULS_CoreGame`

Commands:

```bash
swift test --package-path Packages/ULS_CoreGame --skip ULS_CoreGameEvals
xcodebuild -workspace UnluckySevens.xcworkspace -scheme UnluckySevens-Workspace -destination 'platform=iOS Simulator,name=iPhone 15' test
```

Expected observations:

- mode changes now affect both shell chrome and board affordances
- the user can tell where they are supposed to tap next without reading debug text

### Stage 11.5 — Snapshot Rendering and Bubble Preparation

Goal:

- produce a reusable board snapshot surface for the future hybrid bubble

Implement:

- deterministic board snapshot rendering from the current render model
- size-aware snapshot variants suitable for transcript bubble use later
- a lightweight snapshot API the shell or bubble pipeline can call without depending on live interactivity

Rules:

- snapshot rendering is required in this phase, not optional
- snapshot output should prioritize recognizability over full informational density
- the snapshot should reinforce status lines such as:
  - `Your turn`
  - `Waiting on <player>`
  - `Trade pending`

Key files:

- `MessagesExtension/Sources/Board/GameBoardSnapshotRenderer.swift`
- `MessagesExtension/Sources/Board/GameBoardRenderModel.swift`
- any bubble-prep helper under `Presentation/` if needed later

Commands:

```bash
xcodebuild -workspace UnluckySevens.xcworkspace -scheme MessagesExtension -destination 'generic/platform=iOS Simulator' build
```

Expected observations:

- the board can be rendered both as a live surface and as a compact static artifact
- phase 12 and later bubble work no longer need to invent board imagery

## Validation

### Automated

Run the full repo gate for any substantial stage landing:

```bash
bash ./scripts/gen.sh
swift test --package-path Packages/ULS_CoreGame --skip ULS_CoreGameEvals
swift test --package-path Packages/ULS_CoreGame --filter ULS_CoreGameEvals
swift test --package-path Packages/ULS_Transport
xcodebuild -workspace UnluckySevens.xcworkspace -scheme MessagesExtension -destination 'generic/platform=iOS Simulator' build
xcodebuild -workspace UnluckySevens.xcworkspace -scheme UnluckySevens-Workspace -destination 'platform=iOS Simulator,name=iPhone 15' test
```

Add phase-11-specific tests where practical:

- board layout determinism tests
- hit-target mapping tests
- snapshot smoke tests if the renderer can be tested without full UI hosting
- any additive core query tests required for highlight plumbing

### Manual

Simulator checks:

1. Open a selected canonical `STATE` and confirm the real board renders instead of placeholder art.
2. Pan and zoom the board without losing the bottom tray or compact header.
3. Toggle shell modes and confirm board highlights update.
4. Tap one tile, one node, and one edge and verify the shell receives the correct target type.
5. Confirm robber and ownership visuals are readable without the debug HUD.

Real-device checks:

1. Run the `Real Device Shell Smoke` checklist from [QA](/Users/kunalsharda/Documents/Code/UnluckySevens/docs/quality/qa.md).
2. On both iPhone and iPad, confirm the board remains readable and pan/zoom remains controllable inside Messages.
3. Confirm the board still reloads correctly when context changes between older and newer `STATE` bubbles.
4. Confirm snapshot-backed bubble prep does not regress transcript readability when wired in later.

### Deferred Validation

Deferred by design in phase 11:

- complete setup/build/robber/trade/dev-card player flows
- transcript-level automated Messages interaction
- final bubble-card composition using the new snapshot renderer

Reason for deferral:

- those concerns are better exercised once the board is real and stable, but they still belong to later UI-flow work rather than the board foundation itself

## Progress

- [x] Stage 11.1 — Board Layout Contract and Scene Bridge
- [ ] Stage 11.2 — Board Rendering and Piece Layers
- [ ] Stage 11.3 — Camera, Pan/Zoom, and Hit-Testing
- [ ] Stage 11.4 — Mode-Driven Highlights and Selection Plumbing
- [ ] Stage 11.5 — Snapshot Rendering and Bubble Preparation

Update this section during execution with dates, brief milestone notes, how each milestone was reached, and where execution looped or got stuck.

- 2026-03-14 — Stage 11.1 landed. Added additive deterministic render geometry export in `ULS_CoreGame`, a pure `GameBoardRenderModel` builder in `MessagesExtension`, and the first SpriteKit board bridge via `BoardSceneView` and `GameBoardScene`.
- 2026-03-14 — Validation looped once on tooling rather than code: concurrent `xcodebuild` use previously caused a build-database lock, and `ULS_Transport` needed a clean dependency rebuild before SwiftPM picked up the new `BoardRenderGeometryV1.swift` source file.

## Decisions and Discoveries

Initial expectations for this phase:

- SpriteKit is the correct board substrate here because the board needs deterministic geometry, lightweight camera behavior, and richer hit-testing than a pure SwiftUI stack is likely to provide cleanly
- the shell should keep ownership of mode and intent drafting; the board should only render, select, and report hit targets
- any geometry exported from `ULS_CoreGame` must stay additive and deterministic; no gameplay semantics should move into the UI to make rendering easier
- snapshot rendering is part of the product path, not an optional extra
- this phase should lock geometry, hit-target mapping, camera behavior, and snapshot APIs, but it should not freeze final art assets or prevent later board-style redesign

Record here during execution:

- whether deterministic board-layout geometry stayed inside `MessagesExtension` or needed additive support from `ULS_CoreGame`
- whether pan/zoom inside Messages required shell-level gesture compromises
- whether highlight fidelity required more engine query surface than phase 10 exposed
- any device-specific Messages-host quirks that materially affected the board approach

- 2026-03-14 — Deterministic board-layout geometry needed additive support from `ULS_CoreGame`. `StandardBoardTopologyV1.renderGeometry()` now exports stable tile-center and node-position data so the UI does not invent a parallel ID-to-position mapping.
- 2026-03-14 — `MessagesExtensionTests` is source-based rather than target-based, so stage 11.1 also required adding the pure board render-model files to the test target source list in `Project.swift`.

## Outcome

Not started.

When phase 11 is complete, replace this section with:

- what landed
- what remains for phase 12
- which technical debt or follow-on cleanup should be tracked explicitly
