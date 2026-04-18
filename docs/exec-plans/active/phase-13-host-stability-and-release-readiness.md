# Phase 13 — Messages Host Stability and Release Readiness

## Summary

Pull phase 13 forward as the active execution gate and fix the host-boundary substrate that is now blocking clean completion of phase 12.

This phase now exists as the immediate gate because repeated real-device failures showed the remaining blockers are no longer "missing gameplay features." They are authority, transport, and recovery issues at the Messages boundary.

Success means:

- join and trade-response progression no longer feel like transcript bookkeeping
- the app can recover the right active game context without raw-intent fallbacks whenever recoverable state exists
- the transport path no longer depends on the temporary `summaryText` bridge
- the repo has a durable per-game ledger and recovery model instead of device-local pending joins and ad hoc active-context patching
- after the new substrate lands, the remaining phase-12 gameplay signoff can be completed on top of it

Owner docs for concepts used here:

- [README](/Users/kunalsharda/Documents/Code/UnluckySevens/README.md)
- [ARCHITECTURE](/Users/kunalsharda/Documents/Code/UnluckySevens/ARCHITECTURE.md)
- [decisions](/Users/kunalsharda/Documents/Code/UnluckySevens/docs/decisions.md)
- [QA](/Users/kunalsharda/Documents/Code/UnluckySevens/docs/quality/qa.md)
- [2026-04-13 transport reliability plan](/Users/kunalsharda/Documents/Code/UnluckySevens/docs/quality/audits/2026-04-13-transport-reliability.md)
- [2026-04-16 phase boundary audit](/Users/kunalsharda/Documents/Code/UnluckySevens/docs/quality/audits/2026-04-16-phase-boundary-audit.md)
- [2026-04-16 base Catan feature matrix](/Users/kunalsharda/Documents/Code/UnluckySevens/docs/quality/audits/2026-04-16-base-catan-feature-matrix.md)
- [2026-04-16 phase 13 validation audit](/Users/kunalsharda/Documents/Code/UnluckySevens/docs/quality/audits/2026-04-16-phase-13-validation-audit.md)
- [Phase 12 Plan](/Users/kunalsharda/Documents/Code/UnluckySevens/docs/exec-plans/active/phase-12-gameplay-flows.md)

## Current State

What exists today:

- the repo already has broad gameplay coverage for lobby, setup, turn play, robber/discard, trade, dev cards, and winner-state presentation
- the remaining shipped gameplay flows now follow the rules-exact product model more closely: discard requires explicit card selection, player trade stays explicitly composed, and maritime trade is represented as a legal quick-trade list because the full option set is enumerable
- the board shell is now live-resize rather than snapshot-freeze/remount during normal host drag
- join intents can bridge back into inviter lobby state in some cases
- fresh lobby joins now publish canonical lobby `STATE` on the game session instead of relying on a detached join intent path
- current-player gameplay actions already use the same canonical game-session `STATE` path; the remaining non-canonical message work is now narrowed to responder-side trade/discard transport plus legacy recovery
- targeted trade responses can auto-apply into canonical state when the response message is surfaced and the correct anchor state can be recovered
- same-device cached published-state recovery now uses per-game keys instead of one global record
- a per-game local ledger now persists the latest known canonical `STATE`, observed joiners, and last active game identity instead of splitting those concerns across one global cached-state record plus device-local pending-join arrays
- active-context recovery and intent-context resolution now read from the same per-game ledger path rather than one global last-published-state record
- join intents now recover back into the best available canonical state for the same game instead of dropping into a raw join-intent route whenever recoverable state exists
- trade-response selection now prefers recovered canonical state for the same game whenever the surfaced response cannot be auto-applied cleanly
- canonical transport URLs now use `https://unluckysevens.app/...`; the earlier custom `unluckysevens://...` scheme was a protocol bug, not a harmless cosmetic choice
- canonical `STATE` publishes now prefer the currently selected bubble's `MSSession` for the same game instead of relying only on the in-memory per-game cache; this keeps transcript updates anchored to the surfaced session chain more reliably after context churn
- responder-side trade/discard transport now reuses the canonical game `MSSession` so remote responses stay inside the same game thread instead of forking into detached transcript artifacts
- freshly decoded incoming canonical `STATE` messages now write through into the per-game ledger immediately, so reopen/recovery does not depend only on locally published state
- compact envelope framing now removes the extra outer JSON-envelope overhead for fresh transport sends while keeping backward decode support for the older JSON-wrapped format
- compact canonical state transport now uses the `compactStateV2` wrapper, keeps the worst-case stress payload under the URL budget in tests, and retains legacy summary-fallback decode compatibility while fresh publishes are re-tested URL-only on the corrected `https` transport path
- the shell now exposes a lightweight active-games recovery surface so the app can reopen the latest canonical state for a known game even when the currently selected bubble is stale or missing
- the temporary transport badge, manual `Reload Board`, and host-gesture HUD are now gated off in the default root shell rather than always visible during normal play

