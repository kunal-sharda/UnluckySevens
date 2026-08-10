# AGENTS.md

Unlucky Sevens is an iMessage-first implementation of standard Catan. This file is the local entrypoint for agents working in the codebase.

## Agent Must Do First

For non-trivial work, do these before finalizing:

1. Use `bash ./scripts/gen.sh` as the only project-generation command; never run direct `tuist generate`, `gen-local`, `--open`, or Xcode GUI validation.
2. Use the simulator/XCUITest/UX Lab harnesses from [docs/quality/qa.md](docs/quality/qa.md) for UI validation; manual simulator driving is a temporary fallback only.
3. Check `docs/exec-plans/active/` before multi-step work and keep the active plan updated while the work is in flight.
4. Lock both the validation profile and delivery posture before implementation. For checkpointed work, stop at the declared approval gate; pending approval blocks productionization, fresh review, and the completion gate.
5. Use `make completion-gate PLAN=<path>` for profile-aware final validation. Reserve `make release-gate PLAN=<path>` and `make practical-gate` for release-critical work.
6. End with a doc-freshness note that says which owner docs changed, which were intentionally unaffected, and what validation was or was not run.
7. For qualifying work, keep a verification contract in the active ExecPlan and run `make completion-gate PLAN=<path>` before using the word complete.
8. Lock the exact proof set before implementation and obey the validation circuit breaker in [docs/quality/qa.md](docs/quality/qa.md). Validation may expand scope only for a demonstrated production defect or a sourced contract gap; harness instability must stop and be reported after the retry budget.

## Source Of Truth

Use this order when reasoning about the repo:

1. code, tests, and evals
2. [docs/decisions.md](docs/decisions.md)
3. [ARCHITECTURE.md](ARCHITECTURE.md)
4. [docs/product-specs/mvp-contract.md](docs/product-specs/mvp-contract.md), [docs/product-specs/ui-flows.md](docs/product-specs/ui-flows.md), and [docs/quality/qa.md](docs/quality/qa.md)
5. the PRD, only for original wording or longer-term intent

## Hard Rules

- `ULS_CoreGame` stays pure and owns rules, determinism, validation, and secrecy-safe query logic.
- `ULS_Transport` stays pure and owns the message/protocol boundary.
- `MessagesExtension` consumes engine/query outputs; it must not become a second rules engine.
- For Apple framework, host-lifecycle, or transport-contract bugs, consult the exact symbol-level Apple doc page (`property`, `method`, `enum case`) before designing repo-wide workarounds. If the issue survives that pass, build a minimal repro before treating the behavior as an undocumented platform quirk.
- Use product docs for scope and flow intent; use `docs/decisions.md` for locked decisions.
- Do not commit generated `.xcodeproj` or `.xcworkspace` files.
- Keep tests and evals green.
- Do not change protocol fields, validation semantics, or locked decisions without an explicit request.
- Do not treat a build, screenshot, or reviewer assertion as proof by itself; map every material constraint to the evidence class required by [docs/quality/constraint-verification.md](docs/quality/constraint-verification.md).

## Agent Workflow Rules

- Do not open Xcode as part of agent validation or visual review. Use command-line builds, simulator commands, and the checked-in harnesses.
- Do not run `tuist generate` directly for validation. Run `bash ./scripts/gen.sh`, which performs the repo-specific no-open generation and generated-project patching required for the standalone Messages package.
- Before any `xcodebuild -workspace UnluckySevens.xcworkspace ...` validation, run `bash ./scripts/gen.sh` in the same slice unless the current command sequence already did so.
- Prefer the reusable Messages simulator and screenshot harnesses documented in [docs/quality/qa.md](docs/quality/qa.md). Manual simulator driving is a fallback for gaps; promote repeated manual steps into XCUITest helpers or DEBUG-only UX Lab controls.
- Treat old generated workspace state as disposable. If a build result conflicts with the source tree or scripts, regenerate through `bash ./scripts/gen.sh` before diagnosing product code.
- Do not silently turn failed exploratory validation into new product scope. Keep exploratory artifacts separate from final evidence, amend the active plan before adding a legitimate new constraint, and update the user before validation-driven scope expansion.

## Planning

Use [docs/exec-plans/PLANS.md](docs/exec-plans/PLANS.md) for work that is multi-step, risky, spans multiple files, or needs to be resumable without chat memory.

Before starting multi-step work, check `docs/exec-plans/active/` for a relevant active ExecPlan. If one exists, use it as the working spec and keep it updated.

Work qualifies for a verification contract when it is multi-step, risky, explicitly constrained, or changes architecture, protocol, product behavior, or UI/UX. Every active plan declares a `lightweight`, `standard`, or `release-critical` profile. A fresh constraint-auditor review is mandatory for standard and release-critical plans and optional for lightweight plans; specialist reviews are risk-routed. Pending, failed, blocked, or unverified constraints in the selected plan prohibit its completion claim. Pending work in an unrelated active plan is an audit notice, not a blocker.

