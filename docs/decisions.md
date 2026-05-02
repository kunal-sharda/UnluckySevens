# Decisions (Locked) — Unlucky Sevens

This file records **locked product + architecture decisions** for the MVP.  
If a change is desired, update this file **first**, then update code/tests.

**Last updated:** 2026-05-01

---

## 1) Product scope and packaging

- MVP is **full standard Catan** (base game) inside iMessage: setup → normal turns → win at 10 VP.
- No custom “twists” or house rules in MVP (twists come later).
- Platform: iOS + iPadOS (Messages).
- Product distribution target: **standalone iMessage app**.
- The shipped/generated app target is resource-only and patched after Tuist generation to Apple's standalone Messages-only product type (`com.apple.product-type.application.messages`). The playable surface remains **only accessible within Messages**.

---

## 2) Multiplayer & persistence

- **No GameKit** (no Game Center / GKTurnBasedMatch).
- **No backend** for MVP. The iMessage thread is the “storage.”
- If the message thread is deleted, the game is effectively lost (acceptable for MVP).
- **Fixed roster** at game start: host invites → players join → host starts → roster locks.

---

## 3) Authority model (anti-desync)

- Shipped transcript/runtime is **STATE-only**:
  - **STATE**: authoritative snapshot (canonical truth).
  - Reducer intents are internal engine inputs only. Fresh player-facing transcript flow must not depend on action bubbles.
- The lobby is part of the canonical game timeline:
  - invite/start/join all progress through canonical lobby `STATE` updates on the game session
  - joining is not a detached draft flow or side intent in fresh publishes
- During active gameplay, the **current player** publishes canonical `STATE` for normal turn actions.
- Non-current players:
  - can view the game and their own hand
  - may publish canonical `STATE` directly for rules-defined responder actions that do not advance turn ownership
  - forced discard and targeted trade responses validate as the **responding player's** action while `currentPlayer` stays on the turn owner
- Pre-TestFlight legacy join/setup/current-player transcript intents are intentionally unsupported in the app runtime. The compatibility boundary starts with TestFlight builds, not earlier dev-era transcripts.

---

## 4) Trading (standard Catan rules)

- Only the **current player** can:
  - Propose trades.
  - Replace or withdraw the current live player-trade offer.
- Targeted responder actions may be **Accept**, **Decline**, or **Counter**.
- Fresh targeted trade responses publish canonical `STATE` directly from the responding device; normal product UX must not expose a manual "apply selected response" step.
- Trade-response transitions must validate as the **responding player's action**, not as a synthetic current-player action. The current player remains the turn owner, but the response actor stays the responder for rules/audit semantics.
- `acceptTrade` is the only trade-resolution intent. There is no separate `executeTrade` or current-player commit step.
- Player-trade offers may target any non-empty subset of opponents.
- Non-targeted players may still inspect the live offer read-only in the group thread and shell.
- The first applied **Accept** from a targeted player resolves the trade atomically and closes the offer.
- If every targeted player **Declines**, the offer closes without a trade.
- **Counter** responses stay visible to the current player but do not auto-execute the original offer.
- Trade offers **expire at end of the current player’s turn.**
- Default: **only one active offer at a time** (current player can cancel/replace).

---

## 5) Turn flow

- Explicit “End Turn” button; no auto-advance.
- **No timeout / force-advance** in MVP (social enforcement; game may stall).
- During a `7` discard round, each required discarder publishes one canonical `STATE` in locked roster order while `currentPlayer` stays unchanged. Robber movement stays blocked until the discard queue is empty.

Recommended canonical state cadence per turn:
- STATE update after roll (so others can see results and decide on trades).
- STATE update at end turn (commit builds/trades/dev cards and advance player).

---

## 6) Determinism & randomness

- Deterministic RNG with a shared **seed**.
- Dice, dev deck order, robber steals, and any other random selections must be derived from (seed + deterministic indices).
- Do not use `Date()`, system RNG, or device-local randomness for game outcomes.

---

## 7) Hidden information & secrecy

- Authoritative state **may contain all hands** for MVP (friends-only assumption).
- UI must **only show opponent hand size**, never opponent card composition.
- Avoid UI leaks (resource icons/counts, tooltips, debug screens) that reveal opponents’ hands.

---

## 8) Message sessions (GamePigeon-style UX)

- **One `MSSession` per game** for canonical `STATE` messages across lobby, setup, turn play, forced discard, targeted trade responses, and game over (updates collapse / thread clean).
- Fresh lobby joins publish updated lobby `STATE` on that same canonical game session.
- Fresh current-player gameplay actions publish updated canonical `STATE` on that same canonical game session.
- Fresh forced-discard and targeted trade-response publishes also stay on that same canonical game session so the game transcript remains one thread.
- If the shell can recover canonical `STATE` for a game, it should prefer recovered game state over any raw responder artifact or stale transcript selection.

Current transition rule:
- Preferred transport source is always message URL query `payload`.
- Fresh publishes are URL-only after the `https` scheme fix.
- The app runtime no longer decodes mirrored payloads from `summaryText`; pre-TestFlight dev transcripts that depended on that bridge are intentionally unsupported after the phase-13 cleanup.
- Sender-side cached last-published state may smooth same-device reopen UX when transcript selection drops to `nil`, but it is never cross-device authority and must not replace transcript transport.
- Payload-source diagnostics and transport debug surfaces are intentionally removed from the shipped player shell on the pre-TestFlight branch.

---

## 9) Payload size budget

- Canonical STATE payload must stay **≤ 64KB** (compressed if needed).
- Add automated tests/guards to prevent regressions that exceed budget.

---

## 10) Audit log UX (spirit of the game)

- Default UI shows **last turn recap only** (short).
- Collapsible view shows **one round** of history.
- Full audit log exists for dispute resolution but is hidden behind deliberate action (“Dispute mode”).
