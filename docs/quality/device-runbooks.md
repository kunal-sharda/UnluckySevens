# Device and Simulator Runbooks

This guide owns real-device, manual simulator, and host-stability procedures. Use [QA](qa.md) to select the required lane and [constraint verification](constraint-verification.md) to record evidence and completion status.

## Streaming Patch Test Routes

Use two routes with separate verdicts for each candidate. The runner below orchestrates local checks and records operator-assisted hardware evidence. It does not schedule jobs. Existing catalogs and locked retry budgets remain governed by [QA](qa.md).

| Route | Setup | Available execution | What a pass establishes |
| --- | --- | --- | --- |
| One-device | Mac/simulator; optionally the home iPad | Existing Core/Transport tests and simulator XCUITest catalogs; automated configured iPad probe/invite/inspect/reopen; manual other physical checks | Deterministic rules and local UI/wiring; physical host behavior only for checks actually performed on the iPad |
| Two-device | Home iPad plus a second iPad/iPhone on a different iMessage Apple account | Operator-assisted real Messages journey; second device may be remote via TestFlight | Observed sender-to-recipient delivery/open/reply and state agreement for the exact tested journey |

### Route 1: One-device validation

1. Identify the candidate commit plus local changes, configuration, version/build, and intended ticket scope. Do not assume installed Build 1.0 (8) contains later local fixes.
2. Run the focused Core/Transport checks selected by QA and the relevant `make test-quick FEATURE=<feature>` simulator route. `make test-full` remains a simulator lane, not a physical iPad or multiplayer verdict.
3. When the home iPad is available, install the identified candidate through the existing connected-device pipeline for development testing, or install the distributed candidate through TestFlight. On that device, check applicable production entry, layout, controls, and reopen behavior. Use the proven physical driver below for its bounded probe/invite/inspect/reopen steps; other hardware journeys remain manual until automated.
4. Use valid existing states or supported DEBUG fixtures for local gameplay scenarios. Simulated actors or seeded multiplayer states do not establish real remote delivery, nor authorize starting a standard game with an unsupported player count. DEBUG UX Lab routes cannot be assumed available in TestFlight.
5. Record one-device pass/fail and mark required cross-account checks pending. Continue independent development while waiting for a second participant; do not close delivery/convergence constraints from this route alone.

### Route 2: Two-device Messages validation

1. Confirm the two devices use distinct iMessage Apple accounts and can exchange real Messages in a dedicated test conversation. Different hardware models or physical locations are not required.
2. Verify the intended candidate is installed on both devices. Record each version/build, OS, configuration/distribution source, and anonymous account role. A development install must not be mislabeled as installed-TestFlight evidence; mixed-build tests are explicit compatibility cases.
3. Run the initial bounded smoke: A publishes an invite; B observes and opens the actual bubble, joins; A observes and reopens the resulting update; compare game/revision and roster using available privacy-safe evidence. This lobby check does not require or authorize starting a two-player standard match.
4. Extend only to the ticket's approved journey: valid-game trade response, session reopen, resign/draw, or recovery. Record sender handoff and recipient receipt/open separately. Missing or unavailable diagnostics remain unverified, not inferred from a screenshot.
5. For a remote phone/iPad, the user performs its taps manually and shares the result; TestFlight distributes builds but does not provide remote control. The home side uses the bounded physical driver below; other actions remain manual. Both devices need internet for the live exchange, not the same Wi-Fi or a USB connection to each other.
6. With both devices local and available to the Mac, a future scoped XCUITest feasibility slice may automate invite/join/reopen. Pairing, trust, signing, Developer Mode, device locks, system prompts, and coordination must be tested before unattended runs are claimed. Current simulator scripts are not a drop-in physical-device runner.
7. Record an independent two-device verdict and link exact evidence to #2/#7/#11/#15/#43 and #8 as applicable. Do not overwrite one-device results or reuse another build's proof without establishing applicability.

### Start at home

```bash
make test-home
```

This runs only a bounded installed-app query for the configured home device, using private `output/physical-messages/home.json`. Override with `HOME_DEVICE_CONFIG=<private-path>` if needed. It never builds, installs, opens Messages or sends. A pass confirms device/app query availability and records installed version/build; it does not prove the device is unlocked, UI-ready, correctly signed for a new install, on the intended candidate, or installed through TestFlight. Inspect the private report before choosing the next step.

