# Lobby, Settings, and Rules Polish

## Purpose and Outcome

Polish the first four player-facing utility frames from the 2026-08-01 catalog: reduce lobby-header crowding, anchor Join identity controls to the bottom with readable white text, make Settings feel like an intentional tabletop utility rather than a stack of generic cards, and make the Rules surface visibly scrollable.

## Execution Settings

- Validation profile: `standard`
- Delivery posture: `direct`
- Rationale: The requested visual changes are specific and production implementation is explicitly authorized. Fresh simulator captures remain the observable acceptance evidence.

## Context and Boundaries

- [Design](../../../DESIGN.md) owns the SF Pro/system-type contract and tabletop visual language.
- [UI flows](../../product-specs/ui-flows.md) owns lobby, Settings, Rules, Games, and Tutorial behavior.
- [QA](../../quality/qa.md) owns the Messages UX Lab and screenshot workflow.
- Board rendering, board-number typography, gameplay rules, protocol fields, and game-state behavior are out of scope.
- Existing uncommitted work is preserved; this slice only edits its named surfaces and focused harness coverage.

## Milestones / Plan of Work

1. Consolidate Games and Tutorial into one compact, accessible lobby utility menu.
2. Recompose the Join action area so its white identity treatment and primary action sit at the bottom of the available lobby canvas.
3. Simplify Settings into a compact felt panel with quiet grouping and a row-style Rules destination.
4. Add an explicit Rules scroll cue without obscuring rule content.
5. Regenerate, build, run the focused simulator journey, inspect fresh captures, and run standard completion checks.
6. Distill the approved pass by removing decorative Rules icons, standardizing the lobby identity label on `Display Name`, and removing the redundant `Experience` heading above the single Skip animations setting.
7. Correct the identity interpretation: restore `Playing as` as the visible label and use the same bottom-anchored identity/action geometry for Invite and Join.
8. Remove the redundant explanatory sentence beneath the self-explanatory Skip animations toggle.
9. Remove the redundant Help grouping above the Rules destination and record the approved four-screen composition as locked.
10. Add a final Rules action that opens the existing Strategy quick-tips card as its own focused overlay and returns to Rules when closed.

## Verification Contract and Fresh Review

