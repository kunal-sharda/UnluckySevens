# UI Flows

This document owns the player-facing behavior and journey structure for the current product. It describes what the UI must make possible and understandable. Core owns game rules and legality, [Architecture](../../ARCHITECTURE.md) owns runtime boundaries, [Decisions](../decisions.md) owns locked calls, and [Design](../../DESIGN.md) owns visual language.

## How to Read This Contract

Not every sentence has the same weight:

- **Invariant** — release-blocking behavior or trust boundary. Do not violate it silently.
- **Required flow** — the player journey and available actions the current product must support.
- **Presentation direction** — the approved way that flow is currently expressed. It may change only through explicit design approval.
- **Known gap** — the current implementation or proof does not meet the contract. Gaps are listed together near the end.

When code and this document disagree, code/tests establish what the app currently does, but they do not automatically redefine intended product behavior. Surface the conflict and resolve it explicitly.

## End-to-End Journey

| Stage | Player sees | Primary action | Publishes canonical state? |
| --- | --- | --- | --- |
| New game | First-invite surface | Send Invite | Yes |
| Open lobby | Current roster and open seats | Join, rename, or Start Game | Yes |
| Setup | Live numberless board and placement order | Place two settlement-road pairs | Yes, after each confirmed placement |
| Start of turn | Mounted table beneath a focused roll choice | Play an eligible Dev Card or Roll | Yes |
| Action turn | Current board, hand, legal actions, and public table state | Build, trade, buy/play Dev Cards, or End Turn | Yes |
| Seven flow | Blocking discard/robber sequence | Discard, move robber, then choose a victim if required | Yes, one authoritative step at a time |
| Waiting | Current public table and reason for waiting | Inspect only, or answer a targeted trade/discard prompt | Only when the local player owns the required action |
| Game over | Final board, winner, score summary, and recap | Inspect result | No further gameplay state |
| Reopen | Latest recoverable state for the selected game | Continue from the latest known revision | No, until a new action is taken |

## Cross-Flow Invariants

These are the most important UI requirements:

1. **Core owns rules and legality.** Presentation renders query/engine outputs; it does not invent a second rules engine.
2. **Canonical state remains visible.** The UI must not obscure whose turn it is, what is pending, the next legal action, or the committed result.
3. **The board stays mounted.** Opening Hand, Build, Trade, Dev Cards, End confirmation, Game Information, or another action surface must not resize, remount, or shift the live board.
4. **Private information stays private.** Local hands and owned Dev Cards never leak through public game information, transcript copy, accessibility, or preview art.
5. **One interaction owner at a time.** An overlay or forced flow owns its controls and cannot depend on obscured controls underneath it.
6. **Publishing is deliberate and authoritative.** Local drafts are not canonical state. A confirmed action publishes one validated state transition through the current game session.
7. **Unavailable actions do not masquerade as available.** They are absent or inert, hitless, and accessibility-hidden without moving stable neighboring controls.
8. **Messages remains the host.** After publication, the transcript bubble communicates the result; richer inspection and actions live in the expanded extension.
9. **Accessibility is behavioral.** Interactive targets are at least 44 by 44 points, icon controls have stable labels, important state is not color-only, and authored motion honors Reduce Motion and the local Skip Animations preference.
10. **Host resizing preserves continuity.** Normal Messages resizing keeps the canonical Physical Props shell live and interactive. The board may manage its own rendered continuity, but the shell must never replace the current header, rails, or action surface with a parallel snapshot composition.

## Lobby and Game Start

### Required Flow

| Moment | UI requirement | Result |
| --- | --- | --- |
| Before first invite | One obvious Send Invite action, preferred-name field, read-only game settings, and Tutorial | Sends the initial lobby `STATE`, then dismisses to Messages |
| Guest opens invite | Current roster, open seats, name field, and Join | Join publishes immediately; no second manual send step |
| Joined player reopens | Canonical roster and editable local display name | Rename publishes an updated lobby `STATE` |
| Host reopens lobby | Canonical roster and Start Game when valid | Start locks the roster and publishes the setup state |
| Host views its just-sent message locally | Informational waiting state | Does not become a second start authority |

Additional requirements:

