# App Language Audit

Status: tutorial wording approved on 2026-08-08 and synchronized into production.

This audit covers player-facing language in the Messages extension and records the implemented verbal contract. [UI Flows](../product-specs/ui-flows.md) remains the behavior contract; [Design](../../DESIGN.md) owns visual language.

For tutorial copy, this document is the human editing worksheet. Runtime truth remains the Swift source until an approved worksheet edit is deliberately synchronized into `GameTutorialStep.swift`, `GameTutorialStrategyCardView.swift`, or `GameTutorialView.swift`. Editing this Markdown file alone does not change the app.

## Verdict

The app does not need a new tutorial layout to fix its immediate voice problem. It needs a deliberate copy pass in `GameTutorialStep` first.

At normal text sizes, the tutorial shows only the short coach-mark callouts over the production UI. The lesson title and guidance are exposed through accessibility, and they become visible in the large-text guide. That means all three layers still need editing, but the visible callouts are the highest-priority change.

The broader app has a systemic copy problem rather than a handful of bad sentences: player language is scattered across 99 production Swift files. A mechanical scan found 1,248 raw string-literal matches and 803 likely copy-bearing references after excluding DEBUG-only developer files. These are candidate references, not 1,248 unique visible phrases.

## Proposed Voice

Unlucky Sevens should sound like a calm friend hosting the table:

- concise, warm, and direct;
- lightly playful through rhythm, not jokes;
- precise about rules without sounding like the rules engine;
- focused on what changed or what the player can do next;
- comfortable using established Catan terms when they genuinely help.
- free of semicolons in player-facing copy. Use one short sentence or split the thought.

The app should not sound like:

- an implementation log: `publishes setup state`, `local identity`, `authored from this device`;
- a legal-state inspector: `legal mixed list`, `current phase/step`, `targeted player responses`;
- a dense rulebook: `adjacent producing tile`, `eligible steals`, `non-VP development-card action`;
- a generic tutorial generator: `The real ... surface with ... visible`.

## Copy Roles

| Role | Job | Preferred shape |
| --- | --- | --- |
| Control | Name the action | 1–3 words: `Send Invite`, `End Turn` |
| Upper amber instruction | Name the immediate choice | 2–5 words: `Choose a Piece` |
| Coach mark | Teach one thing beside the real object | One sentence fragment, ideally no more than 9 words |
| Status | Explain what the table is waiting for | Actor or event first: `Waiting for Maya` |
| Help/rules | Explain one rule accurately | One plain sentence; introduce jargon only when needed |
| Transcript receipt | Record what happened | Concise past tense with the player name |
| Error | Say what failed and what to do | Human problem plus recovery; no raw engine error |
| Accessibility | Preserve action, state, and consequence | Natural spoken language; may be more explicit than visible copy |

## Vocabulary Contract Proposal

| Prefer | Avoid in player copy | Reason |
| --- | --- | --- |
| `table` (approved) | `roster`, `pending roster` | Matches the physical game metaphor; roster remains internal |
| `send` / `sent` (approved) | `publish`, `publication` | Describes what players experience in Messages; publishing remains internal |
| `available` / `glowing` (approved) | repeated `legal` | The UI already encodes legality visually; reserve legal for precise rules explanations |
| `Bank or Port` (approved through the amber-heading review) | `Maritime / Bank`, `maritime quick trade` | More recognizable to ordinary players |
| `Dev Cards` in compact controls; `development cards` in prose (approved) | `Play Dev`, `development-card action` | Removes abbreviation and hyphen drift |
| `Victory Point card` in prose; `VP` only in compact scoring UI (approved) | `VP card`, `non-VP` outside compact scoring | Easier for new players |
| `players` / player names (approved) | `recipients`, `targeted players` | Human rather than protocol language |
| `victim` or `choose who to steal from` (approved) | — | `Victim` is concise and acceptable in player-facing game language |
| `your cards` / `your hand` (approved) | `current hidden hand` | Privacy is a system constraint, not player-facing prose |

## Tutorial Copy Worksheet

This is the consolidated 2026-08-07 proposal for owner review. It does not yet describe production copy. The approval and implementation boundary is tracked in [Tutorial Language Redraft](../exec-plans/active/tutorial-language-redraft.md).

- **Title** names the lesson in the progress label, VoiceOver heading, and large-text guide.
- **Visible coach mark** is the primary tutorial. It must carry every essential rule or action because most players will never see the accessible guide.
- **Accessible guidance** adds spoken precision for VoiceOver and the large-text guide. It must not repair missing visible meaning.
- **Preview description** tells VoiceOver what meaningful visual state appears in the otherwise non-interactive preview.

