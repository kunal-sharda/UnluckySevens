# Phase 14 — UI Design, Bubble Polish, and Trust Surfaces

## Summary

Phase 14 starts by tightening the two most visible trust surfaces in the shipped flow:

- transcript bubble copy should read like a product message, not a transport/debug artifact
- key transcript bubbles should show polished presentation-only graphics so the thread reads like a game, not a log
- players should be able to set a custom display name during lobby setup instead of being locked to aliases
- the pre-TestFlight branch should stop carrying dev-only legacy transcript/runtime handling and shipped debug UI
- design iteration should have a DEBUG-only single-device fixture path so UI/UX audit work can cover lobby, setup, turn, forced-flow, trade, and game-over states without carrying two devices; the same path should support dummy-player local playthroughs, not only static screenshots

Success for this slice means fresh lobby/setup/turn bubbles use `Unlucky Sevens: <descriptive title>` plus a short human-readable summary, setup/turn/game-over state bubbles can carry concise action-card graphics, lobby-entered names persist through canonical state, transport round-trips, and the transition into gameplay, and the local player’s preferred lobby name prefills future invite/join flows on the same device.

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
- Setup, turn, and game-over state bubbles can include concise action-card graphics keyed by move type.
- The live board remains inside the expanded app; transcript bubbles should not attempt to thumbnail the full board state.
- A player can set or update their display name while in the lobby. Joiners may carry that name into their join publish, and joined players may update it later from the lobby.
- The local player's most recent lobby name is remembered on that device and prefills later invite/join drafts until the player changes it again.
- Gameplay surfaces prefer the custom name when present and fall back to deterministic aliases otherwise.
- DEBUG builds can open a compact UX Lab overlay that loads representative local fixtures and actor viewpoints for design audit without publishing Messages bubbles.
- UX Lab can drive a local dummy table by applying state-producing actions back into the preview state, switching the acting player without resetting the table, and optionally following the current turn owner after each local action.
- UX Lab can autoplay non-human dummy actors with a deliberately simple policy: join open dummy seats, place first legal setup pieces, roll, satisfy forced discard/robber steps, and end the dummy turn.

Code and docs result:

- `CoreGameStateV1` carries canonical per-player display names.
- Compact state transport round-trips the name map.
- A device-local preferred-name store prefills future lobby drafts without replacing canonical per-game state as shared truth.
- Lobby UI exposes a small name editor.
- Owner docs describe alias fallback plus custom-name precedence.
- QA docs describe the single-device UX Lab as a fast visual-audit and dummy-user playthrough lane, including autoplay limits, with real two-device Messages testing still required before release.

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
   - concise action-card graphics for start/setup/turn/game-over state bubbles
   - text-only fallback when image rendering is unavailable
11. Convert the generated packaging path to a standalone Messages-only app bundle before the first TestFlight boundary.
12. Add a DEBUG-only single-device UX Lab with fixture states for design iteration and a small overlay for switching state and local actor, including a dummy-user path that can play through local actions on one device.
13. Add an XCUITest design-slice harness that opens Messages, finds the Unlucky Sevens app drawer item, and captures simulator screenshots of the invite slice plus UX Lab overlay as XCTest attachments.
14. Reset the first invite surface away from a decorated form and toward a board-game rules/setup card metaphor:
   - table/game-box surface background
   - printed rule-card hierarchy
   - compact setup facts instead of generic chips
   - RSVP-style player-name line
   - single `Send Invite` action

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

Latest bubble-graphic validation:

- `bash ./scripts/gen.sh`
- `swift test --package-path Packages/ULS_Transport`
- `xcodebuild -workspace UnluckySevens.xcworkspace -scheme MessagesExtension -destination 'generic/platform=iOS Simulator' build`
- Focused simulator tests for `TranscriptTransportSupportTests`, `TranscriptBubbleCopyTests`, and `TranscriptBubbleImageRendererTests` should be run on a simulator-capable machine before external TestFlight handoff.

