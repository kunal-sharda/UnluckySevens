# Decisions (Locked) — Unlucky Sevens

This file records **locked product + architecture decisions** for the MVP.  
If a change is desired, update this file **first**, then update code/tests.

**Last updated:** 2026-04-17

---

## 1) Product scope and packaging

- MVP is **full standard Catan** (base game) inside iMessage: setup → normal turns → win at 10 VP.
- No custom “twists” or house rules in MVP (twists come later).
- Platform: iOS + iPadOS (Messages).
- Product distribution target: **standalone iMessage app**.
- The current repo may still carry a minimal containing-app shell for development or transitional project-shape reasons, but the intended shipped product is **only accessible within Messages**.

---

## 2) Multiplayer & persistence

- **No GameKit** (no Game Center / GKTurnBasedMatch).
- **No backend** for MVP. The iMessage thread is the “storage.”
- If the message thread is deleted, the game is effectively lost (acceptable for MVP).
- **Fixed roster** at game start: host invites → players join → host starts → roster locks.

---

## 3) Authority model (anti-desync)

- Two message types:
  - **STATE**: authoritative snapshot (canonical truth).
  - **INTENT**: non-authoritative request anchored to a specific base state.
- The lobby is part of the canonical game timeline:
  - invite/start/join all progress through canonical lobby `STATE` updates on the game session
  - joining is not a detached draft flow or side intent in fresh publishes
- During active gameplay, the **current player** publishes canonical `STATE` for normal turn actions.
- Non-current players:
  - can view the game and their own hand
  - may only send responder-side messages for flows that cannot safely publish canonical gameplay state directly
  - fresh responder-side trade/discard messages stay internal transport, not player-facing protocol
- Legacy join/trade responder `INTENT` decode remains supported only for backward transcript compatibility and bridge recovery.

---

## 4) Trading (standard Catan rules)

- Only the **current player** can:
  - Propose trades.
  - Replace or withdraw the current live player-trade offer.
- Targeted responder actions may be **Accept**, **Decline**, or **Counter**.
- Trade-response messages are still internal responder transport, but normal product UX must not expose a manual "apply selected response" step.
- When the current-player device incorporates a surfaced trade response into canonical `STATE`, the response must validate as the **responding player's action**, not as a synthetic current-player action. The current-player device is the publisher, but the response actor stays the responder for rules/audit semantics.
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

- **One `MSSession` per game** for canonical `STATE` messages across lobby, setup, turn play, and game over (updates collapse / thread clean).
- Fresh lobby joins publish updated lobby `STATE` on that same canonical game session.
- Responder-side non-canonical messages such as trade/discard transport must **not** ride the canonical game `MSSession`, because they can displace the live state bubble without replacing it with authoritative state.

Current transition rule:
- Preferred transport source is always message URL query `payload`.
- Legacy transcript recovery may still decode mirrored payloads from older `summaryText` values, but fresh publishes are URL-only again after the `https` scheme fix.
- Sender-side cached last-published state may smooth same-device reopen UX when transcript selection drops to `nil`, but it is never cross-device authority and must not replace transcript transport.
- UI must label payload source (`URL` vs `summary fallback`) during decode so fallback use is visible.
- Phase 13 owns proving that URL-only publication is stable enough on hardware to retire the remaining legacy summary decode bridge entirely.

---

## 9) Payload size budget

- Canonical STATE payload must stay **≤ 64KB** (compressed if needed).
- Add automated tests/guards to prevent regressions that exceed budget.

---

## 10) Audit log UX (spirit of the game)

- Default UI shows **last turn recap only** (short).
- Collapsible view shows **one round** of history.
- Full audit log exists for dispute resolution but is hidden behind deliberate action (“Dispute mode”).
