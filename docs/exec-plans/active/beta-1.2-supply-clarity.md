# Beta 1.2 supply clarity — #51

## Purpose and Outcome

Implement [#51](https://github.com/kunal-sharda/UnluckySevens/issues/51): approximate Bank supply bars and removal of Trade stock badges, preserving exact local and selected quantities.

## Execution Settings

- Validation profile: `standard`
- Delivery posture: `direct`
- Rationale: owner-selected approximate bars and existing layout; no new composition or purchase/legality design. User explicitly requests feature implementation.

## Context and Boundaries

Branch beta-1.2 inherits Beta 1.1 local fixes; its device acceptance remains separate. Reuse GamePublicPileLevel thirds (resources: 13–19 high, 7–12 medium, 1–6 low); show empty distinctly. Preserve Dev pile mapping, Core eligibility, selected Give/Get quantities, own hand counts and protocol. Existing unused GameTabletopBankStackView has no callers and is outside the live route.

## Milestones / Plan of Work

1. Show approximate resource supply bars only in Bank; remove Trade stock badges and preserve selection/hand counts.
2. Add mixed-supply fixture, boundary/privacy tests and focused installed-host capture.
3. Inspect captures, fresh constraint/SwiftUI review, standard gate, commit and push.

## Verification Contract and Fresh Review

Locked proof: focused GamePublicPileLevelTests and existing GameTradePanelModelBuilderTests after canonical generation; one new supply route on iPhone and iPad, plus iPhone accessibility text-size route, using catalog runner and high/medium/low/empty fixture. Each route captures Bank and Trade (two states), checks expanded accessibility values, exact selected quantity and mounted-board preservation. Inspect screenshots. Standard completion gate and doc freshness after required fresh constraint/SwiftUI review. Initial plus at most two diagnosed retries per command; no unrelated catalogs or runtime scope expansion.

<!-- verification-contract:start -->
| ID | Class | Source | Acceptance | Verification | Evidence | Status | Rationale |
| --- | --- | --- | --- | --- | --- | --- | --- |
| SUP-001 | mechanical | #51 | Coarse Bank thresholds, empty bar, no public stock numbers or Trade badges; hand/selection and rules unchanged | focused tests and source review | report:unit11-bars; report:supply_review-source | pass | Presentation only |
| SUP-002 | observable | #51 | Bank and Trade readable with clear meaning across mixed supply and accessible text | three focused catalog runs and inspected screenshots | report:iphone042024-ipad042311-accessibility042928 | pass | Real components in Messages |
| SUP-003 | mechanical | repo workflow | Owner docs current and validation/push recorded | doc freshness and standard gate | report:owner-doc-source-review | pass | Gate is the final command after contract validation; no milestone closure |
<!-- verification-contract:end -->

<!-- fresh-review:start -->
| Reviewer | Required | Verdict | Evidence |
| --- | --- | --- | --- |
| constraint-auditor | yes | pass | report:supply_review-final-source-and-six-images |
| SwiftUI-accessibility | yes | pass | report:supply_review-final-source-and-six-images |
<!-- fresh-review:end -->

## Living Record

2026-10-21: locked proof before implementation. Trade Get uses bank counts for its existing selection limit; this change preserves that behavior and labels the level specifically as Bank supply, not another player's hand. No trade-rule correction is inferred from this presentation ticket.

## Validation and Outcome

In progress. DESIGN.md and UI flows own the presentation change. Architecture, protocol, rules and historical docs remain unaffected.

Generation and the first unit command were blocked by sandbox cache/CoreSimulator permissions before tests. Authorized reruns succeeded: 11 focused tests passed, zero failures, in /tmp/uls-beta12-supply-unit-r1.xcresult (log /tmp/uls-beta12-supply-unit-r1.log). The xcresult summary reader itself was sandbox-blocked; the test log retains the executed counts and success. Source reviewer found no blocking logic/privacy issue; visual verdict awaits captures. iPhone catalog attempt 1 in progress.

2026-10-21 owner revision: replace Hi/Med/Lo/Out with three-segment approximate Bank bars, zero filled segments for empty, and an explanation that the bars represent approximate cards left. Remove Trade Get supply badges, including exact stock in accessibility; keep selected Give/Get and own hand amounts. This explicitly supersedes #51's word-label direction. Existing thirds remain the coarse mapping so individual cards cannot be counted from fill geometry. Direct posture remains appropriate for the selected direction. Same proof set, new source invalidates earlier unit/UI proof; one initial run plus two diagnosed retries per revised route. Earlier iPhone word-label route passed, but is superseded. No iPad run started before interruption.

Revised source review found no blocking implementation findings; corrected the stale faded-card statement in DESIGN.md. Revised focused tests passed (11/11, /tmp/uls-beta12-bars-unit.xcresult). New iPhone bar capture attempt 1 running.

Revised iPhone and iPad routes passed on their first attempts: output/ui-screenshot-harness/20261022T042024Z-iphone and 20261022T042311Z-ipad. Inspected both Bank and Trade screenshots for each: coarse bars/empty outlines readable, explanation contained, exact selected/local amounts retained without Get stock badges. Independent reviewer agrees. Narrow iPad board crop is outside this unchanged board scope; frame/mount assertions pass. GitHub #51 now records the owner-approved bars/removal revision. Accessibility-medium route remains in progress.

Accessibility attempt 1 passed behavioral assertions but failed visual inspection: new Bank caption wrapped beneath the fixed board edge, and existing Trade ZStack headings overlapped selection summaries. These directly violate SUP-002 readability, so fix within the locked contract: accessibility-size Bank label “Bank supply” with the full approximation explanation in its VoiceOver hint; Trade row headings stack above their selection summaries at accessibility sizes. No board or game changes. Re-run accessibility route as attempt 2 (one diagnosed retry); normal-size iPhone/iPad paths are unchanged and retained evidence applies. Dev label truncation is pre-existing and outside changed Bank/Trade scope.

Accessibility attempt 2 passed in output/ui-screenshot-harness/20261022T042928Z-iphone. Inspected Bank and Trade screenshots: caption contained, three/two/one/empty bars legible, Trade headings and selected summaries separate, all changed controls contained. Manifests verify installed/built hashes and requested content size. Default-size iPhone/iPad proof remains applicable because the follow-up branches only at accessibility sizes; unit mapping/model tests unchanged. DESIGN.md and UI flows updated; architecture, rules, protocol, QA and historical owners intentionally unchanged. No physical-device or release claim.

Final independent constraint and SwiftUI/accessibility review passes SUP-001/002 after inspecting unit log, all six final images and three matched-hash manifests. Doc freshness passed. SUP-003 owner-doc verification passes; completion gate and commit/push are the final delivery operations, recorded below after execution.

Standard completion gate passed, exit 0 (/tmp/uls-beta12-bars-gate.log): contract, harness audit, whitespace, doc freshness, canonical generation and simulator build. The final source is ready for the authorized feature commit/push on beta-1.2. No runtime source changed after the passing evidence.
