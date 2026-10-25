# Beta 1.2 map inspection preview — #54

## Purpose and Outcome

Preview [#54](https://github.com/kunal-sharda/UnluckySevens/issues/54): inspect the mounted map before rolling, then return to the existing Roll/Dev choices. User authorizes parallel visual previews, with agreement before full implementation.

## Execution Settings

- Validation profile: `standard`
- Delivery posture: `checkpointed`
- Rationale: a new pre-roll interaction requires owner visual acceptance. This slice is a DEBUG fixture prototype only.

## Context and Boundaries

Reuse `GamePhysicalStartTurnView` and existing wood/felt/San Francisco controls. The board stays mounted at its original geometry. Inspecting changes only local presentation; it must not roll, consume cards, advance turns or publish state. In this preview, purchase/roll/Dev execution callbacks are inert; the Dev chooser may open locally. Real eligibility and board accessibility routing remain production follow-up work.

## Milestones / Plan of Work

1. Add DEBUG-only preview using the production start-turn component and a wooden Inspect Board affordance.
2. Parent integrates only the `preview-map-inspection` UX Lab fixture over the existing `turnNeedsRoll` board. Capture prompt and inspected board, then assert returning restores choices and board mount/frame.
3. Show the two captures and obtain owner agreement. Only then lock full Core/query and UI proof and implement production routing.

## Approval Gate

Stop after representative real-component screenshots. Owner approval is required before production wiring, additional nested states, fresh completion review, and completion gate. This gate follows the user's explicit preview request.

## Verification Contract and Fresh Review

Preview proof locked before implementation: canonical generation via `bash ./scripts/gen.sh`, focused Messages/XCUITest route on an isolated simulator, two captures (prompt and board inspection), tap inspection then return, compare original board frame and mount identity, and inspect retained screenshots. Maximum two visual rounds; initial plus two diagnosed infrastructure attempts per route. No shared simulator reset or shutdown-all is allowed while the user plays. Parent coordinates generation/build and isolated captures. Full rollout must separately cover both with/without playable Dev cards, compact/expanded hosts, accessibility and non-publication.

<!-- verification-contract:start -->
| ID | Class | Source | Acceptance | Verification | Evidence | Status | Rationale |
| --- | --- | --- | --- | --- | --- | --- | --- |
| MAP-001 | judgment | user request; #54 | Owner approves inspect and return composition | Two real-component captures and explicit owner response | report:pending | pending | Approval gate |
| MAP-002 | mechanical | #54 | Preview inspection changes local state only and invokes no game actions | Source inspection and dedicated DEBUG fixture isolation | report:debug-source-boundary | pass | Preview callbacks only change local state |
| MAP-003 | observable | #54 | Map becomes unobscured; return restores choices without board remount or movement | Focused fixture test and inspected screenshots | report:round-2-map-journey | pass | Two captures inspected; frame and mount assertions pass on inspection and return |
| MAP-004 | mechanical | repo workflow | Final accepted implementation has owner docs and completion evidence | Post-approval doc freshness and completion gate | report:pending | pending | Future production stage |
<!-- verification-contract:end -->

<!-- fresh-review:start -->
| Reviewer | Required | Verdict | Evidence |
| --- | --- | --- | --- |
| constraint-auditor | yes | pending | report:after-owner-approval |
| SwiftUI-product-UX | yes | pending | report:after-owner-approval |
<!-- fresh-review:end -->

## Living Record

2026-10-24: direction accepted for a parallel preview, not full production. Existing start-turn veil blocks map viewing. Proposed Inspect Board button dismisses the veil locally; a compact Back to Roll button restores the same prompt/Dev chooser. No new typography or board composition.

## Validation and Outcome

Component implementation pending scoped integration/capture by parent. DESIGN, UI flows, architecture, rules and QA owners intentionally unchanged while the direction is unapproved. No completed feature, device or milestone-release claim.

2026-10-24 preview round 1: canonical generation/build succeeded on dedicated simulator `ULS Beta12 Preview` (`686DF547-CAC8-467B-8298-89F70C08A878`), using target-only resets. Initial evidence: `output/ui-screenshot-harness/20261025T040640Z-iphone`. Build capture showed clipped top/table framing; Dev captures were readable. Before the single correction round, constrain each DEBUG overlay to the existing shell dimensions. Map preview also exposes its board diagnostics only in that fixture so the declared frame/mount assertions can run. Production accessibility remains unchanged. Round 1 is exploratory evidence, not final acceptance.

Round 1 outcome: all five catalog routes passed (three cost, one map journey, one lifecycle journey; eight attachments). All attachments inspected. Map and Dev layout were readable; Build and lifecycle showed the same top framing issue. Round 2 uses the bounded-shell correction and the declared map frame/mount checks. `make doc-freshness`, `make harness-audit`, shell syntax and whitespace checks passed; audit notices correctly retain pending owner judgments and future production reviews.

Round 2 (`output/ui-screenshot-harness/20261025T042213Z-iphone`): generated build passed. The Build route passed its content assertion, but inspected capture still clips the surrounding table header. Explicit shell bounds did not resolve the framing hypothesis; root cause is unproven. Do not mistake the UI test pass for visual acceptance. Two-round visual budget reached: no further layout edits or capture loops before owner feedback. Purchase availability copy remains synthetic and is not canonical eligibility proof.

Round 2 map outcome: `testPreviewMapInspection` passed with board frame and SKView mount identity equality asserted before inspection, during inspection and after return. Both attachments inspected: prompt and unobscured board retain geometry. Preview control callbacks invoke no game actions. This proves the local fixture interaction only; production accessibility, eligibility and non-publication journeys remain post-approval work.

Final preview checkpoint: round 2 catalog passed all five routes; all eight screenshot attachments inspected. Lifecycle surrounding-table framing is corrected and Dev/map are readable. Build surrounding-header clipping remains an explicit visual failure; no further edits within the two-round budget. SF typography is retained with board-token exception. Owner visual approval is pending; no production purchase/lifecycle wiring, fresh final reviews, completion gate, device acceptance or release claim.

Doc freshness: these three active plans own the prototype state and QA owns the new target-only simulator option. DESIGN, PRODUCT, product flows, decisions, architecture and README intentionally retain accepted production behavior; no production facts or setup changed. Historical/reference cleanup is unaffected. Screenshots/results remain ignored local evidence, with no durable binary admission.
