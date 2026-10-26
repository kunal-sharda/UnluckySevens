# Beta 1.2 approved gameplay integration

## Purpose and Outcome

Integrate owner-approved resignation, contextual Build/Dev tutorials, new-card timing, shared final-result bubbles and reversible Road Building. Coordinates #13/#14/#16/#53/#55 and shared-results scope of #3; the linked feature plans retain preview evidence.

## Execution Settings

- Validation profile: `standard`
- Delivery posture: `direct`
- Rationale: approved UI and gameplay wiring require focused mechanical and observable proof plus fresh review, without milestone-release scope.
- Owner approved the final previews on 2026-10-25, then explicitly requested production integration, real secondary Road buttons, and tests. No new visual approval gate is required for this settled implementation.

## Context and Boundaries

Core remains the rules/legality/secrecy authority. No protocol changes. Tutorial preference is device-local, default enabled, repeats per scenario until disabled, and can be restored in Settings. Disabling teaching preserves required choices and explicit purchases. VP remains passive. Road revisions never publish; final confirmation publishes one pair only after authoritative validation. Rejected handoffs preserve retryable local intent. Public result artwork uses only public scores.

## Plan of Work and Locked Proof

Feature plans locked proof before edits. This aggregate records their integration: focused extension suites for AppPreferences, purchase tutorial events, screen model costs, road draft/publication/overlay, lifecycle presentation and resolver, and transcript copy/render/privacy. Focused Core cost query and existing atomic Road Building tests when that read-only query is added. Canonical generation/build; six cold production UI routes in `scripts/ui-screenshot-catalog-beta12-production.txt`, actual artifact inspection, and representative accessibility-size Road/lifecycle checks. Maximum two visual rounds; diagnosed infrastructure retries bounded by QA. Fresh independent constraint/product-UX review followed by this plan's completion gate. No hardware, cross-device delivery, TestFlight or milestone-release claim.

## Verification Contract and Fresh Review

<!-- verification-contract:start -->
| ID | Class | Source | Acceptance | Verification | Evidence | Status | Rationale |
| --- | --- | --- | --- | --- | --- | --- | --- |
| INT-001 | mechanical | owner; #13/#14/#55 | Persistent optional tutorials; explicit purchases; only accepted local buys produce private timing, no manual VP action | Preference, private delta, async purchase and canonical availability tests | file:output/beta12-production-models-final.xcresult; command:/tmp/uls-core-purchase-tests2.log; file:output/ui-screenshot-harness/20261025T231636Z-iphone/results/testGameplayActionBuyDevCardCommitsCanonicalState.xcresult; file:output/ui-screenshot-harness/20261025T231636Z-iphone/results/testProductionTutorialPreferenceAndInspection.xcresult | pass | Accepted and rejected handoffs, all five kinds, secrecy and persisted preference covered |
| INT-002 | mechanical | owner; #16 | Local cancel/undo/reset; revalidation; one atomic accepted road pair and duplicate/failure safety | Draft/publication tests and production UI journey | file:output/beta12-production-models-final.xcresult; file:output/ui-screenshot-harness/20261025T235959Z-iphone/results/testGameplayActionPlayRoadBuildingCommitsCanonicalState.xcresult; file:output/ui-screenshot-harness/20261025T234749Z-iphone/results/testGameplayActionPlayRoadBuildingCommitsCanonicalState.xcresult | pass | Normal and AX journeys preserve state/frame/mount through cancel/undo/reset and commit one pair |
| INT-003 | observable | approved designs | Real tutorial, lifecycle and Road controls readable and actionable, preserve board identity | Six-route cold harness plus scoped accessibility checks and inspected captures | pending | pending | In progress |
| INT-004 | mechanical | owner; #53 | Lifecycle cancel inert and confirm respects current eligibility | Presentation/resolver tests and production lifecycle journeys | pending | pending | In progress |
| INT-005 | observable | owner; #3 | Shared final result shows all names/public scores; no hidden-card leak | Privacy tests and three production renderer captures | file:output/beta12-production-models-final.xcresult; file:output/beta12-production-model-images; commit:fe09dd2 | pass | Parent and independent auditor inspected all three production render captures and privacy invariance |
| INT-006 | mechanical | AGENTS | Owner docs current and scoped validation/review recorded for delivery | Doc freshness, fresh review and scoped proof; completion gate and push recorded in outcome | pending | pending | In progress |
<!-- verification-contract:end -->

<!-- fresh-review:start -->
| Reviewer | Required | Verdict | Evidence |
| --- | --- | --- | --- |
| constraint-auditor | yes | pending | report:after-implementation |
| product-ux | yes | pending | report:after-captures |
<!-- fresh-review:end -->

## Living Record

2026-10-25: Parallel feature workers implemented road, lifecycle, and result components; root integrates tutorials/shell. First generated test batch ran 63 tests, 7 failures: 5 screen-model assertions used source compiled before the inspection filter correction; 2 purchase tests used an inconsistent board/master seed fixture rejected by transport persistence. Fixture now derives the board seed and checks transport round-trip. All other scoped tests passed, including actual async road publication/duplicate/failure, lifecycle and renderer privacy. Retain `output/beta12-production-models.xcresult` as exploratory evidence; final corrected batch pending.

