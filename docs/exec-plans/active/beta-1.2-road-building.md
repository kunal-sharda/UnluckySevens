# Beta 1.2 Road Building draft preview — #16

## Purpose and Outcome

Address [#16](https://github.com/kunal-sharda/UnluckySevens/issues/16): show Road Building as one two-road action, with visible pending selections and an explicit review step. Existing production applies one atomic Core intent but publishes immediately on the second selection.

## Execution Settings

- Validation profile: `standard`
- Delivery posture: `direct`
- Rationale: the issue requires an interaction checkpoint; current authorization requests implementation and report-back, not approval of an unseen composition.

## Context and Boundaries

This slice adds an isolated DEBUG local draft and controls over the existing mounted board. Core owns legality; no rules or protocol changes. Production Road Building behavior remains unchanged until owner approval. Cancel discards the draft; reopening starts empty. Preview confirmation acknowledges the local pair only and cannot publish or consume a card. Pending roads use numbered outlines distinct from solid committed roads. SF interface typography is retained.

## Milestones / Plan of Work

1. Add Core-query-backed draft selection/revision/revalidation and bounded controls.
2. Integrate the DEBUG fixture on the existing board, retaining frame and mount identity.
3. Capture empty, one-road and two-road review states; obtain owner feedback before production confirmation/publication routing.

## Approval Gate

Owner approves the three representative preview states. Maximum two visual rounds, initial plus two diagnosed infrastructure attempts per route. Pending approval blocks production routing, fresh completion review and completion gate. Parent coordinates generation and simulator harness runs; no shared simulator shutdown.

## Verification Contract and Fresh Review

Locked proof: scoped draft unit tests; existing atomic Core Road Building test; generated build; one UX Lab journey selecting two roads, undoing/changing/canceling, checking invariant canonical state and board frame/mount; three inspected screenshots. Stale draft tests verify Core revalidation. Final production follow-up must prove one publication, one audit and one receipt, accessibility and close/reopen policy.

<!-- verification-contract:start -->
| ID | Class | Source | Acceptance | Verification | Evidence | Status | Rationale |
| --- | --- | --- | --- | --- | --- | --- | --- |
| ROAD-001 | mechanical | #16 | Draft uses Core legality, supports revision/cancel and stale revalidation without mutation | Focused draft tests and source boundary inspection | report:component-review.xcresult-four-tests; report:core-road-building-one-test | pass | DEBUG local draft tests passed; production confirmation is separate |
| ROAD-002 | observable | #16 | Pending roads and review remain on the mounted board without state publication | Dedicated fixture journey and three captures | report:20261025T061738Z-road-building-journey; report:three-final-artifacts-inspected | pass | Full preview journey and no-overlap assertion pass; board, ports and pending markers visibly clear |
| ROAD-003 | judgment | #16 | Owner accepts two-road objective, pending markers and review controls | Owner screenshot feedback | report:owner-approval-2026-10-25 | pass | Owner accepted final presented designs; production proof remains separate |
| ROAD-004 | mechanical | #16 | Final production confirmation produces one atomic result and meets owner-doc contract | Post-approval tests and completion gate | file:docs/exec-plans/active/beta-1.2-approved-integration.md | pass | Production integration proof and standard gate passed; see aggregate evidence |
<!-- verification-contract:end -->

<!-- fresh-review:start -->
| Reviewer | Required | Verdict | Evidence |
| --- | --- | --- | --- |
| constraint-auditor | yes | pass | report:integration_auditor-final-2026-10-25; file:docs/exec-plans/active/beta-1.2-approved-integration.md |
| product-ux | yes | pass | report:integration_auditor-final-2026-10-25; file:docs/exec-plans/active/beta-1.2-approved-integration.md |
<!-- fresh-review:end -->

## Living Record

2026-10-24: user requested Road Building if unfinished. Issue/source inspection confirms the first edge is local but the second tap publishes immediately. This preview introduces a distinct two-selection review without changing production execution.

## Validation and Outcome

Implementation and parent integration in progress. Product/architecture/rules owner docs intentionally unchanged for the isolated preview; no final acceptance or release claim. No historical cleanup required.

2026-10-24 implementation checkpoint: local draft and action rail added with Core-derived first/second legality, replace-second, Undo, Start Over, Cancel and revalidated review value. Existing overlay model gains an empty-by-default pending-edge list; renderer shows outlined roads with SF numbered badges. Only the DEBUG fixture supplies that list. Registered `preview-road-building` on the existing after-roll fixture. Parent owns shell wiring and observable harness route.

Validation: Swift parser passed the new model/view/tests and touched board sources. `swift test --package-path Packages/ULS_CoreGame --filter TurnDevCardsV1Tests.testRoadBuildingPlacesTwoRoadsWithoutResourceCost` passed (1 test). New `GameRoadBuildingPreviewDraftTests` requires the generated extension-test lane and has not yet run. No simulator or final completion gate run by this worker.

Shell integration now routes only `preview-road-building` taps into the local draft, queries the static fixture state, and applies pending overlays to the existing BoardContainerView. The control rail sits at the shell bottom without a veil. Preview confirmation acknowledges both roads and clears local selection; it never invokes publication. Added `testPreviewRoadBuilding` with the three locked captures and assertions for selection, undo, reset, cancel/restart, confirmation, canonical evidence equality and board frame/mount identity. Parser/whitespace checks pass; runtime proof still pending parent execution.


2026-10-24 validation: generated extension test result `component-review.xcresult` passed all four `GameRoadBuildingPreviewDraftTests`; existing Core Road Building focused test passed (one). `testPreviewRoadBuilding` passed its full selection/review/undo/reset/cancel/restart/local-confirmation journey with canonical action evidence, board frame and mount identity unchanged. Evidence: `output/ui-screenshot-harness/20261025T060522Z-iphone/results/testPreviewRoadBuilding.xcresult` and its three exported attachments.

Artifact inspection: empty, first-road pending and two-road review screenshots were inspected. Header remains contained; all board hexes and both selected roads remain visible. Hollow bright road outlines and numbered badges distinguish pending roads from solid committed roads and unnumbered legal highlights. Progress and final explicit confirmation are legible. Review rail grows upward over the lower water margin, leaving the playable hex map visible in this iPhone fixture; compact/accessibility-size fit remains future production proof. Controls remain separate from the board rather than veiling it. No screenshot-driven design changes made. Owner judgment remains pending; these are preview passes, not production or milestone acceptance.

Doc freshness: this active plan owns preview state/evidence. Product, architecture, decisions and design owner docs intentionally unchanged because no production behavior or approved design contract changed. No historical cleanup or completion gate performed in this checkpoint.


Bounded correction: parent review identified a concrete obstruction overlooked in the initial visual assessment. Two-road review rail begins about 64pt above the board's lower edge, covering lower ocean/port margin. Keep the board frame unchanged; remove duplicate title/count and long guidance from the rail, retain one progress heading, 44pt revision controls and explicit confirm. Guidance remains in accessibility hints. This is the single correction round; ROAD-002 stays failed until the same route/captures verify the rail clears the board. No additional feature scope.


Final bounded correction result: `output/ui-screenshot-harness/20261025T061738Z-iphone/results/testPreviewRoadBuilding.xcresult` passes the full interaction/invariance journey, including the added rail-versus-board non-overlap assertion. Inspected all three final exported captures: the compact rail remains below the entire board/ocean frame, including lower ports; numbered pending roads and the explicit confirmation remain legible. ROAD-002 now passes for this preview fixture. No further design edits or capture rounds. Owner judgment ROAD-003 and production ROAD-004 remain pending; no completion gate or release acceptance implied.

Preview delivery closeout: canonical builds, focused model proof and scoped Messages UI journeys pass; actual artifacts inspected by parent and advisory design agent. Doc freshness and harness schema audit pass with expected pending owner judgments. No production routing, final fresh review, preview completion gate, device or accessibility-size acceptance is claimed. Product UI flows owns new timing requirement; QA owns capture routes; DESIGN/architecture/decisions/README intentionally unchanged. Historical/reference cleanup unaffected. Coherent preview checkpoint committed and pushed with parent delivery record.

### Visual acceptance — 2026-10-25

Owner response to the final resignation, Dev timing, shared-result and Road Building captures: “those looks great!” The presented direction is approved; this supersedes pending owner-judgment notes above. Production integration and its scoped behavior tests, fresh reviews and completion gate remain outstanding. This acceptance-only update changes no runtime code. Validation: doc freshness and whitespace checks; prior preview evidence remains applicable without rerunning simulator captures.

### Production implementation authorization — 2026-10-25

Owner approved the shown design, then explicitly requested production integration and tests. Standard/direct for this settled direction. Cancel, Undo and Start Over become actual dark-felt, light-outlined buttons distinct from the brown primary confirmation. Parent owns shell wiring and shared validation; road worker owns production draft/controls, pending-edge projection and focused tests.

Locked production proof before edits: draft tests covering legal dependent selections, replacement, undo/reset, invalid input and stale confirmation; view-model publication tests covering no publish before confirmation, one accepted atomic two-road result with one audit/receipt, duplicate confirmation rejection and failed-send retry; overlay tests that pending roads appear only during the road flow; production UI journey for select/undo/reset/cancel/reopen/confirm, stable board frame/mount and canonical state until confirm. At most three representative road captures in the shared batch plus one diagnosed correction round. Parent runs canonical generation, scoped simulator tests, UI harness and standard completion gate serially, with fresh constraint/product-UX review. Existing Core atomic test remains applicable; no Core/protocol behavior changes. Wider physical-device release acceptance is outside this implementation slice.

Road production component checkpoint: promoted the tested local draft to `GameRoadBuildingDraft`, retained preview aliases, introduced reusable production controls with dark felt/light-outline 44pt revision buttons and accessibility-size stacking, and projected only revalidated pending road IDs during road modes. Added `GameRoadBuildingProductionTests`: actual publication handoff verifies one pending send, accepted atomic pair/one revision/one audit/card decrement/no resource cost, rejects duplicate confirmations, and preserves canonical state after a failed send with explicit retry. Overlay tests exclude idle and invalid drafts. Existing four draft tests now cover the production type through the alias. Swift syntax and whitespace checks pass; generated compile/runtime/UI proof remain parent-coordinated and are not claimed yet. No viewmodel or engine changes were necessary; shell integration must retain draft while send is pending and on failure.

### Accessibility-size non-overlap correction — 2026-10-25

Production AX journey attempt 3 reached the final two-road review and demonstrated the predeclared non-overlap defect: rail minY605.833 versus board maxY687.000. Source and `/tmp/uls-ax-progress.png` inspection identify the duplicated progress heading plus four vertically stacked button rows as the cause. Controls-only correction retains full Dynamic Type text and 44pt targets: at accessibility sizes Cancel and Undo share a row, Start Over occupies the next row, and confirmation remains a separate brown row. The top table header already communicates road progress; the duplicate rail heading is omitted only at accessibility sizes, retaining progress and instructions as the rail's accessibility value/hint and retaining any exceptional guidance visibly. Normal-size appearance and button IDs/actions remain unchanged. No board geometry, identity, scale or shell reservations change. Parent will rerun only the failed production AX road journey, then inspect the accepted artifact. Syntax/whitespace checks pass; visual/runtime correction is not yet claimed verified.

## Final production integration evidence (2026-10-25)

Production behavior and scoped tests are recorded in [the approved integration plan](beta-1.2-approved-integration.md). It owns the clean six-route normal-size and two-route accessibility proof, final fresh review, build gate and pushed commits. This supersedes earlier production-pending progress notes; preview history remains unchanged. Broader milestone/device acceptance and unrelated queued scope are not claimed here.
