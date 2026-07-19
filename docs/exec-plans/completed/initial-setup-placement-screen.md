# Initial Setup Placement Screen

## Purpose and Outcome

Give initial settlement and road placement a dedicated tabletop screen that always makes the active player, current piece, snake-order progress, and transition into the first turn legible while preserving Core-owned legality and the single mounted board.

Parent: [Phase 14](phase-14-ui-design-bubble-polish-and-trust-surfaces.md).

## Execution Settings

- Validation profile: `standard`
- Delivery posture: `checkpointed`
- Rationale: placement behavior is already settled and playable, but the visual hierarchy and transition treatment require user judgment before the new composition becomes the production default.

## Context and Boundaries

- Reuse the approved [Tabletop UI System](../../design/tabletop-ui-system.md), the existing `BoardContainerView`, setup fixture, board targets, and publication path.
- Core state and queries remain the only source of snake order, active actor, setup step, legal nodes/edges, starting resources, and the transition to `.turn`.
- The approved setup composition routes through the production physical-props style. DEBUG fixtures remain the deterministic visual-proof lane.
- Setup settlement, setup road, waiting setup, and the handoff into first turn are in scope. Lobby, normal turn actions, robber, trade, settings, and transcript surfaces are excluded.
- Screenshot and result-bundle evidence stays outside Git.

## Milestones / Plan of Work

1. Add a pure setup presentation model for round, position, active actor, piece step, and completed-pair progress.
2. Compose a physical setup header, snake-order rail, and settlement/road piece guide around the existing live board without moving legality into SwiftUI.
3. Keep settlement and road board taps on the existing draft/publication path; let the authoritative phase change replace setup with the existing first-turn screen.
4. Add focused resolver/model tests and accessibility identifiers for the representative states.
5. Capture no more than three proofs: settlement placement, connected-road placement, and first-turn handoff. Stop for user review.
6. After approval, make the physical setup route the production default, complete fresh review, and run the standard completion gate.

## Approval Gate

Authority: user.

Proof: installed-simulator captures of settlement placement, connected-road placement, and the resulting first-turn handoff using production components and fixture state.

Round budget: two visual rounds by default. While approval is pending, do not make the new setup composition the Release default, launch final specialist review, or run the completion gate.

Passed 2026-07-18: the user approved the final three-state flow and closed the screen for productionization.

## Verification Contract and Fresh Review

<!-- verification-contract:start -->
| ID | Class | Source | Acceptance | Verification | Evidence | Status | Rationale |
| --- | --- | --- | --- | --- | --- | --- | --- |
| ISP-001 | mechanical | Core/query ownership | Snake order, active actor, step, legal targets, and setup-to-turn transition are projected from authoritative state | focused tests and code inspection | `GameSetupPlacementModelTests` and `SetupInteractionResolverTests`: 7/7 pass; generic simulator build passed | pass | Projection reads `SetupStateV1`; existing resolver remains the only board-intent path |
| ISP-002 | observable | UI flows | The active player can distinguish settlement from connected-road placement and waiting players can identify whose placement is active | installed UX Lab journey and still inspection | three-state installed set at `/private/tmp/UnluckySevensSetupWholeFlowFinalAttachments/`; setup rail reports `3 placement slots shown`, and road piece reports `Place now` | pass | Settlement, connected-road, and first-turn states are distinct; current actor and next two placements remain visible during setup |
| ISP-003 | observable | tabletop system | One live board remains visually primary and stable across settlement, road, and first-turn states | board-host assertions and installed captures | `759F1867-0033-4097-A9DA-F760FAD60178.png`, `AD0E55D5-40F6-4B2C-9609-CEF69F3565C8.png`, and `9ECBF5F0-EABD-4FA7-888C-D55BBF593008.png` in `/private/tmp/UnluckySevensSetupWholeFlowFinalAttachments/` | pass | One native board persists from empty settlement placement through the connected-road state and Core-driven first-turn handoff |
| ISP-004 | observable | accessibility | Guidance does not rely on color alone, controls retain accessible labels, and Dynamic Type does not hide the active step | focused UI assertions and inspection | accessibility-XXL three-state XCUITest passed; inspected settlement and road captures in `/private/tmp/UnluckySevensSetupAccessibilityXXLLabelsAttachments/` | pass | Text and accessible values identify the active step; the current-player ring is supplemental, fixed chrome is capped, and fallback/wider labels prevent active-name and piece truncation |
| ISP-005 | judgment | user | The setup composition is strong enough to productionize | explicit user verdict after captures | 2026-07-18 user verdict: “perfect we’re done w this screen” | pass | Approval gate passed and authorized production routing |
<!-- verification-contract:end -->

