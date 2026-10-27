# Beta 1.2 tabletop learning and cost reference — #55

## Purpose and Outcome
Implement the owner-approved tabletop learning flow: a physical Build Costs reference, timely Dev/Bank teaching, compact suppression controls and clear Settings hierarchy. [#55](https://github.com/kunal-sharda/UnluckySevens/issues/55) remains the discoverability issue; #13/#14 own wider cost/timing coverage.

## Execution Settings
- Validation profile: `standard`
- Delivery posture: `direct`
- Rationale: the owner approved the visual checkpoint and explicitly authorized the refined implementation on 2026-10-27. Earlier checkpoint evidence is historical below.

## Context and Boundaries
Build has a persistent reference prop beside physical pieces. Costs move from individual pieces to a cream reference card containing Road, Settlement, City and Dev Card rows, canonical resource costs, 0/1/2 VP and city replacement wording. Legal rows start placement; Dev opens explicit purchase confirmation. The reference slides up onto felt without a scrim or board refit, remains available with tutorials off, fades for Reduce Motion and settles for Skip Animations. Omit the redundant introductory sentence.

Dev/Bank teaching appears when buying becomes legal on the local post-roll turn, at most once per turn while enabled. Wait for active placement/trade/dice/other-card/utility/send work. Explain the top Dev pile, sheep/wheat/ore cost and approximate Bank bars; empty means none. Never buy automatically. Remove permanent Tap labels but retain names, accessibility actions and usable top piles during teaching.

Hide this tip persists a topic preference without closing the current card; global off removes optional guidance while preserving explicit purchase confirmation and manual cost reference. Settings separates the global switch from individual topics. Existing lobby walkthrough/Rules stay available; player-header redesign, expanded tutorial curriculum and protocol/rule changes are excluded.

## Plan of Work and Locked Proof
Model suites: AppPreferencesTests, GamePurchaseTutorialTests, GameMotionPolicyTests (persistence/migration/category independence, eligibility/deferred once-per-turn teaching, next turn, private accepted-only purchase, motion).

Three scoped iPhone journeys: normal Build reference with teaching disabled and canonical road action; automatic Dev/Bank teaching with no repeat, checkbox/Settings restoration, master-off and Players replacement, then explicit purchase; accessibility-medium Build reference with scroll/footer containment. Maximum three final captures: Build reference, Dev/Bank teaching, AX reference. Source/policy tests prove fade/settled motion fallback. Serial canonical harness, initial plus ten diagnosed reruns ceiling, no blind retries. Fresh constraint/product-UX review and standard completion gate after frozen implementation. Commit/push coherent validated slices; shut down task simulators.

## Approval Record
Owner accepted the four-choice preview on 2026-10-27 with subsequent refinements above and said “let’s implement all these ideas.” No approval remains pending. New competing visual directions would require another checkpoint; routine implementation and defect fixes proceed directly.

## Verification Contract and Fresh Review
<!-- verification-contract:start -->
| ID | Class | Source | Acceptance | Verification | Evidence | Status | Rationale |
| --- | --- | --- | --- | --- | --- | --- | --- |
| GUIDE-001 | mechanical | user; Core boundary | Canonical costs/eligibility, explicit purchase, no protocol or rules changes | Focused models; source review | artifact:Test-UnluckySevens-Workspace-2026.10.27_00-52-44--0700.xcresult | pass | 20 scoped model tests pass |
| GUIDE-002 | observable | user | Reference remains available with teaching off, stable board, canonical build action | Normal Build journey | artifact:20261027T082515Z-iphone/testSlidingBuildCostsReference.xcresult | pass | Independently clean result and inspected capture |
| GUIDE-003 | judgment | user | Owner accepts implementation direction | Owner explicit authorization | report:owner-2026-10-27 | pass | Refined physical-card direction approved |
| GUIDE-004 | mechanical | user | Once-per-turn legal teaching and persistent individual/global preferences | AppPreferencesTests; GamePurchaseTutorialTests | artifact:Test-UnluckySevens-Workspace-2026.10.27_00-52-44--0700.xcresult | pass | Models pass; production trigger also requires GUIDE-005 |
| GUIDE-005 | observable | user | Automatic Dev/Bank teaching, explicit purchase, Settings/Players continuity and AX reference | Scoped Dev and AX journeys | artifact:20261027T081019Z-iphone; artifact:20261027T082821Z-iphone | pass | Dev and AX journeys pass; captures inspected; actual Reduce Motion verified |
| GUIDE-006 | judgment | user; DESIGN | Clear physical reference and compact controls | Fresh constraint/product-UX review | report:table_learning_review | pass | Fresh source, result and visual review passed with no blockers |
<!-- verification-contract:end -->
<!-- fresh-review:start -->
| Reviewer | Required | Verdict | Evidence |
| --- | --- | --- | --- |
| constraint-auditor | yes | pass | report:table_learning_review |
| product-ux | yes | pass | report:table_learning_review |
<!-- fresh-review:end -->

## Living Record
2026-10-26: original DEBUG four-choice preview passed focused simulator journey and was pushed as f3c2344. The owner subsequently replaced its redundant sentence and modal composition with the physical-reference direction above.

2026-10-27 implementation: new cost reference/shared resource row, stable per-game turn teaching identity from current player plus dice-stream state (no protocol fields), local preference ledger, active-route teaching guards, compact controls and Settings hierarchy. DESIGN and UI flows own the changed experience. PRODUCT, architecture, decisions and README intentionally unchanged; QA documents the scoped harness commands; no historical cleanup required.

Validation diagnoses retained for resumability:
- Model attempt1 used the UI-only scheme; generated scheme inspection selected UnluckySevens-Workspace. Attempt2 found body-local aliases in a helper; corrected to stored projection/currentMode. Attempt3 passed 20 tests, zero failures/skips.
- UI attempt1 (20261027T075424Z-iphone) captured the reference but could not locate its prop after dismissal. Actual still showed it; buildSpread lacked an accessibility containment boundary. Corrected child identifier propagation.
- UI attempt2 (20261027T075750Z-iphone) Build journey passed: readable costs/VP, 44-point footer, checkbox keeps occurrence usable, reopening without teaching, stable board/mount and canonical road placement. Dev failed before teaching. Initial fixture-reload hypothesis was tested by cold-launching end-turn-action.
- Dev attempt3 (20261027T080253Z-iphone) still failed; live preferences had no consumed marker, falsifying that hypothesis. Source root cause: an available trade composer model was incorrectly treated as an open Trade surface. Removed that check; active shellRoute/currentMode and canonical legality remain the gates.
- Fresh review found Players opening beneath Dev purchase and Settings global-off not clearing snapshot teaching. Fixes close the card before Players and react to master-off while preserving bare Dev confirmation; individual checkbox still preserves the occurrence. Same Dev journey now covers these edges. Dev attempt4 validates all corrections.

## Validation and Outcome
20 model tests and all three scoped UI journeys pass. Fresh constraint-auditor and product-UX review passed with no blockers. Final AX evidence is 20261027T082821Z-iphone: both footer labels fully readable after scrolling and runtime reduceMotion=true;spatial=false. Standard completion gate passed (verification contract, harness audit, diff checks and generated simulator build). Doc freshness passed. Task simulator was shut down, original Reduce Motion value restored, Simulator closed, and no booted devices or Simulator process remained. This validated implementation is ready for the required commit/push; #55 remains open for representative uncoached new-player discoverability evidence.

Dev attempt4 (20261027T080724Z-iphone) proved automatic appearance, live Bank interaction, checkbox behavior, no-repeat, Settings master-off retaining confirmation, and Players replacing the card. Final buy step failed because the test tried to close Players with the top-bar button beneath its scrim. Correct test navigation to the existing uls.gameInfo.close button; production source unchanged. Re-run Dev alone for a clean result.

Dev attempt5 passed cleanly (20261027T081019Z-iphone): automatic eligible-turn teaching, live Bank approximate supply, checkbox on/off, same-turn no-repeat through Settings, master-off retains explicit confirmation, Players replaces card, and explicit purchase publishes once. AX lane additionally enables the simulator's existing ReduceMotionEnabled setting before cold boot and asserts the actual SwiftUI environment/policy through a DEBUG-only marker; restore that simulator setting afterward. This satisfies the originally locked UI-setting motion proof without another lane.

AX attempt1 20261027T081335Z-iphone passed interactions and actual environment assertion reduceMotion=true;spatial=false, but screenshot inspection failed: the large-text all-tip button overflowed the reference bottom. Do not accept that visual proof. Force bounded ScrollView at accessibility sizes for the reference and matching Dev card layout; require both footer buttons hittable and fully within reference bounds before capture. This corrects a demonstrated layout defect within the locked AX contract. Rerun only AX, second visual round. Restore simulator Reduce Motion after task.

AX attempt2 (20261027T081808Z-iphone) screenshot shows both footer controls fully readable inside the card after scrolling. Failure was the assertion comparing the all-tip border against ScrollView's inner viewport minus an invented 8-point inset; observed maxY 776.5 versus inner viewport 776 includes a half-point outline. The card already has 16-point external padding. Correct to inner viewport plus a 1-point stroke/rounding tolerance; no production or design change, no extra visual iteration. Re-run for clean mechanical proof. The AX catalog documents its system Reduce Motion precondition, which the DEBUG marker verifies at runtime.

Final source audit closes a same-turn edge: manually opening eligible Dev teaching from Build before the automatic trigger runs must count as that turn's occurrence too. Manual opening now consumes the same persistent marker (only if enabled and Core says buying is legal), preventing an unsolicited duplicate on close. Existing claim tests cover repeat suppression; final normal reference journey adds the reference-to-Dev-confirmation path before its canonical road action.

AX attempt3 (20261027T082159Z-iphone) passed actions and Reduce Motion, but final screenshot remained at initial scroll position and cut the lower label. XCTest reports clipped button frames as hittable, so bounds alone did not establish full-label visibility. Bounded scrolling already produced a fully readable bottom state in attempt2; explicitly swipe the AX reference to its footer before capture. Production layout is unchanged; rerun for honest observable proof, not another design iteration.

Final normal Build journey 20261027T082515Z-iphone passed with the manual Dev reference path and canonical road action. Reviewer independently inspected that clean result/capture, model summary and clean Dev result. QA now owns the focused catalog/Reduce Motion preconditions; architecture, rules and protocol docs remain intentionally unaffected.
