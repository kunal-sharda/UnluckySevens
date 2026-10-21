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
   - message envelope encoding/decoding, canonical `STATE` payload transport, hashing helpers, and payload-size handling; it depends on Core's canonical state schema but no UI framework
3. `MessagesExtension`
   - thin iMessage host lifecycle and resize-shield glue
   - links the static, extension-safe `MessagesExtensionSupport` module that owns transcript selection, message send/receive orchestration, presentation, board rendering, and DEBUG harnesses

The generated app target is a resource-only standalone Messages app bundle that embeds `MessagesExtension`. It exists for installation and TestFlight packaging, but the shipped product surface is only accessible from Messages.

## Dependency Direction

The dependency rule is strict:

- `ULS_CoreGame` depends on no UI framework and owns gameplay truth
- `ULS_Transport` depends on `ULS_CoreGame` state schemas but no UI framework and owns the protocol boundary
- `MessagesExtensionSupport` consumes both packages and compiles the testable extension implementation once
- `MessagesExtension` consumes that static support module and owns only the Apple extension host surface and resize shield

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
- trade acceptance resolution, expiry, and secrecy-safe eligibility queries consumed by presentation
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

The shipping controller reaches support code through one narrow SPI host runtime. Unit tests import the same static support module; they do not recompile selected production source files. The static module is linked into the extension and is not embedded as a second runtime framework.

The compact canonical-state codec is likewise an implementation SPI between Transport and extension support, not an ordinary public product API. Transport remains the codec owner while Core remains the canonical schema and rules owner.

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

Session continuity is an in-memory host adaptation, not canonical persistence. Only a decoded selected same-game session or a cached in-memory `MSSession` may authorize a canonical update; a mismatched or absent session fails closed and never creates a replacement chain. Persisted `MSSession` archival remains prohibited.

Gameplay context is established only by selecting a real game bubble. A valid newer same-game `didReceive` advances that context and the ledger; another game's update is stored without changing the mounted game. The local ledger is a read-only source for Player Record history and statistics, not a gameplay-entry or publication source.

Apple may present a selected Messages bubble using transcript presentation, especially on iPad. That host mounts a compact summary bridge with an explicit **Open Game** request; the full Lobby/Game shells mount only in the normal compact or expanded extension canvas. Transcript presentation is therefore never treated as a scaled gameplay viewport.

The local per-game ledger stores validated canonical snapshots plus device-local player identity and convergence evidence independently of the compact wire representation. Valid snapshots normally use revision then state hash ordering. Core mints a trade-accept branch claim only from a direct Accept snapshot carrying its parent hash, accepted offer hash, responder, revision, and audit prefix. Two claims become contention evidence only when parent hash, offer hash, revision, and audit prefix match. Core then chooses the lexicographically greatest SHA-256 key derived from `(gameId, acceptedAtRev, responderActorID)`; that responder's entire evidenced lineage outranks later descendants of the losing branch. Transcript selection, action authoring, and ledger persistence consume the same Core-owned context. Neither identity nor convergence evidence enters canonical state or transport. Active records persist while only the eight most recently updated finished games are retained.

Lobby branches are the bounded exception to latest-snapshot-only ledger storage. While a game remains in the lobby, Messages retains every valid same-game lobby snapshot as reconciliation evidence. Core traces the selected lobby anchor to its exact genesis and traverses only revision/hash-anchored, self-authored join edges from that lineage; another valid-looking same-game genesis has no authority. The fixed client permits only the original inviter to author the resulting canonical union on the existing game session. With existing local lobby history, a received union must reproduce exactly from the known parent and validated claims. A fresh device may bootstrap a canonically validated current lobby snapshot, without reconstructing unavailable earlier Messages updates; reopening that exact known snapshot is idempotent. This bootstrap does not grant arbitrary snapshots claim authority: reconciliation still traverses only validated anchored edges. Up to 32 out-of-order lobby receipts are held in process-local quarantine and retried when validated evidence arrives; they never become roster truth before validation, and conversation changes clear quarantine. This is cooperative fixed-client authority, not cryptographic sender authentication: Apple's Messages participant UUIDs are device-scoped and cannot prove that a wire actor string was authored by the same person on another device. Evidence never renders as membership or enters Start directly. Existing canonical members keep their seats, remaining seats up to four use descending claim-state-hash priority, and Start accepts only the canonical 3–4-player roster. Once setup is persisted, every later lobby snapshot is rejected before revision/hash selection and cannot recreate evidence or reopen the lobby.