What is still broken or incomplete:

- separate responder messages still need to be surfaced to the extension before they can be processed
- transport still retains legacy summary-fallback decode compatibility for older bubbles, but fresh publishes are URL-only again. The remaining question is whether valid `https` URLs are now stable enough on hardware to let the repo delete the summary bridge entirely after revalidation.
- the underlying diagnostics/probe code still exists for future troubleshooting, but it is no longer part of the default player-facing shell

What is explicitly deferred to the tail of this phase:

- full two-device standard-match signoff
- any remaining phase-12 gameplay-cohesion bugs that only become visible once the new substrate is in place
- final winner/end-state device confirmation
- row-level status for those deferred gameplay items is tracked in the [2026-04-16 base Catan feature matrix](/Users/kunalsharda/Documents/Code/UnluckySevens/docs/quality/audits/2026-04-16-base-catan-feature-matrix.md)

## Assumptions and Evidence Gate

### Assumption 1

Assumption:

- `MSConversation.selectedMessage` is not a live-updating pointer to the latest session bubble

Evidence:

- Apple documentation
- repeated real-device behavior in this repo

Disproof test:

- keep an older state bubble open while a newer join/trade response arrives and confirm whether the extension receives updated selected-message state without `didReceive` or manual selection

Fallback if false:

- simplify the bridge and reduce the local-ledger surface; this repo has not observed that behavior so far

### Assumption 2

Assumption:

- the current product still needs legacy summary-fallback decode until the corrected `https`-scheme `message.url` path is revalidated on real devices

Evidence:

- historical real-device failures while the repo was publishing custom-scheme URLs
- the temporary standalone probe and QA lesson showing `MSMessage.url` must be `http` or `https`

Disproof test:

- rerun the phase-13 join/trade/lobby flows on real devices after the `https://unluckysevens.app/...` fix and measure whether summary fallback still fires

Fallback if false:

- if valid `https` URLs still fail often enough on hardware, restore the fresh summary mirror until a stronger transcript-safe carrier strategy replaces it

### Assumption 3

Assumption:

- join and trade-response UX will remain poor while device-local pending joins and selected-bubble authority remain primary recovery tools

Evidence:

- current `LobbyDriverViewModel` and `LobbyMembershipResolver` behavior
- current join/trade failures on device

Disproof test:

- implement per-game ledger and transcript-authoritative join/response recovery, then rerun the same device scenarios

Fallback if false:

- if the simpler bridge already becomes robust after targeted fixes, reduce the scope of ledger work; current audit does not support that optimistic path

## Target End State

User-visible result:

- join and trade-response progression feel like game actions, not transcript maintenance
- the app recovers the right game when a recoverable state exists
- transient raw-intent shells become rare diagnostic fallbacks rather than normal UX
- release-testing builds no longer depend on leaky payload mirrors

Code and docs result:

- per-game canonical ledger and context recovery path exist
- lobby roster recovery no longer depends on device-local pending joins as canonical state
- transport-reliability work is active code, not just a future audit
- temporary diagnostics have a clear release-readiness retirement path
- phase-12 remaining items are explicitly tracked as the tail of phase 13 instead of pretending phase 12 can finish independently first

