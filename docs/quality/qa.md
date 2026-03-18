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

1. Install and launch the host app on both devices.
2. Open Messages and confirm Unlucky Sevens appears in the app drawer on both devices.
3. Open the same conversation between the two accounts.
4. Open an existing canonical `STATE` bubble and confirm the shell renders:
   - header
   - board area
   - hand tray
   - action dock
   - compact opponent summaries
5. Confirm the iPhone layout remains readable in compact extension sizing.
6. Confirm the iPad layout remains readable and does not over-expand low-priority UI.
7. Verify opponent information is still count-only and does not leak composition.
8. Toggle debug UI and confirm it is still accessible without taking over the product shell.

### Real Device Lobby Smoke

Run this after any lobby join/start UX change.

1. From device A, send an invite `STATE` into the thread.
2. From device B, open the invite and join.
3. Confirm joining does not require an extra manual send step after tapping `Join`.
4. From device A (host), confirm the lobby UI reflects the joined roster.
5. From device A (host), start the game.
6. From device B, open the start `STATE` and confirm the extension resolves the new setup context cleanly.

### Real Device Messages Lifecycle

Run this after any transcript, bubble, session, or context-selection change.

1. Send a new `STATE` bubble from one device.
2. Select that bubble on the other device and confirm it becomes active context.
3. Switch away from Messages and return.
4. Reopen the same bubble and confirm the shell still resolves the correct context.
5. Select an older bubble after a newer one exists and confirm stale-context behavior is obvious and recoverable.
6. Reload the latest bubble and confirm the warning clears.
7. Force-close and relaunch Messages, then confirm context can still be recovered from the selected bubble.

### Real Device Turn-Taking Smoke

Run this after any action-flow change that affects turns, trades, robber, or dev cards.

1. From device A, publish or reach a playable `STATE`.
2. Perform one legal action from the acting player.
3. On device B, confirm the new bubble appears and opens cleanly.
4. Continue the turn or respond from the other account when appropriate.
5. Verify status text is correct on both sides:
   - `Your turn`
   - `Waiting on <player>`
   - `Trade pending`
6. Confirm no bubble or context step silently drops during cross-device play.

## What Is Already Covered Well

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

## Remaining High-Value Gaps

- no automated transcript-level Messages UI checks yet
- no board/UI snapshot coverage once the production board UI replaces the current debug harness
- no automated real-device lane; hardware validation is still manual

## Manual Simulator Runbook

Use the current Messages debug harness for one smoke pass and three targeted checks.

### Smoke Pass

1. Run the Practical Gate commands.
2. Launch the host app and Messages in the simulator.
3. In Messages, create or open a thread and launch Unlucky Sevens.
4. Tap `Invite New Game`, then verify a lobby `STATE` bubble appears and the extension decodes it as active context.
5. Tap `Join` from another simulated actor path if available, then `Start Game`.
   - If join/start UX is still in transition, debug-only steps such as `Record Join` may exist temporarily. Prefer the product flow when available.
6. Apply setup intents until the game reaches turn phase.
7. Roll once, apply the resulting intent into `STATE`, and verify:
   - rev increments
   - phase is `turn`
   - step becomes `afterRoll` or the correct robber/discard subflow
8. Perform one post-roll action such as build, trade, maritime trade, or dev-card purchase.
9. End the turn and verify:
   - current player advances
   - step resets to `needsRoll`
   - trade offers clear
10. Verify opponent hand and dev-card views show counts only, not composition.

### Targeted Check: Robber / Seven Flow

1. Continue play until a 7 occurs naturally.
2. Verify required discard counts appear only for players with more than 7 cards.
3. Apply discard intents and confirm the engine blocks robber movement until discards complete.
4. Move the robber and confirm the engine only offers eligible victims.
5. Apply steal and verify the turn returns to `afterRoll`.

### Targeted Check: Trade Lifecycle

1. From an `afterRoll` state, propose a trade as current player.
2. Switch acting actor and send one or more accept intents.
3. Switch back to the current player and apply one selected accept into canonical state.
4. Verify resource transfer is atomic and the offer clears.
5. Repeat a turn where the offer is not executed and confirm `End Turn` expires it.

### Targeted Check: Context / Secrecy Safety

1. Select an older `STATE` bubble after a newer one exists.
2. Verify the stale-context warning appears.
3. Reload the latest bubble and verify the warning clears.
4. Change `Acting As` and verify local player detail changes while opponent information remains count-only.
