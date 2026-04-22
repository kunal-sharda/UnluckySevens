# Phase 13 — Messages Host Stability and Release Readiness

## Status

Phase 13 is complete from a code-and-docs standpoint and is now the TestFlight-prep closeout record.

The remaining work before external testing is not more architecture churn. It is focused manual device validation on the current build.

## Summary

Phase 13 pulled the repo out of the "feature-complete but host-fragile" state and made the Messages substrate shippable enough to hand off to TestFlight-oriented QA.

The major outcome is that fresh player flows now run on one consistent model:

- canonical `STATE` on the per-game `MSSession`
- per-game ledger recovery instead of one global cached-state bridge
- URL-only transcript payload transport
- no player-facing dependence on raw legacy join/setup/current-turn transcript bubbles

## What Landed

### 13.1 — Per-Game Ledger and Recovery

- per-game ledger stores latest known canonical state and active-game recovery identity
- incoming decoded `STATE` writes through into that ledger, not only locally published state
- active-game recovery prefers same-game canonical state instead of stale selected bubbles
- the shell exposes a compact `Game` / `Games` recovery affordance backed by that ledger

### 13.2 — Canonical Lobby and Responder Flows

- lobby invite, join, and start now stay on canonical lobby `STATE`
- the host no longer waits in a misleading synthetic post-send lobby; the extension dismisses after invite send and the host reopens the real bubble
- targeted `acceptTrade`, `declineTrade`, and `counterTrade` publish canonical state directly from the responder device while preserving responder actor semantics
- forced discard also publishes canonical state directly from the discarding device
- multi-player discard is serialized in locked roster order to avoid sibling pending-discard races

### 13.3 — Transport Reliability

- canonical payload transport now uses valid `https://unluckysevens.app/...` message URLs
- compact envelope framing plus `compactStateV2` keep worst-case payloads under the URL budget in tests
- app runtime is URL-only again
- app-side `summaryText` payload fallback is retired
- pre-TestFlight development transcripts that depended on mirrored-summary payloads are intentionally unsupported after this cleanup

### 13.4 — Recovery and Release-Readiness Surfaces

- default player shell no longer exposes temporary transport badge, reload controls, or lobby debug surfaces
- diagnostics remain available for troubleshooting branches instead of shipping as normal product UX
- stale-bubble authoring now prefers the newest known canonical state for the same game before drafting or publishing actions

### 13.5 — Tail Gameplay Hardening

- lobby/start flow is aligned with selected-bubble reality in Messages
- discard and trade responder progression no longer depend on surfaced responder-envelope transport
- hit-testing and shell-routing issues around shelves and dock actions were tightened
- the remaining gameplay caveats are now narrow and explicitly documented rather than being mixed into the core flow

## Legacy Cleanup Completed

Phase 13 also retired the remaining pre-TestFlight legacy runtime paths that were still distorting the app model:

- app-side `summaryText` mirrored-payload decode removed
- app-side legacy join/setup/current-turn intent recovery removed
- raw legacy fallback shells removed from normal player flow
- old typed `JoinIntentV1` / `SetupPlacementIntentV1` transport models removed from `ULS_Transport`

The only intentionally preserved residue is lower-level generic intent-envelope support plus inert tombstone source files that still exist solely because the checked-in Xcode target graph points at those paths and generated project files are not committed here.

## Known Remaining Risks

These are the real remaining risks after phase 13. They are no longer phase blockers, but they are the things to watch during TestFlight prep.

### 1. Simultaneous multi-recipient trade accept is still nondeterministic

- two targeted recipients can still accept from the same stale offer state
- one sibling accepted state will converge over the other
- the table should not brick, but the winner is still delivery-order-driven rather than deterministic first-wins

### 2. Session continuity can still fork after sessionless recovery

- if the shell publishes from recovered canonical state with neither a selected same-game session nor a cached session, the transport helper still creates a fresh `MSSession`
- that is more of a transcript cleanliness risk than a rules-integrity bug

### 3. Lobby concurrent join convergence still uses observed-join merge at start

