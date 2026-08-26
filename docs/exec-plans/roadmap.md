# Roadmap

This file is the coarse sequencing surface. GitHub Issues own discrete work, the [Beta 1.1 milestone](https://github.com/kunal-sharda/UnluckySevens/milestone/1) owns current release scope, and ExecPlans are reserved for broad or risky orchestration.

## Now — Beta 1.1 Feedback and Proof

- Triage tester feedback into reproducible issues; do not extend the completed first-beta plan.
- Complete the [post-launch TestFlight device and multiplayer matrix](https://github.com/kunal-sharda/UnluckySevens/issues/8), including the deferred victory-screen observation.
- Fix confirmed player-facing beta defects before structural work when their impact is higher.

## Next — Reliability and Test Coverage

- [Messages host-boundary regression coverage](https://github.com/kunal-sharda/UnluckySevens/issues/2)
- [Production board and bubble visual assertions](https://github.com/kunal-sharda/UnluckySevens/issues/3)
- [Concurrent lobby-join convergence](https://github.com/kunal-sharda/UnluckySevens/issues/4)
- [Fresh-session publication fallback](https://github.com/kunal-sharda/UnluckySevens/issues/7)

Promote an issue into a linked ExecPlan only if investigation reveals cross-cutting architecture, protocol, migration, or release coordination.

## Later — Measured Structural Work

- [Profile remaining board and shell render amplification](https://github.com/kunal-sharda/UnluckySevens/issues/5); optimize only demonstrated hot paths.
- [Define deterministic simultaneous Trade acceptance](https://github.com/kunal-sharda/UnluckySevens/issues/6) if beta evidence or release priority activates it.
- Revisit deferred product ideas only after beta evidence justifies them; [deferred PRD items](../product-specs/deferred-prd-items.md) remain intentionally out of scope.

## Update Rule

Keep only `Now / Next / Later` sequencing here. Issue status belongs in GitHub, durable structural rationale belongs in the [tech-debt tracker](tech-debt-tracker.md), and execution evidence belongs in a qualifying active ExecPlan.
