# Phase 2 — Determinism and Board

## Reconstruction Status

- Backfilled on 2026-03-12.
- Confidence: High.
- Evidence is anchored by commits `fe71c0d`, `179a1da`, and `98dc194`, plus the changelog entries for stages 2.1 through 2.3.

## Canonical Owner Docs

- [Locked Decisions](../../decisions.md)
- [Architecture](../../../ARCHITECTURE.md)
- [QA](../../quality/qa.md)

## Objective

Make randomness deterministic and persistent, then model the board deeply enough that later setup, production, robber, and build legality could be implemented in pure core logic.

## Starting State

The repo had a protocol and canonical state, but no persisted deterministic RNG model and no board topology or generated board data in core state.

## Target End State

The repo could derive domain-specific seeds, persist deterministic RNG state, generate standard-board topology and board setups, and surface board information through the Messages debug UI.

## Implementation Narrative

### Stage 2.1 — Deterministic RNG and seed domains

- Added `DeterministicRNG`, d6 and 2d6 helpers, domain-separated seed derivation, and persisted `diceRngState` in canonical state.
- Evidence: commit `fe71c0d`; changelog stage 2.1 entries.

### Stage 2.2 — Board topology model

- Added `BoardGraphV1` model types for tiles, nodes, edges, and ports.
- Implemented `StandardBoardTopologyV1.standard()` for the standard Catan geometry and adjacency rules.
- Evidence: commit `179a1da`; changelog stage 2.2 entries.

### Stage 2.3 — Board setup generation and state integration

- Added `BoardRulesV1`, `BoardSetupV1`, deterministic board generation strategies, and canonical board hashing.
- Restricted board mutations to the lobby-to-setup start transition and added board debug output in the Messages extension.
- Follow-up work tightened session strategy and board-hash validation.
- Evidence: commit `98dc194`; changelog stage 2.3 entries and follow-ups.

## Key Files or Subsystems

- `Packages/ULS_CoreGame/Sources/ULS_CoreGame/DeterministicRNG.swift`
- `Packages/ULS_CoreGame/Sources/ULS_CoreGame/SeedDeriver.swift`
- `Packages/ULS_CoreGame/Sources/ULS_CoreGame/BoardGraphV1.swift`
- `Packages/ULS_CoreGame/Sources/ULS_CoreGame/BoardGeneratorV1.swift`
- `Packages/ULS_CoreGame/Sources/ULS_CoreGame/BoardSetupV1.swift`
- `Packages/ULS_CoreGame/Tests/ULS_CoreGameTests/BoardGraphV1Tests.swift`
- `Packages/ULS_CoreGame/Tests/ULS_CoreGameTests/BoardGeneratorV1Tests.swift`

## Validation Performed or Evidenced

- Golden RNG and seed-derivation tests were added.
- Board topology tests covered counts, adjacency, IDs, and port constraints.
- Board generation tests covered deterministic generation and strategy behavior.

## What This Enabled Next

Phase 2 created the deterministic substrate needed for setup sequencing, placement legality, resource distribution, robber behavior, and any later replay/eval work.

## Reconstruction Notes

- Confidence is high because the phase lines up cleanly with commits, changelog, and surviving tests.
- The board debug UI is treated here as phase evidence, not as a lasting UI architecture recommendation.
