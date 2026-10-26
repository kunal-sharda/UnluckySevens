# Beta 1.2 individual tutorial controls — #55

## Purpose and Outcome

Give every existing production contextual tip both “Don't show this tip again” and “Disable all tutorial tips”, with individual and all-tip restoration in Settings. Follow-up to the delivered approved-integration plan, linked to [#55](https://github.com/kunal-sharda/UnluckySevens/issues/55).

## Execution Settings

- Validation profile: `standard`
- Delivery posture: `direct`
- Rationale: owner settled both controls and Settings restoration; use existing felt/wood controls and navigation rather than a new visual direction.

## Context and Boundaries

Device-local preferences only; existing global false values remain false. Separate existing Build costs, Dev purchase, action-card timing and Victory Point explanation tips. Dismiss/Close affects only an occurrence. Disabling an individual tip does not change other choices. Global off pauses all tips without erasing individual choices; Enable all tips explicitly restores all. Required purchase confirmation, game rules and card privacy stay intact. The proposed Bank/Dev introductory tip and replacement of permanent pile instructions remain separate #55 design work; do not expose settings for an unimplemented tip.

## Plan of Work and Locked Proof

Implement preferences, shared suppression controls, production routes and Settings. Extend AppPreferencesTests for defaults, persistence, old global-off migration, independent categories, master pause/resume and enable-all; retain GamePurchaseTutorialTests for accepted-only private timing and explicit purchase behavior. Generated build, one extended production preference UI journey at normal and accessibility-medium sizes: suppress only Build, verify Dev teaching remains, suppress all from Dev without buying, restore individual Build in Settings, verify repeat after ordinary Close, unchanged canonical state/mounted board. Existing purchase UI journey proves successful local purchase still shows timing and both controls. At most three captures (normal Build tip + Settings list; AX Settings list), two visual rounds. Serial harness, initial plus ten diagnosed focused reruns per QA, no blind retry or adjacent scope growth. Fresh constraint/product-UX review then selected completion gate; shut down task simulator and close Simulator.

## Verification Contract and Fresh Review

<!-- verification-contract:start -->
| ID | Class | Source | Acceptance | Verification | Evidence | Status | Rationale |
| --- | --- | --- | --- | --- | --- | --- | --- |
| TIP-001 | mechanical | user | Independent persistent tip preferences, compatible global switch and restoration | AppPreferencesTests | artifact:Test-UnluckySevens-Workspace-2026.10.25_19-51-25--0700.xcresult; report:tutorial_controls_review-final | pass | Defaults, migration, independence, persistence and restoration pass |
| TIP-002 | mechanical | user; ui-flows | Both controls wired to current tip/all; confirmation and privacy preserved | GamePurchaseTutorialTests and production source review | test:GamePurchaseTutorialTests; report:tutorial_controls_review-final; artifact:20261026T025349Z-iphone | pass | Explicit purchases and private timing preserved |
| TIP-003 | observable | user | Both actions readable, Settings restores tips, no game mutation | Normal/AX preference journeys and existing purchase journey; three inspected captures | artifact:20261026T025349Z-iphone; artifact:20261026T030647Z-iphone; report:three-captures-inspected | pass | Three scoped journeys and inspected captures pass |
| TIP-004 | mechanical | AGENTS | Owner docs and evidence current | Doc freshness, fresh review and completion gate | file:docs/product-specs/ui-flows.md; command:make-doc-freshness; report:tutorial_controls_review-final | pass | Owner docs/evidence recorded; standard completion gate passed |
<!-- verification-contract:end -->

<!-- fresh-review:start -->
| Reviewer | Required | Verdict | Evidence |
| --- | --- | --- | --- |
| constraint-auditor | yes | pass | report:tutorial_controls_review-final-2026-10-25 |
| product-ux | yes | pass | report:tutorial_controls_review-final-2026-10-25 |
<!-- fresh-review:end -->

## Living Record

