# Game Information and Lifecycle Polish

> Closed 2026-08-26 as superseded product direction. Player Record is now read-only, gameplay resumes from a real Messages bubble, and lifecycle actions belong to the current bubble-bound game's Game Information panel. The pending proof for the retired Your Games composition is not current work.

> Superseded 2026-08-23 for current product behavior: the completed Players/Your Games checkpoint remains historical evidence, but production now uses a read-only Player Record and keeps lifecycle actions on the current bubble-bound game's Game Information panel. See `first-friends-testflight-release.md` TFR-017/019/020.

## Purpose and Outcome

Make Players and Games feel like one coherent in-place switcher, make the dedicated Games library read as one native screen, and present lifecycle confirmations in the same centered tabletop-overlay family without changing recovery or game-end semantics.

## Execution Settings

- Validation profile: `standard`
- Delivery posture: `direct`
- Rationale: The user explicitly selected the established Players/Trade overlay treatment for both lifecycle confirmations; the behavior and actions remain fixed.

## Context and Boundaries

- [UI flows](../../product-specs/ui-flows.md) owns the Game Information, recovery, resignation, and host-end journeys.
- [Design](../../../DESIGN.md) and [decisions](../../decisions.md) own the approved visual composition and lifecycle behavior.
- `ULS_CoreGame` and `ULS_Transport` are unaffected. Existing resignation, draw, host-end, recovery, and publication semantics must remain unchanged.
- Board number typography and all unrelated type treatments remain locked.

## Milestones / Plan of Work

1. Lighten the Game Information overlay and make Players/Games use symmetric people/die controls with no unexplained ellipsis.
2. Center the Your Games title independently of its Back and count controls and use the shared tabletop-overlay treatment for resignation and host end.
3. Update focused XCUITest journeys, owner docs, inspect simulator captures, obtain fresh review, and run the standard completion gate.

## Verification Contract and Fresh Review

<!-- verification-contract:start -->
| ID | Class | Source | Acceptance | Verification | Evidence | Status | Rationale |
| --- | --- | --- | --- | --- | --- | --- | --- |
| GIL-001 | observable | user request | Players and Games replace one another in the same fixed panel using consistent people/die language, with no unexplained ellipsis action | focused Messages XCUITest and screenshot inspection | `testCaptureCityTargetAndGameInfoRegression` passed in `/private/tmp/UnluckySevensGameInfoHeaderFinal20260804.xcresult`; retained Players and inline Games captures | pass | Fixed panel frame, symmetric people/die switch, and no header ellipsis are device-proven |
| GIL-002 | judgment | latest user request | Players and Games use the centered Trade-composer treatment: translucent felt panel, gold keyline, and a dimmed but stationary game surface behind it | focused Messages XCUITest plus screenshot inspection from an explicitly installed fresh app bundle | passing `/private/tmp/UnluckySevensGameInfoRegression20260805.xcresult`; `output/game-info-regression-2026-08-05/screens/` | pass | User accepted the direction; the corrected panel shows complete rows/recap and swaps to Games without changing its frame |
| GIL-003 | observable | user request | Your Games is visually centered while Back and the saved-game count remain aligned navigation utilities | focused Messages XCUITest and screenshot inspection | `testRecoveryGamesLibraryUsesDedicatedSurface` passed in `/private/tmp/UnluckySevensLibraryCenteredFinal20260804.xcresult`; retained library capture | pass | Midpoint assertion and visual inspection both confirm independent centering |
| GIL-004 | observable | latest user request and UI flow contract | Resign and host-end choices use centered Players/Trade-style felt confirmations while preserving explicit safe cancellation, draw-first, destructive action, and continuation/end behavior | focused Messages XCUITest journeys plus screenshot inspection | focused resignation and host-end captures | pending | Prior native-dialog evidence is superseded; the updated journeys target the shared lifecycle overlay and explicit Keep Playing action |
| GIL-005 | mechanical | established UI contract | Revised controls use shared typography, semantic accessibility names, and 44-point interactive targets | source inspection, harness audit, and XCUITest assertions | passing `testCaptureCityTargetAndGameInfoRegression` on 2026-08-05, including the centered Your Games target assertion | pass | Shared GameTheme/system text styles remain intact; the real Your Games label/hit region now measures at least 44 points |
| GIL-006 | mechanical | AGENTS.md | Canonical generation, doc freshness, and the standard completion gate pass | prescribed repository commands | pending | pending | Awaiting final validation |
| GIL-007 | judgment | user request | Preserve the existing water frame and board scale on every route, move only the island enough to center it optically in the water, and dim the stationary game behind Players/Games like Trade | unobstructed/Players/Games simulator screenshots plus user approval | passing `/private/tmp/UnluckySevensGameInfoRegression20260805.xcresult`; retained Players/Games/city frames in `output/game-info-regression-2026-08-05/screens/` | pass | User accepted Players/Your Games; current screenshots and geometry assertions preserve the stationary board/water frame behind both modes |
<!-- verification-contract:end -->

