# ExecPlan Rules

ExecPlans are the live plan and execution log for work that is too large, risky, or stateful to keep only in chat.

## Work Tracking Model

Unlucky Sevens uses a proportional hierarchy:

- GitHub Issues own discrete bugs, enhancements, test gaps, and actionable tech debt.
- GitHub milestones own the scoped set of issues intended for a beta or production release.
- ExecPlans own orchestration when work is broad, risky, release-sensitive, spans multiple issues, or must remain resumable across sessions.

An issue may be implemented directly when its acceptance boundary is contained. If investigation reveals cross-cutting scope, architecture or protocol risk, ambiguous product direction, migration sequencing, or release coordination, create or attach an ExecPlan and link the issue. The issue remains the task-status record; the ExecPlan records shared constraints, sequencing, decisions, discoveries, and evidence without copying the issue backlog.

This hierarchy does not reduce validation. Every change still follows [QA](../quality/qa.md); an issue-sized change uses proportionate evidence, while qualifying work uses the ExecPlan verification contract and completion gate.

## When To Use One

Write an ExecPlan when work is any of the following:

- multi-file or multi-step
- likely to span multiple sessions
- risky enough that rollback and verification need to be explicit
- dependent on sequencing or migration order
- broad enough that acceptance criteria would otherwise be ambiguous
- requested by the user as a formal plan
- explicitly constrained, or changes architecture, protocol, product behavior, or UI/UX

Small edits, isolated bug fixes, and obvious single-file changes do not need an ExecPlan.

Do not create an ExecPlan merely because a GitHub Issue exists. Do not keep release scope only in an ExecPlan when the milestone and its linked issues can express it clearly.

## Before Starting

- Check the relevant GitHub Issue and milestone for the requested task and release scope when they exist.
- Check `docs/exec-plans/active/` for a relevant active plan.
- If one exists, read it first and use it as the working spec.
- If none exists and the work qualifies, create a new active plan.
- Link qualifying ExecPlans to their coordinating issue or milestone, and link constituent issues back to the plan when practical.
- Identify which owner docs may need updates before making broad edits.

## Active Plan Requirements

An active ExecPlan must be self-contained, concrete, living, outcome-oriented, and readable.

Use these sections unless one is clearly not applicable:

1. `Purpose and Outcome`: why the work exists and what success means.
2. `Execution Settings`: one validation profile, one delivery posture, and a short rationale.
3. `Context and Boundaries`: current state, owner links, scope, and non-negotiable constraints.
4. `Milestones / Plan of Work`: ordered, outcome-oriented slices.
5. `Approval Gate`: checkpointed work only; name the authority, proof, round budget, and stop rule.
6. `Verification Contract and Fresh Review`: the existing constraint table and reviewer table from [constraint verification](../quality/constraint-verification.md).
7. `Living Record`: concise `Progress`, `Decisions`, and `Discoveries` subsections.
8. `Validation and Outcome`: exact final evidence, result, and remaining work.

Add assumptions, interfaces/dependencies, migration, recovery, or external-contract evidence only when the work triggers them. Do not add empty sections for unaffected concerns.

Use one of these profiles:

- `lightweight`: a narrow, low-risk change with an obvious acceptance boundary. Keep the contract small and use targeted evidence. A fresh constraint auditor is optional.
- `standard`: the default for meaningful implementation, product, UI/UX, architecture, or behavior work. Use targeted tests and every observable or judgment review triggered by the change. A fresh constraint auditor is required.
- `release-critical`: a release, handoff, broad migration, or other high-blast-radius slice. It includes the standard evidence discipline plus the exhaustive practical gate. A fresh constraint auditor is required.

The profile chooses the baseline breadth of mechanical validation; it never waives a stated constraint or substitutes a build for observable or judgment evidence. Lock it before implementation. Record a later profile change as a dated decision; lowering a standard or release-critical profile also requires fresh constraint-auditor agreement.

Also lock the exact proof set before implementation. Validation may expand the plan only when it exposes a production defect or a constraint gap sourced to the user request or an authoritative owner doc. Follow the retry budget and stop/report rules in [QA](../quality/qa.md); harness instability does not authorize adjacent tests, new product work, or silent contract growth.

Choose delivery posture independently from the profile:

- `explore`: investigate, compare, or prototype, then stop before production.
- `checkpointed`: produce minimum honest proof, pause at a declared approval gate, then continue automatically after approval.
- `direct`: implement and verify without routine intermediate approval when direction is settled or explicitly delegated.

Auto-route an explicitly exploratory request to `explore`; ambiguous high-judgment, irreversible, or competing directions to `checkpointed`; and settled, mechanical, or explicitly delegated work to `direct`. A direct plan may fall back to checkpointed when genuine ambiguity emerges, but it must record the change before further implementation.

For an `Assumptions and Evidence Gate`, state:

- each assumption the phase depends on
- the primary-source evidence for it, if any
- the exact symbol-level docs when the assumption depends on a specific framework property, callback, or error contract
- how the phase will try to falsify it on real hardware
- the fallback path if the assumption fails
- the acceptance rule for promoting a temporary path into canonical behavior

If a platform-contract issue survives one serious debugging pass, the plan should call for a minimal repro before the repo adopts broader workaround paths.

