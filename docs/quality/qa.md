# QA

This is a living document. Update it whenever UI scope, Messages behavior, validation lanes, or device expectations change. Do not rely on chat memory for what needs to be tested.

## Practical Gate

These commands should stay green for the current MVP engine baseline:

```bash
bash ./scripts/gen.sh
swift test --package-path Packages/ULS_CoreGame --skip ULS_CoreGameEvals
swift test --package-path Packages/ULS_CoreGame --filter ULS_CoreGameEvals
swift test --package-path Packages/ULS_Transport
xcodebuild -workspace UnluckySevens.xcworkspace -scheme MessagesExtension -destination 'generic/platform=iOS Simulator' build
xcodebuild -workspace UnluckySevens.xcworkspace -scheme UnluckySevens-Workspace -destination 'platform=iOS Simulator,name=iPhone 15' test
```

GitHub Actions mirrors this practical gate in `.github/workflows/ci.yml`.

`ULS_CoreGameEvals` is the deterministic engine eval harness. `ULS_CoreGameTests` remains the normal core test suite.

Run these validation commands serially. Do not run `swift test` or `xcodebuild` in parallel on this repo; the Messages/simulator lane is prone to lock contention and misleading failures when multiple test or build processes overlap.

## When To Run What

- Any `ULS_CoreGame` or `ULS_Transport` change:
  - run the full Practical Gate
- Any `MessagesExtension` shell, layout, presentation, or mode-system change:
  - run the full Practical Gate
  - run the Manual Simulator Runbook smoke pass
  - run the Real Device Shell Smoke checklist
- Any lobby join/start UX change:
  - run the full Practical Gate
  - run the Manual Simulator Runbook smoke pass
  - run the Real Device Lobby Smoke checklist
- Any transcript-selection, bubble, session, or context-handling change:
  - run the full Practical Gate
  - run the Manual Simulator Runbook context check
  - run the Real Device Messages Lifecycle checklist
- Any same-bubble recovery, board responsiveness, or setup-road interaction change:
  - run the full Practical Gate
  - run the Manual Simulator Runbook smoke pass
  - run the Real Device Messages Lifecycle checklist
  - run the Real Device Turn-Taking Smoke checklist
  - run the Real Device UX Hardening checklist
- Any shell-header, action-dock, player-name, bank-tray, or dev-card timing/change-flow update:
  - run the full Practical Gate
  - run the Manual Simulator Runbook smoke pass
  - run the Real Device Turn-Taking Smoke checklist
  - run the Real Device Gameplay Cohesion checklist
- Any new gameplay flow in the product UI:
  - run the full Practical Gate
  - run the relevant targeted simulator check
  - run the relevant real-device gameplay checklist before calling the flow ready
- Before a phase is declared UI-ready:
  - run the full Practical Gate
  - run at least one full two-device smoke pass end to end

## Real Device Lane

Use real devices as the source of truth for Messages-hosted behavior. Simulator remains the fast build and layout loop, but transcript state, bubble selection, context persistence, and general extension stability should be verified on hardware.

Default matrix:

- iPhone on your primary Apple account
- iPad on a separate Apple account
- one real Messages conversation between those two accounts

Treat this matrix as the baseline for async gameplay validation.

### Real Device Shell Smoke

Run this after shell, layout, presentation, or mode-system changes.

1. Install the current development build on both devices. In the current repo shape this may still happen through the minimal containing-app shell, but the intended product surface is the Messages app drawer.
   Recommended local pipeline:
   `bash ./scripts/install-connected-devices.sh`
2. Open Messages and confirm Unlucky Sevens appears in the app drawer on both devices.
3. Open the same conversation between the two accounts.
4. Open an existing canonical `STATE` bubble and confirm the extension requests expanded presentation and the shell renders:
   - header
   - board area
   - handle band
   - action dock
5. Confirm the collapsed lower rail shows only:
   - small centered pull-tab
   - dock row
6. Confirm the persistent dock order stays:
   - `Roll`
   - `End Turn`
   - `Build`
   - `Play Dev`
