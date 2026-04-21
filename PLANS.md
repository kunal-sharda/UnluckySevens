# PLANS.md

This repo uses **ExecPlans** for work that is too large, risky, or stateful to keep only in chat. An ExecPlan is a self-contained markdown document that lets a new engineer or agent resume work from the repo alone.

## When to write an ExecPlan

Write an ExecPlan when work is any of the following:

- multi-file or multi-step
- likely to span multiple sessions
- risky enough that rollback and verification need to be explicit
- dependent on sequencing or migration order
- broad enough that acceptance criteria would otherwise be ambiguous
- requested by the user as a formal plan or historical reconstruction

Small edits, isolated bug fixes, and obvious single-file changes do not need an ExecPlan.

## Core rules

An ExecPlan must be:

- **self-contained**: do not rely on chat memory or unstated context
- **concrete**: name the commands, files, checks, and expected outcomes
- **living**: update it when the plan changes or new facts are discovered
- **active plans are mandatory context**: if a relevant ExecPlan already exists under `docs/exec-plans/active/`, read it before planning or implementation begins and use it as the working spec
- **active plans must stay current**: update the relevant ExecPlan whenever milestones land, scope changes, validation status changes, or new decisions and discoveries materially affect the work
- **outcome-oriented**: explain what the work should enable, not just which files change
- **readable**: define repo-specific terms and avoid unexplained jargon

An active ExecPlan is not just a plan. It is also the live implementation log for the current slice. If code, behavior, validation state, or technical understanding changes, the relevant active ExecPlan must be updated in the same work slice rather than reconstructed later from chat or git history.

For host-boundary, platform-contract, or carrier-fidelity work, an ExecPlan must also include an explicit **Assumptions and Evidence Gate**. That gate should list:

- each assumption the phase depends on
- the primary-source evidence for it, if any
- the exact symbol-level docs when the assumption depends on a specific framework property, callback, or error contract
- how the phase will try to falsify it on real hardware
- the fallback path if the assumption fails
- the acceptance rule for promoting a temporary path into canonical behavior

If a platform-contract issue survives one serious debugging pass, the plan should also call for a minimal repro before the repo adopts broader workaround paths. Do not let a phase accumulate product-specific complexity while the base platform contract is still unverified.

If the plan depends on other docs, link them directly and state which doc is the owner of each concept.

## Required structure for active ExecPlans

Every active ExecPlan should contain these sections in order unless a section is clearly not applicable:

1. `Summary`
   - What is being built or changed.
   - Why now.
   - What success looks like.
2. `Current State`
   - What exists today.
   - What is missing or broken.
   - Any important constraints already in the repo.
3. `Assumptions and Evidence Gate`
   - Required when the work depends on external framework behavior, host lifecycle, transport carriers, persistence guarantees, or any other platform contract that has already shown instability in real use.
   - List assumptions, the evidence behind them, the disproof test, and the fallback if they fail.
   - Mark undocumented or weakly supported assumptions as provisional rather than canonical.
4. `Target End State`
   - User-visible result.
   - Code and docs result.
   - Acceptance boundary.
5. `Implementation Plan`
   - Ordered steps.
   - Key files or subsystems.
   - Commands to run.
   - Expected observations.
6. `Validation`
   - Automated tests.
   - Manual checks.
   - Any deferred validation and why it is deferred.
7. `Progress`
   - Use checkboxes for major milestones.
   - Record the date when a milestone is completed.
   - Record how each milestone was reached and what issues were faced. i.e. where did the agent struggle/need to loop.
8. `Decisions and Discoveries`
   - Important decisions taken during execution.
   - Surprises, constraints, or deviations from the original plan.
   - Record durable implementation details that materially explain why the code looks the way it does, especially for platform-host, transport, lifecycle, layout, or integration work.
9. `Outcome`
   - What landed.
   - What remains.
   - Follow-on work, if any.

For active ExecPlans, the following update discipline is mandatory while work is in flight:

- implementation detail changed in a way that affects future work:
  - update `Current State`, `Implementation Plan`, `Progress`, or `Decisions and Discoveries` in the same slice
