# Transport Reliability Plan — 2026-04-13

Follow-on to the render/perf audit at
[`2026-04-12-render-performance.md`](2026-04-12-render-performance.md).
This document is a forward-looking plan, not a retrospective audit, but
lives with the audits for discoverability alongside its predecessor.

## Problem statement

`MSMessage.url` is unreliable on real devices once payloads grow past a
size cliff (empirically ~1–2 KB, depending on iOS version and device
pair). When it fails, the current architecture falls through to
`MSMessage.summaryText` with a `ulsenv:` prefix
(`TranscriptTransportSupport.swift:130-148, 172-184`). This is a
**data leak**: `summaryText` is rendered by Messages as the user-facing
preview any time the extension fails to render the collapsed bubble —
on devices without the extension, in notification previews, in backups,
in accessibility readers, on the Mac Messages client under certain
conditions, and during the hydration race window on receive. In device
testing without this fallback, the primary `url` path itself frequently
fails for the same size-cliff reason. So today the system is either
leaky (with the fallback on) or broken (with it off).

## The channel inventory (honest version)

Earlier discussion floated `MSMessageTemplateLayout.mediaFileURL` as an
alternative. **This was wrong.** Per
`MSMessageTemplateLayout.h`, `mediaFileURL` accepts image, audio, or
video files only. Even if Messages preserved file bytes verbatim
(it does not — images in particular get transcoded), wrapping a binary
payload in an audio/image container is an API abuse that Apple could
break without notice. It's not a data channel.

Here is the complete set of fields available on `MSMessage` and
`MSMessageTemplateLayout`, and whether each can carry payload bytes:

| Field | Carries bytes? | Usable as data channel? |
|---|---|---|
| `MSMessage.url` | Yes | **Yes** — primary channel. Size-limited; reliability degrades past ~1–2 KB. |
| `MSMessage.summaryText` | Yes | **No** — user-visible preview. Leaks when extension can't render. |
| `MSSession` | ID only | No — grouping identifier, no payload capacity. |
| `MSMessageTemplateLayout.caption` | Text | No — user-visible. |
| `MSMessageTemplateLayout.subcaption` | Text | No — user-visible. |
| `MSMessageTemplateLayout.trailingCaption` | Text | No — user-visible. |
| `MSMessageTemplateLayout.imageTitle` | Text | No — user-visible. |
| `MSMessageTemplateLayout.imageSubtitle` | Text | No — user-visible. |
| `MSMessageTemplateLayout.image` | UIImage | No — Messages may transcode; steganography is not dependable. |
| `MSMessageTemplateLayout.mediaFileURL` | Media file | No — image/audio/video only per header. |
| `MSMessageLiveLayout` | Same fields | No additional channels. |

So: **one data channel, `MSMessage.url`.** Everything else is either
user-visible (leak risk) or not a data channel at all. The plan must
make STATE and INTENT payloads fit reliably inside `url`.

## Size targets

Based on known device behavior and the percent-encoding overhead of a
URL query param, the targets this plan commits to:

- **STATE payload, base64url-encoded, after envelope wrapping: < 900 bytes.**
  Under ~1 KB is the safe zone across every device I've seen.
  Target is aggressive on purpose; hitting 900 leaves headroom for
  iOS version drift.
- **INTENT payload: < 400 bytes.** Intents are already small;
  this is the ceiling, not a floor.
- **Bootstrap STATE (rev 0, rev 1): allowed up to ~3.5 KB.** These
  travel rarely — lobby invite and game start — and can be heavier.
- **P95 of all real gameplay STATE bubbles: < 700 bytes.**
  P99: < 900 bytes.

These targets are derived from "what reliably makes it across a real
iPhone ↔ iPhone pair on current iOS." They are falsifiable: Phase 1
below measures against them.

## Non-size failure modes

Size is the dominant reason `MSMessage.url` fails today, but it is not
the only one. Even when a payload fits comfortably under the cliff,
`url` can still be unreadable through several orthogonal pathways. The
plan must acknowledge these so nobody mistakes "payload fits" for
"guaranteed delivery" — the realistic ceiling after all phases ship is
~99%, not 100%, and the residual failures are all handled (or
explicitly not-handled) by specific mechanisms below.

