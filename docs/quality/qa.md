# QA

This is a living document. Update it whenever UI scope, Messages behavior, validation lanes, or device expectations change. Do not rely on chat memory for what needs to be tested.

## Practical Gate

These commands should stay green for the current MVP engine baseline:

```bash
bash ./scripts/gen.sh
swift test --package-path Packages/ULS_CoreGame --skip ULS_CoreGameEvals
swift test --package-path Packages/ULS_CoreGame --filter ULS_CoreGameEvals
swift test --package-path Packages/ULS_Transport
xcodebuild -workspace UnluckySevens.xcworkspace -scheme MessagesExtension -destination 'generic/platform=iOS Simulator' build
xcodebuild -workspace UnluckySevens.xcworkspace -scheme UnluckySevens-Workspace -destination 'platform=iOS Simulator,name=iPhone 15' test
```

GitHub Actions mirrors this practical gate in `.github/workflows/ci.yml`.

`ULS_CoreGameEvals` is the deterministic engine eval harness. `ULS_CoreGameTests` remains the normal core test suite.

Run these validation commands serially. Do not run `swift test` or `xcodebuild` in parallel on this repo; the Messages/simulator lane is prone to lock contention and misleading failures when multiple test or build processes overlap.

## When To Run What

- Any `ULS_CoreGame` or `ULS_Transport` change:
  - run the full Practical Gate
- Any `MessagesExtension` shell, layout, presentation, or mode-system change:
  - run the full Practical Gate
  - run the Manual Simulator Runbook smoke pass
  - run the Real Device Shell Smoke checklist
- Any lobby join/start UX change:
  - run the full Practical Gate
  - run the Manual Simulator Runbook smoke pass
  - run the Real Device Lobby Smoke checklist
- Any transcript-selection, bubble, session, or context-handling change:
  - run the full Practical Gate
  - include focused `MessagesExtensionTests` coverage for transcript transport, bubble copy, and snapshot renderers when bubble presentation changes
  - run the Manual Simulator Runbook context check
  - run the Real Device Messages Lifecycle checklist
- Any same-bubble recovery, board responsiveness, or setup-road interaction change:
  - run the full Practical Gate
  - run the Manual Simulator Runbook smoke pass
  - run the Real Device Messages Lifecycle checklist
  - run the Real Device Turn-Taking Smoke checklist
  - run the Real Device UX Hardening checklist
- Any shell-header, action-dock, player-name, bank-tray, or dev-card timing/change-flow update:
  - run the full Practical Gate
  - run the Manual Simulator Runbook smoke pass
  - run the Real Device Turn-Taking Smoke checklist
  - run the Real Device Gameplay Cohesion checklist
- Any new gameplay flow in the product UI:
  - run the full Practical Gate
  - run the relevant targeted simulator check
  - run the relevant real-device gameplay checklist before calling the flow ready
- Before a phase is declared UI-ready:
  - run the full Practical Gate
  - run at least one full two-device smoke pass end to end

## Lessons

This is the running list for durable implementation lessons that should survive the current phase.

Use this section for repo knowledge that was learned the hard way and should influence future work even after the active ExecPlan is archived. ExecPlans can still record phase-local rationale and chronology, but once a lesson becomes durable, normalize it here.

### iMessage Host and Shell

These are the main iMessage-specific complexities we have already paid for in this repo. Treat them as working constraints, not trivia. If a future change touches any of these surfaces, reread this section before changing the code.

### Gameplay Flow Fidelity

These are the durable gameplay-UX rules learned while hardening the product shell against shortcut-heavy debug-era behavior.

### 0. Forced and resource-choice flows must be explicit, not generated defaults

What went wrong:

- The shell originally used shortcut behavior for some legal-but-important actions: discard could fall back to a generated default payload, and other flows blurred the line between acceptable enumerated quick actions and required explicit player choice.
- Those shortcuts were mechanically legal in some cases, but they weakened the base-Catan product contract because the player was no longer choosing the exact cards/resources involved in a rules-significant action.

What we learned:

- If the tabletop rule asks the player to choose exact resources, the product shell should expose that choice directly.
- Quick lists are acceptable only when the legal option set is already fully enumerated by the rules and no extra player choice is being hidden. Maritime / bank trade fits that category; discard and player-to-player trade composition do not.

Current repo answer:

- Discard is now an explicit selection flow: the acting player chooses the exact cards to discard and the submit action stays disabled until the required count is selected.
- Maritime trade is represented as a legal quick-trade list because the engine can enumerate the complete valid option set from the current hand and port access without hiding additional player choice.
- Future gameplay UX should follow this split: explicit selection when the player is choosing exact resources, quick lists only when the legal outcomes are already fully enumerated by the rules.

### 1. `MSMessage.url` must be `http` or `https`; custom schemes are stripped on the wire

What went wrong:

- The main transport (`TranscriptTransportSupport.buildMessage`) and a temporary standalone diagnostic probe both built `MSMessage.url` using custom schemes (`unluckysevens://msg?...`, `probeurl://msg?...`).
- On send, iMessage accepted the `MSMessage` locally and the bubble rendered with its caption/summary intact, but the `url` did not arrive on the recipient's `didSelect`/`didReceive` — or it arrived and was dropped on first reopen.
- For a long stretch of phase-12/phase-13 this looked like a transcript-selection reliability problem, because the *symptom* (URL missing on reopen) lined up with known Messages quirks around `selectedMessage` hydration. The real cause was that a `probeurl://` or `unluckysevens://` URL was never going to round-trip through iMessage at all — the platform validates `MSMessage.url` against the `http`/`https` contract and silently drops non-compliant values.

What we learned:

- `MSMessage.url` is not a generic opaque payload slot. Apple's contract says it must be an `http` or `https` URL, and iMessage enforces that contract by dropping non-conforming URLs somewhere between `activeConversation.insert(_:)` and the recipient. Locally on the sender, `message.url` still reads back fine; that is not proof that the URL was transmitted.
- GamePigeon, Word Hunt, GameClub titles, and similar iMessage games all use real `https://<gamehost>/...?state=<base64>` URLs for exactly this reason. There is no second hidden channel — the URL *is* the transport, but only when the scheme is valid.
- "URL shows up on sender, missing on recipient/reopen" is a scheme bug signal before it is a transcript-selection signal. Check the scheme before blaming lifecycle timing.

