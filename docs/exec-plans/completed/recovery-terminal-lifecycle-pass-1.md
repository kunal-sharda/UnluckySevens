# Recovery and Terminal Lifecycle — Pass 1

## Purpose and Outcome

Implement the functional recovery and terminal-state substrate needed before the remaining UI-polish and full-productization passes. Success means canonical resignation, deterministic recovery selection, bounded/versioned local history, recovery resend, and functional player-facing management exist with focused behavioral proof. This pass does not claim visual completion or TestFlight readiness.

> Reopened 2026-07-26 and relocked 2026-07-29: resignation is non-terminal; remaining active players continue. Any active player may propose a unanimous draw. The inviter/host may end unilaterally, while the UI first offers a draw when none has been attempted. The original terminal-resignation implementation and evidence are superseded.

## Execution Settings

- Validation profile: `standard`
- Delivery posture: `direct`
- Rationale: Product behavior and state semantics are explicitly settled. The functional baseline should land without a visual checkpoint; the separate Pass 2 plan owns the one required visual approval gate.

## Context and Boundaries

- Core owns result semantics, resignation legality, hashing, and snapshot validation.
- Transport remains canonical `STATE` only.
- Messages owns local ledger persistence, transcript session adaptation, and presentation.
- No timeout, force-advance, lobby cancellation, automatic rematch, backend sync, or pre-TestFlight compatibility is added.
- A resigning player becomes inactive: turns and setup slots skip them, they cannot produce, trade, vote, hold awards, or win, their hand returns to the bank, their development cards retire, and their existing board pieces remain inert blockers.
- Any active player may propose a draw and automatically votes yes. Every remaining active player must approve; a rejection clears the proposal and play continues. There is no timeout.
- The inviter/host remains the administrative host even after resigning and may end the game unilaterally. Host end and agreed draw are neutral terminal results with final scores and no winner.
- The host confirmation leads with Propose Draw when no vote has been attempted but retains End Game Anyway as a destructive secondary action.
- Existing dirty lobby work belongs to the user and must not be reverted.

## Milestones / Plan of Work

1. Replace terminal resignation with Core-owned inactive-player continuation, unanimous draw voting, neutral host-end/draw results, and ordinary victory.
2. Extend compact state transport, payload budgets, and standalone snapshot validation.
3. Version and bound the per-game ledger; add deterministic sibling selection, archive, corruption cleanup, and Active/Finished projections.
4. Add recovery resend, functional game management, resign confirmation, terminal result copy, and New Game.
5. Update owner docs, create the checkpointed Pass 2 visual plan, and run the standard completion gate.

## Verification Contract and Fresh Review

<!-- verification-contract:start -->
| ID | Class | Source | Acceptance | Verification | Evidence | Status | Rationale |
| --- | --- | --- | --- | --- | --- | --- | --- |
| RTL1-001 | mechanical | corrected user direction | Core models resignation as non-terminal, preserves legal continuation for remaining players, and gives explicit game-end authority only to the host | focused Core tests | command:ULS_CoreGame-142-pass-2026-07-29 | pass | Setup/current/off-turn resignation, inactive assets, draw approval/rejection, resigned-host authority, neutral results, victory regression, and deterministic matches pass |
| RTL1-002 | mechanical | architecture and corrected user direction | Transport remains STATE-only and compact lifecycle/result payloads round-trip within budget | focused transport and payload tests | command:ULS_Transport-5-pass-2026-07-29; command:CompactStateTransportTests-5-pass-2026-07-29 | pass | Compact v4 round-trips inactive players, open draw votes, and neutral host results; stress payload remains below 64 KB |
| RTL1-003 | mechanical | user plan | Invalid snapshots never enter selection or persistence and equal-revision siblings converge deterministically | focused selection and ledger tests | command:MessagesExtensionTests-284-pass-2026-07-29; report:fresh-architecture-behavior-review-2026-07-29 | pass | Snapshot validation is applied before recording or activation; phase-specific invariants and selection, authoring, and ledger revision/hash ordering passed fresh review |
| RTL1-004 | mechanical | user plan | Ledger records are versioned, corrupt entries are repaired, finished history is capped at eight, and archive is local | focused ledger tests | command:MessagesExtensionTests-284-pass-2026-07-29 | pass | Migration, corruption removal, index repair, active retention, finished pruning, archive, and fork ordering passed in the current full suite |
| RTL1-005 | observable | corrected user direction | Open, resend, archive, non-terminal resign, host end, terminal result, and New Game work through installed Messages surfaces | XCUITest and inspected simulator state | command:installed-lifecycle-5-pass-2026-07-29 | pass | Fresh standalone-app install passed dedicated Games, archive/restore, unchanged resend plus continued resignation, accurate confirmation, and draw-first host-end journeys across focused runs |
| RTL1-006 | judgment | corrected user direction | Functional baseline uses existing tabletop/accessibility patterns without claiming final visual approval | source and artifact inspection | report:functional-baseline-inspection-2026-07-29 | pass | Games is a dedicated surface available from invitation/loading and current-game navigation; copy is accurate; final visual approval remains explicitly owned by Pass 2 |
| RTL1-007 | mechanical | AGENTS.md | Standard profile completion and documentation freshness gates pass | completion gate | command:completion-gate-2026-07-29 | pass | Contract is terminal and the final gate is the closing command for this plan |
<!-- verification-contract:end -->