2026-10-25: inspected current global-only implementation, approved-integration and purchase plans. Existing normal dismissal already preserves preference. Locked the above scope/proof before source edits. Owner docs: UI flows owns preference semantics; DESIGN only if component language changes. No protocol, architecture, locked rule or release changes.

## Validation and Outcome

Scoped implementation complete: 13 focused tests, three UI journeys, three inspected captures, independent review and standard completion gate pass.

Implementation: stable persisted category IDs in GameTutorialTip, per-tip suppression plus existing master preference, shared 44-point suppression controls, production Build/Dev/new-action/VP routing, and a scrollable Tutorial Tips Settings destination. Master resume preserves choices; explicit Enable all resets them. Existing purchase UI coverage is reused through a shared helper; only the scoped new wrapper omits its extra screenshot to keep the three-capture contract.

Focused test result: 13 tests passed, zero failures/skips (`DerivedData/Beta12Tips/Logs/Test/Test-UnluckySevens-Workspace-2026.10.25_19-51-25--0700.xcresult`). Source review `tutorial_controls_review` found no blockers in persistence, category isolation, migration, confirmation/privacy, controls or navigation; final observable review awaits captures. Normal UI catalog running serially.

Normal UI catalog passed on first attempt (`output/ui-screenshot-harness/20261026T025349Z-iphone`): independent Build suppression, unaffected Dev teaching, global suppression retaining explicit Buy, persisted individual selection through master resume, individual re-enable, Enable all restoration, normal Close/reopen, unchanged canonical state and board frame/mount. Successful purchase route retains one canonical purchase and both new-card suppression controls. Parent and reviewer inspected both normal captures; readable controls/list, Enable all reached by scrolling. AX lane runs next with same source.

AX harness preparation stalled for over two minutes in optional `simctl terminate MobileSMS` (PID14689, guarded by `|| true` in harness). Stopped only that confirmed client; remaining install hash checks and required per-route shutdown/boot remain intact. No production change or test assertion weakened; test had not started.

The same simulator then stalled in required `simctl launch MobileSMS` before test start. Stopped that launch client and its harness, shut down the integration simulator, and switched the focused AX lane to the existing dedicated accessibility simulator. Retain `20261026T030116Z-iphone` as preparation failure only; attempt2 changes the simulator host, not product/assertions.

AX attempt2 passed cleanly (`output/ui-screenshot-harness/20261026T030647Z-iphone`): accessibility-medium, matching built/installed binary, preference restoration/purchase safety/44-point controls/local game evidence and board assertions pass. Parent inspected AX Settings capture: labels wrap readably, scroll reaches lower controls and Enable all. All three contracted UI journeys pass; no visual correction required. Earlier simulator preparation failure is not acceptance evidence.

Doc freshness: UI flows updated for independent category suppression, master pause and Settings restoration. This plan owns scope/evidence. DESIGN intentionally unchanged because existing felt/wood/SF and Settings navigation patterns are reused; PRODUCT, architecture, decisions, README and QA intentionally unchanged (no rule, boundary, setup or harness-policy change). Historical/reference cleanup unaffected. `make doc-freshness` passed. Bank/Dev permanent-label replacement and new introductory scenario remain #55 follow-up, with no unimplemented settings advertised.

Fresh final reviewer independently verified all scoped result bundles, canonical evidence, manifests, final source and three captures; TIP001–003 pass, no blockers. Owner-doc/evidence work recorded for TIP004; selected standard completion gate runs next. Both task simulators are shut down and Simulator closed (empty booted list, no Simulator process).

Final outcome: `make completion-gate PLAN=docs/exec-plans/active/beta-1.2-tutorial-controls.md` passed (selected contract, harness audit, whitespace, canonical generation/build); doc-freshness passed. Commit/push to beta-1.2 follows. #55 remains open for the separate top-pile discoverability redesign and uncoached new-player evidence. No milestone-release/hardware claim.