<!-- verification-contract:start -->
| ID | Class | Source | Acceptance | Verification | Evidence | Status | Rationale |
| --- | --- | --- | --- | --- | --- | --- | --- |
| LSR-001 | observable | user direction | Lobby header has one compact utility affordance and preserves Games and Tutorial access | focused XCUITest plus screenshot inspection | `testCaptureLobbyJoinSettingsRulesPolish`; `output/lobby-settings-rules-polish-2026-08-02/01-lobby.png`; `/private/tmp/UnluckySevensLobbySettingsRules20260802F.xcresult` | pass | More is a 44-point control; the final journey opens Games, returns, opens Tutorial, verifies tutorial progress, and exits through the consolidated menu |
| LSR-002 | observable | user direction | Join display-name treatment is readable in white and the identity/action group sits at the bottom | focused XCUITest plus screenshot inspection | `testCaptureLobbyJoinSettingsRulesPolish`; `output/lobby-settings-rules-polish-2026-08-02/02-join.png` | pass | Harness asserts the action finishes within 72 points of the lobby canvas bottom; artifact shows the white felt treatment |
| LSR-003 | judgment | user direction and DESIGN.md | Settings reads as a compact authored tabletop utility rather than generic stacked cards | screenshot inspection | `output/lobby-settings-rules-polish-2026-08-02/03-settings.png` | pass | One felt panel, quiet labels, dividers, and a complete unclipped Rules row replace the nested light-card treatment |
| LSR-004 | observable | user direction | Rules visibly communicates that more content is available below and remains scrollable | focused XCUITest plus screenshot inspection | `testCaptureLobbyJoinSettingsRulesPolish`; `output/lobby-settings-rules-polish-2026-08-02/04-rules.png`; `/private/tmp/UnluckySevensLobbySettingsRules20260802F.xcresult` | pass | The cue reserves its own opaque bottom inset without obscuring Production; an actual swipe exposes Build costs and dismisses it |
| LSR-005 | mechanical | DESIGN.md | Existing SF Pro/system typography contract remains intact and board-number rendering is untouched | scoped diff and typography audit | Impeccable detector `[]`; scoped font search and diff inspection | pass | Changed UI uses existing GameTheme semantic fonts and no board-number source changed |
| LSR-006 | observable | user direction | Rules content uses text hierarchy without decorative section or scroll-cue icons | focused XCUITest plus screenshot inspection | `testCaptureLobbyJoinSettingsRulesPolish`; `output/lobby-settings-rules-polish-2026-08-02/04-rules.png`; `/private/tmp/UnluckySevensLobbySettingsRules20260802I.xcresult` | pass | Final capture shows text-only content headings and scroll cue; Back remains as functional navigation |
| LSR-007 | observable | corrected user direction | Invite and Join consistently use `Playing as` as the visible identity label | focused XCUITest plus scoped string audit | `testCaptureLobbyJoinSettingsRulesPolish`; refreshed lobby and Join captures; `/private/tmp/UnluckySevensLobbySettingsRules20260802M.xcresult` | pass | Passing journey observes Playing as in both states; final captures show matching full-contrast, bold meta labels |
| LSR-008 | observable | user direction | Settings presents only the direct Skip animations label and toggle, without an Experience heading or explanatory copy | focused XCUITest plus screenshot inspection | `testCaptureLobbyJoinSettingsRulesPolish`; refreshed Settings capture; `/private/tmp/UnluckySevensLobbySettingsRules20260802L.xcresult` | pass | Passing journey asserts the label exists while Experience and the prior explanatory sentence do not; compact final panel has no excess lower void |
| LSR-009 | observable | corrected user direction | Invite and Join identity/action groups both finish near the bottom of the lobby canvas | focused XCUITest geometry assertions plus screenshot inspection | `testCaptureLobbyJoinSettingsRulesPolish`; refreshed lobby and Join captures; `/private/tmp/UnluckySevensLobbySettingsRules20260802L.xcresult` | pass | Passing journey asserts Send Invite and Join Game both finish within 72 points of the lobby canvas bottom; captures show matching placement |
| LSR-010 | observable | user direction | The Settings Rules destination follows the current-game facts directly without a separate Help heading | focused XCUITest plus screenshot inspection | `testCaptureLobbyJoinSettingsRulesPolish`; `output/lobby-settings-rules-polish-2026-08-02/final-locked-raw/03-settings.png`; `/private/tmp/UnluckySevensLobbySettingsRules20260802N.xcresult` | pass | The passing journey rejects a visible Help label; the refreshed device capture shows Rules directly after the current-game facts |
| LSR-011 | mechanical | user approval and docs/decisions.md | The approved Lobby, Join, Settings, and Rules compositions are recorded as locked | owner-doc inspection | `docs/decisions.md` section 11; `DESIGN.md`; `docs/product-specs/ui-flows.md` | pass | Subsequent visual-structure changes require explicit user direction and a decision update |
| LSR-012 | observable | user direction | The end of Rules opens the existing Strategy card as a standalone focused overlay, not a destination anchored inside Rules | focused XCUITest plus screenshot inspection | `testCaptureLobbyJoinSettingsRulesPolish`; `output/lobby-settings-rules-polish-2026-08-09/06-standalone-strategy-card.png`; `GameTutorialStrategyCardView` reuse | blocked | Fresh device evidence shows the independent card and close action. The focused retry reached Strategy but exposed an obsolete container assertion; after correcting it, CoreSimulatorService crashed before the confirmation build, exhausting this slice's bounded rerun |
<!-- verification-contract:end -->