Source mapping:

- Steps 1–16: `MessagesExtension/Sources/Presentation/GameTutorialStep.swift`
- Final Strategy card: `MessagesExtension/Sources/Features/Tutorial/GameTutorialStrategyCardView.swift`
- Navigation introduction and accessibility actions: `MessagesExtension/Sources/Features/Tutorial/GameTutorialView.swift`
- Shared gameplay headings: `GameSetupPlacementModel.swift` and `GamePhysicalTurnHeaderPrompt.swift`; changing those affects the real game as well as the tutorial.

### 1. Place Your First Settlement

- **Title:** “Place Your First Settlement”
- **Accessible guidance:** “Each player places one settlement with a connected road. After everyone places once, the order reverses for the second settlement and road.”
- **Visible coach marks:**
  1. “Everyone places a settlement and road twice. Round two goes in reverse order.”
  2. “First, place a settlement on a glowing corner.”
- **Preview description:** “Setup board showing the placement order and glowing settlement locations.”

### 2. Add a Road

- **Title:** “Add a Road”
- **Accessible guidance:** “Place a road on a glowing edge connected to your settlement. After your second settlement, collect one resource from every neighboring producing tile.”
- **Visible coach marks:**
  1. “Next, place a road connected to your settlement.”
  2. “Your second settlement gives you starting resources from the tiles it touches.”
- **Preview description:** “Setup board showing glowing road locations beside the new settlement.”

### 3. Roll to Begin

- **Title:** “Roll to Begin”
- **Accessible guidance:** “Every normal turn begins with a roll. If you have a playable Dev Card, you may play it before rolling.”
- **Visible coach mark:** “Roll to see which numbered tiles produce. You may play a Dev Card first.”
- **Preview description:** “Start-of-turn table with Roll and a playable Dev Card available.”

### 4. Follow the Roll

- **Title:** “Follow the Roll”
- **Accessible guidance:** “When the rolled number matches a tile, each neighboring settlement collects one matching resource and each neighboring city collects two. The robber prevents its tile from producing.”
- **Visible coach marks:**
  1. “Matching tiles give one resource per settlement and two per city.”
  2. “The robber stops its tile from producing resources.”
- **Preview description:** “Post-roll board showing a matching numbered tile, neighboring buildings, and a robber blocking another tile.”

### 5. Check Your Hand

- **Title:** “Check Your Hand”
- **Accessible guidance:** “Open your Hand to see the resource cards you can spend and the Dev Cards you own.”
- **Visible coach mark:** “Open your Hand to see your resources and Dev Cards.”
- **Preview description:** “Open Hand showing owned resource cards and Dev Cards.”

### 6. Choose What to Build

- **Title:** “Choose What to Build”
- **Accessible guidance:** “Each road, settlement, and city shows its resource cost. Building a city upgrades one of your settlements.”
- **Visible coach mark:** “Each piece shows its cost. A city upgrades one of your settlements.”
- **Preview description:** “Build choices showing roads, settlements, cities, and their resource costs.”

### 7. Choose a Glowing Corner

- **Title:** “Choose a Glowing Corner”
- **Accessible guidance:** “Available settlement locations glow. Tap one twice to confirm the build. Settlements must be at least two road lengths apart.”
- **Visible coach mark:** “Tap a glowing corner twice. Settlements must be two road lengths apart.”
- **Preview description:** “Board showing the glowing corners where a settlement can be built.”

### 8. Make an Offer

- **Title:** “Make an Offer”
- **Accessible guidance:** “Choose the cards you will offer, then choose the cards you want in return.”
- **Visible coach mark:** “Choose what you’ll offer and what you want back.”
- **Preview description:** “Player-trade offer showing Give and Get card selections.”

### 9. Choose Who Gets It

- **Title:** “Choose Who Gets It”
- **Accessible guidance:** “Choose one or more players and send the offer. Their accept, decline, or counter response returns through Messages.”
- **Visible coach mark:** “Choose the players, then send your offer.”
- **Preview description:** “Player-trade offer showing the players available to receive it.”

### 10. Trade with Bank or Port

- **Title:** “Trade with Bank or Port”
- **Accessible guidance:** “Choose a Bank or Port trade. The list automatically shows the best rate you can use.”
- **Visible coach mark:** “Your best Bank or Port rate is already shown.”
- **Preview description:** “Bank or Port trade list showing the best available exchange rate.”

### 11. Discard on Seven