- Preferred lobby name is device-local prefill convenience. The submitted display name becomes table-local canonical metadata.
- If no custom name exists, deterministic per-game aliases are used.
- Reopening a real lobby bubble shows the normal roster/start surface even when only the host has joined.
- New games default to the seeded balanced board strategy that avoids adjacent `6` and `8` tokens.
- Every lobby state exposes explicit Game Settings and Tutorial rows directly. A compact die control opens Games directly without crowding the lobby identity bar.
- The canonical publication chain is one invite `STATE`, joined/renamed lobby `STATE` updates, then one host-published start `STATE`.

### Presentation Direction

The first-invite surface is a full-canvas cocktail-table invitation rather than a generic form. A real numberless board sits inside the physical table, four attached stations communicate the roster, and compact identity, explicit Game Settings and Tutorial rows, a direct die control for Games, and one primary action complete the surface. Invite, Join, Ready, and waiting states share this composition and keep one obvious next action. Invite and Join both use `Playing as` as the visible identity label and anchor the identity editor plus primary action near the bottom of the available canvas so the table remains the visual focus.

## Initial Setup

### Required Flow

1. The active player places a settlement.
2. The same player places a connected road.
3. Setup continues in snake order until every player has placed twice.
4. The second completed placement grants starting resources from adjacent non-desert tiles.
5. The UI advances into the first turn only after Core changes the authoritative phase to `.turn`.

Placement is selection-first:

- First tap selects a legal node or edge.
- Tapping a different legal target changes the selection.
- Tapping the selected target again confirms and publishes.
- The UI never predicts legality or the setup-to-turn handoff.

### Presentation Direction

- Setup uses the same full-size live board as normal play, with number tokens withheld from transcript preview art.
- A three-slot placement rail shows the current placement plus the next two.
- The lower rail exposes exactly one settlement and one road for the active placement pair.
- Placement order, active player, legal targets, and “tap again” confirmation remain legible.
- Glowing legal targets remain visible for both placement pairs. The first pair alone adds `Choose a glowing corner.` for the settlement and `Choose a glowing road beside your settlement.` for the connected road; the second pair relies on the learned visual language.

## Turn Lifecycle

### Required Flow

| Phase | Player choice | UI responsibility |
| --- | --- | --- |
| Start of turn | Play an eligible non-VP Dev Card or Roll | Show only currently legal pre-roll choices |
| Dice settled | Continue from the authoritative result | Do not generate or alter the Core-owned roll |
| Production | Inspect payouts and changed state | Keep the board and public state readable |
| Seven | Complete the blocking discard/robber flow | Do not expose ordinary optional actions |
| Action phase | Hand, Build, Trade, Buy/Play Dev Card, Game Information, or End | Show only executable actions and preserve local drafts only while their route stays open |
| End confirmation | Keep Playing or End Turn | Publish the handoff only after confirmation |
| Waiting | Inspect current table and wait reason | Do not show active-player actions |

Turn rules relevant to presentation:

- Eligible non-VP Dev Cards may be played before or after rolling, subject to Core timing.
- A non-VP card bought this turn is not playable this turn.
- Victory Point cards remain private and are revealed only when Core allows an immediate win.
- Rolling is deliberate and never automatic.
- Reaching the win threshold ends the game immediately.

### Start-of-Turn Presentation

- The normal pre-roll state keeps the mounted Physical Props table beneath a focused full-host choice layer.
- If both are legal, the layer shows owned executable Dev Cards and Roll. Otherwise it shows Roll alone.
- Closing the Dev chooser returns without consuming a card.
- Completing a pre-roll Dev action returns to Roll alone.
- Dice animation decorates the already-authoritative result. Skip, Reduce Motion, and Skip Animations all resolve to that same result and still require explicit continuation.

### Normal Post-Roll Presentation

The normal active-player screen has five stable zones:

1. top status and utilities;
2. public Bank and Dev Cards rail;
3. live board;
4. reserved action well;
5. fixed Hand, Build, Trade, and End rail.

Behavioral requirements:

- The top area exposes Settings, current turn/roll state, and Game Information. Games uses a die and replaces the player rows inside that same panel; Players uses the matching people symbol and restores the roster without moving the board. In Games mode, the die-labeled header reads Your Games and opens full lifecycle management without introducing a mode-specific ellipsis or extra row.
- Bank reveal shows qualitative `H`, `M`, or `L` levels only. Exact public counts remain concealed visually and through accessibility.
- Public Dev Cards and privately owned Dev Cards remain distinct.
- The public Dev pile is the sole Buy Dev affordance; Buy Dev does not appear under Build.
- The fixed Hand prop shows the local player's total resource-card count before opening. Hand owns the local resource inventory and owned Dev Cards; its open state shows per-resource counts.
- Build exposes only executable Road, Settlement, and City choices.
- Trade appears only when a player/maritime route can begin or a live offer can be inspected.
- End appears only when ending is legal and opens Keep Playing / End Turn confirmation.
- Selecting the current route closes it and clears its local draft or board selection.
- Selecting another route replaces the current action surface and clears incompatible local state.
- Bank reveal is independent and does not replace the selected action.

