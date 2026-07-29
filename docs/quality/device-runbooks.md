# Device and Simulator Runbooks

This guide owns real-device, manual simulator, and host-stability procedures. Use [QA](qa.md) to select the required lane and [constraint verification](constraint-verification.md) to record evidence and completion status.

## Real Device Lane

Use real devices as the source of truth for Messages-hosted behavior. Simulator remains the fast build and layout loop, but transcript state, bubble selection, context persistence, and general extension stability should be verified on hardware.

Default matrix:

- iPhone on your primary Apple account
- iPad on a separate Apple account
- one real Messages conversation between those two accounts

Treat this matrix as the baseline for async gameplay validation.

### Real Device Shell Smoke

Run this after shell, layout, presentation, or mode-system changes.

1. Install the current development build on both devices. The local install pipeline builds the standalone iMessage app bundle; it installs as an app bundle, but the product surface is only the Messages app drawer.
   Recommended local pipeline:
   `bash ./scripts/install-connected-devices.sh`
2. Open Messages and confirm Unlucky Sevens appears in the app drawer on both devices with the temporary `7` icon.
3. Open the same conversation between the two accounts.
4. Open an existing canonical `STATE` bubble and confirm the extension requests expanded presentation and the shell renders:
   - header
   - board area
   - handle band
   - action dock
5. Confirm the collapsed lower rail shows only:
   - small centered pull-tab
   - dock row
   Confirm the pull-tab and close controls have clear accessibility labels for VoiceOver.
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
14. If the thread has recoverable canonical state for one or more games, confirm the compact `Game` / `Games` chip appears in the top-left and opens a recoverable game list without disturbing the normal shell.
15. Confirm the shell remains product-focused and no debug UI is required to advance the normal game flow.

### Real Device Lobby Smoke

Run this after any lobby join/start UX change.

1. From device A, send an invite `STATE` into the thread.
2. On device A, confirm the extension dismisses back to the Messages thread immediately after the invite is sent.
3. On device B, select the invite bubble and confirm the extension resolves the invite before joining.
4. On device B, enter a custom lobby name before joining and then join from the invite bubble.
5. Confirm joining does not require an extra manual send step after tapping `Join`.
6. On device A, reopen the latest lobby bubble in the thread and confirm the lobby UI now reflects both the host and the joined guest. Reopening a real one-player lobby bubble before anyone joins should show the normal interactive lobby.
7. Confirm the joined roster uses the custom lobby name when set and falls back to the deterministic alias when it is not.
8. Update the joined player's name from the reopened lobby and confirm the renamed roster persists after closing and reopening the latest lobby bubble on both devices.
9. Close the extension on both devices, start a fresh lobby from each device in turn, and confirm the local name field prefills from that device's saved preferred lobby name before any new join/rename publish.
10. Confirm `Start Game` stays unavailable until at least two players appear in that reopened host lobby, then start from device A.
11. From device B, open the start `STATE` and confirm the extension resolves the new setup context cleanly.
12. Confirm the fresh invite, join, rename, and start bubbles all use descriptive product copy instead of revision/debug text.
13. Confirm invite, join, and rename bubbles show the production four-seat table with the current roster and open seats.
14. Confirm the start bubble shows the production board without number tokens.
15. On both devices, if the thread now contains more than one recoverable game or stale lobby context, confirm Games on the invitation/loading card opens the correct latest known lobby or game context without requiring transcript hunting.

### Real Device Messages Lifecycle

Run this after phase-13 stability work or when explicitly validating Messages host behavior. It is no longer a phase-12.7 acceptance gate.

1. Send a new `STATE` bubble from one device.
2. Select that bubble on the other device and confirm it becomes active context.
3. Switch away from Messages and return.
4. Reopen the same bubble and confirm the shell still resolves the correct context.
5. Select an older bubble after a newer one exists and record whether the host keeps you on stale context, upgrades to the latest known state, or fails to recover.
6. If the selected bubble is stale or unrelated but the game is known locally, use Games from the invitation/loading card or current-game top bar and confirm the shell restores the latest known canonical state for the intended game.
7. Force-close and relaunch Messages, then record whether context can still be recovered from the selected bubble or the Games destination.

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
6. Confirm fresh turn/setup bubbles use `Unlucky Sevens: <descriptive title>` copy with a short human-readable summary instead of `ULS STATE` or revision text.
7. Confirm setup bubbles show the production board without number tokens, then roll/build/trade/robber/end-turn and game-over bubbles show the current production board with number tokens and pieces.
8. Reopen/select old bubbles and confirm payload still decodes from the URL-backed state, not from image or display text.
9. Confirm no bubble or context step silently drops during cross-device play.

