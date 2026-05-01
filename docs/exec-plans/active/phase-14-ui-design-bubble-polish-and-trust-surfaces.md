# Phase 14 — UI Design, Bubble Polish, and Trust Surfaces

## Summary

Phase 14 starts by tightening the two most visible trust surfaces in the shipped flow:

- transcript bubble copy should read like a product message, not a transport/debug artifact
- key transcript bubbles should show presentation-only snapshots so the thread reads like a game, not a log
- players should be able to set a custom display name during lobby setup instead of being locked to aliases
- the pre-TestFlight branch should stop carrying dev-only legacy transcript/runtime handling and shipped debug UI

Success for this slice means fresh lobby/setup/turn bubbles use `Unlucky Sevens: <descriptive title>` plus a short human-readable summary, setup/turn/game-over state bubbles can carry board-backed presentation snapshots, lobby-entered names persist through canonical state, transport round-trips, and the transition into gameplay, and the local player’s preferred lobby name prefills future invite/join flows on the same device.

## Starting State

At the start of this slice:

- Canonical gameplay and lobby flows are stable after phase 13, but transcript bubbles still use debug-style revision captions.
- `message.summaryText` is still derived from terse transport diagnostics.
- Player-facing shell naming still relies entirely on deterministic per-game aliases. There is no product path for a player to set a preferred name during the lobby.
- Because naming does not live in canonical state, a UI-only rename would break on reopen, device handoff, and lobby-to-game transition.
- Even after canonical lobby naming landed, the same player would still have to retype the same name on every future game unless the extension remembered a local preferred draft value.
- The repo still carried pre-TestFlight legacy transcript recovery code and internal diagnostics surfaces that would become compatibility debt if left in the shipped branch.

## Assumptions and Evidence Gate

This slice does not depend on a new unstable Apple contract. It builds on the already-verified phase-13 transport contract:

- `MSMessage.url` remains the only canonical payload carrier.
- Bubble copy is presentation metadata only (`MSMessageTemplateLayout.caption`, `MSMessage.summaryText`) and does not affect payload delivery.
- Bubble images are presentation metadata only (`MSMessageTemplateLayout.image`) and must fail soft to text-only publication.
- Canonical player naming must live inside `CoreGameStateV1` and compact state transport to survive transcript round-trips.

Disproof test:

- If compact transport or transition validation drops renamed players on reopen or on lobby-to-setup start, the state/transport patch is incomplete and the slice is not acceptable.

Fallback:

- None. If canonical name persistence fails, the feature must not ship as a local-only field.

## Target End State

User-visible result:

- Lobby, setup, and gameplay transcript bubbles use product copy with a stable `Unlucky Sevens:` prefix and short summaries that describe the most recent move or phase change.
- The first lobby invite can include a deterministic programmatic Unlucky Sevens invite graphic; later join/name-update lobby bubbles stay text-only.
- Setup, turn, and game-over state bubbles can include a board snapshot with a concise status band that mirrors the bubble copy.
- A player can set or update their display name while in the lobby. Joiners may carry that name into their join publish, and joined players may update it later from the lobby.
- The local player's most recent lobby name is remembered on that device and prefills later invite/join drafts until the player changes it again.
- Gameplay surfaces prefer the custom name when present and fall back to deterministic aliases otherwise.

Code and docs result:

- `CoreGameStateV1` carries canonical per-player display names.
- Compact state transport round-trips the name map.
- A device-local preferred-name store prefills future lobby drafts without replacing canonical per-game state as shared truth.
- Lobby UI exposes a small name editor.
- Owner docs describe alias fallback plus custom-name precedence.

Acceptance boundary:

- Name changes survive join/start/reopen/device handoff.
- Preferred-name prefill survives opening a new lobby on the same device.
- Bubble copy no longer exposes debug revision text in fresh product flows.
- Bubble image rendering never blocks gameplay publication; payload decode remains URL-only.

## Implementation Plan

1. Extend canonical state and compact transport with normalized `playerDisplayNamesByPlayer`.
2. Preserve the new field across all reducer/state-construction paths and reject non-lobby name mutations during validated gameplay transitions.
3. Add lobby rename authoring:
   - join publish may include the local player name
   - joined players may publish a lobby rename update
