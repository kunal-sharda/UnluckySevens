# Messages Protocol

This document describes the iMessage-specific game protocol boundary: what gets sent, who is allowed to send it, and which invariants protect the game from desync.

Locked product decisions remain owned by [`../decisions.md`](../decisions.md).

## Two Message Classes

The protocol uses two logical message classes:

- `STATE`
  - authoritative canonical snapshot of the game at a specific revision
- `INTENT`
  - non-authoritative request anchored to a specific base state

The transport layer encodes these through `EnvelopeV1` and the intent payload models in `ULS_Transport`.

## Authority Model

Only the current player may publish a new canonical `STATE`.

Other players are effectively read-only except when they are allowed to send an intent relevant to the current player's turn, such as accepting a trade offer. An intent has no effect unless the current player incorporates it into a later canonical state.

This asymmetric model is deliberate. It reduces desync risk in an async Messages environment where users can open stale bubbles or act from delayed transcript context.

## Revision and Anchor Rules

A canonical state transition is valid only when the usual chain holds:

- `rev == prior.rev + 1`
- `prevHash == prior.stateHash`
- roster is unchanged after the game starts
- actor matches the prior current player

An intent must be anchored to the current canonical base via revision and/or hash. Stale or mismatched intents remain inert.

## Session Strategy

The Messages UX uses two session patterns:

- one `MSSession` per game for canonical `STATE` updates so the main game bubble stays grouped
- a fresh `MSSession` per trade offer so offers appear as distinct bubbles

The protocol source of truth is the message URL payload. Any simulator-only fallback behavior is debug support, not canonical protocol behavior.

## Payload Budget

Canonical `STATE` messages must remain within the payload budget. The repo currently treats `<= 64 KB` as the practical ceiling and has transport regression coverage to guard against budget regressions.

## Secrecy Contract

The canonical state may contain full hidden information for now, but the protocol does not give the UI permission to expose it directly. `MessagesExtension` should render only the viewer-safe summaries provided by `ULS_CoreGame`.

## Failure Model

The protocol assumes benign but messy clients rather than hostile peers:

- stale bubble selection is expected
- out-of-order intents are expected
- replay must stay deterministic
- invalid transitions should fail validation rather than partially mutate state

That is why protocol validation, canonical hashing, and anchored intents are core architecture concerns rather than incidental checks.