- fresh join is canonical now
- concurrent joins from the same older lobby rev can still transiently appear as sibling lobby states
- host start currently merges visible roster with observed joiners so the roster converges at start even if the lobby surface was briefly incomplete

## Validation

### Automated

Practical gate:

```bash
bash ./scripts/gen.sh
swift test --package-path Packages/ULS_CoreGame --skip ULS_CoreGameEvals
swift test --package-path Packages/ULS_Transport
xcodebuild -workspace UnluckySevens.xcworkspace -scheme MessagesExtension -destination 'generic/platform=iOS Simulator' build
xcodebuild -workspace UnluckySevens.xcworkspace -scheme UnluckySevens-Workspace -destination 'platform=iOS Simulator,name=iPhone 15' test
```

Focused validation used during the closeout slices:

```bash
swift test --package-path Packages/ULS_CoreGame --filter TurnRollSevenV1Tests
xcodebuild -workspace UnluckySevens.xcworkspace -scheme MessagesExtension -destination 'generic/platform=iOS Simulator' build
xcodebuild -workspace UnluckySevens.xcworkspace -scheme UnluckySevens-Workspace -destination 'platform=iOS Simulator,name=iPhone 15' -only-testing:MessagesExtensionTests/GameDiscardPanelModelBuilderTests -only-testing:MessagesExtensionTests/TurnInteractionResolverTests -only-testing:MessagesExtensionTests/TradeResponsePublicationResolverTests -only-testing:MessagesExtensionTests/TurnIntentPublishActorResolverTests test
xcodebuild -workspace UnluckySevens.xcworkspace -scheme UnluckySevens-Workspace -destination 'platform=iOS Simulator,name=iPhone 15' -only-testing:MessagesExtensionTests/LobbyScreenModelBuilderTests -only-testing:MessagesExtensionTests/TranscriptTransportSupportTests -only-testing:MessagesExtensionTests/SetupInteractionResolverTests -only-testing:MessagesExtensionTests/GameShellProjectionBuilderTests -only-testing:MessagesExtensionTests/TranscriptStateSelectionTests -only-testing:MessagesExtensionTests/TransportBadgeModelTests -only-testing:MessagesExtensionTests/CompactStateTransportTests test
git diff --check
```

### Manual TestFlight Gate

Run these on real devices before treating the current build as externally testable:

1. 3-player lobby: host invites, one guest joins, host reopens latest bubble, second guest joins, host starts.
2. 4-player lobby: repeat with three joins in mixed order.
3. 3-4 player seven/discard: confirm only the next pending discarder can act and older bubbles cannot publish out of order.
4. 3-player trade: proposer targets two recipients; verify mixed `Decline`/`Counter` responses from stale/open shells.
5. Trade race probe: two recipients accept the same offer within a second; confirm the table converges and does not brick.
6. Full standard match on hardware from lobby through victory.

## Progress

- [x] Stage 13.1 — Per-Game Ledger and Active-Context Recovery
- [x] Stage 13.2 — Canonical Lobby and Responder-Flow Hardening
- [x] Stage 13.3 — Transport Reliability Program
- [x] Stage 13.4 — Multi-Game and Release-Readiness Surfaces
- [x] Stage 13.5 — Tail Gameplay Hardening and TestFlight Prep

## Key Discoveries

- `MSMessage.url` must use `http` or `https`; earlier custom-scheme behavior was a contract bug, not an undocumented quirk.
- `selectedMessage` is not a live-updating pointer to the latest session bubble.
- The host-side first join after invite send is better treated as a selected-bubble reopen flow than a live-updating wait flow.
- Responder actions should publish canonical state directly whenever the rules allow it.
- Multi-player discard is safer as ordered canonical publication than as concurrent responder-envelope merge.

## Outcome

Phase 13 leaves the repo in a state where the next work should no longer be "more Messages substrate repair." The next work should be:

- targeted real-device TestFlight validation on the current build
- UI and trust-surface polish
- then structural decomposition and deeper regression coverage

That is a phase boundary, not just another patch inside the same phase.
