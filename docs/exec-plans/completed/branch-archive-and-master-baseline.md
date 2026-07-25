# Branch Archive and Master Baseline

## Purpose and Outcome

Make the repository branch topology legible without disturbing active product work. Success means `master` is fast-forwarded to the verified `phase-driven-dev` tip, agreed historical branch tips remain reachable through pushed archive tags, obsolete local and remote branch refs are removed, and `game-setup-options` plus `ui-ux-single-device-testing` remain untouched.

## Execution Settings

- Validation profile: `lightweight`
- Delivery posture: `direct`
- Rationale: The user explicitly approved a mechanical ref-maintenance sequence with exact retained and removed refs. Verification is Git ancestry and remote-ref inspection; no source, product, protocol, or UI behavior changes.

## Context and Boundaries

- Preserve the current dirty `ui-ux-single-device-testing` worktree exactly.
- Preserve `game-setup-options` at its current tip for a later semantic decision.
- Refresh `origin` before resolving tag targets.
- Archive the final tips of `device-debug`, `phase-driven-dev`, and `phase1-ui-e2e-test` before deleting their branch refs.
- Keep `master` as the remote default branch and move it only by fast-forward to `phase-driven-dev`.
- A stale deleted temporary worktree record may be pruned; the associated branch must remain.

## Milestones / Plan of Work

1. Fetch and prune `origin`; re-check worktree status, tips, and ancestry.
2. Fast-forward local and remote `master` to the refreshed `phase-driven-dev` tip.
3. Create annotated archive tags at the exact agreed branch tips and push them.
4. Remove only the obsolete local and remote branch refs, then prune stale worktree metadata.
5. Inspect final local refs, remote refs, tags, worktrees, and the preserved dirty status.

## Verification Contract and Fresh Review

<!-- verification-contract:start -->
| ID | Class | Source | Acceptance | Verification | Evidence | Status | Rationale |
| --- | --- | --- | --- | --- | --- | --- | --- |
| C-001 | mechanical | user request | `master` resolves to the refreshed `phase-driven-dev` tip by fast-forward | ancestry and exact-ref inspection | command:git rev-parse master origin/master | pass | Both resolve to `96fc98a4c7412c3d7e5290c51cc46afbb80e36b2`; atomic push reported a fast-forward |
| C-002 | mechanical | user request | Each archive tag resolves to the corresponding branch tip captured after fetch | exact-ref inspection | command:git rev-parse archive tags; command:git ls-remote --heads --tags origin | pass | Dereferenced local and remote targets match `4fe6e55`, `96fc98a`, and `309e7f6` respectively |
| C-003 | mechanical | user request | Obsolete branch refs are removed locally and from origin while retained refs remain | local and remote ref listing | command:git branch -a -vv --no-abbrev; command:git ls-remote --heads --tags origin | pass | Only `master`, `game-setup-options`, and `ui-ux-single-device-testing` remain locally and remotely |
| C-004 | mechanical | user request | Current dirty worktree and both retained feature branches are unchanged | before-and-after status and exact-ref comparison | command:git status --short --branch; command:git rev-parse retained refs | pass | Dirty-path status matched the captured pre-maintenance state; retained local and remote tips remain `d51f105` and `3463c60` |
<!-- verification-contract:end -->

<!-- fresh-review:start -->
| Reviewer | Required | Verdict | Evidence |
| --- | --- | --- | --- |
| constraint-auditor | no | not-applicable | lightweight mechanical ref maintenance |
| architecture | no | not-applicable | no architecture changes |
| behavioral | no | not-applicable | no product behavior changes |
| product-ux | no | not-applicable | no user-facing changes |
<!-- fresh-review:end -->

## Living Record

### Progress

- 2026-07-19: User approved the exact baseline, archive, deletion, and preservation set.
- 2026-07-19: Refreshed `origin`, atomically fast-forwarded `origin/master` with the three archive-tag pushes, aligned local `master`, deleted the agreed obsolete local and remote branches, and pruned only the stale worktree metadata.
- 2026-07-19: Final local and direct-remote inspection confirmed the intended three-branch topology, exact archive targets, and preservation of the active dirty worktree.

### Decisions

- Archive tags use the correctly spelled `archive/` namespace and a `2026-07-19` date suffix.
- `game-setup-options` is preserved without integration or deletion.

### Discoveries

- Before refresh, `master`, `device-debug`, `phase-driven-dev`, and `origin/phase1-ui-e2e-test` were all ancestors of the current integration branch; only `game-setup-options` had a unique unmerged commit.
- The selected verification contract passed during the original maintenance slice. The unrelated ignored design-workbench residue that blocked the repository-wide harness audit was removed by a later approved cleanup.

## Validation and Outcome

Repository ref maintenance passed all four mechanical constraints. `master` was aligned to `96fc98a`; `game-setup-options` and `ui-ux-single-device-testing` were preserved at their recorded tips; and the three dated annotated archive tags were pushed to `origin`. `make doc-freshness` and the selected verification contract passed. The former repository-wide harness notice was unrelated residue that a later approved cleanup removed, so no product or repository work remains in this plan.
