# 2026-04-16 Phase Boundary Audit

## Summary

This audit was written after repeated real-device failures around join progression, trade acceptance, transcript recovery, and active-game desync.

The main conclusion is:

- the repo no longer has a "finish a few more gameplay features, then harden later" problem
- it has a Messages-host authority/recovery architecture problem that is now blocking clean completion of phase 12

Because of that, phase 13 should be pulled forward as the active execution gate. The remaining phase-12 finish work should move to the tail of phase 13 instead of continuing to stack feature patches on top of the current substrate.

## Scope

This audit reviewed:

- the active phase and roadmap docs
- `MessagesViewController`
- `LobbyDriverViewModel`
- transcript transport helpers and intent-context resolution
- shell projection and routing
- trade and dev-card presentation builders
- current test coverage and debt tracking

## Evidence Used

- current code under `MessagesExtension/`, `Packages/ULS_CoreGame`, and `Packages/ULS_Transport`
- current tests under `MessagesExtension/Tests`
- [phase-12-gameplay-flows.md](/Users/kunalsharda/Documents/Code/UnluckySevens/docs/exec-plans/completed/phase-12-gameplay-flows.md)
- [roadmap.md](/Users/kunalsharda/Documents/Code/UnluckySevens/docs/exec-plans/roadmap.md)
- [tech-debt-tracker.md](/Users/kunalsharda/Documents/Code/UnluckySevens/docs/exec-plans/tech-debt-tracker.md)
- [qa.md](/Users/kunalsharda/Documents/Code/UnluckySevens/docs/quality/qa.md)
- Apple Messages API documentation for `MSConversation.selectedMessage` and `MSMessagesAppViewController`

## Findings

### F1. Separate-bubble intent processing is the main product bottleneck

Severity:

- critical

What the code does today:

- `MessagesViewController` only updates the extension through `didSelect`, `didReceive`, and later polling of `conversation.selectedMessage`
- `LobbyDriverViewModel` can auto-apply certain surfaced trade-response intents, but only after the response message has been surfaced to the extension

Why it matters:

- the currently selected `STATE` bubble is not a live subscription to later bubbles
- join and trade acceptance therefore still depend on Messages surfacing a newer message at least once
- this is the core reason remaining async gameplay work keeps feeling blocked by "intent bridge" behavior rather than ordinary UI bugs

Repo consequence:

- finishing phase-12 gameplay polish first is no longer efficient
- the phase-13 authority/recovery substrate needs to become the gate

Primary files:

- [MessagesViewController.swift](/Users/kunalsharda/Documents/Code/UnluckySevens/MessagesExtension/Sources/App/MessagesViewController.swift)
- [LobbyDriverViewModel.swift](/Users/kunalsharda/Documents/Code/UnluckySevens/MessagesExtension/Sources/Features/Lobby/LobbyDriverViewModel.swift)
- [TurnIntentContextResolver.swift](/Users/kunalsharda/Documents/Code/UnluckySevens/MessagesExtension/Sources/Presentation/TurnIntentContextResolver.swift)

Recommended fix:

- make phase 13 own an app-resident canonical-state ledger plus surfaced-message bridge rules
- stop treating "selected bubble" as the primary active-game authority surface

### F2. Lobby roster assembly is still device-local, not transcript-authoritative

Severity:

- critical

What the code does today:

- join flow still depends on `pendingJoiners` stored in `UserDefaults`
- host start still uses that device-local list to assemble the launch roster

Why it matters:

- this is a real source of cross-device lobby drift
- it is incompatible with robust async Messages behavior
- it directly affects join/start correctness, not just a debug view

Repo consequence:

- this can no longer stay scheduled for a later polish phase
- it belongs in the phase-13 pull-forward work

Primary files:

- [LobbyDriverViewModel.swift](/Users/kunalsharda/Documents/Code/UnluckySevens/MessagesExtension/Sources/Features/Lobby/LobbyDriverViewModel.swift)
- [LobbyMembershipResolver.swift](/Users/kunalsharda/Documents/Code/UnluckySevens/MessagesExtension/Sources/Presentation/LobbyMembershipResolver.swift)

Recommended fix:

- replace device-local pending joins with a transcript-authoritative per-game join ledger
- allow local cache only as temporary recovery, not as canonical lobby assembly

### F3. Transport is still sitting on a temporary bridge

Severity:

- critical

What the code does today:

- canonical payloads still prefer `message.url`
- the repo still mirrors a one-line payload into `summaryText` as a temporary fallback

Why it matters:

- `summaryText` is user-visible and explicitly temporary
- the real carrier redesign is not done yet
- reopen/recovery bugs are still entangled with carrier size and carrier fidelity

Repo consequence:

- the transport program documented on 2026-04-13 is no longer optional future hardening
- it is part of the current bottleneck

