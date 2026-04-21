# Render & Gameplay Performance Audit — 2026-04-12

Scope: investigate sources of UI lag when rendering the board and during
gameplay interactions. The audit focuses on the three hot paths that run
on every state change and every tap:

1. `GameShellProjectionBuilder.build(state:)` — triggered by every decoded
   STATE/intent message.
2. `GameBoardScene.updateBase/updateOverlay` — triggered whenever the
   render model or overlay changes.
3. Legal-move queries in `CoreGameViewQueriesV1` — driven by the
   availability/overlay builders during projection construction and every
   mode change.

Findings are ordered by expected impact on perceived lag. File and line
references point at the current tip of `phase-driven-dev`.

---

## Top finding — fix this first

### F1. `StandardBoardTopologyV1.standard()` and `.renderGeometry()` are rebuilt on every call

**Severity: CRITICAL. Cost: ~O(tens of thousands of redundant ops per
state update).**

`StandardBoardTopologyV1.standard()`
(`Packages/ULS_CoreGame/Sources/ULS_CoreGame/StandardBoardTopologyV1.swift:5`)
and `.renderGeometry()` (line 33) both re-run the full geometry
construction (`buildGeometry()`, line 66) on every call:

- 19-tile × 6-corner lattice walk with two hash tables
  (`nodesByPoint`, `edgesByNodes`)
- `coastalEdgeCycle()` traversal over 30 coastal edges with sort
- `canonicalFramePortEdges()` with angular-distance sort
- Three `precondition` checks that re-run on every invocation

These are **pure, deterministic, parameterless** functions. Nothing
about the result changes between calls.

They are then called repeatedly from *every* legal-move query in
`CoreGameViewQueriesV1`. Every `legalBuildRoadEdges`,
`legalBuildSettlementNodes`, `legalSetupRoadEdges`,
`legalRoadBuildingFirstEdges`, `legalRoadBuildingSecondEdges`,
`knightVictimCandidateNodes`, `robberVictimCandidateNodes`,
`isRoadConnected`, and `bestMaritimeTradeRatio` opens with

```swift
let topology = StandardBoardTopologyV1.standard()
```

(`CoreGameViewQueriesV1.swift:141, 167, 274, 288, 334, 360, 418, 439, 468, 586, 624`)

The worst amplifier is `legalRoadBuildingFirstEdges`
(`CoreGameViewQueriesV1.swift:273`): it filters every edge in
`topology.edges.indices` (72 edges) and for each candidate calls
`legalRoadBuildingSecondEdges`, which *also* runs `standard()` and
filters all 72 edges. That is ~5,184 filter iterations per call, each
touching `isRoadConnected` which again calls `standard()`. One
`canSendPlayRoadBuildingIntentDebug` lookup can trigger tens of
thousands of topology reconstructions before returning a single bool.

During `GameShellProjectionBuilder.build(state:)`, the availability
computation (`LobbyDriverViewModel.swift:391` — `shellActionAvailability`)
touches 8+ `canSend…IntentDebug` properties, several of which drive
`legalRoadBuildingFirstEdges`, `legalBuildRoadEdges`,
`legalBuildSettlementNodes`, and `defaultMaritimeTrade`. The
projection build also calls `GameScreenModelBuilder.build` which calls
`GameBoardRenderModelBuilder.build`
(`MessagesExtension/Sources/Board/GameBoardRenderModelBuilder.swift:9-10`),
which makes *two* back-to-back calls:

```swift
let topology = StandardBoardTopologyV1.standard()
let geometry = StandardBoardTopologyV1.renderGeometry()
```

Each `renderGeometry()` also calls `buildGeometry()` internally, so
`buildGeometry` runs twice per render-model build even in the happy path.

**Fix (one-liner level of effort):**

```swift
public enum StandardBoardTopologyV1 {
    public static let standard: BoardGraphV1 = buildStandardTopology()
    public static let renderGeometry: BoardRenderGeometryV1 = buildRenderGeometry()
    // keep static func variants as thin forwarders if call sites expect ()
}
```