- validation result changed:
  - update `Validation` and `Progress` in the same slice
- a workaround became temporary policy or a temporary policy was retired:
  - update the active ExecPlan and the owning doc in the same slice
- a lesson became durable beyond the current phase:
  - normalize it into the running `Lessons` section of `docs/quality/qa.md`, and leave only phase-local chronology in the ExecPlan

Do not treat these updates as optional polish. If the repo state changed materially and the active ExecPlan did not, the plan is stale.

## Required structure for completed or backfilled ExecPlans

A completed ExecPlan is a historical record. It is not the owner of current behavior.

Every completed ExecPlan must contain these sections:

1. `Reconstruction Status`
   - State that the plan was backfilled after the fact.
   - Include the backfill date.
   - Include a confidence level.
2. `Canonical Owner Docs`
   - Link the current docs that own rules, architecture, and QA.
3. `Objective`
   - Why the phase existed.
4. `Starting State`
   - What the repo could and could not do before the phase.
5. `Target End State`
   - What the phase was trying to leave behind.
6. `Implementation Narrative`
   - Walk through the stage or substage breakdown in order.
   - Cite commits or changelog entries as evidence.
7. `Key Files or Subsystems`
   - Name the main code areas that were changed or introduced.
8. `Validation Performed or Evidenced`
   - Tests, evals, builds, or other evidence that support the reconstruction.
9. `What This Enabled Next`
   - Explain the dependency this phase created for later work.
10. `Reconstruction Notes`
   - List uncertainty, missing rationale, or places where current code was used to infer the original intent.

## Evidence rules for retrospective backfills

Use evidence in this order:

1. git commits and commit messages
2. `CHANGELOG.md`
3. current code and tests
4. current tracked docs
5. the PRD, only when needed for product motivation or intended UX

If two sources conflict, prefer the higher-priority source and record the conflict in `Reconstruction Notes`.

If the original plan cannot be recovered fully:

- say so plainly
- identify what is inferred
- separate observed facts from interpretation
- avoid inventing rationale that is not supported by the evidence

## No-duplication rule

ExecPlans should not become a second source of truth for gameplay rules, architecture, or QA. Link the owner docs instead.

For this repo, the typical owner docs are:

- `docs/decisions.md` for locked product and architecture rules
- `ARCHITECTURE.md` for the current engine contract
- `docs/quality/audits/2026-03-engine-readiness.md` for readiness conclusions
- `docs/quality/qa.md` for the current gate and manual QA

## Planning surfaces

Keep the tracked planning surfaces narrow and non-overlapping:

- `docs/exec-plans/active/*.md`: live execution truth for in-flight multi-step work
- `docs/exec-plans/completed/*.md`: historical reconstruction only
- `docs/exec-plans/roadmap.md`: coarse sequencing after the current active phase
- `docs/exec-plans/tech-debt-tracker.md`: durable follow-up debt that should survive the current phase
- `CHANGELOG.md`: retrospective evidence and human-readable phase history, not live execution state

If a fact changes, update the surface that owns that fact instead of copying it into every doc.

## Update discipline

Keep planning docs current in the same slice as the code or behavior change:

- active phase scope, blockers, validation status, or execution findings change:
  - update the relevant active ExecPlan
- active implementation details change in a way that would matter to a future engineer or agent:
  - update the relevant active ExecPlan in the same slice, not at the end of the phase
- future sequencing changes:
  - update `docs/exec-plans/roadmap.md`
- durable cross-phase debt is discovered, re-scoped, or resolved:
  - update `docs/exec-plans/tech-debt-tracker.md`
- durable cross-phase lessons are discovered:
  - update the running `Lessons` section in `docs/quality/qa.md`
- a phase or major slice fully lands:
  - update `CHANGELOG.md` and move or complete the active ExecPlan as appropriate

## Style guidance

- Prefer prose over giant checklists.
- Use short sections and direct language.
- Include commit hashes when they materially improve traceability.
- Do not pad the plan with unaffected behavior.
- Keep exact commands only where they are useful for execution or verification.
- Use markdown links for owner docs and concrete file paths when they help the reader resume work quickly.
