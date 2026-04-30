# Audit Index

This directory stores dated audit evidence. Audits are useful for reconstruction, but they are not owner docs and should not override code, tests, `docs/decisions.md`, `ARCHITECTURE.md`, product specs, QA, or the active ExecPlan.

## Current Readiness Audits

- [2026-04-27 Pre-TestFlight Repo Cleanup Audit](./2026-04-27-pre-testflight-repo-cleanup-audit.md): current repo cleanup and legacy-support cutoff.
- [2026-04-26 Pre-TestFlight Basic Feature Audit](./2026-04-26-pre-testflight-basic-feature-audit.md): current basic feature polish audit.

## Historical Evidence

These files should be read as dated snapshots. They may describe problems or compatibility paths that have since been removed.

- [2026-04-19 Legacy Code Audit](./2026-04-19-legacy-code-audit.md)
- [2026-04-16 Base Catan Feature Matrix](./2026-04-16-base-catan-feature-matrix.md)
- [2026-04-16 Phase Boundary Audit](./2026-04-16-phase-boundary-audit.md)
- [2026-04-16 Phase 13 Validation Audit](./2026-04-16-phase-13-validation-audit.md)
- [2026-04-13 Transport Reliability](./2026-04-13-transport-reliability.md)
- [2026-04-12 Render Performance](./2026-04-12-render-performance.md)
- [2026-03 Engine Readiness](./2026-03-engine-readiness.md)

## Cleanup Rule

When an audit becomes stale, prefer adding a short supersession note or updating this index over rewriting historical evidence. Move durable lessons into [../qa.md](../qa.md), durable debt into [../../exec-plans/tech-debt-tracker.md](../../exec-plans/tech-debt-tracker.md), and current product behavior into the owner docs.
