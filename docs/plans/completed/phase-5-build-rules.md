# Phase 5 — Build Rules

## Reconstruction Status

- Backfilled on 2026-03-12.
- Confidence: High.
- Evidence is anchored by commit `250f714` and the corresponding changelog entries.

## Canonical Owner Docs

- [Locked Decisions](../../decisions.md)
- [Game Engine Technical Specification](../../GameEngineTechSpec.md)
- [QA](../../QA.md)

## Objective

Add the core build actions and their legality/cost enforcement so players could change the board during normal turns using roads, settlements, and cities.

## Starting State

The repo had a working turn loop and board occupancy, but turn-phase construction was still missing.

## Target End State

The current player could build roads, settlements, and cities during `afterRoll`, with proper costs, piece limits, connectivity rules, and canonical validation.

## Implementation Narrative

### Stage 5.1 — Turn-phase build actions

- Added `buildRoad`, `buildSettlement`, and `buildCity` actions.
- Enforced costs, piece limits, occupancy rules, settlement distance, and network connectivity.
- Extended transition validation and debug-driver support to make the resulting board and resource changes auditable.
- Evidence: commit `250f714`; changelog stage 5.1 entries.

## Key Files or Subsystems

- `Packages/ULS_CoreGame/Sources/ULS_CoreGame/TurnReducerV1.swift`
- `Packages/ULS_CoreGame/Sources/ULS_CoreGame/CoreGameValidation.swift`
- `Packages/ULS_CoreGame/Tests/ULS_CoreGameTests/TurnBuildRulesV1Tests.swift`
- `MessagesExtension/Sources/LobbyDriverViewModel.swift`

## Validation Performed or Evidenced

- Focused tests cover legal and illegal build cases, cost conservation, and non-mutating failure behavior.
- Transition validation checks ensure the allowed ownership and economy deltas stay narrow.

## What This Enabled Next

Build legality is a prerequisite for meaningful trading, development-card effects such as Road Building, award computation, and realistic full-match simulations.

## Reconstruction Notes

- This phase is compact and commit evidence is clear, so confidence is high.
- The exact debug affordances are omitted here in favor of the engine and validation outcome.
