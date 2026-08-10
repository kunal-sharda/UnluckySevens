# Full Player Screen Catalog Rerun - 2026-08-02

## Purpose and Outcome

Rerun every canonical player-facing Messages screen from newly generated and explicitly installed builds after the lobby, Settings, Rules, Hand-count, Games, typography, robber-flow, Build-choice, lifecycle-overlay, and victory-copy refinements. Produce a fresh screenshot directory, contact sheet, and rendered PDF from the current worktree capture run.

## Execution Settings

- Validation profile: `standard`
- Delivery posture: `direct`
- Rationale: The user requested the established complete capture lane again. Product changes are out of scope unless a reproduced screen defect or stale harness assertion blocks honest evidence.

## Context and Boundaries

- [QA](../../quality/qa.md) and [UX Lab](../../quality/ux-lab.md) own simulator and capture routing.
- [Design](../../../DESIGN.md) owns approved layout and typography; the board-number serif remains the sole locked type exception.
- The prior 56-screen catalog is historical comparison evidence only. The 2026-08-09 rerun adds Rules-to-Strategy and all three full Trade teaching states, for an exact 60-screen catalog.
- Core rules, transport, and protocol behavior are unchanged. The only production refinement discovered during the rerun is a narrower three-item Build spread so Road, Settlement, and City remain simultaneously visible; DEBUG fixture routing was added for deterministic City evidence.
- Preserve unrelated dirty-worktree changes.

## Milestones / Plan of Work

1. Apply the approved victory wording and clarify that robber victim choice happens by selecting an adjacent settlement beside the robber; update focused tests and owner docs.
2. Generate, build, boot, and explicitly install the current app on iPhone 17 / iOS 26.5.
3. Run the locked canonical catalog XCUITest routes serially and export their named attachments.
4. Assemble exactly 60 fresh screens, regenerate the contact sheet and PDF, render the PDF, and inspect every screen for layout, typography, stale state, debug chrome, legacy components, and complete Trade coverage.
5. Record any reproduced defect honestly; otherwise run fresh reviews, doc freshness, and the standard completion gate.

## Verification Contract and Fresh Review

<!-- verification-contract:start -->
| ID | Class | Source | Acceptance | Verification | Evidence | Status | Rationale |
| --- | --- | --- | --- | --- | --- | --- | --- |
| FSR-001 | mechanical | AGENTS.md and QA | Current sources are generated canonically, built, installed, and launched in Messages on iPhone 17 / iOS 26.5 | canonical generation; explicit current-app install; passing installed-host UI journeys | fresh build and catalog xcresult | pass | Locked device is `C90624F4-0FA3-41FE-8823-AFCEF4AAFF20` |
| FSR-002 | observable | user request | Exactly 60 current named player screens cover the canonical root and nested states, including Rules-to-Strategy, ordinary robber states, and the complete Trade UX | serial XCUITest attachments and manifest resolution | `output/full-player-screen-catalog-2026-08-09/screens/`; catalog manifest; PDF | pass | Locked inventory is 3 lobby, 4 Settings/Rules, 17 tutorial, 3 setup, 2 start, 15 active-turn, 2 robber, 3 other-player, 2 discard, 4 expanded Trade, 4 recovery, and 1 end state |
| FSR-003 | judgment | DESIGN.md and locked decisions | Every captured screen is free of blocking clipping, typography drift, debug chrome, stale state, or unapproved legacy presentation | full-resolution image, contact-sheet, and rendered-PDF inspection | contact sheet, original PNGs, rendered PDF pages | failed | Visual review passed, but the dedicated Trade checkpoint measured a 4-point horizontal board-frame shift from Give/Get to recipient selection |
| FSR-004 | mechanical | AGENTS.md | Diff hygiene, documentation freshness, verification contract, and standard completion gate pass | repository gates | `git diff --check`, `make doc-freshness`, `make completion-gate PLAN=...` | pending | Run only after observable evidence is green |
| FSR-005 | observable | approved user wording | Local victory reads `Victory!` with the concise winning score (`10 points` in the fixture); decisive summaries use `secured the victory`, with `Gaining Longest Road` / `Gaining Largest Army` for award wins | focused unit tests plus end-screen device capture | Game status/end-model tests; end-state screenshot | pass | Proper game-term casing is required |
| FSR-006 | observable | user clarification | Robber victim guidance explicitly directs the player to select an adjacent settlement beside the robber | prompt-resolver test plus ordinary robber-victim screenshot | focused prompt test; robber victim frame | pass | Core victim eligibility and publication behavior remain unchanged |
<!-- verification-contract:end -->

<!-- fresh-review:start -->
| Reviewer | Required | Verdict | Evidence |
| --- | --- | --- | --- |
| constraint-auditor | yes | fail | Current manifest resolves exactly 60 screens and the wording constraints pass, but the Trade checkpoint reports a 4-point board-frame shift; FSR-003 therefore remains failed |
| product-ux | yes | pass-with-finding | Full contact-sheet and original-detail review confirmed current typography, robber guidance, Trade surfaces, lifecycle overlays, and unclipped Victory copy; the measured Trade geometry drift remains a follow-up |
| architecture | no | not-applicable | Capture and test-evidence scope does not change runtime boundaries |
| behavioral | no | not-applicable | Production behavior is unchanged; canonical fixture journeys assert their existing behavior |
<!-- fresh-review:end -->

