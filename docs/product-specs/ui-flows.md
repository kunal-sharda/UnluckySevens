# UI Flows

This document summarizes the player-facing flows the UI must support in the current product direction.

## Lobby Flow

- A player starts a game from Messages and sends an invite/game-state bubble into a thread.
- Before the first invite is sent, the lobby surface should be a simple invite entry screen focused on one action: invite players to Unlucky Sevens. Its visual metaphor should be a board-game rules/setup card, not a generic form: printed setup facts, compact rule-card hierarchy, an RSVP-style player-name line, and one `Send Invite` action.
- Immediately after sending the initial invite, the extension dismisses back to the Messages thread instead of pretending the local post-send shell is a live lobby.
- Other players join before the host starts.
- Joining should feel like a game action, not a draft-composition flow. A player should not need an extra manual send step after choosing `Join`.
- A player may enter a custom display name before joining, and joined players may update that name later while the lobby is still open.
- The app should remember the local player's preferred lobby name on that device and prefill future invite/join drafts from that preference.
- Lobby-entered display names are table-local canonical metadata. If no custom name is set, the UI falls back to deterministic per-game aliases.
- Reopening a real lobby bubble should show the normal lobby roster/start surface, even if no guest has joined yet. The host waits and starts from that selected bubble path, not from a synthetic post-send shell.
- The roster locks when the host starts the game.
- New games should default to seeded balanced board generation that avoids adjacent `6`/`8` number tokens. Fully random board rules may remain protocol-supported for tests or already-persisted state, but they are not the default first-beta product path.
- Lobby UX should stay on the canonical game-state chain:
  - one invite `STATE`
  - joining publishes updated lobby `STATE`
  - one host-published start `STATE`

## Setup Flow

- Players place two settlement-road pairs in snake order.
- The second completed placement grants starting resources from adjacent non-desert tiles.
- The UI must make placement order and legality legible without inventing setup rules locally.
- Setup should feel guided and blocking: the player should always know whether the next action is settlement placement or road placement.
- Setup uses the same full-size live board as normal play. Its public rail becomes a three-slot placement carousel showing the current placement and next two placements, while its lower rail shows exactly one settlement and one road for the active placement pair.
- Setup advances into the existing first-turn screen only after the authoritative Core phase changes to `.turn`; the presentation does not predict that handoff.
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
- The active player’s normal `.afterRoll` Turn Screen uses five persistent zones: a compact top bar, public table rail, live board, reserved action well, and turn-object rail. Lobby, roll-needed, out-of-turn, forced-flow, settings, and game-over screens retain their existing compositions.
- The top bar keeps fixed three-column geometry: Settings, centered two-line turn/roll status, and one Game Information object for players, public scores/card counts, awards, and a one-turn recap.
- The public table rail shows five physical resource Bank stacks and a separate `Dev Cards` pile with no counts while concealed. Tapping Bank reveals qualitative `H`, `M`, or `L` levels in place for all six piles; tapping again conceals them. Exact public counts are not shown visually or through accessibility on this surface.
- The public `Dev Cards` pile remains visually and semantically separate from owned Dev Cards. Tapping the public pile is the sole Buy Dev affordance when Core says purchase is legal. Owned Dev Cards are nested inside Hand for inspection and play; Buy Dev never appears in Build.
- The live board remains visually dominant and keeps one stable renderer, frame, camera, targets, and canonical-piece owner while action-well routes change.
- The action well reserves a constant frame below the board. Hand opens there by default; Build, Trade, nested Dev selection, End confirmation, and Game Information replace it one at a time without moving the board, public rail, status, or turn rail. Bank reveal is an independent in-place public-information toggle and never consumes the well.
- The turn-object rail uses fixed `Hand · Build · Trade · End` anchors. An object exists only when its Core/query-derived action is executable now; an unavailable object leaves invisible, hitless, accessibility-hidden space so neighboring anchors do not move. Playable Dev Cards are entered from the owned-card stack inside Hand rather than a fifth rail object.
- Hand shows the local player’s actual resource inventory plus a compact two-card owned-Dev prop. The prop summarizes the private inventory without trying to lay every card on the default surface; its complete VoiceOver value still reports every owned kind and playable/new status. Those private cards do not appear in public Game Information.
- Build shows only currently executable Road, Settlement, and City choices. Setup/build target selection remains selection-first: tap once to select and the same target again to publish.
- Trade appears only when a player or maritime route can actually be initiated, or when the current live offer can be inspected. The chooser, composer, and pending-offer state stay inside the fixed action well; switching away discards the local draft.
- The owned Dev Cards object appears inside Hand; it opens only when at least one owned card is legally playable. Its opened spread shows the player’s full owned inventory, marks held or newly bought cards as non-interactive, and gives an action affordance only to cards Core says are legally playable. Monopoly/Year of Plenty resource choice and Knight/Road Building board choice stay within the same route.
- End appears only when ending is legal and opens a compact inline `Keep Playing` / `End Turn` confirmation.
- Selecting the active object closes it and clears its local draft or board selection. Selecting another turn object or Game Information replaces the current action-well contents and clears incompatible state. Toggling Bank reveal preserves the selected action.
- Action-well replacement uses an opacity-only transition when Reduce Motion is enabled; every interactive object keeps at least a 44-by-44-point hit region and a stable VoiceOver label.
- Outside the active normal post-roll Turn Screen, the established lower tray and overlay-shelf behavior remains unchanged.
- Dev-card actions should be choice-driven for Knight, Monopoly, Year of Plenty, and Road Building rather than expanding into a deep form flow or hiding behind defaults.
- Victory Point cards remain visible to their owner in Hand/inventory; they enter the Dev selection surface only when revealing them would immediately win the game.
- Knight should stage through robber-tile choice first and only ask for an explicit victim when the chosen tile has multiple eligible steals.
- Guided board flows should use a compact bottom-center in-board hint pill rather than a large floating HUD card.
- The hint pill should be single-line by default and shift upward when the overlay shelf is open so it never sits inside the shelf overlap zone.
- The only valid overlap in the shell is the deliberate shelf-over-board overlay at the bottom edge. Utility tabs, dock buttons, board chrome, and content regions must otherwise stack without collision or wrapping.
- If the active player reaches the win threshold on their turn, the game ends immediately.
- Forced subflows such as discard and robber movement should feel blocking rather than like optional side actions.
- When multiple players must discard after a `7`, only the next pending discarder in locked roster order should see an enabled discard action. Each discard publishes canonical `STATE` immediately while robber movement stays blocked until the discard queue is empty.