Then use the existing physical driver below: probe once for a new candidate, explicitly authorized invite, human phone receive/join, inspect, exact host reopen. Continuations preserve the installed game. Compare independently saved reports with the [report tool](reliability-reports.md#offline-comparison). The phone is a human checkpoint, not an automated device. Fully unattended second-device work is deferred; all three-/four-account product checks remain required later with friends.

### Executable route commands

Existing local tests remain `make test-quick FEATURE=smoke`, `make test-full`, and `make practical-gate`, selected by QA. There is no separate one-device wrapper. The physical driver below does not add gameplay coverage to these suites.

#### Physical driver: first hardware proof

`scripts/run-physical-messages.py` implements `probe` (open the exact conversation, hide DEBUG chrome without loading fixtures, and require a ready production invite control), `invite` (tap that control once), `inspect` (capture visible game-link labels without tapping), and `reopen` (select an exact joined-game bubble after a human phone join). Physical probe, invite, and a remote-human joined-bubble host reopen have passing development-build evidence, including one cold-reopen repeat with identical home game/revision/hash. Repeated unattended runs and installed-TestFlight automation remain separate unproven capabilities.

Create a private JSON file under ignored `output/physical-messages/` with these four strings:

```json
{
  "device": "EXACT-PHYSICAL-DEVICE-UDID",
  "team": "DEVELOPMENT-TEAM-ID",
  "conversation_row": "Exact dedicated conversation row text",
  "conversation_header": "Exact dedicated conversation header button label"
}
```

Use a dedicated test contact/conversation whose displayed header is unique; do not reuse a display name shared by personal contacts. These selectors must be observed on the device. The driver can open an exact visible row or accept an already-open matching header. Unexpected navigation, app entries still hidden after the bounded menu search, ambiguous selectors, onboarding, and disabled controls stop the test for inspection. It does not scroll through arbitrary chats or tap fallback coordinates. Configure the player's display name beforehand if required by the production lobby.

```bash
# Read-only device/app query; no build, install or UI action.
python3 scripts/run-physical-messages.py --config output/physical-messages/home.json --step preflight --execute
# Preview only; no device actions.
python3 scripts/run-physical-messages.py --config output/physical-messages/home.json --step probe
# Install the development candidate on ONLY the configured device, then probe.
python3 scripts/run-physical-messages.py --config output/physical-messages/home.json --step probe --execute --allow-development-install
# After the probe is proven, authorize one invite to the dedicated test contact.
python3 scripts/run-physical-messages.py --config output/physical-messages/home.json --step invite --execute --allow-development-install --allow-send
```

The physical device must be paired, trusted, available and unlocked, with Developer Mode/signing ready. The development install can replace TestFlight. The runner performs read-only preflight first, uses canonical project generation, builds the UI runner, installs to the explicit device, restarts Messages to avoid retaining its old extension panel, and runs one selected XCTest serially without automatic retries. An exclusive runner lock prevents two physical runs overlapping. Keep other repo builds/tests stopped during execution.

Private logs, built app identity/hash, xcresult, summary and screenshots live under `output/physical-messages/`. Zero/skipped/wrong tests cannot produce success. `probe-passed` proves only the observed local UI checkpoint. `invite-control-tapped` does not prove send completion or remote receipt; both receipt and canonical agreement remain explicitly unverified. Inspect failure evidence before a bounded retry. No two-player standard match is started.

On iPad, the probe first dismisses a leftover single app-menu popover through its exact unique dismissal control before checking the conversation header. It can then search for the exact game entry with at most three upward swipes inside a unique app-menu popover collection. It never scrolls the transcript or conversation list to find an app. Missing or ambiguous menu structure stops the probe. This bounded drawer correction has passing physical probe evidence.

After the invite, wait for the human phone participant to confirm receipt/open/join. Run `--step inspect --resume-invite output/physical-messages/INVITE-RUN --remote-joined --execute --allow-development-install` with the same config to capture visible game-link labels without selecting one. Resume with the full observed accessibility link label (including its image suffix):

```bash
python3 scripts/run-physical-messages.py --config output/physical-messages/home.json --step reopen --resume-invite output/physical-messages/INVITE-RUN --join-bubble-label 'EXACT JOINED-BUBBLE ACCESSIBILITY LABEL' --remote-joined --execute --allow-development-install
```

When inspected screenshots show multiple visible links with the same label, explicitly supply `--join-bubble-occurrence N --join-bubble-count C` (one-based top-to-bottom position and exact visible count). The default remains one unique visible match. Selection requires the expected count and non-overlapping vertical frames and captures the screen before tapping. A changed/ambiguous layout stops; there is no automatic latest-message fallback.

Continuation rejects failed invite predecessors, a different home device, a missing or changed retained invite executable, changed installation identity, missing operator confirmation, and ambiguous/missing bubble selectors. Legacy invite reports without installation identity require a fresh invite. Probe/invite install the game once and record its installation URL/version/build and extension hash. Inspect/reopen preserve that game installation, verify the recorded identity and retained executable hash, and install only the newly compiled test runner. All steps use xctestrun destination-artifact mode to prevent implicit game reinstallation. This matters because Apple documents participant identifier changes when the containing app is removed/reinstalled. It does not resend or start a game. A passing home reopen must restore the inviter as host (`Waiting for Players`, no `Join Game`) and records decoded lobby game/revision/phase/hash and a screenshot; phone evidence remains operator-observed and cross-device canonical equality remains unverified without phone diagnostics. Version/build matching alone does not prove source or distribution equivalence, especially against an older TestFlight phone build. Second-device automation and unattended repeatability are deferred beyond #49 and Beta 1.1; the supported home-side flow retains explicit human phone checkpoints.

#### Manual evidence collection

The earlier recorder is retained as `scripts/manual-device-evidence.py`; it never drives devices. Its existing sessions remain readable under `output/testing-streams/`.

```bash
python3 scripts/manual-device-evidence.py two --version 1.0 --build 8 --source 673813f --mode remote-testflight --separate-accounts
python3 scripts/manual-device-evidence.py report --session output/testing-streams/SESSION
python3 scripts/manual-device-evidence.py preflight --device DEVICE_ID
```

Use the actual candidate identity; Build 8 above is only the previously shipped example. Follow generated `instructions.md` and observation templates for the manual invite/receive/join/reopen journey. Supply separate account confirmation, actual version/build and OS, and retained evidence. Missing canonical diagnostics remain null/pending. The remote-TestFlight mode requires both observations from TestFlight. Reports are operator evidence, not automated cross-device proof. Old generated instructions mentioning `testing-streams.py` should use `manual-device-evidence.py` instead; retained evidence files need no migration.

Focused tooling checks: `python3 -m unittest discover -s scripts/tests -p 'test_physical_messages.py'` and the equivalent `test_manual_device_evidence.py`. These test runner behavior, not the game or hardware UI.

### Remaining concurrency and distribution boundaries

- #4 concurrent joins needs host plus two guests; #6 competing accepts needs proposer plus two recipients. Both require three real player accounts/devices for their contracted end-to-end proof. Two-device testing and synthetic branch injection are useful but cannot replace that evidence.
- Local validation can progress independently. A candidate may be offered for explicitly scoped diagnostic playtesting, but pending remote proof cannot be described as a verified multiplayer fix or satisfy a required release gate.
- Physical automation is not implemented by defining these routes. #2 owns host automation/coverage work; #8 owns integrated TestFlight evidence; #44 owns reusable release-available diagnostics. Do not duplicate those tasks with a second test program.
- Some older checklists below retain retired Games/recovery UI and historical player-count assumptions. They are not current product authority. For new route scripts, resolve actions against current UI-flow/decision docs and the selected active plan; do not restore retired controls or weaken current player-count rules to make a historical checklist pass.

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
7. Force-close and relaunch Messages, then record whether the selected game bubble re-establishes context and Player Record remains read-only.

For host-boundary issue closure, retain one operator report for both devices and record these fields at each select, receive, reopen, and relaunch checkpoint:

- device/account role and the participant identity shown by the game;
- selected game ID and revision, payload source (`URL` is expected), and whether the message/session are present;
- lifecycle trigger (`didSelect`, `didReceive`, reopen, or relaunch) and resulting active-context source;
- whether the update replaces/collapses into the same game thread or starts a separate transcript chain;
- any private recovery guidance shown when the selected bubble/session cannot authorize publication.

Then exercise the current game's **Players and game information** → **Current game actions** route rather than Player Record:

1. During setup, confirm the host and non-host can open Propose Draw and Resign; confirm only the original host can open End Game.
2. Cancel Resign and host End Game once each and confirm no canonical revision is published.
3. Propose a draw, then confirm the other active account can Agree and Decline from the live vote state.
4. Publish one resignation and confirm the transcript receipt says play continues and the next legal setup/turn actor remains playable.
5. Exercise the host draw-first guard, then publish End Game Anyway and confirm the neutral terminal receipt/result has no winner.
6. Close/reopen the latest bubble after each published action and confirm the same game session remains the transcript chain.

Screenshots may document the player-facing route, but the report must also record the selected/recovered game revision and same-session transcript observation. Simulator UX Lab proof does not substitute for these hardware checks.

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

- simulator transcript/UI harnesses exist; automated cross-account physical Messages proof is not established
- bubble image assertions are still size/non-empty checks rather than golden image diffs
- bounded iPad probe/invite/inspect/reopen automation exists; broader physical gameplay and remote phone taps remain manual

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
4. Player Record and bubble-only continuation:
   - with no useful selected game bubble open, open Player Record from the invitation/loading card; while a game is open, open it from Game Information
   - confirm Overall and With This Group show read-only local records and accurate completed/win/draw/resignation/best-score values
   - confirm With This Group includes only exact roster matches and discloses that it is player-set based rather than a stable chat identifier
   - confirm no record can open, reconnect, resend, archive, resign, draw, host-end, or publish a game
   - tap a real game bubble and confirm that game resumes and receives newer same-game updates while another game's updates remain ledger-only
5. Resignation, draw, and host end:
   - resign once as the current player and once as a waiting player
   - confirm both devices keep the same active roster order, skip the resigned player, preserve their inert pieces, and agree on returned hand/development-card retirement
   - propose a draw, reject it once, then propose again and approve unanimously; confirm both devices show the same neutral result and final scores
   - as the original host, verify the draw-first soft guard and then `End Game Anyway`; repeat after the host resigns and confirm host authority remains
   - confirm host-end and draw results declare no winner and reject later gameplay actions
   - use New Game from victory, agreed draw, and host-end results and confirm it returns to a fresh unsent invitation
6. Session restart:
   - while a same-game session is live, force-close the extension and reopen the real game bubble
   - confirm the selected bubble re-establishes the game/session and accepts a new canonical action
   - confirm opening Player Record after restart never creates a fresh game chain
7. Full standard-match pass:
   - run a complete real-device match from lobby through victory
   - verify setup, roll/production, trade, dev cards, robber/discard, end-turn progression, and winner-state summary on the corrected substrate
8. If any of the above fail, capture:
   - exact transcript bubble selected
   - whether a newer bubble existed
   - whether the active-games chip was available
   - screenshots of the visible shell state

## Beta 1.1 repair candidate: human checks

Use one identified candidate on every participant. The two-device checks use the USB iPad plus the independently signed-in phone; friends are only needed for competing multi-person actions. Preserve the installation between steps.

1. Invite from iPad, join on phone, reopen the original host bubble, and start. Reopen an older bubble after a subsequent move; compare the latest revision and digest in independently exported reports.
2. Make a normal move and confirm it on the other device. Use Game Information → Resend Game Update (or Settings during lobby/setup/game over) and confirm the same revision, digest, resources and dice; no second move should occur. During a known local-send failure, verify the local canonical game does not advance, then retry the original action. Do not infer a local send error simply by disconnecting Wi-Fi: Messages may queue successfully or use cellular.
3. Repeat the reported win: five settlements + Largest Army + one VP, buy two VP cards to reach ten. The second purchase should end immediately with ten points; both devices should show the same winner after opening the update. In an existing already-winning saved game, use Declare Victory; opening alone should not publish anything.
4. Offer a funded trade to the other player; accept, decline and counter in separate scenarios. Reopen the original offer after resolution; it must not transfer resources twice or revive a closed offer. Check button availability and messages against each player's resources.
5. In one friend session, test simultaneous joins and competing accepts from the same offer in both arrival orders, then reopen on all participants and compare reports. Four-player play already works per the owner; retain affected regression evidence and finish a match on the candidate rather than rebuilding the feature.

Export each device's report with its operator role and candidate details. Compare with the existing report CLI. Local unit/UI results cannot substitute for independent-account receipt, actual physical export or TestFlight install/update evidence. Keep those issue acceptance items open until observed.
