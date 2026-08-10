# Single-Device UX Lab

This guide owns DEBUG fixture coverage and repeatable design-review capture. It does not replace the [real-device lanes](device-runbooks.md#real-device-lane) or the completion evidence rules in [constraint verification](constraint-verification.md).

DEBUG builds include a compact UX Lab overlay in the Messages extension so visual and interaction audit work can happen on one device without needing a live two-account table. The lab can also drive a local dummy table: state-producing actions are applied back into the preview state, and the actor picker can switch between the real local player and dummy players.

Use it for fast design iteration only:

1. Build and install a Debug build.
2. Open Unlucky Sevens from the Messages app drawer.
3. Tap the top-right `Preview` / `UX Lab` control.
4. Choose a fixture and an `Acting as` player.
5. Tap `Load`, inspect the shell, and interact with the visible actions.
6. Tap `Exit` before validating normal transcript behavior.

For a one-device playthrough, load `lobby-invite`, switch `Acting as` to Maya or Theo, and use the join action. Actor switching keeps the current local table instead of resetting the fixture, so you can return to Kunal to start and continue into setup/gameplay. Keep `Follow turn owner` enabled when you want the lab to auto-hop to the current player after a local action; disable it when you want to inspect another player's blocked or waiting view.

Enable `Auto dummy turns` to make the lab move every actor except the selected `You` actor. The dummy policy is intentionally simple: it seats missing dummy players in the lobby, takes first legal setup placements, rolls dice, submits required discards, moves the robber/selects the first steal victim, and ends dummy turns after the roll. It does not build a real Catan strategy, author trades, buy/play development cards, or validate real Messages delivery.

Current fixtures cover:

- `lobby-invite`
- `lobby-ready`
- `setup-placement`
- `turn-needs-roll`
- `turn-after-roll`
- `waiting-on-alice`
- `pending-discard`
- `robber-move`
- `robber-victim`
- `trade-offer`
- `game-over`
- `Recovery Games`, which seeds one validated Active record and one validated Finished record for management journeys

While UX Lab is active, the view model uses local fixture state and local actor override. It does not publish `MSMessage` bubbles; state-producing actions are applied back into the local preview path. That makes it useful for screen-by-screen design review and one-device dummy-user flow checks, but it does not validate transcript URL transport, bubble delivery, cross-device selection, same-session folding, or real Messages lifecycle behavior.

The `UnluckySevensUITests` XCUITest harness can drive the simulator through Messages, open the Unlucky Sevens app drawer item, and attach screenshots of the canonical Invitation slice plus the UX Lab panel to the `.xcresult` bundle. Retired lobby-direction comparisons are no longer UX Lab routes. The harness is a design-review capture aid, not a replacement for the real-device Messages lane. It expects Messages to have at least one existing simulator conversation and falls back to the first visible conversation if the seeded `+1 (888) 555-1212` thread is unavailable.

Default visual iteration lane:

- Use the normal iOS Simulator window for live visual review and interaction.
- Use the XCUITest design-slice harness for repeatable invite/lab/gameplay captures.
- Use DEBUG-only UX Lab clean-shot controls to load common fixture states and hide the UX Lab chrome before screenshots.
- Use `xcrun simctl io <device> screenshot <path>` for quick still screenshots after the harness has placed the simulator in the target state.
- Use Computer Use only for one-off simulator gaps the harness cannot yet reach. If a manual path is needed more than once, add an XCUITest helper or UX Lab automation control instead.

Treat the XCUITest attachment and a direct simulator still as different evidence paths. The Messages host can occasionally serialize embedded compositor surfaces as black rectangles in `XCUIApplication.screenshot()` even though frame assertions pass and the live simulator is rendering correctly. When that happens, keep XCUITest as the deterministic navigation and assertion lane, capture the settled state with `simctl`, and visually inspect the direct still. A green UI test or the mere existence of an attachment is not visual evidence.

The clean setup gameplay capture path is `MessagesExtensionDesignSliceUITests/testOpenMessagesExtensionAndCaptureCleanSetupGameplaySlice`. It opens Messages through the same reusable navigation helpers, opens UX Lab, taps the `uls.uxLab.cleanShot.setupPlacement` control, waits for the setup board, asserts the UX Lab toggle is hidden, and attaches a screenshot after the debug chrome is hidden.

The start-of-turn comparison path is `MessagesExtensionDesignSliceUITests/testOpenMessagesExtensionAndCaptureStartOfTurnComparison`. It captures the normal `turn-needs-roll` fixture, then uses the `Start Dev` item in the DEBUG quick-state menu to reload the same fixture with the pre-roll Dev Card route open. The direct DEBUG `uls.uxLab.cleanShot.turnNeedsRollDevChooser` control is reserved for a deterministic City-target fixture because the embedded Messages XCTest host can expose nested Build choices with invalid accessibility hit points. `testCaptureCityTargetAndGameInfoRegression` owns that direct City proof.

The normal-turn gameplay capture path is `MessagesExtensionDesignSliceUITests/testOpenMessagesExtensionAndCaptureTurnGameplaySlice`. It opens the same UX Lab path, taps the DEBUG clean-shot `uls.uxLab.cleanShot.turnAfterRoll` control, waits for the `turn-after-roll` board, hides the UX Lab chrome, and exercises Hand, independent Bank reveal, Build, Trade, Hand-nested Dev, End, and Game Information routes. It asserts stable top/public-rail/board geometry and a stable DEBUG board-host identity while attaching route screenshots. Use the default Hand capture when judging board tile art independent of setup/build affordances. The shell no longer owns a resize-snapshot replacement UI; a resize regression must therefore be diagnosed in the live shell or board-owned continuity path rather than accepted as a transient legacy composition.

The active-proposer pending-trade capture path is `MessagesExtensionDesignSliceUITests/testOpenMessagesExtensionAndCapturePendingActivePlayerTradeSlice`. Its DEBUG clean-shot control loads `trade-offer` while acting as the proposer, then verifies the anchored `Pending` marker, live recipient responses, and replacement action inside the normal Turn Screen action well.

The ordinary robber capture path is `MessagesExtensionDesignSliceUITests/testCaptureRobberPhysicalFlow`. It loads `robber-move` and `robber-victim` directly, rejects the retired command-bar and forced-flow surfaces, and verifies that the top bar, public rail, mounted board, and turn-object rail keep identical geometry as the prompt advances from `Move the Robber` to `Choose a Player`.

The functional recovery/lifecycle paths are `testRecoveryGamesArchiveAndRestoreJourney`, `testRecoveryResendAndResignationContinuesJourney`, `testRecoveryGamesLibraryUsesDedicatedSurface`, `testRecoveryResignConfirmationExplainsContinuedPlay`, and `testHostEndOffersDrawBeforeUnilateralEnd`. They exercise the dedicated Games destination, local archive followed by later valid fixture restore, unchanged resend, non-terminal resignation, accurate confirmation copy, and the draw-first host-end soft guard. Because UX Lab applies publishes locally, these paths prove UI orchestration but not transcript delivery, session replacement, or cross-device agreement.

Normal-turn board captures should not show empty corner caps or heavy empty-edge rails as if every placement target is active. Tile art should render at the canonical topology radius so painted hexes align with roads, ports, nodes, tokens, and hit testing. Passive tile seams may remain visible. Actual roads, settlements/cities, ports, and the robber may be visible as live SpriteKit pieces; legal setup/build node and edge highlights should appear only while the active mode can legally use those targets.

Messages exposes the app drawer differently across simulator/runtime states. The harness first tries stable button labels such as `add` and `Apps`, then falls back to tapping the visible bottom-left drawer control.

When iterating on the Messages extension UI, the simulator can keep rendering an older installed extension even after the workspace build product contains the new code. If a screenshot shows stale copy or layout, or if the app drawer item disappeared after an uninstall, explicitly install the latest `UnluckySevensApp.app` into the booted simulator, terminate `com.apple.MobileSMS`, and rerun the capture harness before judging the design. The XCUITest target drives Messages; it does not replace a missing installed iMessage app bundle by itself.

Before TestFlight or any release claim, follow the relevant Real Device Lane checklist even if the UX Lab pass looked good.