Because the inputs are fixed, caching is guaranteed-correct. Expect the
biggest single-item perf win in the whole codebase from this change.
Pair with a one-off `GeometryCache.shared` if you want the derived
`edgeToTiles` / `nodeToIncidentEdges` tables as well (see F5).

---

## Critical — rendering hot path

### F2. `GameBoardLayout` recomputes everything on every property access

**Severity: CRITICAL. Cost: ~1–4k float ops per property access,
triggered in nested loops while building the scene and on every tap.**

`GameBoardLayout` (`Board/GameBoardLayout.swift:4`) is a value type with
**only** computed properties — no cached state. Every access to
`tileRadius`, `roadWidth`, `structureRadius`, `boardCenter`,
`contentFrame`, `tileCenter(for:)`, `nodePoint(for:)`, `edgeLine(for:…)`,
or `edgeAngle(for:…)` re-derives the entire layout from scratch.

Cascade example — reading `tileRadius` (line 18):

1. `tileRadius` → `normalizedTileRadius * layoutScale`
2. `normalizedTileRadius` (line 193) iterates **every** tile center
   (19) and for each iterates **every** node (54) computing `hypot`.
   That is **1,026 hypot calls per read**.
3. `layoutScale` (line 182) calls `expandedBounds`.
4. `expandedBounds` (line 212) calls `bounds`.
5. `bounds` (line 117) computes min/max over 54 node positions
   (two `.map` allocations).
6. `point(for:)` — used by every `tileCenter`/`nodePoint` call — also
   internally calls `expandedBounds` + `layoutScale`, so reading one
   point is 3× the cascade again.

Now look where this is called:

- `GameBoardScene.updateBase`
  (`Board/GameBoardScene.swift:68`) — rebuilds a
  `GameBoardLayout` on every update, then calls `makeTileNode` 19 times,
  `makeRoadNode` per road, `makeStructureNode` per structure,
  `makePortNode` 9 times. Each node builder calls `layout.tileRadius`
  (or derived) and `layout.tileCenter(for:)`/`nodePoint(for:)` multiple
  times.
- `GameBoardScene.updateOverlay`
  (`Board/GameBoardScene.swift:163`) — rebuilds a fresh layout on every
  overlay change (happens on every tap selection change).
- `GameBoardCameraController.hitTarget`
  (`Board/GameBoardCameraController.swift:87`) — builds a fresh layout
  on every tap and walks nodes/edges/tiles. In `.idle` mode it walks
  all 54 nodes + 72 edges + 19 tiles per tap.
- `GameBoardSnapshotRenderer.render` — fresh layout during resize
  freezes.

Worst case: a single tap can trigger dozens of fresh layout constructions,
each one performing thousands of redundant trig/hypot calls that always
return the same numbers.

**Fix:**

Make `GameBoardLayout` compute everything in `init` and store results:

```swift
struct GameBoardLayout {
    let size: CGSize
    let geometry: BoardRenderGeometryV1
    let tileRadius: CGFloat
    let roadWidth: CGFloat
    let structureRadius: CGFloat
    let contentFrame: CGRect
    let boardCenter: CGPoint
    private let nodePoints: [CGPoint]        // precomputed 54
    private let tileCenters: [CGPoint]       // precomputed 19
    // …
}
```

Then `tileCenter(for:)` and `nodePoint(for:)` become `O(1)` array lookups
with no allocation or trig.

---

### F3. `SKShapeNode` used for every tile, road, structure, port, and overlay highlight

**Severity: HIGH. Cost: death by a thousand shape rasterizations.**

`GameBoardScene` builds the board out of many, many `SKShapeNode`
instances (`Board/GameBoardScene.swift:205-703`):

- Per tile (19): shadow, hex, inner ring, token circle (+ label). 4
  shape nodes × 19 = **76 shape nodes** just for tiles.
- Per road (up to 60 on a full game): 4 shape nodes (shadow,
  road line, highlight, outline) = **up to 240 shape nodes**.
- Per structure (up to 36): 3 shape nodes. **~108 shape nodes**.
- Per port (9): 3 shape nodes (two tethers + badge). **27 shape nodes**.
- Overlays: every legal node/edge/tile gets 1–2 shape nodes
  per update.

