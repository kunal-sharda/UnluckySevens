# Phase UI Hardening — Engine Readiness and Repo Guardrails

## Reconstruction Status

- Backfilled on 2026-03-12.
- Confidence: High.
- Evidence is anchored by commits `b294a21`, `4e490cc`, `bd6ce19`, `1eee9bf`, `68b36f0`, `debc21d`, `4cf8bc1`, `8865f6a`, `17bcbb2`, `f86f297`, and `4c424f3`, plus the `CHANGELOG.md` entries and the current readiness docs.

## Canonical Owner Docs

- [Locked Decisions](../../decisions.md)
- [Engine Readiness Audit](../../quality/audits/2026-03-engine-readiness.md)
- [Architecture](../../../ARCHITECTURE.md)
- [QA](../../quality/qa.md)

## Objective

Pressure-test the engine before phase 10 UI work, close readiness gaps around legality and secrecy ownership, add a practical CI gate, and leave the repo with stronger documentation and eval discipline.

## Starting State

By the end of phase 9, the game engine was functionally broad but still depended on the Messages debug harness for some UI-adjacent logic, lacked repo-level CI, and had limited long-run deterministic match coverage compared with the complexity of the rules.

## Target End State

The repo would have stronger deterministic full-match evals, an explicit readiness audit, practical CI, a split between normal tests and long-run evals, and engine-owned legality/secrecy-safe query helpers so the next UI phase could build on a stable contract.

## Implementation Narrative

### Deterministic full-match eval expansion

- Added scripted multi-player full-match regressions, including non-`A` winner coverage, live violation probes, invariant checks, and additional randomized dev-pressure scenarios.
- Evidence: commits `b294a21`, `bd6ce19`, `1eee9bf`, and `68b36f0`; matching changelog entries.

### Debug harness and transcript-context hardening

- Improved sticky active-context behavior, explicit reload/clear controls, staleness warnings, acting-as simulation, and intent/application affordances inside the Messages debug harness.
- Evidence: commit `4e490cc`; matching changelog entry.

### Audit, payload budget, and QA documentation

- Added engine-readiness, tech-spec, and QA docs, plus a large canonical `STATE` payload-budget regression test.
- Evidence: commit `debc21d`; current docs under `docs/`.

### Repo gate and test/eval split

- Added a minimal GitHub Actions gate mirroring local generation, package tests, evals, and simulator build.
- Split long-running deterministic full-match coverage into `ULS_CoreGameEvals` apart from normal core tests.
- Evidence: commits `4cf8bc1` and `8865f6a`; current `.github/workflows/ci.yml` and `Packages/ULS_CoreGame/Package.swift`.

### UI-readiness closure work

- Moved shared legal-action queries and viewer-scoped secrecy-safe projections into `ULS_CoreGame`, with `MessagesExtension` consuming them.
- Updated readiness docs to conclude the engine was ready for UI.
- Evidence: commit `f86f297`; current `CoreGameViewQueriesV1.swift`, related tests, and `EngineReadinessAudit.md`.

### Repo-structure and guidance cleanup

- Updated README and the then-tracked `AGENTS.md` to align on conceptual structure and test/eval commands, then later removed the tracked `AGENTS.md` again.
- Evidence: commits `17bcbb2` and `4c424f3`.

## Key Files or Subsystems

- `Packages/ULS_CoreGame/Tests/ULS_CoreGameEvals/ScriptedFullMatchesV1Tests.swift`
- `Packages/ULS_CoreGame/Sources/ULS_CoreGame/CoreGameViewQueriesV1.swift`
- `Packages/ULS_CoreGame/Tests/ULS_CoreGameTests/CoreGameViewQueriesV1Tests.swift`
- `.github/workflows/ci.yml`
- `docs/quality/audits/2026-03-engine-readiness.md`
- `ARCHITECTURE.md`
- `docs/quality/qa.md`
- `MessagesExtension/Sources/LobbyDriverViewModel.swift`

## Validation Performed or Evidenced

- The current practical gate in `docs/quality/qa.md` and `.github/workflows/ci.yml` is the direct result of this phase.
- `ULS_CoreGameEvals` provides long-run deterministic scenario coverage.
- The readiness audit documents the reasoning for the final `Ready for UI` verdict.

## What This Enabled Next

This phase converted a broad but debug-oriented engine into something that could support the real UI phase without asking SwiftUI or SpriteKit to become a second rules engine.

## Reconstruction Notes

- Confidence is high because the work is recent and heavily documented.
- The last tracked `AGENTS.md` removal is included as historical fact, not as a recommendation for future docs structure.
- The phase spans both code and process hardening, but the through-line is readiness for phase 10.