### Transient — recoverable via polling and retry

These resolve themselves within a few seconds. The existing
`MessagesViewController.startSelectionPolling` (lines 86–105, with
delays 0.2/0.6/1.2/2.4s) is the mitigation and already works.

- **Hydration race on `didReceive` / `didSelect`.** Immediately after a
  lifecycle callback fires, `conversation.selectedMessage.url` can be
  `nil` while Messages finishes populating the `MSMessage` from its
  backing store. Happens independently of payload size.
- **Extension cold start.** Post-kill relaunches have a window where
  `activeConversation` is set but `selectedMessage.url` is not yet
  readable.
- **iCloud Messages sync delay.** Messages delivered via iCloud sync
  can appear in the transcript before the URL is readable on the
  receiving device. Usually sub-second, occasionally longer on
  cellular.
- **Send queue latency.** If the sender is offline at send time, the
  message queues. From the receiver's side this is a delay, not a
  failure — the URL is intact when it eventually arrives.

**Plan coverage:** existing polling. Consider extending the tail with
one additional poll at ~4.5s for older devices, but this is a minor
tweak, not a phase.

### Permanent on the wire — recoverable via local cache

These cannot be rescued from `url` itself on the affected bubble, but
the local cache from Phase 5 covers them because the state only needs
to be decoded once to be cached forever.

- **Messages DB pruning.** Old messages in long threads can have their
  `url` stripped as part of Messages' storage management. Exact
  trigger isn't authoritatively documented — reported around storage
  pressure and message age on the order of weeks. Permanent on that
  bubble; no polling recovers it.
- **iCloud backup/restore round-trip.** Messages restored from backup
  can lose `MSMessage` metadata in undocumented ways. Anecdotal but
  consistent across developer reports.

**Plan coverage:** Phase 5. Once a state has been decoded at least
once, it lives in the on-device cache and the pruned/restored bubble
never needs to be re-read.

### Hard boundary — cannot be recovered at the transport layer

- **SMS fallback.** If iMessage delivery fails and Messages falls back
  to SMS (green bubble), `MSMessage` metadata is stripped entirely.
  SMS carries no custom payloads. The extension has no way to read
  data from an SMS bubble at all. This is architectural, not a bug,
  and no amount of wire-format work changes it.

**Plan coverage:** Phase 7 below — detection + resync UX. The data
itself is unrecoverable; the mitigation is a user-visible prompt
asking the current player to re-send the latest STATE as a new
iMessage bubble.

### Known edge cases with partial mitigation

- **macOS Messages quirks.** Historically, `MSMessage` metadata
  behavior on macOS has diverged from iOS. Same content has been
  reported to decode on iPhone and fail on Mac. Improving in recent
  macOS versions but not zero.
- **Cross-version mismatches.** Very old iOS on one side of the thread
  can rarely drop or re-encode URLs.

**Plan coverage:** existing polling catches most of these; Phase 5
local cache catches the rest once a state has been decoded anywhere
in the player's device graph.

### Failure-mode → mitigation table

| Failure mode | Nature | Covered by |
|---|---|---|
| Payload size cliff | Wire | Phases 2–4 (compact board, delta, CBOR) |
| Hydration race | Transient | Existing polling |
| Extension cold start | Transient | Existing polling |
| iCloud sync delay | Transient | Existing polling |
| Send queue latency | Transient | Not a failure on the receiver side |
| DB pruning | Permanent on bubble | Phase 5 local cache |
| Backup/restore gaps | Permanent on bubble | Phase 5 local cache |
| SMS fallback | Hard boundary | Phase 7 (detection + resync UX) |
| macOS quirks | Edge case | Existing polling + Phase 5 |
| Cross-version drift | Edge case | Existing polling + Phase 5 |

## Execution plan

Each phase is independently shippable behind a feature flag and
produces a measurable improvement before the next phase begins. Do not
skip Phase 1 — you cannot optimize what you have not measured, and
intuition about payload sizes is almost always wrong.

---

### Phase 1 — Measure current state

**Goal:** establish a baseline before changing anything. Produce a
size distribution for every STATE and INTENT type under real gameplay.

**Work:**

