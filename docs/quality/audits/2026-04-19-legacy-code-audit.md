# 2026-04-19 Legacy Code Audit

Supersession note: this is a historical audit snapshot. Phase 13/14 cleanup has since removed the pre-TestFlight runtime compatibility and debug surfaces called out below, and the release line now assumes games created before the first TestFlight build will be deleted. Use the current owner docs plus [2026-04-27 Pre-TestFlight Repo Cleanup Audit](./2026-04-27-pre-testflight-repo-cleanup-audit.md) for current readiness decisions.

## Scope

Audit the repo for code that is still carrying legacy behavior, transitional compatibility, or dormant debug/operator surfaces after the phase-13 transport/session overhaul.

This audit focused on:

- `MessagesExtension`
- `Packages/ULS_Transport`
- the active owner docs that define or justify legacy behavior

## Executive Summary

The codebase is **not** dominated by dead code. Most of the remaining legacy surface falls into three buckets:

1. **Backward transcript compatibility that is still intentionally live**
2. **Dormant debug/operator tooling that is compiled in but gated off**
3. **A smaller set of live fallback/product surfaces that should be cleaned up**

The most important conclusion is:

- the highest-priority cleanup is **not** the old debug panel
- it is the **remaining live product logic** that still depends on pre-phase-13 concepts like pending join overlays and manual responder application

## Update

Later on 2026-04-19, the main cleanup slice in phase 13 removed the three highest-priority live product tails identified here:

1. lobby `pendingJoiners` are no longer used for real participant rendering or `Start Game` gating
2. the discard panel no longer exposes manual `Apply Selected Response`
3. the misleading non-join/non-trade `*IntentDebug` surface and `cachedPublishedState` naming were cleaned up

What remains intentionally live after that cleanup:

- transcript compatibility for older join/setup/turn bubbles
- summary-fallback decode for older messages
- the preserved lobby join and trade debug stack

The detailed findings below are preserved as historical evidence for what was cleaned up and why. Treat the `Update` section above as the current truth for the resolved items.

## Highest-Priority Findings

### F1. Lobby membership is still not purely canonical state

Severity:

- high

Why this still matters:

- Fresh join publication is canonical lobby `STATE`, but the lobby UI and start gating still incorporate `pendingJoiners` / `observedJoiners` as a second truth source.
- That means the product model is still partially compensating for missing host-side surfacing instead of relying only on the latest canonical lobby state.

Evidence:

- `LobbyMembershipResolver.canJoin`, `canStart`, and `finalRoster` still merge `pendingJoiners` into lobby truth:
  - [MessagesExtension/Sources/Presentation/LobbyMembershipResolver.swift](../../../MessagesExtension/Sources/Presentation/LobbyMembershipResolver.swift)
- `LobbyScreenModelBuilder` still shows `state.roster + pendingJoiners` in the real lobby shell:
  - [MessagesExtension/Sources/Presentation/LobbyScreenModelBuilder.swift](../../../MessagesExtension/Sources/Presentation/LobbyScreenModelBuilder.swift)
- `TranscriptGameLedgerStore.recordJoin` persists `observedJoiners` separately from canonical state:
  - [MessagesExtension/Sources/Presentation/TranscriptGameLedger.swift](../../../MessagesExtension/Sources/Presentation/TranscriptGameLedger.swift)
- `LobbyDriverViewModel.currentPendingJoiners()` and `rememberPendingJoiner(...)` still wire that overlay into the runtime:
  - [MessagesExtension/Sources/Features/Lobby/LobbyDriverViewModel.swift](../../../MessagesExtension/Sources/Features/Lobby/LobbyDriverViewModel.swift)

Assessment:

- This is real legacy behavior, not harmless debug residue.
- It should be treated as an active architecture tail from the old join-intent model.

Recommended cleanup:

1. Make canonical lobby `STATE` the sole source of lobby roster truth.
2. Keep `observedJoiners` only as a short-lived recovery aid, not as `canStart` / visible-participant input.
3. Remove `pendingJoiners` from the real lobby model once host-side join recovery is judged acceptable.

### F2. The product discard flow still exposes a manual “Apply Selected Response” path

Severity:

- high

Why this still matters:

- The discard panel in the real game shell can still present a manual responder-application action.
- That contradicts the current decision that responder-side trade/discard transport should stay internal and that the product should prefer recovered canonical state over making the player manage raw response bubbles.

Evidence:

- `GameDiscardPanelModel.Action` still includes `.applySelectedDiscard(...)`:
  - [MessagesExtension/Sources/Presentation/GameDiscardPanelModel.swift](../../../MessagesExtension/Sources/Presentation/GameDiscardPanelModel.swift)
- `GameDiscardPanelModelBuilder` emits that action when the current player has a surfaced discard response selected:
  - [MessagesExtension/Sources/Presentation/GameDiscardPanelModelBuilder.swift](../../../MessagesExtension/Sources/Presentation/GameDiscardPanelModelBuilder.swift)
- `GameModalHostView` renders that as `Apply Selected Response`:
  - [MessagesExtension/Sources/Components/GameModalHostView.swift](../../../MessagesExtension/Sources/Components/GameModalHostView.swift)