<!-- fresh-review:start -->
| Reviewer | Required | Verdict | Evidence |
| --- | --- | --- | --- |
| constraint-auditor | yes | pass | Final audit against result N and the locked captures passed LSR-001 through LSR-011; Help is absent, Rules follows the facts directly, typography and board-number constraints remain intact, and the decision lock is correctly recorded |
| product-ux | yes | pass | Final locked-set review found the preference → current-game facts → Rules progression clearer without Help and found all four compositions coherent enough to lock with no blocking concern |
| architecture | no | not-applicable | No engine, transport, protocol, or module-boundary change |
| behavioral | no | not-applicable | Existing destinations and state actions are preserved |
<!-- fresh-review:end -->

## Living Record

### Progress

- [x] Validation profile and delivery posture locked before implementation.
- [x] Production surfaces implemented.
- [x] Focused simulator evidence inspected.
- [x] Required fresh reviews passed.
- [x] Completion gate passed.
- [x] Requested icon, naming, and Settings refinements implemented and recaptured.
- [x] Refinement fresh reviews passed.
- [x] Refinement completion gate passed.
- [x] Corrected Playing as labels, Invite/Join bottom alignment, and direct Skip animations setting recaptured.
- [x] Correction fresh reviews passed.
- [x] Correction completion gate passed.
- [x] Redundant Help heading removed and the final four-screen set recaptured.
- [x] Locked composition recorded in owner docs.
- [x] Final lock fresh reviews passed.
- [x] Final lock completion gate passed.
- [x] Rules-to-Strategy navigation implemented with the existing card.
- [ ] Focused Rules-to-Strategy journey rerun.

### Decisions

- 2026-08-02: Preserve the locked system-type contract and do not alter board-number rendering.
- 2026-08-02: Use one labeled overflow menu for Games and Tutorial rather than two persistent top-bar labels.
- 2026-08-02: Reserve icons in Rules for functional system navigation only.
- 2026-08-02: Corrected user intent supersedes the earlier naming interpretation: `Playing as` remains the visible label, while Invite and Join share bottom-anchored identity/action placement.
- 2026-08-02: Once the standalone Help heading is removed, the approved Lobby, Join, Settings, and Rules compositions become locked and require explicit user direction to change.
- 2026-08-09: Explicit user direction extends the locked Rules composition with one final Strategy row that reuses the tutorial card as an independent overlay and returns to Rules when closed.

### Discoveries

- The prior Join frame used the light control-surface name field, making its label and text visually disconnected from the dark felt canvas.
- The Rules surface exposed a scroll view but gave no persistent visual cue that additional sections continued below the fold.
- The Messages host initially reused a stale extension binary; explicit install plus host restart was required before the passing capture, matching the existing QA owner guidance.
- The standalone Strategy card rendered correctly on the iPhone 17 after an explicit fresh-app install. The former card-root accessibility identifier is not exported in the sibling-overlay composition, so the focused harness now observes the user-facing close control and title instead.
- The bounded confirmation attempt stopped when CoreSimulatorService disconnected before Xcode could resolve the simulator destination. Per the validation circuit breaker, no further simulator restart loop was attempted in this slice.

## Validation and Outcome

Passed so far:

