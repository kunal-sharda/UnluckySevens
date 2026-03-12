# Phase 3 — Setup Flow

## Reconstruction Status

- Backfilled on 2026-03-12.
- Confidence: High.
- Evidence is anchored by commits `6767732`, `f1fd9ec`, `d8b027e`, `5b98bde`, and `a0352de`, plus the changelog entries for stages 3.1 through 3.3.

## Canonical Owner Docs

- [Locked Decisions](../../decisions.md)
- [Architecture](../../../ARCHITECTURE.md)
- [QA](../../quality/qa.md)

## Objective

Implement the full setup sequence in pure core logic: snake draft order, settlement/road placement legality, atomic setup pairing, and second-settlement starting resources.

## Starting State

The repo had deterministic board generation and protocol/state primitives, but no actual setup state machine or setup legality enforcement.

## Target End State

A game could move from lobby start into setup, process legal setup placements in order, reject illegal ones, and hand the finished board state into the first turn with correct starting resources.

## Implementation Narrative

### Stage 3.1 — Setup state machine

- Added `SetupStateV1`, setup steps, player placement tracking, and a pure setup reducer.
- Added `SetupPlacementIntentV1` and setup buttons to the Messages debug driver.
- Evidence: commit `6767732`; changelog stage 3.1 entries.

### Stage 3.2 — Setup legality

- Enforced settlement distance, road adjacency to the just-placed settlement, node/edge bounds, and occupancy checks.
- Evidence: commit `f1fd9ec`; changelog stage 3.2 entries.

### Stage 3.2.1 — Atomic setup pair placement

- Added `placeSetupPair` as an additive transport intent and atomic reducer support for placing the settlement/road pair together.
- Evidence: commit `d8b027e`; changelog stage 3.2.1 entries.

### Stage 3.3 — Starting resource distribution and setup invariants

- Added `ResourceHandV1` and canonical player resources.
- Granted second-settlement starting resources after the second road placement.
- Tightened transition validation and normalized resource storage across the roster.
- Evidence: commits `5b98bde` and `a0352de`; changelog stage 3.3 entries and follow-ups.

## Key Files or Subsystems

- `Packages/ULS_CoreGame/Sources/ULS_CoreGame/SetupStateV1.swift`
- `Packages/ULS_CoreGame/Sources/ULS_CoreGame/SetupReducerV1.swift`
- `Packages/ULS_Transport/Sources/ULS_Transport/SetupPlacementIntentV1.swift`
- `Packages/ULS_CoreGame/Sources/ULS_CoreGame/ResourceHandV1.swift`
- `Packages/ULS_CoreGame/Tests/ULS_CoreGameTests/SetupStateMachineV1Tests.swift`
- `Packages/ULS_CoreGame/Tests/ULS_CoreGameTests/SetupStartingResourcesV1Tests.swift`

## Validation Performed or Evidenced

- Setup reducer and transport roundtrip tests were added.
- Focused topology and starting-resource tests covered the main legality and payout paths.
- Transition validation changes enforced setup-specific resource invariants.

## What This Enabled Next

Phase 3 made it possible to enter normal turn flow from a legal board state without synthetic setup shortcuts.

## Reconstruction Notes

- Confidence is high because the phase is well represented in both commits and current tests.
- The exact debug-button labels are treated as historical implementation details, not part of the long-term UI contract.