- **Title:** “Discard on Seven”
- **Accessible guidance:** “When a seven is rolled, players holding more than seven cards discard half their hand, rounded down, before the robber moves.”
- **Visible coach mark:** “Holding 8+ cards when a seven rolls? Discard half, rounded down.”
- **Preview description:** “Discard screen showing the required number and the resource cards available to discard.”

### 12. Move the Robber

- **Title:** “Move the Robber”
- **Accessible guidance:** “After a seven or Knight, move the robber to a different glowing terrain tile. That tile cannot produce while the robber remains there.”
- **Visible coach mark:** “Move the robber to a different glowing tile. That tile stops producing.”
- **Preview description:** “Board showing the glowing tiles where the robber can move.”

### 13. Choose a Victim

- **Title:** “Choose a Victim”
- **Accessible guidance:** “Select a glowing settlement beside the robber to choose that player. You steal one random resource card from them.”
- **Visible coach mark:** “Choose a neighboring player to steal one random resource from.”
- **Preview description:** “Board showing the neighboring players available for the robber steal.”

### 14. Play a Dev Card

- **Title:** “Play a Dev Card”
- **Accessible guidance:** “You may play one non-Victory Point Dev Card per turn. A card bought this turn cannot be played until your next turn.”
- **Visible coach mark:** “Playable cards glow. Play one per turn. Bought cards wait until next turn.”
- **Preview description:** “Dev Card chooser showing which owned cards can be played now.”

### 15. Send the Turn

- **Title:** “Send the Turn”
- **Accessible guidance:** “End Turn confirms your actions and sends the updated game to the next player through Messages.”
- **Visible coach mark:** “End Turn sends the updated game to the next player in Messages.”
- **Preview description:** “End Turn confirmation ready to send the updated game.”

### 16. Strategy

- **Title:** “Strategy”
- **Accessible guidance:** “Numbers with more dots roll more often. Five connected roads can earn Longest Road, and three played Knights can earn Largest Army. Each award is worth 2 points. Settlements are worth 1 point, and cities are worth 2. The first player to 10 points wins.”
- **Visible coach marks:** none; this lesson uses the Strategy card below.
- **Preview description:** “Board dimmed behind a Strategy card with production, building, and scoring tips.”

#### Strategy card

- **Eyebrow:** “QUICK TIPS”
- **Title:** “Strategy”
- **Tip 1 title:** “Follow the dots”
- **Tip 1 description:** “More dots mean that number rolls more often. Build nearby to collect more resources.”
- **Tip 2 title:** “Build toward points”
- **Tip 2 description:** “Roads reach new settlement spots. Longest Road (5+) and Largest Army (3+) are worth 2 points.”
- **Tip 3 title:** “Race to 10”
- **Tip 3 description:** “Settlements are 1, cities are 2, and awards are 2 points each.”

### Tutorial navigation

Visible introduction:

- “Tap left”
- “Back”
- “Tap right”
- “Next”
- “Tap anywhere to begin”

Accessibility actions and hints:

- “Tutorial navigation”
- “Tap anywhere to begin. Then tap left to go back or right to continue.”
- “Exit tutorial”
- “Previous tutorial step” / “Goes to the previous tutorial step”
- “Next tutorial step” / “Goes to the next tutorial step”
- “Finish tutorial” / “Closes the tutorial”

### Editing and implementation workflow

1. Review and revise the complete quoted proposal in this worksheet without changing lesson IDs, ordering, rules, or shared production headings.
2. Record explicit owner approval in the active Tutorial Language Redraft plan. The Markdown proposal does not change the app.
3. Synchronize the approved fields into their mapped Swift source files.
4. Update copy-sensitive tests and accessibility assertions without weakening behavioral coverage.
5. Run the locked proof set: focused copy/model tests plus the seventeen-state Navigation-and-sixteen-lessons capture on the canonical iPhone 17 simulator.

## Upper Amber Instruction Review

Amber instructions serve a different voice role from tutorial coaching. They should be terse and functional, not playful. Most of the current set already works.