1. Instrument `TranscriptTransportSupport.buildMessage`
   (`TranscriptTransportSupport.swift:108`) to log:
   - Envelope kind (`state` / `intent`)
   - Intent kind (if applicable)
   - `encodedEnvelope.count`
   - `urlString.count` (after percent-encoding)
   - Game phase (`lobby` / `setup` / `turn` / `gameOver`)
   - Rev number
2. Pipe the instrumentation into the existing `appendLog(_:)` path so
   it shows up in the debug HUD, and also `print` it in DEBUG builds.
3. Run a full playthrough against the simulator with three players.
   Run another against real-device pairing. Collect both logs.
4. Build a tiny histogram: min/max/p50/p95/p99 of
   `encodedEnvelope.count`, grouped by envelope kind. A spreadsheet
   is fine; no need for tooling.
5. Also log which STATEs failed to decode via `url` on receive and
   fell through to the `summaryText` fallback (already tracked via
   `selectedDecodeSource`). Correlate failures to sizes.

**Acceptance:**

- Baseline histogram committed to
  `docs/quality/audits/2026-04-13-transport-baseline.md` (this file's
  sibling). Include the empirical size cliff for the tested device pair.
- Clear identification of which STATE types currently exceed the
  targets above.

**Effort:** half a day, no production code changes, no risk.

---

### Phase 2 — Stop retransmitting the immutable board

**Goal:** remove the single biggest redundant contributor to STATE
size.

The board (`resourcesByTile`, `numbersByTile`, `portsByIndex`,
`boardRules`) is frozen at rev 1 and never mutates. Only `robberTile`
changes after that, and it's a single integer. Today, the full board
is serialized into every STATE via `CoreGameStateV1.board`.

**Work:**

1. Add a `BoardSnapshot` struct that holds the immutable fields and a
   method to compute a stable hash from them
   (`boardHash` already exists — reuse it).
2. In the sender path, build a new `CompactBoardV1`:
   ```swift
   struct CompactBoardV1: Codable {
       let boardHash: String   // identifies which snapshot to use
       let robberTile: TileID  // the only mutable piece
       // omit resourcesByTile, numbersByTile, portsByIndex, boardRules
   }
   ```
   and serialize this in the wire format instead of the full board.
3. On the receiver side, the `BoardSnapshot` is materialized once per
   game and cached keyed on `boardHash`. First time a `boardHash` is
   seen that isn't cached, the receiver walks the transcript backward
   looking for a STATE with a full board (the rev-1 `lobbyStart`
   STATE always has one). Record it.
4. Keep the wire payload for rev 1 full-fat — it's the bootstrap.
5. Add a version bump to the envelope so old clients don't
   misinterpret compact boards.

**Expected savings:** 30–40% of STATE payload bytes. `resourcesByTile`
and `numbersByTile` alone are ~19 entries each, serialized as JSON with
full field names and string enums — that's easily 400+ bytes before
any compression.

**Acceptance:**

- Phase 1 histogram re-run shows STATE P50 drops by ≥ 25%.
- Existing tests green. Add one new test:
  `CoreGameKernelV1Tests.testCompactBoardRoundtrip`.

**Risks:**

- A receiver that joins a game mid-stream and never saw rev 1 has no
  cached snapshot. Mitigation: fall back to full-state walk-back
  (transcript walk), and if even that fails, display a "resync
  required" bubble that the current player taps to re-send a full
  state bootstrap.

**Effort:** 2–3 days.

---

### Phase 3 — Delta-encode STATE against `prevHash`

**Goal:** STATE bubbles carry only what changed since the previous
anchor, not the full post-image.

STATE is already anchored to a previous state via `prevHash`. Instead
of serializing the full post-state, serialize the diff from the
pre-state to the post-state.

**Work:**

1. Define `StateDeltaV1` as a tagged union of minimal change
   descriptions:
   ```swift
   enum StateDeltaV1: Codable {
       case setPhase(PhaseV1)
       case setCurrentPlayer(String)
       case setRobberTile(TileID)
       case addSettlement(NodeID, owner: String)
       case addCity(NodeID, owner: String)
       case addRoad(EdgeID, owner: String)
       case setResources(player: String, ResourceHandV1)
       case appendAuditEntry(AuditEntryV1)
       case setTurnState(TurnStateV1)
       // … one case per mutable state field
   }
   ```