## Upper Amber Instruction

The upper instruction is the short action heading centered between Settings and Game Information with a small amber line beneath it. It is a shared presentation surface, not general status text.

### Contract

- It appears only when the mounted Physical Props screen is asking for one immediate choice or displaying the status of one live trade.
- It replaces the passive turn/dice content in that center slot; the two utility buttons remain mounted.
- Exactly one upper instruction may appear at a time.
- Copy is concise, forward-looking Title Case with no terminal punctuation.
- The amber line means “this is the current interaction,” not merely emphasis or decoration.
- The instruction is derived from the active presentation route, Core-owned phase, and local draft state. Individual components must not invent competing headings.
- The visible text is also the center slot’s accessibility label. The line is decorative and accessibility-hidden.
- Exact typography, spacing, and keyline dimensions belong to the shared component and [Design](../../DESIGN.md), not to each flow.

### Canonical Heading Map

| Interaction state | Upper instruction |
| --- | --- |
| Build chooser | `Choose a Piece` |
| Road placement | `Place a Road` |
| Selected road or settlement target | `Tap Again to Build` |
| Settlement placement | `Place a Settlement` |
| City placement | `Upgrade to a City` |
| Selected city target | `Tap Again to Upgrade` |
| Trade chooser | `Choose How to Trade` |
| Player-trade draft | `Make an Offer` |
| Maritime trade | `Trade with Bank or Port` |
| Sent live offer | `Waiting for Replies` |
| Targeted incoming offer | `Review the Offer` |
| Passive wait for required discards | `Waiting for Other Players` |
| Dev Card chooser | `Choose a Dev Card` |
| Knight robber destination | `Move the Robber` |
| Knight victim selection | `Select a Settlement Beside the Robber` |
| Monopoly resource selection | `Choose a Resource` |
| Year of Plenty before a selection | `Choose Two Resources` |
| Year of Plenty after one selection | `Choose One More` |
| Road Building first placement | `Place the First Road` |
| Road Building second placement | `Place the Second Road` |

### Current Exclusions

The current UI does not use the upper amber instruction in these states:

- normal idle play, which shows current turn/dice status;
- start of turn, which uses the focused Roll / Dev Card choice layer;
- setup, which uses its setup-specific placement header;
- active seven discard, which uses its blocking hand-card composer; passive players waiting for required discards use the upper amber instruction;
- ordinary waiting, which uses player/turn status;
- Settings, Game Information, Bank reveal, and End confirmation.

This records current behavior, not yet an approved universal boundary. Ordinary robber movement and victim choice use the upper amber instruction; the active discard composer remains the forced-seven exception.

## Forced Seven, Discard, and Robber

### Required Flow

1. After a `7`, players holding more than seven cards discard half, rounded down.
2. Only the next pending discarder in locked roster order receives an enabled discard action.
3. Each discard publishes canonical state immediately.
4. Robber movement remains blocked until the discard queue is empty.
5. The current player moves the robber to a legal tile.
6. If one victim is eligible, Core may resolve the steal without another choice. If multiple victims are eligible, the player explicitly chooses one.

### Presentation Direction

- Forced actions look blocking, not like optional tray actions.
- Discard uses the real hand-card language, shows progress toward the exact required count, permits correction, and enables Confirm only at the required total.
- Robber movement and victim choice form one continuous Physical Props board interaction. The fixed upper prompt advances from `Move the Robber` to `Select a Settlement Beside the Robber`; the mounted board, public rail, and turn-object rail do not move, and no generic forced-flow card covers the table.
- Legal robber tiles and eligible victim settlements glow on the board. The player chooses whom to steal from by selecting that player's adjacent glowing settlement beside the robber; the selection continues through the existing Core-backed action path rather than a second presentation-owned rules path.
- The active discarder sees `Discard Cards` and `Choose exactly [N] cards`. Passive players see `Waiting for Other Players` without a subtitle or another player’s action controls.

