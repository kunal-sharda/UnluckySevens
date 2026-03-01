# Decisions (Locked) — Unlucky Sevens

This file records **locked product + architecture decisions** for the MVP.  
If a change is desired, update this file **first**, then update code/tests.

**Last updated:** 2026-03-01

---

## 1) Product scope

- MVP is **full standard Catan** (base game) inside iMessage: setup → normal turns → win at 10 VP.
- No custom “twists” or house rules in MVP (twists come later).
- Platform: iOS + iPadOS (Messages).

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
- **Only the current player may publish STATE updates.**
- Non-current players:
  - Can view the game and their own hand.
  - Can only send INTENTs relevant to the current player’s proposals (see trading).

---

## 4) Trading (standard Catan rules)

- Only the **current player** can:
  - Propose trades.
  - Execute/accept trades (by incorporating them into a STATE update).
- Other players may only send **Accept** intents to a current-player offer.
- Counteroffers are handled in chat (group conversation), not in-game UI.
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

- **One `MSSession` per game** for canonical STATE messages (updates collapse / thread clean).
- **Separate `MSSession` per trade offer** so offers appear as distinct bubbles/cards.

Simulator debug decode fallback:
- Canonical transport source is always message URL query `payload`.
- `summaryText` is not canonical protocol data.
- For local simulator reliability only, `summaryText` may mirror payload in `DEBUG + simulator` builds and be used as explicit fallback.
- UI must label payload source (`URL` vs `summary fallback`) during decode so fallback use is visible.

---

## 9) Payload size budget

- Canonical STATE payload must stay **≤ 64KB** (compressed if needed).
- Add automated tests/guards to prevent regressions that exceed budget.

---

## 10) Audit log UX (spirit of the game)

- Default UI shows **last turn recap only** (short).
- Collapsible view shows **one round** of history.
- Full audit log exists for dispute resolution but is hidden behind deliberate action (“Dispute mode”).
