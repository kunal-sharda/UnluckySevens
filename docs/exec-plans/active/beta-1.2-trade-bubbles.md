# Beta 1.2 trade bubbles

## Purpose and Outcome

Implement [#52](https://github.com/kunal-sharda/UnluckySevens/issues/52): a compact tabletop exchange in the Messages conversation bubble. The user rejected the prior slide-like composition and approved trying the independently reviewed direction: tightly gathered full-strength production cards on felt, subordinate sender line, exact per-resource quantities without totals, compact named recipients with individual responses.

## Execution Settings

- Validation profile: `standard`
- Delivery posture: `direct`
- Rationale: user explicitly authorized trying the described composition and previously delegated routine implementation decisions. This is a bounded implementation with screenshots for subsequent user feedback, not a claim of aesthetic acceptance.

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
| TB-001 | observable | user request | Felt/full art; visible small multiplicity; exact resource quantities; compact named recipients with individual responses; no clipping | three production renderer captures inspected | report:compact-round1-three-inspected-renders | pass | Renderer output is shipped artwork, not proof of remote receipt |
| TB-002 | mechanical | architecture and user boundary | Public-only offer; unchanged caption/summary/protocol/in-game behavior; valid content-sized trade image through dispatcher | focused renderer/copy/gallery tests and source review | report:compact18-tests-source-review | pass | Board-family sizing unchanged |
| TB-003 | mechanical | workflow | Tracking gaps repaired; owner docs current; scoped commit/push and standard gate | issue readback and gate/git evidence | report:pending | pending | Preserve concurrent supply work |
| TB-004 | judgment | user approved direction | Cards dominate; tight grouping; quiet sender/separator; readable consistent labels and compact response roster | fresh product-UX inspection of three renders | report:compact_bubble_review | pass | Advisory craft review does not replace user taste feedback |
<!-- verification-contract:end -->

<!-- fresh-review:start -->
| Reviewer | Required | Verdict | Evidence |
| --- | --- | --- | --- |
| constraint-auditor | yes | pass | report:compact_bubble_review-source-and-raw-evidence |
| product-ux | yes | pass | report:compact_bubble_review-three-captures |
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

## Validation and Outcome

Implementation: removed fixed82/112-point regions and equal-width columns. Shared card sizes and consistent count/name labels sit in intrinsic groups. Sender text is subordinate; mixed responses use compact inline rows. Trade height is content-sized; all other families retain fixed canvas. DESIGN bubble paragraph updated.

Round1 proof: canonical generation succeeded after an external-cache sandbox denial and permitted retry. Focused simulator18/18 tests pass, zero skipped/failed, /tmp/uls-trade-compact-round1.xcresult. Three exported trade renders inspected: no clipping/overlap, full art, repeated sheep cards, exact quantities, differing responses and all long names visible. Local copies output/trade-bubbles-review/compact. Existing dispatcher gallery passes with trade-specific size assertions. This is renderer proof, not remote Messages-host delivery. No second visual round needed unless review finds a defect.

Fresh constraint/product-UX review passes TB-001/002/004 after independently inspecting source, all three images and raw18-test results. TB-003 awaits scoped commit/push and completion gate. Doc freshness and whitespace checks pass. Architecture, rules, product-flow and QA owners remain unaffected; no hardware, distribution or final milestone acceptance claim.
