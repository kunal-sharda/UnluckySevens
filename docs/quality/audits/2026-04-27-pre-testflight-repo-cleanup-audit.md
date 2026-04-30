# 2026-04-27 Pre-TestFlight Repo Cleanup Audit

Scope: current repo cleanup and TestFlight-readiness audit after the explicit cutoff that games and bubbles created before the first TestFlight build do not need runtime compatibility.

## Compatibility Cutoff

- Pre-TestFlight games are disposable.
- Runtime compatibility starts at the first TestFlight build, not at old development transcripts.
- Historical docs under `docs/quality/audits/` can remain as evidence, but they must not be used as current readiness truth when they conflict with owner docs or active ExecPlans.

## Current Findings

### F1 — No live join/setup/current-player legacy transcript runtime found

Status: acceptable for TestFlight.

The current `EnvelopeV1` transport only carries canonical `STATE`, app-side `summaryText` payload fallback is removed, and old typed join/setup transport models are no longer present in live source. The remaining `summaryText` usage is presentation metadata and selection snapshots, not payload recovery.

Cleanup landed in this pass:

- deleted empty pre-TestFlight compatibility source/test stubs
- replaced stale `ULS STATE` test fixture copy with product-style bubble copy
- marked older compatibility audits as historical snapshots

### F2 — Transport action draft language removed

Status: fixed in follow-up cleanup.

`ULS_Transport.TurnIntentV1` and its transport resource/dev-card draft helpers were removed. Messages presentation now drafts `TurnActionDraft` values that carry a core reducer intent plus actor and state-anchor metadata, applies the core reducer, and publishes only canonical `STATE`.

### F3 — Balanced board default should be the first-beta path

Status: fixed in the current slice.

`noRedAdjacentV1` already existed and is tested. New Messages lobby driver instances now default to `noRedAdjacentV1` for new games, while `randomV1` remains protocol-supported for existing persisted state and focused tests.

Manual beta gate: on a newly started hardware game, confirm adjacent `6`/`8` number tokens do not appear.

### F4 — Compact controls needed basic accessibility polish

Status: fixed in the current slice.

The lower-rail pull-tab, shelf close chevron, trade close button, and pending-trade banner now have explicit accessibility labels. This is not a full accessibility audit, but it removes the most obvious icon-only control gap before external beta.

### F5 — Stale docs were the main remaining legacy surface

Status: partially fixed; keep archival discipline.

The 2026-04-16 feature matrix and 2026-04-19 legacy audit still contain valuable historical evidence, but they now carry supersession notes. Future cleanup should avoid rewriting historical audits wholesale; instead, add a dated supersession note and update owner docs.

### F6 — Still missing before widening beta: real-device evidence, not more legacy cleanup

Status: TestFlight gate.

The remaining high-risk gap is not a large known legacy runtime path. It is confidence on normal devices:

- full two-device lobby -> setup -> turn play
- seven/discard ordering on stale and latest bubbles
- targeted trade accept/decline/counter from responder devices
- setup/build highlighting responsiveness on iPhone and iPad
- transcript selection/reopen behavior after force-close

Use `docs/quality/qa.md` as the gate before sending to outside testers.

## Bottom Line

With the pre-TestFlight compatibility cutoff, the branch does not appear blocked by a major remaining legacy-support requirement. The next cleanup worth doing is structural: decompose `LobbyDriverViewModel` and deepen visual/host regression coverage after the first hardware gate.

## Validation

- `swift test --package-path Packages/ULS_Transport`
- `xcodebuild -workspace UnluckySevens.xcworkspace -scheme UnluckySevens-Workspace -destination 'platform=iOS Simulator,name=iPhone 15' -only-testing:MessagesExtensionTests/LobbyDriverViewModelIdentityTests -only-testing:MessagesExtensionTests/TranscriptTransportSupportTests -only-testing:MessagesExtensionTests/CompactStateTransportTests -only-testing:MessagesExtensionTests/TranscriptStateSelectionTests -only-testing:MessagesExtensionTests/GameBoardTargetTests test`
- `xcodebuild -workspace UnluckySevens.xcworkspace -scheme MessagesExtension -destination 'generic/platform=iOS Simulator' build`
- `git diff --check`
