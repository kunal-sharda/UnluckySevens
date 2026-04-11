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

## Turn Flow

- Optional non-VP dev-card play before or after the roll, subject to core timing rules and never for a non-VP card bought on the same turn.
- Victory Point cards stay hidden unless revealing them would immediately win the game.
- Roll.
- Resolve either production or the full seven/robber subflow.
- Optionally trade, build, buy or play allowed dev cards, and then end turn.
- The primary dock order should stay shallow and predictable:
  - `Roll`
  - `End Turn`
  - `Build`
  - `Play Dev`
- `Build` opens a compact shelf for legal build/buy actions such as road, settlement, city, and dev-card purchase, while keeping bank-backed availability visible.
- The bank strip stays visible near the hand tray with public remaining counts for wood, brick, sheep, wheat, and ore. It becomes interactive only for resource-selecting dev-card flows such as Monopoly and Year of Plenty.
- Dev-card actions should be choice-driven for Knight, Monopoly, Year of Plenty, and Road Building rather than expanding into a deep form flow or hiding behind defaults.
- Knight should stage through robber-tile choice first and only ask for an explicit victim when the chosen tile has multiple eligible steals.
- If the active player reaches the win threshold on their turn, the game ends immediately.
- Forced subflows such as discard and robber movement should feel blocking rather than like optional side actions.

## Trade Flow

- The current player sees a compact trade modal with suggested player-trade and maritime-trade actions.
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
- The bubble should support lobby readability as well as in-game readability; joining and host-start should not create avoidable transcript clutter.