7. Open the pull-tab and confirm the overlay shelf header exposes:
   - `Hand`
   - `Bank`
   - `Players`
   - close chevron
8. Confirm hand, bank, and player summaries are not always-open cards in the default shell.
9. Confirm `Hand`, `Bank`, and `Players` do not repeat inner titles or subtitles once the shelf is open.
10. Confirm `Hand`, `Bank`, and `Players` do not scroll in the normal case.
11. Confirm the iPhone layout remains readable in compact extension sizing and that the shell continues to fit the visible host bounds while the board stays responsive.
12. Confirm the iPad layout remains readable, does not over-expand low-priority UI, and caps the lower-rail content width instead of stretching hand/bank/player content across the full host width.
13. Verify opponent information is still count-only and does not leak composition.
14. Confirm the shell remains product-focused and no debug UI is required to advance the normal game flow.

### Real Device Lobby Smoke

Run this after any lobby join/start UX change.

1. From device A, send an invite `STATE` into the thread.
2. On device A, select the invite bubble and confirm the extension resolves the lobby from transcript transport rather than falling back to `No Lobby Selected`.
3. On device B, select the same invite bubble and confirm the extension resolves the same invite before joining.
4. From device B, open the invite and join.
5. Confirm joining does not require an extra manual send step after tapping `Join`.
6. From device A (host), confirm the lobby UI reflects both the host and the joined guest before trying to start.
7. Confirm `Start Game` stays unavailable until at least two players appear in the host lobby, then start from device A.
8. From device B, open the start `STATE` and confirm the extension resolves the new setup context cleanly.

### Real Device Messages Lifecycle

Run this after phase-13 stability work or when explicitly validating Messages host behavior. It is no longer a phase-12.7 acceptance gate.

1. Send a new `STATE` bubble from one device.
2. Select that bubble on the other device and confirm it becomes active context.
3. Switch away from Messages and return.
4. Reopen the same bubble and confirm the shell still resolves the correct context.
5. Select an older bubble after a newer one exists and record whether the host keeps you on stale context, upgrades to the latest known state, or fails to recover.
6. Force-close and relaunch Messages, then record whether context can still be recovered from the selected bubble.

### Real Device Turn-Taking Smoke

Run this after any action-flow change that affects turns, trades, robber, or dev cards.

1. From device A, publish or reach a playable `STATE`.
2. Perform one legal action from the acting player.
3. On device B, confirm the new bubble appears and opens cleanly.
4. Continue the turn or respond from the other account when appropriate.
5. Verify status text is correct on both sides:
   - `Your turn`
   - `Waiting on <player>`
   - `Roll pending` before the active player rolls
   - `Roll: <d1> + <d2> = <total>` after the active player rolls
6. Confirm no bubble or context step silently drops during cross-device play.

### Real Device Gameplay Cohesion

Run this before calling phase 12 complete.

1. Open the same active game on both devices and verify the shell uses deterministic aliases such as `SheepGrazer` or `OreMiner` instead of raw participant IDs. The aliases should match on both devices for the same game.
2. On a fresh turn before rolling, confirm the default shell reads as:
   - header
   - board
   - handle band
   - dock
3. Confirm the board does not resize when opening or closing `Hand`, `Bank`, `Players`, `Build`, or `Play Dev`.
4. Confirm the primary dock order is:
   - `Roll`
   - `End Turn`
   - `Build`
   - `Play Dev`
