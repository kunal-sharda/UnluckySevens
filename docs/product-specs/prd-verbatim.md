Unlucky Sevens (Catan IMessage Game)
1. Vision & Objective
Create a full‑length, async board‑strategy game called Unlucky Sevens for iMessage that
captures the core experience of Catan. The game should be playable end‑to‑end inside Messages
bubbles (similar to Gamepigeon), support 3-4 players, and ultimately be modifiable to fit the
groups’ needs (time limits, house rules, etc.).
This document describes the user experience and specific design choices to make this digestible
in an iMessage format. It is an evolving document, with the full Catan rules contained in the
appendix. It is not a technical specification, which is present in a different document.
2. Ideal-ish User Experience Flow
1. Match Invitation ⇒ iMessage bubble with “Join Unlucky Sevens” link.
2. Generate Board ⇒ this needs to be a fair board with a semi-even distribution across all
resources. With that being said, this should be an RNG board with seeds, so there should
be potential for there to be non-even boards as in the spirit of the game. Harbors,
numbers, and resources distributions should all be placed at this stage.
○
*Robber should be on the desert to begin with
○
There should be a way to set fairness of the board, i.e. what sort of distribution
does the group want for the game.
○
There should be a way for players to toggle certain settings:
i. Do not let 6s and 8s touch.
ii. Desert is only on coast or off-center
iii. Same resource as port
iv. Friendly Robber: a player must have greater than 2 VPs before a tile that
they are on is targeted by the robber


3. Initial Placement (2 settlements
+
roads) via interactive board. Get resources from the
second settlement. Settlements are done in a snake draft with a random order set at game
start. The distance rule applies here, wherein any settlement can only be placed if there is
no adjacent settlement or city (must be at least two edges away).
4. Turn Screen (single GameKit hand‑off)
○
Phase 0 - Play development card: At any point during a player’s turn, they can
play exactly one development card from their hand that they acquired in a
previous turn. If the player built a development card this turn, then they may not
play that specific card.
i. Knight: move the robber to any tile, and if there are any players on that
tile (excluding oneself), the steal pop-up allows the active player to select
a target. The active player gets a card at random from the target.
ii. Monopoly: the active player can select a resource out of the 5 potential
resources to acquire. All of the resources of that type that are in any of the
other players’ hands are given to the original player.
iii. Year of Plenty: the active player can choose any two resources and add
them to their hand. These can be the same or different resources.
○
iv. Victory Point: this is a special development card. The player cannot play
this card, but at any point if a victory point helps the player reach the
desired amount of VPs to win the game (usually 10 in a standard game),
this card is auto revealed and the player wins the game.
v. Road builder: the active player enters build mode (as described during
the build phase) and may place up to two roads.
Phase 1 – Roll: dice ⇒ resources auto‑dealt based on either city (2 per touching
tile) or settlement (1 per touching tile) existing.
i. Robber Event:
1. When a 7 is rolled, players with >7 resource cards receive an
auto‑generated discard mini‑turn.
2. Active roller drags robber to any tile
3. If there are any players on that tile (excluding oneself), the steal
pop‑up allows the active player to select a target.


○
4. The active player gets a card at random from the target.
ii. If a robber is on any tile, that tile does not generate resources even if the
number for that resource is rolled
iii. If any resource runs out due to player payouts, no one gets that resource
and it remains at the original count in the bank
Phase 2a – Trade: optional Trade Drawer opens with the ability to compose
Bank, Port, or player to player offers.
i. If P2P option, compose a message in chat for this. Another player can
accept, but table talk before the turn is encouraged.
ii. In more competitive settings, there could be a timer before anyone can
accept the trade to encourage table talk.
iii. Peer‑to‑Peer/Peer-to-Port/Peer-to-Bank Trade Experience
1. Goals
a. Complete common trades in ≤ 3 taps.
b. Keep Bank/Port trades distinct from P2P offers.
c. Maintain hand secrecy so that no UI element reveals
another player's resource counts or types. However, you
should be able to see the total number of cards that a player
has.
i. Clarification note: although the authoritative state
contains the full hands, the UI must only reveal the
opponent’s hand count/size.
2. Interaction Flow
a. The player taps the Trade drawer.
b. Modal presents two tabs: Bank / Port and Players.
c. Players tab lists opponents by avatar + name only (no
resource icons or quantities). Each player should have the
number of cards they have under their avatar + name.
d. Offer Composer:
i. Two vertical stacks labelled Give and Get.


