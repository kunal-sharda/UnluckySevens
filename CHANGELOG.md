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