5. Confirm the collapsed lower rail shows only the pull-tab and the dock row; utility cards should not be visible until the pull-tab is opened.
6. Confirm the full island and all ports are visible at default zoom, with a small ocean margin and slightly more water below the island than above. Confirm you can zoom out only slightly beyond default and zoom in much further than the fit overview.
7. Confirm pan, pinch, and board taps remain responsive on first open on both iPhone and iPad; they should not require reloading the game view before working.
8. Drag the Messages host smaller and larger. Confirm the shell freezes against the last settled frame during the drag, ignores interaction while frozen, and reliably recovers after the drag ends without getting stranded in a permanently frozen state if the host jitters.
9. At the normal fully-extended gameplay height, confirm the board remains live and never enters resize-freeze while panning, pinching, or interacting normally.
10. On iPad, open `Hand`, tap a legal setup/build target, then switch between `Hand`, `Bank`, and `Players`. Confirm the lower shelf stays fully visible and tappable and the board does not steal those taps.
11. Confirm the overlay shelf overlaps the board intentionally only at the bottom edge. No utility/header/dock content should collide or wrap into neighboring regions.
12. On both iPhone and iPad, drag on the board, lower shelf, and dock. Confirm those drags stay inside the game surface and do not start resizing the Messages host. Only the narrow top grabber strip should be able to collapse or expand the host.
13. On iPad, with the Messages host at its normal gameplay height, open `Hand`, `Bank`, and `Players`. Confirm the lower shelf uses the compact vertical layout when needed rather than clipping or disabling utility shelves because the width is wide.
13. Open `Build` and verify the shelf only shows legal actions from:
   - `Road`
   - `Settlement`
   - `City`
   - `Buy Dev`
14. Tap the pull-tab, then `Hand`, `Bank`, and `Players`, and confirm only one shelf opens at a time.
15. Close each shelf through both:
   - the close chevron
   - tapping the selected utility tab again
15. Open the `Hand` shelf and confirm trade is entered from there instead of from a persistent dock button.
16. Confirm the `Hand` shelf shows the five resource chips first, with a full-width `Trade` row underneath when trade is currently available.
17. Open the `Bank` shelf and confirm it shows public remaining counts for wood, brick, sheep, wheat, and ore using the same chip sizing and spacing as the `Hand` shelf. Verify it only becomes interactive during Monopoly or Year of Plenty selection.
18. Open the `Players` shelf and confirm each opponent row only shows:
   - alias
   - current-turn indicator
   - public VP
   - public hand count
19. Confirm `Hand`, `Bank`, and `Players` do not add inner titles or subtitles and do not scroll in the normal case except when the host is too constrained to fit the utility body without scrolling.
20. Tap random nodes, edges, and tiles while idle. Confirm nothing highlights or remains selected unless the active mode actually uses that board target class.
21. Open the dev-card panel and confirm the legal actions are choice-driven, not just default labels:
   - Knight
   - Monopoly
   - Year of Plenty
   - Road Building
   Verify each option only appears when legal for the current turn state.
22. Play Knight and confirm the robber moves to the selected tile. If the chosen tile has multiple legal victims, verify the victim selection step becomes explicit; if it has one or zero legal victims, verify the flow resolves without an unnecessary extra picker.
23. Play Monopoly and confirm the chosen resource is the one collected from opponents.
24. Play Year of Plenty and confirm the selected two resources are taken from the bank and added to the player.
25. Play Road Building and confirm the selected two edges are placed without resource cost.
26. If a Victory Point card is present, confirm it is only surfaced when revealing it would immediately win the game.
27. Open the trade panel as proposer and responder. Confirm the compact panel explains accepted, waiting, passive-decline, and execute/end-turn expiry behavior without leaking raw IDs or debug text.
28. Enter setup, build, robber, Knight, and Road Building flows and confirm the in-board hint chip is small, single-line, and shifted above the overlay shelf when the shelf is open.
29. Finish a game-over state or load one from transcript and confirm the shell shows:
   - winner clearly
   - compact final score
   - short last-turn recap
   - no dead bottom tray
30. Open and close `Hand`, `Bank`, `Players`, `Build`, and `Play Dev` repeatedly and confirm the board does not visibly hitch or rebuild while the shelf changes.
31. In setup and build modes, tap one legal target once and confirm nothing publishes yet. Confirm the target highlights, then tap the same selected target again and confirm it publishes.
32. After selecting a setup/build target, tap a different legal target and confirm the selection moves without publishing.
33. On both iPhone and iPad, select a setup/build target while `Hand`, `Bank`, or `Players` is visible and confirm the shelf header tabs remain usable instead of being replaced by a forced-flow panel.
34. Drag down from the top of the Messages transcript to collapse the host while a live game is open, both with the shelf closed and with a shelf open. Confirm the board freezes visually during host drag, ignores board input while frozen, only performs one clean final refit after the host settles, and never stays frozen indefinitely if the host keeps sending noisy size updates.
35. On both iPhone and iPad, confirm the `Hand` and `Bank` shelves keep the same chip sizing and a capped reading width instead of stretching to full host width.
36. In a visibly constrained host height, confirm a utility shelf closes instead of rendering partially offscreen or leaving unreachable content below the viewport.