ii. Each stack shows five resource chips with +/-
steppers (or tap‑to‑cycle 0 ⇒ 1 ⇒ 2 ⇒ 3).
iii. Players adjust counts to craft an offer, i.e. Give 2
wood ⇒ 1 Brick
e. Review Offer screen summarizes deal; player hits Send. A
pop up saying that table talk in the group chat is
encouraged before the trade offer should be visible here.
f. Optionally, you can specify a recipient for the trade, but the
trade would still be within the group chat.
g. Recipient or table receives inline bubble:
“Player” offers 2 wood for 1 brick — [Accept] [Decline].
This would be through a message in the group chat.
i. Accept completes the trade immediately: both
players’ hands update at once, and the offer is
closed in the chat thread.
h. The main player is the only one that can propose trades, so
they can edit this based on table talk, before the trade is
accepted.
i. Trades must be atomic and completed before the End Turn
phase, wherein they will go stale. They may also go stale
after 12 hours of non-interaction, which can be
configurable in the settings.
3. Port Quick Trades
a. Ports are enabled by either a city or a settlement on the
node that shares the port.
b. On the Bank / Port tab, the composer auto‑applies the best
ratio (4:1 base, 3:1 generic, 2:1 specific) based on ports the
active player owns.
c. One‑tap Confirm executes the trade.


○
Phase 2b – Build: build Mode highlights legal nodes/edges, the player then
places roads/settlements/cities. They can also optionally build a development
card.
i. Legality:
1. For settlements: there must be a settlement in hand, and there must
be at least one road leading up to it with the distance rule applying
here as well: there can be no settlement or city on an adjacent node
(>1 edge away at least).
2. For cities: there must be a city left in hand, and it must replace a
settlement.
3. For roads: there must be a road left in hand, and it must connect
○
from a previous road or settlement/city.
ii. There should only be options to build items that are possible (i.e. a road
can only be built if the player has a wood and a brick, etc.)
Phase 2c – Win Condition Check: If at any point during the build phase, the
player has 10 VPs (or greater), they auto win, and the game goes to the Win
Screen.
i. This phase includes checking for the largest army or longest road.
○
Phase 3 – End Turn: commits state & renders snapshot bubble to the chat.
5. Win Screen with confetti + shareable stats.
2. Core Gameplay Components
Category MVP Phase 2+
Board 19‑tile classic hex layout
(randomized setup).
Ports:
●
4 generic 3:1
Scenario maps, mini‑boards,
and map rerolls.


Category MVP ●
5 2:1 corresponding to each
resource
Players 3–4 players with async turns. Resources Wood, Brick, Wheat, Sheep, Ore,.
There are 19 of each resource.
Resources can be depleted.
Dice Roll 2× D6 roll; 7 triggers Robber. Build Options Road: 1 wood and 1 brick.
Settlement: 1 wood, 1 brick, 1 sheep,
1 wheat.
City: 3 ore, 2 wheat.
Development cards: 1 sheep, 1 ore, 1
wheat.
Trading Player ↔ Player & Bank (4:1, 3:1,
2:1).
Robber Drag robber to new tile, steal 1 card. Cities, Settlements, and
Roads
Players have a piece supply of 5
settlements, 4 cities, and 15 roads.
Largest Army and
Longest Road
Largest Army: player has >2 knights
played and the largest in the game.
Gains 2 VPs.
Phase 2+
Optional 2‑player duels + AI
fill‑ins.
TBA
Animated roll + shake‑to‑roll
gesture.
TBA
Smart suggestions, trade
history.
Optional seven = desert event
trigger, Event animations..


Category MVP Longest Road: player has >4 roads
connected with no breakages (i.e. no
other roads in the middle any other
players). Gains 2 VPs.
Development Cards 14 knight cards: move the robber.
5 victory point cards: automatically
turn over when the user could make
it to 10 Victory Points.
2 Road Builder cards: add two roads
when played with road limitations.
2 Year of Plenty cards: add 2
resources to hand.
2 Monopoly Cards: retrieve all
instances of resource from every
player’s hand
Once depleted, there are no more
development cards.
Victory First to 10 VP. 3. Platform & Technology
Phase 2+
TBA
TBA


●
●
●
●
●
●
Client: iMessage App Extension written in SwiftUI.
Multiplayer:Fully in iMessage Turn‑Based Matches.
State Payload: GameState ⇒ JSON Data ≤ 64 KB per turn.
○
Authoritative GameState is stored in matchData and includes board, VP, and full
hands (resource + dev) for each player. The UI enforces secrecy by showing
opponents only handSize (total card count), not types or per-resource counts.
Devices may cache decoded hands locally for performance/UI, but matchData is
the source of truth.
Graphics: SpriteKit for hex board rendering ⇒ snapshot PNG for bubble.
Group Chat: Runs inside an iMessage group thread. This is presented as an invite
bubble that the user sends into a group thread (existing or newly created by the user).
RNG Setup: Dice and board setup is done using deterministic RNG. Record the seed for
board and dice if needed.
5. Milestones & Timeline
Phase Deliverables
0 – Pre‑Prod Art style guide
Updated PRD
1 – Engine GameState model
Board gen
Turn logic
2 – Core UI Hex renderer
Tap‑to‑build
Dice animation
3 – Trades, Robbers
& Dev Cards
P2P trading UX


Phase Deliverables
Robber workflow
Development Cards
4 – iMessage Glue Bubble snapshot
5 – Beta & Polish Crash handling
Performance
6. Success Metrics
●
●
●
●
≥ 90 % games reach completion without state desync: ensuring that there are no issues
with the game integrity as an IMessage Game
Avg. active‑player turn time ≤ 2 min: measure of an easy to understand UX flow
Session resume lag ≤ 3s
Game satisfaction ≥ 4/5: overall ratings on the game are high
7. Risks & Mitigations
Risk Mitigation
Payload size limits Delta encode board; compress snapshots.
Long async gaps Push‑notification nudges; optional 24 h turn timer.
8. Additional Requirements