Every active plan also declares a delivery posture independently from its validation profile: `explore` prototypes and stops before production, `checkpointed` produces minimum honest proof and pauses at an approval gate, and `direct` implements without routine intermediate approval when direction is settled or delegated. Auto-route ambiguous, high-judgment, irreversible, or competing UI directions to `checkpointed`; route settled or mechanical work to `direct`. Use the compact plan shape and maintenance heuristic in [PLANS.md](docs/exec-plans/PLANS.md).

## Doc Ownership

Keep each fact in its owner doc and link rather than restating it:

- [AGENTS.md](AGENTS.md) owns agent workflow, source-of-truth order, doc ownership, and completion discipline.
- [docs/quality/qa.md](docs/quality/qa.md) owns validation commands and change-type routing; its linked quality guides own Messages lessons, UX Lab usage, and simulator/device runbooks.
- [docs/quality/constraint-verification.md](docs/quality/constraint-verification.md) owns completion contracts, evidence classes, reviewer routing, and completion language.
- [PRODUCT.md](PRODUCT.md) is concise design-facing product context; [DESIGN.md](DESIGN.md) owns current visual language and calibrated taste.
- [ARCHITECTURE.md](ARCHITECTURE.md) owns runtime boundaries, module ownership, protocol shape, and invariants.
- [docs/decisions.md](docs/decisions.md) owns locked decisions that should not drift silently.
- [docs/product-specs/mvp-contract.md](docs/product-specs/mvp-contract.md) and [docs/product-specs/ui-flows.md](docs/product-specs/ui-flows.md) own product scope, player-facing behavior, and flow intent.
- `docs/exec-plans/active/` owns current execution state, temporary findings, validation deltas, and remaining work for active multi-step slices.
- [README.md](README.md) is a human entrypoint and should link to owner docs instead of duplicating detailed status, workflow, or validation rules.
- `docs/design/` may be referenced from tracked docs only when the referenced design artifacts are intended to be durable repo artifacts. Otherwise, mark them as local scratch and do not make tracked docs depend on them.
- Durable binary references are default-denied. They require explicit user approval, a manifest entry, and the repository budget checks; iterative candidates belong in ignored `docs/design/workbench/` and are deleted when the decision closes.

## Doc Freshness Gate

Before calling work complete, classify docs by tier and update only the tier that owns the changed fact:

- Tier 1, always-current owner docs: [README.md](README.md) for human entrypoint/setup links, [ARCHITECTURE.md](ARCHITECTURE.md) for boundaries/invariants, [docs/decisions.md](docs/decisions.md) for locked decisions, product specs for product behavior, [PRODUCT.md](PRODUCT.md) and [DESIGN.md](DESIGN.md) for design context/language, and `docs/quality/` owner guides for validation, verification, durable lessons, and runbooks. Update the owner doc in the same slice when its fact changes.
- Tier 2, active execution docs: `docs/exec-plans/active/` and current design READMEs. Update them when active scope, implementation findings, validation deltas, or current design direction changes.
- Tier 3, periodic summary docs: [docs/exec-plans/roadmap.md](docs/exec-plans/roadmap.md), [docs/exec-plans/tech-debt-tracker.md](docs/exec-plans/tech-debt-tracker.md), and [docs/exec-plans/CHANGELOG.md](docs/exec-plans/CHANGELOG.md). Update only when sequencing changes, durable debt is created/retired, or a major slice lands.
- Tier 4, historical/reference docs: completed ExecPlans, dated audits, old design pass notes, and PRD verbatim source. Do not rewrite these for normal changes; add a supersession note or promote durable lessons into the owner docs when needed.
- Tier 5, local scratch: ignored files and machine-local notes. Do not let tracked docs depend on them.

For non-trivial work, run `make doc-freshness` before finalizing. The final response should include a short doc-freshness note: owner docs updated, owner docs intentionally unaffected, and any deferred historical/reference cleanup. If an affected owner doc is not updated, treat the work as incomplete and say what is missing.

Do not leave implementation details, integration findings, validation deltas, or durable lessons only in chat.

## Simulator Screenshot Workflow

For Messages-extension UI design captures, prefer reusable harnesses over manual UI driving:

- Use `UnluckySevensUITests/MessagesExtensionDesignSliceUITests.swift` to navigate Messages, open Unlucky Sevens, load UX Lab fixtures, and attach screenshots.
- Use DEBUG-only UX Lab screenshot controls to load clean fixture states and hide debug chrome before capture.
- For checkpointed visual work, use real components and fixture data, capture no more than three representative states per round, default to two rounds, and pause for user approval before productionizing nested states.
- Use `xcrun simctl io booted screenshot <path>` only after the harness has placed the simulator in the desired state.
- Use Computer Use only for gaps the harness cannot yet cover, then promote repeated manual steps into XCUITest helpers or DEBUG-only UX Lab controls.

## Local Notes

Machine-specific operator notes, approved command prefixes, and device-specific setup do not belong in tracked docs. Keep those in local, untracked files.
