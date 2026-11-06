# Beta 1.2 delegated delivery

## Purpose and Outcome
Implement remaining Beta 1.2 tickets under the owner's 2026-11-05 delegation to iterate autonomously, commit and push, and report assumptions and delivered behavior afterward. Issue membership remains authoritative in milestone 2.

## Execution Settings
- Validation profile: standard
- Delivery posture: direct
- Rationale: owner explicitly delegated design iteration and production decisions. Each implementation slice receives scoped proof and a fresh review. Final milestone/device acceptance remains separate and requires release-critical evidence.

## Context and Boundaries
Work from c51a207 on the isolated codex/beta-1.2-finish branch because beta-1.2 is checked out in the owner's original directory. Preserve the owner's Build Costs source, drawing, layout and preview work. Use remote beta-1.2 as integration target only after scoped validation and remote comparison. The owner explicitly authorized all required builds and simulators on 2026-11-05. Proceed autonomously with scoped validation.

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
| FL-03 | observable | issues 25,26,55 | Reference and controls work at normal and accessibility sizes | Scoped UI journeys and captures | report:pending | pending | Authorized, awaiting implementation |
| FL-04 | mechanical | issues 42,19,22 | Stable, color-independent identity and public-only scoring | Projection and privacy tests | report:pending | pending | Source audit pending |
| FL-05 | observable | issues 42,19,22 | Identity and standings remain readable across host states | Four-player and forced-action captures | report:pending | pending | Authorized, awaiting implementation |
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
2026-11-05: fetched remote, confirmed 11 open milestone issues (#3,13,14,17,18,19,22,25,26,42,55). Remote remains c51a207. Existing tutorial uses a production shell with hit testing disabled and Next navigation, so it cannot satisfy #25 interaction completion. Existing Rules hardcodes the winning goal and puts Strategy at the bottom. Isolated branch created. Runtime validation was subsequently explicitly authorized by the owner.

### Source audit and implementation assumptions
- #26 Rules currently lives inside AppSettingsView; the lobby Tutorial callback routes directly to GameTutorialView. Add one shared Learn & Reference utility overlay while retaining the mounted real shell. The existing utility route already blocks game interaction while visible.
- #25 GameTutorialPreviewView deliberately disables hit testing. GameTutorialView advances by full-screen navigation zones. An interactive tour needs explicit action observation and separate skipped/completed progress. Reuse GameTutorialStateComposer and the tutorial LobbyDriverViewModel, but verify its send path before permitting synthetic actions.
- #42/#19 GameScreenModelBuilder and GameInfoPlayerSummary already own player projection. Inspect their secrecy-safe query source before adding persistent seat/public-score treatment.
- #18 EconomyPayoutV1 owns production allocation internally. The source search found no public production receipt query. Reliable receipts require a Core-owned attribution design, including old states and bank shortages, before UI implementation.
- #22 requires a color-vision-aware human review. #17/#18 include connected-device acceptance. These remain evidence obligations even when implementation and local proof are delivered autonomously.
- #13 overlaps protected Build Costs work. Reconcile coverage and avoid editing its components until an integration-safe boundary is identified.

## Validation and Outcome
Learning/reference implementation in progress. Initial generated simulator build passed. Focused test attempt 1 stopped at UI-test compilation because the new journey used nonexistent board-frame helper names. Corrected to the existing turnElement/assertFrame helpers. Attempt 2 runs the same focused set. No runtime failure or scope expansion.

Learning UI attempt 1 reached the reference but failed to navigate into the tour. Exported hierarchy showed the Reference content extending below the host while the underlying Bank still existed in the accessibility tree. Inspected the reference screenshot. Constrained the learning overlay to the measured host usable size, moved learning links above the rules, and added an explicit tour-arrival assertion. Normal-size attempt 2 pins the simulator content size to large and restores its original size afterward. This addresses the existing reference containment/entry contract.

Learning UI attempt 2 reached the tour but its Group-level accessibility identifier propagated to every descendant, replacing the Bank and Continue identifiers. The test consequently found the underlying real Bank. Changed the tour root to a containing ZStack accessibility element and scoped tour queries to that container. Independent architecture review also found global board-occlusion broadcasts from practice could affect the mounted real shell. Practice now skips that global channel and uses its local board occlusion projection. The return journey must exercise an already-open real Players panel.

Combined focused model/render attempt 1 passed 51/52 tests. One newly updated draw-copy expectation incorrectly assumed a third player in an existing two-player fixture. Corrected the expected pending voter to Blake only. No product defect. Reviewer findings led to practice callback wiring and receipt initial/deferred-display fixes. Exact receipts still require an observed canonical predecessor and are explicitly unavailable when history is missing. This is an unresolved #18 acceptance gap, without changing protocol fields.

Learning UI attempt 3 passed Bank practice and captured the controls surface, then used an unscoped Dev query that selected the real underlying deck. Scoped all practice controls to the tour. Screenshot review additionally showed a zero-height practice board under safeAreaInset sizing. Replaced that layout with an explicit GeometryReader/VStack allocation for the instruction area and practice shell. Attempt 4 extends the same originally contracted full-tour proof and starts from an open real Players panel.

- Learning harness attempt 4 failed at opening Reference while Players was already open: the existing full-shell modal veil intercepts the underlying top bar. Added an accessible Reference entry above that veil while retaining the mounted Players panel; retry 5 targets this diagnosed defect.

Learning attempt 5 passed Reference with Players open and Bank/public Dev interactions; failed on an incorrect Hand identifier. Corrected to the production physicalProps.hand identifier. Inspected capture still shows collapsed practice board; give the practice shell an exact remaining height. Reviewer also found beginner tutorial global occlusion coupling: added explicit synthetic-session isolation to both tutorial shells. VP copy now follows automatic winning reveal; private read-only inventory added to Reference for forced/pre-roll inspection.

Focused model/render rerun 2 passed 54/54 tests (GameControlsTourTests, GameFlightDeliveryTests, TranscriptBubbleCopyTests, GameDevCardPanelModelBuilderTests, GameScreenModelBuilderTests, GameBoardSnapshotRendererTests, TranscriptBubbleImageRendererTests), result `DerivedData/Flight/Logs/Test/Test-UnluckySevens-Workspace-2026.11.05_17-57-22--0800.xcresult`. Later forced-inventory/public-score invariance tests await the next scoped run. Core production tests previously passed 3/3. Normal tour runtime proof remains pending; implementation checkpoint is not milestone acceptance. Doc freshness passes; product/design/runtime owners updated, locked decisions/protocol unchanged.

Learning attempt 6 passed the full eight-step journey and real Players/state/frame preservation (`output/ui-screenshot-harness/20261106T015758Z-iphone`). Independent visual review found cropped practice board/seat content despite passing interactions. Synthetic boards now fit their current viewport rather than retaining an initial larger reference; compact practice seats and corner-safe insets address the clipping. Individual tour navigation targets are now 44pt. Rerun 7 checks these observed defects, with the already-locked four-player/forced-reference matrix.

Follow-up review corrected two inventory/identity edge cases: legacy public-only victory recovery no longer creates a fictitious owned VP tile, and compact seats retain names. Added regressions for forced-state inspection, hidden-VP public-score invariance, legacy zero-VP inventory, and one-card/off-turn explanations. The cost matrix uses a new DEBUG-only mixed fixture and leaves the protected Build Costs drawing/layout/preview components unchanged. Added observed-roll receipt journey and permanent-reference deduplication check within the original proof scope.

Normal matrix attempt 7 passed full tour, four-player named seats, and forced-action private inventory (`output/ui-screenshot-harness/20261106T020155Z-iphone`). Inspected normal four-player/forced-reference captures. Practice fitting no longer crops the scene; review prompted a full-width synthetic viewport and shorter instruction area to improve board usability, now under attempt 8. The real game's board geometry is unchanged.

Final focused regression run 3 passed 74/74 tests, including new forced/off-turn/exhausted/legacy inventory cases and public-score privacy for both local and opponent viewpoints. Result: `DerivedData/Flight/Logs/Test/Test-UnluckySevens-Workspace-2026.11.05_18-09-13--0800.xcresult`. `make doc-freshness` passes. Commit remains a verified model/normal-journey checkpoint; AX, cost/receipt journeys, final fresh review and completion contract remain pending.

Attempt 8 again exercised all eight controls, then failed because the newly added beginner-return assertion overlooked the existing first-use navigation coach. The harness now dismisses that coach before Exit; no UI defect was inferred from that failure. Source reconciliation against #17 found continuation was still in summary rather than prominent caption: moved it to caption, retaining the outcome in summary, and added all turn-publishing-family hierarchy assertions. Review traced a real #14 waiting-robber stack bug: separated inspection availability from play timing and added both robber-step routing/journey proof. These are sourced contract gaps within the original ticket set, not scope added for harness instability.

Scoped follow-up model run passed 30/30 tests for caption hierarchy, all turn publishing families, inventory timing, and waiting-robber route availability (`/tmp/uls-flight-slice-tests-r4.log`). Attempt 9 runs normal cost/receipt/waiting-inventory/learning journeys. Synthetic centering no longer applies the real host’s physical table offset, preventing cropped practice ports.

Normal cost inspection passed in attempt 9. Receipt journey attempt 1 stopped while the existing dice-result overlay still awaited its tap to dismiss; hierarchy showed Rolled 3 and 2, not a missing receipt computation. The journey now dismisses the settled dice result and any deferred purchase tip before asserting the receipt. Learning attempt 9 did not run because the catalog stopped at that receipt assertion. Product review refined seats to remove passive card backgrounds while retaining public/You/Left wording, and final-score rows now carry the same roster-owned emblem.

#3 explicitly records clipped large-text public-rail labels from prior evidence. Public Bank/Dev labels now size their height to text and permit fitting the full words; the shared Build Costs/name-tile component remains untouched. This correction is included in the locked AX capture matrix.

Follow-up validation run 5 passed 42/42 tests, including end-score mark/roster mapping and updated continuation hierarchy (`/tmp/uls-flight-slice-tests-r5.log`). Current source uses quiet passive text markers rather than four persistent card backgrounds; current actor remains distinct. Normal journey attempt 10 is running, followed by AX and supported iPad composition checks.
