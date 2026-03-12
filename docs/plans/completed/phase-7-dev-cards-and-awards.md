# Phase 7 — Dev Cards and Awards

## Reconstruction Status

- Backfilled on 2026-03-12.
- Confidence: High.
- Evidence is anchored by commits `8a9e693`, `818458e`, and `f6da924`, plus the changelog entries for stages 7.1 through 7.3.

## Canonical Owner Docs

- [Locked Decisions](../../decisions.md)
- [Game Engine Technical Specification](../../GameEngineTechSpec.md)
- [QA](../../QA.md)

## Objective

Implement the deterministic development deck, the playable dev-card actions, and award transfer logic for Largest Army and Longest Road.

## Starting State

The repo had turn flow, building, and trades, but it did not yet model the dev deck, dev-card ownership/timing, or award-state recomputation.

## Target End State

The game could buy and play dev cards with correct timing restrictions, preserve deterministic deck order, and award or transfer Largest Army and Longest Road according to standard Catan rules.

## Implementation Narrative

### Stage 7.1 — Deterministic dev deck

- Added `DevCardV1`, deterministic shuffle logic, and canonical dev-deck state.
- Evidence: commit `8a9e693`; changelog stage 7.1 entries.

### Stage 7.2 — Dev card play

- Added persistent dev-card ownership, same-turn purchase restrictions, per-turn dev action tracking, and play flows for Knight, Monopoly, Year of Plenty, Road Building, and VP reveal.
- Extended transport and debug-driver support for buying and playing dev cards.
- Evidence: commit `818458e`; changelog stage 7.2 entries.

### Stage 7.3 — Award transfer logic

- Added canonical award persistence and deterministic recomputation for Largest Army and Longest Road.
- Implemented threshold, tie-retention, and transfer behavior.
- Evidence: commit `f6da924`; changelog stage 7.3 entries.

## Key Files or Subsystems

- `Packages/ULS_CoreGame/Sources/ULS_CoreGame/DevDeckV1.swift`
- `Packages/ULS_CoreGame/Sources/ULS_CoreGame/DevCardInventoryV1.swift`
- `Packages/ULS_CoreGame/Sources/ULS_CoreGame/AwardsV1.swift`
- `Packages/ULS_CoreGame/Tests/ULS_CoreGameTests/DevDeckDeterminismV1Tests.swift`
- `Packages/ULS_CoreGame/Tests/ULS_CoreGameTests/TurnDevCardsV1Tests.swift`
- `Packages/ULS_CoreGame/Tests/ULS_CoreGameTests/TurnAwardsV1Tests.swift`

## Validation Performed or Evidenced

- Deterministic deck sequence and state-hash continuity tests exist.
- Focused dev-card tests cover timing restrictions and each effect.
- Award tests cover threshold, transfer, and tie behavior.

## What This Enabled Next

This phase completed the higher-leverage turn actions that materially affect victory pacing, robber flow, and later full-match eval realism.

## Reconstruction Notes

- Confidence is high because the phase is well represented in commits, changelog, and dedicated tests.
- The exact interaction details for future polished UI are intentionally left to later phases.