<!-- fresh-review:start -->
| Reviewer | Required | Verdict | Evidence |
| --- | --- | --- | --- |
| constraint-auditor | yes | pass | Fresh audit on 2026-07-29 found no functional constraint blocker |
| architecture | yes | pass | Fresh review on 2026-07-29 confirmed Core/Transport/Messages ownership and invariants |
| behavioral | yes | pass | Fresh review on 2026-07-29 confirmed resignation, draw, host-end, victory, recovery, and ledger behavior |
| product-ux | no | not-applicable | Final product judgment is deferred to checkpointed Pass 2 |
<!-- fresh-review:end -->

## Living Record

### Progress

- [x] Corrected Core resignation, draw, host-end, and victory lifecycle.
- [x] Transport and snapshot integrity.
- [x] Ledger lifecycle and deterministic selection.
- [x] Dedicated Games recovery/lifecycle UI and installed functional journeys.
- [x] Owner docs and reset Pass 2 checkpoint plan.
- [x] Fresh standard-profile reviews.
- [x] Completion gate.

### Decisions

- 2026-07-29: Resignation is non-terminal. The player stays in the canonical roster/history but becomes inactive; their pieces remain blockers, their resource hand returns to the bank, development cards retire, and active rules skip them.
- 2026-07-29: Any active player may propose a draw; all remaining active players must approve. Rejection clears the proposal without changing play and there is no timeout.
- 2026-07-29: The original inviter remains host authority even if inactive. Host end is unilateral, but the UI offers a draw first when no draw has been attempted. Draw and host end have no winners.
- 2026-07-26: Active local games persist until archive; only the eight most recent finished games are retained.
- 2026-07-26: Resend republishes an unchanged validated state and does not advance revision or hash.
- 2026-07-26: Equal-revision siblings resolve to the lexicographically greatest valid state hash.
- 2026-07-26: `MSSession` persistence is not promoted without two-device replacement evidence. The supported implementation reuses a matching selected or in-memory session and deliberately creates a fresh recovery bubble after an extension restart.

### Discoveries

- `xcrun xctrace list devices` reported the available iPhone and iPads offline, so the requested two-device `MSSession` archive experiment could not run. The conservative fresh-bubble fallback is implemented and the promotion experiment remains a real-device Pass 3 item.
- The pre-existing DEBUG segmented result rail had already been rejected by the user. Pass 1 therefore adds a restrained Release functional footer while the consolidated Pass 2 plan owns the replacement visual direction.
- The recovery UX fixture originally generated its board from a hard-coded board seed while advertising a different canonical master seed. Compact decode correctly regenerated a different board and the ledger rejected the hash-invalid result. The fixture now derives its board from the canonical master seed, with a regression covering resignation, compact round-trip, persistence, and summary copy.

## Validation and Outcome

Current corrected implementation evidence:

- `bash ./scripts/gen.sh`: passed after the final source update.
- `make build`: passed after granting the normal Tuist/Xcode cache access required outside the workspace sandbox.
- `swift test --package-path Packages/ULS_CoreGame`: 142 tests passed, including 10 deterministic match evaluations.
- `swift test --package-path Packages/ULS_Transport`: 5 tests passed.
- Full `MessagesExtensionTests`: 284 tests passed, including the final fixture-integrity regression.
- Latest standalone Messages simulator build: passed.
- Installed focused journeys: dedicated Games, archive/restore, unchanged resend plus continued resignation, accurate resignation confirmation, and draw-first host end all passed across fresh-install focused runs.
- `make completion-gate PLAN=docs/exec-plans/active/recovery-terminal-lifecycle-pass-1.md`: passed on 2026-07-29.

Fresh constraint, architecture, and behavioral reviews passed. Pass 1 is complete; it intentionally does not claim TestFlight readiness.

Remaining external evidence: no physical device was online for the `MSSession` persistence experiment. Persisted sessions therefore remain disabled and the safe fresh-bubble fallback is canonical until Pass 3 can run the two-device experiment.

Pass 2 is recorded in [Recovery and Terminal Lifecycle — Pass 2 UI Polish](recovery-terminal-lifecycle-pass-2-ui-polish.md). Pass 1 does not claim TestFlight readiness.
