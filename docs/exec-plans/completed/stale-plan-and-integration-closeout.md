# Stale Plan and Integration Closeout

## Purpose and Outcome

Reconcile the repository after the completed icon, transcript-preview, tutorial, and language work, archive terminal plans, preserve genuinely pending product gaps, and publish the integrated branch. Success means `active/` names only real remaining work, owner docs point to the correct plan locations, repository checks pass, and the intended product changes are committed and pushed together.

## Execution Settings

- Validation profile: `lightweight`
- Delivery posture: `direct`
- Rationale: the product and UI work already passed its standard app-language completion gate. This slice is mechanical plan-state reconciliation and publication with no new runtime behavior.

## Context and Boundaries

- Archive only plans whose verification contracts and owner approvals are terminal.
- Keep the invitation-card productionization, connected-iPad proof, and Phase 14 parent active.
- Keep the two real UI-flow gaps visible.
- Preserve local `.impeccable/` critique output outside Git.
- Notion is an external mirror, not a repository source of truth; update it when the connected Notion tool is available.

## Milestones / Plan of Work

1. Audit active plans and accumulated working-tree scope.
2. Move terminal plans to `completed/`, repair cross-links, and refresh roadmap/debt/UI-flow ownership.
3. Run diff, document-freshness, generation, build, and harness checks through the completion gate.
4. Stage the intended repository changes, commit, and push the current branch.

## Verification Contract and Fresh Review

<!-- verification-contract:start -->
| ID | Class | Source | Acceptance | Verification | Evidence | Status | Rationale |
| --- | --- | --- | --- | --- | --- | --- | --- |
| CLOSE-001 | mechanical | AGENTS.md plan discipline | `active/` contains only the invitation, responsive-iPad, Phase 14 parent, and this in-flight closeout | exact active-plan listing | command:find-active-plans-2026-07-25 | pass | Four terminal plans moved to `completed/`; three substantive plans remain active |
| CLOSE-002 | mechanical | doc ownership rules | Cross-links, roadmap, debt, and known-gap inventory reflect the reconciled terminal state | link search, `git diff --check`, and `make doc-freshness` | command:doc-freshness-2026-07-25; command:git-diff-check-2026-07-25 | pass | Tutorial approval is closed; invite and real-iPad proof remain explicit |
| CLOSE-003 | mechanical | user request | The publication set contains the intended accumulated product work without local critique output | explicit staged name/status and diff-stat inspection | command:git-diff-cached-name-status-2026-07-25 | pass | All accumulated product, test, and owner-doc changes are staged; `.impeccable/` remains untracked and excluded |
<!-- verification-contract:end -->

<!-- fresh-review:start -->
| Reviewer | Required | Verdict | Evidence |
| --- | --- | --- | --- |
| constraint-auditor | no | not-applicable | Lightweight mechanical reconciliation; the underlying UI work already passed standard fresh review |
| product-ux | no | not-applicable | No new UI or product judgment is introduced |
<!-- fresh-review:end -->

## Living Record

### Progress

- [x] Active-plan and working-tree scope audited.
- [x] Terminal plans archived and owner-doc links refreshed.
- [x] Diff and doc-freshness checks passed.
- [x] Completion gate passed.
- [x] Intended changes committed and pushed.

### Decisions

- 2026-07-25: Archive branch maintenance, discard, Settings/Tutorial, and UI-flow audit.
- 2026-07-25: Keep lobby invite, responsive-iPad adaptation, and the Phase 14 parent active.
- 2026-07-25: Exclude `.impeccable/` local critique output from publication.

### Discoveries

- The Notion connector is unavailable in this session, so the repository closure can publish but the external task mirror cannot be updated honestly until the connector is enabled.
- GitHub CLI is unavailable, but the requested current-branch commit and direct remote push do not require PR creation.

## Validation and Outcome

- Automated: the lightweight completion gate passed, including verification-contract, harness, diff, and doc-freshness checks.
- Simulator/browser/local app: the underlying integrated UI slice previously passed the 262-test MessagesExtension suite and installed seventeen-state tutorial replay.
- Device/manual: connected-iPad proof remains owned by the responsive-adaptation plan.
- Judgment: no new judgment introduced.
- Release/config: integration commit `7d20642` pushed to `origin/ui-ux-single-device-testing`.
- Deferred: Notion mirror update awaits a connected Notion tool.

The repository closeout is complete: terminal plans are archived, three substantive plans remain active, the selected lightweight completion gate passed, and the reviewed integration commit was pushed. The Notion mirror remains an external follow-up because its connector was unavailable during this session.
