# Beta 1.2 purchase-cost visibility — #13

## Purpose and Outcome

Implement [#13](https://github.com/kunal-sharda/UnluckySevens/issues/13): inspect canonical construction and Dev purchase costs even when unavailable. #14 owns arrival/owned-card timing separately.

## Execution Settings

- Validation profile: `standard`
- Delivery posture: `checkpointed`
- Rationale: user explicitly requests seeing the proposed direction and agreeing before implementation, then seeing the finished result.

## Context and Boundaries

Current owner direction (2026-10-24): retain the previously shown Build/Dev panels as optional **tutorial pop-ups**, with a global disable control inside each. The prior anchored-hints proposal is superseded. [#55](https://github.com/kunal-sharda/UnluckySevens/issues/55) owns preference/routing and Bank discoverability; #14 already owns Dev-deck discoverability. Authoritative intended behavior is in [UI flows](../../product-specs/ui-flows.md#contextual-tutorial-pop-ups-and-tabletop-discoverability). This is approved requirements scope, not acceptance of the unresolved Build framing defect or unshown disabled-mode interaction.

Preserve physical tabletop pieces, resource artwork, wooden labels and mounted board geometry. Build remains inspectable during ordinary action phase; retain stable Road/Settlement/City choices, costs and concise private unavailability reasons. Public Dev pile opens a cost/availability inspection before an explicit purchase. Core owns costs and eligibility; no rules, secrecy or protocol changes. DESIGN and UI flows currently describe hiding unavailable actions and must change with accepted production behavior.

## Milestones / Plan of Work

1. Present the proposed interaction and copy using a compact mixed-availability example; obtain direction agreement.
2. Build minimum real-component UX Lab proof for Build and Dev purchase; inspect at most three representative states per round, two rounds maximum. Obtain visual acceptance before production routing.
3. Implement accepted routing and canonical query-backed availability, validate, show final screenshots, commit and push to beta-1.2.

## Approval Gate

Owner approval required for proposed direction and then representative real-component proof. Pending approval blocks productionization, fresh review and completion gate. No production changes in initial proposal turn. User requested this gate explicitly.

## Verification Contract and Fresh Review

Initial proof is source inspection plus owner response. Before prototype edits, lock exact fixture/capture routes and bounded retries. Before production edits, lock focused canonical cost/eligibility tests and inspection/no-publication journeys for affordable, resource-short, no-piece/no-placement, wrong-phase and empty-deck cases. Final standard completion gate and doc freshness required; no milestone release claim.

<!-- verification-contract:start -->
| ID | Class | Source | Acceptance | Verification | Evidence | Status | Rationale |
| --- | --- | --- | --- | --- | --- | --- | --- |
| COST-001 | judgment | user request; #13 | Owner agrees direction and representative layout before production | explicit owner approval after proposal and real-component proof | report:pending | pending | Approval gate |
| COST-002 | mechanical | #13 | Canonical costs/eligibility and secrecy preserved; inspection publishes nothing | source and focused model/action tests locked before implementation | report:pending | pending | No duplicate rules |
| COST-003 | observable | #13 | Mixed availability remains readable and inspectable without moving board | bounded fixture journeys and inspected captures locked before implementation | report:round-2-framing-failure | fail | Header framing remains incorrect; content assertions alone are insufficient |
| COST-004 | mechanical | repo workflow | Owner docs, final gate and branch delivery recorded | doc freshness and standard completion gate | report:pending | pending | Final stage only |
| COST-005 | mechanical | user clarification; #55; UI flows | Build/Dev panels act as optional tutorial pop-ups with persistent global disable and Settings re-enable, preserving gameplay | Lock preference and enabled/disabled journey tests before implementation | report:pending | pending | Requirement recorded; no implementation yet |
| COST-006 | judgment | user request; #55; #14 | Bank and Dev purchase entry are discoverable with tutorials enabled or disabled | Representative new-player observation and accessible action-name checks | report:pending | pending | Track Bank explicitly and reuse Dev requirement |
<!-- verification-contract:end -->

<!-- fresh-review:start -->
| Reviewer | Required | Verdict | Evidence |
| --- | --- | --- | --- |
| constraint-auditor | yes | pending | report:after-owner-approval |
| SwiftUI-product-UX | yes | pending | report:after-owner-approval |
<!-- fresh-review:end -->

## Living Record

2026-10-23: inspected current design and kickoff sequence; working tree clean on beta-1.2. Proposal keeps Build pieces in stable positions with resource costs beneath; unavailable choices show a reason rather than disappearing. Tapping public Dev pile opens cost and explicit Buy Dev Card action. Await direction response; no runtime edits.

## Validation and Outcome

Planning only. Active plan is the changed owner of proposed execution state. Product/design/architecture/QA owners intentionally unchanged until accepted implementation. No builds/tests needed for this proposal; no completion claim.

2026-10-24: owner authorizes parallel preview batch (purchase costs, map inspection, lifecycle). Direction accepted; real-component visual approval remains pending. Lock prototype proof: one iPhone-large Messages catalog route, three captures (mixed Build, affordable Dev purchase, unavailable Dev purchase), DEBUG-only local controls and Core cost constants. Maximum two visual rounds; initial plus two diagnosed infrastructure retries. Use dedicated simulator with target-only reset to preserve user sessions; generation/build coordinated centrally. No production routing, rule edits, fresh final review or completion gate before owner visual approval. SF typography throughout UI; board tokens retain serif.

2026-10-24 preview round 1: canonical generation/build succeeded on dedicated simulator `ULS Beta12 Preview` (`686DF547-CAC8-467B-8298-89F70C08A878`), using target-only resets. Initial evidence: `output/ui-screenshot-harness/20261025T040640Z-iphone`. Build capture showed clipped top/table framing; Dev captures were readable. Before the single correction round, constrain each DEBUG overlay to the existing shell dimensions. Map preview also exposes its board diagnostics only in that fixture so the declared frame/mount assertions can run. Production accessibility remains unchanged. Round 1 is exploratory evidence, not final acceptance.

Round 1 outcome: all five catalog routes passed (three cost, one map journey, one lifecycle journey; eight attachments). All attachments inspected. Map and Dev layout were readable; Build and lifecycle showed the same top framing issue. Round 2 uses the bounded-shell correction and the declared map frame/mount checks. `make doc-freshness`, `make harness-audit`, shell syntax and whitespace checks passed; audit notices correctly retain pending owner judgments and future production reviews.

Round 2 (`output/ui-screenshot-harness/20261025T042213Z-iphone`): generated build passed. The Build route passed its content assertion, but inspected capture still clips the surrounding table header. Explicit shell bounds did not resolve the framing hypothesis; root cause is unproven. Do not mistake the UI test pass for visual acceptance. Two-round visual budget reached: no further layout edits or capture loops before owner feedback. Purchase availability copy remains synthetic and is not canonical eligibility proof.

Final preview checkpoint: round 2 catalog passed all five routes; all eight screenshot attachments inspected. Lifecycle surrounding-table framing is corrected and Dev/map are readable. Build surrounding-header clipping remains an explicit visual failure; no further edits within the two-round budget. SF typography is retained with board-token exception. Owner visual approval is pending; no production purchase/lifecycle wiring, fresh final reviews, completion gate, device acceptance or release claim.

Doc freshness: these three active plans own the prototype state and QA owns the new target-only simulator option. DESIGN, PRODUCT, product flows, decisions, architecture and README intentionally retain accepted production behavior; no production facts or setup changed. Historical/reference cleanup is unaffected. Screenshots/results remain ignored local evidence, with no durable binary admission.

2026-10-24 owner feedback: rejects modal purchase/build presentation in favor of real pieces on felt; asks about optional tutorial/help guidance. Prior panels are superseded design candidates, not a production direction. Proposed replacement for discussion: Build spreads pieces directly onto felt with small resource costs beneath; tapping selects a piece and highlights legal board placements; unavailable reason appears beside that piece. Dev selection shows cost and an explicit Buy affordance adjacent to the deck, without a framed modal or board veil. Optional Show Hints adds anchored explanations to the same interaction; do not create two divergent gameplay modes. Proposal is not yet accepted or implemented. Existing Build framing failure remains recorded but further polishing the rejected panel is out of scope.

2026-10-24 clarified owner requirement: the earlier Build and Dev panels are exactly the requested tutorial pop-ups, each containing “Disable tutorial pop-ups”. This supersedes the earlier interpretation that the panels were rejected outright and the unaccepted anchored-hints proposal. Created Beta 1.2 issue #55 and linked existing Dev discoverability in #14; Bank now has an explicit requirement. Further scenarios are permitted but not yet enumerated or committed. Revised enabled/disabled UI and first-show/repeat policy still need a locked proof set before implementation. Keep the known Build framing failure open.

Requirement-recording slice: product UI flows and this active plan updated; GitHub #55 owns task status. No runtime edits, simulator captures, build, fresh implementation review or completion gate in this slice. Validation: doc freshness and whitespace checks. DESIGN, architecture, decisions, QA and historical docs intentionally unchanged because the approved future flow is recorded in its product owner, while shipped appearance, rules and validation procedures are unchanged.