For checkpointed visual work, the default authority is the user. Build the smallest honest DEBUG-only comparison with real components and fixture data, capture no more than three representative states per round, and default to two feedback rounds. While approval is pending, do not productionize nested states, launch automatic fresh review, or run the completion gate. Pause and ask the user how to proceed if the round budget is exhausted. Product/UX review is advisory on request during iteration and otherwise runs once after productionization; it may approve only when the user explicitly delegates authority. Record approval as a judgment row in the existing verification contract.

Route ambiguous judgment and final independent review to high-capability reasoning. Use the cheapest capable executor for implementation against an approved contract, and deterministic tools rather than agents for builds, tests, fixtures, and screenshot capture. If the runtime cannot select a cheaper child tier, do not spawn a same-tier agent for bounded mechanical work.

## Update Discipline

Update the active ExecPlan in the same slice when:

- scope, blockers, implementation details, validation status, or execution findings change
- a workaround becomes temporary policy or is retired
- a milestone lands
- a decision or discovery would matter to future work
- the outcome or remaining work changes
- validation exposes a legitimate sourced contract gap; record the amendment and update the user before expanding work
- a phase or major slice lands and `docs/exec-plans/CHANGELOG.md` needs a compact historical note

Also run `make doc-freshness` and the documentation freshness gate in `docs/quality/qa.md`. Update Tier 1 owner docs in the same slice when behavior changes, update Tier 2 active docs when execution/design direction changes, and avoid rewriting Tier 4 historical/reference docs unless a supersession note is needed. Put durable QA lessons in `docs/quality/qa.md` and durable follow-up work in `docs/exec-plans/tech-debt-tracker.md`.

If a material change only exists in chat, the plan is stale.

At approximately 150 lines or 2,500 words, review an active plan for compaction or splitting. Preserve current intent, unresolved work, locked decisions, and concise proof. Promote durable facts into owner docs, remove superseded iteration chronology instead of archiving it, and prefer focused child plans for independently deliverable or judgment-heavy slices.

## Completion Discipline

Qualifying work must include the exact verification-contract and fresh-review table shapes from [docs/quality/constraint-verification.md](../quality/constraint-verification.md). Establish the contract before implementation, update evidence as work proceeds, and record any acceptance-boundary change as a dated decision. For checkpointed work, a pending approval judgment row blocks progression from comparison to production as well as any completion claim.

Before claiming completion, run:

```bash
make completion-gate PLAN=docs/exec-plans/active/<plan>.md
```

The command accepts only a direct, non-symlinked Markdown child of `docs/exec-plans/active/`, validates that selected plan, runs the repository structural audit, and dispatches the plan's declared profile. Completed, sidecar, and external plans cannot be used as completion substitutes. Use the exhaustive release lane only with a `release-critical` plan:

```bash
make release-gate PLAN=docs/exec-plans/active/<release-plan>.md
```

`make harness-audit` checks every active plan's schema and reports unresolved in-flight constraints as notices. An unrelated active plan is not required to be complete before the selected plan can close.

Only `pass` and justified `not-applicable` constraint statuses are terminal. Every required reviewer must return `pass`. A command that was not run, an artifact that was not inspected, or a constraint that remains blocked must be reported as incomplete rather than softened in the final response.

## Planning Surfaces

- GitHub Issues: discrete actionable work and task status.
- GitHub milestones: release scope and issue-level progress.
- `docs/exec-plans/active/*.md`: live execution truth for in-flight work.
- `docs/exec-plans/completed/*.md`: historical records only.
- `docs/exec-plans/roadmap.md`: future sequencing after the current active phase.
- `docs/exec-plans/tech-debt-tracker.md`: durable cross-phase debt.
- `docs/exec-plans/CHANGELOG.md`: compact retrospective phase history, not live execution state.

Completed plans should be short closeout records. Backfilled historical plans are no longer part of the normal workflow.

## No Duplication

ExecPlans should not become a second source of truth for gameplay rules, architecture, or QA. Link the owner docs instead.

GitHub Issues are also not durable product or architecture specifications. They should link the relevant owner docs and state only the problem, acceptance boundary, local context, and validation needed for the task.

Owner docs:

- `README.md` for human setup links and repo entrypoint context, not detailed workflow truth.
- `docs/decisions.md` for locked decisions.
- `ARCHITECTURE.md` for runtime boundaries and ownership.
- `docs/product-specs/mvp-contract.md` and `docs/product-specs/ui-flows.md` for product behavior.
- `docs/quality/qa.md` for validation.
- `docs/quality/constraint-verification.md` for completion contracts and reviewer routing.
- `PRODUCT.md` and `DESIGN.md` for design-facing product context and current visual language.
- `docs/design/` for durable design artifacts only when those artifacts are intended to be committed with the repo. If a design artifact is local scratch, do not make tracked plans or changelog entries depend on it.

Active plans may record validation deltas and historical command output, but current validation rules must live in `docs/quality/qa.md`. If a plan entry conflicts with an owner doc, update the plan or add a supersession note instead of copying the owner doc into the plan.

## Style

- Prefer prose over giant checklists.
- Use short sections and direct language.
- Do not pad the plan with unaffected behavior.
- Do not retain every command rerun, screenshot path, or superseded iteration; keep only concise proof and current implications.
- Include exact commands only where they are useful for execution or verification.
- Link owner docs instead of copying their content.