Current repo answer:

- Main transport builds `https://unluckysevens.app/msg?payload=<encodedEnvelope>` (`MessagesExtension/Sources/Presentation/TranscriptTransportSupport.swift`). The host does not need to resolve; it only has to pass the scheme check.
- A temporary standalone diagnostic probe was also switched to `https://unluckysevens.app/probe?...` for the same reason during validation; the key durable rule is the contract, not the existence of the probe.
- Custom schemes are banned anywhere we assign to `MSMessage.url`. If a future surface needs a custom scheme for deep linking, that belongs on `UIApplication.open(_:)` or `UISceneDelegate.scene(_:openURLContexts:)` — not on `MSMessage.url`.

How to apply this going forward:

- Any new `MSMessage` construction path must use `components.scheme = "https"`. Reviewers should treat a custom scheme on `MSMessage.url` as a correctness bug, not a style choice.
- When diagnosing "URL missing on recipient," first confirm the sender wrote `https://...`. If it did not, fix the scheme before instrumenting further.
- The mental model is: the `url` is validated on the wire the same way iMessage validates any link preview; anything that is not a real web URL is at the platform's mercy.

### 1a. When a platform boundary keeps failing, check the exact symbol-level doc before building repo-wide workarounds

What went wrong:

- The repo spent a long time reasoning from the class-level `MSMessage` / `MSSession` docs, runtime symptoms, and higher-level lifecycle quirks without reading the exact property page for `MSMessage.url`.
- That let a basic contract bug survive: the symbol-level page already stated that `MSMessage.url` must use `http` or `https`, while the repo was still publishing `unluckysevens://...`.
- Because the sender could still read `message.url` back locally, the team overfit to transcript-selection and host-hydration theories and built temporary recovery bridges before falsifying the underlying property contract.

What we learned:

- For Apple framework boundaries, the exact symbol-level page (`property`, `method`, `enum case`) is part of the source of truth, not optional supporting reading.
- If a host/platform bug survives multiple debugging passes, stop and verify the exact API symbol contract before assuming the failure is undocumented framework behavior.
- If the contract still seems ambiguous after reading the exact symbol page, build the smallest possible repro immediately. Do not keep expanding product workarounds while the base contract is still unverified.

How to apply this going forward:

- For Messages, UIKit, SwiftUI, SpriteKit, or any other Apple-host boundary, read the exact symbol page first when the issue depends on a specific property or callback.
- If the bug persists after one serious pass, write or update a micro repro and record the exact symbol links in the active ExecPlan's `Assumptions and Evidence Gate`.
- Reviewers should challenge any platform-workaround patch that does not cite either:
  - the exact symbol-level Apple doc, or
  - a minimal local repro that falsified the obvious contract assumptions.

### 1b. Transcript transport is not perfectly faithful on selection and reopen

This lesson originally described the symptoms traced back to the scheme bug above. After the `https` fix, the remaining real lesson is narrower: even with a correct URL, transcript re-selection is not perfectly faithful on reopen.

What we learned:

- Transport publication and transcript re-selection are not the same reliability boundary inside Messages, but most of the pain we attributed to that boundary was actually scheme validation.
- Even with the correct scheme, the most authoritative payload read is still the `message` argument in `didSelect(_:conversation:)` / `didReceive(_:conversation:)`, not `selectedMessage` during early lifecycle callbacks.

Current repo answer:

- Canonical payload prefers `message.url` now that the scheme is correct.
- Fresh sends are URL-only again after the `https` scheme fix.
- Compact envelope framing plus `compactStateV2` keep the worst-case canonical STATE stress path under the URL budget in tests.
- The app treats pre-TestFlight dev-era summary-mirrored bubbles as intentionally unsupported after the phase-13 cleanup. The compatibility boundary starts with TestFlight builds, not older development transcripts.

### 1c. Lobby host should reopen the latest lobby bubble after the first invite send

What we observed (all real-device, both participants on the thread):

- Host sends the first lobby invite (`STATE rev0`, `.state(gameId:)`) and remains in the Messages thread.
- Joiner taps the invite bubble, taps Join, and publishes `STATE rev1` on the same game session.
- The host does not reliably live-update while sitting in the just-sent host context. Reopening the latest lobby bubble always lands the correct state.
- Established gameplay bubbles behave better than this first invite reply, so the narrow product issue is the initial lobby handshake, not a blanket failure of all same-session updates.

What is not yet the root cause:

- Not MSSession policy: join, setup, and turn STATE publishes all go through `sessionPolicy: .state(gameId:)`, and gameplay works. Swapping join to `.new` was proposed as a diagnostic, not a fix.
- Not transcript transport payload: the envelope, URL scheme, and caption format are identical between invite and gameplay STATE publishes.
- Not transcript chain shape alone: reopening the latest lobby bubble succeeds immediately, so the payload/session path itself is valid enough to recover.

Likely-but-not-yet-confirmed directions:

- Something specific to the *first* reply on a freshly-minted `MSSession` (the invite is the only STATE on that session until the joiner replies). Established sessions in gameplay have multiple prior exchanges and may route deliveries differently.
- Something specific to the lobby host shell state (single-participant roster, `.lastSentState` active context, "just sent first message" presentation state) interacting with Messages' delivery routing.
- An iMessage quirk around delivery to the sender of the *initiating* message in a thread while that sender is still presenting.

How to apply this while the root cause is open:

- Treat the initial host invite shell as disposable. The shipped UX now dismisses immediately after send so the host naturally returns to the thread and reopens the latest lobby bubble.
- Keep `didReceive` as the optimization path for already-open gameplay, but keep bubble reopen plus per-game ledger recovery as the durable path.
- Do not promise that the host’s just-sent invite shell will live-update on the first join reply. The reliable product path is “send invite, return to thread, reopen the latest lobby bubble when ready.”

### 2. Messages host resize must be treated as a hostile gesture boundary

What went wrong:

- Passive drags on the board, shelf, or dock could leak upward and start collapsing or expanding the Messages host.
- The leak was worse when parts of the UI became passive or when the board interaction path failed to claim the gesture strongly enough.

