# Variant Feature Request Intake

## Purpose and Outcome

Record the user's 2026-09-09 desert/robber variant and separate game-speed requests as nonduplicate, unscheduled GitHub features. This is tracking only, not rules implementation.

## Execution Settings

- Validation profile: `lightweight`
- Delivery posture: `direct`
- Rationale: Two bounded feature requests and sequencing links; unresolved gameplay decisions remain explicitly unapproved.

## Context and Boundaries

The current issue inventory contains #20 for victory targets and #12 for 1v1, but neither requested feature in full. Preserve standard rules, release milestones, and unrelated working-tree changes. GitHub owns acceptance and status; roadmap/program link future work.

## Milestones / Plan of Work

1. File separate feature requests with confirmed intent and unresolved decisions.
2. Link later-work sequencing without assigning release scope.
3. Read back exact issue bodies/milestones and run the lightweight completion gate.

## Verification Contract and Fresh Review

<!-- verification-contract:start -->
| ID | Class | Source | Acceptance | Verification | Evidence | Status | Rationale |
| --- | --- | --- | --- | --- | --- | --- | --- |
| VF-001 | mechanical | user request 2026-09-09 | Separate desert/non-stacking and speed requests exist, overlap links are explicit, and uncertain rules remain decisions | Exact GitHub readback | report:Exact issue 45/46 readback matches authored bodies; milestones null | pass | Tracking scope only |
| VF-002 | mechanical | repo ownership | Roadmap/program link unscheduled requests without changing runtime or release scope | Issue milestones and scoped doc inspection | report:Roadmap and program inspected for issue links and unscheduled scope | pass | No implementation |
<!-- verification-contract:end -->

<!-- fresh-review:start -->
| Reviewer | Required | Verdict | Evidence |
| --- | --- | --- | --- |
| constraint-auditor | no | not-applicable | Optional lightweight tracking review |
<!-- fresh-review:end -->

## Living Record

- 2026-09-09: Locked lightweight/direct. Exact proof set: issue body/milestone readback, scoped document inspection, lightweight completion gate including doc freshness. No build or simulator validation is required.

## Validation and Outcome

Created #45 and #46; exact GitHub readback and scoped doc inspection passed. The lightweight completion gate passed on 2026-09-09, including the contract, harness audit, diff whitespace check, and doc freshness. No runtime tests were run for this tracking-only slice. Current product/rules owner docs remain intentionally unaffected; no historical cleanup is required.