<!-- fresh-review:start -->
| Reviewer | Required | Verdict | Evidence |
| --- | --- | --- | --- |
| constraint-auditor | yes | pass | Fresh post-productionization audit mapped ISP-001–005 to focused tests, installed captures, accessibility proof, and the explicit user verdict; no unresolved material constraint remains |
| architecture | no | not-applicable | Presentation consumes existing Core/query outputs and transport |
| behavioral | yes | pass | Core-derived setup fixtures, 27 focused presentation/board tests, and the installed three-state journey verify settlement, connected road, and authoritative first-turn handoff |
| product-ux | yes | pass | Final normal-size flow was explicitly approved by the user; accessibility-XXL inspection preserves the active actor and placement-step hierarchy without changing the shared board size |
<!-- fresh-review:end -->

## Living Record

### Progress

- [x] Existing setup interaction, fixture, board overlay, and production routing inspected.
- [x] Validation profile, checkpointed posture, representative states, and exclusions locked.
- [x] DEBUG physical settlement comparison implemented.
- [x] Three-state evidence captured for approval: settlement, connected-road placement, and Core-driven first-turn handoff.
- [x] Approved direction productionized and verified.

### Decisions

- 2026-07-18: Initial setup is a dedicated state of the same physical table, not a modal, second board, or rules surface.
- 2026-07-18: Settlement and road remain separate authoritative publications. The presentation may visually pair them but must not stage an atomic UI-only pair.
- 2026-07-18: The transition into first turn is driven only by the received Core phase change; the setup screen does not predict or animate into an invented state.
- 2026-07-18: Per user review, the setup-order rail shows a three-slot carousel: the current placement and the next two placements. The full snake order remains projected for progress and advances the window without duplicating rules.
- 2026-07-18: Per user review, each placement pair displays one settlement and one road without a connector line or sequence numbers; current and on-deck player names use the same typography, with state conveyed by color and the current-player ring.
- 2026-07-18: The order treatment uses three equal-width slots with uniform avatar size, label font, and avatar-to-label spacing. The current player is fully emphasized, the next slot is faded and labeled `Next`, and later or empty slots fade progressively.
- 2026-07-18: The rejected compact/scaled board direction is superseded. Setup retains the exact shared game-screen board dimensions and native SpriteKit rendering; the setup order replaces the public bank rail and the placement pieces replace the normal lower prop rail.
- 2026-07-18: Setup disables the normal physical-turn board-centering correction because that correction shifts the SpriteKit surface and exposes a contrasting strip at the bottom. A zero setup offset centers the unchanged board inside the unchanged host without scaling it.
- 2026-07-18: Settlement placement omits the redundant `Choose a glowing corner` subtitle because the title and legal-target highlights already communicate the action. Road and waiting states retain their clarifying guidance where the extra constraint is meaningful.
- 2026-07-18: Number-token labels center their rendered serif glyph bounds rather than SpriteKit's typographic advance, preventing value-specific horizontal drift inside the circular chips without changing token or board geometry.
- 2026-07-18: The user approved the complete settlement, connected-road, and first-turn flow. Setup now selects the physical-props layout in production as well as DEBUG fixtures.
- 2026-07-18: Setup-only fixed chrome caps semantic Dynamic Type at `.xxxLarge`; the order rail falls back from `Name · Next` to the full player name when width is constrained, and piece labels reserve enough width to keep the active step readable.

### Discoveries

- The setup flow is already end-to-end playable and has a dedicated UX Lab fixture, but setup currently resolves to the legacy framed-shelf shell even when the physical tabletop system is selected.
- Existing legal-target overlays and endpoint-biased road hit testing already provide the board interaction needed by this slice.
- The first installed XCUITest reached the settlement screen and found the setup status but exposed an accessibility-identifier collision on the order rail; that collision was corrected. Two follow-up runs then failed before proof: one lost the Messages remote-view accessibility tree while opening UX Lab, and one test runner was killed during bootstrap. A manual fallback opened a different Simulator device than the headless test destination, so it was rejected as evidence.
- After shutting down every Simulator and reopening only the designated iPhone 17, the current lobby UI exposed a stale harness assumption: the setup test opened the `Preview` panel even though the setup fixture is now directly available from `States`. Routing this one test through the direct quick-state path produced the installed settlement capture.
- A first capture after narrowing the rail reused a stale Messages extension process and still showed six placements; it was rejected. Restarting the designated simulator and rerunning after the app-drawer bootstrap produced a fresh two-placement proof, which was later superseded by the user-approved three-slot direction.
- The follow-up screenshot supplied by the user proved the installed Messages bundle was still stale despite the test target rebuilding. The reliable lane is build, terminate Messages, explicitly `simctl install` the standalone app bundle, then run the focused XCUITest; the corrected capture was accepted only after that installed-bundle sequence and direct inspection.
- The apparent dark-water defect was not part of the board texture. The normal physical-turn centering correction offset the entire SpriteKit view inside its clipped host, exposing the SwiftUI background at the bottom. Removing that offset only for setup eliminates the seam while preserving the shared board host size and native token rendering.
- The original setup screenshot fixture inherited normal-turn pieces and inventory. Core-derived DEBUG fixture states now begin with an empty board and zero resources, apply the first settlement for the road proof, and execute the full authoritative setup reducer for a Roll-only first-turn handoff.
- Accessibility XXL inspection exposed overflow in the fixed-height physical setup rails even though UI existence assertions passed. Setup-only chrome now caps semantic Dynamic Type at `.xxxLarge`; a width-fitting next-player label and wider piece tiles keep the active actor and step visible. VoiceOver labels remain complete, while the board and other app surfaces retain their existing scaling behavior.