<!-- fresh-review:start -->
| Reviewer | Required | Verdict | Evidence |
| --- | --- | --- | --- |
| constraint-auditor | yes | pending | initial FAIL was evidence-only and is superseded by fresh device proof; re-review pending |
| architecture | no | not-applicable | no module, protocol, or ownership-boundary changes |
| behavioral | yes | pending | re-review requested with independent cancel, draw, and end journey evidence |
| product-ux | yes | pass | fresh review found no blockers across source and retained library/dialog captures |
<!-- fresh-review:end -->

## Living Record

### Progress

- 2026-08-03: Locked `standard` validation and `direct` delivery before implementation.
- 2026-08-03: Initial focused proof exposed a stale Messages extension process. Fresh-build proof then showed that Your Games rows inside or beside the compact scroll region either clipped or lost the gesture to the game shell's lower transparent layout layer. The Games-mode die header now becomes the explicit Your Games destination in the proven interactive header zone.
- 2026-08-04: Focused device journeys now pass for the in-place Players/Games panel, centered library, resignation safe cancellation, draw proposal, and unilateral host end. Harness audit, doc freshness, and diff checks pass; fresh behavioral and constraint re-reviews remain before the completion gate.
- 2026-08-04: Pixel comparison proved all opacity/backing captures were identical. Two bounded compositor reruns then proved that neither a flattened SwiftUI layer nor a UIKit subview can cover the final `SKView` pass. The production correction now computes the exact board/panel overlap and draws that opaque region as a camera-anchored SpriteKit node; visual proof remains pending because the locked rerun budget was exhausted.
- 2026-08-04: The renderer-level correction passes the generic Messages simulator build and focused `GameBoardSceneTests/testGameInfoOcclusionIsAuthoredInsideSpriteKitViewport`. `make doc-freshness` and `git diff --check` pass. No third screenshot rerun was taken.
- 2026-08-04: User explicitly requested a new screenshot proof. The fresh focused journey passed, but the inspected Players capture still shows board imagery across the panel header. GIL-002 returns to failed; the next diagnosis must inspect the runtime overlap coordinate/value rather than attempt another compositor layer.
- 2026-08-04: Executable hashes proved that `test-without-building` had preserved an older installed Messages extension even after the build products changed. After explicitly installing the matching standalone app, the dedicated Game Information route and updated accessibility contract passed in `/private/tmp/UnluckySevensGameInfoDedicatedScreen20260804ak.xcresult`; inspected Players and Games captures are fully opaque.
- 2026-08-05: User rejected the dedicated surface because it removed the map. Restored the normal game hierarchy, retained the live map outside the panel, and moved the opaque overlap backing into the board host. Players and Games captures are visually correct. The contracted journey reached both captures but failed afterward because the Close query selected a retained label proxy; the harness now selects the real `xmark` button, with no further rerun taken after the circuit-breaker limit.
- 2026-08-05: User requested a new bounded visual iteration at 0.95 panel opacity and the complete three-capture focused set. Preserve the map and board-host overlap backing; rerun the corrected Close selector once as a new user-authorized visual round.
- 2026-08-05: Captured the complete 0.95 set in `/private/tmp/UnluckySevensGameInfoOpacity095RendererControlled20260805.xcresult` and retained map, Players, and Games images. The visual blend remains stronger than a literal five-percent reveal because of the Messages SpriteKit/SwiftUI composition. The journey again failed only after capture: the native hierarchy exposed the Close glyph as a 13-point target. The production button now has an explicit 44-point content shape and stable `uls.gameInfo.close` accessibility element; compile proof follows, with no third visual rerun.
- 2026-08-05: The board-centering checkpoint used two bounded real-device rounds. Round one proved a post-layout translation was cancelled by the existing self-centering feedback and that a SwiftUI-only veil could not uniformly dim SpriteKit. Round two retained unobstructed, Players, and Games captures in `/private/tmp/UnluckySevensBoardCenterCheckpoint20260805c.xcresult`; it proves the fixed-size in-place switcher direction, but visual inspection fails the gate because the island is still low and the panel still reveals board imagery. The journey failed only after all three attachments on the retained Close selector. No completion gate or further productionization is permitted before user review and a revised rendering approach.
- 2026-08-05: User clarified that the desired reference is the centered translucent Trade composer, not the existing bottom Game Information panel. Game Information now uses the same centered 346-point felt surface, gold keyline, shadow, and full-table focus treatment; Players and Games replace one another without moving the panel. The board centering measurement subtracts its current presentation offset before solving the correction, preventing the feedback loop that previously cancelled the move. A fresh explicit app install produced the retained centered-board and live Players/Games screenshots. The focused harness stopped before its named Players attachment on a 0.08-point containment edge, exposing a small remaining recap-height correction; no completion claim is made.
- 2026-08-05: User accepted the Players/Your Games direction. The recap-height correction, stable close selector, centered geometry assertions, occluded-live-board assertion, and 44-point Your Games header target now pass together in `testCaptureCityTargetAndGameInfoRegression`; final readable captures are retained in `output/game-info-regression-2026-08-05/screens/`.
- 2026-08-09: User explicitly replaced the native-dialog direction for resignation and host end with the established Players/Trade overlay family. Production now uses one shared centered lifecycle panel; focused device proof remains pending.