Latest standalone Messages packaging validation:

- Xcode template inspection confirmed standalone iMessage apps use `com.apple.product-type.application.messages`.
- Temporary generated-project spike confirmed the app bundle builds when the app target has no Swift sources and embeds `MessagesExtension.appex`.
- `bash ./scripts/gen.sh`
- `xcodebuild -workspace UnluckySevens.xcworkspace -scheme UnluckySevensApp -configuration Debug -destination 'generic/platform=iOS' -derivedDataPath DerivedData/MessagesOnlyValidation CODE_SIGNING_ALLOWED=NO build`
- `xcodebuild -workspace UnluckySevens.xcworkspace -scheme MessagesExtension -destination 'generic/platform=iOS Simulator' build`
- `git diff --check`

Latest extension icon validation:

- Xcode template inspection confirmed Messages extensions expect an extension-local `iMessage App Icon.stickersiconset`, not only the container app's `AppIcon.appiconset`.
- `bash ./scripts/gen.sh`
- `xcodebuild -workspace UnluckySevens.xcworkspace -scheme MessagesExtension -destination 'generic/platform=iOS Simulator' build`
- `xcodebuild -workspace UnluckySevens.xcworkspace -scheme UnluckySevensApp -configuration Debug -destination 'generic/platform=iOS' -derivedDataPath DerivedData/MessagesOnlyValidation CODE_SIGNING_ALLOWED=NO build`

Latest core validation hardening:

- Hidden Victory Point reveal gating now counts all hidden VP cards before deciding whether a reveal sequence can reach the winning goal, while each intent still reveals only one VP card.
- Lobby join and rename publishes now call `validateTransition` before sending canonical `STATE`, and core validation has an explicit audit-neutral lobby-to-lobby path for actor-authored join/rename transitions.
- `swift test --package-path Packages/ULS_CoreGame --filter TurnVictoryV1Tests`
- `swift test --package-path Packages/ULS_CoreGame --skip ULS_CoreGameEvals`
- `xcodebuild -workspace UnluckySevens.xcworkspace -scheme UnluckySevens-Workspace -destination 'platform=iOS Simulator,name=iPhone 15' -only-testing:MessagesExtensionTests/LobbyMembershipResolverTests test`
- `xcodebuild -workspace UnluckySevens.xcworkspace -scheme MessagesExtension -destination 'generic/platform=iOS Simulator' build`
- `git diff --check`
- `swift test --package-path Packages/ULS_CoreGame`

Latest single-device UX Lab validation:

- Lobby invite fixtures now expose dummy Maya/Theo actor options before they join, actor switching keeps the current local table instead of reloading the fixture, the `Follow turn owner` toggle can auto-switch the active lab actor after locally applied `STATE` publishes, and `Auto dummy turns` can advance every actor except the selected `You` actor through dummy joins, setup placements, rolls, forced discards/robber moves, and turn end.
- `bash ./scripts/gen.sh`
- `xcodebuild -workspace UnluckySevens.xcworkspace -scheme MessagesExtension -destination 'generic/platform=iOS Simulator' build`
- `xcodebuild -workspace UnluckySevens.xcworkspace -scheme UnluckySevens-Workspace -destination 'platform=iOS Simulator,name=iPhone 15' -only-testing:MessagesExtensionTests/UXTestingFixturesTests test`
- `git diff --check`

Latest XCUITest design-slice validation:

- `bash ./scripts/gen.sh`
- `xcodebuild -workspace UnluckySevens.xcworkspace -scheme UnluckySevens -destination 'platform=iOS Simulator,name=iPhone 15' -only-testing:UnluckySevensUITests/MessagesExtensionDesignSliceUITests/testOpenMessagesExtensionAndCaptureDesignSlices test`
- The UI test opened Messages, selected Unlucky Sevens from the app drawer, and attached screenshots for the invite slice and UX Lab panel to the test result bundle.
- On iOS 18.6 simulator, Messages exposed the drawer control as `Apps` instead of `add`; the harness now tries both labels and falls back to the visible bottom-left drawer coordinate.
- The in-app browser simulator mirror worked for showing the Simulator inside Codex, but it was heavier and occasionally reconnected during tap synthesis. Default design iteration should use the normal Simulator window, XCUITest harness captures, and `simctl` screenshots; keep the browser mirror as an explicit backup lane only.
- Repeated screenshot setup should be promoted into the XCUITest harness or DEBUG-only UX Lab automation controls. Computer Use remains a one-off fallback for surfaces the harness cannot reach yet, not the default capture path.

Latest invite-surface visual reset validation:

- The current first invite surface is an intermediate paper tabletop invite: title `A table is open`, setup chips for `Standard`, `3-4`, and `Async`, RSVP-style `Playing as` name field, and primary `Send Invite` CTA. The next design target is sharper: a board-game rules/setup card with printed facts instead of generic chips.
- The DEBUG-only rules button placement moves beside the invite badge so the UX Lab `Preview` control does not occlude it in design-slice screenshots; release/product placement keeps the rules affordance in the top-right of the invite card.
- The simulator rendered a stale installed extension after the first rebuild even though the derived build product contained the new strings. Explicitly installing `UnluckySevensApp.app` into the booted simulator and terminating `com.apple.MobileSMS` forced the design harness onto the fresh extension.
- `xcodebuild -workspace UnluckySevens.xcworkspace -scheme UnluckySevens-Workspace -destination 'platform=iOS Simulator,name=iPhone 15' -only-testing:MessagesExtensionTests/LobbyScreenModelBuilderTests test`
- `xcrun simctl install booted /Users/kunalsharda/Library/Developer/Xcode/DerivedData/UnluckySevens-gdscmhgchilzfjgbllclbkwyxdvz/Build/Products/Debug-iphonesimulator/UnluckySevensApp.app`
- `xcrun simctl terminate booted com.apple.MobileSMS`
- `xcodebuild -workspace UnluckySevens.xcworkspace -scheme UnluckySevens -destination 'platform=iOS Simulator,name=iPhone 15' -resultBundlePath Derived/UIHarness/uls-design-harness-invite-reset-20260605-clean.xcresult -only-testing:UnluckySevensUITests/MessagesExtensionDesignSliceUITests/testOpenMessagesExtensionAndCaptureDesignSlices test`

Latest board-scene visual spike validation:

- The live SpriteKit board scene can take the darker felt/deep-teal direction without replacing the SwiftUI shell. This spike is intentionally limited to the board palette, SpriteKit backdrop, SKView/snapshot background color, and city token silhouette.
- `xcodebuild -workspace UnluckySevens.xcworkspace -scheme UnluckySevens-Workspace -destination 'platform=iOS Simulator,name=iPhone 15' -only-testing:MessagesExtensionTests/GameBoardSceneTests test`
- `xcodebuild -workspace UnluckySevens.xcworkspace -scheme MessagesExtension -destination 'generic/platform=iOS Simulator' build`

Latest tabletop gameplay-surface validation:

- The expanded setup gameplay surface now uses a continuous tabletop direction: dark felt app background, compact command card, SpriteKit board with cream rim/deep-teal water, permanent board-game grid pieces, terrain texture marks, and a bottom tray with resource cards plus a dev deck stack.
- The implementation remains SwiftUI shell plus hosted SpriteKit board. UIKit is not needed for this visual iteration because the visible gap was composition, board rendering, and tray styling, not a framework limitation.
- UX Lab now has a DEBUG-only clean setup screenshot control that loads `setup-placement` and hides the UX Lab chrome before capture; the hidden restore affordance is accessibility-addressable as `uls.uxLab.restoreChrome`.
- The clean setup gameplay screenshot harness passed on the booted iPhone 16e simulator, found the `Clean setup screenshot` control, waited for `Place settlement`, and asserted the UX Lab toggle was absent before attachment.
- Manual simulator still: `/private/tmp/unluckysevens_tabletop_iteration_3.png`
- `xcodebuild -workspace /Users/kunalsharda/Documents/Code/UnluckySevens/UnluckySevens.xcworkspace -scheme UnluckySevens -destination id=C8ECCA82-D595-46D0-BC8E-258B27C16F18 build`
- `xcodebuild -workspace /Users/kunalsharda/Documents/Code/UnluckySevens/UnluckySevens.xcworkspace -scheme UnluckySevens -destination id=C8ECCA82-D595-46D0-BC8E-258B27C16F18 -only-testing:UnluckySevensUITests/MessagesExtensionDesignSliceUITests/testOpenMessagesExtensionAndCaptureDesignSlices test`
- `xcodebuild -workspace /Users/kunalsharda/Documents/Code/UnluckySevens/UnluckySevens.xcworkspace -scheme UnluckySevens -destination id=C8ECCA82-D595-46D0-BC8E-258B27C16F18 -only-testing:UnluckySevensUITests/MessagesExtensionDesignSliceUITests/testOpenMessagesExtensionAndCaptureCleanSetupGameplaySlice test`
- `xcrun simctl io booted screenshot /private/tmp/unluckysevens_tabletop_iteration_3.png`
- `xcrun simctl io booted screenshot /private/tmp/unluckysevens_clean_setup_no_debug.png`

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
- [x] Presentation-only lobby invite and action-card bubble graphics added with text-only fallback
- [x] Temporary generated `7` app icon added through the app asset catalog
- [x] Local generation/install path converted to a standalone Messages-only app bundle
- [x] Extension-local iMessage icon assets wired into the Messages extension target
- [x] Hidden multi-VP reveal gate fixed and covered
- [x] Lobby join/rename `STATE` transition validation restored below Messages publishing
- [x] DEBUG-only single-device UX Lab added for visual/design audit and one-device dummy-player playthroughs across representative states
- [x] XCUITest design-slice harness added for repeatable simulator capture of the Messages extension invite surface and UX Lab overlay
- [x] First invite surface reset from decorated form toward an initial tabletop paper-invite design language
- [ ] Refine the invite surface into a board-game rules/setup card design language
- [x] Simulator-first design iteration lane documented after validating the browser mirror as backup-only
- [x] Dark felt/deep-teal SpriteKit board-scene visual spike landed without a UIKit shell rewrite
- [x] First tabletop gameplay-surface pass landed across the SwiftUI shell, SpriteKit board, and lower hand/dev tray
- [x] Clean setup gameplay screenshot harness added so repeatable captures can hide DEBUG chrome without manual Computer Use

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
- Transcript bubble graphics are presentation-only. `MSMessage.url` remains the only decode surface, and failed image rendering intentionally falls back to the same caption/summary text bubble.
- Lobby join and lobby name-update publishes remain text-only so the transcript does not become visually noisy during roster edits.
- Full board thumbnails were intentionally replaced by per-action graphics because the board is too dense to read well inside an iMessage bubble.
- The installed Tuist `ProjectDescription.Product` enum exposes `.messagesExtension` but not a standalone messages application product. The repo now applies a narrow post-generation project patch to set `UnluckySevensApp` to `com.apple.product-type.application.messages` until Tuist can represent that product directly.
- A standalone Messages-only app target must remain resource-only. If host-app Swift sources are generated into `UnluckySevensApp`, Xcode tries to produce both the Messages app stub executable and a linked app executable and the build fails with duplicate outputs.
- The app-drawer icon comes from the Messages extension's own `iMessage App Icon.stickersiconset`. The container app's `AppIcon.appiconset` is not sufficient for the extension surface.
- Victory Point reveal affordances must count the player's full hidden VP inventory, not just one reveal, because the reducer intentionally reveals only one card per action and otherwise a player with multiple hidden VPs can be blocked from reaching a legal win.
- Canonical lobby join and rename publishes are core state transitions even though they do not append turn audit actions. Messages must validate them through `ULS_CoreGame.validateTransition` before send, with only append-actor join and actor-owned display-name rename allowed.
- The single-device UX Lab is a design aid only. It is DEBUG-gated, loads local fixture `STATE` directly, and routes UX-lab actions back into local state instead of sending `MSMessage`; two-device transcript, selection, and delivery behavior still require the real-device QA lane.
- The `lobby-invite` UX Lab fixture intentionally exposes dummy actor options before they are in the canonical roster so one device can simulate joiners, then continue through setup/gameplay by switching actor viewpoints.
- UX Lab dummy autoplay is intentionally a flow skipper, not a product AI. It avoids strategic build/trade/dev-card choices and only takes deterministic first-legal setup, roll, forced-flow, and end-turn actions for non-human actors.
- XCUITest sees SwiftUI-in-Messages leaf text and buttons more reliably than container-level identifiers. The design-slice harness therefore asserts on visible invite/lab text while still keeping accessibility identifiers on stable app controls for future expansion.
- The invite screen should not chase generic "cozy" styling by adding more rounded beige UI. The target direction is a rules/setup card from a board game box: printed hierarchy, functional facts, compact marks, and board-game materials. The current dark green table surface, ivory paper, charcoal ink, clay primary action, and small moss/slate/clay accents are an intermediate exploration, not the locked final style.
- Simulator design captures can show stale extension UI after a successful rebuild. Verify the installed simulator app's embedded extension or explicitly reinstall the latest app and terminate Messages before treating a screenshot as design evidence.
- The default visual-review loop is the native iOS Simulator, XCUITest for deterministic design-slice captures, and `simctl` screenshots for stills. The in-app browser mirror is useful when explicitly requested, but its memory/runtime overhead and reconnect behavior make it a backup, not the normal UI sprint path.
- Messages app drawer accessibility differs across simulator/runtime states; the harness should target visible labels such as `add` or `Apps` first, then use a narrow bottom-left coordinate fallback when those labels are unavailable.
- A darker, more physical board feel does not require replacing the whole shell with UIKit. The narrow board-scene path is feasible because `BoardSceneHostView` already hosts a dedicated `SKView`; palette, backdrop, and token-shape experiments can stay inside `MessagesExtension/Sources/Board/` while the surrounding shell remains SwiftUI.
- A fuller tabletop gameplay look also does not require an immediate UIKit rewrite. Keep SwiftUI for app chrome while it is mostly static layout and controls; keep SpriteKit responsible for the board, zoom, hit testing, and tactile board pieces. Reconsider a UIKit container only if SwiftUI starts blocking continuous animation, gesture arbitration, or precise Messages-host lifecycle behavior.
- Repeatable simulator screenshots should be harness-first: use XCUITest to navigate Messages and UX Lab controls, use `simctl` for still capture once the state is prepared, and reserve Computer Use for one-off gaps. If a Computer Use click sequence becomes repeatable, convert it into a test helper or DEBUG-only UX Lab automation control.

## Outcome

This transcript-copy, action-graphic bubble presentation, temporary app-icon, extension icon wiring, standalone Messages-only packaging, canonical lobby-naming, local preferred-name prefill, one-step trade-resolution cleanup, ordered-discard hardening, hidden-VP reveal hardening, lobby transition validation, single-device UX Lab with dummy-player playthrough and dummy-autoplay support, XCUITest design-slice capture harness, simulator-first design-review workflow, first invite tabletop visual reset, dark felt/deep-teal board-scene visual spike, first tabletop gameplay-surface pass, pre-TestFlight runtime/debug purge, repo cleanup, and basic feature audit slice is complete. Phase 14 remains active for broader UI/bubble polish beyond this slice.
