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
- **outcome-oriented**: explain what the work should enable, not just which files change
- **readable**: define repo-specific terms and avoid unexplained jargon

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
3. `Target End State`
   - User-visible result.
   - Code and docs result.
   - Acceptance boundary.
4. `Implementation Plan`
   - Ordered steps.
   - Key files or subsystems.
   - Commands to run.
   - Expected observations.
5. `Validation`
   - Automated tests.
   - Manual checks.
   - Any deferred validation and why it is deferred.
6. `Progress`
   - Use checkboxes for major milestones.
   - Record the date when a milestone is completed.
7. `Decisions and Discoveries`
   - Important decisions taken during execution.
   - Surprises, constraints, or deviations from the original plan.
8. `Outcome`
   - What landed.
   - What remains.
   - Follow-on work, if any.

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
- `docs/architecture/overview.md` for the current engine contract
- `docs/EngineReadinessAudit.md` for readiness conclusions
- `docs/QA.md` for the current gate and manual QA

## Style guidance

- Prefer prose over giant checklists.
- Use short sections and direct language.
- Include commit hashes when they materially improve traceability.
- Do not pad the plan with unaffected behavior.
- Keep exact commands only where they are useful for execution or verification.
- Use markdown links for owner docs and concrete file paths when they help the reader resume work quickly.
