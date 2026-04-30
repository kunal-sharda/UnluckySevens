# ExecPlan Rules

ExecPlans are the live plan and execution log for work that is too large, risky, or stateful to keep only in chat.

## When To Use One

Write an ExecPlan when work is any of the following:

- multi-file or multi-step
- likely to span multiple sessions
- risky enough that rollback and verification need to be explicit
- dependent on sequencing or migration order
- broad enough that acceptance criteria would otherwise be ambiguous
- requested by the user as a formal plan

Small edits, isolated bug fixes, and obvious single-file changes do not need an ExecPlan.

## Before Starting

- Check `docs/exec-plans/active/` for a relevant active plan.
- If one exists, read it first and use it as the working spec.
- If none exists and the work qualifies, create a new active plan.
- Identify which owner docs may need updates before making broad edits.

## Active Plan Requirements

An active ExecPlan must be self-contained, concrete, living, outcome-oriented, and readable.

Use these sections unless one is clearly not applicable:

1. `Summary`: what is changing, why now, and what success looks like.
2. `Current State`: what exists, what is missing, and important constraints.
3. `Assumptions and Evidence Gate`: required for platform, host-lifecycle, transport, persistence, or other external-contract work.
4. `Target End State`: user-visible result, code/docs result, and acceptance boundary.
5. `Implementation Plan`: ordered steps, key files, commands, and expected observations.
6. `Validation`: automated checks, manual checks, and deferred validation.
7. `Progress`: milestone checklist with implementation and validation notes.
8. `Decisions and Discoveries`: durable facts, surprises, and rationale discovered during execution.
9. `Outcome`: what landed and what remains.

For an `Assumptions and Evidence Gate`, state:

- each assumption the phase depends on
- the primary-source evidence for it, if any
- the exact symbol-level docs when the assumption depends on a specific framework property, callback, or error contract
- how the phase will try to falsify it on real hardware
- the fallback path if the assumption fails
- the acceptance rule for promoting a temporary path into canonical behavior

If a platform-contract issue survives one serious debugging pass, the plan should call for a minimal repro before the repo adopts broader workaround paths.

## Update Discipline

Update the active ExecPlan in the same slice when:

- scope, blockers, implementation details, validation status, or execution findings change
- a workaround becomes temporary policy or is retired
- a milestone lands
- a decision or discovery would matter to future work
- the outcome or remaining work changes
- a phase or major slice lands and `docs/exec-plans/CHANGELOG.md` needs a compact historical note

Also update owner docs in the same slice when behavior changes. Put durable QA lessons in `docs/quality/qa.md` and durable follow-up work in `docs/exec-plans/tech-debt-tracker.md`.

If a material change only exists in chat, the plan is stale.

## Planning Surfaces

- `docs/exec-plans/active/*.md`: live execution truth for in-flight work.
- `docs/exec-plans/completed/*.md`: historical records only.
- `docs/exec-plans/roadmap.md`: future sequencing after the current active phase.
- `docs/exec-plans/tech-debt-tracker.md`: durable cross-phase debt.
- `docs/exec-plans/CHANGELOG.md`: compact retrospective phase history, not live execution state.

Completed plans should be short closeout records. Backfilled historical plans are no longer part of the normal workflow.

## No Duplication

ExecPlans should not become a second source of truth for gameplay rules, architecture, or QA. Link the owner docs instead.

Owner docs:

- `docs/decisions.md` for locked decisions.
- `ARCHITECTURE.md` for runtime boundaries and ownership.
- `docs/product-specs/mvp-contract.md` and `docs/product-specs/ui-flows.md` for product behavior.
- `docs/quality/qa.md` for validation.

## Style

- Prefer prose over giant checklists.
- Use short sections and direct language.
- Do not pad the plan with unaffected behavior.
- Include exact commands only where they are useful for execution or verification.
- Link owner docs instead of copying their content.