What we learned:

- Messages host resize is not limited to the visible grabber unless the app claims drags aggressively inside its own surfaces.
- A game surface that is only visually interactive is not enough; it must own the drag path.

Current repo answer:

- The app reserves a narrow top-only host-resize strip.
- Board, shelf, and dock drags are meant to stay local to the game.
- The board now uses a dedicated `SKView` host with UIKit recognizers rather than a SwiftUI gesture overlay.

### 3. Bubble folding and transcript collapse are separate from payload transport

What went wrong:

- It was easy to conflate “the bubble collapses cleanly in Messages” with “the app can reliably recover state from that bubble later.”
- In practice, grouping/collapse behavior, selected-bubble recovery, and payload readback were related but not the same problem.

What we learned:

- `MSSession` is primarily a grouping/collapse mechanism for transcript UX, not a durable payload store.
- Reusing one `MSSession` per game helps produce the expected turn-based folded thread behavior, but it does not guarantee that selecting or reopening a bubble later will yield a fully faithful `MSMessage`.
- Collapse/latest-bubble behavior, same-bubble recovery, and payload transport should be reasoned about separately even when they share the same transcript surface.

Current repo answer:

- Canonical game `STATE` messages reuse one `MSSession` per game.
- Lobby join now publishes canonical lobby `STATE` on that same game session instead of treating join as a detached side bubble.
- Forced discard and targeted trade responses now also publish canonical `STATE` on that same game session so remote responder gameplay stays inside the same game thread.
- Pre-TestFlight responder artifacts are no longer a product compatibility target; the shell should recover and prefer live canonical game `STATE`.
- Folding/collapse behavior is treated as a phase-13 host-stability concern, not proof that transcript recovery is already solved.

### 4. SpriteKit board interaction should not run through a hot SwiftUI gesture loop

What went wrong:

- Pan/pinch/tap routed through SwiftUI gesture layers caused lag and made gesture arbitration with Messages harder.
- Two-finger and mixed pan/pinch cases were especially fragile.

What we learned:

- SwiftUI is acceptable for the shell, but the board camera/input loop needs a narrower UIKit/SpriteKit boundary.
- For this app, `SKView` + recognizers is the right interaction surface even though the rest of the shell remains SwiftUI.

Current repo answer:

- Board pan/pinch/tap run through `BoardSceneHostView` and a dedicated `SKView`.
- Camera state lives in the board interaction controller rather than being driven per-frame through SwiftUI gesture state.

### 5. Snapshot-freeze/remount is not a stable default resize strategy

What went wrong:

- Freezing the board to a snapshot during host drag avoided some lag, but it also introduced dead-board states, manual reload dependence, and camera jumps after thaw/remount.
- The more we hardened freeze recovery, the more obvious it became that remounting the board was the disruptive part.

What we learned:

- The right fix for normal gameplay-height resize is not “better thaw.”
- The right fix is to keep the board mounted, do only cheap viewport/camera work during drag, and defer the heavier board redraw to a short debounced settle step.

### 6. Responder actions should publish canonical state directly whenever the rules allow it

What went wrong:

- Non-current-player trade responses and forced discard originally depended on responder envelopes plus later authority-side surfacing.
- That made trade resolution and seven/discard progression feel like transcript bookkeeping instead of one coherent game action.
- It also left correctness exposed to exactly the weakest Messages boundary: whether another device happened to surface the response bubble while open.

What we learned:

- If the rules already allow a non-current actor while `currentPlayer` stays unchanged, that player should publish canonical `STATE` directly instead of waiting for the turn owner to absorb a responder envelope later.
- The publish path must preserve the **responding player's** actor semantics for validation and audit. If the shell blindly re-validates `acceptTrade` / `declineTrade` / `counterTrade` / `submitDiscard` as if the current player were the action actor, the transition is wrong even if the state math itself is legal.
- When a responder action is authored from an older selected bubble, the shell should resolve against the newest known canonical state for that game before drafting or validating the action.
- Ordered forced discard is the cheapest Messages-only way to avoid sibling-state races. If only the next pending discarder may act, multi-player seven flow no longer depends on cross-device merge of simultaneous discard states.
- Same-device cached last-published state is an acceptable temporary recovery bridge for the current-player device when the extension reopens without an active state already in memory, but it must be keyed per game rather than as one global record.
- `MSConversation.selectedMessage` is the currently selected transcript bubble, not a live-updating pointer to the latest game update.
- `didReceive` should be treated as the live-update optimization path for the currently open game, not as permission to hijack the shell onto any newer game update in the thread. If another game's message arrives while a game is open, record it for recovery but keep the visible shell anchored to the active game.
- Do not rebuild player-facing transport diagnostics as a product dependency. If a flow only feels debuggable with custom in-app transport HUDs, the UX contract is still too brittle.

Current repo answer:

- Targeted `acceptTrade`, `declineTrade`, and `counterTrade` now publish canonical state directly from the responding device.
- Forced discard now publishes canonical state directly from the discarding player's device while preserving the original turn owner as `currentPlayer`.
- Multi-player discard is serialized in locked roster order, so only the next pending discarder can act and each canonical discard publish advances the queue deterministically.
- Pre-TestFlight legacy responder action bubbles are intentionally unsupported after the hard runtime reset. Fresh gameplay no longer depends on responder envelopes surfacing on another device.
- Authoring from a stale selected bubble is a different failure mode from recovering from a stale selected bubble. Turn/setup/trade/dev-card publication paths should resolve against the newest known canonical state for the same game before drafting or validating an action, otherwise the shell can still produce obsolete anchors even after recovery logic improved.
- A short post-selection polling burst is not enough for Messages-hosted async play. If the extension is open on a game bubble, it needs a lightweight ongoing selection watch while that context remains active, because same-session surfacing can lag well past the first couple of seconds.
- Same-device cached published-state recovery now stores a per-game bridge for reopen/response selection paths instead of relying on one global last-published state.
- Trade-response copy no longer exposes old transport intent terminology, and fresh responder gameplay no longer uses action bubbles as the main transport primitive.

### 7. Per-game recovery beats one global cached-state bridge

What went wrong:

