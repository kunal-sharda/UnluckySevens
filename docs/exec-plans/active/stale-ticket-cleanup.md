# Stale Ticket Cleanup

## Purpose and Outcome

Correct stale issue descriptions against shipped Build 1.0 (8), frozen source 673813f, and later local work. Review the open backlog for duplicate ownership without discarding pending evidence or making release commitments.

## Execution Settings

- Validation profile: `lightweight`
- Delivery posture: `direct`
- Rationale: Tracking and execution-record corrections only; no runtime changes.

## Context and Boundaries

User authorized corrections and duplicate review on 2026-09-10. Build provenance is recorded in the seven-lane program and completed first-friends release plan. Preserve issue milestones, existing valid acceptance criteria, and unrelated working-tree changes. Do not close implemented-but-unverified tickets as finished.

## Milestones / Plan of Work

1. Correct #4/#6/#7/#11/#15/#38 and review overlap across all 45 open issues.
2. Clarify shared verification ownership and repair stale learning parent links.
3. Read back exact edited issue bodies/titles and check unchanged milestones/status; run the lightweight completion gate.

## Verification Contract and Fresh Review

<!-- verification-contract:start -->
| ID | Class | Source | Acceptance | Verification | Evidence | Status | Rationale |
| --- | --- | --- | --- | --- | --- | --- | --- |
| ST-001 | mechanical | user request; Build 8 provenance | Six stale candidates distinguish shipped capability, local implementation, and pending proof without false closures | Source/plan comparison and exact issue readback | report:Build 8 source and child-plan comparison; exact GitHub readback of six candidates | pass | Preserve unresolved acceptance |
| ST-002 | mechanical | user duplicate-check request | Review covers all 45 open issues; overlapping deliverables have explicit owners and learning children link to existing epic | Backlog inspection and issue readback | report:45-issue purpose/acceptance review and exact 12-issue readback; all states/milestones preserved | pass | Epics and shared evidence are not duplicate implementation |
<!-- verification-contract:end -->

<!-- fresh-review:start -->
| Reviewer | Required | Verdict | Evidence |
| --- | --- | --- | --- |
| constraint-auditor | no | not-applicable | Optional lightweight tracking review |
<!-- fresh-review:end -->

## Living Record

- 2026-09-10: Locked lightweight/direct. Exact proof: source/record comparison, GitHub title/body/milestone/state readback, scoped doc inspection, completion gate/doc freshness. No gameplay tests are implied by this tracking slice.

## Validation and Outcome

Updated #4/#6/#7/#11/#15/#38; clarified #2/#8 evidence ownership and #23-#26 learning links. All 45 open tickets were reviewed for purpose and overlapping acceptance. No whole-ticket duplicates or fully verified closure candidates were established.

Overlap audit: #2/#7/#8/#43 cover broad host proof, focused session continuity, integrated validation, and missing-update recovery respectively; #6/#11 separate competing-accept convergence from eligibility; #13/#14 reuse purchase-cost presentation while the latter owns the card lifecycle; #22/#42 share redundant identity cues while audit coverage and seat orientation remain distinct; #19 public scores and #42 seat identity require a joint composition decision, not duplicate rosters; #20/#46 separate target implementation from pacing discovery; #24-#26 are children of #23; #27-#29 coordinate children rather than implementing their features twice; #30/#31/#34/#35 explicitly exclude the early #44 slice; #32/#36/#37 separate account implementation, invitation UI, and architecture decision; #33/#39 separate display profiles from actor credentials; #9/#41/#38 separate recap computations from local history; #5 performance and #21 sensory feedback are distinct from #46 pacing. Other tickets have distinct behavioral or mode scope.

Source-status corrections are recorded in the program/lobby plan. Trade plan TR-006 now explicitly represents the existing #6 three-account acceptance requirement; no test was run or claimed by this amendment. Current runtime/product/QA owner docs are unaffected; no historical rewrite is needed. Exact 12-issue readback passed; all 45 states/milestones and untouched issues match the initial snapshot.

The lightweight completion gate passed on 2026-09-10: contract, harness audit, diff whitespace, and doc freshness. No builds, simulator journeys, or device tests ran. No tickets were closed or milestones changed.
