# Deferred PRD Items

These items appeared in the PRD or were later identified as post-MVP product ideas. They are intentionally not part of the current MVP contract.

## Gameplay Options and Variants

- board fairness toggles beyond the current shipped strategy surface
- tabletop realism / hard mode that reduces exact arithmetic aids:
  - hide exact public bank/resource remaining counts by default so players must infer scarcity from the board, visible draws, trades, builds, and memory
  - replace numeric bank chips with nonnumeric availability states such as available, low, or empty, with exact counts reserved for debug/dispute surfaces if needed
  - keep opponent hand secrecy aligned with standard play: opponent total hand size may remain visible, but opponent resource/dev composition stays hidden
  - make trade and dev-card choice surfaces avoid exposing unnecessary remaining-card math, while still preventing illegal choices when the bank is empty or a rule cannot be satisfied
  - consider lobby-level per-game selection between normal assisted mode and realistic mode; if implemented, the selected mode must be canonical state and query/projection behavior, not ad hoc Messages UI state
- other tabletop-feel options to evaluate alongside hard mode:
  - classic fully random board setup as a player-selected alternative to the balanced first-beta default
  - lighter default recap wording that preserves dispute-mode audit detail without turning the main shell into a perfect counting ledger
  - more tactile dice, robber, steal, build, and trade presentation that increases table presence without changing rules
  - lower-assistance trade UX variants that favor table talk and negotiation over strategy-suggesting shortcuts
- friendly robber
- optional timers or forced stale-trade expiry
- 2-player support and AI fill-ins
- scenario maps, mini-boards, and rerolls

## UX and Presentation

- animated roll polish and shake-to-roll
- smart trade suggestions and richer trade-history tooling
- event-animation layers beyond the current MVP UI needs

## Product and Platform Work

- analytics and anonymous telemetry
- Crashlytics or similar crash reporting
- cosmetics, stores, or paid unlocks
- privacy/compliance work beyond the minimal app-store launch baseline
- localization beyond the initial English-only assumption

## Notes

Deferred does not mean abandoned. It means these items should not drive current engine or UI scope unless the product direction changes explicitly.
