# Seven-Lane Delivery Program

## Purpose and Outcome

Deliver the approved beta-feedback backlog in dependency order: close the correctness gate first, then improve gameplay clarity, learning, accessibility, optional modes, performance, and final multiplayer proof. GitHub Issues own ticket status; this plan owns cross-ticket sequencing, shared constraints, and integrated evidence.

## Execution Settings

- Validation profile: `standard`
- Delivery posture: `checkpointed`
- Rationale: The program spans rules, Messages lifecycle, hidden information, UI/UX, and accessibility. Correctness work is directly authorized; ambiguous visual and learning changes pause at their declared approval gates with representative simulator proof.

## Context and Boundaries

- Source of truth: code/tests, `docs/decisions.md`, `ARCHITECTURE.md`, product/UI-flow specs, and `docs/quality/qa.md`.
- Model routing: Sol/medium implements and integrates; Terra/medium audits and expands settled fixtures; Sol/xhigh is reserved for unresolved concurrency, secrecy, protocol, or rules planning/review. Implementation escalates only after an evidenced reasoning failure.
- `ULS_CoreGame` remains the rules, determinism, validation, and secrecy-safe query owner. `ULS_Transport` remains the pure protocol boundary. Messages consumes their outputs and must not become a second rules engine.
- Protocol fields, authority, secrecy, and locked rules do not change without an explicit plan amendment and owner decision.
- Validation is serial. Agents must not run SwiftPM, generation, xcodebuild, simulator, or completion gates concurrently.

## Milestones / Plan of Work

**Sequencing superseded 2026-09-14:** use [marketable-release-plan.md](marketable-release-plan.md) and current GitHub milestones. The older waves below are historical context; child contracts/approval gates remain binding. The 2026-09-15 outcome consolidation restores broader pre-public scope; pacing/1v1 inclusion requires an explicit decision. Earlier blanket deferrals below are historical.

1. Correctness gate: investigate and repair asymmetric update delivery/recovery #43 with bounded local diagnostics and explicit export #44; complete #2, #7, #15; #6 and #11; accessibility audit #22; then standalone lobby convergence #4.
2. Core gameplay clarity: batch #17/#42, batch #13/#14/#16, and #18; expand settled visual coverage under #3.
3. Post-match and scoring: batch #9/#41 and sequence #20 then #19 after the core clarity slice.
4. Learning and privacy: implement #23-#26 through a visual checkpoint; implement #10 only after trade correctness is closed.
5. Independent later work: preserve local-first value under #33/#38 while account/communications work #27-#40 remains separately planned, excluding the early local reliability/export subset #44; plan and slice #12; profile and address #5 only from measurements; explore #21 before implementation. Keep #45 (desert/robber variant) and #46 (game speed) as separate unscheduled discovery requests; #46 reuses #20 for any victory-target implementation.
6. Integrated proof: execute #8 at the end of the Beta 1.1 reliability gate; later release-targeted lanes add their own scoped proof rather than reopening that gate.

## Approval Gates

- Authority: solo owner.
- UI/learning proof: at most three representative real-component states per round, two rounds by default.
- Accessibility redesign: audit findings may authorize small redundant cues; a broad player-piece or palette redesign pauses before productionization.
- Protocol/rules: any unresolved authority, compatibility, secrecy, or 1v1 rules decision pauses for a decision-complete Sol/xhigh plan.
- Stop condition: do not productionize checkpointed nested states, run their fresh review, or claim their completion while approval is pending.

## Verification Contract and Fresh Review

<!-- verification-contract:start -->
| ID | Class | Source | Acceptance | Verification | Evidence | Status | Rationale |
| --- | --- | --- | --- | --- | --- | --- | --- |
| SLD-001 | mechanical | issues #2, #4, #6, #7, #11, #15, #43 | Session, lobby, trade, and publication boundaries have deterministic regression coverage and no protocol/secrecy drift | focused Core/Transport/extension tests plus source inspection | command:pending | pending | Correctness gate precedes features |
| SLD-002 | observable | issues #2, #4, #6, #7, #8, #11, #15, #43 | Contracted two-account lifecycle, lobby, trade, and asymmetric-delivery journeys converge, publish, and are recoverable through the supported Messages path | connected-device runbooks with private diagnostics | report:pending | pending | Sender-side success cannot establish remote receipt or rendering |
| SLD-003 | judgment | issues #3, #13, #14, #16-#18, #42 | Core gameplay prompts make table identity, cost, actor, next action, and production understandable without noisy persistent chrome | owner-approved representative screenshots and product/UX review | report:pending | pending | Visual direction is checkpointed |
| SLD-004 | judgment | issue #22 | Accessibility audit identifies every material color-only state and locks implementation-ready redundant cues and proof | audit artifact plus accessibility review | report:pending | pending | Compliance is not inferred from automated checks |
| SLD-005 | mechanical | repo workflow | Every qualifying child plan passes its selected gate; owner docs and issue sequencing remain current | contract checker, doc freshness, child completion gates | command:pending | pending | Program completion composes child evidence |
| SLD-006 | observable | issue #44; user approval 2026-09-06 | Beta 1.1 provides bounded privacy-safe local diagnostics and previewed explicit export, separates local handoff from recipient observation, and requires no analytics backend | Child implementation contract: schema/retention tests, simulator export proof, paired-device reports, and applicable privacy review | report:pending | pending | Early diagnostics support field investigation; implementation has not started |
<!-- verification-contract:end -->

