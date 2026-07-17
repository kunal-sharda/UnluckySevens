# Tabletop UI System

Status: **Approved**

This contract extracts the durable interface system approved through the normal post-roll Physical Props Turn Screen. It tells future screen work what to reuse, what may adapt, and which ownership boundaries may not move. [DESIGN.md](../../DESIGN.md) remains the concise visual owner; production code remains the value and behavior source of truth.

## 1. The Tabletop Scene

Unlucky Sevens should read as a real game table inside Messages: a dominant live island, public objects above it, private or actionable objects below it, and compact status embedded directly in the felt. Physicality comes from recognizable silhouettes, restrained contact shadows, stacking, overlap, material edges, and consistent scale—not painted textures, ornamental panels, or fake perspective.

The tabletop has three visual layers:

1. **Board layer:** the live island, ocean, ports, tokens, canonical pieces, robber, legal targets, and camera.
2. **Object layer:** cards, dice, roads, settlements, cities, ships, flags, resource marks, and player icons.
3. **Language layer:** short labels, counts or qualitative levels, pending/new markers, costs, and contextual prompts.

The board remains the champion whenever it is present. Object and language layers support the board; they do not frame it with dashboard chrome.

## 2. Sources of Truth

| Concern | Production source | Contract |
| --- | --- | --- |
| General felt/material theme | `GameTheme` | Owns broad felt, cream, wood, ink, resource, spacing, radius, and motion seeds used across established surfaces. |
| Physical-props semantics | `GamePhysicalTurnPalette` | Owns warm felt text, amber action context, Harbor Blue Dev cards, and wooden name-tile treatment. |
| Board/ocean rendering | `GameBoardPalette`, `GameBoardScene` | Own SpriteKit colors, layers, shoreline treatment, highlights, and renderer behavior. |
| Resource identity | `ResourceV1+TabletopPresentation`, Board/mini stamp assets | One resource family supplies fill, dark terrain-derived ink/edge, detailed art, and purpose-rendered micro art. |
| Responsive geometry | `GamePhysicalTurnLayout`, `GameShellLayoutMetrics` | Ratios with minimum/maximum bounds replace device-specific offsets. |
| Piece silhouettes | `GamePieceGeometry` | SpriteKit and SwiftUI use the same Road, Settlement, and City geometry. |
| Legality and availability | Core/query and presentation models | SwiftUI renders executable outputs; it does not recreate rules. |
| Board ownership | SpriteKit board host | Opening SwiftUI surfaces never changes board identity, camera, canonical pieces, targets, or frame. |

The document owns **why and when** a role is used. The listed code owns exact numeric color and geometry values so documentation does not drift into a second token implementation.

## 3. Semantic Material and Color Roles

### Felt

- Dark green felt is the continuous game surface and primary negative space.
- Raised felt may separate dense information such as Game Information, but it must remain quieter than cards and the board.
- Do not add decorative grain, stitched borders, glass blur, or nested felt panels.

### Ocean and board frame

- The ocean is one rounded teal field with a subtle shoreline Halo: lighter near the island, darker toward the outside.
- The field may extend slightly farther below the island to balance the full-display center, never farther above in a way that crowds public objects.
- Cream topology lines frame the complete hex grid. Terrain-local dark edges and colored stamps provide secondary separation.
- Ocean treatment may not change board topology, target coordinates, camera behavior, or the SpriteKit host identity.

### Cream and ink

- Warm cream is the high-contrast tabletop light: dice bodies, primary text on felt, board seams, number tokens, and restrained selection separation.
- Near-black or terrain-derived dark ink carries card marks, resource drawings, counts, and molded piece edges.
- Secondary copy is a reduced-opacity version of the same warm cream—not generic gray.

### Amber action context

- Amber is reserved for an action the player can take now, the currently selected action context, or a legal target.
- It appears as a thin keyline, compact underline, selection index, or board target highlight.
- It is never decorative fill and does not outline every tappable item by default.
- A grouped choice may use one amber contextual prompt instead of outlining every equivalent choice. A mixed spread containing executable and non-executable items uses per-item amber keylines.
- Amber must be paired with shape, lift, text, selection traits, or target geometry; color alone never communicates state.

### Player color

- Player-owned roads, settlements, cities, and the End flag use the canonical player color.
- Live pieces add a darker mixture of the same color as their molded edge so they remain visible on like-colored terrain.
- Player color communicates ownership, not legality. Amber continues to communicate action and targeting.

### Card families

- Resource cards use canonical terrain fill, matching dark edge/ink, and the approved detailed stamp.
- Public and owned Dev cards use the same Harbor Blue family and portrait orientation.
- The public Dev back uses the factory mark. Owned Dev faces use card-specific marks while preserving the same family and aspect ratio.
- Public resource stacks and the public Dev stack share exact card geometry so public ownership reads as one rail.

## 4. Typography and Iconography

