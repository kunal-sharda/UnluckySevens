# App Language Audit

Status: owner-approved and implemented, 2026-07-25.

This audit covers player-facing language in the Messages extension and records the implemented verbal contract. [UI Flows](../product-specs/ui-flows.md) remains the behavior contract; [Design](../../DESIGN.md) owns visual language.

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

## Tutorial: Current Visible Language

Normal-size lessons currently show these coach marks:

| # | Current title | Current visible coach mark(s) |
| --- | --- | --- |
| 1 | Place a Settlement | `Round two reverses the order`; `Tap a marked legal intersection` |
| 2 | Connect the Road | `Choose a connected marked edge`; `Settlement, then road` |
| 3 | Roll the Dice | `Roll first to produce resources` |
| 4 | Read Production | `The rolled number pays adjacent buildings`; `The robber stops this tile` |
| 5 | Use Your Hand | `These are your spendable cards` |
| 6 | Choose What to Build | `Compare costs; cities replace settlements` |
| 7 | Place on a Highlight | `Only highlighted targets are legal` |
| 8 | Offer a Player Trade | `Tap cards in Give and Get` |
| 9 | Choose Trade Partners | `Select players, then Send Offer` |
| 10 | Use the Bank or a Port | `Check the ratio, then confirm` |
| 11 | Discard After a Seven | `Choose exactly half your hand` |
| 12 | Move the Robber | `Move it to a highlighted tile` |
| 13 | Choose a Victim | `Tap Maya’s marked building` |
| 14 | Play a Development Card | `Bright cards are playable now` |
| 15 | End and Send the Turn | `Confirm to send the updated game` |
| 16 | Build a Strong Position | `Trade surpluses; watch both awards` |
| 17 | Win at Ten Points | `First to 10 · Settlement/VP card 1 · City/award 2` |

### Why It Sounds Robotic

- Most titles are taxonomy labels rather than a teaching voice: `Read Production`, `Use Your Hand`, `Place on a Highlight`.
- Several callouts describe the implementation instead of the object: `marked legal intersection`, `highlighted targets are legal`.
- Semicolon and dot-separated compression reads like generated summary text.
- The title, guidance, and callout often repeat the same fact in three registers.
- The accessibility descriptions repeat `The real ...` on every lesson, which sounds synthetic and adds no useful spoken context.
- Some guidance is grammatically accurate but unnaturally formal: `each adjacent producing tile adds its resource to your hand`.

## Tutorial: Recommended Visible Pass

This is the approved visible-copy direction:

| # | Suggested title | Suggested visible coach mark(s) |
| --- | --- | --- |
| 1 | Place Your First Settlement | `You place twice. Round two goes in reverse.`<br>`Start on a glowing corner.` |
| 2 | Add a Road | `Add a road beside your settlement.`<br>`Your second spot deals starting cards.` |
| 3 | Roll to Begin | `Roll to see which tiles produce.` |
| 4 | Follow the Roll | `Matching numbers pay nearby buildings.`<br>`The robber blocks this tile.` |
| 5 | Check Your Hand | `These are the cards you can spend.` |
| 6 | Pick a Build | `Each piece shows its cost. Cities replace settlements.` |
| 7 | Choose a Glowing Spot | `Tap a glowing spot twice to build.` |
| 8 | Make an Offer | `Pick what you’ll give and what you want.` |
| 9 | Choose Who Gets It | `Choose the players, then send the offer.` |
| 10 | Use Your Best Rate | `Your best Bank or Port rate is shown.` |
| 11 | Discard on Seven | `Choose half your hand, then confirm.` |
| 12 | Move the Robber | `Move the robber to a glowing tile.` |
| 13 | Choose a Victim | `Choose a neighboring player.` |
| 14 | Play a Dev Card | `Bright cards can be played now.` |
| 15 | Send the Turn | `End Turn sends the new board to the chat.` |
| 16 | Strategy | Replace the board callout with the three-tip Strategy card below |
| 17 | Remove | Merge scoring into Strategy instead of adding another tutorial step |

The accessible guidance should then add the precise rule that the short callout cannot hold. It should not repeat the same sentence or begin with `The real`.

### Strategy Card

The final lesson should be one centered tabletop card titled `Strategy`, not another board callout. A dark scrim greys the rest of the live board without unmounting it. The card contains three simple rows, not three nested cards:

1. **Read the dots**
   More dots under a number mean a stronger spot for that resource. Cover several resources when you can.
2. **Spend for points**
   Roads open new settlement spots and can earn Longest Road. Knights build toward Largest Army. Victory Point cards score 1.
3. **Know the score**
   Cities and awards (Longest Road and Largest Army) are worth 2 points. Settlements are worth 1 point each.

The probability tip must visually reference a number token with its dots. The second row explains when Roads and Dev Cards contribute to scoring without pretending that ordinary Roads or action cards score directly. The third row stays an immediately scannable scoring summary.

The card uses one cream tabletop surface, three icon-led text rows, and the existing invisible left/right tutorial navigation. It does not introduce close, expand, or nested-card controls. VoiceOver reads the title followed by the three tips in order.

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
| `Choose a Player` | Keep | The highlighted board supplies the steal context |
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
