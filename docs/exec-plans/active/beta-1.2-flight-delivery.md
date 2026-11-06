# Beta 1.2 delegated delivery

## Purpose and Outcome
Implement remaining Beta 1.2 tickets under the owner's 2026-11-05 delegation to iterate autonomously, commit and push, and report assumptions and delivered behavior afterward. Issue membership remains authoritative in milestone 2.

## Execution Settings
- Validation profile: standard
- Delivery posture: direct
- Rationale: owner explicitly delegated design iteration and production decisions. Each implementation slice receives scoped proof and a fresh review. Final milestone/device acceptance remains separate and requires release-critical evidence.

## Context and Boundaries
Work from c51a207 on the isolated codex/beta-1.2-finish branch because beta-1.2 is checked out in the owner's original directory. Preserve the owner's Build Costs source, drawing, layout and preview work. Use remote beta-1.2 as integration target only after scoped validation and remote comparison. The earlier request to ask before builds/simulators is pending explicit confirmation. No build or simulator is authorized by silence.

Retain approximate three-segment supply. Full-word stock levels did not fit and abbreviated levels confused the owner. Design for an experienced Catan player learning controls, a newcomer needing contextual explanation, and a returning player consulting reference. Human feedback is deferred by owner instruction. Do not claim uncoached observation or connected-device proof from automated tests.

## Plan of Work and Locked Proof
1. #26/#25/#55: accessible mounted reference entry, progressive rules/reference and interactive synthetic controls practice. Reuse existing production controls and synthetic model. Preserve all game drafts and private data boundaries. Proof: focused model/navigation tests, normal and accessibility reference/tour harness journeys, inspected captures.
2. #42/#19/#22: stable identity and public score orientation with non-color cues. Derive public scores from Core queries. Proof: public/private invariance and presentation tests, four-player and forced-action harness captures including accessibility.
3. #17/#18: public next-action copy and reliable private roll receipt. Inspect existing canonical attribution before design. No protocol additions without explicit approval. Proof: all publishing-family copy tests and receipt attribution/deduplication tests, scoped renderer and local/no-gain/Reduce Motion journeys. Hardware receipt isolation remains separately evidenced.
4. #13/#14/#3: reconcile existing proof, cover remaining availability/timing and deterministic board/bubble matrices. Avoid Build Costs production changes conflicting with owner work. Proof: existing focused tests plus only missing fixture/capture rows.
5. Run independent constraint, behavioral and product/UX reviews on final diffs and raw evidence, then standard completion gate per slice. Commit coherent validated slices and push. Report unresolved human/device acceptance precisely.

Use the QA diagnostic-first initial plus ten focused-rerun ceiling. Every rerun needs a diagnosed correction. Do not expand proof for unrelated harness failures. Simulator cleanup is required after authorized runs.

## Verification Contract and Fresh Review
<!-- verification-contract:start -->
| ID | Class | Source | Acceptance | Verification | Evidence | Status | Rationale |
| --- | --- | --- | --- | --- | --- | --- | --- |
| FL-01 | mechanical | user isolation request | Preserve original checkout and Build Costs work | Diff and worktree inspection | report:isolated-worktree-c51a207 | pending | Recheck before delivery |
| FL-02 | mechanical | issues 25,26,55 | Learning is interactive, isolated and context preserving | Focused learning tests | report:pending | pending | Implementation pending |
| FL-03 | observable | issues 25,26,55 | Reference and controls work at normal and accessibility sizes | Scoped UI journeys and captures | report:pending | pending | Build permission requested |
| FL-04 | mechanical | issues 42,19,22 | Stable, color-independent identity and public-only scoring | Projection and privacy tests | report:pending | pending | Source audit pending |
| FL-05 | observable | issues 42,19,22 | Identity and standings remain readable across host states | Four-player and forced-action captures | report:pending | pending | Build permission requested |
| FL-06 | mechanical | issues 17,18 | Public continuation and private receipts preserve secrecy and attribution | Copy and query tests | report:pending | pending | Source audit pending |
| FL-07 | observable | issues 17,18 | Roll feedback and transcript composition are usable | Renderer and receipt journeys | report:pending | pending | Hardware evidence separately required |
| FL-08 | mechanical | issues 13,14,3 | Missing timing and visual regression matrices covered | Focused test and fixture inventory | report:pending | pending | Reconcile prior evidence first |
| FL-09 | judgment | user flight delegation | Coherent product fit across new surfaces | Fresh product UX review | report:pending | pending | Feedback deferred by owner |
| FL-10 | mechanical | AGENTS | Docs, scoped validation and integration are current | Doc freshness and completion gate | report:pending | pending | No completion claim yet |
<!-- verification-contract:end -->

<!-- fresh-review:start -->
| Reviewer | Required | Verdict | Evidence |
| --- | --- | --- | --- |
| constraint-auditor | yes | pending | report:pending |
| behavioral | yes | pending | report:pending |
| product-ux | yes | pending | report:pending |
<!-- fresh-review:end -->

## Living Record
2026-11-05: fetched remote, confirmed 11 open milestone issues (#3,13,14,17,18,19,22,25,26,42,55). Remote remains c51a207. Existing tutorial uses a production shell with hit testing disabled and Next navigation, so it cannot satisfy #25 interaction completion. Existing Rules hardcodes the winning goal and puts Strategy at the bottom. Isolated branch created. Runtime validation authorization remains pending.

### Source audit and implementation assumptions
- #26 Rules currently lives inside AppSettingsView; the lobby Tutorial callback routes directly to GameTutorialView. Add one shared Learn & Reference utility overlay while retaining the mounted real shell. The existing utility route already blocks game interaction while visible.
- #25 GameTutorialPreviewView deliberately disables hit testing. GameTutorialView advances by full-screen navigation zones. An interactive tour needs explicit action observation and separate skipped/completed progress. Reuse GameTutorialStateComposer and the tutorial LobbyDriverViewModel, but verify its send path before permitting synthetic actions.
- #42/#19 GameScreenModelBuilder and GameInfoPlayerSummary already own player projection. Inspect their secrecy-safe query source before adding persistent seat/public-score treatment.
- #18 EconomyPayoutV1 owns production allocation internally. The source search found no public production receipt query. Reliable receipts require a Core-owned attribution design, including old states and bank shortages, before UI implementation.
- #22 requires a color-vision-aware human review. #17/#18 include connected-device acceptance. These remain evidence obligations even when implementation and local proof are delivered autonomously.
- #13 overlaps protected Build Costs work. Reconcile coverage and avoid editing its components until an integration-safe boundary is identified.

## Validation and Outcome
Source inspection only. No product slice delivered yet.