In steady state, the scene can easily hold **450–500 `SKShapeNode`
instances**. Apple has warned for years that `SKShapeNode` rasterizes
via Core Graphics on the CPU and does not batch well. The framework is
slow enough at ~100 shapes that guidance is to use `SKSpriteNode` with
a baked `SKTexture` for anything static.

This also interacts badly with the cache-invalidation logic
(`updateBase`, lines 70–137): any key mismatch calls
`removeAllChildren()` on a layer and rebuilds every shape node from
scratch. On a device, this is visibly chunky when the state changes
(for example, when a road or settlement is placed).

**Fix options, in priority order:**

1. **Bake static layers to textures.** `backdropContentNode`,
   `tileContentNode`, and `portContentNode` only depend on the board
   layout, which is fixed at game start. Build them once into an
   `SKTexture` (via `SKView.texture(from:)` or manual rasterization)
   and render as a single `SKSpriteNode` per layer.
2. **Share paths.** `hexagonPath(radius:)` is recomputed per call
   (line 684). Cache one hex `CGPath` per unique radius used. Same for
   `structurePath` and `structureCapPath` (lines 710, 736).
3. **Keep overlay minimal.** Overlay highlights rebuild on every
   selection tap. Given the small count this is survivable, but see
   F4 below for the much cheaper alternative (don't rebuild the whole
   layer when only the selected target changed).
4. **If you must keep `SKShapeNode`**, at least set
   `lineWidth` sensibly low and avoid tiny `lineCap = .round` where
   possible; they multiply rasterization cost.

---

### F4. Layers are torn down and rebuilt on cache miss instead of diffed

**Severity: HIGH. Cost: GC churn + re-rasterization every key miss.**

`GameBoardScene.updateBase`
(`Board/GameBoardScene.swift:62-138`) uses
`cachedXxxLayerKey` structs to decide whether to rebuild each layer.
The keys include `BoardGraphV1`, full `[GameBoardRoadRenderModel]`
arrays, and `[String]` player order. Two issues:

1. **Equality walks large structures.** Comparing a cached
   `RoadLayerKey` to a new one compares `topology: BoardGraphV1`
   (which is 19 tiles + 72 edges + 9 ports of value-type structs) plus
   the full road array. The cache "hit" case still pays this cost
   every update.
2. **Any mismatch wipes the whole layer.** `removeAllChildren()` then
   `for road in renderModel.roads { node.addChild(makeRoadNode(…)) }`
   (line 107–117). Adding one road rebuilds every road. Moving the
   robber rebuilds every tile. This is why placing a piece feels like
   it "judders."

**Fix:**

Use a monotonic revision int (or a small fingerprint) as the cache
key, and diff by edge/node id to reuse unchanged children:

```swift
private var knownRoadEdges: [EdgeID: SKNode] = [:]
private var roadRevision: UInt64 = 0
// In update: compute new edge set, remove missing, add new, leave rest.
```

Also stop including `BoardGraphV1` in cache keys — topology does not
change during a game; putting it in the key just makes the miss path
more expensive.

---

### F5. `BoardGraphV1` adjacency queries walk the full edge list per call

**Severity: HIGH. Cost: O(E) per call, called in O(E) loops.**

`BoardGraphV1.edges(incidentTo:)` (line 107),
`nodes(adjacentTo:)` (line 113), `tiles(adjacentToNode:)` (line 122),
`tiles(adjacentToEdge:)` (line 128), and `portKind(at:)` (line 138) all
do an O(72) scan with a `.enumerated().filter.map` allocation per call.

They are called from inside loops in
`legalBuildSettlementNodes`
(`CoreGameViewQueriesV1.swift:377-388`), `legalSetupSettlementNodes`
(line 428-434), and other legal-move functions. When `legalBuildSettlementNodes`
filters 54 candidate nodes, for each one it calls `topology.nodes(adjacentTo:
nodeID)` (full edge scan) and then `topology.edges(incidentTo: nodeID)`
(another full edge scan). The inner filter then walks the incident edges
checking road ownership. Combined with F1 (topology rebuilt each call),
a single legal-settlement query is ~O(|V| × (|E| + |E|)) = ~7,700 ops
*before* the topology-rebuild multiplier.