## Living Record

### Progress

- [x] Validation profile, delivery posture, device, and exact 60-screen proof set locked for the 2026-08-09 rerun.
- [x] Approved copy changes implemented and focused tests updated.
- [x] Current app generated, built, and explicitly installed.
- [ ] All locked canonical routes passed and attachments exported (Trade geometry assertion remains failed).
- [x] Sixty screens, contact sheet, and PDF inspected.
- [ ] Fresh reviews and completion gate passed.

### Decisions

- 2026-08-02: Retain both the initial Rules cue and the scrolled Rules state because the cue's disappearance is a distinct approved behavior.
- 2026-08-02: Add ordinary robber movement and victim choice as dedicated production screens rather than treating tutorial or Knight captures as substitutes.
- 2026-08-03: Keep Road, Settlement, and City in one fixed Build spread; a horizontal carousel made City look absent and was inappropriate for only three choices.
- 2026-08-03: Give City targets a direct DEBUG fixture route so evidence does not depend on nested Messages-host hit testing.
- 2026-08-09: Expand the catalog from 56 to exactly 60 screens by retaining the Rules-to-Strategy destination and the three complete Trade teaching states. Use iPhone 17 / iOS 26.5 only.
- 2026-08-09: Local victory title is `Victory!`, with the concise score line (`10 points` in the fixture) so the locked end-screen column does not truncate; decisive copy uses `secured the victory`, and award wins use `Gaining Longest Road` or `Gaining Largest Army` with canonical casing.
- 2026-08-09: Robber victim guidance must name the on-board interaction: select an adjacent settlement beside the robber.

### Discoveries

- The Messages host retained an older installed extension after a source rebuild; uninstalling alone also removed the app drawer entry. The reliable recovery was canonical generation, explicit installation of `UnluckySevensApp.app`, then Simulator/Messages restart before rerunning XCUITest.
- The prior Build spread width clipped the three-option presentation. The final fixed spread uses narrower existing-style cards and preserves the established typography and board-number exception.
- Screens 7 and 8 are the tutorial navigation coach and first placement coach marks. Their dimming/callouts are deliberate tutorial layers over the current Physical Props board, not legacy gameplay components.
- 2026-08-09: The first 60-screen catalog attempt exceeded the simulator connector's fixed 300-second tool-call timeout. It left an incomplete xcresult without `Info.plist`, so it is harness infrastructure rather than product evidence. The first permitted rerun uses the same locked journeys through direct `xcodebuild`, which supports long-running serial polling without changing scope.
- 2026-08-09: Running all 18 UI routes in one `xcodebuild` invocation caused 13 Messages-host signal-kill results. Isolating each missing route into its own `test-without-building` invocation eliminated those host-process failures.
- 2026-08-09: The new lifecycle overlay was visibly correct, but its container identifier was not exposed through the host accessibility tree. The harness now asserts the globally exposed action identifiers and copy; Resign and Host End both pass and attach their screenshots.
- 2026-08-09: The dedicated Trade checkpoint reproduced a 4-point horizontal board-frame shift between Give/Get and recipient selection. The PDF retains complete Trade UX using the fresh canonical tutorial recipient and maritime attachments, but this measurement blocks a clean completion claim.
- 2026-08-09: Focused UI runs can retain an older installed Messages extension after rebuilding. Explicitly reinstalling `UnluckySevensApp.app` before the final Victory capture produced the current concise `10 points` line and removed the stale ellipsis.

## Validation and Outcome

- `bash ./scripts/gen.sh` — passed after each current-source capture slice.
- Focused presentation tests — 26 passed, 0 failed for status, end-model, and physical prompt resolvers.
- Isolated catalog routes — all required routes passed except `testCapturePhysicalTradeCorrectionTutorialCheckpoint`; that route failed its recipient-selection board midpoint assertion by 4 points after attaching Give/Get.
- Corrected lifecycle routes — Resign and Host End passed; attached Resign Confirmation, Host End Decision, and Neutral Host End.
- Final explicitly reinstalled Victory route plus `GameScreenModelBuilderTests` — passed; device screenshot shows `Victory!`, `10 points`, and `Your city secured the victory.` without truncation.
- Catalog builder — resolved exactly 60 screens; emitted `output/full-player-screen-catalog-2026-08-09/contact-sheet.png`, `catalog-manifest.json`, and `output/pdf/unlucky-sevens-all-player-screens-2026-08-09.pdf`.
- `pdfinfo` — 61 pages (cover plus 60 screens); all 61 pages rendered through Poppler and the contact sheet plus wording-critical originals were inspected.
- Completion gate intentionally not run because FSR-003 is failed; the verification contract prohibits a completion claim until the Trade geometry drift is resolved or explicitly accepted.
