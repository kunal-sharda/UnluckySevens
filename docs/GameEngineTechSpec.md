# Game Engine Technical Specification

## Purpose

This document is the implementation contract for the current MVP engine. It bridges product intent from the PRD with the locked MVP rules in `docs/decisions.md` and the current codebase.

Source-of-truth priority:

1. Code and tests
2. `docs/decisions.md`
3. `docs/UnluckySevensPRD.pdf`

## Architecture Boundaries

- `ULS_CoreGame`
  - Pure game rules, state transitions, validation, determinism, board generation, economy, awards, and victory.
- `ULS_Transport`
  - Pure transport envelope and intent/state payload encoding.
- `MessagesExtension`
  - iMessage orchestration, message selection/sending, local debug driver, and formatting/rendering of engine-derived projections.

Design rule: UI code must not become a second rules engine.

## Canonical State and Invariants

Canonical state is `CoreGameStateV1`.

Key invariants:

- one canonical `STATE` revision chain per game
- `rev == prior.rev + 1`
- `prevHash == prior.stateHash`
- roster is fixed after game start
- only the current player publishes canonical state
- seed-derived randomness drives all gameplay randomness after game start
- bank, hands, dev deck, ownership, awards, and victory data live in canonical state
- opponents may exist in canonical state with full hidden data, but the UI may only expose secrecy-safe projections

## Determinism Model

- A master seed is chosen at game start and stored in canonical state.
- Domain-specific seeds derive board, dice, dev deck, and robber randomness streams.
- Random outcomes are advanced through stored RNG state, not through device-local randomness.
- Canonical state hashing is part of the anti-desync model and is validated on every transition.

Implication: replaying the same valid action sequence from the same seed must produce the same resulting state and state hash.

## State Machines

### Setup

- Snake order is derived from the fixed roster.
- Setup alternates `placeSettlement -> placeRoad`.
- The second completed placement grants starting resources from adjacent non-desert tiles.
- When setup completes, the engine transitions to turn phase with `TurnStateV1(step: .needsRoll)`.

### Turn

Turn step model:

- `needsRoll`
- `pendingDiscards`
- `needsRobberMove`
- `needsRobberSteal`
- `afterRoll`

Rules enforced in core:

- one dev card action per turn, with same-turn purchase restriction except VP reveal
- non-7 production with finite-bank all-or-nothing payout
- 7 flow with discard, robber move, and deterministic steal
- build legality, costs, and piece limits
- domestic trade proposal / accept / execute lifecycle
- maritime best-ratio enforcement
- award recomputation
- immediate win at 10+ VP on the active player’s turn

## Authority Model

The transport layer uses two message classes:

- `STATE`
  - authoritative canonical snapshot
- `INTENT`
  - anchored request against a specific canonical base

Current MVP authority model:

- only the current player publishes canonical `STATE`
- other players are effectively read-only except for sending relevant intents such as trade accept
- intents are inert until incorporated into a later canonical state

This model optimizes for desync resistance over symmetric mutation.

## UI-Readiness Contract

The engine already provides enough canonical state for the UI to know:

- current phase and turn step
- pending discard requirements and submissions
- eligible robber-steal victims
- active trade offer and pending accepts
- legal default/availability queries for build, trade, discard, and dev-card flows
- bank state
- ownership and board placement
- viewer-scoped secrecy-safe resource and dev-card projections
- audit history and last-turn recap
- victory totals and game-over result

Current default:

- `ULS_CoreGame` owns shared legal-action derivation and secrecy-safe projections in `CoreGameViewQueriesV1.swift`
- `MessagesExtension` stays orchestration and rendering only

## Deferred PRD Items

The following PRD ideas are intentionally not part of the current MVP engine contract:

- friendly robber
- timeout / forced stale trade expiry
- extra board fairness rules beyond current strategy support
- GameKit or backend persistence
- analytics / Crashlytics / monetization / cosmetics
- anti-tamper signatures

These should be treated as future hooks, not as missing MVP behavior.