Acceptance boundary:

- phase 13 is complete when the host/transport/recovery substrate is strong enough that the final phase-12 gameplay signoff can be completed without re-opening architecture debates
- phase 13 also owns that tail signoff before it exits

## Implementation Plan

### Stage 13.1 — Per-Game Ledger and Active-Context Recovery

- introduce a per-game canonical local ledger for latest known `STATE`
- make active-game resolution prefer:
  - exact anchor match
  - latest canonical state for the same game
  - only then raw-intent fallback
- eliminate device-local pending joins as canonical lobby authority

### Stage 13.2 — Join and Trade Response Bridge

- make inviter-side join handling resolve back into the active lobby/game context whenever possible
- make current-player trade-response handling auto-progress into canonical state as soon as a surfaced response can be anchored
- make stale surfaced responses prefer recovered latest state instead of intent-only shells
- document and handle first-wins trade-response race semantics explicitly

### Stage 13.3 — Transport Reliability Program

- execute the measured transport-reliability plan in the documented order
- compact and measure payloads before deleting fallback paths
- keep legacy summary-fallback decode only as a backward-compatibility path until repeated device evidence supports deleting it entirely

### Stage 13.4 — Multi-Game and Release-Readiness Surfaces

- identify active game context explicitly
- support browsing and recovering active games in the thread
- add release-readiness runbooks and device checks
- gate down or remove temporary diagnostics once the host substrate is stable

### Stage 13.5 — Tail Phase-12 Gameplay Signoff

- rerun full two-device gameplay completion on the corrected substrate
- fix remaining real gameplay bugs found after the host/transport overhaul
- close the deferred phase-12 items that were blocked by the old architecture

## Validation

### Automated

Run the practical gate serially:

```bash
bash ./scripts/gen.sh
swift test --package-path Packages/ULS_CoreGame --skip ULS_CoreGameEvals
swift test --package-path Packages/ULS_CoreGame --filter ULS_CoreGameEvals
swift test --package-path Packages/ULS_Transport
xcodebuild -workspace UnluckySevens.xcworkspace -scheme MessagesExtension -destination 'generic/platform=iOS Simulator' build
xcodebuild -workspace UnluckySevens.xcworkspace -scheme UnluckySevens-Workspace -destination 'platform=iOS Simulator,name=iPhone 15' test
```

Add and maintain focused tests for:

- per-game context recovery
- join bridge recovery
- trade-response auto progression
- stale surfaced response handling
- transport payload budgeting and decoding
- active-games overlay recovery summaries

### Manual

- two-device join while inviter bubble stays open
- two-device trade accept/decline/counter while proposer bubble stays open
- stale bubble reopen after newer state exists
- active-games recovery using only the local per-game ledger and no currently selected canonical state bubble
- extension reopen and same-game recovery
- multi-game thread selection
- full standard-match pass after stage 13.5

### 2026-04-16 Validation Snapshot

Automated lanes completed:

- `bash ./scripts/gen.sh`
- `swift test --package-path Packages/ULS_CoreGame --skip ULS_CoreGameEvals`
- `swift test --package-path Packages/ULS_Transport`
- `xcodebuild -workspace UnluckySevens.xcworkspace -scheme MessagesExtension -destination 'generic/platform=iOS Simulator' build`
- `xcodebuild -workspace UnluckySevens.xcworkspace -scheme UnluckySevens-Workspace -destination 'platform=iOS Simulator,name=iPhone 15' test`

Automated lane still unresolved in this environment:

- `swift test --package-path Packages/ULS_CoreGame --filter ULS_CoreGameEvals`
  - the lane builds immediately, then hangs without producing eval progress
  - do not call this green yet; treat it as an environment/test-harness issue that still needs separate investigation

Manual signoff still required before phase exit:

- real two-device join progression without bubble hopping
- real two-device trade accept/decline/counter progression on surfaced response bubbles
- stale-bubble reopen and active-games recovery on hardware
- full standard-match pass on real devices after the host/transport overhaul

## Progress