2. Add `CoreGameReducerV1.diff(from: CoreGameStateV1, to: CoreGameStateV1) -> [StateDeltaV1]`
   that produces the minimal list of deltas needed to reach `to` from
   `from`. This is already implicitly computed by the turn reducer —
   the reducer knows what it just changed. Extend the reducer to
   return its deltas alongside the new state.
3. On the wire, STATE becomes:
   ```swift
   struct StateEnvelopeV2 {
       let gameId: String
       let rev: Int
       let prevHash: String
       let stateHash: String
       let deltas: [StateDeltaV1]  // diff from prevHash
   }
   ```
4. On receive, the receiver:
   a. Looks up `prevHash` in the local cache (Phase 5 — must ship
      together).
   b. Applies `deltas` to the cached base state.
   c. Verifies the resulting state hashes to `stateHash`.
   d. Stores the new state in the cache.
5. If the base state isn't in the cache, walk back through the
   transcript applying earlier deltas until a cached base or a
   full-state bootstrap is found.

**Expected savings:** additional 50–70% on top of Phase 2. A typical
turn changes 2–4 fields (resources, audit log entry, turn step,
maybe a built piece). At ~30 bytes per delta entry, a turn STATE is
roughly 150 bytes of payload + envelope overhead.

**Acceptance:**

- STATE P95 under 600 bytes in the Phase 1 histogram re-run.
- New test:
  `CoreGameKernelV1Tests.testDeltaRoundtripAcrossFullPlaythrough` —
  generates a random playthrough, delta-encodes each transition,
  applies deltas on a cold receiver, asserts final states match.
- Existing evals pass without modification.

**Risks:**

- Delta application bugs produce divergent state that still hash-matches
  only because both sides applied the same wrong delta. Mitigation:
  ship a "full state check" debug mode that re-serializes and
  re-hashes the reconstructed state and compares against `stateHash`.
  This is cheap enough to leave on in production.
- Receivers with no cached base and a short transcript (< rev 1
  visible) are stuck. Mitigation: always ship full state for rev 0
  and rev 1 (bootstrap), and ship a full "keyframe" STATE every 10
  revs so receivers only need to walk back at most 10 bubbles.

**Effort:** 4–6 days. Biggest single-phase effort in this plan.

---

### Phase 4 — Binary codec (CBOR)

**Goal:** replace JSON serialization with a packed binary format to
recover another 30–50% per payload.

JSON is paying for field names on every object, spaces, quotes, and
verbose enum representations. CBOR uses one-byte type tags and
integer-indexed map keys.

**Work:**

1. Add CBOR support to `ULS_Transport`. Swift has several
   implementations; `PotentCodables` or a hand-rolled encoder works.
   Target: CBOR with integer keys, not string keys, for the main
   state fields.
2. Wire envelope becomes CBOR bytes rather than JSON. The wrapping
   base64url encoding stays the same since URLs need ASCII.
3. Version bump: `EnvelopeV2` uses CBOR; `EnvelopeV1` stays on JSON
   for backward compat with old bubbles in existing transcripts.
4. Add an `EnvelopeCodec` that transparently decodes both V1 and V2
   so receivers can read historical bubbles from before the upgrade.

**Expected savings:** additional 30–50% on top of Phase 3. A
150-byte JSON delta payload becomes roughly 80 bytes of CBOR after
base64url encoding.

**Acceptance:**

- STATE P95 under 350 bytes, P99 under 500 bytes.
- INTENT P95 under 200 bytes.
- Codec round-trip tests for every payload type.
- Backward compat tests: ability to decode a saved V1 envelope into
  the current state type.

**Risks:**

- CBOR integer-keyed maps are fragile to re-add a field in the middle.
  Establish a numbering convention (no-reuse, append-only) and
  document it in `docs/decisions.md`.
- Base64url overhead still applies on top of CBOR since URLs require
  ASCII. That's ~33% bloat over raw bytes. Budget accordingly.

**Effort:** 3–4 days.

---

### Phase 5 — Local state cache (Caches/ directory)

**Goal:** persistent local cache that (a) supports delta application
in Phase 3 and (b) survives extension relaunches for instant
responsiveness.

