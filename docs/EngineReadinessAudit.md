# Engine Readiness Audit

Date: 2026-03-06

Verdict: `Ready with caveats`

## Summary

The engine is in good shape for the next stage. The audited surface shows strong deterministic rule enforcement, clear authority semantics, and unusually deep package-level test coverage for a side-project iMessage game.

No `P0` engine-correctness failures were found in the audited MVP surface. The remaining caveats are about `UI attachment risk` and `operational guardrails`, not obvious rules-engine breakage.

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
| UI legal-action derivation | Partly lives in `MessagesExtension` instead of `ULS_CoreGame` | Weak | Caveat |
| Secrecy-safe presentation contract | Present in current UI glue, not shared as a reusable engine-facing projection | Weak | Caveat |
| CI / automated gate outside local machine | No repo-level CI workflow yet | Weak | Caveat |

## Findings

### P1: Legal-action derivation is still UI-owned instead of engine-owned

- Impacted code: `MessagesExtension/Sources/LobbyDriverViewModel.swift`
- Examples: `firstLegalRoadEdge`, `firstLegalSettlementNode`, `defaultRoadBuildingEdges`, `defaultMaritimeTrade`, `defaultTradeProposal`
- Why it matters: the next real UI will either duplicate rules or depend on debug-harness heuristics. That creates rule drift risk even if the reducer remains correct.
- Required fix shape: add pure `ULS_CoreGame` helpers for legal-action queries and readiness summaries; keep the UI as a consumer, not a second rules engine.
- Required automated tests: helper-query tests that compare exposed legal actions against reducer acceptance/rejection.
- Required manual QA scenario: verify every enabled UI affordance succeeds when applied, and every disabled affordance maps to a reducer rejection if forced.

### P2: Secrecy-safe projection is implemented in UI glue, not as a shared contract

- Impacted code: `MessagesExtension/Sources/LobbyDriverViewModel.swift`
- Examples: `visibleHandsSummary`, `visibleDevCardsSummary`
- Why it matters: the current MVP allows full hands in canonical state, so secrecy depends entirely on presentation discipline. A future UI can leak by accident if it does not reuse a single shared projection rule.
- Required fix shape: add a pure presentation/projection helper layer that takes canonical state plus local actor and returns secrecy-safe summaries.
- Required automated tests: projection tests asserting local detail and opponent count-only rendering for both resources and dev cards.
- Required manual QA scenario: switch local actor and verify opponent hands/dev cards never show composition in any screen or recap.

### P2: Engine quality is enforced locally, not at repo gate level

- Impacted code: repo process; no CI workflow is present
- Why it matters: the engine is good enough that future regressions are more likely to come from incremental changes than from the current base. Without a gate, the repo relies on manual discipline.
- Required fix shape: add a minimal CI lane for generate, package tests, and simulator build.
- Required automated tests: CI itself should run the existing commands plus the payload-budget guard added in this pass.
- Required manual QA scenario: after CI lands, verify a PR-sized change still runs the same local commands successfully.

## Closed During This Pass

- Added a transport regression test for a large canonical STATE envelope and roundtrip decode.
- Verified the current engine/test/build baseline is green.

## Verdict Rationale

Why this is not `Not ready`:

- Reducer, validator, and deterministic replay coverage are already strong.
- The engine enforces core Catan MVP rules in a way that is unusually disciplined for a side project.
- No critical gameplay-correctness breakage was found in the audited surface.

Why this is not fully `Ready for UI` yet:

- The next UI stage will need shared engine-derived queries rather than continuing to reimplement move legality in the extension layer.
- Secrecy-safe presentation rules should be shared, not left as ad hoc UI logic.
- The new payload-size regression covers one key product constraint, but the repo still lacks a repeatable CI gate.

## Deferred / Non-MVP PRD Items

These were intentionally not treated as readiness blockers because they are not part of the locked MVP contract:

- board fairness toggles beyond current strategy support
- friendly robber
- timeout / 12-hour stale trades
- scenario maps / rerolls / AI / 2-player mode
- analytics, Crashlytics, cosmetics, monetization
- anti-tamper signatures beyond the current friends-only trust model