### Real Device UX Hardening

Run this during phase-12 cleanup or after any change to product authority, board responsiveness, or setup-road interaction.

1. During setup road placement, tap near the just-placed settlement endpoint and confirm the intended legal road can still be selected without hunting for a tiny mid-edge target.
2. Toggle setup, build, and turn overlays several times on both devices and confirm board updates remain responsive rather than visibly rebuilding or hitching.
3. Pan and zoom after those updates and confirm responsiveness does not degrade noticeably on either device.
4. On the non-current device, confirm the shell remains read-only and out-of-turn actions cannot be published.

### Debug-Only Transport Triage

Use this only on the disposable debug branch when a selected transcript bubble does not open context on hardware. It is not part of the clean phase-driven-dev acceptance flow.

1. Open the debug HUD on the affected device after selecting the bubble.
2. Check `Selection` and `Transport Debug` before trying fallback actions.
3. Confirm the selected bubble reports:
   - `message: present`
   - `payloadLength: > 0`
   - `decodeSource: URL`
4. Prefer `url: present` plus `payloadQuery: present`. If they are missing, treat it as a transport publication or host-selection failure rather than a lobby-state bug.
5. During the temporary phase-12 product fallback, `decodeSource: summary fallback` is acceptable evidence that the one-line mirrored summary carrier recovered the payload; capture it as a host-fidelity defect and keep phase 13 responsible for removing that fallback.
6. While the temporary in-app diagnostics slice is active, the gameplay route may expose a `Reload Board` control in the top-right overlay. Use it only as a local recovery/debug aid when host-resize cycles leave the SpriteKit board non-responsive.
7. If lobby `STATE` decodes but `Join Game` is still missing on the receiving device, inspect:
   - `localParticipant`
   - `resolvedActor`
   - `localInRoster`
   - `localPendingJoin`
   - `canJoin`
   - `isInviter`
8. Capture the debug HUD state as the primary repro artifact before retrying with a new bubble or escalating the issue into the stability phase.

## What Is Already Covered Well

- lobby join/start UX, including one-step join and host-owned start
- setup placement UX in the product shell
- the common turn loop and build/buy actions in the product shell
- robber/discard forced-flow handling in the product shell
- trade UX in the product shell, including compact player and maritime trade entry, accept intents, and execute flow
- dev-card UX in the product shell, including compact play actions, pre-roll/post-roll timing, staged bank/board choice flows, and winning-only Victory Point reveal
- setup sequencing and starting resources
- deterministic dice, board generation, dev deck, and robber steal behavior
- production, bank depletion, discard flow, robber flow
- trade proposal / accept / execute / expiry
- maritime trade ratio selection
- dev card timing and effects
- awards and victory gating
- deterministic full-match replay and invariant rejection

## What This Pass Added

- realistic transport stress test for canonical STATE payload budget and roundtrip decode
- shared `ULS_CoreGame` view/query helpers for legal default actions and viewer-scoped secrecy-safe projections
- focused core tests covering the new query/projection surface against reducer legality and secrecy expectations
- transport diagnostics in the debug HUD so selected-message failures show URL, payload, summary, session, and decode-source facts instead of only the empty-state shell
- temporary production one-line summary mirroring plus sender-side cached-state recovery so device triage and phase-12 gameplay can continue when the Messages host drops `message.url` or transiently clears selection on reopen

## Remaining High-Value Gaps