## Validation and Outcome

Mechanical validation passed:

- `bash ./scripts/gen.sh`
- `xcodebuild -workspace UnluckySevens.xcworkspace -scheme MessagesExtension -destination 'generic/platform=iOS Simulator' build`
- Focused `GameSetupPlacementModelTests` and `SetupInteractionResolverTests`: 7 tests, 0 failures.

Installed settlement validation now passes:

- `xcodebuild -workspace UnluckySevens.xcworkspace -scheme UnluckySevens-Workspace -destination 'id=098EFE33-4CE6-4436-802C-4396864F446B' -only-testing:UnluckySevensUITests/MessagesExtensionDesignSliceUITests/testOpenMessagesExtensionAndCaptureCleanSetupGameplaySlice -resultBundlePath /private/tmp/UnluckySevensSetupFinalRetry2.xcresult test`
- Result: 1 test, 0 failures; screenshot attachment exported to `/private/tmp/UnluckySevensSetupFinalRetry2Attachments/6A4AC0BD-DA9B-487F-9FB0-961EEBD57DE6.png`.
- Revised order-window validation: `GameSetupPlacementModelTests` 4 tests, 0 failures; installed setup capture 1 test, 0 failures; fresh attachment at `/private/tmp/UnluckySevensSetupOrderTwoFresh2Attachments/B339050B-F9C2-4901-BBC1-88F2E94A77A8.png`.
- Corrected installed-bundle validation: `GameSetupPlacementModelTests` 4 tests, 0 failures; focused setup XCUITest 1 test, 0 failures after explicit app install; attachment at `/private/tmp/UnluckySevensSetupCorrectedInstalledAttachments/E78E4697-58D3-40B8-8562-5BC01B1D8B39.png` visually confirms two order entries, matching name typography, no connector, and one badge on each piece.
- Latest user-directed layout validation: `GameSetupPlacementModelTests` passed 4 tests with 0 failures; explicit app install followed by focused setup XCUITest passed 1 test with 0 failures. The inspected attachment at `/private/tmp/UnluckySevensSetupNoSubtitleAttachments/D6D3EC67-0C5A-447E-A0BC-251ED9DED2FA.png` confirms the simplified settlement header, uniform three-slot carousel, exact shared board sizing with native sharp rendering, centered setup placement without a water seam, and one settlement plus one road with no connector.
- Whole-flow checkpoint validation: `SetupStateMachineV1Tests` passed 13 tests with 0 failures, `GameSetupPlacementModelTests` passed 4 tests with 0 failures, and the freshly installed three-state XCUITest passed 1 test with 0 failures. Final inspected captures are in `/private/tmp/UnluckySevensSetupWholeFlowFinalAttachments/` and show empty-board settlement placement, the Core-derived connected-road state, and the authoritative Roll-only first-turn handoff.
- Number-token alignment follow-up: focused `GameBoardSceneTests` plus `GameSetupPlacementModelTests` passed 20 tests with 0 failures, including rendered-glyph centering coverage. The freshly installed three-state XCUITest passed 1 test with 0 failures; inspected settlement capture `/private/tmp/UnluckySevensSetupCenteredTokensAttachments/1C15CD8B-6445-41B0-90B1-DBE5038FAB44.png` confirms centered single- and double-digit serif labels without the prior CoreText fallback.
- Production routing follow-up: `GameTabletopLayoutStyleResolver` now selects Physical Props for setup in Release and its focused resolver test passes. A Release simulator build passed after productionization.
- Accessibility closeout: at `accessibility-extra-extra-large`, the freshly installed three-state XCUITest passed 1 test with 0 failures. Inspected captures in `/private/tmp/UnluckySevensSetupAccessibilityXXLLabelsAttachments/` confirm the active player and full `Settlement`/`Road` labels remain readable; the simulator content size was restored to `large` afterward.
- Final focused suite: `GamePhysicalNotPrimaryPlayerContextTests`, `GameSetupPlacementModelTests`, and `GameBoardSceneTests` passed 27 tests with 0 failures after the label-fit adjustment.

The user approval gate, production routing, accessibility proof, required fresh review, and standard completion gate all pass. This plan is closed as a completed historical record.
