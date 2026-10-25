# Beta 1.2 trade bubbles

## Purpose and Outcome

Implement [#52](https://github.com/kunal-sharda/UnluckySevens/issues/52): a compact tabletop exchange in the Messages conversation bubble. The user rejected the prior slide-like composition and approved trying the independently reviewed direction: tightly gathered full-strength production cards on felt, subordinate sender line, exact per-resource quantities without totals, compact named recipients with individual responses.

## Execution Settings

- Validation profile: `standard`
- Delivery posture: `direct`
- Rationale: owner approved the final shared-result previews on 2026-10-25 and explicitly authorized production integration and tests. Existing trade acceptance remains unchanged.

## Context and Boundaries

Use beta-1.2 and preserve concurrent supply-clarity changes. Only trade receipt, card grouping, snapshot sizing, corresponding renderer tests and documentation change. Public offer data, Messages caption/summary, Core, protocol, in-game controls and eligibility remain unchanged. Width remains360; trade artwork height follows its content instead of inheriting the board's260-point canvas. Source inspection found a generic renderer test assuming fixed board dimensions for trade; adjust only that trade expectation and add its existing gallery test to the focused proof. This sizing change removes surplus felt around compact offers.

## Plan and Locked Proof

1. Replace evenly distributed columns and fixed empty card slots with intrinsic card clusters and consistent count/name labels. Use a compact sender line and inline recipient response rows; shared waiting states retain one recipient list and one status line.
2. Canonical generation, focused simulator tests: TranscriptTradeSnapshotRendererTests (three fixtures), TranscriptBubbleCopyTests, and TranscriptBubbleImageRendererTests/testFiveFamilyCheckpointGalleryUsesProductionComponents (existing dispatcher/size contract). Inspect three trade captures: simple two sheep/one wood; mixed large three-recipient offer with differing responses; five resource types/long recipient names. At most two visual rounds; each mechanical command initial plus two diagnosed retries. No real sends or unrelated gameplay catalogs.
3. Fresh constraint-auditor/product-UX review, doc freshness, standard completion gate, scoped commit/push. User will judge the screenshots; leave #52 open for that feedback.

## Verification Contract and Fresh Review

<!-- verification-contract:start -->
| ID | Class | Source | Acceptance | Verification | Evidence | Status | Rationale |
| --- | --- | --- | --- | --- | --- | --- | --- |
| TB-001 | observable | user request | Felt/full art; visible small multiplicity; exact resource quantities; compact named recipients with individual responses; no clipping | three production renderer captures inspected | report:player-pieces18-tests-three-renders-fresh-review | pass | Renderer output is shipped artwork, not proof of remote receipt |
| TB-002 | mechanical | architecture and user boundary | Public-only offer; unchanged caption/summary/protocol/in-game behavior; valid content-sized trade image through dispatcher | focused renderer/copy/gallery tests and source review | report:player-pieces18-tests-three-renders-fresh-review | pass | Board-family sizing unchanged |
| TB-003 | mechanical | workflow | Tracking gaps repaired; owner docs current; scoped commit/push and standard gate | issue readback and gate/git evidence | report:player-pieces-doc-freshness-c540ed9-pushed | pass | Preserve concurrent supply work |
| TB-004 | judgment | user approved direction | Cards dominate; tight grouping; quiet sender/separator; readable consistent labels and compact response roster | fresh product-UX inspection of three renders | report:player-pieces18-tests-three-renders-fresh-review | pass | Advisory craft review does not replace user taste feedback |
| SB-001 | observable | owner request and issue3 | Real long-name final result and draw remain readable at conversation size | Three renderer comparison images inspected | report:shared-results-final-three-images-inspected | pass | DEBUG proposal readable; owner judgment remains separate |
| SB-002 | mechanical | architecture and approved trade boundary | Production dispatcher, trade artwork, caption/summary and protocol unchanged; preview uses canonical public scores | Source diff and focused renderer test | report:shared-results-round1-17-tests | pass | No publication path selects proposal |
| SB-003 | judgment | owner visual gate | Owner approves the shared result composition before productionization | Owner screenshot feedback | report:owner-approval-2026-10-25 | pass | Owner accepted final presented designs; production proof remains separate |
| SB-004 | mechanical | owner production request | Production game-over dispatcher uses public structured score rows; private cards/resources cannot affect result artwork/copy; other families unchanged | Renderer and copy suites plus source review | report:pending-production | pending | Production integration proof |
| SB-005 | observable | accepted shared result design | Production victory and draw show full names/scores with complete board and continuous ocean | Three production renderer captures inspected | report:pending-production | pending | Accepted layout promoted unchanged |
<!-- verification-contract:end -->

<!-- fresh-review:start -->
| Reviewer | Required | Verdict | Evidence |
| --- | --- | --- | --- |
| constraint-auditor | yes | pending | report:production-shared-results-review |
| product-ux | yes | pending | report:production-shared-results-review |
<!-- fresh-review:end -->

## Living Record

### Tracking reconciliation — 2026-10-21

- Milestone1 implementation/local proof: beta-local-implementation-readiness.md. Candidate distribution and hardware/multiplayer acceptance remain in testing-streams-implementation.md and linked Beta1.1 issues.
- Lifecycle test failures: #15 updated with the four-route attempt11 local pass and corrected fixture-preference harness. Hardware acceptance stays open.
- Lifecycle appearance: new [#53](https://github.com/kunal-sharda/UnluckySevens/issues/53), single coherent felt surface instead of stacked panels; not implemented.
- In-game trade overlap/taps/counts: #47 updated to preserve affected-device/overlap verification. Existing draft/button fixes do not prove all reported symptoms resolved. User permits current in-game composition if no overlap.
- Trade bubble appearance: #52 now owns this work; earlier commits7d37a08 and4c75baf are functional baselines, not aesthetic acceptance.
- Other bubbles: #3 now explicitly records conversation-size review, starting with the end-game score strip; report concerns before redesigning. Source concern is not a demonstrated defect.
- Bank/supply clarity remains separate #51 and beta-1.2-supply-clarity.md; its uncommitted changes are preserved.

### Previous evidence

Two prior bounded visual passes established full-strength illustrated felt cards, removed aggregate totals and added three fixtures. Each final pass had17 passing tests and a passing completion gate; implementations and evidence commits are pushed. The user's subsequent slideshow criticism reopens composition. Independent Impeccable review identified fixed82/112-point empty regions, equal-width columns and dashboard-like response layout as causes. No further polish of the old layout is implied.

## Current follow-up — 2026-10-21

User authorizes fixing the remaining slide-like composition. Reopen standard/direct with the same18-test proof and three renderer captures, maximum two visual rounds; preserve public data and in-game controls. Remove Gives/Wants headings from the side-by-side exchange, gather mixed cards in shallow fans with art still identifiable, keep exact per-resource labels, and group recipients by identical response state/detail (each name once). Dense two-row offers keep directional labels for unambiguous reading. No new data/protocol. Previous passes below are historical and do not prove this new composition. Fresh constraint/product-UX review and completion gate follow scoped commit/push. Pre-roll map inspection is separately ticketed as [#54](https://github.com/kunal-sharda/UnluckySevens/issues/54) from the user's new report; not folded into bubble changes.

## Validation and Outcome

Implementation: removed fixed82/112-point regions and equal-width columns. Shared card sizes and consistent count/name labels sit in intrinsic groups. Sender text is subordinate; mixed responses use compact inline rows. Trade height is content-sized; all other families retain fixed canvas. DESIGN bubble paragraph updated.

Round1 proof: canonical generation succeeded after an external-cache sandbox denial and permitted retry. Focused simulator18/18 tests pass, zero skipped/failed, /tmp/uls-trade-compact-round1.xcresult. Three exported trade renders inspected: no clipping/overlap, full art, repeated sheep cards, exact quantities, differing responses and all long names visible. Local copies output/trade-bubbles-review/compact. Existing dispatcher gallery passes with trade-specific size assertions. This is renderer proof, not remote Messages-host delivery. No second visual round needed unless review finds a defect.

Fresh constraint/product-UX review passes TB-001/002/004 after independently inspecting source, all three images and raw18-test results. TB-003 tracking readback and scoped commit/push are verified: b545a42 on origin/beta-1.2. Standard completion gate passed (exit0): selected contract, harness audit, whitespace, doc freshness, canonical generation and simulator build. All selected constraints/reviews pass. Doc freshness and whitespace checks pass. Architecture, rules, product-flow and QA owners remain unaffected; no hardware, distribution or final milestone acceptance claim.

Doc freshness: DESIGN bubble contract and active trade/kickoff plans updated. Architecture, decisions, rules, product flow and QA contracts intentionally unchanged by this slice; no historical cleanup. Concurrent supply changes remain untouched. Issue52 remains open for user visual feedback, not a missing local implementation check. No live receipt, physical device or milestone-release claim.

Fan follow-up validation: first run /tmp/uls-trade-fan-round1.xcresult was interrupted (16pass,2 signal-kill crashes). Process inspection confirmed the separate supply screenshot harness simultaneously targeting the same simulator. Do not use that bundle as final proof. Diagnosed retry1 uses a temporary isolated iPhone17/iOS26.5 simulator; no product-scope expansion.

Isolated follow-up proof: /tmp/uls-trade-fan-isolated.xcresult passes18/18, zero failures/skips. Three final images inspected and retained at output/trade-bubbles-review/fan: larger shallow mixed fans, single-line exact resource labels, no side-by-side headings, shared Waiting response for Theo/Sam with distinct Maya Declined, full long names and all dense terms. No clipping or concealed resource illustrations. One visual round used; no correction round needed.

Fresh follow-up constraint/product-UX review passes source, raw18-test result and all three final images. Doc freshness passed; temporary isolated simulator removed after validation. Final workflow check/commit/push follows.

Follow-up implementation committed and pushed as dcf4407 on beta-1.2. All selected constraints and fresh reviews pass. Standard completion gate passed (exit0): contract, harness audit, whitespace, doc freshness, canonical generation and simulator build; local log /tmp/uls-trade-fan-completion.log. DESIGN and this plan own the changed facts; architecture, rules, product flows and QA contracts remain intentionally unchanged. No historical cleanup. Map inspection #54 remains tracked but unimplemented.

## Player-piece pass — 2026-10-21

User approves trying player-colored pieces with names and attached status symbols, replacing all status sentence rows. Standard/direct; same three renderer fixtures and18 focused tests, at most two visual rounds. Carry canonical public roster order into the presentation visual so piece colors match the board even for a targeted subset; add a roster assertion to the existing copy test. Reuse production settlement geometry and palette. Names plus clock/check/cross/counter symbols provide redundant identity/state cues; image accessibility text includes full response details. No fake controls, protocol/rules or in-game changes. Dense long-name fixture will also exercise accepted/countered/waiting badges; mixed fixture keeps declined/waiting. Isolated simulator from the start avoids the prior shared-device collision. Fresh review, doc freshness, scoped commit/push and completion gate remain required. Earlier passes below/above are historical evidence only for their respective source.

Player-piece proof: canonical generation and isolated simulator run /tmp/uls-trade-pieces-round1.xcresult pass18/18 with zero skips/failures. All three final captures inspected at output/trade-bubbles-review/player-pieces; distinct clock/cross/check/counter badges, canonical board colors, all names visible including wrapping long names. Fresh source/constraint/product-UX review passes. No second visual round required. Full response accessibility is source-proven in the SwiftUI view only, not transported through UIImage; Messages caption/summary unchanged. No remote/hardware accessibility claim. Final workflow evidence follows.

Player-piece implementation committed/pushed as c540ed9. Standard completion gate passed (exit0): contract, harness audit, whitespace, doc freshness, canonical generation and simulator build. Evidence log /tmp/uls-trade-pieces-completion.log. DESIGN and active plan updated; architecture, rules/protocol, product-flow and QA contracts intentionally unchanged. No historical cleanup. Temporary simulator removed. User aesthetic feedback and remote/device acceptance remain separate.

## Owner acceptance — 2026-10-21

User explicitly approved the final player-piece rendering: "that's so much nicer !! let's go with that". This supersedes prior pending aesthetic feedback. Keep the shipped composition from c540ed9; verification recorded in81da0a8 remains applicable. Issue52 closes for this visual slice. Pre-roll map inspection54, lifecycle appearance53, broader bubble coverage3, and hardware/release acceptance remain separate. DESIGN records the approved direction. This acceptance-only update changes no source: run doc freshness and whitespace checks, commit/push the record; do not repeat the passing18-test/build/review proof without a source change.

## Shared-bubble follow-up — 2026-10-24

The owner requests parallel work on shared conversation bubbles. The accepted trade composition above stays unchanged. Broader #3 identifies the end-game score strip as the first inspection target. This new slice is **standard/checkpointed**: build a DEBUG-only real-component comparison, then obtain owner judgment before changing the production dispatcher or artwork. The existing pass rows above describe the accepted trade slice only, not this comparison.

Locked proof: one focused `TranscriptBubbleImageRendererTests/testSharedGameOverDesignComparison` route produces at most three images: production long-name result, proposed long-name victory, and proposed draw. The existing production renderer/copy suites remain the regression proof if the proposal is approved. Two visual rounds maximum; the parent serializes canonical generation and simulator execution. No live sends, protocol changes, hidden-information changes, or changes to the approved trade renderer.

Design direction: retain the real board as the shared-game identity, give the result its own quiet felt region, and replace the one-line all-player score string with individually readable public name/score pairs and the same player pieces/colors used in the approved trade bubble. SF typography remains consistent; the production board retains its number-token lettering. A result with long names may grow vertically instead of shrinking or clipping names. The comparison consumes the canonical fixture state and production board rendering; it is never selected by publication code.

Pending proof/approval: renderer execution, actual image inspection, and owner visual acceptance. No fresh final review or completion gate while this visual gate is pending. Source review found that the production winner and score strip each use `lineLimit(1)`; truncation remains a concern until inspected at conversation scale. Lobby/ordinary-turn designs remain unchanged pending evidence of a concrete issue.

Shared-result round1: parent reports17 passing scoped renderer/model tests; three artifacts in `output/beta12-component-review` independently inspected. The production long-name result truncates after Samantha and omits Theodore, demonstrating the source concern. Both DEBUG proposals show the complete winner/draw title, all four names, canonical player colors and scores without text clipping. The reduced board remains complete; this is a result summary rather than detailed board inspection. One concrete composition defect is corrected in the permitted second round: extend the production ocean background across the top region, removing the inset bitmap's exposed rectangular edges against felt. This does not enlarge/crop the map or change data. Final correction capture is recorded below. Owner acceptance remains pending; no production publication or remote-host proof is claimed.

Shared-result final preview proof: parent reports the focused comparison route passed1/1; all three final images in `output/beta12-bubbles-final` independently inspected. Victory `4453961F-0DA6-4EB2-BF05-86B37AE370F1.png` and draw `03AA4F24-4041-4416-8FBC-50A134AC9B5F.png` show the complete board on a continuous ocean region, distinct felt result area, readable title, all four complete names and public scores, and canonical player-piece colors. Baseline `68E6DC3B-AA26-4D4E-B57B-A453CA906890.png` confirms the original score truncation. The inset-image edge defect is resolved; two bounded visual rounds are used and no further iteration is planned before feedback. SB-001/002 pass for this preview; SB-003 remains pending owner acceptance. Production dispatcher/artwork and approved trade composition are unchanged. No live Messages delivery, full accessibility, fresh final review or completion-gate claim.

### Visual acceptance — 2026-10-25

Owner response to the final resignation, Dev timing, shared-result and Road Building captures: “those looks great!” The presented direction is approved; this supersedes pending owner-judgment notes above. Production integration and its scoped behavior tests, fresh reviews and completion gate remain outstanding. This acceptance-only update changes no runtime code. Validation: doc freshness and whitespace checks; prior preview evidence remains applicable without rerunning simulator captures.

### Production integration — 2026-10-25

Standard/direct following explicit owner approval and implementation request. Locked proof before source edits: full `TranscriptBubbleImageRendererTests`, `TranscriptBubbleCopyTests` and `TranscriptTradeSnapshotRendererTests` suites; add structured roster/public-score and hidden-resource/Dev-card invariance assertions. Capture exactly three production results (short-name victory, four long-name victory, four long-name draw) through `testSharedGameOverDesignComparison`; inspect all three, one correction round if needed. Parent serializes canonical generation and simulator execution. Existing ordinary-turn/lobby/gallery and trade tests preserve non-target families. No protocol, caption/summary or Core scoring changes; production view consumes only the public visual model, not canonical private state. Fresh constraint/product-UX review and standard completion gate follow final proof. No live delivery or device-accessibility claim.

Production source handoff: approved composition now lives in `TranscriptGameOverSnapshotView`, reached by the existing production dispatcher. The public visual model carries ordered player ID/name/score rows; no canonical state or private inventory enters the view. Result artwork uses intrinsic height, preserving full names; board/trade/lobby dispatch and caption/summary stay unchanged. Removed the superseded DEBUG-only comparison component. The three-image comparison test now renders only production routes. Added privacy invariance coverage varying resources and both old/new Dev inventories (including hidden VP) for victory and draw. Swift parser and whitespace checks pass. Runtime tests/capture inspection, fresh review and completion gate remain parent-coordinated and pending.

Production validation 2026-10-25: corrected generated extension batch passes 63/63 tests, including all three transcript suites and hidden-inventory invariance. Exported three production result captures under `output/beta12-production-model-images`; parent inspected victory, long-name victory and draw. Complete board, all names/scores and public player colors remain readable without clipping. Shared-result source is ready for scoped commit/push; aggregate fresh review and completion gate remain tracked in `beta-1.2-approved-integration.md`. No remote delivery or milestone acceptance claim.