## Trade

### Offer Flow

1. The active player opens Trade.
2. The chooser offers Player Trade and Maritime / Bank Trade when legal.
3. Player Trade composes Give and Get quantities from one shared draft.
4. The sender chooses one or more eligible recipients.
5. Send Offer publishes the live canonical offer.
6. The active player sees the pending offer state until it resolves or is replaced.

Player Trade requirements:

- The full composer is self-contained and must not depend on controls underneath it.
- Give/Get cards, badges, and quantity controls mutate the same draft values.
- Recipient selection supports multiple players and exposes a non-color selected state.
- Switching away or closing discards the unsent local draft.
- Counter offers use the same composer but are addressed only to the original proposer.

### Response Flow

- A targeted recipient may Accept, Decline, or Counter.
- Each response publishes immediately from the responder’s device; there is no second “apply response” step.
- The first applied Accept resolves and closes the offer.
- The offer closes after every targeted player declines.
- Non-targeted players may inspect the public offer but cannot respond.

### Maritime / Bank Flow

- The app shows one complete legal exchange at a time.
- Previous/next paging and `N of M` communicate the available options.
- Confirm Trade is required.
- Options use the player’s best legal ratio from bank and owned ports; players do not choose bank versus port as separate destinations.

## Game Information, History Boundary, and Game Over

### Required Flow

- Game Information exposes public player names, scores, public card counts, awards, current-player state, and one short previous-turn recap when available.
- Game over preserves the final board, clearly identifies the winner, and shows a compact final score summary plus the last-turn recap when available.
- Private hands and private Dev Card identities never enter these views.

### History Boundary

- The product does not expose a full player-facing audit or dispute-history view.
- Game Information keeps only the short previous-turn recap described above.
- Canonical audit data may continue to support determinism, validation, and internal state interpretation without becoming a browsing surface.
- A skippable animation that replays the immediately previous turn after a player opens a bubble on their turn is a deferred concept, not part of the current contract. If pursued, it requires a separate interaction, privacy, recovery, and animation specification.

## Settings, Rules, and Tutorial

### Settings and Rules

- Settings opens as a centered tabletop overlay over the exact lobby or game surface that invoked it.
- The overlay is one compact felt utility panel: grouping comes from spacing and dividers rather than nested light cards.
- Rules uses text-only section headings, keeps visible scroll indicators, and shows an initial text-only `Scroll for more` cue so below-fold sections are unmistakable.
- After the final rule, Rules offers a Strategy row that opens the existing three-tip Strategy card as its own focused overlay. Closing Strategy returns to the same place in Rules.
- Settings contains a direct Skip animations toggle without a redundant category heading, read-only Standard/Balanced/10-point facts, and a Rules destination immediately after those facts without a separate Help heading.
- Rules remains inside the same utility context.
- Tutorial is a separate lobby destination, not a Settings row.
- Skip Animations is device-local and never enters canonical state, hashes, or transport.

### Tutorial Navigation

- Tutorial is available from every lobby state.
- It renders deterministic local-only state through the production game shell.
- Its first screen is a transient veil explaining tap-left for Back and tap-right for Next.
- The first tap dismisses the veil without advancing.
- Afterward, the left and right halves navigate; explicit accessibility actions provide the same behavior.
- A compact exit control remains available without resizing or covering the board.
- Exit and the final right-side tap return to the invoking lobby state.
- Tutorial never publishes or mutates a real game.

### Tutorial Lesson Map

| # | Lesson | Real surface taught |
| --- | --- | --- |
| 1 | Place Your First Settlement | Setup order and a glowing intersection |
| 2 | Add a Road | Connected glowing road edge |
| 3 | Roll to Begin | Start-of-turn roll action |
| 4 | Follow the Roll | Number tokens, buildings, and robber blocking |
| 5 | Check Your Hand | Spendable resources and owned Dev Cards |
| 6 | Pick a Build | Road, settlement, and city costs |
| 7 | Choose a Glowing Spot | Available build targets |
| 8 | Make an Offer | Give/Get composer |
| 9 | Choose Who Gets It | One or more players and Send Offer |
| 10 | Use Your Best Rate | Best Bank or Port exchange |
| 11 | Discard on Seven | Exact-count discard composer |
| 12 | Move the Robber | Legal robber destination |
| 13 | Choose a Victim | Eligible steal target |
| 14 | Play a Dev Card | Playable versus held/new cards |
| 15 | Send the Turn | End confirmation and Messages handoff |
| 16 | Strategy | One centered three-tip card covering probability dots, purposeful Road/Dev Card investment, and scoring |