**Fix:**

Precompute adjacency tables once when the topology is built and store
them on the graph:

```swift
public struct BoardGraphV1 {
    // … existing fields …
    public let incidentEdgesByNode: [[EdgeID]]        // [NodeID: [EdgeID]]
    public let adjacentNodesByNode: [[NodeID]]
    public let tilesByNode: [[TileID]]
    public let tilesByEdge: [[TileID]]
}
```

These are deterministic and match the existing memoization opportunity
in F1. Expose them from `StandardBoardTopologyV1.standard` once, then
every caller becomes `topology.incidentEdgesByNode[nodeID]` — an O(1)
array lookup.

---

## High — SwiftUI/projection churn

### F6. `GameShellProjection` bundles 36 debug strings with render models; `removeDuplicates` walks all of them on every publish

**Severity: HIGH. Cost: pathological re-render triggers + wasted Equatable walks.**

`GameShellProjection` (`Presentation/GameShellProjection.swift:4`) has
**36 `String` fields** plus 4 nested models. Most of the strings
(`boardResourcesByTile`, `boardNumbersByTile`, `boardPortsByIndex`,
`visibleHands`, `bankResources`, `devDeckRemaining`, `visibleDevCards`,
`pendingDiscardRequirements`, `submittedDiscardsStatus`, and the
turn/intent/setup/board debug strings) are **debug telemetry that the
rendered GameShellView never reads** — see `GameShellView.swift:22-48`
which only uses `projection.gameScreenModel`, `phase`,
`setupGuidanceText`, `discardPanelModel`, `tradePanelModel`,
`robberVictimOptions`.

Every state change rebuilds all 36 strings via
`GameShellProjectionBuilder.build(state:)`
(`Presentation/GameShellProjection.swift:171-234`), including enumerating
the board tile grid 3 times for the debug strings
(`boardResourcesByTile`, `boardNumbersByTile`, `boardPortsByIndex` at
lines 200–208), and running `visibleResourceHands`/`visibleDevCards`
projections solely to join them into a debug string.

Then on the SwiftUI side,
`GameShellView.onReceive(viewModel.$gameplayShellProjection.removeDuplicates())`
(line 246) drops duplicates — but `removeDuplicates()` calls the
auto-synthesized `==` which compares all 40+ fields.

This burns work twice: once to compute the debug strings that are
thrown away, and once to compare them before deciding to update state.

**Fix:**

Split the projection cleanly:

```swift
struct GameShellRenderProjection: Equatable {
    let gameScreenModel: GameScreenModel
    let phase: PhaseV1
    let setupGuidanceText: String?
    let discardPanelModel: GameDiscardPanelModel?
    let robberVictimOptions: [GameRobberVictimOption]
    let tradePanelModel: GameTradePanelModel?
}

// Keep the debug struct behind `#if DEBUG` or a toggle so it doesn't
// even exist in release builds.
```

Publish only the render projection on the hot path. In
`LobbyDriverViewModel`, keep the debug fields on a separate
`ObservableObject` (or just `@Published` directly, detached from the
game shell) so that their mutations don't invalidate the shell view.

This also unblocks F7 and F11.

---

### F7. `LobbyDriverViewModel` has 29 `@Published` properties; 22 of them are debug strings

**Severity: HIGH. Cost: every debug-string setter fires `objectWillChange`.**

`LobbyDriverViewModel.swift:9-37` declares 29 `@Published` properties.
22 of them are debug strings (`selectionStatus`, `selectedTrigger`,
`selectedMessagePresence`, `selectedURLPresence`, `selectedURLString`,
`selectedPayloadQueryPresence`, `selectedPayloadLength`,
`selectedSummaryText`, `selectedLayoutCaption`,
`selectedSessionPresence`, `selectedDecodeSource`,
`selectedDecodeResult`, `localParticipantDebug`, `resolvedActorDebug`,
`localInRosterDebug`, `localPendingJoinDebug`, `canJoinDebug`,
`isInviterDebug`, `lastError`, `actingAs`, `activeContextSource`,
`activeContextUpdatedAgo`, `staleContextWarning`, `latestUpdateNotice`).

Plus the 40+ field-for-field forwarding setters on the projection
struct (lines 85–232), each of which reads the current projection,
mutates one string, and reassigns — publishing the whole projection
and triggering Equatable comparisons in every observer.

`GameShellView` observes only
`viewModel.$gameplayShellProjection` directly via `.onReceive`, so it
is partially insulated. But anything reading `viewModel` as an
`@ObservedObject` (including any debug HUD or the lobby screen) will
invalidate on every string mutation.

**Fix:**

- Delete unused debug fields. `diagnosticsEnabled = false` and
  `showsLatestUpdateNotices = false` in release, so most of this state
  is write-only telemetry.
- For the remaining debug fields, put them behind
  `#if DEBUG` or a non-`@Published` subobject so production builds do
  not pay the `objectWillChange` cost.
