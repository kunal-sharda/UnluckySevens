# AGENTS.md

Unlucky Sevens is an iMessage-first implementation of standard Catan. This file is intentionally short.

## Source of truth

Use this order when reasoning about the repo:

1. code, tests, and evals
2. [docs/index.md](docs/index.md)
3. [docs/decisions.md](docs/decisions.md)
4. the current owner docs linked from the docs index
5. the PRD, only for product wording or longer-term intent

## When to use an ExecPlan

Use [PLANS.md](PLANS.md) for work that is multi-step, risky, spans multiple files, or needs to be resumable without chat memory.

## Hard rules

- `ULS_CoreGame` stays pure and owns rules, determinism, validation, and secrecy-safe query logic.
- `ULS_Transport` stays pure and owns the message/protocol boundary.
- `MessagesExtension` consumes engine/query outputs; it must not become a second rules engine.
- Use the product docs in `docs/product/` for scope and flow intent; use `docs/decisions.md` for locked decisions.
- Do not commit generated `.xcodeproj` or `.xcworkspace` files.
- Keep tests and evals green.
- Do not change protocol fields, validation semantics, or locked decisions without an explicit request.

## Local-only notes

Machine-specific operator notes, approved command prefixes, and device-specific setup do not belong here. Keep those in local, untracked files.
