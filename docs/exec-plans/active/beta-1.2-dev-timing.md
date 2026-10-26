# Beta 1.2 new Dev Card timing tutorial — #14 / #55

## Purpose and Outcome

Preview the newly purchased Dev Card timing guidance requested by the owner on 2026-10-24. [#14](https://github.com/kunal-sharda/UnluckySevens/issues/14) owns Dev discovery/timing and [#55](https://github.com/kunal-sharda/UnluckySevens/issues/55) owns optional contextual tutorials. Explain where a bought card lives and why an action card cannot be played yet, with the passive Victory Point exception explicit.

## Execution Settings

- Validation profile: `standard`
- Delivery posture: `direct`
- Rationale: requested addition joins the still-unapproved tutorial visual checkpoint. Implement an honest DEBUG preview and obtain owner visual judgment before production trigger wiring.

## Context and Boundaries

Use the existing private `GameDevCardPanelModelBuilder` output and production portrait card artwork. The view accepts a requested kind but renders only when that kind exists in the viewer's `newCounts` and card models. No raw opponent inventory, Core rules, transport, purchase, Play or Reveal callbacks. The parent owns fixtures, shell/settings integration, shared harness edits, canonical generation and simulator execution. This slice owns one new DEBUG view and this plan.

The owner-approved repeat policy is every relevant scenario until globally disabled. Acknowledging one occurrence dismisses only that occurrence; Disable tutorial pop-ups uses the shared preference callback. Re-enable remains in Settings. Actual purchase-trigger detection and repeat/persistence behavior remain production work after approval, not claims made from an always-loaded fixture. Product owner: [UI flows](../../product-specs/ui-flows.md#contextual-tutorial-pop-ups-and-tabletop-discoverability).

## Milestones / Plan of Work

1. Inspect canonical private Dev presentation and new-card fixtures.
2. Author a focused new-card tutorial with real art, location path, timing explanation, Got it and global disable.
3. Parent captures two representative states: new Knight and new Victory Point. Inspect them with the surrounding mounted table visible.
4. After owner approval, separately lock production triggers, secrecy/preference behavior tests and completion proof.

## Approval Gate

Owner approves the two real-component captures before production routing. One initial visual round and one corrective round; at most three states per round (only two planned). Pending approval blocks final fresh review and completion gate. Harness failure follows the QA diagnosed retry budget, with evidence retained; do not expand to unrelated Dev scenarios.

## Verification Contract and Fresh Review

Locked preview proof: DEBUG boundary/source inspection, canonical generated build by parent, two Messages UX Lab screenshots and interaction assertions that acknowledgement/disable publish no action and preserve board frame/mount. The new-card appearance must come from private canonical panel output. No new engine tests are required because this slice changes no engine behavior. Production trigger/persistence and device acceptance are outside this checkpoint.

<!-- verification-contract:start -->
| ID | Class | Source | Acceptance | Verification | Evidence | Status | Rationale |
| --- | --- | --- | --- | --- | --- | --- | --- |
| DEVT-001 | mechanical | #14; #55; user request | Only DEBUG fixture UI; no gameplay or reveal callback; private model only | Source boundary inspection and generated build | report:beta12-component-review | pass | Generated build and three private fixture tests passed; source callbacks inspected |
| DEVT-002 | observable | #14; user request | New action card explains next-turn wait and Hand / Dev Cards location; VP explains passive score and automatic winning reveal | Two fixture captures and inspected copy/art | report:20261025T060522Z-dev-timing | pass | Both actual PNGs inspected; explanation and controls readable without clipping |
| DEVT-003 | observable | #55; user frequency answer | Got it dismisses this occurrence; global Disable uses shared preference; board and canonical evidence stay unchanged | Parent scoped tutorial harness assertions | report:20261025T060522Z-dev-timing | pass | Knight dismiss and VP disable passed board/frame/canonical invariance; preview scope only |
| DEVT-004 | judgment | user visual-checkpoint requirement | Owner approves concrete timing tutorial before production | Explicit owner response to captures | report:owner-approval-2026-10-25 | pass | Owner accepted final presented designs; production proof remains separate |
| DEVT-005 | mechanical | repo workflow | Owner facts and final scoped validation recorded | Doc freshness and post-approval standard completion gate | file:docs/exec-plans/active/beta-1.2-approved-integration.md | pass | Production integration proof and standard gate passed; see aggregate evidence |
<!-- verification-contract:end -->

<!-- fresh-review:start -->
| Reviewer | Required | Verdict | Evidence |
| --- | --- | --- | --- |
| constraint-auditor | yes | pass | report:integration_auditor-final-2026-10-25; file:docs/exec-plans/active/beta-1.2-approved-integration.md |
| SwiftUI-product-UX | yes | pass | report:integration_auditor-final-2026-10-25; file:docs/exec-plans/active/beta-1.2-approved-integration.md |
<!-- fresh-review:end -->

## Living Record

2026-10-24: inspected `GameDevCardPanelModelBuilder`, `GameDevCardPanelModel`, portrait-card renderer and current UX Lab default state. Current default fixture has new VP=1 but no new action card, so new Knight fixture must explicitly provide that canonical inventory. `newCounts` is derived from the acting viewer's `visibleDevCards`; no UI eligibility calculation is added. Existing presentation still contains legacy winning-reveal action strings; this tutorial exposes no such action, and broader cleanup is outside this new-file slice.

## Validation and Outcome

DEBUG preview implemented and captured; owner visual approval remains pending. This plan owns proposed execution/design state. Parent updates product UI flows for the requested scenario; DESIGN, architecture, decisions and historical docs intentionally remain unchanged for an unapproved preview. No production, final-review or completion claim.

Implementation handoff: added `GameDevTimingPreviewView(panel:kind:onDismiss:onDisableTutorialPopups:)`. It exposes IDs `uls.preview.devTiming.surface`, `.explanation`, `.dismiss`, `.disableTutorials`. New fixtures `preview-dev-timing-knight` / `Preview new Knight` and `preview-dev-timing-vp` / `Preview new Victory Point` provide only one new private card, no old cards, and after-roll turn state. Parent explicitly expanded this worker's ownership to the now-released fixture file. The view reuses private panel output, renders production card art, provides Hand / Dev Cards navigation guidance, and has no Play or Reveal control. Dismiss and disable are callbacks so the parent owns local presentation/shared preference; repeat policy remains every scenario until disabled.

Exact focused mechanical addition: `GameDevTimingPreviewFixtureTests` verifies new Knight is not actionable, VP has no play/reveal action in its subthreshold fixture, and another viewer receives no card identity. These tests validate the fixture/private-model inputs, not automatic winning reveal or production purchase-trigger behavior. DEBUG parser and whitespace checks passed for the view/fixtures/tests; test execution, generated build, UI captures and behavior checks remain parent-owned and pending. No production routing or completion claim.


Focused fixture validation: parent reports all three `GameDevTimingPreviewFixtureTests` passed in `output/beta12-component-review.xcresult`. This supports new-card non-actionability and private fixture inputs only; timing UI captures/invariance and owner judgment remain pending.

Parent integrated the timing surface via canonical private panel query in play-card inspection mode, with local occurrence dismissal and shared DEBUG preference. Settings exposes the same re-enable toggle for timing fixtures as cost fixtures. Production event routing is still untouched. First Knight UI route passed with unchanged canonical evidence and board frame/mount; screenshot inspected and readable. VP route pending.


Final preview evidence for this round: parent reports both `testPreviewNewKnightTiming` and `testPreviewNewVictoryPointTiming` passed in `output/ui-screenshot-harness/20261025T060522Z-iphone/results/`. Agent inspected both PNGs: `attachments/testPreviewNewKnightTiming/96F101D6-2B90-44A8-BFDF-42A587A9B4A2.png` and `attachments/testPreviewNewVictoryPointTiming/C52369EA-6273-4824-800F-777E1C6D81BA.png`. Card identity, location path, full timing/VP exception text, Got it and Disable are visible and readable; table header remains visible. Knight acknowledgement and VP global disable remove the surface with unchanged canonical action evidence and board frame/mount. Source confirms the latter uses the same DEBUG preference as purchase tutorials; Settings opts in for both fixture prefixes. No visual correction requested: this is a deliberately instructional surface and its size follows the displayed guidance, but owner taste approval remains pending.

Evidence limits: these fixture routes do not prove a real purchase invokes the tutorial, every-occurrence event routing, cross-launch preference persistence, re-enable specifically from a timing fixture, dynamic-type/device acceptance, or automatic winning reveal behavior. The shared preference/re-enable source is wired, but no claim is made beyond the exercised paths. DEVT-001/002/003 pass only the locked DEBUG preview scope; DEVT-004/005 and fresh reviews remain pending. No productionization or completion gate before owner approval.

Preview delivery closeout: canonical builds, focused model proof and scoped Messages UI journeys pass; actual artifacts inspected by parent and advisory design agent. Doc freshness and harness schema audit pass with expected pending owner judgments. No production routing, final fresh review, preview completion gate, device or accessibility-size acceptance is claimed. Product UI flows owns new timing requirement; QA owns capture routes; DESIGN/architecture/decisions/README intentionally unchanged. Historical/reference cleanup unaffected. Coherent preview checkpoint committed and pushed with parent delivery record.

### Visual acceptance — 2026-10-25

Owner response to the final resignation, Dev timing, shared-result and Road Building captures: “those looks great!” The presented direction is approved; this supersedes pending owner-judgment notes above. Production integration and its scoped behavior tests, fresh reviews and completion gate remain outstanding. This acceptance-only update changes no runtime code. Validation: doc freshness and whitespace checks; prior preview evidence remains applicable without rerunning simulator captures.

### Production integration authorized — 2026-10-25

Owner explicitly requests integrating all approved designs and writing tests. Standard/direct; visual checkpoint passed. Lock proof before edits: AppPreferences persistence/default/re-enable tests; private new-card delta and purchase-inspection tests; generated extension build and scoped resolver/model suites; installed Messages journeys for Build inspection, Dev explicit confirmation/new-card dismissal/disable, Settings re-enable, Road review, and lifecycle cancel/confirm. Use at most two visual rounds, with diagnosed infrastructure retries under QA. Fresh constraint/product-UX review and completion gate follow implementation. No protocol or rule changes. Production tutorial state must be local; disabled tutorials preserve required choices and explicit purchase confirmation.

## Final production integration evidence (2026-10-25)

Production behavior and scoped tests are recorded in [the approved integration plan](beta-1.2-approved-integration.md). It owns the clean six-route normal-size and two-route accessibility proof, final fresh review, build gate and pushed commits. This supersedes earlier production-pending progress notes; preview history remains unchanged. Broader milestone/device acceptance and unrelated queued scope are not claimed here.
