# Tech Debt Tracker

This is the durable rationale index for structural debt. GitHub Issues own actionable status; this file explains why the debt matters and links its single task owner.

## Open Debt

### TD-001 — Messages host-boundary regression coverage

- Risk: transcript selection, reopen lifecycle, session identity, and payload-carrier behavior can regress while engine and simulator tests remain green.
- Additional identity risk: Apple participant UUIDs are device-scoped, so existing whole-roster comparisons against `MSConversation` remote identifiers—including `isCompatibleWithActiveConversation(_:)` and exact-participant Player Record matching—may reject valid cross-device rosters. Local actor lookup is not equivalent because each device authors its own local actor identifier.
- Direction: deterministic simulator coverage plus an operator-assisted connected-device diagnostics lane; separately prove or replace remote-participant roster matching without treating device-scoped UUIDs as stable wire identity.
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

## Resolved Index

| ID | Resolution | Date |
| --- | --- | --- |
| TD-003 | Extension responsibilities isolated behind focused host, feature, presentation, recovery, and DEBUG seams | 2026-08-21 |
| TD-004 | Shipping extension and tests share one compiled support module | 2026-08-21 |
| TD-010 | Removed the unused fresh-session state helper; production `.state(gameId:)` resolution uses only the selected same-game or cached session and otherwise fails closed | 2026-08-28 |
| TD-011 | Core build costs have one production definition | 2026-08-21 |
| TD-012 | Terminal plans and stale flow narration reconciled | 2026-07-25 |
| TD-013 | Superseded standalone UI types removed | 2026-08-10 |
| TD-014 | Legacy tabletop presentation branches removed | 2026-08-10 |
| TD-015 | Local game-ledger retention and schema lifecycle defined | 2026-07-26 |
| TD-016 | Superseded board-art assets removed | 2026-08-21 |

Detailed implementation evidence remains in git history, completed ExecPlans, architecture, and the linked source/tests. Reopen a resolved item only with new evidence and a new or reactivated GitHub issue.

### Deferred — fully unattended second physical Messages device

Owner decision 2026-09-28: beyond Beta 1.1 and #49. Current supported automation is the home iPad plus remote-human phone checkpoints. Revisit when a second controllable device with an independent iMessage account is available and unattended operation materially saves work. Preserve installation identity, provenance, consent for actual sends and bounded recovery. This deferral does not waive three-/four-account product verification with friends. Execution entrypoint: [Beta testing plan](active/testing-streams-implementation.md).
