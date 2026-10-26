# Beta 1.2 pre-roll map inspection — #54

## Purpose and Outcome

Implement approved [#54](https://github.com/kunal-sharda/UnluckySevens/issues/54): inspect the mounted map before rolling, then return to the existing Roll/Dev choices. The production slice and locked proof below supersede the historical preview scope.

## Execution Settings

- Validation profile: `standard`
- Delivery posture: `direct`
- Rationale: owner approved the real-component design and explicitly authorized production integration on 2026-10-25.

## Historical Preview Context and Boundaries

Reuse `GamePhysicalStartTurnView` and existing wood/felt/San Francisco controls. The board stays mounted at its original geometry. Inspecting changes only local presentation; it must not roll, consume cards, advance turns or publish state. In this preview, purchase/roll/Dev execution callbacks are inert; the Dev chooser may open locally. Real eligibility and board accessibility routing remain production follow-up work.

## Historical Preview Milestones

1. Add DEBUG-only preview using the production start-turn component and a wooden Inspect Board affordance.
2. Parent integrates only the `preview-map-inspection` UX Lab fixture over the existing `turnNeedsRoll` board. Capture prompt and inspected board, then assert returning restores choices and board mount/frame.
3. Show the two captures and obtain owner agreement. Only then lock full Core/query and UI proof and implement production routing.

## Historical Approval Gate — cleared

The original preview stopped after representative real-component screenshots. Owner approval is required before production wiring, additional nested states, fresh completion review, and completion gate. This gate follows the user's explicit preview request.

## Verification Contract and Fresh Review

Preview proof locked before implementation: canonical generation via `bash ./scripts/gen.sh`, focused Messages/XCUITest route on an isolated simulator, two captures (prompt and board inspection), tap inspection then return, compare original board frame and mount identity, and inspect retained screenshots. Maximum two visual rounds; initial plus two diagnosed infrastructure attempts per route. No shared simulator reset or shutdown-all is allowed while the user plays. Parent coordinates generation/build and isolated captures. Full rollout must separately cover both with/without playable Dev cards, compact/expanded hosts, accessibility and non-publication.

<!-- verification-contract:start -->
| ID | Class | Source | Acceptance | Verification | Evidence | Status | Rationale |
| --- | --- | --- | --- | --- | --- | --- | --- |
| MAP-001 | judgment | user request; #54 | Owner approves inspect and return composition | Two real-component captures and explicit owner response | report:owner-feedback-2026-10-24 | pass | Owner: Inspect the board is fine |
| MAP-002 | mechanical | #54 | Production inspection is local, preserves Roll/Dev legality and resets on canonical context changes | Focused pre-roll eligibility test, source review and canonical evidence in UI journeys | test:GamePreRollInspectionTests+pre-roll-Knight; report:map_fresh_review-2026-10-25; artifact:20261026T013432Z+013800Z+014105Z | pass | Four tests and all three local-state journeys pass |
| MAP-003 | observable | #54 | Unobscured map, clear return, same board within stable host, usable compact entry and larger text | Two normal UI journeys (expanded with Dev; compact Roll-only to expanded inspection), repeat with Dev at accessibility-medium; inspect at most three captures per round | artifact:20261026T013432Z-iphone; artifact:20261026T013800Z-iphone; artifact:20261026T014105Z-iphone; report:inspected-three-final-captures | pass | Expanded, compact-to-expanded and accessibility-medium pass |
| MAP-004 | mechanical | repo workflow | Final accepted implementation has owner docs and completion evidence | Post-approval doc freshness and completion gate | file:DESIGN.md; file:docs/product-specs/ui-flows.md; command:make-doc-freshness; report:recorded-scoped-evidence-and-fresh-review | pass | Owner docs and scoped verification recorded; standard completion gate passed |
<!-- verification-contract:end -->

<!-- fresh-review:start -->
| Reviewer | Required | Verdict | Evidence |
| --- | --- | --- | --- |
| constraint-auditor | yes | pass | report:map_fresh_review-final-2026-10-25 |
| SwiftUI-product-UX | yes | pass | report:map_fresh_review-final-2026-10-25; artifact:three-final-captures |
<!-- fresh-review:end -->

## Living Record

2026-10-24: direction accepted for a parallel preview, not full production. Existing start-turn veil blocks map viewing. Proposed Inspect Board button dismisses the veil locally; a compact Back to Roll button restores the same prompt/Dev chooser. No new typography or board composition.

## Validation and Outcome

Historical preview entry: component implementation pending scoped integration/capture by parent. DESIGN, UI flows, architecture, rules and QA owners intentionally unchanged while the direction is unapproved. No completed feature, device or milestone-release claim.

2026-10-24 preview round 1: canonical generation/build succeeded on dedicated simulator `ULS Beta12 Preview` (`686DF547-CAC8-467B-8298-89F70C08A878`), using target-only resets. Initial evidence: `output/ui-screenshot-harness/20261025T040640Z-iphone`. Build capture showed clipped top/table framing; Dev captures were readable. Before the single correction round, constrain each DEBUG overlay to the existing shell dimensions. Map preview also exposes its board diagnostics only in that fixture so the declared frame/mount assertions can run. Production accessibility remains unchanged. Round 1 is exploratory evidence, not final acceptance.

Round 1 outcome: all five catalog routes passed (three cost, one map journey, one lifecycle journey; eight attachments). All attachments inspected. Map and Dev layout were readable; Build and lifecycle showed the same top framing issue. Round 2 uses the bounded-shell correction and the declared map frame/mount checks. `make doc-freshness`, `make harness-audit`, shell syntax and whitespace checks passed; audit notices correctly retain pending owner judgments and future production reviews.

Round 2 (`output/ui-screenshot-harness/20261025T042213Z-iphone`): generated build passed. The Build route passed its content assertion, but inspected capture still clips the surrounding table header. Explicit shell bounds did not resolve the framing hypothesis; root cause is unproven. Do not mistake the UI test pass for visual acceptance. Two-round visual budget reached: no further layout edits or capture loops before owner feedback. Purchase availability copy remains synthetic and is not canonical eligibility proof.

Round 2 map outcome: `testPreviewMapInspection` passed with board frame and SKView mount identity equality asserted before inspection, during inspection and after return. Both attachments inspected: prompt and unobscured board retain geometry. Preview control callbacks invoke no game actions. This proves the local fixture interaction only; production accessibility, eligibility and non-publication journeys remain post-approval work.

Final preview checkpoint: round 2 catalog passed all five routes; all eight screenshot attachments inspected. Lifecycle surrounding-table framing is corrected and Dev/map are readable. Build surrounding-header clipping remains an explicit visual failure; no further edits within the two-round budget. SF typography is retained with board-token exception. Owner visual approval is pending; no production purchase/lifecycle wiring, fresh final reviews, completion gate, device acceptance or release claim.

Doc freshness: these three active plans own the prototype state and QA owns the new target-only simulator option. DESIGN, PRODUCT, product flows, decisions, architecture and README intentionally retain accepted production behavior; no production facts or setup changed. Historical/reference cleanup is unaffected. Screenshots/results remain ignored local evidence, with no durable binary admission.

2026-10-24 owner feedback: Inspect Board direction approved ("Inspect the board is fine"). This clears the visual approval gate for this track; full production behavior and its exact proof set still need to be locked before implementation. Current turn addresses design feedback across tracks, not production rollout.

## Approved production slice — 2026-10-25

The user's “go ahead with #54” supersedes the preview-only gate and authorizes standard/direct integration. Retain prior preview record as history. Reuse the accepted Inspect Board / Back to Roll composition; hide only its veil/choices during inspection. Keep board mounted and same geometry within a stable host; compact Inspect requests the existing expanded Messages presentation, which legitimately resizes the host once. Do not collapse on return. Roll/Dev callbacks remain canonical and are unavailable while inspecting. Keep Inspect/Back controls accessible and remove pre-roll accessibility hiding from the mounted board during inspection, prevent target commits, preserve any open chooser on return, and clear inspection on game/revision/reset changes.

Locked proof before edits: `DevCardInteractionResolverTests.testDraftPlayKnightIntentBeforeRollingIsLegalForCurrentPlayer` and focused new pre-roll availability/fixture tests for Roll-only, playable Dev and off-turn; generated build; production UI journeys with playable Dev expanded and Roll-only compact entry, plus playable-Dev accessibility-medium. UI compares canonical game/revision/hash before/after inspection and return, verifies no roll/purchase/publication, repeated inspection board frame/mount equality, public target interaction inertness, preserved Dev chooser, return control visibility and no board overlap. Capture prompt + inspected map at normal size, one inspected map at accessibility size (three total). No hardware release claim. No extra journeys unless demonstrated defect or sourced gap. QA initial-plus-ten ceiling applies to diagnosed focused reruns; no blind reruns. Run lanes serially and shut down task simulators/Simulator app afterward. Fresh constraint/product-UX review then `make completion-gate PLAN=docs/exec-plans/active/beta-1.2-map-inspection.md`. Owner updates: DESIGN and UI flows; QA only if harness behavior gains a reusable rule.

Ticket reconciliation: #51/#16/#53 closed with delivered evidence; #13/#14/#55/#3 updated with shipped scope and remaining acceptance; #54 marked in progress. GitHub remains task-status owner, not this plan.

Production implementation: shared production/preview inspection component, local shell state with canonical game/hash and mode/reset invalidation, guarded expansion callback, accessible Inspect/Back controls and inert target callback. Pre-roll choices scroll within the reserved Inspect control area on short hosts. Added Roll-only fixture, expanded pre-roll clean control, three eligibility tests and three scoped UI routes. Canonical generation and focused test run in progress; production acceptance remains pending.

Review clarification before UI proof: #54 requires accessible controls; it does not require new terrain/road narration. Existing DEBUG board-host identifiers prove mount/frame only, not production VoiceOver board narration. Narrowed design/flow wording accordingly. Header hit testing is disabled alongside the public rail during pre-roll so Settings/Game Information cannot open underneath inspection. Initial focused build rejected a test access to private selectedState; removed that redundant assertion (UI canonical evidence owns non-mutation proof) and reran the same four tests.

Focused validation: four selected tests passed, zero failures/skips (`DerivedData/Beta12MapUnit/Logs/Test/Test-UnluckySevens-Workspace-2026.10.25_18-26-32--0700.xcresult`). Fresh source reviewer `map_fresh_review` inspected #54, current diff, owner docs and reset/action boundaries; no source blockers after header correction. Runtime/capture review still pending. First normal UI catalog now running serially on the dedicated integration simulator.

UI attempt1 (`20261026T012732Z-iphone`) failed before inspection: Inspect exists at visible host-contained frame but is not hittable. Captured hierarchy exposes the inactive full-host dice control above it. Keep the historical prewarmed SceneKit surface, but explicitly route inactive dice below the choice layer with shell-level hit/accessibility gating. Captured prompt also shows an undimmed bottom stripe from reserving button space inside the veil; correction moves the veil to the full wrapper and disables the inner duplicate veil. This is the single visual correction round, within unchanged #54 scope. Attempt2 repeats the two normal journeys after these diagnosed fixes; no weaker assertions.

Compact harness gap found by source inspection while attempt2 runs: DEBUG beginFreshLobby unconditionally expands every configured launch fixture. Roll-only inspection fixture now opts out so Inspect itself must trigger expansion. No production launch behavior changes. Attempt2 already built before this harness-only correction; its compact result cannot serve as final compact-entry evidence. The next focused compact lane will use regenerated corrected fixture startup; normal expanded captures remain valid if passed.

Attempt2 expanded journey passed cleanly (`output/ui-screenshot-harness/20261026T013432Z-iphone/results/testPreRollMapInspectionPreservesDevChoices.xcresult`). Both named captures inspected: prompt and unobscured map are legible, the single veil is consistent, return stays below board, and all canonical/mount/chooser assertions passed. Stopped the stale compact lane before its test started and regenerated for focused compact attempt3; no failed compact assertion used as evidence. This is the second/final composition round; further lanes repeat the accepted composition at contracted host/text settings.

Compact attempt3 passed (`output/ui-screenshot-harness/20261026T013800Z-iphone`): asserted actual compact host before Inspect, expansion on Inspect, Roll-only choices before/after, unchanged game evidence and repeated expanded board mount/frame equality. The final accessibility-medium lane is running with the same production source; no layout edits after accepted round2. Fresh reviewer independently inspected both normal captures and raw result/evidence (revision8, needsRoll, identical hash/inventories and zero submissions), passing source and normal visuals while awaiting the remaining lane.

Accessibility-medium journey passed (`output/ui-screenshot-harness/20261026T014105Z-iphone`), including chooser preservation, unchanged canonical evidence, board mount/frame, inert board tap, clear return and minimum44-point target. Captured map inspected: terrain/ports/pieces unobscured, Back to Roll readable. Manifest confirms accessibility-medium and restoration to large. Existing inactive Bank/Dev public-rail label truncation is recorded in open #3; it is outside this inspection-control slice and is not claimed fixed.

Doc freshness: DESIGN and UI flows own the new inspection behavior; this active plan owns implementation/proof. Architecture, decisions, PRODUCT and README intentionally unchanged (no rules, boundary, setup, or design-principle changes). QA intentionally unchanged: new catalogs/fixtures use existing harness controls and retry policy. Historical/reference cleanup unaffected. `make doc-freshness` passes; no release/hardware claim.

Fresh final constraint/product-UX review (`map_fresh_review`) passed MAP001–003 after independently reading all four focused test results, all three UI results, canonical before/after evidence, AX manifest, final source and all three captures. No remaining blockers. Owner docs and evidence recorded for MAP004; selected standard completion gate is the final command before any completion claim. Task simulator shut down and Simulator app closed; booted-device list empty and no Simulator process.

Final outcome: `make completion-gate PLAN=docs/exec-plans/active/beta-1.2-map-inspection.md` passed (contract, harness audit, whitespace and standard generated build); doc-freshness passed. #54 scoped production work is complete: four focused tests, three clean UI journeys, three inspected final captures and fresh review pass. No device/milestone-release acceptance implied. Commit/push to beta-1.2 follows; GitHub #54 closure follows confirmed push.
