# Phase 6 — Trading

## Reconstruction Status

- Backfilled on 2026-03-12.
- Confidence: High.
- Evidence is anchored by commits `20fcbe3` and `fee2e7a`, plus the changelog entries for stages 6.1 and 6.2.

## Canonical Owner Docs

- [Locked Decisions](../../decisions.md)
- [Architecture Overview](../../architecture/overview.md)
- [QA](../../QA.md)

## Objective

Implement standard-player trade offers, anchored accepts, and current-player execution while preserving the async authority model.

## Starting State

The repo could process normal turns and builds, but there was no in-engine trade lifecycle and no way for non-current players to participate through anchored intents.

## Target End State

The current player could propose a trade, other players could submit anchored accepts, and the current player could execute one accepted trade atomically or let the offer expire at end turn.

## Implementation Narrative

### Stage 6.1 — Offer and accept lifecycle

- Added canonical trade state for the active offer and pending accepts.
- Enforced one-active-offer-at-a-time and offer expiry on end turn.
- Added `proposeTrade` and `acceptTrade` transport payloads plus debug-driver support.
- Evidence: commit `20fcbe3`; changelog stage 6.1 entries.

### Stage 6.2 — Trade execution

- Added atomic `executeTrade` handling with current-player commit gating and no-partial-mutation failure behavior.
- Extended transport/UI support to select a pending accept for execution.
- Evidence: commit `fee2e7a`; changelog stage 6.2 entries.

## Key Files or Subsystems

- `Packages/ULS_CoreGame/Sources/ULS_CoreGame/TradeStateV1.swift`
- `Packages/ULS_CoreGame/Sources/ULS_CoreGame/TurnReducerV1.swift`
- `Packages/ULS_Transport/Sources/ULS_Transport/TurnIntentV1.swift`
- `Packages/ULS_CoreGame/Tests/ULS_CoreGameTests/TurnTradeOffersV1Tests.swift`
- `Packages/ULS_CoreGame/Tests/ULS_CoreGameTests/TurnTradeExecutionV1Tests.swift`

## Validation Performed or Evidenced

- Focused tests cover propose actor gating, accept anchor mismatch rejection, one-offer constraint, trade execution success, and expiry behavior.
- The current engine spec still reflects the authority model this phase implemented.

## What This Enabled Next

Phase 6 completed the async trading contract that the PRD and locked decisions required, which in turn made full-match evals and later UI trade flows meaningful.

## Reconstruction Notes

- Confidence is high due to the clean commit boundary and dedicated trade test files.
- The dispute-resolution and chat-side counteroffer expectations remain owned by the current product docs, not by this historical plan.