<!-- fresh-review:start -->
| Reviewer | Required | Verdict | Evidence |
| --- | --- | --- | --- |
| constraint-auditor | yes | pending | report:pending |
| architecture | yes | pending | report:pending |
| behavioral | yes | pending | report:pending |
| product-ux | yes | pending | report:pending |
| accessibility | yes | pending | report:pending |
<!-- fresh-review:end -->

## Living Record

### Progress

- 2026-09-10: Corrected stale issue status against Build 8: #4/#6/#11 fixes and #15 guidance remain local/unshipped; #7 was an unused-helper cleanup with focused device proof remaining; #38 now starts from shipped Player Record capabilities. Broad host/integrated matrix ownership and learning parent links are explicit. The backlog review found no whole-ticket duplicates warranting closure; shared deliverables must be reused. Historical approval-pending notes below are superseded by the child plans that record approval and local implementation.

- 2026-08-28: User approved the seven-lane sequencing and lean model-routing policy.
- 2026-08-28: Started Wave 1 with separate session-correctness, trade-correctness, and color-blind accessibility-audit owners.
- 2026-08-28: Session and issue-#11 deterministic slices landed and their focused tests pass. Issue #4 and #6 planning reviews surfaced explicit owner decisions, so implementation remains paused at those contract gates.
- 2026-09-04: A field screenshot established asymmetric visibility for #43: the sender saw the rich update while the named next player did not. The private screenshot is not retained in the repository; the issue records only minimized evidence. #43 now leads Beta 1.1, while companion-app/APNs work remains deferred.

### Decisions

- 2026-09-13: Use separate [one-device and two-device test routes](../../quality/device-runbooks.md#streaming-patch-test-routes) for streaming patches. Local checks progress while hardware is unavailable; remote TestFlight participation is manual. Hardware UI automation remains unproven, and #4/#6 still require three-account concurrency evidence. Route definition does not change release gates or approve unattended execution.

- 2026-09-09: Filed #45/#46 from user feature requests; non-stacking desert benefit is intended, while payout trigger/city behavior and speed mechanics require decisions before implementation. No release membership or default rules changed.

- 2026-09-06: User approved #44 for Beta 1.1: the local reliability contract, instrumentation, preview/export, and applicable privacy checks are extracted from #30/#31/#34/#35. Remote analytics, accounts, hosted support, and communications stay later; no broader milestone regrouping is enacted by this scope update.

- 2026-08-28: Use Sol/medium for implementation and Terra/medium for audits; reserve Sol/xhigh for unresolved planning/review rather than routine coding.
- 2026-08-28: Bugs and latent correctness issues must pass the correctness gate before feature batches begin.
- 2026-09-04: Keep recovery and reminders distinct. Beta 1.1 must make a missing canonical Messages update diagnosable and safely recoverable; automatic remote turn pushes require a later app-surface/backend decision and are not part of this gate.

### Discoveries

- 2026-09-10: Build 1.0 (8) provenance checked against the completed first-friends release record (TFR-002/TFR-009), frozen commit `673813f`, and retained `output/release/UnluckySevens-1.0-8-673813f.xcarchive/Info.plist` (version 1.0, build 8, expected bundle). Source comparison confirms #4 lobby reconciliation, #6 trade convergence, #11 shared eligibility, and #15 unavailable-action guidance are later local changes, not in Build 8. Build 8 already includes Player Record statistics and existing resign/draw/host-end controls. For #7, Build 8 production state publication already fails closed; the fallback was an unused helper whose removal is local. No tickets closed; device proof remains outstanding. This provenance check ran no builds or gameplay tests.

- 2026-08-28: The generic `gpt-5.6` subagent alias is unavailable on the ChatGPT-hosted path; explicit `gpt-5.6-sol` and `gpt-5.6-terra` dispatches are required.
- 2026-08-28: The lifecycle XCUITest catalog exhausted its circuit-breaker budget after repeated Messages-host/fixture routing failures. Setup-host proof passed; remaining observable routes require an owner-authorized retry or a separately scoped harness correction.
- 2026-08-28: Lobby sibling joins cannot converge under revision/hash selection alone. A Sol/xhigh review recommends host-published reconciliation of transcript-validated self-authored join claims, gated by six owner decisions recorded in the issue-#4 child plan.
- 2026-09-04: The Xcode 26.5 `MSConversation` symbol contract distinguishes local handoff from delivery: `insertMessage` completion reports staging in the Messages input field, while `sendMessage` completion reports only that sending started successfully. Neither completion establishes per-recipient receipt, so #43 requires explicit two-account observation and cannot honestly show a remotely delivered state from those callbacks alone.

## Validation and Outcome

- Automated: pending child-plan proof.
- Simulator: pending focused contracted journeys.
- Connected devices: pending correctness gate and final #8 matrix.
- Judgment: pending UI/learning checkpoints and accessibility review.
- Deferred: #10, #12, #5, #21, and #8 remain sequenced behind their prerequisites.

- 2026-09-13: [Testing-stream tooling](testing-streams-implementation.md) now provides serial local checks and resumable operator-assisted two-device lobby evidence. Baseline build and focused runner tests passed; actual hardware verification remains blocked by unavailable/locked devices. No unattended physical UI capability is claimed.

- 2026-09-13 correction: redundant local-stream wrapper removed; existing simulator commands remain authoritative. Physical probe/invite driver now compiles but awaits configured hardware proof. Manual recorder is explicitly named; remote-response handling and two-device coordination remain pending under the testing implementation plan.

- 2026-09-15: Six tracking issues consolidated into authoritative successors; see backlog-outcomes.md and marketable-release-plan.md. Seventeen formerly unassigned outcomes restored to Pre-public — Expanded player experience. No requirements canceled, no product implementation in this revision.