- The repo previously mixed three separate recovery ideas:
  - `latestKnownStatesByGameId` in memory
  - one global last-published-state cache
  - device-local observed-join overlays
- That split made join/start recovery and reopen behavior brittle because the app could recover state for one game and joiners for another, or regress to the wrong recovery source after a reopen.

What we learned:

- Recovery has to be per game.
- The latest canonical state, observed joiners, and last active game identity should come from one ledger surface rather than from unrelated caches.
- A global "last published state" record is too coarse for an app that can have multiple active games in one thread history.

Current repo answer:

- The app now keeps a per-game local ledger for latest known `STATE`, observed joiners, and last active game identity.
- Active-context recovery and intent-context resolution now consult that ledger instead of a separate global cached-state bridge.
- Device-local pending joins are no longer the canonical lobby assembly surface.

### 7a. Lobby join should be canonical state only

What went wrong:

- Join spent too long as a detached intent flow even though the product wanted it to feel like the rest of the game.
- That left the open lobby dependent on surfaced join bubbles and made `Start Game` artificially tied to the original `rev0` invite instead of the latest lobby state.

What we learned:

- Fresh join should publish updated lobby `STATE` on the canonical game session.
- The app should not keep product logic around pre-TestFlight legacy join bubbles once the protocol boundary is reset for TestFlight.
- If the app can recover canonical state for the same game, it should reopen that state rather than rendering a join-specific fallback shell.

Current repo answer:

- Fresh `Join Game` publishes canonical lobby `STATE` and advances lobby rev instead of emitting a detached join bubble.
- `Start Game` uses the latest lobby rev, not a hard-coded `rev0` invite assumption.
- Start-roster assembly merges the visible lobby roster with observed joiners so concurrent join states can still converge when the host starts.

### 8. Player-facing names that must survive reopen or handoff belong in canonical state

What went wrong:

- Alias-only display was acceptable while player naming did not exist, but a local-only rename field would have disappeared on reopen, transcript round-trip, and lobby-to-game transition.
- That would have made the rename UX feel broken even if the local device updated immediately.

What we learned:

- If a player-facing name needs to survive Messages transport, reopen, and device handoff, it must live in canonical game state and round-trip through compact state transport.
- Alias fallback is still useful, but it is a fallback. It cannot be the only persistence story once custom names exist.

Current repo answer:

- Lobby display names now live in `CoreGameStateV1.playerDisplayNamesByPlayer`.
- Compact state transport round-trips those names.
- The shell prefers the canonical custom name and falls back to the deterministic alias when no custom name is present.

### 8b. Local convenience persistence is separate from canonical table truth

What went wrong:

- Once lobby renaming existed, players would have had to retype their preferred name every new game on the same device even though the game already had a clean canonical persistence model for the current table.
- Solving that only in local UI state would have been fine for convenience, but mixing it up with canonical naming would have risked hiding where shared truth actually lives.

What we learned:

- There are two different persistence layers for player naming:
  - device-local preferred-name storage for prefill convenience
  - canonical per-game naming for what the table actually sees
- The local preference should prefill new host/join drafts on that device, but it should only become shared truth when the player publishes host/join/rename state for that game.

Current repo answer:

- The Messages extension stores a local preferred lobby name in device-local `UserDefaults`.
- New invite and join drafts prefill from that stored value when no canonical name for the local player already exists in the selected lobby state.
- Once the player hosts, joins, or renames in the lobby, that name is still published into canonical state so reopen and device handoff remain correct.

### 7b. Current-player gameplay should not masquerade as generic action transport

What went wrong:

- The repo gradually moved the real player flows onto direct canonical `STATE` publication, but the codebase and fallback shells still talked as if generic action transport were the main model.
- That made it harder to reason about session ownership and easy to accidentally reintroduce fresh-session action sends for flows that should have behaved like roll/build/end-turn.

What we learned:

- The clean product model is: new game creates the game session once, and lobby/current-player gameplay keep reusing that session for canonical `STATE`.
- Trade/discard responder actions should also stay on that same per-game session when they publish canonical `STATE`.
- Pre-TestFlight legacy setup/current-turn action bubbles are not worth preserving once the fresh protocol path is stable enough for TestFlight.

Current repo answer:

- Fresh lobby join and current-player gameplay publish canonical `STATE` on the canonical game session.
- Forced discard and targeted trade responses now also publish canonical `STATE` on that same game session.
- The per-game ledger must record decoded incoming `STATE` as well as locally published `STATE`; otherwise recovery becomes asymmetrically worse on receiving devices, which is exactly where Messages host churn already hurts the most.

### 8. Active-game recovery needs a player-visible affordance, not only invisible cache logic

What went wrong:

- Even after the repo gained a per-game ledger, recoverable games could still feel "missing" if the currently selected transcript bubble was stale or unrelated.
- Recovery that exists only as internal cache logic is not enough if the player has no obvious way to tell the app which known game to reopen.

What we learned:

- Messages-hosted recovery needs both substrate and surface.
- Once the app knows about multiple recoverable games, it should expose a compact in-app recovery affordance rather than forcing transcript archaeology.

Current repo answer:

- The shell now exposes a compact `Game` / `Games` recovery chip backed by the per-game ledger.
- Recovering a game from that chip restores the latest known canonical state for that game and updates active context without requiring a fresh state bubble selection.

### 9. Messages layout classes are not enough; iPad host height is a separate constraint

What went wrong:

- iPad Messages hosts can be wide but vertically short.
- Percentage-only lower-area sizing and generic overlay heights made `Hand`, `Bank`, and `Players` clip, over-expand, or become hard to tap.

What we learned:

- Width class is not enough.
- Utility shelves, build/dev shelves, and trade panels need content-class sizing, and wide-but-short iPad hosts need a compact vertical fallback.

Current repo answer:

- Lower rail and overlay shelf use bounded sizing rather than pure percentages.
- Utility shelves stay compact and content-only.
- Wide-but-short iPad hosts fall back to compact vertical metrics instead of oversized pad minima.

### 10. Overlapping shell modes create dead-end UI state quickly

What went wrong:

- `Build`, utility shelves, trade state, and dev-card state previously overlapped.
- That caused “can’t close,” “must back out first,” and “button froze until reopen” behavior because more than one piece of shell state could be active at once.

