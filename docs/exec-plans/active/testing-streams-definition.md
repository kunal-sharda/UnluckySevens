# One-Device and Two-Device Testing Routes

> Current execution: [Beta 1.1 testing and candidate delivery](testing-streams-implementation.md). The 2026-09-28 owner decision supersedes second-automated-device gating and separates diagnostic candidate distribution from final milestone acceptance. This definition remains a technical reference.

## Purpose and Outcome

Define separate testing routes for routine local validation and real cross-account Messages proof, accommodating one home iPad and a second device that may be remote. This slice documents routing; it does not build or claim a physical-device automation runner.

## Execution Settings

- Validation profile: `lightweight`
- Delivery posture: `direct`
- Rationale: Bounded documentation clarification using existing commands; no acceptance criteria or hardware proof are waived.

## Context and Boundaries

User approved two testing streams on 2026-09-13. QA owns routing and device-runbooks owns operator steps. Existing simulator scripts stay simulator-only. Two local physical devices enable a future automation feasibility test; remote TestFlight participants act manually. Three-account concurrency remains separate required evidence.

## Milestones / Plan of Work

1. Document the two routes, capability status, exact-build evidence, and limits.
2. Link the routing from the delivery program.
3. Inspect documentation consistency and run the lightweight completion gate.

## Verification Contract and Fresh Review

<!-- verification-contract:start -->
| ID | Class | Source | Acceptance | Verification | Evidence | Status | Rationale |
| --- | --- | --- | --- | --- | --- | --- | --- |
| TS-001 | mechanical | user request | One-device and two-device routes distinguish available simulator/manual testing from unproven hardware automation | Inspect QA and device runbook | report:QA and runbook inspected; existing command paths verified; hardware automation explicitly unproven | pass | No new runtime capability claimed |
| TS-002 | mechanical | existing verification contracts | Exact build, TestFlight provenance, two-account requirements, and three-account concurrency limits remain explicit | Cross-check program and child-plan constraints | report:Program and lobby/trade constraints cross-checked; three-account and exact-build limits retained | pass | No waiver of device evidence |
<!-- verification-contract:end -->

<!-- fresh-review:start -->
| Reviewer | Required | Verdict | Evidence |
| --- | --- | --- | --- |
| constraint-auditor | no | not-applicable | Optional lightweight documentation review |
<!-- fresh-review:end -->

## Living Record

- 2026-09-13: Locked lightweight/direct; exact proof set is document inspection, referenced-command existence, doc freshness, and completion gate. No device interactions, uploads, test runs, or scheduling are part of this definition slice.

## Validation and Outcome

QA and device runbook now define both routes; delivery program links them. Documentation/command-path inspection passed. Product, architecture, and locked gameplay decisions remain unchanged. Older runbook checklist drift is explicitly flagged for targeted correction before implementing new journeys; no historical source was rewritten. No automation runner, device test, or scheduled job was created.

Lightweight completion gate passed on 2026-09-13, including contract verification, harness audit, whitespace check, and doc freshness. No gameplay or physical-device tests were run.

Executable tooling is tracked separately in [testing-streams-implementation.md](testing-streams-implementation.md); this definition slice remains historical evidence for route scope.
