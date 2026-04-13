# UI Flows

This document summarizes the player-facing flows the UI must support in the current product direction.

## Lobby Flow

- A player starts a game from Messages and sends an invite/game-state bubble into a thread.
- Other players join before the host starts.
- Joining should feel like a game action, not a draft-composition flow. A player should not need an extra manual send step after choosing `Join`.
- The host sees the current joined roster in the lobby UI and explicitly starts the game when ready.
- The roster locks when the host starts the game.
- Lobby UX should preserve the current authority model:
  - one invite `STATE`
  - join `INTENT`s
  - one host-published start `STATE`

## Setup Flow

- Players place two settlement-road pairs in snake order.
- The second completed placement grants starting resources from adjacent non-desert tiles.
- The UI must make placement order and legality legible without inventing setup rules locally.
- Setup should feel guided and blocking: the player should always know whether the next action is settlement placement or road placement.
- Setup and build placement should be selection-first rather than one-tap publish:
  - first tap selects a legal node or edge
  - the player can confirm from a compact confirm surface or by tapping the same selected target again
  - tapping a different legal target changes the selection instead of publishing immediately

## Turn Flow

- Optional non-VP dev-card play before or after the roll, subject to core timing rules and never for a non-VP card bought on the same turn.
- Victory Point cards stay hidden unless revealing them would immediately win the game.
- Roll.
- Resolve either production or the full seven/robber subflow.
- Optionally trade, build, buy or play allowed dev cards, and then end turn.
- The default shell should read as:
  - header
  - board
  - handle band
  - dock
- The fixed shell height targets are:
  - header `12%`
  - board `70%`
  - dock region `18%`
- Within the dock region:
  - handle band `6%`
  - dock row `12%`
- The lower shelf should be an overlay, not a layout reflow:
  - total shelf height `18%`
  - visible in lower rail `6%`
  - overlap into the board `12%`
- The primary dock order should stay shallow and predictable:
  - `Roll`
  - `End Turn`
  - `Build`
  - `Play Dev`
- The collapsed lower rail should show only:
  - a small centered pull-tab / chevron in the handle band
  - the four dock actions in the dock row
- Only one lower shelf should be open at a time.
- Opening the pull-tab should reveal a compact shelf header with:
  - `Hand`
  - `Bank`
  - `Players`
  - close chevron
- `Hand`, `Bank`, and `Players` utility shelves should be content-only. They should not repeat inner section titles or subtitles once the shelf header is visible.
- `Hand`, `Bank`, and `Players` utility shelves should not scroll in the normal case.
- `Build` opens a compact shelf for legal build/buy actions such as road, settlement, city, and dev-card purchase.
- `Build` and `Play Dev` should use the same overlay shelf surface as the utility entry path.
- `Trade` should be entered from the `Hand` shelf, not from the persistent dock.
- The `Hand` shelf should show the five resource chips first and a full-width `Trade` action row directly below them when trade is currently available.
- The bank should be quickly accessible rather than always expanded. Its full public counts for wood, brick, sheep, wheat, and ore should live in the `Bank` shelf and become interactive only for Monopoly and Year of Plenty.
- The bank should reuse the same five-chip visual format as the hand in normal viewing, adding only minimal selection decoration during Monopoly or Year of Plenty.
- Opponent summaries should be shelf-only rather than always visible in the main shell.
- Dev-card actions should be choice-driven for Knight, Monopoly, Year of Plenty, and Road Building rather than expanding into a deep form flow or hiding behind defaults.
- Knight should stage through robber-tile choice first and only ask for an explicit victim when the chosen tile has multiple eligible steals.
- Guided board flows should use a compact bottom-center in-board hint pill rather than a large floating HUD card.
- The hint pill should be single-line by default and shift upward when the overlay shelf is open so it never sits inside the shelf overlap zone.
- The only valid overlap in the shell is the deliberate shelf-over-board overlay at the bottom edge. Utility tabs, dock buttons, board chrome, and content regions must otherwise stack without collision or wrapping.
- If the active player reaches the win threshold on their turn, the game ends immediately.
- Forced subflows such as discard and robber movement should feel blocking rather than like optional side actions.

## Trade Flow

- The current player enters trade from the `Hand` shelf.
- The current player sees a compact trade surface with suggested player-trade and maritime-trade actions.
- Other players can respond through accept-style intent bubbles.
- The current player can apply a selected accept-intent bubble and execute with the accepted players before end turn.
- Bank and port trades should feel distinct from player-to-player trade offers.
- Pending trade state should stay legible from the shell and later bubble copy rather than disappearing into a deep modal.
- The shell should keep trade status visible while the offer is pending.

## Audit and Game-Over Flow

- Minimum end-of-game clarity in the default shell should show:
  - the winner clearly
  - a compact final score summary
  - a short last-turn recap when available
- One round of history should be available without overwhelming the main screen.
- A fuller dispute view exists for deliberate inspection.
- The win state should preserve the final game summary.

## Bubble Experience

- The transcript bubble should carry enough information to understand the current moment at a glance.
- The expanded Messages view should remain the place for richer actions and board interaction.
- The primary shell status language should stay compact and direct:
  - `Your turn`
  - `Waiting on <player>`
- The top shell summary should show dice state during turn play:
  - `Roll pending`
  - `Roll: 4 + 3 = 7`
- Player-facing names in the shell should use deterministic per-game aliases until explicit player naming exists.
- The main screen should avoid persistent stacked cards; hand, bank, player summaries, build choices, and dev-card inventory should appear through the shared lower shelf instead.
- The board should not resize when the lower shelf opens. The shelf should slide over the bottom of the board while the board and dock remain fixed.
- During interactive Messages-host resize, the board should freeze visually, ignore board taps/gestures, and then perform one settled update after the host stops moving.
- The bubble should support lobby readability as well as in-game readability; joining and host-start should not create avoidable transcript clutter.