- [x] Stage 13.1 — Per-Game Ledger and Active-Context Recovery
- [x] Stage 13.2 — Join and Trade Response Bridge
- [x] Stage 13.3 — Transport Reliability Program
- [x] Stage 13.4 — Multi-Game and Release-Readiness Surfaces
- [ ] Stage 13.5 — Tail Phase-12 Gameplay Signoff

## Decisions and Discoveries

- 2026-04-16: phase 13 was pulled forward after a repo-wide audit showed the remaining blockers were authority/recovery architecture issues, not ordinary phase-12 gameplay gaps.
- 2026-04-16: the remaining unfinished phase-12 work is now explicitly treated as the tail of phase 13 rather than the current execution gate.
- 2026-04-16: stage 13.1 landed as a real per-game local ledger. Latest canonical state, observed joiners, and last-active-game recovery now come from the same ledger instead of separate pendingJoiners arrays and one global cached published-state record.
- 2026-04-16: stage 13.2 no longer exposes a proposer-side "Apply Selected Response" gameplay path. Trade-response intents are still an internal authority primitive, but normal trade UI should either auto-resolve them into canonical `STATE` or stay on the state-driven trade surface.
- 2026-04-16: stage 13.2 completed its recovery-bridge hardening. Join intents now recover into the best available canonical state for the same game whenever possible, cached published-state recovery falls back per game rather than globally, and surfaced trade responses now prefer recovered state when auto-apply cannot happen cleanly instead of dropping into raw intent/open-game shells.
- 2026-04-16: stage 13.3 started with compact envelope framing in `ULS_Transport`. Fresh sends now use a smaller binary-framed base64url envelope while decode remains backward-compatible with the older JSON-wrapped transport payloads.
- 2026-04-16: stage 13.3 completed its first shippable transport cut. `CompactStateTransport` now uses the `compactStateV2` wrapper, the worst-case canonical STATE stress test stays under the URL budget, and fresh publishes keep a readable multiline summary mirror because real-device join flow still cannot rely on `message.url` alone on first open.
- 2026-04-16: real-device lobby join re-confirmed that URL-only fresh publishes were not safe enough for first-open recovery, so the outgoing summary mirror was restored in readable multiline form rather than the older payload-first one-line format.
- 2026-04-16: the missing-URL diagnosis was materially revised after a standalone probe showed the repo had been publishing custom-scheme `MSMessage.url` values. `MSMessage.url` must be `http` or `https`; the main app and the probe both emitted `https://unluckysevens.app/...` after the fix, and device validation had to be rerun against that corrected contract before treating remaining misses as platform behavior.
- 2026-04-16: after the `https` fix and passing transport/probe validation, fresh outgoing summary mirroring was disabled again. The repo now re-tests URL-only publication while still decoding legacy `summaryText` payload mirrors from older transcript bubbles.
- 2026-04-17: canonical `STATE` session reuse was tightened so send-time session selection prefers `activeConversation.selectedMessage?.session` when the selected bubble belongs to the same game. The prior cache-only path could fork the transcript chain after context recovery or extension relaunch, leaving valid `STATE` publishes on a different `MSSession` than the bubble the user had actually selected.
- 2026-04-17: the repo stopped treating lobby join as a generic responder intent. Fresh join publishes canonical lobby `STATE` on the game session, `Start Game` now works from the latest lobby rev instead of a special-case rev0 invite bubble, and start-roster assembly merges the current lobby roster with observed joiners so concurrent join states can still converge at start.
- 2026-04-17: responder-side trade/discard transport now reuses the canonical game session again. The earlier detached-session approach prevented transcript collapse and made open-bubble async play feel like separate bubble bookkeeping. The shell now compensates by preferring recovered game `STATE` whenever a responder bubble can be resolved, so the UI does not drop into a raw response shell if recoverable context exists.
- 2026-04-17: per-game ledger writes now happen on incoming decoded `STATE` as well as locally sent `STATE`. The prior local-send-only path meant recovery quality was asymmetric across devices, which is the wrong tradeoff for an iMessage-hosted game where reopen and stale-bubble recovery are first-order concerns.
- 2026-04-17: trade-response auto-apply was failing for a concrete reason: the extension was validating responder `acceptTrade` / `declineTrade` / `counterTrade` transitions as if the current player were the action actor. The authority-side publish path now preserves the responder as the validation/audit actor for those trade-response transitions while still publishing the resulting canonical `STATE` from the authority device.
- 2026-04-17: the repo’s internal terminology was tightened to match the intended product model. Fresh lobby joins and current-player gameplay are canonical `STATE` updates on the game session. Detached `INTENT` transport is now treated as responder-only for discard/trade plus legacy/debug compatibility, and fallback shells label those cases as responder or legacy transport instead of pretending generic intents are the normal gameplay substrate.
- 2026-04-18: the gameplay-flow rule was narrowed after product review. Discard and player trade keep explicit resource selection, but maritime trade returns to a quick-trade list because the engine already enumerates the complete legal option set and the list does not hide extra player choice.
- 2026-04-17: focused validation for the rules-exact discard and maritime trade cleanup passed:
  - `xcodebuild -workspace UnluckySevens.xcworkspace -scheme MessagesExtension -destination 'generic/platform=iOS Simulator' build`
  - `xcodebuild -workspace UnluckySevens.xcworkspace -scheme UnluckySevens-Workspace -destination 'platform=iOS Simulator,name=iPhone 15' -only-testing:MessagesExtensionTests/GameDiscardPanelModelBuilderTests -only-testing:MessagesExtensionTests/TurnInteractionResolverTests -only-testing:MessagesExtensionTests/GameTradePanelModelBuilderTests -only-testing:MessagesExtensionTests/GameShellProjectionBuilderTests test`
