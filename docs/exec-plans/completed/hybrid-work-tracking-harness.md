# Hybrid Work Tracking Harness

## Purpose and Outcome

Add the missing proportional work-tracking layer to the repository harness. Unlucky Sevens will use GitHub Issues for discrete bugs, enhancements, test gaps, and actionable tech debt; GitHub milestones will group release scope; ExecPlans will remain reserved for broad, risky, release-sensitive, or resumable orchestration. Update the reusable harness skills with the same concept without prescribing GitHub or any other tracker to unrelated repositories.

## Execution Settings

- Validation profile: `lightweight`
- Delivery posture: `direct`
- Rationale: This is a settled, documentation-and-template-only workflow correction with deterministic validation and no product, runtime, protocol, release, or UI behavior change.

## Context and Boundaries

- [ExecPlan rules](../PLANS.md) remain the owner of plan qualification, maintenance, and completion discipline.
- [AGENTS.md](../../../AGENTS.md) remains the agent workflow entrypoint.
- GitHub is the selected tracker for this repository only. Reusable skills must detect or ask for the repository's tracker instead of selecting a vendor.
- Tickets own discrete task status; milestones or equivalent tracker groupings own release scope; ExecPlans coordinate qualifying multi-ticket or high-risk work and link tickets instead of copying their status.
- Existing active plans and tech-debt entries are not migrated to external issues in this slice. That requires a separate bounded reconciliation so historical evidence is not converted into noisy or duplicate tickets.

## Milestones / Plan of Work

1. Add tracker-neutral proportional work tracking to the general and solo harness skills and their ExecPlan templates/rules.
2. Record GitHub Issues and milestones as the Unlucky Sevens work queue and release grouping in AGENTS.md, PLANS.md, README.md, and the roadmap.
3. Add concise GitHub issue forms for bugs, enhancements, and tech debt without duplicating product, architecture, or QA owner docs.
4. Validate both reusable skills and the repository harness, then archive this plan.

## Verification Contract and Fresh Review

<!-- verification-contract:start -->
| ID | Class | Source | Acceptance | Verification | Evidence | Status | Rationale |
| --- | --- | --- | --- | --- | --- | --- | --- |
| HWT-001 | mechanical | user request; skill-creator guidance | General and solo harness skills describe tickets, release groupings, and ExecPlans by responsibility without prescribing a tracker vendor | source inspection; skill validation | command:general-and-solo-quick-validate-pass | pass | Both skills preserve tracker choice, escalation, linking, and proportionate validation |
| HWT-002 | mechanical | user request | Unlucky Sevens explicitly uses GitHub Issues for discrete work and GitHub milestones for release scope, with ExecPlans limited to qualifying orchestration | source inspection; harness audit | command:harness-audit-pass | pass | AGENTS, PLANS, README, roadmap, and debt ownership now agree on the GitHub-specific choice |
| HWT-003 | mechanical | source-of-truth discipline | Issue forms capture actionable intake and acceptance/validation data while linking rather than duplicating durable product, architecture, decision, and QA truth | source inspection | report:bug-enhancement-and-tech-debt-forms-reviewed; command:issue-form-yaml-parse-pass | pass | Forms request problem, acceptance, validation, and links while directing durable contracts to owner docs |
| HWT-004 | mechanical | AGENTS.md | Documentation freshness, diff hygiene, skill validation, and harness audit pass | repository and skill commands | command:doc-freshness-pass; command:git-diff-check-pass; command:skill-validation-pass; command:harness-audit-pass | pass | Locked deterministic proof set for the workflow-only slice |
<!-- verification-contract:end -->

<!-- fresh-review:start -->
| Reviewer | Required | Verdict | Evidence |
| --- | --- | --- | --- |
| constraint-auditor | no | not-applicable | Lightweight profile; deterministic source and harness validation cover the locked workflow-only change |
| architecture | no | not-applicable | No runtime or module boundary changes |
<!-- fresh-review:end -->

## Living Record

### Progress

- [x] Validation profile, delivery posture, scope, and proof set locked.
- [x] Reusable skills updated and validated.
- [x] Repository workflow and GitHub issue forms updated and validated.
- [x] Selected completion gate passed and plan archived with a compact changelog entry.

### Decisions

- 2026-08-26: Use a proportional hierarchy: discrete work in the selected tracker, release scope in tracker-native groupings, and ExecPlans only for orchestration that is broad, risky, release-sensitive, multi-ticket, or resumable.
- 2026-08-26: Select GitHub Issues and milestones for Unlucky Sevens, but keep reusable harness skills tracker-neutral.

### Discoveries

- 2026-08-26: The existing harness already exempts small fixes from ExecPlans but does not name their durable work queue, allowing active plans to absorb feedback and remain open after their release outcome lands.

## Validation and Outcome

- Automated: both reusable skills pass the bundled `quick_validate.py`; all four GitHub issue-form YAML files parse; `make harness-audit`, `make doc-freshness`, and `git diff --check` pass.
- Documentation: AGENTS, PLANS, README, roadmap, tech-debt ownership, and the changelog now express one non-duplicative work-tracking model.
- Completion: `make completion-gate PLAN=docs/exec-plans/active/hybrid-work-tracking-harness.md` passed under the lightweight profile before archival.
- Deferred: migration of existing active-plan remnants and tech-debt entries into a deduplicated GitHub backlog.