### Real Device Gameplay Cohesion

Run this before calling the current gameplay shell ready for external testers.

1. Open the same active game on both devices and verify the shell uses the lobby-set custom player names when present, otherwise deterministic aliases such as `SheepGrazer` or `OreMiner`. The displayed names should match on both devices for the same game.
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
7. On a freshly started game, confirm the generated board does not place adjacent `6`/`8` number tokens.
8. Confirm pan, pinch, and board taps remain responsive on first open on both iPhone and iPad; they should not require reloading the game view before working.
9. Drag the Messages host smaller and larger. Confirm the shell remains fitted to the visible host bounds during the drag, the board stays interactive at gameplay height, and one settled redraw completes after the host stops moving without requiring manual board reload.
10. At the normal fully-extended gameplay height, confirm the board remains live throughout host drag, panning, pinching, and normal interaction.
11. On iPad, open `Hand`, tap a legal setup/build target, then switch between `Hand`, `Bank`, and `Players`. Confirm the lower shelf stays fully visible and tappable and the board does not steal those taps.
12. Confirm the overlay shelf overlaps the board intentionally only at the bottom edge. No utility/header/dock content should collide or wrap into neighboring regions.
13. On both iPhone and iPad, drag on the board, lower shelf, and dock. Confirm those drags stay inside the game surface and do not start resizing the Messages host. Only the narrow top grabber strip should be able to collapse or expand the host.
14. On iPad, with the Messages host at its normal gameplay height, open `Hand`, `Bank`, and `Players`. Confirm the lower shelf uses the compact vertical layout when needed rather than clipping or disabling utility shelves because the width is wide.
15. Open `Build` and verify the shelf only shows legal actions from:
   - `Road`
   - `Settlement`
   - `City`
   - `Buy Dev`
16. While `Build` is open, tap `Hand`, `Bank`, and `Players` and confirm the shell switches directly to the requested utility shelf instead of forcing a manual build close first.
17. While `Hand`, `Bank`, or `Players` is open, tap `Roll`, `Build`, `Trade`, `Dev Cards`, and `End Turn` as they become legal and confirm the dock buttons stay tappable instead of being blocked by the visible shelf container.
18. Tap the pull-tab, then `Hand`, `Bank`, and `Players`, and confirm only one shelf opens at a time.
19. Close each shelf through both:
   - the close chevron
   - tapping the selected utility tab again
20. Confirm the `Trade` dock action appears only after rolling and opens a dedicated trade panel rather than a `Hand` shelf row.
21. While trade is open, confirm the lower shelf is hidden/disabled and the trade panel fully owns interaction until the draft is sent or cancelled.
22. As proposer, confirm the player-trade composer is vertically stacked as:
   - `You Give`
   - `You Want`
   - `Recipients`
   and that only the recipient section scrolls.
23. Confirm `You Want` shows both the five resource types and the remaining public bank counts.
24. Switch away from trade by opening another peer route and confirm the trade draft is discarded immediately rather than leaving stale shell state behind.
25. Open the `Bank` shelf and confirm it shows public remaining counts for wood, brick, sheep, wheat, and ore using the same chip sizing and spacing as the `Hand` shelf. Verify it only becomes interactive during Monopoly or Year of Plenty selection.
26. Open the `Players` shelf and confirm each opponent row only shows:
   - display name
   - current-turn indicator
   - public VP
   - public hand count
27. Confirm `Hand`, `Bank`, and `Players` do not add inner titles or subtitles and do not scroll in the normal case except when the host is too constrained to fit the utility body without scrolling.
28. Tap random nodes, edges, and tiles while idle. Confirm nothing highlights or remains selected unless the active mode actually uses that board target class.
29. Open the dev-card panel and confirm it renders as visible card inventory rather than a long text list. The owning player should be able to see held dev cards, including Victory Point cards.
30. Confirm only legal dev-card plays are actionable from that card shelf:
   - Knight
   - Monopoly
   - Year of Plenty
   - Road Building
