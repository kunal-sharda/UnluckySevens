# Lobby Invite Identity Follow-up

## Purpose and Outcome

Correct the approved production lobby card by removing the visible player-count footer without changing its spacing, replacing the temporary dice mark with the canonical masked-robber identity, simplifying the header to the icon/Tutorial utility row without redundant brand text or divider, and slightly raising the upper lobby/settings group without moving the lower name/action block.

## Execution Settings

- Validation profile: `lightweight`
- Delivery posture: `direct`
- Rationale: the requested direction is explicit, presentation-only, and limited to two lobby components plus focused evidence.

## Context and Boundaries

- [DESIGN.md](../../../DESIGN.md) owns the canonical grey robber, dark mask, and red `7` identity.
- Roster membership, lobby actions, transport, and game rules remain unchanged.
- The roster footer's occupied height remains stable even though its count copy is removed.
- The existing three-state Messages lifecycle capture remains the observable proof lane.

## Milestones / Plan of Work

1. Replace the dice placeholder with a compact renderer that reuses `RobberPieceGeometry`.
2. Remove visible player-count copy while preserving its Dynamic Type-aware line space.
3. Remove the redundant header wordmark and divider while retaining one clean spacing step before the state title.
4. Bias the flexible middle region upward by one subtle spacing increment while preserving the lower block's frame.
5. Regenerate, run the focused lifecycle test, and inspect Send, Join, and Ready captures.

## Verification Contract and Fresh Review

<!-- verification-contract:start -->
| ID | Class | Source | Acceptance | Verification | Evidence | Status | Rationale |
| --- | --- | --- | --- | --- | --- | --- | --- |
| LIF-001 | observable | user direction | No lobby lifecycle state shows “X players at the table,” while the roster-to-settings spacing remains unchanged | installed three-state capture inspection and focused UI assertions | artifact:/tmp/unluckysevens-lobby-identity-followup-fresh; command:testCaptureProductionLobbyLifecycle-pass-2026-07-25 | pass | Roster-scoped assertions and direct captures prove the text is absent while its semantic-font line box remains |
| LIF-002 | observable | DESIGN | Lobby header uses the canonical grey masked robber with a red `7`, not a dice placeholder | production-source inspection and installed capture inspection | file:MessagesExtension/Sources/Features/Lobby/LobbyRobberIdentityMark.swift; artifact:/tmp/unluckysevens-lobby-identity-followup-fresh | pass | Header renderer consumes `RobberPieceGeometry`, preserving the app and board silhouette, mask, and `7` |
| LIF-003 | mechanical | architecture | Change remains presentation-only and preserves lobby state/action behavior | path inspection and focused lifecycle test | command:testCaptureProductionLobbyLifecycle-pass-2026-07-25; report:no-Core-or-transport-paths-changed | pass | Only lobby SwiftUI, focused UI assertions, and execution documentation changed |
| LIF-004 | observable | user direction | Header retains only the robber identity mark and Tutorial utility; redundant wordmark and divider are absent | installed three-state capture inspection | artifact:/tmp/unluckysevens-lobby-header-simplified; command:testCaptureProductionLobbyLifecycle-pass-2026-07-25-151758 | pass | Fresh Send, Join, and Ready captures show the utility row without the wordmark or divider and preserve one block-spacing step before the state title |
| LIF-005 | observable | user direction | The player lobby and Game Settings sit slightly higher while Display Name and the primary action retain their prior positions | before/after production capture geometry and focused lifecycle test | artifact:/tmp/unluckysevens-lobby-header-simplified; artifact:/tmp/unluckysevens-lobby-upper-spacing; command:testCaptureProductionLobbyLifecycle-pass-2026-07-25-152219; command:impeccable-layout-scan-clean | pass | One block-spacing bottom inset inside the fixed middle region raises the rendered roster/settings controls by about 6 pt; the region boundary, divider, lower form, and CTA remain unchanged |
<!-- verification-contract:end -->

<!-- fresh-review:start -->
| Reviewer | Required | Verdict | Evidence |
| --- | --- | --- | --- |
| constraint-auditor | no | not-applicable | Lightweight, narrowly scoped correction with direct executable and visual evidence |
<!-- fresh-review:end -->

## Living Record

### Progress

- [x] Validation profile, delivery posture, scope, and acceptance boundary locked.
- [x] Canonical robber geometry identified as the identity source.
- [x] Focused lifecycle evidence passed and inspected.
- [x] Simplified header evidence passed and inspected.
- [x] Upper-group spacing evidence passed and inspected without lower-block drift.

### Decisions

- 2026-07-25: Preserve the removed count's semantic-font line box with hidden layout space rather than tightening the approved roster rhythm.
- 2026-07-25: Render the header mark from `RobberPieceGeometry`; do not load an AppIcon raster or recreate the robber separately.
- 2026-07-25: The robber mark now carries product identity alone. Remove the repeated Unlucky Sevens wordmark and divider so the state title begins after one normal block-spacing step.
- 2026-07-25: Keep the card's flexible middle region and lower boundary intact; apply only an internal spacing bias so the upper group rises subtly without pulling Display Name or the primary action upward.

### Discoveries

- The lobby header still used the early `dice.fill` placeholder despite DESIGN naming the masked robber as the approved product identity.

## Validation and Outcome

After an initial stale-installed-extension capture exposed the old dice/count, the freshly built app bundle was explicitly installed and the focused lifecycle journey rerun. `testCaptureProductionLobbyLifecycle` passed on iPhone 17 / iOS 26.5. Direct inspection of all three exported captures confirmed:

- the canonical grey masked robber and red `7` replace the dice mark;
- no player-count footer is visible;
- the former footer line box still preserves roster-to-settings rhythm; and
- Send Invite, Join Game, and Start Game remain fully visible and hittable.

The immediate header follow-up was then validated through the same installed lifecycle lane. The focused test passed from `Test-UnluckySevens-2026.07.25_15-17-58--0700.xcresult`, and `/tmp/unluckysevens-lobby-header-simplified` confirms the header now contains only the robber mark and Tutorial utility, with no wordmark or divider.

For the final spacing follow-up, isolated visual and mechanical assessments agreed that the flexible middle region was structurally sound but centered the roster/settings cluster slightly too low. Adding one tokenized bottom inset to that internal cluster shifts its visible controls upward by about 6 pt while preserving the middle region's outer frame. The freshly installed lifecycle test passed from `Test-UnluckySevens-2026.07.25_15-22-19--0700.xcresult`; comparison of `/tmp/unluckysevens-lobby-header-simplified` with `/tmp/unluckysevens-lobby-upper-spacing` confirms the divider, Display Name, and primary action retain their prior positions. The post-change Impeccable layout detector returned no findings.

`make completion-gate PLAN=docs/exec-plans/active/lobby-invite-identity-followup.md` passed, including verification-contract enforcement, harness audit, `git diff --check`, and doc freshness.