- 2026-08-09 standalone Strategy refinement: `bash ./scripts/gen.sh`
- 2026-08-09 standalone Strategy refinement: focused `build-for-testing` (`TEST BUILD SUCCEEDED`) on iPhone 17 / iOS 26.5 after the production and initial harness changes
- 2026-08-09 standalone Strategy refinement: Impeccable detector returned `[]`
- 2026-08-09 standalone Strategy refinement: fresh visual evidence at `output/lobby-settings-rules-polish-2026-08-09/06-standalone-strategy-card.png`
- 2026-08-09 standalone Strategy refinement: focused retry reached and rendered the Strategy overlay, then failed on the obsolete card-root assertion; the assertion now targets the standalone close control
- 2026-08-09 standalone Strategy refinement: final confirmation was blocked before build by a CoreSimulatorService disconnect; no completion gate was run while LSR-012 remains blocked
- 2026-08-09 Rules-to-Strategy extension: `bash ./scripts/gen.sh`
- 2026-08-09 Rules-to-Strategy extension: `xcodebuild -workspace UnluckySevens.xcworkspace -scheme MessagesExtension -destination 'generic/platform=iOS Simulator' build` (`BUILD SUCCEEDED`)
- 2026-08-09 Rules-to-Strategy extension: `git diff --check`
- 2026-08-09 Rules-to-Strategy extension: `make doc-freshness`
- `bash ./scripts/gen.sh`
- `xcodebuild -workspace UnluckySevens.xcworkspace -scheme MessagesExtension -destination 'generic/platform=iOS Simulator' build`
- `xcodebuild -workspace UnluckySevens.xcworkspace -scheme UnluckySevens-Workspace -destination 'id=444E5D9E-DDE5-4EFD-89A2-673CE380CB25' -only-testing:UnluckySevensUITests/MessagesExtensionDesignSliceUITests/testCaptureLobbyJoinSettingsRulesPolish -resultBundlePath /private/tmp/UnluckySevensLobbySettingsRules20260802F.xcresult test` (passed in 76.000 seconds; 1 test, 0 failures; Games and Tutorial both exercised through More)
- `node /Users/kunalsharda/.agents/skills/impeccable/scripts/detect.mjs --json ...` returned no findings.
- `git diff --check`
- `make doc-freshness`
- `make completion-gate PLAN=docs/exec-plans/active/lobby-settings-rules-polish.md` (passed under the standard profile after granting Tuist access to its external cache directory)
- `xcodebuild -workspace UnluckySevens.xcworkspace -scheme UnluckySevens-Workspace -destination 'id=444E5D9E-DDE5-4EFD-89A2-673CE380CB25' -only-testing:UnluckySevensUITests/MessagesExtensionDesignSliceUITests/testCaptureLobbyJoinSettingsRulesPolish -resultBundlePath /private/tmp/UnluckySevensLobbySettingsRules20260802I.xcresult test` (refinement run passed in 73.727 seconds; 1 test, 0 failures)
- Refinement rerun of `make completion-gate PLAN=docs/exec-plans/active/lobby-settings-rules-polish.md` passed under the standard profile.
- `xcodebuild -workspace UnluckySevens.xcworkspace -scheme UnluckySevens-Workspace -destination 'id=444E5D9E-DDE5-4EFD-89A2-673CE380CB25' -only-testing:UnluckySevensUITests/MessagesExtensionDesignSliceUITests/testCaptureLobbyJoinSettingsRulesPolish -resultBundlePath /private/tmp/UnluckySevensLobbySettingsRules20260802M.xcresult test` (final corrected run passed in 78.616 seconds; 1 test, 0 failures)
- Final correction rerun of `make completion-gate PLAN=docs/exec-plans/active/lobby-settings-rules-polish.md` passed under the standard profile.
- `xcodebuild -workspace UnluckySevens.xcworkspace -scheme UnluckySevens-Workspace -destination 'id=444E5D9E-DDE5-4EFD-89A2-673CE380CB25' -only-testing:UnluckySevensUITests/MessagesExtensionDesignSliceUITests/testCaptureLobbyJoinSettingsRulesPolish -resultBundlePath /private/tmp/UnluckySevensLobbySettingsRules20260802N.xcresult test` (final locked run passed in 88.404 seconds; 1 test, 0 failures; Help absence and Rules scrolling asserted)
- Final constraint-auditor review passed LSR-001 through LSR-011 against result N, current source/docs, and captures 01–04 with no actionable findings.
- Final product-UX review passed the four-screen locked set with no blocking concern.
- Final lock rerun of `make completion-gate PLAN=docs/exec-plans/active/lobby-settings-rules-polish.md` passed under the standard profile.

Fresh constraint and product-UX reviews passed against final result F and captures 01–04. The standard completion gate passed.