| Current heading | Recommendation | Reason |
| --- | --- | --- |
| `Choose Dev or Roll` | Remove from this inventory (approved) | It is not currently emitted. The pre-roll choice layer explains itself. |
| `Choose a Piece` | Keep | Short and concrete |
| `Place a Road` | Keep | Matches the board action |
| `Tap Again to Place` | `Tap Again to Build` | States the result rather than the gesture alone |
| `Place a Settlement` | Keep | Matches the board action |
| `Upgrade to a City` | Keep | Explains what happens to the settlement |
| `Tap Again to Upgrade` | Keep | Clear confirmation instruction |
| `Choose a Trade` | `Choose How to Trade` | Distinguishes player trade from Bank or Port |
| `Make an Offer` | Keep | Natural and concise |
| `Trade with the Bank` | `Trade with Bank or Port` | The options may use a controlled port rate |
| `Waiting for Players` | `Waiting for Replies` | Makes clear that the sent offer is awaiting responses |
| `Answer the Trade Offer` | `Review the Offer` | Less stiff and does not imply a single required response |
| `Waiting for Discard` | `Waiting for Other Players` | Use when the local player is passively waiting for required discards |
| `Choose a Dev Card` | Keep | Matches the compact control vocabulary |
| `Move the Robber` | Keep | Canonical game term and direct action |
| `Choose a Player` | `Select a Settlement Beside the Robber` | Names the actual on-board gesture used to choose the victim |
| `Choose a Resource` | Keep | Direct and unambiguous |
| `Choose Two Resources` | Keep | Direct and unambiguous |
| `Choose One More` | Keep | Correctly reflects the in-progress selection |
| `Place First Road` | `Place the First Road` | Natural spoken grammar |
| `Place Second Road` | `Place the Second Road` | Natural spoken grammar |

`Choose Dev or Roll` is approved for removal. `Choose How to Trade` is the approved trade-chooser heading.

## App-Wide Findings

### P1 — Internal implementation language reaches player surfaces

Examples:

- `Starting publishes the setup state and locks the roster.`
- `You are in the pending roster for this lobby.`
- `Trade actions need your joined local Messages identity before they can be authored from this device.`
- `No legal development-card play is available from the current state.`
- `Do not start from this post-send shell.`

Impact: players are asked to understand transport, identity, and state-machine concepts to play a board game.

Direction: explain the situation and next step only. For example, `Send the invite, then reopen the newest table message after everyone joins.`

### P1 — Raw technical errors can be displayed

`LobbyDriverViewModel` prefixes many `error.localizedDescription` values and sends them to the visible lobby warning. Some errors contain terms such as payload, active context, intent anchor, revision, or phase/step.

Impact: failures feel unsafe and unrecoverable, and may reveal implementation detail without helping.

Approved direction: map known failure families such as send failure, stale message, missing player identity, and invalid action to specific recovery copy. Visible errors state the human problem and one recovery action. Only unknown failures use a generic fallback. Keep the raw diagnostic in DEBUG logging only.

### P1 — Tutorial teaching copy is over-layered

Each lesson owns a title, guidance paragraph, one or more coach marks, and an accessibility preview description. The four layers do not have clearly different jobs.

Impact: standard-size copy feels terse and robotic while large-text and VoiceOver copy becomes repetitive.

Direction: title names the lesson, coach mark points to the next action, guidance explains the rule once, and the preview label describes only non-text visual state needed by VoiceOver.

### P1 — Trade and Dev Card language is rules-engine-shaped

Trade uses `Trade Desk`, `targeted player responses`, `maritime / bank quick trades`, `current hidden hand`, and `Replace Offer`. Dev Cards use `non-Victory Point development-card action`, `board or bank selection flow`, `eligible steals`, and `full two-road pair is legal`.

Impact: the two most complex gameplay surfaces also demand the most translation.

Direction: lead with the concrete choice. Put exceptional timing rules beside the affected card, not in a general system paragraph.

### P2 — Terminology and capitalization drift

Current variants include:

- `Dev Cards`, `Dev Card`, `Play Dev`, `development cards`, and `development-card action`;
- `Year Of Plenty` and `Year of Plenty`;
- `Maritime Trade`, `Maritime / Bank`, `bank trade`, and `Bank or Port`;
- `Lobby`, `table`, `roster`, and `joined players`.

Impact: the app feels assembled surface by surface.

Direction: approve the vocabulary table above and enforce it through focused copy types and exhaustive tests.

### P2 — Lobby copy repeats process instead of welcoming players

The release lobby includes title, subtitle, helper, empty-state description, status label, footer, and disabled-action hint. Several repeat how Messages state is sent and reopened.

Impact: the first-run experience feels administrative.

Approved structure: one invitation sentence, one name prompt, one table-status sentence, and one primary action. Recovery details appear only when recovery is actually needed.

Approved guest-invite heading: `Join the Table`.

Approved guest-invite sentence: `[Host] invited you to play Unlucky Sevens.`

Approved name-field label: `Display Name`.

Approved live table-status copy: `[Count] player(s) at the table`, with natural singular and plural forms.

Approved joined-guest state: heading `You're In` with status `Waiting for [Host] to start.`

Approved fresh host-invite heading: `Start an Unlucky Sevens Game`.

