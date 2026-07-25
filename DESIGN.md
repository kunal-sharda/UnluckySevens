# Design

This document owns the current visual language and calibrated product taste for Unlucky Sevens. [PRODUCT.md](PRODUCT.md) owns concise design-facing context; product behavior remains in the product specs.

## Scene

Three or four people return to a Catan table inside an iMessage thread in short, interrupted sessions. The interface must reorient them immediately, keep the board visually primary, and make the next legal action obvious inside a constrained Messages host.

## Visual Language

- Compact, tactile, and trustworthy: premium tabletop materials with product-level control density.
- Board first: supporting chrome yields to the canonical board, current actor, pending flow, and legal action.
- Physical but efficient: use printed cards, felt, tile seams, tokens, and stacks only when they improve scanability or ownership.
- Restrained color: dark felt and teal frame the play field; warm cream carries paper/tabletop surfaces; clay, moss, slate, and command blue communicate roles rather than decorate.
- Familiar controls: SF/system typography and standard interaction affordances are preferred unless a tabletop treatment makes the state clearer.

## Typography

- All player-facing typography uses the OS-provided **SF Pro** family through SwiftUI semantic system styles or `UIFont.systemFont`. The app never embeds or addresses downloaded SF Pro files by name.
- `GameTheme` owns the shared display, title, heading, body, metadata, and label hierarchy. Weight and size may change to communicate hierarchy; the type family does not.
- New York/system serif, SF Pro Rounded, SF Mono, Georgia, and custom bundled fonts are not part of ordinary interface typography. The sole exception is the geometry-bound board number token: it uses the OS-provided New York bold face with dice-probability pips beneath the numeral to read as a printed tabletop component rather than application chrome.
- `monospacedDigit()` is allowed for changing counts, dice totals, and aligned numeric data because it preserves SF Pro while stabilizing numeral width. A monospaced typeface is not allowed for ordinary text.
- Other SpriteKit labels, rendered transcript text, SwiftUI controls, and DEBUG UX Lab chrome follow the SF Pro family contract. Authored lettering inside resource illustrations is artwork rather than interface typography.
- Prefer semantic Dynamic Type styles. Fixed sizes are reserved for geometry-bound micro labels and board tokens and must remain legible at their supported host sizes.

## Component Vocabulary

- One compact command surface states the current phase or action.
- The active player’s normal post-roll screen is one fixed tabletop with five zones: compact top bar, public table rail, live board, reserved action well, and turn-object rail.
- On that screen, physical Bank and `Dev Cards` objects communicate public ownership. Exact public counts stay concealed; tapping Bank reveals only `H/M/L` levels in place. The local player’s resources and a two-card splayed owned-Dev entry prop are nested together inside Hand; tapping that prop opens the complete owned-card spread, with action keylines only on legally playable cards.
- Public and owned Dev Cards use a desaturated blue-gray family (`#71858B`) with a lighter steel edge. The public pile uses the approved factory vector in charcoal; the Trade prop uses the approved merchant-ship vector in warm wood. Every revealed public-pile level uses the same bold warm-white treatment over its faded card.
- The normal post-roll turn-object rail keeps stable `Hand · Build · Trade · End` anchors. Unavailable actions leave empty, hitless, accessibility-hidden space instead of disabled props or rearranged neighbors.
- Other gameplay states continue to use their existing lower-tray and shelf compositions.
- Overlays belong to one interaction owner and must not depend on controls underneath them.
- Settings is a compact centered felt utility card over the exact lobby or game surface that opened it. A restrained scrim preserves origin context; Rules pushes inside that card instead of replacing the host with a generic system screen.
- Tutorial coach marks sit beside anchored targets on the production game shell. Standard sizes use at most three numbered bubbles; accessibility sizes replace collision-prone bubbles with a numbered ordered guide. The one-time split veil explains invisible left/back and right/next navigation.
- Collapsed Messages previews reuse the game’s production table, board, resource, and score language. Lobby/setup/gameplay remain image-first; live player trades use one neutral public receipt with no response controls, and game over overlays a compact final-score strip without obscuring the board’s result.
- Opening or replacing an action-well surface must not resize, shift, freeze, or remount the live board, public rail, or top status.
- Number tokens, roads, structures, ports, robber, and legal highlights remain separate live board layers; production terrain textures live under `MessagesExtension/Resources/Assets.xcassets/BoardTiles/`.
- Icon-first controls require stable accessibility labels and identifiers.

## Anti-References