The final Strategy lesson dims but does not replace or remount the production board. One centered tabletop card presents three ordered tips:

1. more dots under a number mean a stronger spot for that resource, and covering several resources makes a position more flexible;
2. Roads open new settlement spots and can earn Longest Road, Knights build toward Largest Army, and Victory Point cards score 1;
3. Cities and the Longest Road/Largest Army awards score 2 points, while settlements score 1 point each.

The Strategy card replaces the separate strategy and final-scoring lessons. It is one surface with three rows, not three nested cards, and it remains skippable through the normal tutorial navigation.

## Transcript Bubbles and Publishing

### Invariants

- `MSMessage.url` remains the canonical payload. Caption, summary, and image are presentation metadata and fail soft.
- Updates for one game reuse the same per-game `MSSession`, allowing Messages to collapse earlier rich state.
- Caption and summary preserve readable event history even when prior images collapse.
- If image rendering fails, the same caption and summary still publish.
- Preview art is non-interactive and never carries response controls or private information.

Player-facing language has three jobs:

- **Amber instruction** — forward-looking action in the expanded app.
- **Transcript outcome** — past-tense receipt in Messages.
- **Preview image** — compact public view of canonical state.

### Event-to-Preview Families

The upper amber column points to the canonical map above; `—` means that state uses another instruction surface.

| Game condition | Upper amber instruction | Transcript outcomes | Preview |
| --- | --- | --- | --- |
| Lobby invitation or roster change | — | `Lobby Invite`, `<player> Joined`, `Name Updated` | Production player table |
| Initial setup | — | `Game Started`, `Settlement Placed`, `Road Placed`, `Setup Placed`, `Setup Complete` | Numberless production board |
| Roll and turn handoff | — | `Rolled <total>`, fail-soft `Dice Rolled`, `Turn Ended` | Numbered production board |
| Seven and robber | — | `Discard Submitted`, `Robber Moved`, `Card Stolen` | Numbered board with committed robber state |
| Construction | `Choose a Piece` and placement variants | `Road Built`, `Settlement Built`, `City Built` | Numbered board with committed piece |
| Player trade | `Choose How to Trade`, `Make an Offer`, `Waiting for Replies`, `Review the Offer` | `Trade Offered`, `Counteroffer Sent`, `Trade Accepted`, `Trade Declined` | Shared public trade receipt while live; otherwise board |
| Bank or Port trade | `Trade with Bank or Port` | `Bank or Port Trade` | Numbered board |
| Development Cards | `Choose a Dev Card` and card-specific choices | `Dev Card Bought` and card-specific played/revealed receipts | Numbered board with committed public change |
| Game over by victory | — | `<player> Wins` | Final board plus score summary |
| Player resignation | `Resign from this game?` | `<player> Resigned` | Continuing numbered or setup board |
| Draw proposal and vote | Draw actions in Games | `Draw Proposed`, `Draw Vote`, `Draw Declined`, `Draw Agreed` | Continuing board, or final board after unanimous agreement |
| Host end | `End this game?` with draw-first soft guard | `Game Ended` | Final board plus neutral score summary |
| Recovery republication | — | `Game Restored` | Unchanged phase-appropriate canonical preview |

The publishing inventory includes lobby, setup, turn, victory, resignation, draw, host-end, and unchanged recovery outcomes. `Dice Rolled` is a fail-soft title, not a separate event.

Additional requirements:

- A live shared trade receipt shows proposer, public terms, recipients, and public response status when relevant. Accept/Decline/Counter controls remain in the expanded app.
- Discard art never exposes discarded cards or private hand contents.
- Resource payouts, bank changes, award changes, private hand changes, local drafts, validation errors, and prompt-only transitions do not publish independent transcript events.
- Any new independently published lobby/setup/turn outcome must update `TranscriptBubbleCopyBuilder`, its exhaustive tests, and this family assignment in the same change.

## Recovery and Messages-Host Adaptation

### Recovery

