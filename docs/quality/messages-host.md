# Messages Host and Gameplay Lessons

Durable implementation knowledge for the Messages host, canonical gameplay flow, transport boundaries, and shell ownership. Current commands and change-type routing live in [QA](qa.md); device procedures live in [device runbooks](device-runbooks.md).

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

- Main transport builds `https://ksharda.me/unluckysevens/msg?payload=<encodedEnvelope>` (`MessagesExtension/Sources/Presentation/TranscriptTransportSupport.swift`). The public host is owned by the developer; transport decoding remains query-based so pre-TestFlight development bubbles using the former host still decode.
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

### 4a. A SpriteKit surface can overdraw SwiftUI and UIKit sibling backgrounds

What went wrong:

- Game Information labels appeared above the live board, but every SwiftUI fill, mask, z-index change, and sibling UIKit backing remained below the final `SKView` render pass.
- Opacity experiments looked pixel-identical because the panel color matched the table wherever the board was absent; the only visible failure was the board/panel overlap.

What we learned:

- When a shell surface must hide part of the live board without unmounting or resizing it, the occlusion must be authored in the SpriteKit scene itself.
- A green frame/assertion journey is not proof of compositor ordering. Compare the rendered overlap pixels or inspect the settled screenshot.

Current repo answer:

- Game Information computes only the portion of the board viewport it overlaps.
- `GameBoardScene` owns a camera-anchored, top-rounded opaque occlusion node for that overlap; the SwiftUI panel owns the remainder and all controls.
- `GameBoardSceneTests` locks the occlusion node's viewport geometry and hidden-state behavior.

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
- Messages XCUITest journeys must not pre-toggle a source control when the destination action already owns that cleanup. After dismissing an overlay, wait for nonexistence, reacquire the destination by its stable identifier, and use its current frame for the tap when Messages returns a stale accessibility hit target. Reacquire again after the tap and assert the destination surface identifier rather than reading selection state from the pre-transition element. This avoids animation races, stale-target taps such as Hand reopening instead of Trade, and stale-element assertions after SwiftUI replaces the route.
- When a responder action is authored from an older selected bubble, the shell should resolve against the newest known canonical state for that game before drafting or validating the action.
- Ordered forced discard is the cheapest Messages-only way to avoid sibling-state races. If only the next pending discarder may act, multi-player seven flow no longer depends on cross-device merge of simultaneous discard states.
- Same-device cached last-published state is an acceptable temporary recovery bridge for the current-player device when the extension reopens without an active state already in memory, but it must be keyed per game rather than as one global record.
- `MSConversation.selectedMessage` is the currently selected transcript bubble, not a live-updating pointer to the latest game update.
- `didReceive` should be treated as the live-update optimization path for the currently open game, not as permission to hijack the shell onto any newer game update in the thread. If another game's message arrives while a game is open, record it for recovery but keep the visible shell anchored to the active game.
- Drawer entry begins in an Apple-owned compact presentation and `requestPresentationStyle(.expanded)` is only a request. Repeated physical tests showed automatic expansion can vary on unchanged bytes, so fixed-delay retries are not a durable contract. Record activation, style, bounds, and transition callbacks on an unchanged build before changing controller timing. iPad may retain Apple-owned transcript presentation; render a bounded summary/**Open Game** continuation there and never mount or scale the tabletop into the transcript card.
- A ledger-backed snapshot cannot establish a live game. Two-account physical tests showed that restoring its game ID does not recreate Apple-selected message/session delivery; gameplay must begin from a real selected bubble. A valid newer `didReceive` then advances that bubble-bound game, while other-game updates remain ledger-only.
- Do not rebuild player-facing transport diagnostics as a product dependency. If a flow only feels debuggable with custom in-app transport HUDs, the UX contract is still too brittle.

Current repo answer:

- Targeted `acceptTrade`, `declineTrade`, and `counterTrade` now publish canonical state directly from the responding device.
- Forced discard now publishes canonical state directly from the discarding player's device while preserving the original turn owner as `currentPlayer`.
- Multi-player discard is serialized in locked roster order, so only the next pending discarder can act and each canonical discard publish advances the queue deterministically.
- Pre-TestFlight legacy responder action bubbles are intentionally unsupported after the hard runtime reset. Fresh gameplay no longer depends on responder envelopes surfacing on another device.
- Authoring from a stale selected bubble is a different failure mode from recovering from a stale selected bubble. Turn/setup/trade/dev-card publication paths should resolve against the newest known canonical state for the same game before drafting or validating an action, otherwise the shell can still produce obsolete anchors even after recovery logic improved.
- A short post-selection polling burst is not enough for Messages-hosted async play. If the extension is open on a game bubble, it needs a lightweight ongoing selection watch while that context remains active, because same-session surfacing can lag well past the first couple of seconds.
- Same-device cached published state remains a per-game ledger input for history, latest-state resolution after real bubble selection, and response safety; it is not a navigation or publication authority.
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
- Canonical lobby joins and renames are still core state transitions. They must pass `ULS_CoreGame.validateTransition` before Messages publishes the bubble, even though they are audit-neutral and happen before turn actions exist.

Current repo answer:

- Fresh `Join Game` publishes canonical lobby `STATE` and advances lobby rev instead of emitting a detached join bubble.
- `Start Game` uses the latest lobby rev, not a hard-coded `rev0` invite assumption.
- Start-roster assembly merges the visible lobby roster with observed joiners so concurrent join states can still converge when the host starts.
- Core validation now explicitly accepts only two lobby-to-lobby mutations: appending the joining actor with normalized default maps, or changing the already-joined actor's display name. Wrong actors, roster reorder/removal, and editing another player's name are rejected below the Messages shell.

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

### 8. Local history must not impersonate a live Messages selection

What went wrong:

- The first Games surface let a player open a ledger snapshot and appeared to restore the intended game ID.
- On two separate physical builds, A bubble → saved game B → newer B left the receiver stale until B's real bubble was selected.
- Apple does not expose transcript enumeration, a setter for `selectedMessage`, or a reconstructible public `MSSession` identity, so the app cannot honestly turn arbitrary local history into a live selected game.

What we learned:

- Canonical state identity and live Messages delivery identity are separate constraints.
- A local ledger is valuable for statistics, history, and stale-state resolution after real selection, but not as a gameplay launcher.
- When the platform cannot prove a live session, publication must fail closed rather than create a parallel bubble chain.

Current repo answer:

- The fresh invitation/loading card and current-game Game Information expose a read-only Player Record backed by the versioned per-game ledger.
- Player Record presents device-local overall results and an exact-participant-set group view. It does not claim a stable chat identity, because Messages does not expose one.
- The ledger validates canonical snapshots, repairs corrupt records, converges equal-revision siblings by greatest hash, stores the local player's identity outside canonical state, and caps finished history at eight.
- Player Record has no Open, Reconnect, Resend, archive, or lifecycle publication controls. Resign, draw, and host end live on the current game and require its bound session.

### 9. Messages layout classes are not enough; host height is a separate constraint

What went wrong:

- iPad Messages can supply both wide-short and phone-width-short extension canvases.
- Percentage-only lower-area sizing and generic overlay heights made `Hand`, `Bank`, and `Players` clip, over-expand, or become hard to tap.

What we learned:

- Width class is not enough.
- Utility shelves, build/dev shelves, and trade panels need content-class sizing. Wide-short hosts need compact vertical metrics; narrow-short hosts need an overlay composition that preserves board scale.

Current repo answer:

- Lower rail and overlay shelf use bounded sizing rather than pure percentages.
- Utility shelves stay compact and content-only.
- Wide-but-short iPad hosts fall back to compact vertical metrics instead of oversized pad minima.
- The board and ocean resolve from live width and height as one canonical-aspect viewport. One uniform scale fits that viewport inside its region; temporary surfaces may overlay it, but they must not refit it, stretch either axis, or shift the island independently.
- UI centering assertions compare against extension-local anchors such as the mounted board, never the outer Messages window.
- `MessagesViewController` owns the live measurement. It publishes the first valid bounds immediately, suppresses intermediate values between Messages/UIKit transition callbacks, and commits one settled snapshot at completion. A measurement is valid only when bounds are finite and nonzero, all safe-area insets are finite and nonnegative, and their sums leave positive usable width and height. An invalid transition measurement cannot replace the last settled snapshot; the next valid size-only observation may settle normally after the 180 ms debounce. Measurements within one point are ignored.
- The edge-filling app background must be attached as a non-sizing SwiftUI background. It cannot be a root `ZStack` child with `ignoresSafeArea`, because that child can expand the root proposal after a Messages process reconstruction and move a valid manually inset canvas outside the controller frame. The settled usable-canvas accessibility frame must itself remain contained by the real Messages window.
- SwiftUI frames every product route inside the settled usable canvas. Internal navigation never republishes it. DEBUG evidence exposes the bounds, insets, usable size, profile, style, revision, local shell frame, and true `SKView` mount identity.
- Bottom placement reserves the missing amount toward the 12-point visual minimum plus one point of compositor-rounding allowance. A bottom safe area larger than that receives no added padding, so the established iPhone composition remains unchanged.

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
- Winning-only VP reveal checks must count every hidden VP card the player owns. The reducer still reveals one card per action, so tests need to cover multi-card winning reveals that proceed from 8 visible points to 9 and then 10.

Current repo answer:

- `Play Dev` now opens a card-oriented dev shelf.
- Knight, Monopoly, Year of Plenty, and Road Building stay action-driven from that card surface.
- Victory Point cards are visible to the owning player and only become revealable when the player's total hidden VP inventory can reach the winning threshold.

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
