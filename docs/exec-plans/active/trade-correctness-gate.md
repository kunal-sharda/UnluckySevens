# Trade Correctness Gate

## Purpose and Outcome

Resolve [GitHub issue #11](https://github.com/kunal-sharda/UnluckySevens/issues/11) at the narrowest demonstrated boundary by making the player-trade Accept control and its intent resolver consume one secrecy-safe eligibility result, with DEBUG-only rejection diagnostics. Resolve [GitHub issue #6](https://github.com/kunal-sharda/UnluckySevens/issues/6) through the approved deterministic responder-lineage preference without changing protocol shape, responder authority, or secrecy semantics.

## Execution Settings

- Validation profile: `standard`
- Delivery posture: `checkpointed`
- Rationale: #11 is a meaningful behavior/diagnostic correction with deterministic package coverage. #6 exposes competing valid sibling states and therefore requires an explicit authority/convergence decision before production implementation.

## Context and Boundaries

- Build 1.0 (8) does not contain the later #6/#11 fixes. #11 funded-recipient lifecycle proof can use two active accounts in a valid game; #6 competing acceptance requires a proposer and two recipients (three player accounts). Both require an identified fixed candidate.

- Core owns trade legality and acceptance resolution; Messages may consume a shared eligibility projection but must not become a second rules engine ([Architecture](../../../ARCHITECTURE.md)).
- A targeted responder publishes a canonical state immediately, and the first applied Accept closes the offer ([UI flows](../../product-specs/ui-flows.md)).
- Core now owns deterministic preference plus device-local evidence: only direct Accept claims with the same parent hash, offer hash, revision, and audit prefix establish contention; the responder with the greatest SHA-256 key wins and that evidenced lineage outranks later losing descendants.
- In scope: Accept eligibility agreement, private local reason codes, DEBUG-only structured diagnostics, deterministic Core/Messages tests, and approved #6 convergence across transcript memory, action authoring, and ledger persistence.
- Out of scope: protocol fields, responder authority, altered trade legality, resource-count logging, issue #10, broad UI redesign, and device/simulator proof in this slice.

## Milestones / Plan of Work

1. Map reducer legality, panel enablement, intent authoring, state selection, and publication boundaries.
2. Introduce one secrecy-safe Accept eligibility query and consume it from both panel and action resolver.
3. Add DEBUG-only rejection diagnostics at the local action boundary without resource amounts or another player's private state.
4. Add focused deterministic coverage for missing/replaced offers, actor targeting, prior responses, turn transitions, and affordability.
5. Run the locked package tests serially, update the living record and owner docs, then complete the approved #6 implementation and its deterministic proof before device validation.

## Approval Gate

- Authority: user, after Sol/xhigh planning review for issue #6.
- Minimum honest proof: focused Core and Messages tests pass; panel/resolver agreement is mechanically tested; plan records why current sources do not settle competing-accept convergence.
- Iteration budget: one implementation pass plus one focused corrective retry per failing test class.
- Stop condition: any fix requires changing protocol shape, actor authority, first-applied semantics, secrecy, or reconciliation of a higher-revision descendant against a losing equal-revision sibling.
- Authorized after approval: implement the selected #6 convergence model, add deterministic fork/reconciliation tests, then run paired-device acceptance proof and the completion gate.

## Verification Contract and Fresh Review

<!-- verification-contract:start -->
| ID | Class | Source | Acceptance | Verification | Evidence | Status | Rationale |
| --- | --- | --- | --- | --- | --- | --- | --- |
| TR-001 | mechanical | Issue #11; Architecture | Panel enablement and final resolver consume one eligibility result without duplicating rules | Focused Messages tests cover every eligibility reason and builder/resolver agreement | command:`/tmp/UnluckySevens-trade-focused.xcresult` (16/16 pass) | pass | Resolver and panel matrices cover every reason, including unavailable state/actor |
| TR-002 | mechanical | Issue #11 | Rejected Accept attempts expose structured DEBUG-only reason codes without private resource counts | Focused diagnostics tests and source inspection | command:`/tmp/UnluckySevens-trade-focused.xcresult` | pass | Diagnostic emits reason, revision, offer presence, and actor presence only |
| TR-003 | mechanical | Issues #6/#11 | Current Core trade behavior remains green, including acceptance economy and stale/missing offer rejection | `swift test --package-path Packages/ULS_CoreGame --filter TurnTrade` | command:9/9 pass; eligibility 5/5 pass | pass | Root-serialized focused Core filters passed |
| TR-004 | observable | Issue #11 | A targeted funded responder accepts after the implicated lifecycle sequence on connected accounts | Paired-device journey from QA harness | artifact:deferred | blocked | Explicitly deferred by assigned slice |
| TR-005 | judgment | Issue #6; UI flows; Architecture | After both direct same-parent/same-offer Accept siblings are observed, their descendants converge on the approved hash-derived responder lineage; unrelated lineages retain revision/hash order | Sol/xhigh planning review, user approval, adversarial Core tests, and Messages evidence-retention tests | report:user-approved; command:CanonicalStatePreferenceV1Tests 7/7 pass; command:non-eval Core 159/159 pass; command:`/tmp/UnluckySevens-trade-chained-accept-green.xcresult` 33/33 pass; report:2026-08-29-final-fresh-rereview | pass | Exact claim anchors, unrelated lookalikes, later losing descendants, and a later Accept on the losing lineage are covered and passed fresh review |
| TR-006 | observable | Issue #6; corrected account requirement 2026-09-10 | Proposer and two targeted recipients observe competing accepts and converge after both claims and reopen on fixed clients | Three-account near-simultaneous acceptance journey with identified build and canonical result evidence | report:pending | pending | Explicitly preserves issue #6 device acceptance; two accounts cannot supply two recipients and a proposer |
<!-- verification-contract:end -->

<!-- fresh-review:start -->
| Reviewer | Required | Verdict | Evidence |
| --- | --- | --- | --- |
| constraint-auditor | yes | pass | report:2026-08-29-final-fresh-rereview; no remaining deterministic blocker |
| concurrency/protocol specialist | yes | pass | report:2026-08-29-final-fresh-rereview; exact contention anchors and descendant tracking pass |
<!-- fresh-review:end -->

## Living Record

### Progress

- [x] Mapped issue text, owner docs, Core reducer/validation, Messages eligibility, and equal-revision state selection.
- [x] Shared Core eligibility, Messages consumption, generic guidance, and local DEBUG diagnostics implemented with focused regression tests.
- [x] Initial Core eligibility validation and required project generation recorded; remaining focused validation handed to the root coordinator for serialized execution.
- [x] Root-serialized Core and Messages proof passed after correcting funded fixtures, adding all-reason agreement matrices, and redacting actor identity from diagnostics.
- [x] #6 convergence decision approved and implemented; deterministic validation passed.
- [ ] Paired-device proof and completion gate run.

### Decisions

- 2026-08-28: Lock `standard` / `checkpointed`; deterministic package proof is the implementation proof set, while device proof and the completion gate remain blocked until approved #6 implementation proof passes.
- 2026-08-28: Do not treat lexicographic equal-revision storage preference as a complete #6 resolution because a device can author a higher-revision descendant before observing the preferred sibling.
- 2026-08-28: Preserve Core's existing error cases while routing acceptance execution through the same Core-owned eligibility query consumed by Messages.
- 2026-08-28: User approved deterministic canonical order instead of physical arrival, the SHA-256 responder tie-break, and an all-upgraded-client convergence guarantee. Protocol shape and responder actor semantics remain unchanged.

### Discoveries

- 2026-08-28: `GameTradePanelModelBuilder` and `TradeInteractionResolver` independently repeat the same affordability/target/response checks, creating a drift risk even though no deterministic disagreement has yet been reproduced.
- 2026-08-28: Core correctly rejects missing, mismatched, unauthorized, already-responded, and unaffordable acceptance; the field report lacks enough evidence to attribute the intermittent symptom to any one condition.
- 2026-08-28: A deterministic UI/Core disagreement existed when the proposer spent the offered cards while the offer remained live: Messages enabled and drafted Accept using only responder affordability, while Core rejected execution. The shared query now disables Accept with secrecy-safe generic guidance.
- 2026-08-28: Fresh review found three misleading fixtures and an incomplete presentation matrix. The fixtures now isolate proposer versus responder funding, and resolver/panel tests cover every eligibility reason.
- 2026-08-28: The simultaneous-Accept review recommends a deterministic canonical responder selected from already-canonical audit evidence. It requires owner approval that canonical order replaces physical arrival, a hash-derived tie-break is acceptable, and the guarantee applies only when every client uses the fixed build.
- 2026-08-29: Fresh review correctly found that audit actor/revision did not prove a shared parent or offer. Core now extracts claims only from direct Accept snapshots, requires matching parent and offer anchors before establishing contention, and Messages retains that evidence across in-memory selection and persisted ledger recovery. An adversarial unrelated-lineage case remains on ordinary revision/hash ordering.

## Validation and Outcome

- Automated: `TradeAcceptEligibilityV1Tests` passed 5/5 and the TurnTrade filter passed 9/9; the final `CanonicalStatePreferenceV1Tests` passed 7/7; the full non-eval Core suite passed 159/159; focused presentation tests passed 16/16 in `/tmp/UnluckySevens-trade-focused.xcresult`; affected selection/authoring/ledger tests passed 33/33 in `/tmp/UnluckySevens-trade-chained-accept-green.xcresult` after generation.
- Observable/judgment: the final fresh review passed TR-005 and both required reviewer rows. Paired-device proof remains deferred/blocked, so the plan cannot complete.
- Deferred: issue #10, the device matrix, and any protocol-shape change.

Root-coordinated `make doc-freshness` passed on 2026-08-29. Do not run the completion gate until the paired-device journey resolves TR-004.

This plan cannot use completion language until all required contract rows and reviewers pass.
