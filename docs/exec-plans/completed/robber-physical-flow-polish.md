# Robber Physical Flow Polish

## Purpose and Outcome

Migrate ordinary Move Robber and Choose a Victim states out of the hybrid command-bar/modal presentation and into one continuous Physical Props board-first sequence. The mounted board, public rail, and turn-object rail remain stable while the fixed top prompt advances from moving the robber to choosing a player.

## Execution Settings

- Validation profile: `standard`
- Delivery posture: `direct`
- Rationale: The user explicitly identified the legacy components and authorized the settled correction. Fresh device captures of both adjacent states are the primary observable evidence.

## Context and Boundaries

- [Design](../../../DESIGN.md) owns the Physical Props visual language and stable-board contract.
- [UI flows](../../product-specs/ui-flows.md) owns the robber player journey.
- [QA](../../quality/qa.md) and [UX Lab](../../quality/ux-lab.md) own simulator capture.
- Core continues to own robber legality, eligible victims, random stealing, and state transitions.
- This slice changes presentation routing and DEBUG/XCUITest evidence only; engine rules, protocol fields, and board rendering are unchanged.
- Existing uncommitted work in `GameShellView.swift` belongs to the user and must be preserved.

## Milestones / Plan of Work

1. Route ordinary robber-move and robber-victim modes through the Physical Props gameplay composition.
2. Use fixed physical header prompts for both states and suppress the legacy forced-flow modal for victim selection.
3. Add direct UX Lab fixtures and focused XCUITest coverage for the adjacent states, including stable geometry and retired-component absence.
4. Capture and inspect both device frames, run fresh review, and pass the standard completion gate.
5. Incorporate the separately delegated read-only Terra audit of other legacy production components into the outcome or durable follow-up tracking.

## Verification Contract and Fresh Review

<!-- verification-contract:start -->
| ID | Class | Source | Acceptance | Verification | Evidence | Status | Rationale |
| --- | --- | --- | --- | --- | --- | --- | --- |
| RPF-001 | observable | user direction | Move Robber uses the Physical Props top bar, public rail, mounted board, and turn-object rail without the legacy command bar | focused XCUITest plus screenshot inspection | `testCaptureRobberPhysicalFlow`; `output/robber-physical-flow-2026-08-02/01-move-robber.png` | pass | Device evidence shows the fixed prompt and the test rejects the old `Tap tile`/component-surface route |
| RPF-002 | observable | user direction | Choose a Victim continues on identical Physical Props geometry and does not render the generic cream forced-flow modal | focused XCUITest plus screenshot inspection | passing exact frame assertions; `output/robber-physical-flow-2026-08-02/02-choose-player.png` | pass | Top/public/board/turn-rail frames match the Move Robber fixture and retired copy/surface checks are negative |
| RPF-003 | mechanical | code and Core boundary | Existing legal tile/node selection and publish behavior remain unchanged | focused unit tests and existing interaction tests | `GamePhysicalTurnHeaderPromptResolverTests` 6/6; scoped presentation routing diff | pass | The shell continues to pass Core-derived tile/victim options into the existing board interaction path |
| RPF-004 | mechanical | DESIGN.md | The change uses existing semantic system typography and does not modify board-number rendering | scoped diff and completion gate | existing `GamePhysicalTurnPromptView`; no board-number source change in this slice; `git diff --check` | pass | Only presentation classification/prompt routing changed; board-number rendering remains untouched |
| RPF-005 | mechanical | user-requested audit | Other player-facing legacy/hybrid routes are inventoried with production reachability and evidence | Terra read-only audit | `/root/legacy_component_audit` findings recorded below | pass | Games/recovery is known production debt; dormant gameplay shells are unreachable; no other active gameplay bypass was found |
<!-- verification-contract:end -->

<!-- fresh-review:start -->
| Reviewer | Required | Verdict | Evidence |
| --- | --- | --- | --- |
| constraint-auditor | yes | pass | Fresh Terra review verified RPF-001–005, Core boundary preservation, unchanged board-number/type contract, and both full-screen device frames; recommended direct retired-shelf rejection, which was added and rerun |
| product-ux | yes | pass | Independent Terra tiebreak inspected both exact 1170×2532 PNGs and confirmed identical top/public/board/Hand geometry, clear prompt/target progression, and no legacy card |
| architecture | no | not-applicable | No engine, protocol, or module-boundary change |
| behavioral | no | not-applicable | Existing Core-backed target and publish paths are preserved and mechanically tested |
<!-- fresh-review:end -->

## Living Record

### Progress

- [x] Validation profile and delivery posture locked before implementation.
- [x] Physical robber sequence implemented.
- [x] Focused simulator evidence captured and inspected.
- [x] Terra legacy-component audit incorporated.
- [x] Completion gate passed.

### Decisions

- 2026-08-02: Treat ordinary robber movement and victim choice as one forced board interaction on the Physical Props table, not as utility or modal content.
- 2026-08-02: Reuse Core-derived glowing tile/node targets for selection; do not create a second victim-selection rules path.

### Discoveries

- The style resolver already returns Physical Props globally, but the narrower `isPhysicalGameplayTurn` classifier omitted both ordinary robber modes.
- Robber victim additionally routed to the generic `GameModalHostView` through `.forcedFlow`, producing the visible legacy card.
- The Terra audit found no other production-reachable gameplay bypass: Game Information is an intentional overlay, while Rules, Settings, and Tutorial are approved exceptions to the gameplay composition.
- The production-reachable Games/recovery library still uses a generic baseline surface. `DESIGN.md` already reserves that as known debt for a dedicated checkpointed pass, so this robber slice does not silently redesign it.
- Retired framed-shelf, frameless-shelf, felt-tools, and forced-flow branches remain compiled but are unreachable because the only selectable tabletop style is Physical Props. Their eventual deletion and negative reachability coverage belong to a separate cleanup slice.
- The build exposed a line break inside a concurrently edited tutorial string literal. The syntax was repaired without changing the requested words.
- One product-UX reviewer received an apparent cropped rendering of the second PNG that contradicted the local bytes and frame assertions. An independent fresh Terra review verified both exact 1170×2532 files and confirmed the complete stable composition in each.

## Validation and Outcome

- `bash ./scripts/gen.sh` — passed.
- Generic MessagesExtension simulator build — passed.
- `GamePhysicalTurnHeaderPromptResolverTests` — 6 tests passed, 0 failures.
- `MessagesExtensionDesignSliceUITests/testCaptureRobberPhysicalFlow` — passed after one harness-only retry; the initial run exposed that a second SwiftUI `Menu` selection sometimes needed a disappearance/retry guard. A final strengthened run also directly rejects `uls.overlayShelf` in both states and passed.
- Device screenshots inspected at `output/robber-physical-flow-2026-08-02/01-move-robber.png` and `02-choose-player.png`; both show the same mounted-table geometry with no legacy command bar or forced-flow card.
- `git diff --check` — passed.
- `make doc-freshness` — passed; affected design, product-flow, QA/UX Lab, and active-plan owners are updated.
- `make completion-gate PLAN=docs/exec-plans/completed/robber-physical-flow-polish.md` — passed under the standard profile (contract, harness audit, diff hygiene, doc freshness, canonical generation, and generic simulator build).