31. Play Knight and confirm the robber moves to the selected tile. If the chosen tile has multiple legal victims, verify the board highlight victim step becomes explicit; if it has one or zero legal victims, verify the flow resolves without an unnecessary extra picker.
32. Play Monopoly and confirm the chosen resource is the one collected from opponents.
33. Play Year of Plenty and confirm the selected two resources are taken from the bank and added to the player.
34. Play Road Building and confirm the selected two edges are placed without resource cost.
35. If a Victory Point card is present, confirm it is visible in the owner card shelf but only becomes revealable when it would immediately win the game.
36. Open the trade panel as proposer and responder. Confirm the compact panel explains accepted, waiting, passive-decline, and end-turn expiry behavior without leaking raw IDs or debug text.
37. Enter setup, build, robber, Knight, and Road Building flows and confirm the in-board hint chip is small, single-line, and shifted above the overlay shelf when the shelf is open.
38. Finish a game-over state or load one from transcript and confirm the shell shows:
   - winner clearly
   - compact final score
   - short last-turn recap
   - no dead bottom tray
39. Open and close `Hand`, `Bank`, `Players`, `Build`, and `Play Dev` repeatedly and confirm the board does not visibly hitch or rebuild while the shelf changes.
40. In setup and build modes, tap one legal target once and confirm nothing publishes yet. Confirm the target highlights, then tap the same selected target again and confirm it publishes.
41. After selecting a setup/build target, tap a different legal target and confirm the selection moves without publishing.
42. On both iPhone and iPad, select a setup/build target while `Hand`, `Bank`, or `Players` is visible and confirm the shelf header tabs remain usable instead of being replaced by a forced-flow panel.
43. Drag down from the top of the Messages transcript to collapse the host while a live game is open, both with the shelf closed and with a shelf open. Confirm the board stays mounted and responsive at gameplay height during the drag, then performs one clean final refit after the host settles without camera jumps or manual reload.
44. On both iPhone and iPad, confirm the `Hand` and `Bank` shelves keep the same chip sizing and a capped reading width instead of stretching to full host width.
45. In a visibly constrained host height, confirm a utility shelf closes instead of rendering partially offscreen or leaving unreachable content below the viewport.

### Real Device UX Hardening

Run this after any change to product authority, board responsiveness, or setup-road interaction.

1. During setup road placement, tap near the just-placed settlement endpoint and confirm the intended legal road can still be selected without hunting for a tiny mid-edge target.
2. Toggle setup, build, and turn overlays several times on both devices and confirm board updates remain responsive rather than visibly rebuilding or hitching.
3. Pan and zoom after those updates and confirm responsiveness does not degrade noticeably on either device.
4. On the non-current device, confirm the shell remains read-only and out-of-turn actions cannot be published.

## What Is Already Covered Well

- lobby join/start UX, including one-step join and host-owned start
- setup placement UX in the product shell
- the common turn loop and build/buy actions in the product shell
- robber/discard forced-flow handling in the product shell
- trade UX in the product shell, including self-contained player trade, maritime quick-trade options, and responder actions
- dev-card UX in the product shell, including compact play actions, pre-roll/post-roll timing, staged bank/board choice flows, and winning-only Victory Point reveal
- setup sequencing and starting resources
- deterministic dice, board generation, dev deck, and robber steal behavior
- production, bank depletion, discard flow, robber flow
- trade proposal / accept / expiry
- maritime trade ratio selection
- dev card timing and effects
- awards and victory gating
- deterministic full-match replay and invariant rejection

## What This Pass Added

- realistic transport stress test for canonical STATE payload budget and roundtrip decode
- shared `ULS_CoreGame` view/query helpers for legal default actions and viewer-scoped secrecy-safe projections
- focused core tests covering the new query/projection surface against reducer legality and secrecy expectations
- sender-side compact canonical STATE transport plus sender-side cached-state recovery on top of URL-only publication

## Remaining High-Value Gaps

- no automated transcript-level Messages UI checks yet
- bubble image assertions are still size/non-empty checks rather than golden image diffs
- no automated real-device lane; hardware validation is still manual

## Manual Simulator Runbook

Use the current product shell for one smoke pass and three targeted checks.

### Smoke Pass

