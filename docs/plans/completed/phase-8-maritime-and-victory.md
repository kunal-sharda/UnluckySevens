# Phase 8 — Maritime and Victory

## Reconstruction Status

- Backfilled on 2026-03-12.
- Confidence: High.
- Evidence is anchored by commits `082393d` and `39d5d93`, plus the changelog entries for stages 8.1 and 8.2.

## Canonical Owner Docs

- [Locked Decisions](../../decisions.md)
- [Architecture Overview](../../architecture/overview.md)
- [QA](../../quality/qa.md)

## Objective

Finish the remaining core turn-to-win gameplay loops by adding maritime trade and canonical game-over victory handling.

## Starting State

The repo already supported normal turn actions, domestic trade, dev cards, and awards, but it still lacked port/bank trade actions and a clean victory/game-over transition.

## Target End State

The current player could perform legal maritime trades using the best applicable port ratio, and the engine could detect and lock in an immediate win on the active player's turn.

## Implementation Narrative

### Stage 8.1 — Maritime trade

- Added maritime trade actions and deterministic best-ratio selection using owned ports.
- Extended transition validation to admit only the narrow bank/player transfers associated with legal maritime trades.
- Evidence: commit `082393d`; changelog stage 8.1 entries.

### Stage 8.2 — Victory and game over

- Added canonical VP utilities, game-over winner metadata, and reducer logic to transition to `gameOver` when the active player reaches 10+ VP.
- Rejected further gameplay intents after game over.
- Evidence: commit `39d5d93`; changelog stage 8.2 entries.

## Key Files or Subsystems

- `Packages/ULS_CoreGame/Sources/ULS_CoreGame/VictoryV1.swift`
- `Packages/ULS_CoreGame/Sources/ULS_CoreGame/TurnReducerV1.swift`
- `Packages/ULS_CoreGame/Sources/ULS_CoreGame/CoreGameValidation.swift`
- `Packages/ULS_CoreGame/Tests/ULS_CoreGameTests/TurnMaritimeTradeV1Tests.swift`
- `Packages/ULS_CoreGame/Tests/ULS_CoreGameTests/TurnVictoryV1Tests.swift`

## Validation Performed or Evidenced

- Maritime trade tests cover ratio selection, insufficient-resource rejection, and no-mutation failure behavior.
- Victory tests cover win gating, post-game rejection, and non-current-player non-win behavior.

## What This Enabled Next

Phase 8 closed the playable core-game loop from setup through win and made it possible for later audit-log and full-match eval work to end on real game-over states.

## Reconstruction Notes

- Confidence is high due to clear commit and test evidence.
- The exact UI for presenting VP totals and winner state remained a later concern.
