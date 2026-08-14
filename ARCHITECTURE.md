# ARCHITECTURE.md

Unlucky Sevens is an iMessage-first async Catan implementation. The architecture optimizes for four things:

- deterministic game state and replay
- strict authority semantics in a noisy Messages environment
- clear separation between game rules, message transport, and UI
- enough structure that future UI work does not re-implement game logic

This document explains the major pieces, how they collaborate, where new code should go, and how the state-first protocol boundary protects the game from desync. Locked product decisions remain in [`docs/decisions.md`](docs/decisions.md).

## System Shape

There are three runtime layers:

1. `ULS_CoreGame`
   - pure game rules, reducers, validation, board generation, economy, awards, victory, and viewer-safe query helpers
2. `ULS_Transport`
   - message envelope encoding/decoding, canonical `STATE` payload transport, hashing helpers, and payload-size handling
3. `MessagesExtension`
   - iMessage lifecycle, transcript selection, message send/receive orchestration, and UI rendering

The generated app target is a resource-only standalone Messages app bundle that embeds `MessagesExtension`. It exists for installation and TestFlight packaging, but the shipped product surface is only accessible from Messages.

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

The UI should ask the engine what is legal and visible rather than deriving those answers independently.

## Ownership Boundaries

### Game rules

Anything that changes canonical state or determines whether a move is legal belongs in `ULS_CoreGame`.

Examples:

- setup sequencing and legality
- turn step transitions
- resource and bank invariants
- trade acceptance resolution and expiry
- dev-card effects
- awards, inactive-player resignation, draw voting, victory, and canonical terminal results
- secrecy-safe projections and legal-action queries

### Message protocol

Anything about how canonical `STATE` is encoded, decoded, versioned, or size-checked belongs in `ULS_Transport`.

Examples:

- envelope versioning
- base64url and JSON handling
- transport error types
- encoded-size helpers

### Extension/UI orchestration

Anything about iMessage lifecycle or presentation belongs in `MessagesExtension`.

Examples:

- `MSMessagesAppViewController` wiring
- controller-owned `MessagesHostLayoutStore` capture and settling of the actual host bounds, safe area, presentation style, and responsive profile
- transcript selection and session handling
- screen state and mode switching
- SwiftUI and SpriteKit presentation
- recovery and transcript selection behavior

The controller is the sole authority for host geometry. SwiftUI consumes one settled
`MessagesHostLayoutSnapshot`; product routes cannot publish layout revisions. UIKit
transition callbacks suppress intermediate geometry and commit once after a genuine
Messages presentation or window-size transition settles. SpriteKit keeps its mounted
`SKView` and receives only the resulting viewport adjustment.

## Protocol Model

The shipped transcript/runtime is `STATE`-only:

- `STATE`
  - authoritative canonical snapshot of the game at a specific revision

`SetupIntentV1`, `ULS_CoreGame.TurnIntentV1`, and anchored `GameLifecycleIntentV1` values are engine reducer inputs, not transcript compatibility payloads. Messages authoring applies them locally against a game/revision/hash anchor and publishes only the resulting canonical `STATE`. `ULS_Transport` does not own action draft DTOs.

Turn-advancing actions are still constrained by game rules:

- the current player publishes canonical `STATE` for normal turn progression
- responder actors may also publish canonical `STATE` directly for rules-defined off-turn actions that do not change `currentPlayer`, such as forced discard or targeted trade responses
- any active player may publish a Core-produced resignation or draw-vote `STATE`; resignation preserves active play for the remaining roster
- only the original inviter/host may publish a neutral host-end `STATE`, while ordinary victory remains reducer-owned

This keeps the wire/runtime model simpler while preserving the asymmetric authority semantics that reduce desync risk in async Messages play.

## Revision, Anchor, and Session Rules

A canonical state transition is valid only when the usual chain holds:

- `rev == prior.rev + 1`
- `prevHash == prior.stateHash`
- roster is unchanged after the game starts
- actor semantics match the validated transition rules

Internal authoring actions must still be anchored to the current canonical base via revision/hash before publication. Stale authoring inputs should resolve against the newest known canonical state for that game or fail validation.

The Messages UX uses one `MSSession` per game for canonical `STATE` updates so the main game bubble stays grouped across lobby, setup, turn play, responder actions, and game over.

Session continuity is an in-memory host adaptation, not canonical persistence. Recovery publication reuses the selected same-game or cached in-memory `MSSession` when available. If extension restart leaves neither available, it deliberately starts a fresh recovery bubble; persisted `MSSession` archival is prohibited until a two-device replacement experiment proves it reliable.

The local per-game ledger stores validated canonical snapshots independently of the compact wire representation. Higher revisions win; valid equal-revision siblings converge on the lexicographically greatest state hash. Active records persist until local archive, while only the eight most recently updated finished games are retained. Archive is device-local and a later valid transcript bubble can recreate the record.

The protocol source of truth is the message URL payload. Pre-TestFlight dev-era summary mirroring, legacy envelopes, and retired transcript debug surfaces are intentionally unsupported on the current branch.

## Invariants That Shape the Codebase

Several invariants explain why the code is split this way:

- only one canonical `STATE` chain exists per game
- normal turn progression is authored by the current player; rules-defined responder transitions may publish canonical `STATE` without changing turn ownership
- random outcomes must be reproducible from persisted deterministic state
- the canonical state may contain hidden information, but the UI may only expose viewer-safe projections
- transport is a boundary layer, not a rules engine
- canonical `STATE` messages must stay within the payload budget
- every decoded or persisted snapshot must pass canonical hash and terminal-result validation before selection
- game-over state owns one canonical `GameResultV1` with reason and final scores; victory owns roster-ordered winners, while agreed draw and host end own no winners; pending setup, turn, draw, and trade state is absent

These invariants are enforced by code and tests first, then documented in the owner docs.

## Failure Model

The system assumes benign but messy clients rather than hostile peers:

- stale bubble selection is expected
- out-of-order intents are expected
- replay must stay deterministic
- invalid transitions should fail validation rather than partially mutate state

That is why protocol validation, canonical hashing, and anchored intents are core architecture concerns rather than incidental checks.

## Where New Code Should Go

- Add rule logic, legality checks, and canonical-state helpers to `ULS_CoreGame`
- Add envelope/payload/codec work to `ULS_Transport`
- Add UI composition, screen models, and app-extension flows to `MessagesExtension`
- Add product guidance, quality docs, and execution artifacts under `docs/`

If a feature needs the UI to compute legality or hidden-information policy on its own, that is usually a sign the engine surface is incomplete.

## Current Pressure Points

The main architectural pressure is not package shape; it is keeping the growing UI phase from collapsing back into a single monolithic extension file. The next stage should organize `MessagesExtension` internally by feature and presentation responsibility while keeping rules and protocol logic in their current packages.