- Use San Francisco system text styles. Gameplay status, labels, costs, and controls do not introduce a custom font.
- Primary tabletop copy uses warm cream; supporting copy uses the same hue at reduced opacity.
- Keep prompts to one concise action clause: generally a verb plus object, such as `Place a road` or `Choose a resource`.
- Use full player-facing names where ambiguity matters. Long compact Dev names may use two intentional lines (`Year of / Plenty`, `Road / Builder`, `Victory / Point`).
- Visible text must not be authored below the system `caption2` style. Accessibility labels may be fuller than visible labels.
- SF Symbols are used for familiar system controls and player-group status. Authored vectors are reserved for game objects whose silhouette carries tabletop meaning.
- Wooden name tiles label resting rail props and public stacks. Choice-spread labels sit directly on felt and do not gain a second wooden button background.

## 5. Reusable Object Grammar

### Portrait cards

- Canonical public size: `38 × 47pt`.
- Canonical Hand size: `46 × 57pt`.
- Other cards preserve the same aspect ratio and scale proportionally.
- Stack depth uses small diagonal offsets; it never becomes a fanned toolbar button background.
- Counts or `H/M/L` overlays fade the underlying mark but keep enough art visible to retain identity.
- Exact Bank counts stay private to the model on the normal Turn Screen. The public reveal uses qualitative levels only.

### Dice

- Dice are physical action or result objects, not numbered rectangular controls.
- Use conventional pips, a cream body, dark pips, a quiet edge, and a readable total when showing a result.
- Rolling must remain an explicit player action whenever Core says a roll is required.

### Roads, settlements, and cities

- Always consume shared `GamePieceGeometry`; never redraw a second SwiftUI approximation.
- Road remains thinner and visually subordinate to structures.
- Settlement is the canonical peaked house.
- City is larger than Settlement and uses one peaked tower with a low rectangular wing.
- Build costs use Core-owned values with purpose-rendered resource micro stamps.

### Ship and flag

- The authored merchant ship is the Trade object and the generic port marker. It uses warm wood, cream sails, white flags, and a dark outline.
- The flag is the End object. Its cloth uses player color and its foot/pole use warm wood.
- Neither may be substituted with an unrelated SF Symbol when shown as a tabletop prop.

### Resource artwork

- Large cards and board tiles use the approved detailed resource drawings.
- Ports and cost pips use purpose-rendered 1×/2×/3× mini PNGs derived from that same art.
- Never shrink the large PNG at runtime for a micro context, replace it with a stylistically unrelated glyph, or generate a raster approximation.

## 6. State Grammar

| State | Visible treatment | Interaction and accessibility |
| --- | --- | --- |
| Resting | Object sits directly on felt with a restrained contact shadow and subordinate label where needed. | Stable label and 44pt hit region when interactive. |
| Action context | Compact amber underline/keyline or legal-target highlight; prompt names the immediate verb. | Exists only when Core/query says an action is executable. |
| Selected | Slight lift, tighter shadow, selected label/keyline, and non-color geometry change. | `.isSelected`; tapping the same object closes it when the flow allows. |
| Pressed | Brief `0.98` depth compression or equivalent system feedback. | No bounce or decorative choreography. |
| Pending | Persistent concise text such as `Pending` paired with a restrained amber edge. | VoiceOver value states what is pending and for whom when public. |
| Held/new | Card remains visible, faded or marked `New`, without an amber action keyline. | Non-interactive; VoiceOver reports held/new reason. |
| Unavailable rail action | No prop, placeholder, or accessibility node; the fixed anchor stays empty. | Hitless and accessibility-hidden. |
| Unavailable choice within visible inventory | Object may remain visible when ownership/public information matters, but it is subdued. | Disabled with an explanatory accessibility value or hint. |
| Destructive confirmation | Compact inline confirmation, with the safe action first and destructive action clearly named. | Never a full-screen warning for an ordinary turn action. |

Selection ownership is singular: choosing Hand, Build, Trade, nested Dev, End, or Game Information replaces the active action-well surface and clears incompatible local draft state. Public information toggles such as Bank reveal may remain independent when the product contract explicitly says so.

## 7. Layout and Responsive Contract

- Use bounded responsive resolvers based on the available host size. Do not add simulator-model branches or one-device offsets.
- Align heterogeneous props by their topmost and bottommost **visible artwork**, not by transparent asset or SwiftUI bounds.
- Every prop receives a shared optical stage; per-prop offsets compensate only for authored visible bounds.
- Public cards, action-well contents, and bottom props remain inside the board's visual width unless a deliberate public grouping requires less width.
- The canonical island—not merely its teal container—is centered on the full display for the fully expanded gameplay host.
- Top bar, public rail, board frame, action well, and prop rail keep stable resolved frames while nested routes change.
- Internal action content may scroll or scale within its reserved region; it must not push the board.
- Compact and tall phones use the same hierarchy. Wider hosts may increase reserved dimensions within the resolver's bounds but do not invent a separate composition.
- Safe areas and the Messages host grabber remain clear. Interactive objects may be visually smaller than 44pt only when wrapped by an invisible 44×44pt target.

## 8. Prompt Contract

The compact top status has two modes:

- **Passive:** dice result, waiting status, current actor, or other stable table state.
- **Active:** one short presentation-derived instruction with a thin amber underline.

