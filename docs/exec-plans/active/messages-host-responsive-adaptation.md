# Messages Host Responsive Adaptation

## Purpose and Outcome

Make the existing Messages surfaces respond correctly to the actual host bounds supplied by iPhone and iPadOS, including the distinct widths observed when entering from the app drawer and from a transcript bubble. The system-owned host frame may differ; product content must fill, reflow, and remain legible without treating device identity as a layout input.

## Execution Settings

- Validation profile: `standard`
- Delivery posture: `checkpointed`
- Rationale: the host-size behavior is externally controlled and the responsive visual result requires real-iPad judgment before broader production cleanup.

## Context and Boundaries

- Apple owns the Messages extension frame. `requestPresentationStyle(.expanded)` requests a style, not an exact width.
- Layout resolves from live container width and height, never device model or `UIScreen.main`.
- This pass adapts the existing Lobby, UX Lab chrome, Start, and approved Turn compositions. It does not redesign legacy product surfaces.
- SpriteKit remains the board owner; container changes must not remount the live board.
- Existing dirty worktree changes are preserved.

## Milestones / Plan of Work

1. Add a pure host-layout profile covering narrow, standard, wide-short, and wide containers.
2. Make UX Lab quick navigation collapse into menus before labels wrap or cover product content; tuck settled legacy visual comparisons behind a clearly labeled menu.
3. Apply profile-driven zone and prop scaling to the physical Start/Turn surfaces while giving the live board the remaining space.
4. Add focused resolver tests for representative small/standard/large iPhones and both observed iPad host widths.
5. Build, install on the connected iPad, and stop for user review of both entry paths.

## Approval Gate

Authority: user. Proof is the connected iPad showing one app-drawer entry and one transcript-bubble entry without clipped developer chrome or miniature tabletop composition. One correction round is allowed before deciding whether a broader legacy-screen adaptation should become a separate slice.

<!-- verification-contract:start -->
| ID | Class | Source | Acceptance | Verification | Evidence | Status | Rationale |
| --- | --- | --- | --- | --- | --- | --- | --- |
| MHR-001 | mechanical | user screenshots | Layout profile is derived from live container size across representative iPhone and iPad host bounds | focused resolver tests | command:GameShellLayoutMetricsTests-12-pass | pass | Six container shapes resolve without device-model checks |
| MHR-002 | observable | user screenshots | UX Lab navigation does not wrap vertically or obscure the product at either observed iPad width | connected-iPad inspection | report:pending | pending | Awaiting device proof |
| MHR-003 | observable | approved Turn direction | Physical Start and Turn surfaces use the available host without remounting the board | focused UI journey and connected-iPad inspection | report:pending | pending | Awaiting implementation |
| MHR-004 | judgment | user request | Both iPad entry paths feel proportionate and usable | user review of installed build | report:pending | pending | Approval gate |
<!-- verification-contract:end -->

<!-- fresh-review:start -->
| Reviewer | Required | Verdict | Evidence |
| --- | --- | --- | --- |
| constraint-auditor | yes | pending | report:pending |
| architecture | no | not-applicable | No ownership or dependency change planned |
| behavioral | no | not-applicable | No gameplay behavior change planned |
| product-ux | yes | pending | report:pending |
<!-- fresh-review:end -->

## Living Record

### Progress

- [x] Reproduced two distinct real-iPad host widths from user screenshots.
- [x] Responsive implementation and focused tests.
- [ ] Connected iPhone and iPad review; the identical signed build was installed on both devices 2026-07-16.

### Decisions

- 2026-07-16: Adapt by live host bounds rather than device model, size class alone, or whole-screen scaling.
- 2026-07-16: Replace the always-visible four-state DEBUG chip row with one `States` menu. Keep settled visual comparisons inside the expanded lab rather than over product content.

### Discoveries

- The DEBUG quick-state row assumes phone-like horizontal room and wraps each label vertically in the narrower iPad transcript host.
- The physical layout currently clamps zone heights to phone-oriented ranges and has no wide-container proof.
- Apple continues to own the outer Messages panel width. The implementation scales physical objects and their reserved zones, not the entire SwiftUI root or the system host.

## Validation and Outcome

Focused Messages build passed and 12 `GameShellLayoutMetricsTests` passed. The same signed Debug app bundle was installed on a paired iPhone 16 Pro and iPad 8th generation. Real-device visual approval remains pending.
