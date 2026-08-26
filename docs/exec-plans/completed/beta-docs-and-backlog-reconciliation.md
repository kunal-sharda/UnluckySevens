# Beta Docs and Backlog Reconciliation

## Purpose and Outcome

Close the documentation loop after the first TestFlight beta. Success means the launched release is recorded durably, stale active plans are archived with honest terminal outcomes, genuine remaining work has one GitHub issue owner, and the roadmap, debt tracker, and changelog are concise current navigation surfaces rather than parallel backlogs.

## Execution Settings

- Validation profile: `standard`
- Delivery posture: `direct`
- Rationale: The edits are documentation and work-tracking changes, but they span multiple sources of truth and require judgment about supersession, remaining work, and historical evidence. The user approved direct execution after reviewing the cleanup plan.

## Context and Boundaries

- [ExecPlan rules](../PLANS.md) own the proportional work-tracking model; [QA](../../quality/qa.md) and [constraint verification](../../quality/constraint-verification.md) own validation and completion language.
- Build `1.0 (8)` completed Beta App Review and launched through TestFlight. The first-friends release plan must be closed against that outcome without pretending every deferred beta observation was performed before launch.
- GitHub Issues own discrete remaining bugs, enhancements, test gaps, and actionable debt. A `Beta 1.1` milestone owns confirmed post-launch scope.
- Tier 1 owner docs are changed only when their current fact is stale or duplicated. Completed plans remain historical evidence; this slice may add terminal summaries or supersession notes but will not rewrite their chronology.
- No gameplay, protocol, UI, architecture, source, test, Apple configuration, or TestFlight distribution behavior changes in this slice.

## Milestones / Plan of Work

1. Inventory the active plans, current owner docs, debt entries, GitHub issues, and milestones; classify each unresolved item as satisfied by newer evidence, superseded, declined, or genuinely actionable.
2. Record the launched beta and archive every terminal or superseded active plan with a concise honest outcome.
3. Create a deduplicated `Beta 1.1` milestone and GitHub issues only for confirmed remaining work, linking historical plans and owner docs instead of copying their narratives.
4. Compact the roadmap, resolved-debt history, and changelog release boundary; remove stale sequencing while preserving durable facts.
5. Audit README, AGENTS, product, architecture, design, decisions, flows, and QA for actual ownership duplication; avoid line-count-driven edits.
6. Run structural and freshness validation, obtain a fresh constraint-auditor verdict, run the standard completion gate, and archive this plan.

## Verification Contract and Fresh Review

<!-- verification-contract:start -->
| ID | Class | Source | Acceptance | Verification | Evidence | Status | Rationale |
| --- | --- | --- | --- | --- | --- | --- | --- |
| DBR-001 | mechanical | AGENTS.md and PLANS.md | Every prior active plan has one honest terminal disposition and no terminal plan remains in `active/` | active/completed inventory and plan-link audit | command:active-plan-inventory-pass; report:fresh-constraint-audit-pass | pass | Eight prior plans moved to completed with explicit outcomes; only this reconciliation remains active |
| DBR-002 | mechanical | proportional work-tracking model | Every confirmed remaining action has one GitHub issue owner and the next beta scope has one milestone without duplicate plan or debt backlog text | GitHub issue and milestone inspection plus repository link search | report:Beta-1.1-milestone-seven-issue-audit-pass; report:fresh-constraint-reaudit-pass | pass | Issues #2–#8 own six durable gaps plus the full post-launch device/multiplayer matrix |
| DBR-003 | judgment | user-approved cleanup plan and doc ownership rules | Current docs are shorter where repetition or stale execution state existed while owner truth and historical evidence remain intelligible | semantic before/after review of changed docs | report:fresh-constraint-audit-and-correction-pass | pass | Planning summaries fell from 438 to 125 lines while completed plans preserve detailed history |
| DBR-004 | mechanical | AGENTS.md completion discipline | Harness structure, documentation freshness, diff hygiene, and the selected standard completion gate pass | prescribed repository commands | command:harness-audit-pass; command:doc-freshness-pass; command:git-diff-check-pass; command:standard-completion-gate-and-Messages-build-pass | pass | Initial sandboxed generation was permission-blocked; the identical escalated rerun passed |
<!-- verification-contract:end -->

<!-- fresh-review:start -->
| Reviewer | Required | Verdict | Evidence |
| --- | --- | --- | --- |
| constraint-auditor | yes | pass | report:fresh-audit-failed-two-doc-truth-gaps; report:corrected-scope-and-owner-date; report:fresh-reaudit-pass |
| architecture | no | not-applicable | No runtime boundaries or source change |
| behavioral | no | not-applicable | No gameplay or protocol behavior change |
| product-ux | no | not-applicable | No player-facing UI or copy change |
<!-- fresh-review:end -->

## Living Record

### Progress

- [x] Validation profile, delivery posture, proof set, and documentation-only boundary locked.
- [x] Active-plan and GitHub inventory reconciled.
- [x] Terminal plans archived and remaining actions ticketed.
- [x] Planning surfaces compacted and owner-doc freshness audited.
- [x] Fresh constraint review passed after correcting Issue #8 scope and the decisions owner-doc date.
- [x] Standard completion gate passed.

### Decisions

- 2026-08-26: Shortening is ownership-driven, not line-count-driven. Historical completed plans remain intact unless a concise terminal or supersession note is necessary.
- 2026-08-26: `Beta 1.1` will contain only confirmed follow-up work; speculative product ideas remain deferred.
- 2026-08-26: Seven issues own the current milestone: six durable debt/test gaps and one post-launch device/multiplayer TestFlight matrix. Old screenshot or approval rows were not copied into issues when newer evidence or product direction superseded them.

### Discoveries

- 2026-08-26: Eight active plans remain after the launched beta; several already report completion or supersession and are stale execution state rather than live work.
- 2026-08-26: README still described Phase 14 and pre-TestFlight readiness; the compatibility decision named an unspecified TestFlight build; QA and UI flows retained two pre-Player-Record phrases. Those owner facts required narrow freshness edits. Architecture, Product, Design, and the MVP contract remained current.

## Validation and Outcome

- Automated: standard completion gate passed, including canonical generation and the generic Messages simulator build
- Repository inspection: eight prior active plans archived with terminal summaries; only this cleanup plan remains active
- GitHub work tracking: [Beta 1.1](https://github.com/kunal-sharda/UnluckySevens/milestone/1) contains issues #2–#8
- Judgment: fresh constraint audit passed after one correction round
- Owner docs: README, decisions, UI flows, QA, roadmap, debt tracker, changelog, and the historical language-audit pointer updated; Architecture, Product, Design, AGENTS, MVP contract, and constraint-verification intentionally unaffected
- Deferred: product, source, runtime, and release changes are outside this documentation-only slice

Outcome: the first beta is durably recorded, all stale active plans have honest terminal records, Beta 1.1 has one milestone and seven deduplicated issues, and current planning summaries are compact. No implementation or player-facing behavior changed.