The existing prompt vocabulary is the starting set:

- Build: choose piece, place road/settlement, upgrade city, tap again to place/upgrade.
- Trade: choose trade, make offer, trade with Bank, waiting for players.
- Dev/robber: choose Dev Card, move robber, choose player/resource(s), place first/second road.

New prompts must describe the immediate action, fit on one line at supported Dynamic Type sizes where practical, and derive from presentation state rather than SwiftUI legality checks.

## 9. Accessibility and Motion

- Every interactive control has a minimum 44×44pt hit region even when the visible prop is smaller.
- Labels remain stable across visual states. Values and hints explain selected, pending, held/new, concealed/revealed, and unavailable reasons.
- Selection, ownership, pending state, and legality never rely on color alone.
- Decorative card art, contact highlights, and shadows stay hidden from accessibility so the object is announced once.
- Fixed unavailable anchors contain no accessibility node.
- Default action-well replacement may use a short opacity and depth transition. Reduce Motion uses opacity only or an effectively immediate crossfade.
- Board identity and camera remain stable during every SwiftUI transition.
- Dynamic Type uses system text styles; compact labels may scale down within a bounded frame but may not clip or disappear.

## 10. Screen Reuse Modes

These are **not priority, quality, maturity, or rollout tiers**. They only describe how much of the gameplay-table composition a screen should reuse.

### Mode 1 — Same gameplay table

Use the complete five-zone hierarchy and stable live board. Appropriate for normal turn and Start of Turn.

### Mode 2 — Board-guided flow

Keep the live board dominant and reuse physical pieces, cards, compact prompts, player/status language, and targeting. Rails may simplify because the flow is blocking or another player owns the action. Appropriate for Setup, Not Primary Player, and forced-seven flows.

### Mode 3 — Same visual family

Reuse typography, color roles, card/wood/felt materials, spacing, icon weight, and action semantics without copying the gameplay shell. Appropriate for Lobby, Settings, Recovery, End hierarchy, and the icon family.

| Current surface | Reuse mode | Required reuse | Deliberate adaptation |
| --- | --- | --- | --- |
| Tabletop UI System Contract | Foundation | This document and mapped sources | No product surface. |
| Start of Turn (Roll + Dev) | Same gameplay table | Board, top/public rails, Hand-nested Dev entry, dice, prompt/action grammar | Replace post-roll action spread with explicit Roll and legal pre-roll Dev routes. |
| Lobby Invite / Ready | Same visual family | Felt/cream/wood roles, typography, player iconography, action amber | Welcoming rules/setup card; no gameplay rails or fake props toolbar. |
| Initial Setup Placement | Board-guided flow | Board, shared pieces, player color, amber targets, compact prompts | Blocking settlement-then-road guidance and setup order. |
| Not Primary Player | Board-guided flow | Same board/public table/status and trade objects | Remove unavailable local turn props; add incoming-trade and waiting surfaces. |
| Discard / Robber | Board-guided flow | Hand cards, prompts, board targets, player/victim objects | Blocking progress and exact resource selection; no ordinary turn rail. |
| Recovery + Error | Same visual family | Calm typography, material surfaces, icon weight, explicit amber actions | Trust-first copy and standard retry/reopen controls; no transport jargon or decorative props. |
| End Screen | Same visual family + final board | Final board, player colors, awards, felt/cream hierarchy | Winner and scores dominate; board becomes contextual rather than interactive. |
| Settings | Same visual family | Typography, spacing, restrained material accents, system icons | Standard scan-friendly list/navigation controls; do not simulate physical props for preferences. |
| App Icon | Same visual family, reduced | Harbor/felt/cream/amber or one approved piece silhouette | One simple silhouette at icon scale; never shrink the board or combine many props. |

## 11. Iteration Protocol

Each remaining visual slice follows the same economical loop:

1. Reuse an existing UX Lab fixture and production components.
2. Lock scope, validation profile, delivery posture, and excluded surfaces.
3. Compare no more than three representative states.
4. Use direct simulator stills for visual judgment; XCUITest proves navigation and geometry.
5. Allow one focused correction round by default.
6. Record explicit approval before productionizing ambiguous nested states.
7. Run the selected full validation profile once after direction settles.

Do not create a second shell, duplicate Core legality, add generated raster props, or launch broad specialist review during a visual checkpoint.

## 12. Conformance Fixes Included in Review

These narrow mismatches were discovered while extracting the contract and corrected before review. They do not broaden the slice into a redesign.

1. **Shoreline Halo default — resolved:** `GameBoardOceanStyle.productionDefault` is now Halo while DEBUG comparisons remain available.
2. **Pending trade treatment — resolved:** pending state now changes the anchored wooden label to `Pending` instead of floating a second badge over the ship. Its accessibility label remains `Trade` with the value `Pending offer`.
3. **Inline tabletop actions — resolved:** physical-props actions such as `Replace Offer`, `Keep Playing`, and `End Turn` share one system Caption treatment and the established neutral/amber keyline semantics instead of inheriting blue bordered-button chrome.

Everything else in this contract describes the approved production direction or a boundary already enforced by existing code and tests.
