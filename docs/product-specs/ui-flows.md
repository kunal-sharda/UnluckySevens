# UI Flows

This document summarizes the player-facing flows the UI must support in the current product direction.

## Lobby Flow

- A player starts a game from Messages and sends an invite/game-state bubble into a thread.
- Before the first invite is sent, the lobby surface should be a simple invite entry screen focused on one action: invite players to Unlucky Sevens.
- Immediately after sending the initial invite, the extension dismisses back to the Messages thread instead of pretending the local post-send shell is a live lobby.
- Other players join before the host starts.
- Joining should feel like a game action, not a draft-composition flow. A player should not need an extra manual send step after choosing `Join`.
- Reopening a real lobby bubble should show the normal lobby roster/start surface, even if no guest has joined yet. The host waits and starts from that selected bubble path, not from a synthetic post-send shell.
- The roster locks when the host starts the game.
- Lobby UX should stay on the canonical game-state chain:
  - one invite `STATE`
  - joining publishes updated lobby `STATE`
  - one host-published start `STATE`

## Setup Flow

- Players place two settlement-road pairs in snake order.
- The second completed placement grants starting resources from adjacent non-desert tiles.
- The UI must make placement order and legality legible without inventing setup rules locally.
- Setup should feel guided and blocking: the player should always know whether the next action is settlement placement or road placement.
- Setup and build placement should be selection-first rather than one-tap publish:
  - first tap selects a legal node or edge
  - the player confirms by tapping the same selected target again
  - tapping a different legal target changes the selection instead of publishing immediately
  - setup/build confirmation should not replace the utility shelf header tabs or make `Hand` / `Bank` / `Players` unreachable on larger hosts

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
  - before rolling: `Roll`, `End Turn`, `Build`, `Play Dev`
  - after rolling during normal turn play: `Trade`, `End Turn`, `Build`, `Play Dev`
- The left dock slot is contextual:
  - it shows `Roll` when the turn still needs dice
  - it switches to `Trade` once rolling is no longer the relevant action for the turn
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
- `Build`, `Play Dev`, and the utility shelves should behave as peer shell routes. Tapping `Hand`, `Bank`, or `Players` while `Build` is open should switch directly instead of forcing the player to unwind build first.
- `Build` and `Play Dev` should use the same overlay shelf surface as the utility entry path.
- `Trade` should be available from the post-roll left dock slot, and a live-offer banner above the lower shelf should reopen the trade panel while an offer is pending. It should not exist as a permanent always-on dock action.
- Trade should render in its own panel above the lower shelf rather than inside `Hand`.
- While the trade panel is open, the lower shelf should be fully hidden/disabled instead of remaining interactive underneath it.
- The bank should be quickly accessible rather than always expanded. Its full public counts for wood, brick, sheep, wheat, and ore should live in the `Bank` shelf and become interactive only for Monopoly and Year of Plenty.
- The bank should reuse the same five-chip visual format as the hand in normal viewing, adding only minimal selection decoration during Monopoly or Year of Plenty.
- Opponent summaries should be shelf-only rather than always visible in the main shell.
- The `Players` shelf should show each opponent with the same player-color swatch used by their roads and settlements on the board so the roster and board stay visually aligned.
- `Play Dev` should open a dedicated dev-card shelf rendered as card tiles rather than a text-heavy action list.
- Dev-card actions should be choice-driven for Knight, Monopoly, Year of Plenty, and Road Building rather than expanding into a deep form flow or hiding behind defaults.
- Victory Point cards should remain visible to the owning player in that card shelf, but only become actionable when revealing them would immediately win the game.
- Knight should stage through robber-tile choice first and only ask for an explicit victim when the chosen tile has multiple eligible steals.
- Guided board flows should use a compact bottom-center in-board hint pill rather than a large floating HUD card.
- The hint pill should be single-line by default and shift upward when the overlay shelf is open so it never sits inside the shelf overlap zone.
- The only valid overlap in the shell is the deliberate shelf-over-board overlay at the bottom edge. Utility tabs, dock buttons, board chrome, and content regions must otherwise stack without collision or wrapping.
- If the active player reaches the win threshold on their turn, the game ends immediately.
- Forced subflows such as discard and robber movement should feel blocking rather than like optional side actions.

## Trade Flow

- The current player enters trade from the dock `Trade` button or from the pending-offer banner.
- The trade panel opens above the lower shelf and starts on a chooser surface with:
  - `Player Trade`
  - `Maritime / Bank Trade`
- `Player Trade` should be fully self-contained inside the trade panel. It should not depend on tapping controls in the lower shelf underneath it.
- `Player Trade` should present three vertical sections in this order:
  - `You Give`, using the current player hand chips as the interactive source
  - `You Want`, using bank-style resource chips plus remaining public bank counts
  - `Recipients`, as the only scrollable section in the composer
- Forced discard should use an explicit hand-chip pattern: the acting player selects the exact cards to discard, sees progress toward the required count, and cannot submit until the required total is selected.
- Closing or switching away from trade should discard the current draft immediately for now.
- After send, the trade panel should close and the pending-offer banner should become the primary reopen affordance.
- `Maritime / Bank Trade` should use a quick-trade list because the legal option set is fully enumerable from the current hand and available ports.
- The maritime quick-trade list should only show legal ratio-compliant options for the current hand and available port access.
- Targeted recipients can respond with `Accept`, `Decline`, or `Counter`.
- `Counter` should use the same composer flow, but it is addressed only back to the current player.
- Targeted responder actions should feel final from the responder side. A targeted `Accept` should publish the resolved canonical trade state immediately, while `Decline` and `Counter` may still travel as internal trade-response transport on the same game session. Normal trade UX must not require a manual "apply selected response" step or a separate response bubble workflow.
- The first applied targeted `Accept` should resolve the trade and close the live offer.
- If every targeted player declines, the live offer should close.
- Non-targeted players should still be able to inspect the live trade state so the table can follow what is happening.
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
- Utility shelves should stay only slightly taller than needed for their content; `Players` may scroll, but `Hand` and `Bank` should remain compact in the normal host size.
- The board should not resize when the lower shelf opens. The shelf should slide over the bottom of the board while the board and dock remain fixed.
- During interactive Messages-host resize, the gameplay-height board should stay live. Host drag should update viewport/camera cheaply in place, then perform one settled redraw after the host stops moving instead of snapshot-freezing and remounting the board.
- At the normal fully-extended gameplay height, the live board should stay interactive throughout host drag. Normal resize should not enter a board freeze mode or require a board reload to recover.
- Outside the narrow top grabber strip, drags should stay inside the game. Board drags should pan/zoom the board, shelf drags should stay local to the shelf, and only the top strip should be able to hand off to Messages-host resize.
- On iPad-sized but vertically short Messages hosts, the lower shelf should fall back to the compact vertical layout instead of using oversized pad minima that clip or disable `Hand`, `Bank`, and `Players`.
- When the app has recoverable canonical state for one or more games, the shell should expose a compact `Game` / `Games` recovery affordance that can reopen the latest known state for that game without forcing the user to hunt for the right transcript bubble first.
- The bubble should support lobby readability as well as in-game readability; joining and host-start should stay on the same canonical state chain instead of creating avoidable transcript clutter.
