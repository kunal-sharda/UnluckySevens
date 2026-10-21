# Concurrent Lobby Convergence

## Purpose and Outcome

Resolve [GitHub issue #4](https://github.com/kunal-sharda/UnluckySevens/issues/4) so independently valid sibling joins converge into one published canonical lobby before Start, without restoring intent messages, treating device-local observations as roster truth, or changing the transport wire shape.

## Execution Settings

- Validation profile: `standard`
- Delivery posture: `checkpointed`
- Rationale: the failure is deterministic, but fixing it expands host authority and requires explicit capacity, cutoff, trigger, and mixed-version decisions before implementation.

## Context and Boundaries

- Shipped Build 1.0 (8) can lose a guest when two joins share the same parent/revision. The approved reconciliation is implemented locally; it is not in Build 8 and still requires three-account proof on an identified fixed candidate.
- Canonical state remains the only visible roster and the only input to Start. Local ledger evidence may justify a reconciliation publication but may not itself become membership.
- `ULS_CoreGame` owns anchored reconciliation validation and deterministic union logic. Messages owns validated transcript observation, idempotent orchestration, same-session publication, and Start gating. `ULS_Transport` requires no schema change.
- The six Approval Gate decisions were approved on 2026-08-28 and are recorded in owner docs.

## Milestones / Plan of Work

1. Admit only Core-valid, self-authored lobby join transitions as bounded durable claims before normal sibling selection discards them.
2. Add a host-only, Core-produced reconciliation transition anchored to the selected canonical lobby state.
3. Compute a deterministic monotonic roster union, normalize appended-player defaults, and publish it once per anchor/frontier digest.
4. Gate Start while a locally observed valid frontier is unresolved; treat Start as the causal close barrier for joins the host has not observed.
5. Prove delivery-order invariance, authority, capacity, migration, reopen, and three-account convergence before completing the slice.

## Approval Gate

- Authority: user.
- Recommended decisions:
  1. Allow the original inviter to publish a constrained union of transcript-validated, self-authored guest joins.
  2. Let Start win over joins the host had not observed; setup never rolls back.
  3. Reconcile automatically and idempotently on receive/reopen.
  4. Enforce the owner-doc standard-Catan limit of 3–4 players in this slice.
  5. On over-capacity siblings, retain canonical members and fill remaining seats by deterministic claim priority; excluded guests see “Lobby full.”
  6. Guarantee convergence when the host runs the fixed build; do not migrate the protocol solely for old hosts.
- Approval outcome: all six recommendations approved on 2026-08-28.

## Verification Contract and Fresh Review

<!-- verification-contract:start -->
| ID | Class | Source | Acceptance | Verification | Evidence | Status | Rationale |
| --- | --- | --- | --- | --- | --- | --- | --- |
| LC-001 | judgment | Issue #4; Architecture | Host reconciliation authority, Start cutoff, trigger, player count, capacity, and compatibility are explicitly approved | owner decision plus decisions/spec updates | report:user-approved-2026-08-28 | pass | All six recommendations approved and recorded in owner docs |
| LC-002 | mechanical | Issue #4 | Every permutation of independently valid sibling claims yields the same canonical union/hash/defaults | exhaustive deterministic Core permutation, capacity, and Start-boundary tests | command:focused lobby Core tests 7/7 pass; command:non-eval Core 159/159 pass | pass | Exhaustive sibling and over-capacity permutations plus 1/2/5-player Start rejection passed |
| LC-003 | mechanical | Architecture; decisions | Fixed clients permit only the original inviter to reconcile validated claims; receipts reproduce the exact anchored union; local observations never render or start directly | Core genesis-lineage tests plus Messages anchored-receipt tests and source review | command:`/tmp/UnluckySevens-wave1-convergence-green.xcresult` (80/80 pass); report:2026-08-29-fresh-convergence-rereview | pass | Alternate genesis fails closed; multi-claim receipts reproduce exactly without treating device-scoped Messages UUIDs as wire identity |
| LC-004 | mechanical | Issue #4 | Host publishes idempotently per in-flight anchor/frontier, gates Start while unresolved, resumes after reopen with a live same-game session, and ignores post-Start stale joins | focused Messages transaction, persistence, receipt, and ledger tests | command:`/tmp/UnluckySevens-wave1-convergence-green.xcresult` (80/80 pass); report:2026-08-29-fresh-convergence-rereview | pass | Two-phase send/persist/commit, retry behavior, persistence, reconciliation hooks, and the hard post-Start barrier passed |
| LC-005 | observable | Issue #4 | Two concurrent guests and the host converge in both delivery orders, then setup uses exactly the reconciled roster | three-account device matrix | device-report:pending | pending | Two accounts cannot demonstrate competing guest branches |
| LC-006 | mechanical | AGENTS.md | Owner docs, generation, focused tests, fresh reviews, and completion gate pass | `make completion-gate PLAN=docs/exec-plans/active/concurrent-lobby-convergence.md` | command:pending | pending | Standard profile completion discipline |
<!-- verification-contract:end -->

<!-- fresh-review:start -->
| Reviewer | Required | Verdict | Evidence |
| --- | --- | --- | --- |
| constraint-auditor | yes | pass | report:2026-08-29-fresh-convergence-rereview; LC-001 through LC-004 pass, LC-005/006 remain pending by contract |
| concurrency/architecture specialist | yes | pass | report:2026-08-29-fresh-convergence-rereview; authority, genesis anchoring, Start cutoff, and deterministic ordering pass |
| Messages host/session specialist | yes | pass | report:2026-08-29-fresh-convergence-rereview; send/persist/commit, retry, receipt, reopen, and post-Start behavior pass |
<!-- fresh-review:end -->

## Living Record

### Progress

- [x] Mapped the sibling-join failure through Core validation, transcript selection, ledger replacement, visible roster, and Start.
- [x] Produced a decision-complete Sol/xhigh reconciliation plan with ownership and deterministic test/device matrices.
- [x] Record owner decisions and update owner docs.
- [x] Implement the approved Core reconciliation, durable branch evidence, Messages publication resolver, Start gate, capacity UI, and deterministic tests.
- [ ] Run three-account proof and completion gate; serialized generation, focused tests, and fresh reviews passed.

### Decisions

- 2026-08-28: Lock `standard` / `checkpointed`; planning may proceed, but production code pauses at the authority/capacity approval gate.
- 2026-08-28: User approved all six recommendations. Claim priority is the descending canonical join-state hash; this is already a SHA-256 digest and avoids a second tie-break representation.
- 2026-08-28: DEBUG direct-launch validation uses `uls.debug.launchFixtureID` and optional `uls.debug.launchActorID`; this is compiled out of Release.

### Discoveries

- 2026-08-28: Both sibling joins are independently Core-valid because each appends only its own actor to the same parent.
- 2026-08-28: Greatest-hash sibling selection is deterministic but lossy; the losing guest disappears from canonical selection, ledger state, UI, authoring, and Start.
- 2026-08-28: Core already permits the host to choose the setup roster at Start, but merging a local `observedJoiners` list only at Start would violate canonical-before-Start and single-source-of-truth requirements.
- 2026-08-28: No timeout can prove an absence of in-flight Messages updates. The proposed Start barrier therefore excludes only claims the host had not observed when Start published.
- 2026-08-28: The ledger must retain all valid lobby snapshots, not only actor IDs, so Core can revalidate parent/child join edges after reopen without trusting a second roster.
- 2026-08-29: Fresh review showed phase ordering must outrank revision/hash ordering: after a canonical setup/gameplay state is stored, even a higher-revision lobby snapshot is rejected before evidence or latest-state mutation.
- 2026-08-29: A same-game rev-0 shape is not sufficient genesis authority. Reconciliation now traces the selected anchor's exact `prevHash` lineage and seeds only that genesis plus the selected anchor.
- 2026-08-29: Canonical hashing proves content, not sender identity. An incoming reconciliation must reproduce exactly from its known parent and locally validated claims, while original-inviter authority remains a cooperative fixed-client authoring rule.
- 2026-08-29: Apple's `MSMessage.senderParticipantIdentifier` is device-scoped; each device assigns a different UUID for the same person. It therefore cannot authenticate actor strings authored on another device. No false equality check or protocol migration was added.
- 2026-08-29: The same device-scoped identity boundary may invalidate existing whole-roster comparisons in `isCompatibleWithActiveConversation(_:)` and exact-participant Player Record matching for remote actors. Local actor resolution is different because each player authors their own actor from that device's local identifier. This pre-existing risk is deferred to TD-001 / issue #2 rather than expanded into issue #4.
- 2026-08-29: Reconciliation publication is a two-phase transaction. Send success advances only to persistence verification; selected state changes only after the exact target is durable. Failure clears the attempt for retry while the unresolved frontier continues to gate Start.

## Validation and Outcome

- Automated: corrected focused Core convergence tests passed 12/12 across lobby and trade classifiers; the full non-eval Core suite passed 157/157; the corrected focused Messages convergence suite passed 80/80 in `/tmp/UnluckySevens-wave1-convergence-green.xcresult`. Fresh review passed LC-001 through LC-004.
- Observable: three-account proof is locked and pending execution.
- Deferred: a four-account extension; deterministic over-capacity ordering is covered in Core.

No completion claim is permitted until LC-002 through LC-006 and both required fresh reviews pass.
