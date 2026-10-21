# Reliability publication failure coverage

## Purpose and Outcome

Continue #44 toward the Beta 1.1 candidate by recording failures before Messages handoff: no conversation, envelope encoding, session resolution and message construction. This bounded slice does not finish all eligibility/recovery instrumentation or distribution acceptance.

## Execution Settings

- Validation profile: `standard`
- Delivery posture: `direct`
- Rationale: Settled typed local instrumentation; no UI, rules, protocol or distribution change.

## Context and Boundaries

Preserve all unrelated dirty work and existing publication order/error propagation. Use existing schema allowlist: publication/eligibility/unavailable for missing conversation; publication/encoding/failed for encoding or message construction; recovery/recovery/unavailable for unbound session. These observations never establish receipt or selected-state agreement. No free-form error or new identifier. Existing tutorial/UX exclusions remain. No new UI run; prior UI budget remains exhausted. Candidate remains unfrozen.

## Milestones / Plan of Work

1. Extract a small synchronous preparation observer around existing throwing steps, preserving their errors and order; wire it at sendEnvelope.
2. Test failure at each step, successful sequencing and lack of false handoff/selection evidence; retain bounded report tests and comparator regression.
3. Fresh constraint/privacy review, owner guide update, Release compilation and standard completion gate.

## Verification Contract and Fresh Review

<!-- verification-contract:start -->
| ID | Class | Source | Acceptance | Verification | Evidence | Status | Rationale |
| --- | --- | --- | --- | --- | --- | --- | --- |
| PF-001 | mechanical | #44 | Every preparation failure for a decodable valid-revision game state is classified; original error propagates and later steps do not execute | focused preparation tests and source review | artifact:/tmp/uls-publication-failures-tests.xcresult; report:22 focused tests pass, fresh source review passes | pass | No runtime transport semantics change |
| PF-002 | mechanical | #44 privacy/receipt boundary | Existing allowlist only, fixture exclusion, no fabricated delivery or selection | diagnostic suites, comparator tests, independent privacy review | report:22 Swift and 8 comparator tests pass; fresh privacy review passes | pass | No schema expansion |
| PF-003 | mechanical | AGENTS | Owner docs, Release and standard gate pass | Release build and completion gate | artifact:/tmp/uls-publication-failures-release.log; report:Release passed, standard gate enforced below | pass | No UI change |
<!-- verification-contract:end -->

<!-- fresh-review:start -->
| Reviewer | Required | Verdict | Evidence |
| --- | --- | --- | --- |
| constraint-auditor | yes | pass | report:fresh independent review confirms error/order preservation, typed-only recording, fixture exclusion and no receipt claim |
<!-- fresh-review:end -->

## Living Record

2026-09-23: Exact proof locked before edits: preparation tests plus existing 20 diagnostic tests, 8 comparator tests, source/privacy review, unsigned Release and standard gate. One diagnosed test infrastructure retry only; no UI journey, physical send or upload. Existing report UI proof is unchanged.

## Validation and Outcome

Bounded publication preparation coverage is complete. #44 and integrated physical acceptance remain open.

Fresh source/privacy review passes. Attribution requires a decodable nonnegative-revision state; malformed outbound payloads are not attributed to a guessed game. Coverage guide now records this limit. Eight comparator tests pass; Swift/Release/gate pending.

Focused Swift run passed 22/22 with zero failures in /tmp/uls-publication-failures-tests.xcresult. Existing 20 diagnostic cases plus two new preparation tests (all three failure stages and success) passed on first run. No UI test rerun.

Unsigned Release build passed in /tmp/uls-publication-failures-release.log. Initial contract precheck caught reviewer label requiring the exact constraint-auditor key; corrected the label without changing the passing combined constraint/privacy review. Standard completion gate follows.

Final standard completion gate passed: /tmp/uls-publication-failures-gate.log (contract, harness audit, whitespace, doc freshness, generation and baseline build). Independent reviewer verified raw 22-test and Release logs; focused-suite guide updated after review. Owner docs updated: architecture diagnostics wording and reliability report coverage/validation guide. Rules, protocol, product flow, design and historical docs intentionally unchanged. No UI/device/install/upload proof claimed.