- 2026-04-17: focused validation for the lobby/trade architecture correction passed:
  - `bash ./scripts/gen.sh`
  - `xcodebuild -workspace UnluckySevens.xcworkspace -scheme MessagesExtension -destination 'generic/platform=iOS Simulator' build`
  - `xcodebuild -workspace UnluckySevens.xcworkspace -scheme UnluckySevens-Workspace -destination 'platform=iOS Simulator,name=iPhone 15' -only-testing:MessagesExtensionTests/LobbyDriverViewModelIdentityTests -only-testing:MessagesExtensionTests/TurnIntentPublishActorResolverTests -only-testing:MessagesExtensionTests/TurnIntentContextResolverTests -only-testing:MessagesExtensionTests/JoinIntentContextResolverTests -only-testing:MessagesExtensionTests/TranscriptTransportSupportTests test`
  - `xcodebuild -workspace UnluckySevens.xcworkspace -scheme UnluckySevens-Workspace -destination 'platform=iOS Simulator,name=iPhone 15' -only-testing:MessagesExtensionTests/LobbyScreenModelBuilderTests test`
  - `git diff --check` on the touched lobby/transport/docs files
- 2026-04-17: the selection watch in `MessagesViewController` now stays alive while the extension has an active game/selection context instead of stopping after a short 2.4s burst. The earlier burst polling was too optimistic for delayed same-session surfacing, which meant an already-open bubble could miss remote join/trade-response updates if `didReceive` was late or absent.
- 2026-04-16: stage 13.4 started with an in-app active-games recovery surface. Recoverable games now have a user-facing reopen path backed by the per-game ledger instead of depending entirely on the selected transcript bubble.
- 2026-04-16: stage 13.4 completed its release-readiness gating pass. The active-games recovery surface remains visible, but the temporary transport badge, host-gesture HUD, and manual `Reload Board` control are now gated off from the default root shell so normal play no longer exposes operator-only diagnostics.
- 2026-04-16: stage 13.5 simulator/practical-gate validation is green except for the `ULS_CoreGameEvals` lane, which still hangs after the build phase in this environment. Hardware/two-device QA remains the honest exit gate for the phase.

## Outcome

Planned result:

- a host-stable, recovery-aware, release-ready Messages game substrate
- plus the remaining phase-12 gameplay signoff completed on top of it

What remains after this phase by design:

- broad UI polish and trust-surface work in phase 14
- deeper structural decomposition and test-architecture cleanup in phase 15