**Work:**

1. Promote the in-memory `latestKnownStatesByGameId: [String: CoreGameStateV1]`
   (`LobbyDriverViewModel.swift:54`) to a persistent store.
2. Storage layout under `FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)`:
   ```
   Caches/uls-games/
     <gameId>/
       latest.cbor           // Phase 4 codec
       bootstrap.cbor        // rev 1 full state (for delta walk-back)
       keyframe-<rev>.cbor   // periodic keyframes, Phase 3
   ```
3. On extension launch, pre-warm `latestKnownStatesByGameId` from
   disk. No blocking I/O on main — launch is async.
4. On every decoded STATE, update the cache. Cache write is
   fire-and-forget on a background queue; failures are logged, not
   surfaced.
5. Turn on `allowsCachedPublishedStateRecovery`
   (`LobbyDriverViewModel.swift:46`) which is currently hardcoded
   `false`. The TTL (600s) and key (`uls.lastPublishedState`) are
   already there; just flip the flag.
6. Add a cache-eviction policy: keep the 20 most recently touched
   games, evict older ones. `Caches/` is allowed to be purged by
   iOS under disk pressure, so the on-device cache is opportunistic
   by design.
7. Purge hook: `clearActiveContext` should wipe the cached entry for
   the current game.

**Expected impact:** not a payload-size win, but a **responsiveness**
win — extension relaunches become instant, and Phase 3 is dependent
on this landing first.

**Acceptance:**

- Extension relaunch during a game restores the shell view
  immediately (< 100 ms), without waiting for Messages to re-hydrate
  the selected bubble.
- Cache survives a device reboot.
- Cache is evicted on `clearActiveContext`.
- No main-thread I/O.

**Risks:**

- Cache poisoning if a bad decode writes garbage. Mitigation:
  always verify the cached state round-trips its own hash before
  trusting it on load.
- `Caches/` can be purged by iOS. This is fine — bootstrap from
  transcript walk-back is still available as the authoritative
  rebuild path.

**Effort:** 2 days.

---

### Phase 6 — Delete the `summaryText` fallback

**Goal:** remove the data leak surface entirely.

**2026-04-16 status:**

- Fresh publishes no longer mirror payload bytes into `summaryText`.
- Legacy mirrored-summary decode is still enabled for backward compatibility with already-sent transcript bubbles.
- The remaining work in this phase is to remove that incoming compatibility path after repeated real-device evidence shows URL-only publication is stable enough.

**Work:**

1. After Phases 1–5 ship and Phase 1's histogram re-run confirms
   STATE P99 is under the 900-byte target and `url`-path success rate
   on real device is ≥ 99%, delete the remaining incoming summary
   fallback decode path entirely. Fresh sends already publish without
   mirrored summary payloads; the remaining compatibility flag is the
   incoming decode path in `LobbyDriverViewModel`.
2. Delete the `summaryFallback` case from `TranscriptPayloadSource`
   (`TranscriptTransportSupport.swift:19`).
3. Delete `mirroredPayloadValue(from:summaryPayloadPrefix:)`
   (`TranscriptTransportSupport.swift:242`).
4. Delete the `includeSummaryPayloadMirror` parameter from
   `TranscriptTransportSupport.buildMessage`
   (`TranscriptTransportSupport.swift:108`).
5. Replace `summaryText` with a plain human caption per envelope
   kind:
   - `"Kunal's turn · rolled 8"` for STATE bubbles on turns
   - `"Kunal joined the game"` for join intents
   - `"Kunal ended their turn"` for end-turn STATEs
   - etc.
6. Set `summaryPayloadPrefix` to a value that is not recognized as
   a decode source at all — or just remove it. The summary is now
   purely presentational.

**Acceptance:**

- Manual verification: install the app on a test device, start a
  game, uninstall the extension on a second test device, verify the
  second device sees only the human-readable caption (no `ulsenv:`
  prefix, no base64 blob).
- Real-device playthrough reports zero `summaryFallback` decode
  sources.

**Risks:**

- Phase 6 must not ship before Phase 1 proves the `url` path is
  reliable enough. If payload sizes are still flaky, deleting the
  fallback breaks the game. Treat Phase 6 as gated on a successful
  Phase 1 re-run.