4. Update display-name resolution across lobby/game/recovery builders to prefer canonical names before alias fallback.
5. Add same-device preferred-name persistence so fresh invite/join drafts prefill from local defaults unless canonical lobby state already provides the local player name.
6. Replace debug transcript copy with descriptive bubble copy for:
   - invite
   - join
   - lobby rename
   - start
   - setup publishes
   - turn publishes
7. Add focused tests and update owner docs.
8. Remove pre-TestFlight-only legacy transport/runtime handling and delete shipped debug UI/diagnostics surfaces before the TestFlight boundary hardens.
9. Audit small pre-TestFlight feature polish candidates after the runtime cleanup:
   - forced-discard ordering below the UI
   - balanced-board defaults
   - board highlighting feel
   - compact control accessibility labels
10. Add presentation-only transcript bubble images:
   - branded programmatic lobby invite graphic for the first invite bubble
   - board snapshot plus status band for start/setup/turn/game-over state bubbles
   - text-only fallback when snapshot rendering is unavailable

## Validation

Automated:

- `swift test --package-path Packages/ULS_CoreGame --skip ULS_CoreGameEvals`
- `swift test --package-path Packages/ULS_Transport`
- `xcodebuild -workspace UnluckySevens.xcworkspace -scheme MessagesExtension -destination 'generic/platform=iOS Simulator' build`
- Focused `MessagesExtensionTests` for compact transport, lobby model building, name resolution, preferred-name persistence, and transcript copy
- `swift test --package-path Packages/ULS_Transport`
- Focused `MessagesExtensionTests` for transcript transport support and lobby model coverage after the hard runtime/debug purge

Manual:

- Host invite -> reopen bubble -> rename host -> guest joins with custom name -> host starts -> names persist into gameplay.
- Close the extension, start a fresh lobby on the same device, and verify the local player name field prefills from the previously used preferred name before any new publish.
- Verify fresh transcript bubbles show descriptive product copy instead of revision/debug text.

Latest cleanup-pass validation:

- `swift test --package-path Packages/ULS_Transport`
- `xcodebuild -workspace UnluckySevens.xcworkspace -scheme UnluckySevens-Workspace -destination 'platform=iOS Simulator,name=iPhone 15' -only-testing:MessagesExtensionTests/LobbyDriverViewModelIdentityTests -only-testing:MessagesExtensionTests/TranscriptTransportSupportTests -only-testing:MessagesExtensionTests/CompactStateTransportTests -only-testing:MessagesExtensionTests/TranscriptStateSelectionTests -only-testing:MessagesExtensionTests/GameBoardTargetTests test`
- `xcodebuild -workspace UnluckySevens.xcworkspace -scheme MessagesExtension -destination 'generic/platform=iOS Simulator' build`
- `git diff --check`

Latest transport-draft cleanup validation:

- `swift test --package-path Packages/ULS_Transport`
- `tuist generate`
- `xcodebuild -workspace UnluckySevens.xcworkspace -scheme UnluckySevens-Workspace -destination 'platform=iOS Simulator,name=iPhone 15' -only-testing:MessagesExtensionTests/TurnInteractionResolverTests -only-testing:MessagesExtensionTests/TradeInteractionResolverTests -only-testing:MessagesExtensionTests/TradeResponsePublicationResolverTests -only-testing:MessagesExtensionTests/DevCardInteractionResolverTests -only-testing:MessagesExtensionTests/TranscriptBubbleCopyTests -only-testing:MessagesExtensionTests/TranscriptTransportSupportTests -only-testing:MessagesExtensionTests/CompactStateTransportTests test`
- `xcodebuild -workspace UnluckySevens.xcworkspace -scheme MessagesExtension -destination 'generic/platform=iOS Simulator' build`
- `git diff --check`

Latest bubble-snapshot validation:

- `bash ./scripts/gen.sh`
- `swift test --package-path Packages/ULS_Transport`
- `xcodebuild -workspace UnluckySevens.xcworkspace -scheme MessagesExtension -destination 'generic/platform=iOS Simulator' build`
- Focused simulator tests for `TranscriptTransportSupportTests`, `TranscriptBubbleCopyTests`, and `TranscriptBubbleImageRendererTests` should be run on a simulator-capable machine before external TestFlight handoff.

