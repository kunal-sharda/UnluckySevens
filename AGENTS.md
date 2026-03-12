# AGENTS.md

Unlucky Sevens is an iMessage-first implementation of standard Catan. This file is the repo entrypoint for agents and humans working in the codebase.

## Source of truth

Use this order when reasoning about the repo:

1. code, tests, and evals
2. [docs/decisions.md](docs/decisions.md)
3. [ARCHITECTURE.md](ARCHITECTURE.md)
4. the owner docs under `docs/`
5. the PRD, only for product wording or longer-term intent

## Primary docs

- [ARCHITECTURE.md](ARCHITECTURE.md)
  - system shape, dependency direction, protocol model, and code ownership
- [PLANS.md](PLANS.md)
  - required format for active and completed ExecPlans
- [docs/decisions.md](docs/decisions.md)
  - locked product and architecture decisions
- [docs/product-specs/mvp-contract.md](docs/product-specs/mvp-contract.md)
  - current product promise, scope, and non-goals
- [docs/product-specs/ui-flows.md](docs/product-specs/ui-flows.md)
  - player-facing flow summaries
- [docs/quality/qa.md](docs/quality/qa.md)
  - practical gate, evals, and manual QA
- [docs/quality/golden-principles.md](docs/quality/golden-principles.md)
  - highest-signal engineering rules
- [docs/exec-plans/](docs/exec-plans/)
  - active, completed, and debt-tracking plan artifacts

## Hard rules

- `ULS_CoreGame` stays pure and owns rules, determinism, validation, and secrecy-safe query logic.
- `ULS_Transport` stays pure and owns the message/protocol boundary.
- `MessagesExtension` consumes engine/query outputs; it must not become a second rules engine.
- Use the product docs in `docs/product-specs/` for scope and flow intent; use `docs/decisions.md` for locked decisions.
- Do not commit generated `.xcodeproj` or `.xcworkspace` files.
- Keep tests and evals green.
- Do not change protocol fields, validation semantics, or locked decisions without an explicit request.

## When to use an ExecPlan

Use [PLANS.md](PLANS.md) for work that is multi-step, risky, spans multiple files, or needs to be resumable without chat memory.

## Local-only notes

Machine-specific operator notes, approved command prefixes, and device-specific setup do not belong here. Keep those in local, untracked files.
