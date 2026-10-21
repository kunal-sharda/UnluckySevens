# 2026-08-28 Color-Blind Accessibility Audit

**Scope:** GitHub issue #22. Static audit of production gameplay, transcript, lobby, and Player Record surfaces on 2026-08-28. This is implementation input, not a statement of accessibility compliance. It intentionally excludes concurrent session and trade-correctness work.

## Result

The app has strong non-color cues for resource choice, recipient selection, score/outcome text, and setup order. The material gap is ownership on the live board and its transcript-board rendering: roads and structures receive their owner identity exclusively from the four-color `GameBoardPalette.playerColor` palette. The SpriteKit host's generic diagnostic accessibility label/value is DEBUG-only, so Release builds expose neither a board summary nor per-piece ownership semantics. There is no production use of `accessibilityDifferentiateWithoutColor`.

This is a gameplay-critical failure for people who cannot reliably distinguish the red, blue, cream, and amber player palette. Color remains useful as a redundant cue; it cannot remain the sole ownership cue.

## Inventory

| Surface | Semantic color owner | Existing non-color cue | Audit verdict |
| --- | --- | --- | --- |
| Live board roads and settlements/cities | `GameBoardPalette.playerColor` and `playerStroke`, rendered by `GameBoardScene` | Road/structure silhouette distinguishes piece kind, not owner; Release has no aggregate or per-piece board ownership semantics | **Failure:** owner is color-only visually and unavailable semantically |
| Transcript board and game-over board image | Same render model and `GameBoardScene` snapshot path | Final-score strip names the winner; embedded board ownership still uses color-only pieces | **Failure inherited:** fix must render into snapshot variants too |
| Setup order rail | `GamePlayerTint` forwarded from `GameScreenModelBuilder` | Initials, name/next text, current-player keyline, and accessibility value | Pass for color differentiation |
| Game Information roster | `GamePlayerTint` dot | Player name, VP/cards, current-turn icon, and row keyline | Pass for color differentiation |
| Player-trade recipient rows | `GamePlayerTint` avatar/fill | Name, counts, checkmark, selected trait/value | Pass for color differentiation |
| End score / Player Record standings and honors | `GamePlayerTint` plus independent palettes in `PlayerRecordGroupLedgerView` and `PlayerRecordHonorsView` | Player name, winner seal, points/outcome text, VoiceOver row labels | Pass for color differentiation; both palette copies require token-drift consolidation |
| Resource cards, chips, board tiles, and trade receipt | `GameTheme` resource colors, `ResourceV1+TabletopPresentation`, board resource fills | Resource name/count controls plus distinct stamp illustrations; receipt has direction and status symbols/text | Pass for color differentiation |
| Legal and selected board targets | `GameBoardPalette.legalHighlight` and `selectedHighlight` | Legal targets have a halo/outline; selected targets add a thicker stroke and outer ring | Not a demonstrated color-only failure, but no Differentiate Without Color mode exists; include in visual regression proof |
| Lobby seats and transcript lobby image | `LobbyPalette` | Names/seat-state copy and person icon | Pass for color differentiation |

## Evidence Read

- [GameBoardPalette.swift](../../../MessagesExtension/Sources/Board/GameBoardPalette.swift) owns both player palette selection and the legal/selected colors. Its player identity return type is `SKColor`, which is the root cause of the ownership-only encoding.
- [GameBoardScene.swift](../../../MessagesExtension/Sources/Board/GameBoardScene.swift) applies only color/stroke to every road and structure. Those same scene nodes feed the snapshot renderer used by [TranscriptBubbleImageRenderer.swift](../../../MessagesExtension/Sources/Presentation/TranscriptBubbleImageRenderer.swift).
- [BoardSceneHostView.swift](../../../MessagesExtension/Sources/Board/BoardSceneHostView.swift) assigns its generic diagnostic board label/value only under `#if DEBUG`; Release has no equivalent semantic summary.
- [GamePhysicalSetupOrderRailView.swift](../../../MessagesExtension/Sources/Components/GamePhysicalSetupOrderRailView.swift), [GameTurnGameInfoView.swift](../../../MessagesExtension/Sources/Components/GameTurnGameInfoView.swift), and [GamePhysicalTradeSurfaceView.swift](../../../MessagesExtension/Sources/Components/GamePhysicalTradeSurfaceView.swift) already make identity or selection legible with text, symbols, and accessibility values.
- [ResourceChipGridView.swift](../../../MessagesExtension/Sources/Components/ResourceChipGridView.swift) and [ResourceV1+TabletopPresentation.swift](../../../MessagesExtension/Sources/Presentation/ResourceV1+TabletopPresentation.swift) pair resource tint with visible/semantic labels and distinct stamp assets.
- [PlayerRecordGroupLedgerView.swift](../../../MessagesExtension/Sources/App/PlayerRecordGroupLedgerView.swift) and [PlayerRecordHonorsView.swift](../../../MessagesExtension/Sources/App/PlayerRecordHonorsView.swift) each repeat the board player palette locally. They are not color-only user-flow failures, but neither may remain an independent token source after remediation.
- Repository search found no use of `accessibilityDifferentiateWithoutColor`; existing Dynamic Type coverage is limited to `testCaptureProductionLobbyAccessibilityLayout` in the accessibility catalog.