**Effort:** 1 day.

---

### Phase 7 — SMS-fallback detection and resync UX

**Goal:** handle the one failure mode that cannot be fixed at the wire
level. When Messages silently falls back to SMS, `MSMessage` metadata
is stripped entirely, so the receiving extension has zero bytes to
work with on that bubble. The data itself is unrecoverable — the only
meaningful response is to tell the user and make it cheap for the
current player to re-send the latest STATE.

This is a small-surface-area phase, but it closes the last hole in the
reliability story. It ships after Phase 6.

**Work:**

1. **Classify unrecoverable bubbles.** Extend
   `TranscriptTransportSupport.selectionSnapshot` to detect the
   "bubble present, but no decodable envelope after full polling +
   walk-back" state. Inputs:
   - `message != nil`
   - `message.url` is `nil` or produces no `payload` query item
   - Phase 5 transcript walk-back finds no ancestor STATE to replay
     from
   - The extension is not mid-hydration (polling window is exhausted)

   When all four hold, mark the bubble as
   `TranscriptDecodedPayload.source = .unrecoverable` (new enum case).
   Do not guess SMS specifically — any bubble that reaches this state
   is functionally equivalent.

2. **Render a recovery hint in the shell.** When the active context
   resolves to `.unrecoverable`, show a small banner in
   `GameShellView` above the board:
   > This message didn't come through. Ask **\<current player\>** to
   > re-send the latest update.

   Use `PlayerPseudonymResolver` for the display name, and key the
   banner off `selectedState == nil && selectionStatus == "unrecoverable"`
   so it doesn't flash during the normal hydration race.

3. **Cheap re-send path for the current player.** In
   `LobbyDriverViewModel`, expose a `resendLatestState()` action that:
   - Reads the most recent STATE from the local cache for the
     current `gameId` (Phase 5).
   - Re-publishes it as a brand new iMessage bubble with a fresh
     `MSSession`.
   - Captions the new bubble with `"Resent: \<phase\> rev\<N\>"` so
     players can distinguish it from the original send.

   This is available only if `actingAs == state.currentPlayer`, since
   STATE authority is unchanged (documented in "Out of scope").

4. **Opportunistic prompt for the current player.** If the local
   player opens a game where the latest bubble they can see is stale
   relative to the cached state (which happens when a teammate's
   resend request reaches them), show the same banner with a
   "Resend latest" button that calls `resendLatestState()`.

5. **Telemetry.** Add an `unrecoverable` decode source count to the
   debug HUD so you can track how often SMS fallback (or equivalent
   permanent failures) actually happens in practice. This feeds into
   the post-ship reality check on the Phase 6 acceptance criterion.

**Acceptance:**

- Manual test: put the sending device in Airplane Mode with SMS
  fallback enabled, send a STATE over SMS (green bubble on receiver),
  verify the receiving extension shows the "didn't come through"
  banner instead of a blank shell.
- Unit test: `TranscriptSelectionTests.testUnrecoverableClassification`
  exercises the four conditions above.
- Resend action round-trips: receiving player sees the re-sent state
  with identical `stateHash` as the original.
- Zero false positives: the banner does not appear during the normal
  hydration polling window (0.2s–2.4s).

**Risks:**

- **Over-eager classification.** If the polling window is too short,
  the banner flashes during normal hydration. Mitigation: only
  classify as `.unrecoverable` after the full poll sequence exhausts
  without finding a decodable envelope.
- **Resend collision.** Two players both tap resend within the same
  second. The receivers will see two identical STATEs in the
  transcript. Not a correctness problem — both decode to the same
  `stateHash` and the game logic idempotently applies them — but
  visually noisy. Mitigation: debounce the resend button for 5
  seconds after a send.
- **SMS is silent from the sender's perspective.** The sender's
  extension has no signal that its iMessage failed and fell back to
  SMS. They see a normal send. Mitigation: the recovery flow is
  receiver-initiated, not sender-initiated. The sender only acts
  when asked.

**Effort:** 2 days.

---

## Out of scope

To keep this plan focused, the following are explicitly deferred:

- **Authority model changes.** STATE publication stays current-player-only.
- **Hash chain semantics.** `prevHash` → `stateHash` linking is unchanged.
- **Moving to a backend.** The no-backend constraint from
  `docs/decisions.md` is preserved.
- **Visual bubble redesign.** The plan says nothing about what the
  rendered bubble should look like — that's a UI pass, not a
  transport pass. Rendering the board snapshot into `layout.image`
  for a nicer collapsed bubble is a separate (and worthwhile)
  improvement.
- **Intent payload optimization beyond Phase 4.** Intents are already
  small; further tightening is not worth the risk.

## Acceptance criteria for the full plan

When all seven phases have shipped, the following must hold on real
devices for a full playthrough with three players:

1. **≥ 99% of STATE messages decode via `url` on first tap** (Phase 1
   instrumentation proves this). The remaining ~1% is the residual
   pool from the non-size failure modes — primarily DB pruning,
   backup/restore gaps, and SMS fallback — and is explicitly handled
   by Phases 5 and 7 rather than by further wire shrinkage.
2. **STATE P99 encoded envelope size < 900 bytes.**
3. **Zero occurrences of `summaryFallback` in decode source logs.**
4. **Zero `ulsenv:` strings visible in message previews on any
   device, including devices without the extension installed.**
5. **Extension relaunch mid-game restores the shell view in under
   100 ms.**
6. **Unrecoverable bubbles surface a resync banner within one polling
   cycle, and the current player's re-send action round-trips to the
   identical `stateHash` as the original.**
7. **Full existing test suite green.**
8. **New tests added per phase are green.**

Note that 100% reliability is explicitly not a target and is not
achievable at the transport layer. See "Non-size failure modes" above
for the failure taxonomy and which phase handles each.

## Rollout order and dependencies

```
Phase 1 (measure) ──┬──▶ Phase 2 (immutable board)
                    │
                    └──▶ Phase 5 (local cache) ──┬──▶ Phase 3 (delta encoding)
                                                 │              │
                                                 │              ▼
                                                 │       Phase 4 (CBOR)
                                                 │              │
                                                 │              ▼
                                                 │       Phase 6 (delete fallback)
                                                 │              │
                                                 │              ▼
                                                 └────▶ Phase 7 (SMS-fallback UX)
```

- Phase 1 gates everything (establish baseline).
- Phase 2 is independent of Phases 3–4 and can ship first for an
  early win.
- Phase 5 must ship before Phase 3 (delta application needs the
  cached base state) and before Phase 7 (resend action reads from
  the cache).
- Phase 4 should ship after Phase 3 because the delta format is
  what the binary codec is encoding; shipping CBOR on fat JSON
  states wastes the churn.
- Phase 6 gates on a successful Phase 1 re-run after Phases 2–4.
- Phase 7 ships after Phase 6 because `.unrecoverable` classification
  is cleaner once the `summaryText` fallback is gone — otherwise
  every currently-flaky bubble would spuriously classify as
  unrecoverable before falling through to the summary decode path.

## Commitments the plan makes explicit

- **`MSMessage.url` is the only data channel.** No stenography
  through layout fields. No API abuse of `mediaFileURL`. No
  `summaryText` payloads.
- **Local cache is a supporting pillar, not a replacement for
  transport.** It makes delta encoding viable and covers the
  permanent-on-wire failure modes (DB pruning, backup/restore), but
  it does not transmit state between devices.
- **100% reliability is not a target.** Size failures get fixed in
  Phases 2–4; transient races are handled by existing polling;
  permanent-on-bubble failures are handled by the Phase 5 cache; SMS
  fallback is handled by the Phase 7 resync UX. Anything the plan
  cannot fix in those four categories is architectural to Messages
  itself and out of reach of any wire-format change.
- **Measurement gates every optimization.** No guessing at payload
  sizes. Phase 1 proves the baseline and every subsequent phase
  re-measures.
- **Backward compat during rollout.** V1 envelopes still decode.
  New clients speak V2 on send; receivers speak both on receive for
  the full lifetime of any transcripts that contain V1 bubbles.

---

*Author: Claude (Opus 4.6, 1M context). No code changes were made as
part of this plan. Implementation should track progress against each
phase's acceptance criteria before moving to the next.*