Road advisory review identified active board taps/underlying props during send, stale draft on external revision, and retained submission anchor on cancel. Integration guards taps, hides old props without changing board reservations, resets draft on external revision, and clears anchor on dismissal. Production new-card events now originate exclusively from accepted local publication callbacks, not general remote state deltas.

## Validation and Outcome

In progress. Feature sources/tests and owner docs are being integrated; no completion claim. Architecture/protocol/locked rules intentionally unchanged; no historical cleanup needed.

Corrected proof: `output/beta12-production-models-final.xcresult` passes 63/63 extension tests; `/tmp/uls-core-purchase-tests2.log` passes 11 Core query/atomic-road tests. Core initial test compilation missed two explicit lastRoll initializer arguments; corrected tests now pass without production changes. Three exported shared-result images inspected independently by parent and fresh auditor, including all four long player names and public scores. Shared-result block committed/pushed as `fe09dd2`. Six production UI routes running; accessibility follow-up is locked to `scripts/ui-screenshot-catalog-beta12-accessibility.txt` at accessibility-medium.

Fresh source review identified a sending-state observation gap: the shell's canonical projection can remain unchanged after failed handoff. Added a narrow subscription to `isSendingGameUpdate`, preserving the existing projection architecture while ensuring retry controls re-enable. This is a sourced correctness correction; the final Road UI confirmation will use the rebuilt source.

First three production UI routes passed (purchase/timing, tutorial toggle/inspection, Road revision/confirm). Parent inspected all three captures: board/header intact and Road rail below the complete ocean viewport. Road capture exposed a contradictory top prompt (“Place the Second Road” with two pending roads); correct that to “Review Both Roads” with one focused resolver test in the single correction round. Final road confirmation capture also includes the sending-state subscription correction.

First installed lifecycle route failed at Game Actions discovery; retained hierarchy shows Players remains after a correctly centered ellipsis tap in a compact host. Narrow source correction moves its full hit rectangle inside the Button label. First accessibility Road route also started compact, with a zero-size board and therefore no legal target; it is not a verdict on expanded Road layout. Add a DEBUG-only explicit expanded-screenshot control (existing host callback, no state mutation) and require expanded usableCanvas evidence before lifecycle/Road baselines. Retain both failure bundles; rerun only the four affected/unrun production routes and two accessibility routes, with diagnosis metadata. No compact-host acceptance claim.

Attempt 2 standard (`output/ui-screenshot-harness/20261025T233315Z-iphone`) stopped in screenshot setup: stale panel existence during clean-fixture hiding meant the header Expand control was absent. Retained hierarchy contains only Restore Chrome. AX attempt 2 (`20261025T233335Z-iphone`) was intentionally interrupted before repeating the superseded helper; neither is product acceptance. Helper now returns if the host is already expanded and otherwise restores header chrome directly, requests expansion, and verifies host state. Attempt 3 uses `20261025T234148Z-iphone` (standard) and `20261025T234203Z-iphone` (accessibility), pending. Dedicated simulator parallelism is explicitly owner-authorized; generation was serialized and DerivedData isolated.

Attempt 3 AX reached the production ready state and demonstrated a product layout defect: vertically stacked accessibility revision buttons put the rail at y605.83, above board bottom y687 (assertion2519). Preserve the failure bundle; correct the rail within INT-003 before a focused retry. Standard attempt 3 stalled before any route in a four-minute MobileSMS termination command (black simulator still); attempted to terminate only that stuck simctl client, but it had already exited; the existing cold-start script proceeds with launch/termination/hash checks. No product verdict derives from that stall.

Standard attempt 3 ultimately failed at helper5456 before gameplay: retained AX tree still shows Restore Chrome, while later still shows header. Scoped fix adds a dedicated DEBUG Road fixture that requests expansion before loading/hiding; actual expanded canvas is awaited without reopening. Lifecycle helper awaits restored-header disappearance/presence transition explicitly. Standard attempt 4 is the focused rerun. AX attempt 4 separately validates the rail geometry correction (Cancel/Undo row, Start Over row, no repeated heading, unchanged text sizes/board).

AX Road attempt 4 passed; parent and auditor inspected its capture and action evidence under `output/ui-screenshot-harness/20261025T234749Z-iphone`: clear board, readable buttons, rev9→10, one card consumed, two roads placed, resources unchanged. Lifecycle in that run and default Road attempt 4 (`20261025T235353Z-iphone`) failed after Players/owned-card taps. Decoded events match current element centers; no stale-coordinate or product defect established. Concurrent runner contention is possible, not proven. Normalize those two helpers to explicit hittable/enabled checks and one existing current-frame tap, then run remaining proof serially (default attempt5; AX lifecycle-only attempt5). No rerun of passed AX Road required. No whole-screen AX claim; existing rack label truncation is outside these scoped controls.

Serial attempt5 default Road passed in `20261025T235959Z-iphone`; parent inspected final screenshot. The following lifecycle process stalled in XCTest's accessibility existence request at test t37.42s for over four minutes, with simulator later at SpringBoard, before any lifecycle assertion. Retain staging diagnostics; interrupt only its xcodebuild process. Next lifecycle-only run uses the other dedicated simulator serially to isolate the failing simulator host; no production change or unchanged product-failure rerun.
