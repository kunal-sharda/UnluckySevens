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
- New York/system serif, SF Pro Rounded, SF Mono, Georgia, and custom bundled fonts are not part of the Unlucky Sevens interface language.
- `monospacedDigit()` is allowed for changing counts, dice totals, and aligned numeric data because it preserves SF Pro while stabilizing numeral width. A monospaced typeface is not allowed for ordinary text.
- SpriteKit labels, rendered transcript text, SwiftUI controls, and DEBUG UX Lab chrome follow the same family contract. Authored lettering inside resource illustrations is artwork rather than interface typography.
- Prefer semantic Dynamic Type styles. Fixed sizes are reserved for geometry-bound micro labels and board tokens and must remain legible at their supported host sizes.

## Component Vocabulary

- One compact command surface states the current phase or action.
- The active player’s normal post-roll screen is one fixed tabletop with five zones: compact top bar, public table rail, live board, reserved action well, and turn-object rail.
- On that screen, physical Bank and `Dev Cards` objects communicate public ownership. Exact public counts stay concealed; tapping Bank reveals only `H/M/L` levels in place. The local player’s resources and a two-card splayed owned-Dev entry prop are nested together inside Hand; tapping that prop opens the complete owned-card spread, with action keylines only on legally playable cards.
- Public and owned Dev Cards use a desaturated blue-gray family (`#71858B`) with a lighter steel edge. The public pile uses the approved factory vector in charcoal; the Trade prop uses the approved merchant-ship vector in warm wood. Every revealed public-pile level uses the same bold warm-white treatment over its faded card.
- The normal post-roll turn-object rail keeps stable `Hand · Build · Trade · End` anchors. Unavailable actions leave empty, hitless, accessibility-hidden space instead of disabled props or rearranged neighbors.
- Other gameplay states continue to use their existing lower-tray and shelf compositions.
- Overlays belong to one interaction owner and must not depend on controls underneath them.
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

The approved normal post-roll Turn Screen is the Physical Props composition: a full-display-centered live island surrounded by compact public and private tabletop objects on dark felt. Bank and Dev Cards share portrait geometry; four optically aligned Hand, Build, Trade, and End props use subordinate wooden labels; a two-card splayed Dev prop remains nested in Hand and opens the full owned-card spread. Build and legally playable card choices use amber action keylines directly on felt, while held/new cards remain visible without looking actionable. Short presentation-derived action prompts replace the passive dice only when the player must act. This direction is productionized only for the active local player’s normal `.afterRoll` state; excluded game states retain their established compositions.

Previous numbered terrain and tree passes were experimentation, not durable product truth. They were removed after their final outputs were integrated. New experiments belong in ignored `docs/design/workbench/` and are deleted when the decision closes.

## Human Calibration

Ask for user judgment when current guidance cannot distinguish viable directions, reviewers disagree about a judgment constraint, or a new visual principle is being established. Record the selected principle here and enforce it through the narrowest reusable component, fixture, test, or reviewer rule.

## Durable References

- [Tabletop UI System](docs/design/tabletop-ui-system.md) is the approved detailed reusable contract extracted from the Physical Props Turn Screen and the starting reference for remaining game surfaces.

Binary references are default-denied and require explicit user approval. The manifest and budgets live in [docs/design/references/manifest.json](docs/design/references/manifest.json). Prefer production assets and text decisions over duplicate reference binaries.