What we learned:

- `Build`, utility shelves, `Trade`, and `Play Dev` must be peer routes, not overlapping modes.
- End-turn and action switching need one consistent “cancel transient state and switch” rule.

Current repo answer:

- The shell now treats utility shelves, `Build`, `Trade`, and `Play Dev` as peer routes.
- Direct switching is allowed between peer actions.
- `End Turn` clears transient build-selection state instead of blocking on it.

### 11. Trade cannot depend on tapping controls underneath an overlay

What went wrong:

- A trade panel layered above the lower shelf while still telling the user to tap `Hand` or `Players` below was unreliable on both hit-testing and layout.
- Close/resume behavior was brittle because trade state and shelf state were split.

What we learned:

- Trade must own its own interaction surface.
- Reusing visual components is fine; reusing the shelf interaction model underneath an overlay is not.

Current repo answer:

- Trade is now a dedicated self-contained panel.
- The lower shelf is hidden/disabled while trade is open.
- `You Give`, `You Want`, and `Recipients` live inside the trade panel, and switching away discards the draft immediately.

### 12. Dev-card UX needs card inventory, not long instructional text

What went wrong:

- The earlier dev-card surface was text-heavy and made ownership/actionability hard to read, especially for VP cards.

What we learned:

- The player needs to see dev-card inventory as cards first, then move into the minimal next choice for the selected card.
- Visibility and actionability are separate concerns: VP cards should be visible to the owner without always being playable.

Current repo answer:

- `Play Dev` now opens a card-oriented dev shelf.
- Knight, Monopoly, Year of Plenty, and Road Building stay action-driven from that card surface.
- Victory Point cards are visible to the owning player and only become revealable when they would immediately win.

### 13. Temporary diagnostics are justified for iMessage-host work, but they must stay temporary

What went wrong:

- Without visible source diagnostics and host-gesture probes, device debugging became guesswork.

What we learned:

- For iMessage-host problems, compact in-app instrumentation is often the fastest way to prove what the host is actually doing.
- But this instrumentation must stay clearly temporary so it does not silently become product UI.

Current repo answer:

- The probe code still exists, but the temporary transport badge, host-gesture HUD, and manual `Reload Board` control are now gated off in the default root shell.
- Active game recovery remains product-visible; operator-only diagnostics do not.

Removal expectation:

- Phase 13 release-readiness cleanup owns keeping these diagnostics gated down unless a future troubleshooting slice explicitly re-enables them.

### 14. Simulator confidence is not enough for Messages-hosted UI work

What went wrong:

- Several flows looked acceptable in Simulator or Debug builds but broke on real devices, especially around transcript selection, host resize, and interaction responsiveness.
- This created false confidence and delayed the discovery of the actual host-boundary problems.

What we learned:

- Messages-hosted UI behavior must be judged on hardware.
- Simulator remains the fast build/layout loop, but host lifecycle, transcript fidelity, resize behavior, and overall turn-taking confidence need device validation before the flow is considered real.

Current repo answer:

- Real-device checklists remain part of the live QA gate.
- Phase conclusions and major UI claims should not rely on Simulator-only confidence.

### 15. Board-first shells need strict surface ownership

What went wrong:

- When too many surfaces were allowed to compete for the same space or interaction band, the shell became hard to reason about: shelves clipped, controls overlapped, the board resized unexpectedly, and interaction felt inconsistent.

What we learned:

- In a Messages-hosted game, each region needs one clear job:
  - board owns pan/zoom/tap
  - lower shelf owns utility/detail content
  - dock owns primary turn actions
  - top strip owns host resize
- Utility/detail surfaces should overlay the board intentionally instead of forcing the board to resize whenever the lower UI changes.

Current repo answer:

- The board remains visually stable while shelves and panels move over the lower portion of the shell.
- Trade owns its own panel.
- Utility shelves stay compact and content-scoped instead of becoming a second full-screen app layout.

### 15. When async feature bugs cluster around bubble surfacing, stop patching the feature layer first

What went wrong:

- Join progression, trade-response progression, active-game recovery, and stale-bubble reopen all kept presenting as separate feature bugs.
- In practice they were all hitting the same selected-bubble, surfaced-message, and local-ledger boundary in Messages.

What we learned:

- Once multiple player-facing bugs reduce to the same host/transport/recovery limitation, they are no longer ordinary phase-local feature work.
- At that point, continuing feature-by-feature patching is usually lower leverage than pulling the architecture slice forward.

Current repo answer:

- The 2026-04-16 audit moved phase 13 to the front of the queue.
- The remaining unfinished phase-12 gameplay/signoff work now rides at the tail of phase 13 instead of pretending gameplay can finish cleanly on top of an unstable host substrate.

## Real Device Lane

Use real devices as the source of truth for Messages-hosted behavior. Simulator remains the fast build and layout loop, but transcript state, bubble selection, context persistence, and general extension stability should be verified on hardware.

Default matrix:

- iPhone on your primary Apple account
- iPad on a separate Apple account
- one real Messages conversation between those two accounts

Treat this matrix as the baseline for async gameplay validation.

### Real Device Shell Smoke

Run this after shell, layout, presentation, or mode-system changes.

1. Install the current development build on both devices. In the current repo shape this may still happen through the minimal containing-app shell, but the intended product surface is the Messages app drawer.
   Recommended local pipeline:
   `bash ./scripts/install-connected-devices.sh`
2. Open Messages and confirm Unlucky Sevens appears in the app drawer on both devices.
3. Open the same conversation between the two accounts.
4. Open an existing canonical `STATE` bubble and confirm the extension requests expanded presentation and the shell renders:
   - header
   - board area
   - handle band
   - action dock
5. Confirm the collapsed lower rail shows only:
   - small centered pull-tab
   - dock row
   Confirm the pull-tab and close controls have clear accessibility labels for VoiceOver.
6. Confirm the persistent dock order stays:
   - `Roll`
   - `End Turn`
   - `Build`
   - `Play Dev`
7. Open the pull-tab and confirm the overlay shelf header exposes:
   - `Hand`
   - `Bank`
   - `Players`
   - close chevron