Primary files:

- [LobbyDriverViewModel.swift](/Users/kunalsharda/Documents/Code/UnluckySevens/MessagesExtension/Sources/Features/Lobby/LobbyDriverViewModel.swift)
- [TranscriptTransportSupport.swift](/Users/kunalsharda/Documents/Code/UnluckySevens/MessagesExtension/Sources/Presentation/TranscriptTransportSupport.swift)
- [2026-04-13 transport reliability plan](/Users/kunalsharda/Documents/Code/UnluckySevens/docs/quality/audits/2026-04-13-transport-reliability.md)

Recommended fix:

- promote the transport-reliability plan into the active phase-13 execution path
- stop treating the `summaryText` mirror as an acceptable medium-term solution

### F4. Product fallback still leaks into raw-intent/open-game shells

Severity:

- high

What the code does today:

- `GameShellProjectionBuilder` still builds explicit `INTENT(...)` projections
- `MessagesRootRoute` falls back from game-state routing when state recovery is missing

Why it matters:

- this is acceptable as a debug/operator fallback
- it is not acceptable as the normal user-facing answer for joins, trade responses, or async reopen

Repo consequence:

- phase 13 should explicitly reduce "raw intent shell" cases to only unrecoverable host situations
- recoverable cases should always prefer the best canonical state for that game

Primary files:

- [GameShellProjection.swift](/Users/kunalsharda/Documents/Code/UnluckySevens/MessagesExtension/Sources/Presentation/GameShellProjection.swift)
- [MessagesRootRoute.swift](/Users/kunalsharda/Documents/Code/UnluckySevens/MessagesExtension/Sources/App/MessagesRootRoute.swift)

Recommended fix:

- make canonical-state recovery the first-class route decision
- keep intent-only shells as explicit diagnostics/fallback only

### F5. `LobbyDriverViewModel` is still the highest-risk orchestration choke point

Severity:

- high

What the code does today:

- one file still owns transcript selection, identity, lobby state, join bridge, trade-response bridge, transport publishing, cached-state recovery, diagnostics, and large parts of gameplay projection

Why it matters:

- every host-boundary fix now crosses the same file
- state recovery, gameplay UX, and debug surfaces remain too coupled

Repo consequence:

- phase 13 should explicitly carve out:
  - per-game ledger/context recovery
  - transcript transport adaptation
  - gameplay projection
- this decomposition is not only a phase-15 cleanup concern anymore; a minimal version is needed now for host stability

Primary files:

- [LobbyDriverViewModel.swift](/Users/kunalsharda/Documents/Code/UnluckySevens/MessagesExtension/Sources/Features/Lobby/LobbyDriverViewModel.swift)

Recommended fix:

- use phase 13 to extract the authority/recovery surfaces out of the gameplay shell path before broader phase-15 cleanup

### F6. Remaining phase-12 work is now mostly signoff and post-overhaul product fit

Severity:

- medium

What still remains from phase 12 after this audit:

- full two-device standard-match signoff after the substrate is corrected
- any remaining gameplay-shell issues that only become clear once join/trade/reopen are stable
- final winner/end-state sanity pass on device
- remaining device QA for iPhone/iPad spacing, trade/dev/build flow continuity, and match completion

What does not need pulling forward:

- recap/history/dispute
- broad visual redesign
- structural test-architecture cleanup

Repo consequence:

- phase 12 is no longer the current execution gate
- its remaining work should be treated as the tail of phase 13

## Recommendation

Make the following resequencing change immediately:

1. pull phase 13 forward as the active execution gate
2. treat join/trade authority, local ledger, transport reliability, active-game recovery, and surfaced-message auto progression as the current critical path
3. move the remaining phase-12 finish work to the tail of phase 13
4. do not continue treating current join/trade/desync bugs as isolated feature-polish issues

## Proposed New Boundary

### Phase 13 should now own

- per-game canonical local ledger
- join/lobby bridge and transcript-authoritative roster recovery
- surfaced trade/join auto progression into canonical state
- active-game recovery rules
- transport reliability plan execution
- `message.url` carrier hardening and removal of the `summaryText` bridge
- multi-game active-context identity and recovery
- release-readiness operator tooling and temporary diagnostic retirement plan
- final phase-12 gameplay signoff after the new substrate is in place

### Remaining phase-12 items to finish at the end of phase 13

- full real-device standard-match pass
- last gameplay-shell bugs found after the host/transport overhaul
- end-of-match/winner-state confirmation on hardware
- final iPhone/iPad gameplay-cohesion checks

## Validation Notes

At the time this audit was written:

- the focused state-selection and turn-intent-context tests were green
- the simulator build for `MessagesExtension` was green
- broader repo validation should still be rerun after the phase-boundary doc updates land
