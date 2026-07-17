# Constraint Verification

This document owns evidence-backed completion. It complements [QA](qa.md), which owns validation commands and runbooks.

## Trigger

Use a verification contract when work is multi-step, risky, explicitly constrained, or changes architecture, protocol, product behavior, or UI/UX. Tiny mechanical edits may remain lightweight when their acceptance boundary is obvious and fully covered by one existing check.

## Validation Profiles

Every active ExecPlan declares exactly one profile with a rationale:

- `lightweight` for narrow, low-risk work with a small targeted contract.
- `standard` for normal meaningful implementation and any product, UI/UX, architecture, protocol, or behavior work.
- `release-critical` for releases, handoffs, broad migrations, and high-blast-radius changes.

Profiles control the baseline breadth of mechanical checks. They do not remove constraints, downgrade evidence classes, or excuse an uninspected UI artifact. Use `standard` when uncertain. Profile changes are dated plan decisions; lowering a profile requires a fresh constraint-auditor verdict.

## Delivery Postures

Every active ExecPlan also declares one delivery posture independently from its profile:

- `explore`: investigate or prototype and stop before production.
- `checkpointed`: produce minimum honest proof, pause at a declared approval gate, and continue automatically after approval.
- `direct`: implement and verify without routine intermediate approval when direction is settled or delegated.

Route exploratory requests to `explore`, ambiguous high-judgment or competing directions to `checkpointed`, and settled or mechanical work to `direct`. Delivery posture does not weaken the final contract or validation profile.

## Evidence Classes

- `mechanical`: a deterministic command, test, lint, build, or static invariant can prove the constraint.
- `observable`: the agent must drive a fixture, journey, device, or integration boundary and inspect the resulting state, log, screenshot, or payload.
- `judgment`: correctness depends on product fit, clarity, accessibility, visual quality, or another calibrated standard that cannot be reduced safely to one assertion.

Passing one class never substitutes for another. A successful build does not prove an observable journey or a judgment constraint.

## Contract Format

Add one table between these exact markers in the active ExecPlan:

```markdown
<!-- verification-contract:start -->
| ID | Class | Source | Acceptance | Verification | Evidence | Status | Rationale |
| --- | --- | --- | --- | --- | --- | --- | --- |
| C-001 | mechanical | user request | Exact boundary | Exact command or inspection | command:pending | pending | Awaiting implementation |
<!-- verification-contract:end -->
```

Rules:

- IDs are stable and unique.
- Allowed classes are `mechanical`, `observable`, and `judgment`.
- Allowed statuses are `pending`, `pass`, `fail`, `blocked`, and `not-applicable`.
- Use semicolon-separated evidence tokens. Prefix repository files with `file:` so the checker verifies that they exist.
- `pass` requires concrete evidence. `not-applicable` requires a specific rationale.
- Do not use the pipe character inside table cells.

Add one fresh-review table:

```markdown
<!-- fresh-review:start -->
| Reviewer | Required | Verdict | Evidence |
| --- | --- | --- | --- |
| constraint-auditor | yes | pending | report:pending |
| architecture | no | not-applicable | not triggered |
| behavioral | no | not-applicable | not triggered |
| product-ux | no | not-applicable | not triggered |
<!-- fresh-review:end -->
```

## Review Routing

The fresh `constraint-auditor` is required for `standard` and `release-critical` plans. It is optional for `lightweight` plans. When required, the auditor receives the active plan, owner docs, diff, and raw evidence without inheriting the implementer's optimistic summary.

Route specialists when triggered:

- `architecture`: module ownership, dependency direction, protocol shape, external contracts, or duplicated rules.
- `behavioral`: state transitions, secrecy, recovery, failure modes, transport, or observable user journeys.
- `product-ux`: user-facing flow, copy, accessibility, layout, visual quality, or established product taste.

Each reviewer must identify the constraints inspected, evidence actually opened or commands actually run, blocking findings, and final verdict. After a correction, re-run every review whose evidence changed.

## Human Calibration

Escalate when existing owner docs cannot distinguish viable directions, reviewer and implementer disagree about a judgment constraint, or the work establishes a new product/design principle. After the decision, promote it into the narrowest durable owner: a design principle, component, fixture, test, lint, or reviewer rule.

For checkpointed work, express the approval boundary as a `judgment` constraint in the existing contract. A pending approval blocks progression from comparison to production, not only the final completion claim. The user is the default visual authority; another reviewer may approve only when the user explicitly delegates that authority. During visual iteration, product/UX review is advisory on request. Otherwise run it once, after the approved direction is productionized. Do not launch routine fresh reviews or the completion gate while approval is pending.

## Completion Language

Run `make completion-gate PLAN=<active-plan>` before claiming completion. If the gate cannot pass, use precise language such as `implemented but not verified`, `incomplete`, or `blocked`, and name the missing evidence.

The completion gate accepts only a direct active-plan file, checks that selected plan, and dispatches its profile. `make harness-audit` checks active-plan schema and repository structure; pending work in another active plan is a notice, not a blocker. `make release-gate PLAN=<active-plan>` accepts only a `release-critical` plan and runs the exhaustive practical gate.

The final response must summarize constraint results, fresh-review verdicts, validation actually run, unresolved items, and doc freshness.