- `GameShellView` wires it to `publishSelectedTurnIntentState()`:
  - [MessagesExtension/Sources/Features/Game/GameShellView.swift](../../../MessagesExtension/Sources/Features/Game/GameShellView.swift)

Assessment:

- This is a live product fallback surface, not just compatibility code.
- It should be removed or hidden behind an explicit debug-only path once discard auto-apply/recovery is considered the intended model.

Recommended cleanup:

1. Remove `.applySelectedDiscard(...)` from the product discard panel.
2. Leave manual responder application only in a debug/operator surface if it still has diagnostic value.
3. Treat any need for this path during normal play as a host-delivery defect, not normal UX.

### F3. Real product logic still depends on APIs named as debug/legacy intent helpers

Severity:

- medium

Why this still matters:

- A large part of the current real gameplay shell now publishes canonical `STATE` directly.
- But the view-model surface still routes capability and mode checks through names like `canSendRollDiceIntentDebug`, `canSendBuildRoadIntentDebug`, and related legacy terminology.
- That naming mismatch makes the architecture harder to reason about and keeps the code feeling more legacy than it actually is.

Evidence:

- `shellActionAvailability` and `shellModeAvailability` use `canSend*IntentDebug` properties even for real shell actions:
  - [MessagesExtension/Sources/Features/Lobby/LobbyDriverViewModel.swift](../../../MessagesExtension/Sources/Features/Lobby/LobbyDriverViewModel.swift)
- Real gameplay paths already use canonical publication helpers such as:
  - `publishSetupState(...)`
  - `publishTurnState(...)`
  - `publishTradeOffer(...)`
  - `publishMaritimeTrade(...)`
  - `publishDevCardDraft(...)`

Assessment:

- This is primarily naming and API-shape debt.
- It is not the most urgent runtime risk, but it is a major source of confusion during debugging and design discussions.

Recommended cleanup:

1. Rename `canSend*IntentDebug` capability helpers to neutral gameplay terms.
2. Rename any remaining “intent” wording in direct current-player paths to reflect canonical state publication.
3. Keep `legacy` in names only where the code is genuinely transcript-compatibility-only.

## Compatibility Code That Is Still Intentionally Live

These surfaces are legacy, but they are not obviously safe to delete yet because the iMessage thread is still the storage model and older bubbles can still be selected.

### C1. Legacy join/setup/current-player intent decode

What remains:

- `JoinIntentV1`
- `SetupPlacementIntentV1`
- legacy current-player turn-intent rendering and recovery
- legacy join/setup/current-player fallback shells

Evidence:

- Transport models:
  - [Packages/ULS_Transport/Sources/ULS_Transport/JoinIntentV1.swift](../../../Packages/ULS_Transport/Sources/ULS_Transport/JoinIntentV1.swift)
  - [Packages/ULS_Transport/Sources/ULS_Transport/SetupPlacementIntentV1.swift](../../../Packages/ULS_Transport/Sources/ULS_Transport/SetupPlacementIntentV1.swift)
- Decode/render path:
  - [MessagesExtension/Sources/Features/Lobby/LobbyDriverViewModel.swift](../../../MessagesExtension/Sources/Features/Lobby/LobbyDriverViewModel.swift)
- Legacy shell projections:
  - [MessagesExtension/Sources/Presentation/GameShellProjection.swift](../../../MessagesExtension/Sources/Presentation/GameShellProjection.swift)
- Recovery helpers:
  - [MessagesExtension/Sources/Presentation/JoinIntentContextResolver.swift](../../../MessagesExtension/Sources/Presentation/JoinIntentContextResolver.swift)
  - [MessagesExtension/Sources/Presentation/TurnIntentTransportRoleResolver.swift](../../../MessagesExtension/Sources/Presentation/TurnIntentTransportRoleResolver.swift)

Assessment:

- This is intentional compatibility code.
- Removing it without an explicit transcript-compatibility cutoff would risk breaking recovery of older real-thread bubbles.

### C2. Summary-fallback decode and legacy envelope decode

What remains:

- incoming `summaryText` mirrored-payload fallback decode
- decode support for the older JSON-wrapped envelope format in the transport codec

Evidence:

- `TranscriptPayloadSource.summaryFallback` and decode fallback:
  - [MessagesExtension/Sources/Presentation/TranscriptTransportSupport.swift](../../../MessagesExtension/Sources/Presentation/TranscriptTransportSupport.swift)
- compact codec still decodes old JSON envelopes when payload bytes begin with `{`:
  - [Packages/ULS_Transport/Sources/ULS_Transport/EnvelopeV1Codec.swift](../../../Packages/ULS_Transport/Sources/ULS_Transport/EnvelopeV1Codec.swift)

Assessment:

- This is still phase-13 compatibility, not accidental residue.
- The docs already treat it as intentional temporary compatibility.
- It should only be removed after an explicit cutoff decision for pre-`https` bubbles and old envelope payloads.

### C3. Cached published-state naming still reflects the older model

What remains:

