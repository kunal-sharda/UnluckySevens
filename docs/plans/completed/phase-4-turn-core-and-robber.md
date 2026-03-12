# Phase 4 — Turn Core and Robber

## Reconstruction Status

- Backfilled on 2026-03-12.
- Confidence: High.
- Evidence is anchored by commits `380cf2b`, `b557a3b`, `3df52e9`, and `28c12af`, plus the matching changelog entries.

## Canonical Owner Docs

- [Locked Decisions](../../decisions.md)
- [Architecture Overview](../../architecture/overview.md)
- [QA](../../QA.md)

## Objective

Implement the base turn loop: rolling, production, bank/resource movement, roll-7 discard flow, robber movement, and deterministic stealing.

## Starting State

The repo could complete setup and had deterministic seeds and board state, but normal turns did not yet exist.

## Target End State

A legal turn could progress through roll, production or seven-flow substeps, robber movement, deterministic steal, and explicit end turn with correct actor gating and state validation.

## Implementation Narrative

### Stage 4.1 — Turn sequencing, roll, and end turn

- Added `TurnStateV1`, `TurnStepV1`, `DiceRollV1`, and reducer support for `rollDice` and `endTurn`.
- Added `TurnIntentV1` transport support and initial Messages debug controls.
- Evidence: commit `380cf2b`; changelog stage 4.1 entries.

### Stage 4.2 — Non-7 production and bank handling

- Added deterministic production payout using board occupancy and robber blocking.
- Added finite-bank all-or-nothing payout behavior and canonical bank/occupancy state.
- Evidence: commit `b557a3b`; changelog stage 4.2 entries.

### Stage 4.3 — Discard and robber move

- Added the roll-7 subflow with discard requirements, staged discard submission, and gated robber movement.
- Extended transport and debug controls for discard and robber movement.
- Evidence: commit `3df52e9`; changelog stage 4.3 entries.

### Stage 4.4 — Deterministic robber steal

- Added eligible-victim computation, `needsRobberSteal`, and deterministic steal selection using persisted robber RNG state.
- Extended transport/UI for selecting a victim.
- Evidence: commit `28c12af`; changelog stage 4.4 entries.

## Key Files or Subsystems

- `Packages/ULS_CoreGame/Sources/ULS_CoreGame/TurnStateV1.swift`
- `Packages/ULS_CoreGame/Sources/ULS_CoreGame/TurnReducerV1.swift`
- `Packages/ULS_Transport/Sources/ULS_Transport/TurnIntentV1.swift`
- `Packages/ULS_CoreGame/Tests/ULS_CoreGameTests/TurnStateMachineV1Tests.swift`
- `Packages/ULS_CoreGame/Tests/ULS_CoreGameTests/TurnResourceDistributionV1Tests.swift`
- `Packages/ULS_CoreGame/Tests/ULS_CoreGameTests/TurnRollSevenV1Tests.swift`
- `Packages/ULS_CoreGame/Tests/ULS_CoreGameTests/TurnRobberStealV1Tests.swift`

## Validation Performed or Evidenced

- Focused unit coverage exists for turn sequencing, non-7 production, discard requirements, robber preconditions, and deterministic steal behavior.
- Transition validation and transport roundtrip coverage grew alongside the reducer work.

## What This Enabled Next

Phase 4 created the real turn backbone. Build legality, trades, dev cards, awards, victory, and the audit log all depend on this turn-state machinery.

## Reconstruction Notes

- Confidence is high because the phase boundaries match both commit history and dedicated test files.
- The Messages debug driver was a delivery vehicle for the engine, not the long-term product UI.