8.1 Accessibility & Localization
●
●
Dynamic Type & V oiceOver labels for all buttons and resource icons.
Support for at least English in the first phase only (localized Strings file).
8.2 Telemetry & Analytics
●
●
Anonymous event logging: roll distribution, average turn duration, trade frequencies.
Opt‑in crash reporting via Firebase Crashlytics (or Sentry).
8.3 Launch
●
●
Cosmetics store (player‑color skins) – non‑gameplay.
One‑time unlock to host unlimited concurrent matches.
8.4 Privacy & Compliance
●
●
●
No collection of personal data beyond Game Center ID.
GDPR/CPRA opt‑out toggle.
Age 13+ rating (no in‑app chat beyond standard iMessage).
9. Open Questions (as they come up)
1. Are we handling authorization in this initial design?
a. No, as authorization complexities come up, they may be addressed, but assume
that they are built in line with Apple standards
2. Are we handling hand secrecy + matchData?
a. No, assume that all people playing are friends/do not want to cheat. This may be
addressed in the future, but it is more important to have a launch first. The game
is social/group chat game, so if a player is consistently cheating, they can be
caught and shamed socially.


Appendix
Catan Rules
●
Objective
○
wins).
Be the first player to reach 10 Victory Points (VP) on your turn (immediately
●
Setup
○
Build the island with 19 hex tiles (resources: wood, brick, wheat, sheep, ore; 1
●
●
desert).
○
Place number tokens (2–12) on non-desert tiles; robber starts on the desert.
○
Each player, in snake order (1→N, N→1), places:
■ 1 settlement on any vertex + 1 connected road.
■ Then a second settlement + road (reverse order).
○
Starting resources: collect 1 of each resource from the second settlement’s
adjacent tiles.
Turn Structure (one handoff)
○
Play 1 development card (optional; restrictions below) at any time.
○
Roll 2d6:
○
If 7: see “Robber”.
○
○
○
○
Else: all tiles with that number produce (see Production).
Trade (optional): with players and/or Bank/Ports.
Build/Buy (optional): roads, settlements, cities, development card.
End turn.
Production
○
For each producing tile:
■ Adjacent settlement owners gain 1 of that resource.
■ Adjacent city owners gain 2 of that resource.
■ Robber-blocked tiles produce nothing.
●
Trading


●
●
●
○
Domestic trade: propose any deal with any players; all terms allowed.
○
Bank trade: 4:1 of one resource for any 1.
○
Ports (if you own a settlement/city at that port):
■ 3:1 (generic) or 2:1 (specific resource) with the bank.
Building (costs & rules)
○
Road = 1 wood + 1 brick
■ Place on an edge connected to your network (road/settlement/city).
○
Settlement = 1 wood + 1 brick + 1 wheat + 1 sheep
■ Must be at a vertex connected to your road and obey the distance rule: no
other settlement/city on adjacent vertices (1 edge away).
○
City (upgrade) = 2 wheat + 3 ore
■ Replace your settlement at that vertex (remove the settlement piece).
○
Piece limits: per player 15 roads, 5 settlements, 4 cities; you cannot build beyond
your supply.
Robber (rolling a 7 or playing Knight)
○
Discard: any player with >7 resource cards discards half (rounded down).
○
Move robber to any tile; that tile is blocked until robber moves again.
○
Steal 1 random resource from one opponent with a settlement/city on that tile.
Development Cards (buy: 1 wheat + 1 sheep + 1 ore)
○
Types:
■ Knight: move robber + steal 1 (counts toward Largest Army).
■ Road Building: place 2 roads for free (obey placement rules).
■ Year of Plenty: take any 2 resources from the bank.
■ Monopoly: choose a resource; all other players give you all of that
resource.
■ Victory Point: +1 VP, kept hidden until it is possible to reach 10 points
with the VPs to win. If so, those are automatically turned over.
○
Play limits:
■ 1 dev card per turn.
■ You cannot play a dev card on the same turn you bought it (except you
may reveal VP to win).


●
●
●
■ Dev cards are not tradable.
Special Awards
○
Longest Road (2 VP): longest continuous road of ≥5 edges; can change hands.
■ An opponent’s settlement breaks your continuity; your own does not.
○
Largest Army (2 VP): first to have played ≥3 Knights; can change hands.
Other Rules & Clarifications
○
Bank is finite: if the bank runs out of a resource, no one can take more of it until
returned. This means that if a bank resource runs out as players are trying to
collect it (i.e. 3 wheat left, but all 4 players need to pick up a wheat), then no one
gets to pick up the resource and all players must return the wheat until it is
possible to pick up the resource without it running out.
○
Hand size: no max hand size (only the robber’s discard on 7).
○
Build timing: you may build/trade in any order after rolling; place pieces
immediately upon paying.
Winning: the moment you reach 10+ VP on your turn, you win immediately.
