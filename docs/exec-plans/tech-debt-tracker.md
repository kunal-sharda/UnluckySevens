# Tech Debt Tracker

This is the durable rationale index for structural debt. GitHub Issues own actionable status; this file explains why the debt matters and links its single task owner.

## Open Debt

### TD-001 — Messages host-boundary regression coverage

- Risk: transcript selection, reopen lifecycle, session identity, and payload-carrier behavior can regress while engine and simulator tests remain green.
- Direction: deterministic simulator coverage plus an operator-assisted connected-device diagnostics lane.
- Owner: [GitHub issue #2](https://github.com/kunal-sharda/UnluckySevens/issues/2)

### TD-002 — Production board visual assertions are shallow

- Risk: real gameplay boards, transcript variants, and device-sized compositions remain under-protected against visual regressions.
- Direction: representative deterministic fixtures and production-surface assertions.
- Owner: [GitHub issue #3](https://github.com/kunal-sharda/UnluckySevens/issues/3)

### TD-005 — Concurrent lobby joins do not converge before start

- Risk: sibling join states can leave the visible roster dependent on transcript delivery and selection order.
- Direction: a transcript-authoritative reconciliation model that preserves canonical lobby authority.
- Owner: [GitHub issue #4](https://github.com/kunal-sharda/UnluckySevens/issues/4)

### TD-007 — Remaining render-path amplification

- Risk: render-model rebuilds, query amplification, and SpriteKit reconstruction may still contribute to device lag. Topology caching, immutable layout geometry, and projection/debug separation are already resolved; no measured latency improvement is claimed.
- Direction: profile first, then address only confirmed hot paths from F3–F5, F8–F16, and F18–F21 of the dated audit.
- Owner: [GitHub issue #5](https://github.com/kunal-sharda/UnluckySevens/issues/5); [performance audit](../quality/audits/2026-04-12-render-performance.md)

### TD-009 — Simultaneous targeted Trade accepts are delivery-order-driven

- Risk: recipients can accept sibling stale copies of one offer before either response is observed.
- Direction: deterministic resolution or serialized authority without changing responder semantics or secrecy.
- Owner: [GitHub issue #6](https://github.com/kunal-sharda/UnluckySevens/issues/6)

### TD-010 — State publication retains a fresh-session fallback

- Risk: when neither a selected same-game session nor cached session exists, a fresh `MSSession` can fragment transcript presentation if the path remains reachable.
- Direction: map reachable callers, remove an unreachable fallback, or prove the intended restart behavior on two accounts.
- Owner: [GitHub issue #7](https://github.com/kunal-sharda/UnluckySevens/issues/7)

## Resolved Index

| ID | Resolution | Date |
| --- | --- | --- |
| TD-003 | Extension responsibilities isolated behind focused host, feature, presentation, recovery, and DEBUG seams | 2026-08-21 |
| TD-004 | Shipping extension and tests share one compiled support module | 2026-08-21 |
| TD-011 | Core build costs have one production definition | 2026-08-21 |
| TD-012 | Terminal plans and stale flow narration reconciled | 2026-07-25 |
| TD-013 | Superseded standalone UI types removed | 2026-08-10 |
| TD-014 | Legacy tabletop presentation branches removed | 2026-08-10 |
| TD-015 | Local game-ledger retention and schema lifecycle defined | 2026-07-26 |
| TD-016 | Superseded board-art assets removed | 2026-08-21 |

Detailed implementation evidence remains in git history, completed ExecPlans, architecture, and the linked source/tests. Reopen a resolved item only with new evidence and a new or reactivated GitHub issue.
