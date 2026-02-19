# AGENT.md — Unlucky Sevens (Catan iMessage Game)

This repo is an iMessage-first, GamePigeon-style implementation of **standard Catan** called **Unlucky Sevens**. The game is fully playable asynchronously inside an iMessage group thread with **3–4 players**, end-to-end, with deterministic RNG and strict hand secrecy in the UI. Consult docs/UnluckySevensPRD.pdf only when changing gameplay rules, message protocol, or UX flows; otherwise rely on this file and docs/decisions.md.

---

## 1) North Star

### MVP goals
- Play **full standard Catan** in iMessage end-to-end (setup → win at 10 VP).
- Async turns, “bubble-first” UX (like GamePigeon).
- Deterministic RNG (seeded board + dice + any “random pick” like robber steal).
- Game state payload stays **≤ 64 KB per committed state**.
- UI secrecy: show opponents only **hand size**, not composition (even if state contains full hands).

### Explicit non-goals (for MVP)
- No GameKit / Game Center multiplayer.
- No backend/server persistence (thread is the “storage”; deleting the thread loses the game).
- No custom “twists” / house rules (later iteration).

---

## 2) Product decisions locked (do not change without an explicit request)

### Identity & roster
- Identity uses the iMessage conversation participants (no external accounts).
- Roster is **fixed at start**; join happens before Start.

### Turn authority model (critical)
- **Only the current player publishes canonical game state.**
- Non-current players are **read-only** except for accepting a current player’s trade offer.

### Two message types
1) **STATE bubble (authoritative)**
   - Canonical snapshot of the game at revision `rev`.
   - Must validate against previous state (`rev`, `prevHash`, roster, etc.).
2) **INTENT bubble (non-authoritative)**
   - A request anchored to a specific base state (e.g., trade accept).
   - INTENTs do nothing unless incorporated by the current player into a subsequent STATE.

### Trading rules (standard Catan behavior)
- Only current player can **propose** a trade.
- Other players can only send **Accept** intents.
- Current player decides which accept (if any) to execute.
- Trade offers expire at end of the current player’s turn.

### Timeout
- No timeout/force-advance in MVP.

---

## 3) Repo structure

Target structure (generated Xcode files are NOT committed):
```
App/                     # minimal host app required to run Messages extension
MessagesExtension/       # MSMessagesAppViewController + SwiftUI/SpriteKit UI
Packages/
  ULS_CoreGame/          # pure logic (rules, reducer, validation, determinism)
  ULS_Transport/         # encoding, hashing, compression, size guards
scripts/
docs/ 
  UnluckySevensPRD.pdf
CHANGELOG.md
AGENT.md
README.md
```

---

## 4) Tooling rules (Tuist + SwiftPM)

### Tuist
- Tuist manifests are the source of truth for targets/settings.
- Do **not** commit generated `.xcodeproj` / `.xcworkspace`.

### Swift packages
- `ULS_CoreGame` must stay **pure** (no UIKit, no Messages framework).
- `ULS_Transport` must stay **pure** (no UI), focused on encoding/decoding/hashing/compression.

---

## 5) Build / Run / Test

### Generate project
- `./scripts/gen.sh`  → runs `tuist generate`
- Open: `open UnluckySevens.xcworkspace`

### Run in Simulator
- Run the Messages extension scheme (or host app scheme if that is how Tuist wires it).
- In iOS Simulator → Messages → open any conversation → app drawer → Unlucky Sevens.

### Tests (must stay green)
- Always add/maintain tests in packages:
  - `ULS_TransportTests`: roundtrip encoding/decoding + size guards
  - `ULS_CoreGameTests`: determinism + rules validation

---

## 6) iMessage protocol constraints (must follow)

### Session strategy (prevents “bubble spam”)
- **One MSSession per game** for canonical STATE updates (so the state bubble appears as an updating thread).
- **New MSSession per trade offer** (so offers appear as distinct bubbles/cards).

### Validation & desync prevention
- Each STATE includes:
  - `gameId`, `rev`, `prevHash`, `stateHash`
  - `roster`, `currentPlayer`
- A new STATE is valid only if:
  - `rev == prior.rev + 1`
  - `prevHash == prior.stateHash`
  - roster unchanged
  - actor == `prior.currentPlayer`
- Each INTENT must include:
  - `baseRev` and/or `baseHash`
- INTENTs are only applied if anchored to the current canonical state (base hash matches).

### Payload size
- Canonical STATE payload must remain **≤ 64KB** (compressed if needed).
- Add regression tests that fail if payload exceeds target limits.

---

## 7) UI rules (hand secrecy + clarity)

### Hand secrecy
- Authoritative state may contain all hands for now, but:
  - UI must only show **opponent hand size** (total cards), not composition.
- Avoid any UI affordance that leaks opponents’ resources (icons, counts, tooltips).

### Rendering
- Board view can use SpriteKit for hex rendering and can generate a snapshot for bubbles.
- Build mode highlights legal nodes/edges.

### Audit log (spirit of the game)
- Default view: last turn recap only (short).
- Expandable: 1 round history.
- Dispute mode: full audit available but hidden behind deliberate action.

---

## 8) Game rules to implement (standard Catan, MVP)

### Setup
- 19 hex classic layout; robber starts on desert.
- Initial placement: 2 settlements + 2 roads in snake draft.
- Starting resources granted from 2nd settlement adjacent tiles.

### Turn structure
- Optional dev card play (1 per turn; cannot play same-turn purchase).
- Roll 2d6:
  - If 7: discard (>7 cards discard half), move robber, steal 1.
  - Else: distribute resources (cities=2, settlements=1), robber blocks production.
- Trade (players + bank/ports).
- Build (roads/settlements/cities/dev card).
- Win check: first to 10 VP on their turn wins immediately.

### Bank constraints
- Bank is finite; if a payout would exhaust a resource, nobody gets that resource and counts remain unchanged.

### Special awards
- Longest Road (≥5), Largest Army (≥3 knights), both worth +2 VP and can change owners.

---

## 9) Engineering workflow rules for agents (Codex, etc.)

### Small, testable tasks only
Every task MUST include:
- a user-visible deliverable (something you can tap in Messages)
- 1–3 unit tests
- a short manual QA script (5–10 steps)
- updated CHANGELOG entry under `[Unreleased]`

### Do NOT do these without being asked
- Large refactors
- Renaming public types across packages
- Introducing heavy dependencies
- Changing message protocol fields or validation rules

### Determinism is sacred
- Any “random” outcome must be derived from the game seed + deterministic indices.
- Add golden tests for sequences (dice rolls, dev draw order, robber steals).

### Definition of Done (for any PR/task)
- `tuist generate` succeeds
- app runs in iMessage simulator
- all package tests pass
- no generated Xcode files committed
- payload size guard tests pass

---

## 10) Future-proofing hooks (keep modular)
Design CoreGame/Transport so we can later add:
- signatures / anti-tamper (malice resistance)
- backend persistence / matchmaking
- house rules toggles (board “fairness” options, etc.)