- no automated transcript-level Messages UI checks yet
- snapshot regression substrate exists, but production board and bubble visual assertions are still shallow
- no automated real-device lane; hardware validation is still manual

## Manual Simulator Runbook

Use the current product shell for one smoke pass and three targeted checks. Keep the debug HUD available only as fallback if a branch has not finished a flow yet.

### Smoke Pass

1. Run the Practical Gate commands.
2. Launch the current development build if needed to install the extension, then open Messages in the simulator.
3. In Messages, create or open a thread and launch Unlucky Sevens.
4. Tap `Invite New Game`, then verify a lobby `STATE` bubble appears and the extension decodes it as active context.
5. Tap `Join` from another simulated actor path if available, then `Start Game`.
   - Prefer the product flow. Debug-only steps such as `Record Join` should only be used on older branches or if a stage is still incomplete.
6. Apply setup intents until the game reaches turn phase.
7. Roll once, apply the resulting intent into `STATE`, and verify:
   - rev increments
   - phase is `turn`
   - step becomes `afterRoll` or the correct robber/discard subflow
8. If available, play one legal dev card before rolling and verify the resulting state change appears without leaking hidden card composition to opponents.
9. Confirm the default shell reads as header, board, handle band, and dock rather than stacked hand/bank/player cards.
10. Confirm the board does not resize when opening `Hand`, `Bank`, `Players`, `Build`, or `Play Dev`.
11. Drag the Messages host between expanded and constrained heights and confirm the board world stays visually stable even though the visible viewport changes.
12. Tap the pull-tab, then `Hand`, `Bank`, and `Players`, and confirm only one shelf opens at a time and each shelf can be closed via the chevron or by tapping the selected tab again.
13. Confirm the bank shelf shows public counts for wood, brick, sheep, wheat, and ore, and only becomes interactive during Monopoly or Year of Plenty selection.
14. Roll once, then perform one post-roll action such as build, trade, maritime trade, or dev-card purchase.
15. Open the dev-card panel when legal and verify only legal play/reveal actions are shown there; buy-dev-card should now live under the `Build` shelf instead.
16. Verify `Play Dev` never falls back to default-choice labels for Knight, Monopoly, Year of Plenty, or Road Building. Knight should move through tile choice first and only open a victim choice when the chosen tile has multiple eligible steals; Monopoly should use the bank shelf, Year of Plenty should use first/second bank picks, and Road Building should use first/second road choice.
17. Verify Victory Point reveal stays hidden unless the reveal would immediately win the game.
18. Confirm the only valid overlap is the overlay shelf covering the bottom of the board; handle-band controls, dock controls, and board chrome must not collide or wrap.
19. End the turn and verify:
    - current player advances
    - step resets to `needsRoll`
    - trade offers clear
20. Verify opponent hand and dev-card views show counts only, not composition.
21. Verify the turn header never shows raw debug/context metadata; it should stay limited to ownership plus dice state.

### Targeted Check: Robber / Seven Flow

1. Continue play until a 7 occurs naturally.
2. Verify required discard counts appear only for players with more than 7 cards.
3. Apply discard intents and confirm the engine blocks robber movement until discards complete.
4. Move the robber and confirm the engine only offers eligible victims.
5. Apply steal and verify the turn returns to `afterRoll`.

### Targeted Check: Trade Lifecycle

1. From an `afterRoll` state, open the compact trade modal as the current player.
2. Verify suggested player-trade and maritime-trade actions are visible.
3. Switch acting actor and send one or more accept intents.
4. Switch back to the current player and apply one selected accept into canonical state, then execute with the accepted players.
5. Verify resource transfer is atomic and the offer clears.
6. Repeat a turn where the offer is not executed and confirm `End Turn` expires it.

### Targeted Check: Context / Secrecy Safety

1. Select an older `STATE` bubble after a newer one exists.
2. Record whether the simulator shell resolves to the latest known game state, stays on stale context, or fails to recover.
3. Confirm a non-joined participant remains read-only and only sees count-only hidden-information summaries.
4. Confirm the joined local participant sees only their own hidden detail while opponent information remains count-only.
