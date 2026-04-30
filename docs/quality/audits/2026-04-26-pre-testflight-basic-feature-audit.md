# 2026-04-26 Pre-TestFlight Basic Feature Audit

Scope: focused check of small but visible pre-TestFlight features after the legacy/runtime cleanup and one-step trade simplification. This audit covers forced-discard ordering, board highlighting, board-balance defaults, and low-risk UI polish.

## Findings

### F1 — Ordered forced discard must be enforced below the UI

Status: fixed in the current slice.

The Messages UI already exposes discard submission only to the next pending discarder in roster order through `PendingDiscardOrderResolver`, but the core reducer previously accepted any required player who submitted from the same pending-discard state. That left the locked decision dependent on the app shell instead of the engine.

Fix landed:

- `TurnReducerV1` rejects out-of-order `submitDiscard` with `discardSubmissionOutOfOrder`.
- `CoreGameValidation` rejects forged out-of-order discard transitions.
- `TurnRollSevenV1Tests` covers reducer rejection and transition-validation rejection.

Remaining manual check: in a real-device multi-discard seven, confirm older bubbles do not allow the second pending discarder to publish before the first pending discarder has published.

### F2 — Balanced-board support exists, but the product default is still plain random

Status: product decision needed before external beta.

The engine has `BoardGenStrategyV1.noRedAdjacentV1` and tests prove it avoids adjacent 6/8 tokens. The default `BoardRulesV1` and `LobbyDriverViewModel` fallback still use `.randomV1`, and there is no visible product control after debug surfaces were removed.

Risk: first beta games can produce legal but rough-feeling boards with adjacent red numbers. That is valid Catan, but it may read as unfair to early testers when the app already has a safer generator.

Recommendation before external TestFlight: either make `.noRedAdjacentV1` the default for new games, or expose a small host-only "Balanced board" option in the lobby. The lowest-risk product choice is changing the default while leaving `randomV1` supported for old/local test states.

### F3 — Board highlighting is feature-complete, but selected-target changes still rebuild the whole overlay layer

Status: not a correctness blocker; test on hardware before deciding whether to patch pre-beta.

The overlay model covers legal tiles, nodes, edges, setup-road anchor highlighting, and selected-target emphasis. However, `GameBoardScene.updateOverlay` keys the whole overlay layer by `overlayModel`, so a selection-only change clears and rebuilds every highlight node.

Risk: setup/build confirmation may feel flickery or sluggish on older devices, especially when many legal nodes are shown.

Recommendation: if hardware smoke shows visible flicker, split overlay rendering into a stable legal-target layer and a small selected-target layer. If hardware feels stable, keep this as phase-15 render polish rather than delaying beta.

### F4 — Compact icon controls should get explicit accessibility labels

Status: low-risk polish candidate.

Several compact controls are visually clear but rely on icon-only or mostly-icon labels, including the lower-rail pull tab and shelf/trade close buttons. VoiceOver will not consistently describe these as product actions.

Recommendation before beta if time allows: add explicit labels such as "Open shelf", "Close shelf", and "Close trade panel" to those controls. This is small, low-risk UI polish and aligns with the existing product-focused cleanup.

### F5 — Production board/bubble visual regression coverage is still shallow

Status: known debt; do not block the first small TestFlight group if manual device QA passes.

Snapshot tests exist, but they do not yet cover enough production board states, transcript bubble variants, and device-sized compositions to replace real-device review.

Recommendation: for the first beta, rely on the real-device QA lane and collect screenshots for any visual issue. Add deeper snapshot fixtures before widening the beta audience.

## Recommended Pre-TestFlight Order

1. Keep the ordered-discard core fix.
2. Decide the board default: prefer `.noRedAdjacentV1` for new games unless there is a strong product reason to keep fully random boards.
3. Add accessibility labels to icon-only compact controls.
4. Run the real-device highlighting/setup/build smoke on iPhone and iPad.
5. Defer overlay-layer splitting unless the hardware smoke exposes visible flicker.
