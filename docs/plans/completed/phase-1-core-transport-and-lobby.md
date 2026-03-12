# Phase 1 — Core Transport and Lobby

## Reconstruction Status

- Backfilled on 2026-03-12.
- Confidence: High.
- Evidence is anchored by commits `4839d04`, `a1ec60b`, and `001d2a5`, plus the matching changelog entries.

## Canonical Owner Docs

- [Locked Decisions](../../decisions.md)
- [Architecture Overview](../../architecture/overview.md)
- [QA](../../quality/qa.md)

## Objective

Define the first real async game protocol, add canonical state hashing and transition validation, and prove a lobby flow could move a conversation from invite/join/start into the beginning of a game session.

## Starting State

The repo had a generated Messages app shell and a debug bubble loop, but no authoritative game envelope, no canonical state contract, and no lobby/state transition flow.

## Target End State

The repo could encode and decode versioned `STATE` and `INTENT` envelopes, validate canonical state transitions, and drive a basic lobby flow from the Messages extension.

## Implementation Narrative

### Stage 1.1 — Transport v1

- Added `EnvelopeV1` for `STATE` and `INTENT`, along with reusable base64url JSON codecs and transport errors.
- Evidence: commit `4839d04`; changelog stage 1.1 entries.

### Stage 1.2 — CoreGame v1 kernel

- Added `CoreGameStateV1`, canonical hashing, and `validateTransition(from:to:actor:)`.
- Established the first anti-desync contract: `rev`, `prevHash`, actor gating, roster stability, and canonical `stateHash` verification.
- Evidence: commit `a1ec60b`; changelog stage 1.2 entries.

### Stage 1.3 — Lobby flow stub

- Added the SwiftUI lobby driver with invite, join, record join, start, and clear-pending-joins actions.
- Added `JoinIntentV1` and lobby-to-setup state changes with seed handling.
- Evidence: commit `001d2a5`; changelog stage 1.3 entries.

## Key Files or Subsystems

- `Packages/ULS_Transport/Sources/ULS_Transport/EnvelopeV1.swift`
- `Packages/ULS_Transport/Sources/ULS_Transport/EnvelopeV1Codec.swift`
- `Packages/ULS_CoreGame/Sources/ULS_CoreGame/CoreGameStateV1.swift`
- `Packages/ULS_CoreGame/Sources/ULS_CoreGame/CoreGameValidation.swift`
- `MessagesExtension/Sources/LobbyDriverViewModel.swift`

## Validation Performed or Evidenced

- Transport roundtrip and invalid decode tests were added with the transport layer.
- CoreGame tests were added for golden hashing and transition validation failures.
- The lobby flow was evidenced by new Messages UI controls and join-intent roundtrip coverage.

## What This Enabled Next

This phase created the durable protocol and canonical-state model that every later gameplay phase depended on. Without it, determinism, anti-desync validation, and async authority semantics would have remained undefined.

## Reconstruction Notes

- The phase intent is directly supported by commit messages and changelog entries, so confidence is high.
- The detailed user-facing lobby behavior is summarized here, but the current owner docs still define the authoritative product rules.
