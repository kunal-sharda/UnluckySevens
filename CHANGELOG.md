# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Stage 0.A bootstrap scaffolding for `Tuist/`, `App/`, `MessagesExtension/`, `Packages/`, and `scripts/`.
- Stage 0.A developer scripts: `scripts/gen.sh` and `scripts/clean.sh`.
- Stage 0.A repository baseline files: `.gitignore`, `README.md`, and `Makefile`.
- Stage 0.B Tuist manifests (`Tuist.swift`, `Workspace.swift`, `Project.swift`) for iOS 17+ app and Messages extension generation.
- Stage 0.B minimal Messages extension view controller showing the centered label `Unlucky Sevens — Stage 0`.
- Stage 0.B SwiftPM stub libraries (`ULS_CoreGame`, `ULS_Transport`) with one baseline unit test each.
- Stage 0.C Hello Bubble loop: Messages extension can send a debug bubble and decode selected bubble payload fields.
- Stage 0.C transport debug payload codec (`DebugPayload`, base64url encode/decode) implemented in `ULS_Transport`.
- Stage 0.C transport tests added for roundtrip, invalid base64url handling, and payload size sanity.
- Stage 0.C.1 observability hardening in Messages extension: explicit send/selection/decode status, lifecycle retry polling for selected message reads, and richer transcript bubble metadata.
- Stage 0.C.1 transport regression test for unsupported payload version decode handling.
- Stage 0.C.2 Simulator fallback: when `selectedMessage.url` is missing, decode attempts now fall back to payload embedded in message `summaryText`.
- Stage 0.C.2 terminology cleanup: user-facing `nonce` renamed to `debugId` with backward-compatible decoding for legacy payloads.
- Stage 1.1 Transport v1: added `EnvelopeV1` (`STATE`/`INTENT`) with reusable base64url JSON encode/decode APIs.
- Stage 1.1 added `TransportError` (`emptyPayload`, `invalidBase64URL`, `invalidJSON`, `unsupportedVersion`) and encoded size helpers.
- Stage 1.1 added transport unit tests for envelope roundtrip, invalid decode cases, and encoded size sanity.
- Stage 1.2 CoreGame v1 kernel: added `CoreGameStateV1`, `PhaseV1`, deterministic canonical SHA-256 state hashing, and `rehashed()` support.
- Stage 1.2 added transition validator `validateTransition(from:to:actor:)` with strict rev/prevHash/actor/roster/gameId/stateHash checks.
- Stage 1.2 added CoreGame tests for golden hash, valid transition, and per-rule transition validation failures.
- Stage 1.3 Lobby flow UI stub: added SwiftUI lobby driver in `MessagesExtension` with Invite, Join, Record Join, Start Game, and Clear Pending Joins actions.
- Stage 1.3 added `JoinIntentV1` transport payload model for anchored `INTENT(join)` messages.
- Stage 1.3 updated CoreGame v1 state with `seed` and lobby-to-setup transition handling that permits roster/seed changes only for Start.
- Stage 1.3 added/updated Transport and CoreGame tests for join intent roundtrip, seed-aware hashing, and start-transition validation rules.
- Stage 2.1 added deterministic SplitMix64 RNG (`DeterministicRNG`) with deterministic d6 and 2d6 helpers.
- Stage 2.1 added domain-separated seed derivation (`SeedDomain`, `SeedDeriver`) for board, dice, dev deck, and robber streams.
- Stage 2.1 extended `CoreGameStateV1` with persisted `diceRngState` and included it in canonical state hashing.
- Stage 2.1 updated lobby Start flow to initialize `diceRngState` from the derived dice domain seed.
- Stage 2.1 added CoreGame test coverage for RNG golden sequence, seed derivation golden vectors, dice state hashing, and transition behavior.
- Stage 2.2 added `BoardGraphV1` board topology model types (`TileV1`, `EdgeV1`, `PortV1`, `PortKindV1`) with typed IDs and adjacency helper APIs.
- Stage 2.2 added deterministic `StandardBoardTopologyV1.standard()` generation for standard Catan geometry (19 tiles, 54 nodes, 72 edges, 9 ports, robber placeholder).
- Stage 2.2 added canonical-frame port placement over perimeter-derived frame slots with deterministic edge selection.
- Stage 2.2 added board graph test coverage for topology counts, ID validity, node degrees, edge/tile adjacency rules, and port constraints.
- Stage 2.3 added deterministic board setup models (`BoardRulesV1`, `BoardSetupV1`) with canonical SHA-256 `boardHash`.
- Stage 2.3 added strategy-based board generation (`randomV1`, `noRedAdjacentV1`) and Start integration to persist board rules/setup in `CoreGameStateV1`.
- Stage 2.3 added CoreGame validation rules that restrict board and board-rule changes to lobby->setup Start transitions only.
- Stage 2.3 added Messages lobby driver board strategy selection plus text-only Board Debug output for decoded state messages.
- Stage 2.3 added CoreGame test coverage for board generation goldens/distributions and board transition invariants.
- Stage 2.3 follow-up: canonical STATE messages now reuse a per-game `MSSession` while INTENT messages use fresh sessions.
- Stage 2.3 follow-up: removed payload mirroring into `summaryText`; extension now decodes only from message URL payloads.
- Stage 2.3 follow-up: transition validation now rejects mismatched `BoardSetupV1.boardHash` values.
- Stage 2.3 follow-up: strengthened random board strategy test to assert unconstrained generation can produce adjacent 6/8 tiles.
- Stage 3.1 added setup state machine models (`SetupStateV1`, `SetupStepV1`, `PlayerSetupPlacementsV1`) and deterministic snake-order initialization helpers.
- Stage 3.1 added a pure setup reducer (`apply(intent:to:actor:)`) for settlement/road sequencing and setup completion to turn phase.
- Stage 3.1 added setup placement transport payload model (`SetupPlacementIntentV1`) for anchored setup INTENT bubbles.
- Stage 3.1 updated lobby Start flow to initialize `setupState` and added setup debug intent buttons (`Place Settlement`, `Place Road`) in Messages UI.
- Stage 3.1 added CoreGame and Transport test coverage for setup sequencing/validation and setup intent roundtrips.
- Stage 3.2 setup placement legality: settlement distance rule and setup-road adjacency to the just-placed settlement.
- Stage 3.2 setup placement legality now validates node/edge bounds and enforces occupied node/edge rejection from setup placements.
- Stage 3.2 added runtime-topology CoreGame tests for distance, adjacency, and occupancy legality during setup.
