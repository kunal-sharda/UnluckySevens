# UI Flows

This document summarizes the player-facing flows the UI must support in the current product direction.

## Lobby Flow

- A player starts a game from Messages and sends an invite/game-state bubble into a thread.
- Other players join before the host starts.
- The roster locks when the game starts.

## Setup Flow

- Players place two settlement-road pairs in snake order.
- The second completed placement grants starting resources from adjacent non-desert tiles.
- The UI must make placement order and legality legible without inventing setup rules locally.

## Turn Flow

- Optional dev-card play at the start of a turn, subject to core timing rules.
- Roll.
- Resolve either production or the full seven/robber subflow.
- Optionally trade, build, buy or play allowed dev cards, and then end turn.
- If the active player reaches the win threshold on their turn, the game ends immediately.

## Trade Flow

- The current player proposes trades.
- Other players can respond through accept-style intent bubbles.
- The current player decides whether to execute a trade before end turn.
- Bank and port trades should feel distinct from player-to-player trade offers.

## Audit and Game-Over Flow

- The default audit surface should show a short last-turn recap.
- One round of history should be available without overwhelming the main screen.
- A fuller dispute view exists for deliberate inspection.
- The win state should present the winner clearly and preserve the final game summary.

## Bubble Experience

- The transcript bubble should carry enough information to understand the current moment at a glance.
- The expanded Messages view should remain the place for richer actions and board interaction.