## Progress

- [x] Canonical name state/transport landed
- [x] Lobby rename UI and publish path landed
- [x] Same-device preferred-name draft persistence landed
- [x] Descriptive transcript copy landed
- [x] Pre-TestFlight legacy transcript/runtime handling retired
- [x] Shipped debug UI and gesture/transport diagnostics surfaces removed
- [x] Docs and validation updated
- [x] Core ordered forced-discard invariant enforced below the UI
- [x] Pre-TestFlight basic feature audit recorded
- [x] Follow-up repo cleanup pass recorded with the explicit no-pre-TestFlight-compatibility cutoff
- [x] Stale phase 12/13 ExecPlans moved out of `active/`
- [x] Audit index added so historical audits no longer compete with owner docs
- [x] ExecPlan rules moved into `docs/exec-plans/PLANS.md`
- [x] README, AGENTS, and ExecPlan rules docs tightened into separate reference roles
- [x] Changelog moved into `docs/exec-plans/CHANGELOG.md` as compact phase history
- [x] AGENTS.md now explicitly includes itself in kept-current docs and requires a doc-freshness pass before completion
- [x] Transport-layer turn draft DTO removed; Messages now drafts core turn actions through `TurnActionDraft`
- [x] Obsolete summary-payload mirror residue removed from transcript message metadata
- [x] Presentation-only lobby invite and board/status bubble snapshots added with text-only fallback

## Decisions and Discoveries

- Lobby display names must live in canonical state, not just local UI state, or they disappear on reopen, transport round-trip, and lobby-to-game transition.
- Device-local preferred-name persistence is convenience only. Shared truth still lives in canonical state and must only change when the player publishes host/join/rename state for that table.
- Bubble copy belongs in `MSMessageTemplateLayout.caption` / `summaryText` only. Payload truth remains `MSMessage.url`.
- Canonical metadata changes require golden-hash test refreshes in `ULS_CoreGame`; this slice changed one fixed-state hash expectation because display names are now part of the canonical hash surface.
- Pre-TestFlight is the right boundary to delete dev-era transcript compatibility and visible debug surfaces. After TestFlight, whatever ships becomes real compatibility debt.
- Trade resolution is now one canonical action: targeted `acceptTrade` atomically transfers resources and closes the offer. The older separate `executeTrade` intent, audit action, transport constructor, and compatibility test were removed before the TestFlight boundary.
- Forced-discard ordering must be a core invariant, not just a Messages-shell affordance. The reducer and transition validator now reject out-of-order `submitDiscard` transitions.
- The pre-TestFlight feature audit found no missing basic board-highlighting feature, but selected-target changes still rebuild the full overlay layer. Treat that as hardware-polish risk rather than a correctness blocker.
- Balanced-board generation already exists through `noRedAdjacentV1`, and new TestFlight games now default to that safer generator instead of plain `randomV1`.
- Pre-TestFlight games and bubbles are disposable for this release line. Runtime compatibility must start at the TestFlight build boundary, so stale dev-era support stubs should be deleted instead of preserved as compatibility affordances.
- Turn actions are no longer authored as `ULS_Transport` payloads internally. Messages uses `TurnActionDraft` for actor/anchor metadata and core `TurnIntentV1` for reducer semantics, then publishes canonical `STATE`.
- `randomV1` remains protocol-supported for already-persisted state and focused tests, but it is no longer the default first-beta product path.
- Only phase 14 should remain in `docs/exec-plans/active/`; phase 12 and phase 13 are now completed/historical records.
- Transcript bubble snapshots are presentation-only. `MSMessage.url` remains the only decode surface, and failed image rendering intentionally falls back to the same caption/summary text bubble.
- Lobby join and lobby name-update publishes remain text-only so the transcript does not become visually noisy during roster edits.

## Outcome

This transcript-copy, snapshot-backed bubble presentation, canonical lobby-naming, local preferred-name prefill, one-step trade-resolution cleanup, ordered-discard hardening, pre-TestFlight runtime/debug purge, repo cleanup, and basic feature audit slice is complete. Phase 14 remains active for broader UI/bubble polish beyond this slice.