- Remove the per-field forwarding setters at lines 85–232. The
  `gameplayShellProjection` is already published; these legacy
  shims exist so `var gameId: String { get set }` pattern still works
  for tests, but the test-friendly API can be built with a different
  abstraction.

---

### F8. `GameBoardRenderModelBuilder.build` runs on every screen-model build and has no memoization

**Severity: MEDIUM-HIGH. Cost: topology rebuild (F1 amplifier) + array allocations on every update.**

`GameBoardRenderModelBuilder.build`
(`Board/GameBoardRenderModelBuilder.swift:4`) runs on every call to
`GameScreenModelBuilder.build`
(`Presentation/GameScreenModelBuilder.swift:18`), which runs on every
call to `GameShellProjectionBuilder.build`. It:

1. Calls `StandardBoardTopologyV1.standard()` (see F1).
2. Calls `StandardBoardTopologyV1.renderGeometry()` (see F1).
3. Re-maps tiles, ports, structures, roads.
4. `sorted` on structures and roads.

Since `state.stateHash` uniquely identifies the state, memoize by
state hash:

```swift
private static var cachedStateHash: String?
private static var cachedModel: GameBoardRenderModel?

static func build(state: CoreGameStateV1?) -> GameBoardRenderModel? {
    guard let state, let hash = Optional(state.stateHash), let board = state.board
    else { cachedModel = nil; cachedStateHash = nil; return nil }

    if cachedStateHash == hash, let cachedModel { return cachedModel }
    // … build as before, then cache
}
```

Pair with F1's `static let` topology and this becomes effectively free
on re-renders of the same state.

---

### F9. `BoardSceneView` re-equates the whole render model on every SwiftUI pass

**Severity: MEDIUM. Cost: redundant Equatable walks.**

`BoardSceneView` declares `View, Equatable` with

```swift
static func == (lhs: BoardSceneView, rhs: BoardSceneView) -> Bool {
    lhs.renderModel == rhs.renderModel
        && lhs.overlayModel == rhs.overlayModel
        && lhs.interactionMode == rhs.interactionMode
}
```

(`Board/BoardSceneView.swift:33-37`)

This is correct in intent (skip body re-evaluation when inputs match)
but the comparison walks the entire `GameBoardRenderModel` every time
— including `topology: BoardGraphV1` (which never changes during a
game) and `playerOrder: [String]`. Combine with F6 which causes the
parent to invalidate more often than necessary, and these walks happen
frequently.

**Fix:** once F8 memoizes the render model, identity comparison
(`lhs.renderModel === rhs.renderModel` via a class wrapper, or a
version int) is enough. Alternatively, store a `renderRevision: UInt64`
inside the render model and only compare that in the Equatable.

---

### F10. Tile/overlay rebuild triggers on every selection tap, not just legal-set changes

**Severity: MEDIUM. Cost: per-tap overlay layer rebuild.**