### Decisions

- 2026-08-03: Keep full lifecycle management as progressive disclosure from the inline Games list, but expose it as a labeled Your Games destination instead of an unexplained header ellipsis.
- 2026-08-03: Use native confirmation dialogs for resignation and host end; preserve every existing action and view-model transition.
- 2026-08-04: The compact Messages host follows the native popover convention and suppresses a visible cancel-role row. Safe cancellation remains the system tap-outside gesture and is covered as an unchanged-state journey.
- 2026-08-09: Supersede the native-popover decisions above. Both lifecycle confirmations use a centered felt panel, focus veil, gold keyline, explicit `Keep Playing`, and a distinct destructive action; host end retains draw-first behavior.
- 2026-08-04: Increase Game Information panel opacity from 0.54 to 0.68 as a middle treatment between the rejected transparent result and the earlier heavier panel. Validation is limited to the existing focused Game Information journey and one Players screenshot.
- 2026-08-04: User explicitly selected 0.80 opacity after reviewing the 0.68 device capture; make no adjacent layout or typography changes and reuse the same focused proof path once.
- 2026-08-04: User selected 0.95 opacity after reviewing the 0.80 device capture; keep the change isolated and reuse the same focused proof path once.
- 2026-08-04: User requested removal of transparency after reviewing the 0.95 device capture; use the solid theme surface directly and reuse the same focused proof path once.
- 2026-08-04: The first fully opaque capture showed board imagery still visible across the header because the externally allocated panel frame was not itself backed; add a solid backing at the GameShell frame boundary without changing layout, content, or typography.
- 2026-08-04: The outer background confirmation still showed board bleed-through, proving the renderer composites above SwiftUI background layers. Move the solid fill into the panel ZStack so it shares the same foreground compositing plane as the already-correct header and rows.
- 2026-08-04: User explicitly requested fixing the render ordering. Elevate Game Info from the board-adjacent layer to the modal-surface layer (`6`/`6.1` for visible content/accessibility proxy), still below tutorial chrome at `10`, without changing panel layout or content.
- 2026-08-04: The elevated-layer capture proved `zIndex` does not reorder the embedded `SKView` against SwiftUI fills. Restore the existing overlay layer values and conditionally crop the physical board mask by the Game Info surface height while the route is open.
- 2026-08-04: The SwiftUI mask also cannot clip the embedded `SKView`. Revert it and use a native opaque, non-interactive rounded backing view inside Game Info so the panel and board share the UIKit compositing boundary.
- 2026-08-04: Pixel sampling of the final capture proved the backing did not occupy the header region; the `UIViewRepresentable` lacked an expanding frame. Force it to fill the ZStack. Do not silently take another screenshot after exhausting the locked rerun budget.
- 2026-08-04: Source membership and a fresh build ruled out a legacy or stale component. The apparent transparency is cross-renderer composition: `SKView` overdraws shell fills while SwiftUI labels remain visible. Keep the panel's own solid fill, calculate only its overlap with the board viewport, and author that overlap inside `GameBoardScene` above all board content.
- 2026-08-04: Replace the complete game hierarchy while Game Information is open. A dedicated opaque surface avoids cross-renderer overlap entirely while preserving the fixed in-place Players/Games switch and close action.
- 2026-08-05: Supersede the dedicated-surface decision. Keep the map rendered and visible, disable board hit testing while Game Information is open, and cover only the board/panel intersection inside the board host so panel content stays opaque and interactive.

### Discoveries

- The inline switcher used a stacked-squares Games symbol while the lobby had already established a die, and added a fourth ellipsis control only in Games mode.
- Host end used a custom medium/large sheet. Resignation used the older centered `Alert` API, which dominates the compact Messages host despite being system-rendered.

## Validation and Outcome

The centered Players/Your Games checkpoint is implemented and device-proven. Repository-wide standard completion validation remains tracked separately from this user-facing screenshot handoff.

2026-08-09 lifecycle-overlay extension passed canonical generation and the generic Messages simulator build. Focused resignation/host-end device screenshots and behavior journeys remain pending under GIL-004.