- Generic SaaS dashboards, nested cards, debug/log surfaces, oversized hero typography, and ornamental chrome.
- Beige rounded-card repetition used as a substitute for hierarchy.
- Heavy permanent board rails or empty node caps that make normal play look like placement mode.
- Generated-looking terrain variation, baked gameplay pieces, noisy micro-texture, fake 3D lighting, or resource props that compete with number tokens.
- Decorative motion, hidden primary state, or color-only legality/player identity.

## Approved Direction

The current production source of truth is the code and assets, especially `GameTheme`, `GameBoardPalette`, and `MessagesExtension/Resources/Assets.xcassets/BoardTiles/`. The six default terrain assets use one canonical texture per resource. SpriteKit owns live gameplay layers and SwiftUI owns the surrounding shell.

The approved normal post-roll Turn Screen is the Physical Props composition: a full-display-centered live island surrounded by compact public and private tabletop objects on dark felt. Bank and Dev Cards share portrait geometry; four optically aligned Hand, Build, Trade, and End props use subordinate wooden labels; a two-card splayed Dev prop remains nested in Hand and opens the full owned-card spread. Build and legally playable card choices use amber action keylines directly on felt, while held/new cards remain visible without looking actionable. Trade uses card-native Give/Get stages, a centered full-bottom recipient veil, and one complete maritime exchange with restrained unboxed paging controls and explicit confirmation; these full-size nested surfaces overlay rather than resize the mounted table. Short presentation-derived action prompts replace the passive dice only when the player must act. This direction is productionized only for the active local player’s normal `.afterRoll` state; excluded game states retain their established compositions.

The approved initial-setup screen is a setup-specific state of that same Physical Props table. It keeps the live board at the shared game-screen size, replaces the Bank rail with a centered three-slot placement carousel (current plus the next two placements), and replaces the lower turn props with one settlement and one road. Player slots use uniform system typography and spacing, with opacity and an amber current-player ring supplementing—not replacing—text and accessibility state. Core-owned setup progress drives the separate settlement and connected-road steps and the handoff into the existing first-turn screen.

The approved Start-of-Turn screen is the pre-roll state of the same Physical Props table. A full-host charcoal focus veil keeps the mounted board faintly legible while centering a `Your Turn` ritual: executable owned Dev Cards and a physical dice pair when both choices are legal, or Roll alone after a pre-roll Dev action. The Dev chooser remains inside that focus layer and can close without consuming a card. Rolling decorates the Core-owned result with the dimensional dice bowl, offers skip while moving, waits for explicit continuation after settling, and crossfades directly to the result when Reduce Motion is enabled. The board host and geometry do not remount during these transitions.

The approved learning surfaces retain the tabletop rather than becoming separate documents. Settings is the centered overlay described above. Tutorial is a read-only composition of the production game shell using deterministic synthetic state; each advance removes the previous instruction and places the next short coach mark beside the real action. The final lesson is one concise `Strategy` card over the dimmed board, combining three probability, investment, and scoring tips without becoming a second rulebook.

The approved product identity is a cool-grey physical robber piece marked with a warm-black wrapped domino mask and clay-red `7`, presented directly on dark felt without a framing keyline. Restrained antique-gold edging traces the mask silhouette and apertures; the outer contour is thinner and quieter so gold remains a painted accent rather than turning the mask into eyewear. App and iMessage catalog assets are generated from the tracked SVG masters in `scripts/assets/` by `scripts/generate-icon-assets.sh`; shipping icon PNGs are full bleed and have no alpha channel. The live board robber and every board snapshot share `RobberPieceGeometry` so the sphere, egg body, squat plinth, mask, and `7` do not drift between product surfaces. Tiny board uses may drop the aperture accent and mask contour detail, but must preserve the grey silhouette, dark mask mass, and red `7`.

Collapsed Messages previews reuse production surfaces instead of introducing a parallel illustration system. Lobby updates render the actual four-seat table from the canonical roster; setup renders the actual board with number tokens withheld; turn play and game over render the actual current board. These images stay label-free because the Messages caption and summary own readable status.

Previous numbered terrain and tree passes were experimentation, not durable product truth. They were removed after their final outputs were integrated. New experiments belong in ignored `docs/design/workbench/` and are deleted when the decision closes.

## Human Calibration

Ask for user judgment when current guidance cannot distinguish viable directions, reviewers disagree about a judgment constraint, or a new visual principle is being established. Record the selected principle here and enforce it through the narrowest reusable component, fixture, test, or reviewer rule.

## Durable References

- [Tabletop UI System](docs/design/tabletop-ui-system.md) is the approved detailed reusable contract extracted from the Physical Props Turn Screen and the starting reference for remaining game surfaces.

Binary references are default-denied and require explicit user approval. The manifest and budgets live in [docs/design/references/manifest.json](docs/design/references/manifest.json). Prefer production assets and text decisions over duplicate reference binaries.
