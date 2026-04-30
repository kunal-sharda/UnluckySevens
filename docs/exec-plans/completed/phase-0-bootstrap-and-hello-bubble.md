# Phase 0 — Bootstrap and Hello Bubble

## Reconstruction Status

- Backfilled on 2026-03-12.
- Confidence: Medium.
- This plan is reconstructed primarily from `docs/exec-plans/CHANGELOG.md`, the current repo layout, and the surviving early debug transport code. Commit-level evidence for the stage 0 work is incomplete.

## Canonical Owner Docs

- [Locked Decisions](../../decisions.md)
- [Architecture](../../../ARCHITECTURE.md)
- [QA](../../quality/qa.md)

## Objective

Establish a working Tuist-based iMessage app skeleton, prove the Messages extension can send and decode a transcript bubble, and harden the local simulator loop enough to support later game-engine work.

## Starting State

The repo did not yet have a stable generated project, package layout, or a verified message-send/decode loop inside Messages. Simulator-specific selection issues were already known risk.

## Target End State

A generated host app plus Messages extension existed, `ULS_CoreGame` and `ULS_Transport` packages were present, and the extension could send a debug bubble, reselect it, and decode a transport payload reliably enough to unblock phase 1 protocol work.

## Implementation Narrative

### Stage 0.A — Repository bootstrap

- Added the baseline repo scaffolding for Tuist, packages, scripts, and top-level project files.
- Evidence: `docs/exec-plans/CHANGELOG.md` entries for stage 0.A covering bootstrap scaffolding, `scripts/gen.sh`, `scripts/clean.sh`, `.gitignore`, `README.md`, and `Makefile`.

### Stage 0.B — Generated app and package shell

- Introduced Tuist manifests and the minimal host app plus Messages extension wiring.
- Added stub `ULS_CoreGame` and `ULS_Transport` packages so later logic could land behind package boundaries from day one.
- Evidence: `docs/exec-plans/CHANGELOG.md` stage 0.B entries and the current descendants in `Project.swift`, `Workspace.swift`, `Tuist.swift`, `App/`, and `Packages/`.

### Stage 0.C — Hello Bubble loop

- Implemented a debug payload codec and a first end-to-end bubble flow through Messages.
- The extension could send a debug bubble, select it again, and decode payload metadata in-app.
- Evidence: `docs/exec-plans/CHANGELOG.md` stage 0.C entries and current `ULS_Transport/Sources/ULS_Transport/DebugPayload.swift` plus `MessagesExtension/Sources/MessagesViewController.swift`.

### Stage 0.C.1 — Observability hardening

- Added send, selection, and decode status to make the simulator loop debuggable.
- Added retry polling for delayed `selectedMessage` visibility and richer bubble metadata.
- Evidence: `docs/exec-plans/CHANGELOG.md` stage 0.C.1 entries.

### Stage 0.C.2 — Simulator fallback and payload terminology cleanup

- Added fallback decode from `summaryText` when simulator selection omitted `selectedMessage.url`.
- Renamed the user-facing payload field from `nonce` to `debugId` with backward-compatible decoding.
- Evidence: `docs/exec-plans/CHANGELOG.md` stage 0.C.2 entries and current `DebugPayload` fields/tests.

## Key Files or Subsystems

- `Project.swift`, `Workspace.swift`, `Tuist.swift`
- `scripts/gen.sh`, `scripts/clean.sh`
- `MessagesExtension/Sources/MessagesViewController.swift`
- `Packages/ULS_Transport/Sources/ULS_Transport/DebugPayload.swift`
- `Packages/ULS_Transport/Tests/ULS_TransportTests/ULS_TransportTests.swift`

## Validation Performed or Evidenced

- Transport roundtrip and invalid-decode tests existed by the end of the phase.
- The current README smoke-check flow still reflects the outcome of this work, especially the debug bubble send/select/decode loop.
- Evidence is strongest in `docs/exec-plans/CHANGELOG.md` and the surviving transport tests, not in preserved active plans.

## What This Enabled Next

Phase 0 made it possible to build the real message protocol and canonical state model against a working Messages transcript loop instead of building blind.

## Reconstruction Notes

- Confidence is lower than later phases because stage 0 work is represented mainly in the changelog rather than surviving phase-labeled commits.
- The exact sequencing between 0.B and 0.C is inferred from changelog order and current file descendants.
- The simulator fallback later became a temporary/local concern rather than the canonical transport path.