## Implementation-Ready Batches

### Batch A — Central player identity markers (required)

Introduce one presentation-owned player identity token derived from roster order, alongside—not instead of—the existing tint. It should provide: a stable ordinal/short text identity for semantics, a compact marker shape, and the existing color. Keep it out of `ULS_CoreGame`; roster-to-marker presentation is not rules or protocol state. `GameScreenModelBuilder`, SwiftUI, SpriteKit, and both Player Record views must consume this source rather than deriving or copying colors independently. Unknown owners need an explicit deterministic fallback; do not reuse Swift's process-random `hashValue` as a stable marker key.

Use it in the board renderer:

- Overlay a high-contrast, shape-distinct ownership marker on settlements/cities.
- Render a shape-distinct road treatment (for example, a stable dash/end-cap pattern) so a road owner can be distinguished without relying on its hue.
- Keep the existing dark stroke and color; do not replace the tabletop palette.
- Make the same renderer change flow automatically into transcript board and game-over snapshot images.
- Expose a production aggregate, secrecy-safe board accessibility value that reports visible owned-piece counts. Resolve public player pseudonyms at the presentation boundary, or use approved roster ordinals; `GameBoardRenderModel.playerOrder` contains internal IDs and is not itself suitable user-facing copy. Do not add touch targets or reveal hidden cards/resources, Dev Cards, hidden VP, or legal targets.

Recommended ownership: a new `PlayerIdentityToken` / marker helper under `MessagesExtension/Sources/Presentation` with `GameScreenModelBuilder` and `GameBoardPalette` consuming it, then remove the duplicate four-color arrays from both `PlayerRecordGroupLedgerView` and `PlayerRecordHonorsView`. The existing roster context is sufficient to derive it without protocol changes.

### Batch B — Differentiate-without-color affordances (required with Batch A)

Read `@Environment(\\.accessibilityDifferentiateWithoutColor)` at the SwiftUI-to-board presentation boundary and pass a rendering mode to the board. In that mode, increase marker/stroke contrast and make legal versus selected target geometry unambiguous (legal outline/halo versus selected double ring), while preserving the existing amber palette for other users. Do not add a separate rules engine or a DEBUG-only substitute.

### Batch C — Token and regression consolidation (required after A/B)

Replace both Player Record duplicated palettes with the shared identity token. Add focused unit coverage for stable roster-to-marker assignment, deterministic unknown-owner fallback, and board render-model propagation. Add XCUITest assertions and inspected screenshots for the same board in normal and Differentiate Without Color modes; current tests inspect host geometry and identifiers but do not assert visual ownership differentiation.

## Frozen Follow-Up Proof Set

Run these only in the implementation follow-up, serially and after the required `bash ./scripts/gen.sh` lifecycle:

1. Focused MessagesExtension unit tests for the new identity-token/board-render mapping and existing `GameBoardSceneTests`.
2. Add and name one dedicated isolated UX Lab catalog route based on `testOpenMessagesExtensionAndCaptureCleanSetupGameplaySlice` that contains at least two players’ roads and structures, plus a selected legal target. The implementation ExecPlan must lock the exact route/test name and the exact simulator preference or launch-argument mechanism before production changes. Capture once at default settings and once with Differentiate Without Color enabled through that mechanism.
3. `testGameplayActionVictoryPointReachesGameOverSurface` or an equally deterministic fixture that produces a game-over transcript-board snapshot; inspect the exported image for the markers.
4. `testCapturePhysicalTradeCorrectionTutorialCheckpoint` to guard recipient selected/unselected cues already considered passing.
5. `UI_SCREENSHOT_CONTENT_SIZE=accessibility-medium bash ./scripts/run-ui-screenshot-catalog.sh iphone "$PWD/scripts/ui-screenshot-catalog-accessibility-size.txt"` to retain the existing accessibility-size regression lane; this is supplementary, not color-differentiation proof.
6. Inspect the clean screenshots/XCResults manually, then run `make completion-gate PLAN=docs/exec-plans/active/color-blind-accessibility-audit.md` only after the follow-up plan changes from `explore` to an implementation posture and all contract rows have current evidence.

The current harness has no catalog setting for `differentiateWithoutColor`; adding a bounded simulator preference step or test launch argument is itself part of Batch C. Until the implementation plan names that exact route and setting, this proof row is pending rather than frozen. Do not substitute a default-size screenshot for that proof.

## Non-Findings and Boundaries

- This audit does not evaluate WCAG contrast ratios from screenshots or device pixels. Those require the post-change visual pass in the exact host context.
- It does not assert that all SpriteKit board content becomes individually VoiceOver navigable. The proposed aggregate summary is the narrowest secrecy-safe improvement; individual accessibility elements need a separate interaction design decision.
- Resource colors are not proposed for recoloring because their visible names/stamps and accessibility labels already carry the distinction.
- No production, session, trade, engine, transport, or simulator state was changed during this audit.

## Follow-Up Acceptance Boundary

Close #22 only when player ownership is distinguishable on live and transcript boards without hue, the preference-aware mode is visibly and semantically tested, both Player Record views no longer own duplicate palettes, Release exposes an aggregate public-piece summary using resolved public display names or approved ordinals, and the frozen proof set has an inspected clean result. Until then, this audit is evidence of a known accessibility gap, not a compliance attestation.