- `cachedPublishedState`
- `.cachedPublishedState` source labels in context recovery

Evidence:

- [MessagesExtension/Sources/Presentation/TurnIntentContextResolver.swift](../../../MessagesExtension/Sources/Presentation/TurnIntentContextResolver.swift)
- [MessagesExtension/Sources/Features/Lobby/LobbyDriverViewModel.swift](../../../MessagesExtension/Sources/Features/Lobby/LobbyDriverViewModel.swift)

Assessment:

- The underlying functionality is still useful as local ledger recovery.
- The problem is mostly stale naming: the repo is no longer centered on one global “cached published state,” but the names still imply that older architecture.

Recommended cleanup:

1. Rename this to explicit local-ledger terminology.
2. Keep behavior unless a better recovery path replaces it.

## Dormant Debug / Operator Surfaces

These are legacy or temporary tools, but most are already gated off in the normal shell.

### D1. Full debug panel stack is compiled in but dormant

Evidence:

- debug panel entry:
  - [MessagesExtension/Sources/Debug/DebugPanelView.swift](../../../MessagesExtension/Sources/Debug/DebugPanelView.swift)
- large driver surface:
  - [MessagesExtension/Sources/Features/Lobby/LobbyDriverView.swift](../../../MessagesExtension/Sources/Features/Lobby/LobbyDriverView.swift)
- debug HUD / temporary overlay:
  - [MessagesExtension/Sources/Debug/DebugHUDView.swift](../../../MessagesExtension/Sources/Debug/DebugHUDView.swift)
  - [MessagesExtension/Sources/App/TemporaryDiagnosticsOverlayView.swift](../../../MessagesExtension/Sources/App/TemporaryDiagnosticsOverlayView.swift)
- diagnostics config is off:
  - [MessagesExtension/Sources/Presentation/TemporaryDiagnosticsConfig.swift](../../../MessagesExtension/Sources/Presentation/TemporaryDiagnosticsConfig.swift)

Assessment:

- This is low runtime risk because `TemporaryDiagnosticsConfig.live.isEnabled` is currently `false`.
- It is still maintenance weight and review noise.

Scope note:

- `LobbyDriverViewModel` still carries a large number of debug-only published fields because of this dormant panel.

### D2. Legacy sender buttons remain in the driver view model

Evidence:

- `LobbyDriverViewModel` still contains **21** `send*IntentDebug` methods for legacy setup/turn publication experiments:
  - [MessagesExtension/Sources/Features/Lobby/LobbyDriverViewModel.swift](../../../MessagesExtension/Sources/Features/Lobby/LobbyDriverViewModel.swift)

Assessment:

- These are clear candidates to move behind a smaller operator-only seam or delete once transcript-compatibility investigation is done.
- They are not the main product risk because they are not the normal player path.

## Tests That Still Anchor Legacy Behavior

Legacy cleanup is not a single-file delete. The repo currently has focused tests that intentionally preserve these compatibility surfaces.

Examples:

- `JoinIntentContextResolverTests`
- `GameShellProjectionBuilderTests`
- `GameDiscardPanelModelBuilderTests`
- `TranscriptTransportSupportTests`
- `TurnIntentTransportRoleResolverTests`
- `TranscriptStateSelectionTests`
- `EnvelopeV1TransportTests`

Assessment:

- Legacy removal will require deliberate test pruning and spec updates, not just code deletion.

## Recommended Cleanup Sequence

### 1. Remove live product fallback behavior first

Priority:

- highest

Targets:

- discard `Apply Selected Response`
- lobby `pendingJoiners` as real participant/start gating input

Reason:

- These are the remaining legacy behaviors that players can still feel directly.

### 2. Rename the transitional API surface

Priority:

- high

Targets:

- `canSend*IntentDebug`
- `cachedPublishedState`
- any current-player canonical-state helper still named as if it were debug or generic intent transport

Reason:

- This reduces architectural confusion without risking transcript compatibility.

### 3. Collapse or remove dormant debug/operator surfaces

Priority:

- medium

Targets:

- `LobbyDriverView`
- `DebugHUDView`
- `DebugPanelView`
- temporary overlay badge plumbing
- `useSingleSessionDebug`

Reason:

- Low product impact, but a meaningful simplification once active Messages-host debugging is done.

### 4. Only then retire transcript compatibility layers

Priority:

- gated / explicit decision required

Targets:

- `JoinIntentV1`
- `SetupPlacementIntentV1`
- legacy turn-intent fallback shells
- summary fallback decode
- old JSON-envelope decode

Reason:

- The repo still treats the thread as storage. Removing these is a product-compatibility decision, not a casual cleanup.

## Bottom Line

The remaining legacy code is best described as:

- **some real product debt that should be cleaned up soon**
- **a larger amount of intentional transcript compatibility**
- **a dormant debug stack that is mostly safe but noisy**

The first cleanup slice should target:

1. lobby `pendingJoiners` as product truth
2. discard `Apply Selected Response`
3. misleading `*IntentDebug` / `cachedPublishedState` naming

That gives the repo the biggest simplification without breaking old transcript recovery.