When the player taps a legal target, `selectedBoardTarget` changes in
`GameShellView`, which causes
`viewModel.makeBoardOverlayModel(mode:…, selectedTarget:)`
(`Features/Game/GameShellView.swift:40`) to return a new
`GameBoardOverlayModel` (different `selectedTarget`). That triggers
`onChange(of: overlayModel)` in `BoardSceneView`
(`Board/BoardSceneView.swift:96`), which calls `scene.updateOverlay`.
`scene.updateOverlay` compares `OverlayLayerKey` — which includes the
full `overlayModel` — fails, and calls `removeAllChildren()` +
`addChild(makeOverlayNode(…))` which rebuilds every highlight shape
(`Board/GameBoardScene.swift:140-171`).

In practice this means each tap causes a full overlay teardown and
recreation of ~6–30 `SKShapeNode` highlights. Visually it shows up as
a flicker when selecting a legal spot.

**Fix:** treat the selected target as a separate, small layer on top of
the legal-set layer. Rebuild legal highlights only when the legal sets
change; move just the "selected ring" on selection changes.

---

## Medium — CoreGame query economy

### F11. Availability checks repeat the same legal-move queries

**Severity: MEDIUM. Cost: amplifier for F1, F5.**

`LobbyDriverViewModel.shellActionAvailability`
(`Features/Lobby/LobbyDriverViewModel.swift:391`) is a computed
property that touches 13 `canSend…IntentDebug` properties. Multiple of
them run overlapping legal-move queries:

- `canSendBuildRoadIntentDebug` → `firstLegalRoadEdge(for:)` →
  `legalBuildRoadEdges` → walks edges and calls
  `isRoadConnected` per edge.
- `canSendBuildSettlementIntentDebug` → `firstLegalSettlementNode(for:)`
  → `legalBuildSettlementNodes` → walks nodes and calls
  `topology.nodes(adjacentTo:)` and `topology.edges(incidentTo:)` per
  candidate.
- `canSendBuildCityIntentDebug` → `firstUpgradeableCityNode(for:)`.
- `canSendPlayRoadBuildingIntentDebug` → `legalRoadBuildingFirstEdges`
  (the O(E²) one from F1).

This runs once for `shellActionAvailability` during projection build,
then again for `shellModeAvailability`, plus the trade and dev-card
equivalents. Each one rebuilds topology per call (until F1 is fixed).

**Fix:**

- Fix F1 first; it alone drops the cost by an order of magnitude.
- Then add a `LegalMoveCache` keyed on `state.stateHash + actor` that
  stores `legalBuildRoadEdges`, `legalBuildSettlementNodes`,
  `legalBuildCityNodes`, `legalSetupSettlementNodes`, etc. All
  availability checks collapse to `!cache.buildRoadEdges.isEmpty`.

---

### F12. `visibleResourceHands` / `visibleDevCards` recomputed multiple times per projection build

**Severity: MEDIUM.**

`GameShellProjection.visibleHandsSummary` (line 209) calls
`state.visibleResourceHands(for:)`. `GameScreenModelBuilder.makeOpponentSummaries`
(line 86) calls it again. `makeHandChips` (line 110) calls it a third
time. `visibleDevCardsSummary` (line 212) calls `visibleDevCards` and
`GameDevCardPanelModelBuilder.build` (line 20) calls it again.

The functions themselves are cheap — O(roster) — but they allocate
arrays and map over all players every invocation. On hot path, expect
~6–8 duplicate calls per state update.

**Fix:** build once at the top of projection construction, pass the
result down into the builders.

---

### F13. `defaultRoadBuildingEdges` computes twice

`defaultRoadBuildingEdges`
(`CoreGameViewQueriesV1.swift:264`) calls
`legalRoadBuildingFirstEdges` and then, for the winning edge, calls
`legalRoadBuildingSecondEdges` — which internally filters the full
edge list again. Combined with F1's topology rebuilds, this compounds
badly.

**Fix:** fold into a single `firstValidEdgePair()` that walks edges
once and returns on the first valid pair.

---

### F14. `roadsByEdge.values.filter { $0 == player }.count` is repeated throughout