The protocol source of truth is the message URL payload. Pre-TestFlight dev-era summary mirroring, legacy envelopes, and retired transcript debug surfaces are intentionally unsupported on the current branch.

## Invariants That Shape the Codebase

Several invariants explain why the code is split this way:

- only one canonical `STATE` chain exists per game
- concurrent lobby joins converge through a Core-produced, host-published canonical union; local branch evidence is never a second roster truth
- concurrent valid sibling trade Accept states converge by Core-owned deterministic lineage preference when clients use the fixed build and observe both direct same-parent/same-offer Accept snapshots; audit resemblance alone, message-arrival order, and protocol additions are not authority
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

The extension now has explicit host, support, feature, presentation, board, recovery-policy, and DEBUG-harness seams. `LobbyDriverViewModel` and `GameShellView` intentionally remain orchestration/state-owner facades; further splits should be driven by independently testable responsibilities, not line count. The remaining render-path work is tracked in TD-007 and should not move rules or transport authority into presentation code.

## Local reliability diagnostics foundation

`MessagesExtension/Sources/Diagnostics/ReliabilityDiagnosticBuffer.swift` owns a typed, in-memory reliability buffer and single-game JSON export projection. Its companion `ReliabilityDiagnosticStore.swift` provides single-owner, device-local persistence in a caller-supplied private directory. A main-actor `ReliabilityDiagnostics` owner now connects validated decoded state selection and local preparation/send completion to that store; storage errors cannot throw into gameplay. Tutorial and DEBUG UX fixture events are excluded. There is no networking. Records use domain-separated SHA-256 game correlation (not actor credentials), game-scoped state digests, revision, timestamp/sequence, typed trigger/session-presence and allowlisted action/boundary/outcome/membership categories; raw IDs, names, hands, trade contents and free-form errors have no schema fields. Retention is 128 records with 24-hour expiry pruned on append/export, a 64-KiB export ceiling and explicit clear. Idle memory is not erased by a timer. This buffer is never canonical state or evidence of remote delivery. Storage uses a versioned typed snapshot, bounded reads and atomic writes, file protection and backup exclusion. Reopen validates version, count, sequence ordering and correlation format; malformed or oversized data is discarded, and expired/future entries are pruned and rewritten. Storage failures are typed and leave the in-memory buffer usable; failed clear does not promise durable deletion. The production directory is private Application Support/Reliability. `ReliabilityReport` projects one game into schema-v2 immutable JSON with binary/OS metadata and a whole-report 64-KiB cap. Settings previews those exact bytes and explicitly exports through the system file picker. Candidate metadata defaults to unfrozen; it is not a claim of signing/distribution. The offline comparator requires fresh active decoded-state evidence, not local send callbacks; account independence is operator-attested. Full boundary instrumentation and paired-device/export proof remain #44. See [reliability reports](docs/quality/reliability-reports.md) for scope, privacy and commands.

### Beta 1.1 victory and publication correctness

Core evaluates the current player's buildings, awards and all owned VP cards (including cards bought this turn) for immediate victory. Public standings still omit unrevealed cards. Terminalization reveals only the winner's VP cards. Turn entry and resignation handoff use the resulting current player; canonical winning transitions must exactly replay a legal Core turn or lifecycle intent. Decoding an old snapshot never rewrites it: an explicit winning claim or next current-player action publishes the terminal transition.

Ordinary lobby/setup/turn/lifecycle publications stage a snapshot until the Messages send callback accepts the local handoff. Failure discards the staged snapshot, allowing the original action to be retried. Only one publication can be in flight; conversation changes invalidate its callback, including lobby reconciliation. Reconciliation callbacks preserve a newer persisted state, cannot reopen another selected game, and drain newly observed join claims after an accepted handoff. A late accepted snapshot is recorded but cannot replace a preferred received state or reopen another selected game. The player-triggered resend republishes the validated latest known snapshot unchanged in the existing bound session; it does not advance revision, reroll or execute an intent. Messages acceptance is not remote delivery evidence.