## Trade Flow

- The current player enters trade from the normal post-roll `Trade` object; excluded shell states retain their established trade affordances.
- The normal post-roll action well starts on a chooser surface with:
  - `Player Trade`
  - `Maritime / Bank Trade`
- `Player Trade` should be fully self-contained inside the trade panel. It should not depend on tapping controls in the lower shelf underneath it.
- `Player Trade` should present three vertical sections in this order:
  - `You Give`, using the current player hand chips as the interactive source
  - `You Want`, using bank-style resource chips plus remaining public bank counts
  - `Recipients`, as the only scrollable section in the composer
- Forced discard should use an explicit hand-chip pattern: the acting player selects the exact cards to discard, sees progress toward the required count, and cannot submit until the required total is selected.
- Closing or switching away from trade should discard the current draft immediately for now.
- After send, the normal post-roll Trade route stays on the pending live-offer state and marks its anchored object `Pending`; excluded shell states retain their established pending banner behavior.
- `Maritime / Bank Trade` should use a quick-trade list because the legal option set is fully enumerable from the current hand and available ports.
- The maritime quick-trade list should only show legal ratio-compliant options for the current hand and available port access.
- Targeted recipients can respond with `Accept`, `Decline`, or `Counter`.
- `Counter` should use the same composer flow, but it is addressed only back to the current player.
- Targeted responder actions should feel final from the responder side. `Accept`, `Decline`, and `Counter` should each publish canonical trade state immediately from the responder device. Normal trade UX must not require a manual "apply selected response" step or a separate response bubble workflow.
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
- Fresh transcript bubbles should use product copy in the form `Unlucky Sevens: <descriptive title>` plus a short summary of the latest lobby, setup, or turn change.
- The first lobby invite bubble may include a branded programmatic Unlucky Sevens image so the thread reads as an invitation before anyone joins.
- Lobby join and lobby name-update bubbles should stay text-only to avoid noisy roster-edit snapshots.
- Setup, turn, and game-over `STATE` bubbles may include concise action-card graphics keyed by move type. The image is presentation only; the canonical state must still decode from the URL payload.
- The bubble image should use as few words as possible. The caption and summary carry the readable move copy.
- If image rendering is unavailable, publishing should still send the same caption and summary as a text-only bubble.
- The expanded Messages view should remain the place for richer actions and board interaction.
- The primary shell status language should stay compact and direct:
  - `Your turn`
  - `Waiting on <player>`
- The top shell summary should show dice state during turn play:
  - `Roll pending`
  - `Roll: 4 + 3 = 7`
- Player-facing names in the shell should prefer the lobby-set custom name for that table, with deterministic per-game aliases as the fallback.
- The main screen should avoid persistent stacked cards. On the normal post-roll screen, Hand, Game Information, build choices, trade, and dev-card actions replace one another inside the reserved action well; Bank levels reveal independently in the public rail, and other states continue to use their existing shelf ownership.
- The board must not resize or remount when the normal post-roll action well changes or when an existing lower shelf opens elsewhere.
- During interactive Messages-host resize, the gameplay-height board should stay live. Host drag should update viewport/camera cheaply in place, then perform one settled redraw after the host stops moving instead of snapshot-freezing and remounting the board.
- At the normal fully-extended gameplay height, the live board should stay interactive throughout host drag. Normal resize should not enter a board freeze mode or require a board reload to recover.
- Outside the narrow top grabber strip, drags should stay inside the game. Board drags should pan/zoom the board, shelf drags should stay local to the shelf, and only the top strip should be able to hand off to Messages-host resize.
- On iPad-sized but vertically short Messages hosts, the lower shelf should fall back to the compact vertical layout instead of using oversized pad minima that clip or disable `Hand`, `Bank`, and `Players`.
- When the app has recoverable canonical state for one or more games, the shell should expose a compact `Game` / `Games` recovery affordance that can reopen the latest known state for that game without forcing the user to hunt for the right transcript bubble first.
- The bubble should support lobby readability as well as in-game readability; joining and host-start should stay on the same canonical state chain instead of creating avoidable transcript clutter.