Examples:
`CoreGameViewQueriesV1.swift:345, 371, 406, 563, 2804-2807`.

Each call walks the whole road dictionary allocating a new array just
to count. Cheap per call but called many times per state update.

**Fix:** maintain a `piecesUsedByPlayer: [String: PlayerPieceCounts]`
derived once per state, or replace with a single-pass reduce.

---

## Lower-impact findings

### F15. `hexagonPath` / `structurePath` rebuilt per node
`Board/GameBoardScene.swift:684, 710, 736`. Each tile/structure/highlight
recomputes the same `CGPath` (6 points of sin/cos). Cache one path per
radius as a static dictionary or `lazy var`.

### F16. `Array(0..<totalCount)` allocated per tap in idle mode
`Board/GameBoardCameraController.swift:341, 363, 383`. Trivial allocation
but avoidable; switch to `stride` or just return empty if
`interactionMode == .idle` should not route to highlights.

### F17. `contentFrame` iterates node positions 4 times
`Board/GameBoardLayout.swift:39-42, 53-57`. Four `.map { nodePoint(for:) }`
passes when one loop with running min/max would do.

### F18. `GameBoardPalette` color lookups do linear searches over `playerOrder`
Not opened in this audit, but grep `playerOrder: [String]` usage:
several call sites search for the player's owner index by linear scan.
Precompute `[String: Int]` on first use.

### F19. `GameBoardSnapshotRenderer` builds a throwaway `SKView`
`Board/GameBoardSnapshotRenderer.swift:39`. Each resize-freeze path
constructs a whole new `SKView` and `SKScene`. This runs only during
resize-freeze, so impact is bounded, but if resize is sluggish this is
one amplifier.

### F20. `GameShellView.body` recomputes `resolvedMode` / shelf presentation on every pass
`Features/Game/GameShellView.swift:25-29`. These themselves are cheap,
but the flood of computed values at the top of `body` could be gated
on the handful of inputs that actually change by pulling them into a
small `StateObject`-like cache.

### F21. `precondition` checks in hot path
`StandardBoardTopologyV1.buildGeometry()` runs three `precondition`
calls every invocation (lines 113–115). Cheap per call, but they are
on the hot path of F1; once F1 is fixed this becomes moot.

---

## Recommended order of operations

1. **F1** — cache `StandardBoardTopologyV1.standard` / `.renderGeometry` as
   `static let`. This single change likely removes the bulk of the
   lag and unblocks accurate measurement of everything else.
2. **F2** — precompute `GameBoardLayout` in `init`. Second-biggest win.
3. **F5** — add precomputed adjacency tables to `BoardGraphV1`.
4. **F8** — memoize `GameBoardRenderModelBuilder` by `stateHash`.
5. **F6, F7** — shrink `GameShellProjection` and drop debug `@Published`
   fields.
6. **F3, F4, F10** — bake static board layers to textures and diff the
   overlay instead of tearing it down on every tap.
7. **F9** — switch `BoardSceneView.==` to identity/revision comparison
   after F8 lands.
8. **F11, F12, F13, F14** — dedupe availability/visibility queries and
   factor out repeated role counts.
9. Mop up F15–F21 opportunistically.

## How to verify

- **Instruments → Time Profiler** on a real device, focus on
  `GameBoardScene.updateBase`, `GameBoardLayout.normalizedTileRadius`,
  and any function on the `StandardBoardTopologyV1` stack.
- **Instruments → SwiftUI** to watch view update counts on
  `GameShellView` and `BoardSceneView` — they should drop substantially
  after F6/F7/F9.
- **Count check**: log the number of `StandardBoardTopologyV1.standard()`
  calls per state update before and after F1. Expect >1000 → 1.
- **Tests**: the existing `ULS_CoreGame` and `MessagesExtension` test
  suites should continue to pass. Add a small perf test that asserts
  `legalRoadBuildingFirstEdges` completes in <10 ms on a populated
  board.

---

*Auditor: Claude (Opus 4.6, 1M context) on 2026-04-12. No code changes
were made as part of this audit; all findings are read-only
observations from the current `phase-driven-dev` branch.*
