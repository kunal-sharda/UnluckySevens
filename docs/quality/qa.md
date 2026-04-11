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
   - utility strip
   - action dock
5. Confirm the utility strip exposes:
   - `Hand`
   - `Bank`
   - `Players`
6. Confirm the persistent dock order stays:
   - `Roll`
   - `End Turn`
   - `Build`
   - `Play Dev`
7. Confirm hand, bank, and player summaries are not always-open cards in the default shell.
8. Confirm the iPhone layout remains readable in compact extension sizing.
9. Confirm the iPad layout remains readable and does not over-expand low-priority UI.
10. Verify opponent information is still count-only and does not leak composition.
11. Confirm the shell remains product-focused and no debug UI is required to advance the normal game flow.

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
   - utility strip
   - dock
3. Confirm the primary dock order is:
   - `Roll`
   - `End Turn`
   - `Build`
   - `Play Dev`
4. Confirm the full island and all ports are visible at default zoom, with a small ocean margin and slightly more water below the island than above. Confirm you can zoom out only slightly beyond default and zoom in much further than the fit overview.
5. Open `Build` and verify the shelf only shows legal actions from:
   - `Road`
   - `Settlement`
   - `City`
   - `Buy Dev`
6. Tap `Hand`, `Bank`, and `Players` and confirm only one shelf opens at a time.
7. Open the `Hand` shelf and confirm trade is entered from there instead of from a persistent dock button.
8. Open the `Bank` shelf and confirm it shows public remaining counts for wood, brick, sheep, wheat, and ore. Verify it only becomes interactive during Monopoly or Year of Plenty selection.
9. Open the `Players` shelf and confirm each opponent row only shows:
   - alias
   - current-turn indicator
   - public VP
   - public hand count
10. Tap random nodes, edges, and tiles while idle. Confirm nothing highlights or remains selected unless the active mode actually uses that board target class.
11. Open the dev-card panel and confirm the legal actions are choice-driven, not just default labels:
   - Knight
   - Monopoly
   - Year of Plenty
   - Road Building
   Verify each option only appears when legal for the current turn state.
12. Play Knight and confirm the robber moves to the selected tile. If the chosen tile has multiple legal victims, verify the victim selection step becomes explicit; if it has one or zero legal victims, verify the flow resolves without an unnecessary extra picker.
13. Play Monopoly and confirm the chosen resource is the one collected from opponents.
14. Play Year of Plenty and confirm the selected two resources are taken from the bank and added to the player.
15. Play Road Building and confirm the selected two edges are placed without resource cost.
16. If a Victory Point card is present, confirm it is only surfaced when revealing it would immediately win the game.
17. Open the trade panel as proposer and responder. Confirm the compact panel explains accepted, waiting, passive-decline, and execute/end-turn expiry behavior without leaking raw IDs or debug text.
18. Finish a game-over state or load one from transcript and confirm the shell shows:
   - winner clearly
   - compact final score
   - short last-turn recap
   - no dead bottom tray

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
5. If a debug-only branch is temporarily using a mirrored summary fallback for host investigation, capture that as a host-fidelity defect and do not treat it as canonical product transport.
6. If lobby `STATE` decodes but `Join Game` is still missing on the receiving device, inspect:
   - `localParticipant`
   - `resolvedActor`
   - `localInRoster`
   - `localPendingJoin`
   - `canJoin`
   - `isInviter`
7. Capture the debug HUD state as the primary repro artifact before retrying with a new bubble or escalating the issue into the stability phase.

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
- debug-build payload mirroring plus sender-side cached-state recovery so device triage can continue when the Messages host drops `message.url` or transiently clears selection on reopen

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
9. Confirm the default shell reads as header, board, utility strip, and dock rather than stacked hand/bank/player cards.
10. Tap `Hand`, `Bank`, and `Players` and confirm only one shelf opens at a time.
11. Confirm the bank shelf shows public counts for wood, brick, sheep, wheat, and ore, and only becomes interactive during Monopoly or Year of Plenty selection.
12. Roll once, then perform one post-roll action such as build, trade, maritime trade, or dev-card purchase.
13. Open the dev-card panel when legal and verify only legal play/reveal actions are shown there; buy-dev-card should now live under the `Build` shelf instead.
14. Verify `Play Dev` never falls back to default-choice labels for Knight, Monopoly, Year of Plenty, or Road Building. Knight should move through tile choice first and only open a victim choice when the chosen tile has multiple eligible steals; Monopoly should use the bank shelf, Year of Plenty should use first/second bank picks, and Road Building should use first/second road choice.
15. Verify Victory Point reveal stays hidden unless the reveal would immediately win the game.
16. End the turn and verify:
    - current player advances
    - step resets to `needsRoll`
    - trade offers clear
17. Verify opponent hand and dev-card views show counts only, not composition.
18. Verify the turn header never shows raw debug/context metadata; it should stay limited to ownership plus dice state.

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
