# Validation Circuit Breaker

## Purpose and Outcome

Prevent focused UI validation from turning into silent, open-ended proof expansion. Success means agents lock proof before implementation, distinguish production failures from harness instability, stop after a bounded retry budget, and update the user before expanding scope.

## Execution Settings

- Validation profile: `lightweight`
- Delivery posture: `direct`
- Rationale: This is a narrow, explicitly requested documentation-only harness correction with no product, runtime, or protocol change.

## Context and Boundaries

- [QA](../../quality/qa.md) owns validation execution and retry behavior.
- [Constraint verification](../../quality/constraint-verification.md) owns evidence and reviewer boundaries.
- [ExecPlan rules](../PLANS.md) own plan maintenance and scope changes.
- [AGENTS.md](../../../AGENTS.md) remains the concise agent entrypoint and links to the owner rules.
- Product code, tests, simulator fixtures, and validation command implementation are out of scope.

## Milestones / Plan of Work

1. Add a bounded validation circuit breaker and clean-evidence rules to QA.
2. Add matching contract/reviewer scope rules and concise agent/plan entrypoint enforcement.
3. Run the documentation and harness checks, then report the already-passed device run without starting another product-validation loop.

## Verification Contract and Fresh Review

<!-- verification-contract:start -->
| ID | Class | Source | Acceptance | Verification | Evidence | Status | Rationale |
| --- | --- | --- | --- | --- | --- | --- | --- |
| VCB-001 | mechanical | user request | QA defines locked proof, a bounded retry budget, failure classification, and a stop/report rule | source inspection and harness audit | file:docs/quality/qa.md; command:make-harness-audit | pass | QA now limits a journey to the initial attempt plus two reruns and requires stop/classify/report behavior |
| VCB-002 | mechanical | user request | Reviewer and plan rules prevent silent validation-driven scope expansion and separate exploratory failures from final proof | source inspection and harness audit | file:docs/quality/constraint-verification.md; file:docs/exec-plans/PLANS.md; file:AGENTS.md | pass | Contract amendments require a source and user update; clean final evidence is separated from diagnostics |
| VCB-003 | mechanical | AGENTS.md | Doc freshness, diff hygiene, and the structural harness audit pass | prescribed repository commands | command:make-doc-freshness; command:git-diff-check; command:make-harness-audit | pass | All three checks passed on 2026-08-04 |
<!-- verification-contract:end -->

<!-- fresh-review:start -->
| Reviewer | Required | Verdict | Evidence |
| --- | --- | --- | --- |
| constraint-auditor | no | not-applicable | Lightweight docs-only harness correction with deterministic checks |
| architecture | no | not-applicable | No runtime or module-boundary change |
| behavioral | no | not-applicable | No product behavior change |
| product-ux | no | not-applicable | No player-facing UI change |
<!-- fresh-review:end -->

## Living Record

### Progress

- 2026-08-04: Locked `lightweight` validation and `direct` delivery before editing owner docs.
- 2026-08-04: Added the circuit breaker to QA, reviewer/evidence boundaries to constraint verification, plan amendment rules to PLANS, and concise enforcement at the AGENTS entrypoint.

### Decisions

- 2026-08-04: A validation failure may expand implementation only when it demonstrates a production defect or a sourced verification-contract gap. Harness instability stops at the retry budget and is reported.

### Discoveries

- 2026-08-04: Existing docs bound visual feedback rounds but did not bound repeated simulator/XCUITest retries after implementation, nor explicitly separate exploratory failed bundles from final evidence.

## Validation and Outcome

- Automated: `make harness-audit` passed; `make doc-freshness` passed; `git diff --check` passed.
- Product/runtime: intentionally not run because this slice changes documentation-only harness policy.
- Judgment: not triggered; the user explicitly approved the rule set before implementation.
- Completion: `make completion-gate PLAN=docs/exec-plans/completed/validation-circuit-breaker.md` passed on 2026-08-04.
- Remaining: none for this harness correction.
