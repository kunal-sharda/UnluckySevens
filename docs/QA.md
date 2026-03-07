# QA

## Practical Gate

These commands should stay green for the current MVP engine baseline:

```bash
bash ./scripts/gen.sh
swift test --package-path Packages/ULS_CoreGame
swift test --package-path Packages/ULS_Transport
xcodebuild -workspace /Users/kunalsharda/Documents/Code/UnluckySevens/UnluckySevens.xcworkspace -scheme MessagesExtension -destination 'generic/platform=iOS Simulator' build
```

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

## Remaining High-Value Gaps

- shared engine-level legal-action query coverage once those helpers exist
- shared secrecy-safe projection coverage once those helpers exist
- CI execution of the practical gate above

## Manual Simulator Runbook

Use the current Messages debug harness for one smoke pass and three targeted checks.

### Smoke Pass

1. Run the Practical Gate commands.
2. Launch the host app and Messages in the simulator.
3. In Messages, create or open a thread and launch Unlucky Sevens.
4. Tap `Invite New Game`, then verify a lobby `STATE` bubble appears and the extension decodes it as active context.
5. Tap `Join` from another simulated actor path if available, record the join, then `Start Game`.
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