- The app tracks the latest locally recoverable state per game.
- A dedicated Games destination is available from the fresh invitation/loading card. Inside current-game Game Information, the die-labeled Games action swaps the player rows for a compact saved-game switcher in the same centered panel; it never takes a separate gameplay top-bar slot. The centered Your Games header is a 44-point lifecycle destination, and the dedicated lifecycle screen keeps its title centered independently of Back and the saved-game count.
- Games separates Active and Finished records and identifies them by player names, phase/result, and update time.
- The local list may include games retained from other Unlucky Sevens conversations. Publish actions enable only when the saved roster is compatible with the currently open Messages conversation; Messages does not expose a durable identifier that can distinguish two chats with the same participant set.
- Joined players can Open, Resend Latest State, Archive locally, Resign, propose or vote on a draw, and—if they are the original host—End an Active game. Finished games remain openable, resendable, and locally archivable.
- Resend publishes the unchanged validated state with the same revision and hash under a `Game Restored` receipt.
- Active games remain until local archive; the device keeps only the eight most recently updated Finished games.
- Selecting an older bubble resolves to the latest known revision for that game and communicates that redirection.
- Equal-revision valid siblings resolve to the lexicographically greatest state hash so selection is order-independent.
- Missing, malformed, unsupported, integrity-failed, and corrupt-local recovery states receive distinct guidance.

### Resignation and terminal states

- Ordinary victory ends at 10 or more canonical VP and rejects later gameplay actions.
- A local victory leads with `Victory!` and the concise winning score (`10 points` in the standard fixture). The decisive summary says the city, settlement, or Victory Point `secured the victory`; award-winning actions use `Gaining Longest Road` or `Gaining Largest Army` with canonical casing.
- Any active joined player can resign during setup or turn after a centered tabletop confirmation with explicit `Keep Playing` and destructive `Resign` actions, provided at least one active player remains.
- Resignation is non-terminal. The player stays in roster/history; their pieces remain inert blockers, their hand returns to the bank, development cards retire, and all active rules skip them. Existing players continue from the next legal setup slot or turn.
- Any active player can propose a draw. The proposer automatically approves; every remaining active player must approve. Rejection clears the proposal and play continues, with no timeout.
- The original inviter remains host even after resigning and can end unilaterally. A centered tabletop confirmation leads with `Propose Draw` when no draw has been attempted while retaining destructive `End Game Anyway` and an explicit `Keep Playing` action.
- Agreed draw and host end are neutral terminal results: no winner is declared, while final scores, recap, and board remain inspectable. Victory continues to present the winner.
- `New Game` returns to the fresh invitation entry without sending, rematching, or archiving the completed game.

### Host Adaptation

- Layout derives from the controller-owned, settled host bounds and safe-area insets, never a hard-coded device model or `UIScreen`.
- The complete Messages-assigned canvas is used after the host settles. Intermediate compact/expanded, rotation, Split View, and Stage Manager measurements do not recompose the product.
- Players, Games, Hand, Build, Trade, Dev Cards, forced actions, confirmations, and tutorial guidance are state-static layers: opening them cannot change the host revision, mounted board, or fixed rails.
- The board remains live during a genuine host transition and updates its canonical-aspect viewport/camera in place after the settled snapshot commits.
- Only the narrow top grabber region may hand dragging back to Messages; board and shelf gestures remain local elsewhere.
- Wide but vertically short hosts use the compact lower-surface layout instead of clipping phone or iPad assumptions.
- The lower visual region retains at least 12 points of total host-edge clearance after counting the system bottom safe area; only the missing clearance is added.
- Real-device iPad proof remains required before responsive adaptation is considered fully verified.

## Known Contract Gaps

| ID | Type | Current mismatch | Required disposition |
| --- | --- | --- | --- |
| UI-GAP-003 | Pending proof | Responsive host logic exists and has focused tests, but connected-iPad visual approval remains pending. | Complete both real-iPad entry-path checks before calling the adaptation verified. |

## Evidence Anchors

Material behavior is currently exercised by:

- lobby model, membership, identity, and preferred-name tests;
- setup placement, board-commit, turn-action, discard, robber, trade, Dev Card, and game-over presentation tests;
- transcript copy, image-family, session, and recovery tests;
- board resize/layout tests and installed Messages-host UI journeys;
- the full seventeen-state tutorial replay: navigation veil plus sixteen lessons.

These tests prove current implementation behavior. Judgment requirements and pending real-device proof remain governed by the active ExecPlans and owner checkpoints.