The fresh host-invite screen has no subtitle.

Approved host waiting heading: `Waiting for Players`, shown above the live player list and count until the game can start.

Once the game can start, use `Ready to Start` with the `Start Game` action and no explanatory subtitle or helper text.

### P2 — Some upper instructions are ambiguous

The full heading review above finds seven copy changes and two unused cases. The most important corrections are `Waiting for Replies`, `Review the Offer`, and `Trade with Bank or Port`.

Direction: approve the heading table as a separate terse action vocabulary. Do not make amber prompts carry tutorial explanation.

### P2 — Accessibility copy is thorough but not consistently natural

There are 155 explicit accessibility label, hint, or value references. Coverage is a strength, but several hints expose UI structure (`full-screen dice bowl`, `pre-roll Dev Card chooser`) or repeat visible labels without adding consequence.

Direction: retain the strong state coverage while rewriting for spoken comprehension: action, current value, and result.

## Approved Surface Cleanup

- Lobby keeps only the guest invitation, the joined guest's `Waiting for [Host] to start.`, and the necessary post-send instruction. The other subtitle and helper layers, including Display Name helpers, are removed.
- The post-send state uses `Invite Sent` with `Return to the chat. Reopen the latest invite to see who joined.` and no additional helper.
- Setup keeps its glowing legal targets in both rounds. Only the first placement pair receives explanatory copy: `Choose a glowing corner.` and `Choose a glowing road beside your settlement.`
- Generic gameplay-mode subtitles are removed when the amber instruction, glowing targets, or active component already communicates the action.
- Monopoly keeps `Choose a resource to collect from every opponent.` beside the Bank. Year of Plenty keeps `Choose two resources from the Bank.` beside the Bank.
- Forced discard uses `Discard Cards` and `Choose exactly [N] cards` for the active discarder. Passive players see `Waiting for Other Players` with no subtitle.
- Compact turn status such as `Roll pending` and `Roll: 4 + 3 = 7` remains.
- Tutorial visible copy and the final Strategy card are approved. Accessibility descriptions drop the repeated `The real...` construction and describe only the action, relevant visual state, and result.
- Trade uses `Trade`, not `Trade Desk`. Redundant explanatory paragraphs are removed while offer details, player response statuses, and recovery messages remain.
- Dev Card timing and availability explanations appear only beside the affected card; rules-engine-shaped general paragraphs are removed.
- Recovered-game rows replace raw revisions, phase names, and truncated game IDs with useful player state such as player count and whose turn it is.
- Transcript bubbles preserve their concise event-receipt structure while adopting the approved vocabulary.
- Settings, rules reference, and game-over retain their current structure and receive terminology or natural-language cleanup only.
- The canonical card name is `Year of Plenty`.

## Surface Assessment

| Surface | Assessment | Rewrite priority |
| --- | --- | --- |
| Tutorial | Accurate but robotic and repetitive | First |
| Lobby/invite/waiting | Warm visual metaphor, administrative copy | First |
| Errors and recovery | Technical and inconsistent | First |
| Trade | Too much protocol and legality language | First |
| Dev Cards | Precise but over-explained and inconsistent | First |
| Upper amber instructions | Mostly concise and effective | Targeted |
| Setup/build/discard/robber | Generally clear; repeated `legal` and confirmation prose | Targeted |
| Transcript bubbles | Strongest voice: concise, named, past tense | Light polish |
| Settings | Clear and appropriately restrained | Preserve |
| Rules reference | Mostly good; simplify jargon after vocabulary lock | Light polish |
| Game information/game over | Compact and understandable | Preserve |

## Recommended Rewrite Sequence

1. Approve the voice, vocabulary, and tutorial sample.
2. Rewrite all tutorial titles, guidance, callouts, and preview accessibility labels together.
3. Replace technical lobby and visible error language.
4. Simplify Trade and Dev Card copy without changing action semantics.
5. Normalize terminology across upper prompts, rules, transcript receipts, and accessibility.
6. Introduce narrow copy owners and exhaustive tests by surface; do not create one unstructured global string dump.
7. Add localization infrastructure only when language support enters scope, but stop adding scattered literals now.

## Positive Findings

- Transcript receipts already use the right basic voice: player name, past-tense event, short next-state context.
- Primary control labels such as `Send Invite`, `Start Game`, `Roll`, `Build`, `Trade`, and `End Turn` are strong.
- Settings explains Skip Animations without implying that rules or dice outcomes change.
- Accessibility coverage is materially better than average; the problem is tone and duplication, not absence.
- The amber instruction system provides a good reusable home for concise action language once its vocabulary is locked.