8. Confirm hand, bank, and player summaries are not always-open cards in the default shell.
9. Confirm `Hand`, `Bank`, and `Players` do not repeat inner titles or subtitles once the shelf is open.
10. Confirm `Hand`, `Bank`, and `Players` do not scroll in the normal case.
11. Confirm the iPhone layout remains readable in compact extension sizing and that the shell continues to fit the visible host bounds while the board stays responsive.
12. Confirm the iPad layout remains readable, does not over-expand low-priority UI, and caps the lower-rail content width instead of stretching hand/bank/player content across the full host width.
13. Verify opponent information is still count-only and does not leak composition.
14. If the thread has recoverable canonical state for one or more games, confirm the compact `Game` / `Games` chip appears in the top-left and opens a recoverable game list without disturbing the normal shell.
15. Confirm the shell remains product-focused and no debug UI is required to advance the normal game flow.

### Real Device Lobby Smoke

Run this after any lobby join/start UX change.

1. From device A, send an invite `STATE` into the thread.
2. On device A, confirm the extension dismisses back to the Messages thread immediately after the invite is sent.
3. On device B, select the invite bubble and confirm the extension resolves the invite before joining.
4. On device B, enter a custom lobby name before joining and then join from the invite bubble.
5. Confirm joining does not require an extra manual send step after tapping `Join`.
6. On device A, reopen the latest lobby bubble in the thread and confirm the lobby UI now reflects both the host and the joined guest. Reopening a real one-player lobby bubble before anyone joins should show the normal interactive lobby.
7. Confirm the joined roster uses the custom lobby name when set and falls back to the deterministic alias when it is not.
8. Update the joined player's name from the reopened lobby and confirm the renamed roster persists after closing and reopening the latest lobby bubble on both devices.
9. Close the extension on both devices, start a fresh lobby from each device in turn, and confirm the local name field prefills from that device's saved preferred lobby name before any new join/rename publish.
10. Confirm `Start Game` stays unavailable until at least two players appear in that reopened host lobby, then start from device A.
11. From device B, open the start `STATE` and confirm the extension resolves the new setup context cleanly.
12. Confirm the fresh invite, join, rename, and start bubbles all use descriptive product copy instead of revision/debug text.
13. Confirm the first invite bubble shows the branded Unlucky Sevens invite image, while join and rename bubbles remain text-only.
14. Confirm the start bubble shows a board/status snapshot when the board exists.
15. On both devices, if the thread now contains more than one recoverable game or stale lobby context, confirm the compact `Game` / `Games` recovery chip opens the correct latest known lobby or game context without requiring transcript hunting.

### Real Device Messages Lifecycle

Run this after phase-13 stability work or when explicitly validating Messages host behavior. It is no longer a phase-12.7 acceptance gate.

1. Send a new `STATE` bubble from one device.
2. Select that bubble on the other device and confirm it becomes active context.
3. Switch away from Messages and return.
4. Reopen the same bubble and confirm the shell still resolves the correct context.
5. Select an older bubble after a newer one exists and record whether the host keeps you on stale context, upgrades to the latest known state, or fails to recover.
6. If the selected bubble is stale or unrelated but the game is known locally, use the compact `Game` / `Games` recovery chip and confirm the shell restores the latest known canonical state for the intended game.
7. Force-close and relaunch Messages, then record whether context can still be recovered from the selected bubble or from the active-games recovery chip.

### Real Device Turn-Taking Smoke

Run this after any action-flow change that affects turns, trades, robber, or dev cards.

1. From device A, publish or reach a playable `STATE`.
2. Perform one legal action from the acting player.
3. On device B, confirm the new bubble appears and opens cleanly.
4. Continue the turn or respond from the other account when appropriate.
5. Verify status text is correct on both sides:
   - `Your turn`
   - `Waiting on <player>`
   - `Roll pending` before the active player rolls
   - `Roll: <d1> + <d2> = <total>` after the active player rolls
6. Confirm fresh turn/setup bubbles use `Unlucky Sevens: <descriptive title>` copy with a short human-readable summary instead of `ULS STATE` or revision text.
7. Confirm setup, roll/build/trade/robber/end-turn, and game-over bubbles show a board/status snapshot when the board exists.
8. Reopen/select old bubbles and confirm payload still decodes from the URL-backed state, not from image or display text.
9. Confirm no bubble or context step silently drops during cross-device play.

### Real Device Gameplay Cohesion

Run this before calling the current gameplay shell ready for external testers.

1. Open the same active game on both devices and verify the shell uses the lobby-set custom player names when present, otherwise deterministic aliases such as `SheepGrazer` or `OreMiner`. The displayed names should match on both devices for the same game.
2. On a fresh turn before rolling, confirm the default shell reads as:
   - header
   - board
   - handle band
   - dock
3. Confirm the board does not resize when opening or closing `Hand`, `Bank`, `Players`, `Build`, or `Play Dev`.
4. Confirm the primary dock order is:
   - `Roll`
   - `End Turn`
   - `Build`
   - `Play Dev`
5. Confirm the collapsed lower rail shows only the pull-tab and the dock row; utility cards should not be visible until the pull-tab is opened.
6. Confirm the full island and all ports are visible at default zoom, with a small ocean margin and slightly more water below the island than above. Confirm you can zoom out only slightly beyond default and zoom in much further than the fit overview.
7. On a freshly started game, confirm the generated board does not place adjacent `6`/`8` number tokens.
8. Confirm pan, pinch, and board taps remain responsive on first open on both iPhone and iPad; they should not require reloading the game view before working.
9. Drag the Messages host smaller and larger. Confirm the shell remains fitted to the visible host bounds during the drag, the board stays interactive at gameplay height, and one settled redraw completes after the host stops moving without requiring manual board reload.
10. At the normal fully-extended gameplay height, confirm the board remains live throughout host drag, panning, pinching, and normal interaction.
11. On iPad, open `Hand`, tap a legal setup/build target, then switch between `Hand`, `Bank`, and `Players`. Confirm the lower shelf stays fully visible and tappable and the board does not steal those taps.
12. Confirm the overlay shelf overlaps the board intentionally only at the bottom edge. No utility/header/dock content should collide or wrap into neighboring regions.
13. On both iPhone and iPad, drag on the board, lower shelf, and dock. Confirm those drags stay inside the game surface and do not start resizing the Messages host. Only the narrow top grabber strip should be able to collapse or expand the host.
14. On iPad, with the Messages host at its normal gameplay height, open `Hand`, `Bank`, and `Players`. Confirm the lower shelf uses the compact vertical layout when needed rather than clipping or disabling utility shelves because the width is wide.
15. Open `Build` and verify the shelf only shows legal actions from:
   - `Road`
   - `Settlement`
   - `City`
   - `Buy Dev`
