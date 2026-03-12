# Architecture Overview

Unlucky Sevens is an iMessage-first async Catan implementation. The architecture optimizes for four things:

- deterministic game state and replay
- strict authority semantics in a noisy Messages environment
- clear separation between game rules, message transport, and UI
- enough structure that future UI work does not re-implement game logic

This document explains the major pieces, how they collaborate, and where new code should go. It is not the lockfile for product decisions; that remains [`../decisions.md`](../decisions.md).

## System Shape

There are three runtime layers:

1. `ULS_CoreGame`
   - pure game rules, reducers, validation, board generation, economy, awards, victory, and viewer-safe query helpers
2. `ULS_Transport`
   - message envelope encoding/decoding, intent/state payload transport, hashing helpers, and payload-size handling
3. `MessagesExtension`
   - iMessage lifecycle, transcript selection, message send/receive orchestration, and UI rendering

The minimal host app exists only to run the Messages extension in development and on device.

## Dependency Direction

The dependency rule is strict:

- `ULS_CoreGame` depends on no UI framework and owns gameplay truth
- `ULS_Transport` depends on no UI framework and owns the protocol boundary
- `MessagesExtension` consumes both packages and owns the app-extension surface

`MessagesExtension` may format or present engine state, but it must not become a second rules engine.

## Runtime Flow

A normal gameplay loop works like this:

1. The extension selects or receives a transcript bubble.
2. `ULS_Transport` decodes the envelope and payload.
3. `ULS_CoreGame` validates and applies the intended transition.
4. `ULS_CoreGame` also provides viewer-safe summaries and legal/default action queries for rendering.
5. `MessagesExtension` renders the current state, surfaces legal actions, and publishes the next authoritative `STATE` when allowed.

This means the UI should ask the engine what is legal and visible rather than deriving those answers independently.

## Ownership Boundaries

### Game rules

Anything that changes canonical state or determines whether a move is legal belongs in `ULS_CoreGame`.

Examples:

- setup sequencing and legality
- turn step transitions
- resource and bank invariants
- trade execution and expiry
- dev-card effects
- awards and victory
- secrecy-safe projections and legal-action queries

### Message protocol

Anything about how a `STATE` or `INTENT` is encoded, decoded, versioned, or size-checked belongs in `ULS_Transport`.

Examples:

- envelope versioning
- base64url and JSON handling
- transport error types
- encoded-size helpers

### Extension/UI orchestration

Anything about iMessage lifecycle or presentation belongs in `MessagesExtension`.

Examples:

- `MSMessagesAppViewController` wiring
- transcript selection and session handling
- screen state and mode switching
- SwiftUI and SpriteKit presentation
- local debug harness behavior

## Invariants That Shape the Codebase

Several invariants explain why the code is split this way:

- only one canonical `STATE` chain exists per game
- only the current player publishes canonical `STATE`
- random outcomes must be reproducible from persisted deterministic state
- the canonical state may contain hidden information, but the UI may only expose viewer-safe projections
- transport is a boundary layer, not a rules engine

These invariants are enforced by code and tests first, then documented in the owner docs.

## Where New Code Should Go

- Add rule logic, legality checks, and canonical-state helpers to `ULS_CoreGame`
- Add envelope/payload/codec work to `ULS_Transport`
- Add UI composition, screen models, and app-extension flows to `MessagesExtension`
- Add cross-cutting verification or historical execution records to `docs/` and `docs/plans/`

If a feature needs the UI to compute legality or hidden-information policy on its own, that is usually a sign the engine surface is incomplete.

## Current Pressure Points

The main architectural pressure is not package shape; it is keeping the growing UI phase from collapsing back into a single monolithic extension file. The next stage should therefore organize `MessagesExtension` internally by feature and presentation responsibility while keeping rules and protocol logic in their current packages.
