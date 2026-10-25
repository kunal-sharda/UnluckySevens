# Beta 1.2 lifecycle surface preview — #53

## Purpose and Outcome

Preview [#53](https://github.com/kunal-sharda/UnluckySevens/issues/53): one felt surface whose content changes between current-game actions and confirmations. This is a visual checkpoint, not a lifecycle behavior rewrite or completion of #15 device acceptance.

## Execution Settings

- Validation profile: `standard`
- Delivery posture: `checkpointed`
- Rationale: user explicitly requests parallel design previews and agreement before finished implementation.

## Context and Boundaries

Retain the existing felt palette, wooden action-button treatment, SF typography and mounted game context. Only a new DEBUG-only component is authored. Preview taps change local presentation state; no Core actions, transport, canonical state, resign, draw or host-end publication. Production Game Information, confirmations and legality remain unchanged. Parent owns shared host integration and simulator execution; this slice owns its preview component and plan.

## Milestones / Plan of Work

1. Inspect the existing Game Information and lifecycle confirmation components.
2. Present a single framed felt surface with readable actions and in-place confirmation content.
3. Capture three representative states through the existing Messages UX Lab harness on an isolated simulator: actions, draw-proposal confirmation and resignation confirmation. Inspect once, allow one correction round, then pause for owner visual approval.
4. Only after approval, lock production behavior/legality proof and implement accepted routing in a subsequent slice.

## Approval Gate

Stop after three representative captures. User approval of this concrete visual direction is required before productionization, fresh final reviews or the completion gate. Initial direction approval authorizes the DEBUG preview only. No completion claim while approval is pending.

## Verification Contract and Fresh Review

Locked preview proof: source boundary inspection, canonical project generation/build through the parent coordinator, three Messages harness captures on an isolated device, and screenshot inspection. Maximum two visual rounds. An infrastructure retry requires retained diagnostics and a recorded correction; no repeated unchanged runs. Final production tests and exact routes are locked after owner approval and before production edits.

<!-- verification-contract:start -->
| ID | Class | Source | Acceptance | Verification | Evidence | Status | Rationale |
| --- | --- | --- | --- | --- | --- | --- | --- |
| LIFE-001 | mechanical | #53; user request | Preview cannot publish lifecycle actions or alter production routing | DEBUG boundary and callback source inspection | report:debug-source-boundary | pass | Local state transitions only; no gameplay callbacks |
| LIFE-002 | observable | #53 | Actions, draw-proposal confirmation and resignation confirmation share one coherent surface with readable controls | three harness captures and inspection | report:20261025T060522Z-lifecycle | pass | Three captures inspected; current journey passed; owner taste judgment remains separate |
| LIFE-003 | judgment | user request | Owner approves concrete preview before production work | explicit owner response to captures | report:owner-approval-2026-10-25 | pass | Owner accepted final presented designs; production proof remains separate |
| LIFE-004 | mechanical | repo workflow | Accepted final behavior and required validation recorded before delivery claim | later scoped tests, doc freshness and completion gate | report:pending | pending | Deferred until approval |
<!-- verification-contract:end -->

<!-- fresh-review:start -->
| Reviewer | Required | Verdict | Evidence |
| --- | --- | --- | --- |
| constraint-auditor | yes | pending | report:after-owner-approval |
| SwiftUI-product-UX | yes | pending | report:after-owner-approval |
<!-- fresh-review:end -->

## Living Record

2026-10-24: inspected GameTurnGameInfoView, GameLifecycleConfirmationView, GameTabletopActionButtonStyle and lifecycle guidance. Existing confirmation nests a second framed panel and veil inside the framed Players surface. Proposed preview uses one frame, changes its title/body in place, keeps a clear Back path, and separates dangerous actions with spacing and explanatory copy. Font/materials reuse production definitions. No production changes.

## Validation and Outcome

Preview in progress. This active plan owns proposed execution/design state. DESIGN, product flows, architecture, decisions and QA owners intentionally unchanged until acceptance. Parent coordinates isolated build/capture; no test, build or completion claim yet.

Parent coordination: fixture `preview-lifecycle` uses the existing turnAfterRoll board and overlays this DEBUG component at zIndex6. Three captures are menu, draw-proposal confirmation and resignation confirmation. End Game and draw voting are reachable local presentation states; they are not extra captures in this first checkpoint. Parent owns harness/tests. Component IDs use `uls.preview.lifecycle.*`.

2026-10-24 preview round 1: canonical generation/build succeeded on dedicated simulator `ULS Beta12 Preview` (`686DF547-CAC8-467B-8298-89F70C08A878`), using target-only resets. Initial evidence: `output/ui-screenshot-harness/20261025T040640Z-iphone`. Build capture showed clipped top/table framing; Dev captures were readable. Before the single correction round, constrain each DEBUG overlay to the existing shell dimensions. Map preview also exposes its board diagnostics only in that fixture so the declared frame/mount assertions can run. Production accessibility remains unchanged. Round 1 is exploratory evidence, not final acceptance.

Round 1 outcome: all five catalog routes passed (three cost, one map journey, one lifecycle journey; eight attachments). All attachments inspected. Map and Dev layout were readable; Build and lifecycle showed the same top framing issue. Round 2 uses the bounded-shell correction and the declared map frame/mount checks. `make doc-freshness`, `make harness-audit`, shell syntax and whitespace checks passed; audit notices correctly retain pending owner judgments and future production reviews.

Round 2 (`output/ui-screenshot-harness/20261025T042213Z-iphone`): generated build passed. The Build route passed its content assertion, but inspected capture still clips the surrounding table header. Explicit shell bounds did not resolve the framing hypothesis; root cause is unproven. Do not mistake the UI test pass for visual acceptance. Two-round visual budget reached: no further layout edits or capture loops before owner feedback. Purchase availability copy remains synthetic and is not canonical eligibility proof.

Final preview checkpoint: round 2 catalog passed all five routes; all eight screenshot attachments inspected. Lifecycle surrounding-table framing is corrected and Dev/map are readable. Build surrounding-header clipping remains an explicit visual failure; no further edits within the two-round budget. SF typography is retained with board-token exception. Owner visual approval is pending; no production purchase/lifecycle wiring, fresh final reviews, completion gate, device acceptance or release claim.

Doc freshness: these three active plans own the prototype state and QA owns the new target-only simulator option. DESIGN, PRODUCT, product flows, decisions, architecture and README intentionally retain accepted production behavior; no production facts or setup changed. Historical/reference cleanup is unaffected. Screenshots/results remain ignored local evidence, with no durable binary admission.

2026-10-24 owner feedback: remove explanatory flavor text from the Game Actions list. Applied narrowly to the DEBUG preview: title, icon and navigation affordance remain; consequence copy in confirmations remains. Scope is a copy-removal revision; source syntax and whitespace checks plus doc freshness only in this turn, no new simulator/build/capture or completion claim. A new visual pass should be batched with the next accepted preview direction.

2026-10-24 revision authorization: owner asks to fix the chunk before approval, accepts resignation content but requests a smaller panel and improved buttons, and permits parallel work. Remain standard/checkpointed: DEBUG preview refinement only, not production rollout. This new owner-feedback round permits one initial capture batch and one diagnosed correction batch. Lock proof before integration: iPhone-large isolated Messages harness; purchase captures are Build tutorial, Dev tutorial, and tutorials-disabled tabletop (three total); lifecycle captures are title-only actions, draw confirmation, compact resignation (three). Assert header containment and board frame/mount stability when disabling, no canonical action evidence changes, disable controls from both purchase panels, and Settings re-enable. Bank/Dev tap-purpose cues are opt-in fixture presentation only. Source check preview isolation and persistent DEBUG preference. No additional tutorial scenarios, full production preference/non-publication proof, final fresh review or completion gate before owner feedback. Root owns shell/settings integration, tests, plan and captures; parallel workers own lifecycle component, rack cue component and read-only framing diagnosis.

Revision attempt 1: canonical generated build passed; Build screenshot/header assertion passed with host canvas and shell both `(0,112,402,748)` and Settings `(16,122,44,44)`. Evidence `output/ui-screenshot-harness/20261025T045731Z-iphone`. Journey stopped at disable-control lookup. Exported hierarchy proves the parent purchase identifier overwrote all descendant IDs, including the visible button (not a simulator failure). Correction: explicit accessibility containment at purchase root and place 44pt hit region inside button label. Retry only after this correction; no unrelated layout/behavior changes. This is the single correction capture batch.

Revision attempt 2: Build framing and disable transition passed (board frame/mount and canonical evidence unchanged). Journey stopped at Dev button assertion: hierarchy shows `uls.tabletop.devDeck` on a generic Group wrapping an unlabeled Button. Correct the opt-in preview branch by attaching label, ID and accessibility semantics directly to its Button; production branch remains unchanged. Final focused rerun uses the original initial-plus-two diagnosed retry allowance. This is a mechanical accessibility correction with no new visual direction or polishing round. Run lifecycle first so independent preview evidence is retained. No retries after attempt 3.

Owner frequency answer: tutorial pop-ups appear every time the relevant scenario occurs until disabled. Updated product owner; individual scenario triggers and production wiring remain pending.

Final lifecycle evidence for this revision: `output/ui-screenshot-harness/20261025T050826Z-iphone/results/testPreviewLifecycle.xcresult` passed; all three attachments inspected. Game Actions has titles only; draw/resign panels fit their content and use compact adjacent wooden controls. No production lifecycle callbacks connected. Owner approval of revised sizing/buttons remains pending.

Final Build retry failed the header-containment assertion again. Same diagnostic host snapshot as passing attempts (bounds402x802, safe20/0/34/0, usable402x748, expanded/narrowShort, revision5), but canvas and shell now y=-38.33 instead of112; Settings y=-28.33. Evidence `output/ui-screenshot-harness/20261025T050826Z-iphone/results/testPreviewBuildCosts.xcresult`; exported diagnostics inspected. Whole-host translation is intermittent; root top-pinning hypothesis did not solve it and is removed rather than retained as an unsupported workaround. Build retry budget exhausted: no more Build runs or layout guesses. Next investigation must inspect the exact Apple host/containment APIs and construct a minimal repro before broad changes. Lifecycle independent journey passed. Dev independent journey has not executed because the catalog stops at first failure; run its initial attempt separately without changing its design. Chunk is NOT ready for overall approval or completion.

Revision delivery status: lifecycle compact-layout journey is verified independently; the overall preview chunk is not ready for approval because Build/Dev share intermittent host displacement (#56). Purchase retry logs are owned by the purchase plan. QA and product UI flows updated for preview setup and tutorial repeat policy; DESIGN/architecture/decisions and historical docs intentionally unchanged pending production acceptance. Doc freshness and source checks passed; no completion gate or final review before owner approval.


2026-10-24 new owner-directed design pass: user rejected the compact resignation result as uglier and explicitly requested agent design work. Remain standard/checkpointed; this authorizes a fresh DEBUG refinement round, not production lifecycle wiring. The prior capture proves navigation only and is not visual approval. Lock proof before editing: parent-generated build, source inspection for local-only callbacks, existing lifecycle XCUITest journey with actions/draw/resign captures (at most three), one batched inspection and at most one corrective round. Keep Playing replaces the redundant header Back control in the journey. No extra lifecycle scenarios or standalone agent simulator runs. Final user judgment remains pending.

Design diagnosis and direction: the rejected panel combined an inset question, separately aligned body, tiny unequal wooden controls and a heavy outer frame. This produced an unfinished lower-right void and competing outlines. Preserve the felt, SF type, consequence copy and 44-point targets. Align question and body on one left edge, keep one Close affordance, use equal-width actions with a single warm wooden safe action and a quiet destructive text action. A narrower content-sized surface and quieter gold keyline reduce the amount of covered board without shrinking the controls. At accessibility sizes the actions stack at full width; the existing scroll fallback keeps content reachable. This is refinement of the established material world, not a replacement visual system.

Agent source pass: implemented the above DEBUG revision in `GameLifecycleDesignPreviewView`. Both action labels now share semantic subheadline weight; the destructive text uses a lighter warm red against felt, with explicit wording and destructive role. No source outside the component changed. Swift DEBUG parser and scoped whitespace checks passed. Parent must still build, run the adjusted lifecycle journey, inspect the three actual screenshots, and report pending owner approval; parser success is not layout or interaction proof. Production/design owner docs remain intentionally unchanged because this is an unapproved preview. No completion gate or final review was run.


New design round evidence: parent reports `testPreviewLifecycle` passed in `output/ui-screenshot-harness/20261025T060522Z-iphone/results/testPreviewLifecycle.xcresult`. Agent inspected all three exported PNGs and manifest: Actions `3836DD5E-3D0B-4960-8ACA-2E4FC88E345E.png`, Resign `C0FB4143-8593-4803-B21A-1A2CD5AA953D.png`, Draw `E3DD7E16-6A1B-4559-B615-77E474CB0267.png`. All are under that run's `attachments/testPreviewLifecycle/`. Title/body alignment is coherent; the action pair now fills the bottom row; question/consequences/actions are readable without clipping. The surrounding header and tabletop remain visible in all three images. The lighter destructive text reads distinctly from the safe wooden action without a second competing border.

Advisory design verdict: suitable to show for owner judgment, not automatically accepted. This is a clearer confirmation within the existing felt utility-panel language; it still covers the center of the board and retains a conventional modal composition. If the owner dislikes that overall form, another spacing tweak is unlikely to resolve the preference. No concrete clipping/overlap defect in this captured size warrants a correction round. Preserve this capture, await owner direction, and do not run an open-ended polish loop. No accessibility-size/device judgment or production behavior acceptance is implied. LIFE-003 remains pending.

### Visual acceptance — 2026-10-25

Owner response to the final resignation, Dev timing, shared-result and Road Building captures: “those looks great!” The presented direction is approved; this supersedes pending owner-judgment notes above. Production integration and its scoped behavior tests, fresh reviews and completion gate remain outstanding. This acceptance-only update changes no runtime code. Validation: doc freshness and whitespace checks; prior preview evidence remains applicable without rerunning simulator captures.