16. While `Build` is open, tap `Hand`, `Bank`, and `Players` and confirm the shell switches directly to the requested utility shelf instead of forcing a manual build close first.
17. While `Hand`, `Bank`, or `Players` is open, tap `Roll`, `Build`, `Trade`, `Dev Cards`, and `End Turn` as they become legal and confirm the dock buttons stay tappable instead of being blocked by the visible shelf container.
18. Tap the pull-tab, then `Hand`, `Bank`, and `Players`, and confirm only one shelf opens at a time.
19. Close each shelf through both:
   - the close chevron
   - tapping the selected utility tab again
20. Confirm the `Trade` dock action appears only after rolling and opens a dedicated trade panel rather than a `Hand` shelf row.
21. While trade is open, confirm the lower shelf is hidden/disabled and the trade panel fully owns interaction until the draft is sent or cancelled.
22. As proposer, confirm the player-trade composer is vertically stacked as:
   - `You Give`
   - `You Want`
   - `Recipients`
   and that only the recipient section scrolls.
23. Confirm `You Want` shows both the five resource types and the remaining public bank counts.
24. Switch away from trade by opening another peer route and confirm the trade draft is discarded immediately rather than leaving stale shell state behind.
25. Open the `Bank` shelf and confirm it shows public remaining counts for wood, brick, sheep, wheat, and ore using the same chip sizing and spacing as the `Hand` shelf. Verify it only becomes interactive during Monopoly or Year of Plenty selection.
26. Open the `Players` shelf and confirm each opponent row only shows:
   - display name
   - current-turn indicator
   - public VP
   - public hand count
27. Confirm `Hand`, `Bank`, and `Players` do not add inner titles or subtitles and do not scroll in the normal case except when the host is too constrained to fit the utility body without scrolling.
28. Tap random nodes, edges, and tiles while idle. Confirm nothing highlights or remains selected unless the active mode actually uses that board target class.
29. Open the dev-card panel and confirm it renders as visible card inventory rather than a long text list. The owning player should be able to see held dev cards, including Victory Point cards.
30. Confirm only legal dev-card plays are actionable from that card shelf:
   - Knight
   - Monopoly
   - Year of Plenty
   - Road Building
31. Play Knight and confirm the robber moves to the selected tile. If the chosen tile has multiple legal victims, verify the board highlight victim step becomes explicit; if it has one or zero legal victims, verify the flow resolves without an unnecessary extra picker.
32. Play Monopoly and confirm the chosen resource is the one collected from opponents.
33. Play Year of Plenty and confirm the selected two resources are taken from the bank and added to the player.
34. Play Road Building and confirm the selected two edges are placed without resource cost.
35. If a Victory Point card is present, confirm it is visible in the owner card shelf but only becomes revealable when it would immediately win the game.
36. Open the trade panel as proposer and responder. Confirm the compact panel explains accepted, waiting, passive-decline, and end-turn expiry behavior without leaking raw IDs or debug text.
37. Enter setup, build, robber, Knight, and Road Building flows and confirm the in-board hint chip is small, single-line, and shifted above the overlay shelf when the shelf is open.
38. Finish a game-over state or load one from transcript and confirm the shell shows:
   - winner clearly
   - compact final score
   - short last-turn recap
   - no dead bottom tray
39. Open and close `Hand`, `Bank`, `Players`, `Build`, and `Play Dev` repeatedly and confirm the board does not visibly hitch or rebuild while the shelf changes.
40. In setup and build modes, tap one legal target once and confirm nothing publishes yet. Confirm the target highlights, then tap the same selected target again and confirm it publishes.
41. After selecting a setup/build target, tap a different legal target and confirm the selection moves without publishing.
42. On both iPhone and iPad, select a setup/build target while `Hand`, `Bank`, or `Players` is visible and confirm the shelf header tabs remain usable instead of being replaced by a forced-flow panel.
43. Drag down from the top of the Messages transcript to collapse the host while a live game is open, both with the shelf closed and with a shelf open. Confirm the board stays mounted and responsive at gameplay height during the drag, then performs one clean final refit after the host settles without camera jumps or manual reload.
44. On both iPhone and iPad, confirm the `Hand` and `Bank` shelves keep the same chip sizing and a capped reading width instead of stretching to full host width.
45. In a visibly constrained host height, confirm a utility shelf closes instead of rendering partially offscreen or leaving unreachable content below the viewport.

### Real Device UX Hardening

Run this after any change to product authority, board responsiveness, or setup-road interaction.

1. During setup road placement, tap near the just-placed settlement endpoint and confirm the intended legal road can still be selected without hunting for a tiny mid-edge target.
2. Toggle setup, build, and turn overlays several times on both devices and confirm board updates remain responsive rather than visibly rebuilding or hitching.
3. Pan and zoom after those updates and confirm responsiveness does not degrade noticeably on either device.
4. On the non-current device, confirm the shell remains read-only and out-of-turn actions cannot be published.

## What Is Already Covered Well

- lobby join/start UX, including one-step join and host-owned start
- setup placement UX in the product shell
- the common turn loop and build/buy actions in the product shell
- robber/discard forced-flow handling in the product shell
- trade UX in the product shell, including self-contained player trade, maritime quick-trade options, and responder actions
- dev-card UX in the product shell, including compact play actions, pre-roll/post-roll timing, staged bank/board choice flows, and winning-only Victory Point reveal
- setup sequencing and starting resources
- deterministic dice, board generation, dev deck, and robber steal behavior
- production, bank depletion, discard flow, robber flow
- trade proposal / accept / expiry
- maritime trade ratio selection
- dev card timing and effects
- awards and victory gating
- deterministic full-match replay and invariant rejection

## What This Pass Added