1. Run the Practical Gate commands.
2. Launch the current development build if needed to install the extension, then open Messages in the simulator.
3. In Messages, create or open a thread and launch Unlucky Sevens.
4. Tap `Invite Players`, then verify a lobby `STATE` bubble appears and the extension decodes it as active context.
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
3. Submit explicit discard selections and confirm the engine blocks robber movement until all required discards complete.
4. In a multi-player discard turn, verify only the next pending discarder can submit. After the first discard publishes, confirm the next required player becomes active on the latest state and an older bubble does not allow an out-of-order discard publish.
5. Move the robber and confirm the engine only offers eligible victims.
6. Apply steal and verify the turn returns to `afterRoll`.

### Targeted Check: Trade Lifecycle

1. From an `afterRoll` state, open the compact trade modal as the current player.
2. Verify `Player Trade` opens a self-contained composer with `You Give`, `You Want`, and `Recipients`.
3. Verify `Maritime / Bank Trade` opens a quick-trade list of legal options rather than a manual composer.
4. Switch acting actor and accept the offer from a targeted responder device.
5. Confirm the accepting device immediately publishes the resolved canonical trade state and that the updated state is visible to the table without a second commit step.
6. Verify resource transfer is atomic and the offer clears.
7. Repeat with decline or counter and confirm those responses also publish canonical state immediately from the responder device without a manual "apply selected response" step.
8. Repeat a turn where the offer is not executed and confirm `End Turn` expires it.

### Targeted Check: Context / Secrecy Safety

1. Select an older `STATE` bubble after a newer one exists.
2. Record whether the simulator shell resolves to the latest known game state, stays on stale context, or fails to recover.
3. Confirm a non-joined participant remains read-only and only sees count-only hidden-information summaries.
4. Confirm the joined local participant sees only their own hidden detail while opponent information remains count-only.

## Host-Stability Regression Checklist

These were the highest-signal device checks from the host-stability phase. Reuse them when transcript recovery, stale-bubble reopen, or cross-device host behavior looks suspect again.

1. Two-device join:
   - keep the inviter bubble open
   - accept/join from the second device
   - confirm the inviter shell updates through canonical lobby-state progression without raw join-intent UI
2. Two-device trade response:
   - proposer creates a targeted trade
   - responder accepts, declines, and counters in separate runs
   - confirm the proposer shell auto-recovers the right game state when the response bubble is surfaced and does not require manual “intent bookkeeping”
   - confirm clicking a surfaced response bubble does not replace the live game with raw response UI
3. Stale bubble reopen:
   - create a newer canonical `STATE`
   - reopen an older bubble for the same game
   - confirm the app prefers the latest recovered state for that game
4. Games recovery:
   - with no useful selected state bubble open, use Games from the invitation/loading card; while a game is open, use Games from its top bar
   - confirm the latest known canonical state for the intended game reopens correctly
   - confirm Active and Finished grouping, unchanged `Game Restored` resend, and device-local archive
   - confirm publish actions are unavailable when the current Messages participant set is incompatible with the saved roster
   - after archive, tap a later valid bubble and confirm the game returns to the local list
5. Resignation, draw, and host end:
   - resign once as the current player and once as a waiting player
   - confirm both devices keep the same active roster order, skip the resigned player, preserve their inert pieces, and agree on returned hand/development-card retirement
   - propose a draw, reject it once, then propose again and approve unanimously; confirm both devices show the same neutral result and final scores
   - as the original host, verify the draw-first soft guard and then `End Game Anyway`; repeat after the host resigns and confirm host authority remains
   - confirm host-end and draw results declare no winner and reject later gameplay actions
   - use New Game from victory, agreed draw, and host-end results and confirm it returns to a fresh unsent invitation
6. Session restart experiment:
   - while a same-game session is live, securely archive the `MSSession`, force-close the extension, restore it, and publish from the restored canonical state
   - retain session persistence only if two devices show replacement/collapse on the original game bubble; otherwise confirm the product creates a deliberate fresh `Game Restored` bubble
7. Full standard-match pass:
   - run a complete real-device match from lobby through victory
   - verify setup, roll/production, trade, dev cards, robber/discard, end-turn progression, and winner-state summary on the corrected substrate
8. If any of the above fail, capture:
   - exact transcript bubble selected
   - whether a newer bubble existed
   - whether the active-games chip was available
   - screenshots of the visible shell state
