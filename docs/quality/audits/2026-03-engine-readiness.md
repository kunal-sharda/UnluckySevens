# Engine Readiness Audit

Date: 2026-03-06

Verdict: `Ready for UI`

Follow-up (2026-03-07): `.github/workflows/ci.yml` now runs the practical gate on `pull_request` and pushes to `master`/`main`. `ULS_CoreGame` now owns shared legal-action queries and viewer-scoped secrecy-safe projections in `CoreGameViewQueriesV1.swift`, with `MessagesExtension` consuming those helpers. This closes the three original readiness caveats below.

## Summary

The engine is in good shape for the next stage. The audited surface shows strong deterministic rule enforcement, clear authority semantics, and unusually deep package-level test coverage for a side-project iMessage game.

No `P0` engine-correctness failures were found in the audited MVP surface. The original caveats around `UI attachment risk` and `operational guardrails` are now closed.

## Audit Method

Source-of-truth order used for this pass:

1. Code and tests
2. `docs/decisions.md`
3. `docs/UnluckySevensPRD.pdf`

Audited areas:

- `ULS_CoreGame` reducer, validation, state, economy, awards, victory, and setup flow
- `ULS_Transport` envelope and intent transport boundary
- `MessagesExtension` only where it affects correctness, secrecy, or UI-readiness

Validation steps performed during this pass:

- `swift test` in `Packages/ULS_CoreGame`
- `swift test` in `Packages/ULS_Transport`
- `bash ./scripts/gen.sh`
- `xcodebuild -workspace /Users/kunalsharda/Documents/Code/UnluckySevens/UnluckySevens.xcworkspace -scheme MessagesExtension -destination 'generic/platform=iOS Simulator' build`

## Rule / Readiness Matrix

| Area | Engine status | Coverage status | Readiness note |
| --- | --- | --- | --- |
| Setup order, placement legality, starting resources | Implemented in pure core reducers and validation | Strong | Ready |
| Turn sequencing, dice, production, robber, discard, steal | Implemented in reducer and transition validation | Strong | Ready |
| Domestic trade and end-turn expiry | Implemented with anchored accepts and execution | Strong | Ready |
| Maritime trade and best-ratio enforcement | Implemented and validated | Strong | Ready |
| Development cards, awards, victory | Implemented and tested | Strong | Ready |
| Determinism, state hashing, replay | Core strength of the current design | Strong | Ready |
| Canonical STATE payload budget | Transport helpers existed; realistic regression guard was missing | Closed in this pass | Ready |
| UI legal-action derivation | Shared helper API now lives in `ULS_CoreGame` and is consumed by `MessagesExtension` | Strong | Ready |
| Secrecy-safe presentation contract | Shared viewer-scoped projections now live in `ULS_CoreGame` | Strong | Ready |
| CI / automated gate outside local machine | GitHub Actions practical gate is present for PRs and branch pushes | Strong | Ready |

## Findings

### Closed P1: Legal-action derivation was UI-owned instead of engine-owned

- Status: closed on 2026-03-07 by `Packages/ULS_CoreGame/Sources/ULS_CoreGame/CoreGameViewQueriesV1.swift` and `MessagesExtension/Sources/LobbyDriverViewModel.swift`
- Impacted code: `MessagesExtension/Sources/LobbyDriverViewModel.swift`
- Examples: `firstLegalRoadEdge`, `firstLegalSettlementNode`, `defaultRoadBuildingEdges`, `defaultMaritimeTrade`, `defaultTradeProposal`
- Why it matters: the next real UI will either duplicate rules or depend on debug-harness heuristics. That creates rule drift risk even if the reducer remains correct.
- Required fix shape: add pure `ULS_CoreGame` helpers for legal-action queries and readiness summaries; keep the UI as a consumer, not a second rules engine.
- Required automated tests: helper-query tests that compare exposed legal actions against reducer acceptance/rejection.
- Required manual QA scenario: verify every enabled UI affordance succeeds when applied, and every disabled affordance maps to a reducer rejection if forced.

### Closed P2: Secrecy-safe projection was implemented in UI glue, not as a shared contract

- Status: closed on 2026-03-07 by `Packages/ULS_CoreGame/Sources/ULS_CoreGame/CoreGameViewQueriesV1.swift` and projection coverage in `ULS_CoreGameTests`
- Impacted code: `MessagesExtension/Sources/LobbyDriverViewModel.swift`
- Examples: `visibleHandsSummary`, `visibleDevCardsSummary`
- Why it matters: the current MVP allows full hands in canonical state, so secrecy depends entirely on presentation discipline. A future UI can leak by accident if it does not reuse a single shared projection rule.
- Required fix shape: add a pure presentation/projection helper layer that takes canonical state plus local actor and returns secrecy-safe summaries.
- Required automated tests: projection tests asserting local detail and opponent count-only rendering for both resources and dev cards.
- Required manual QA scenario: switch local actor and verify opponent hands/dev cards never show composition in any screen or recap.

### Closed P2: Engine quality was enforced locally, not at repo gate level

- Status: closed on 2026-03-07 by `.github/workflows/ci.yml`
- Impacted code: repo process; no CI workflow is present
- Why it matters: the engine is good enough that future regressions are more likely to come from incremental changes than from the current base. Without a gate, the repo relies on manual discipline.
- Required fix shape: add a minimal CI lane for generate, package tests, and simulator build.
- Required automated tests: CI itself should run the existing commands plus the payload-budget guard added in this pass.
- Required manual QA scenario: after CI lands, verify a PR-sized change still runs the same local commands successfully.

## Closed During This Pass

- Added a transport regression test for a large canonical STATE envelope and roundtrip decode.
- Added shared `ULS_CoreGame` view/query helpers for legal default actions and viewer-scoped secrecy-safe projections, plus focused core tests for those helpers.
- Verified the current engine/test/build baseline is green.

## Verdict Rationale

Why this is not `Not ready`:

- Reducer, validator, and deterministic replay coverage are already strong.
- The engine enforces core Catan MVP rules in a way that is unusually disciplined for a side project.
- No critical gameplay-correctness breakage was found in the audited surface.

Why this is now `Ready for UI`:

- The reducer, validator, and deterministic replay coverage remain strong.
- Legal-action derivation and secrecy-safe projections now live in shared pure-core helpers instead of `MessagesExtension`.
- The repo now has a repeatable GitHub Actions practical gate that mirrors the local baseline.

## Deferred / Non-MVP PRD Items

These were intentionally not treated as readiness blockers because they are not part of the locked MVP contract:

- board fairness toggles beyond current strategy support
- friendly robber
- timeout / 12-hour stale trades
- scenario maps / rerolls / AI / 2-player mode
- analytics, Crashlytics, cosmetics, monetization
- anti-tamper signatures beyond the current friends-only trust model