- realistic transport stress test for canonical STATE payload budget and roundtrip decode
- shared `ULS_CoreGame` view/query helpers for legal default actions and viewer-scoped secrecy-safe projections
- focused core tests covering the new query/projection surface against reducer legality and secrecy expectations
- sender-side compact canonical STATE transport plus sender-side cached-state recovery on top of URL-only publication

## Remaining High-Value Gaps

- no automated transcript-level Messages UI checks yet
- snapshot regression substrate exists, but visual assertions are still size/non-empty checks rather than golden image diffs
- no automated real-device lane; hardware validation is still manual

## Manual Simulator Runbook

Use the current product shell for one smoke pass and three targeted checks.

### Smoke Pass

1. Run the Practical Gate commands.
2. Launch the current development build if needed to install the extension, then open Messages in the simulator.
3. In Messages, create or open a thread and launch Unlucky Sevens.
4. Tap `Invite Players`, then verify a lobby `STATE` bubble appears and the extension decodes it as active context.
5. Tap `Join` from another simulated actor path if available, then `Start Game`.
   - Prefer the product flow. Debug-only steps such as `Record Join` should only be used on older branches or if a stage is still incomplete.
6. Apply setup intents until the game reaches turn phase.
7. Roll once, apply the resulting intent into `STATE`, and verify:
   - rev increments
   - phase is `turn`
   - step becomes `afterRoll` or the correct robber/discard subflow
8. If available, play one legal dev card before rolling and verify the resulting state change appears without leaking hidden card composition to opponents.
9. Confirm the default shell reads as header, board, handle band, and dock rather than stacked hand/bank/player cards.
10. Confirm the board does not resize when opening `Hand`, `Bank`, `Players`, `Build`, or `Play Dev`.
11. Drag the Messages host between expanded and constrained heights and confirm the board world stays visually stable even though the visible viewport changes.
12. Tap the pull-tab, then `Hand`, `Bank`, and `Players`, and confirm only one shelf opens at a time and each shelf can be closed via the chevron or by tapping the selected tab again.
13. Confirm the bank shelf shows public counts for wood, brick, sheep, wheat, and ore, and only becomes interactive during Monopoly or Year of Plenty selection.
14. Roll once, then perform one post-roll action such as build, trade, maritime trade, or dev-card purchase.
15. Open the dev-card panel when legal and verify only legal play/reveal actions are shown there; buy-dev-card should now live under the `Build` shelf instead.
16. Verify `Play Dev` never falls back to default-choice labels for Knight, Monopoly, Year of Plenty, or Road Building. Knight should move through tile choice first and only open a victim choice when the chosen tile has multiple eligible steals; Monopoly should use the bank shelf, Year of Plenty should use first/second bank picks, and Road Building should use first/second road choice.
17. Verify Victory Point reveal stays hidden unless the reveal would immediately win the game.
18. Confirm the only valid overlap is the overlay shelf covering the bottom of the board; handle-band controls, dock controls, and board chrome must not collide or wrap.
19. End the turn and verify:
    - current player advances
    - step resets to `needsRoll`
    - trade offers clear
20. Verify opponent hand and dev-card views show counts only, not composition.
21. Verify the turn header never shows raw debug/context metadata; it should stay limited to ownership plus dice state.

### Targeted Check: Robber / Seven Flow

1. Continue play until a 7 occurs naturally.
2. Verify required discard counts appear only for players with more than 7 cards.
3. Submit explicit discard selections and confirm the engine blocks robber movement until all required discards complete.
4. In a multi-player discard turn, verify only the next pending discarder can submit. After the first discard publishes, confirm the next required player becomes active on the latest state and an older bubble does not allow an out-of-order discard publish.
5. Move the robber and confirm the engine only offers eligible victims.
6. Apply steal and verify the turn returns to `afterRoll`.

### Targeted Check: Trade Lifecycle

1. From an `afterRoll` state, open the compact trade modal as the current player.
2. Verify `Player Trade` opens a self-contained composer with `You Give`, `You Want`, and `Recipients`.
3. Verify `Maritime / Bank Trade` opens a quick-trade list of legal options rather than a manual composer.
4. Switch acting actor and accept the offer from a targeted responder device.
5. Confirm the accepting device immediately publishes the resolved canonical trade state and that the updated state is visible to the table without a second commit step.
6. Verify resource transfer is atomic and the offer clears.
7. Repeat with decline or counter and confirm those responses also publish canonical state immediately from the responder device without a manual "apply selected response" step.
8. Repeat a turn where the offer is not executed and confirm `End Turn` expires it.

### Targeted Check: Context / Secrecy Safety

1. Select an older `STATE` bubble after a newer one exists.
2. Record whether the simulator shell resolves to the latest known game state, stays on stale context, or fails to recover.
3. Confirm a non-joined participant remains read-only and only sees count-only hidden-information summaries.
4. Confirm the joined local participant sees only their own hidden detail while opponent information remains count-only.

## Host-Stability Regression Checklist

These were the highest-signal device checks from the host-stability phase. Reuse them when transcript recovery, stale-bubble reopen, or cross-device host behavior looks suspect again.

1. Two-device join:
   - keep the inviter bubble open
   - accept/join from the second device
   - confirm the inviter shell updates through canonical lobby-state progression without raw join-intent UI
2. Two-device trade response:
   - proposer creates a targeted trade
   - responder accepts, declines, and counters in separate runs
   - confirm the proposer shell auto-recovers the right game state when the response bubble is surfaced and does not require manual “intent bookkeeping”
   - confirm clicking a surfaced response bubble does not replace the live game with raw response UI
3. Stale bubble reopen:
   - create a newer canonical `STATE`
   - reopen an older bubble for the same game
   - confirm the app prefers the latest recovered state for that game
4. Active-games recovery:
   - with no useful selected state bubble open, use the in-app `Game/Games` recovery chip
   - confirm the latest known canonical state for the intended game reopens correctly
5. Full standard-match pass:
   - run a complete real-device match from lobby through victory
   - verify setup, roll/production, trade, dev cards, robber/discard, end-turn progression, and winner-state summary on the corrected substrate
6. If any of the above fail, capture:
   - exact transcript bubble selected
   - whether a newer bubble existed
   - whether the active-games chip was available
   - screenshots of the visible shell state
