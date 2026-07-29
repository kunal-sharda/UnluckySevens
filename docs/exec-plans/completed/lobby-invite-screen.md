# Lobby Invite Screen

## Purpose and Outcome

Establish one coherent lobby presentation from the first invitation through guest joining and host readiness, ending at the existing host-owned handoff into setup. The screen should feel like opening and filling a physical board-game table inside Messages, while keeping the canonical lobby `STATE` chain and existing transport behavior unchanged.

Parent: [Phase 14](../active/phase-14-ui-design-bubble-polish-and-trust-surfaces.md).

The completed Settings, Rules, and full lobby Tutorial work is recorded by the focused [Settings, Rules, and Click-Through Tutorial](../completed/settings-rules-tutorial.md) child plan.

## Execution Settings

- Validation profile: `standard`
- Delivery posture: `checkpointed`
- Rationale: invitation, joining, and setup handoff behavior are already settled, but the visual composition across those states requires user judgment before productionization.

## Context and Boundaries

- This slice owns the empty invite entry, selected-bubble guest join, joined/waiting roster, host ready state, and the visible `Start Game` handoff into setup.
- The existing `LobbyScreenModelBuilder` remains the presentation boundary. Core and transport continue to own roster validity, lobby transitions, canonical state publication, and the setup transition.
- The canonical path remains one invite `STATE`, joined lobby `STATE` updates on the same game session, and one host-published start `STATE`.
- The local post-send shell remains informational; it does not become a second roster or start authority.
- The screen may reuse the approved tabletop material, type, spacing, and physical-object grammar. It must not introduce a board preview, protocol field, new join semantic, or setup rule.
- Transcript bubble art and copy, setup placement UI, gameplay shells, and game recovery are excluded except where the existing handoff label or selected-bubble context must remain legible.
- Screenshot evidence stays outside Git.

## Milestones / Plan of Work

1. Audit the existing invite, join, joined/waiting, and host-ready states against UI flows, the tabletop system, Dynamic Type, VoiceOver, and Messages-host geometry.
2. Produce one checkpointed direction using existing production behavior and fixtures. Keep one dominant command surface, a legible roster, and one obvious next action in every state.
3. Capture no more than three representative states: first invite, guest join, and host ready-to-start. Stop for user review.
4. After approval, productionize any remaining nested/warning/post-send states, run fresh standard-profile reviews, and execute the completion gate.

## Approval Gate

Authority: user.

Proof: direct installed-simulator captures of first invite, guest join, and host ready-to-start using the checked-in UX Lab/XCUITest harness and production components.

Round budget: two visual rounds by default. While approval is pending, do not claim the direction as productionized, run fresh final review, or run the completion gate.

## Verification Contract and Fresh Review

<!-- verification-contract:start -->
| ID | Class | Source | Acceptance | Verification | Evidence | Status | Rationale |
| --- | --- | --- | --- | --- | --- | --- | --- |
| LIS-001 | mechanical | decisions and architecture | Invite, join, and start preserve the canonical lobby `STATE` chain and setup transition ownership | focused presentation tests plus code inspection | command:LobbyScreenModelBuilderTests-6-pass-2026-07-25; report:lobby-behavior-review-pass-2026-07-25 | pass | Refactor is presentation-only and retains the existing invite, join, name, and start callbacks |
| LIS-002 | observable | UI flows | First invite, guest join, joined/waiting, and host ready states each expose one clear next action and accurate roster context | installed harness journey and direct still inspection | artifact:/tmp/unluckysevens-lobby-lifecycle-verified; command:testCaptureProductionLobbyLifecycle-pass-2026-07-25 | pass | Invite, Join, and Ready are captured; focused model tests cover passive joined and waiting variants |
| LIS-003 | observable | accessibility and Messages-host contracts | Interactive controls retain 44-point targets, semantic text behavior, stable VoiceOver labels, and usable compact-host layout | focused UI assertions and code inspection | command:testCaptureProductionLobbyLifecycle-pass-2026-07-25; command:testOpenMessagesExtensionAndCaptureLobbyInviteDirections-pass-2026-07-25 | pass | Primary actions are asserted 44-point, hittable, and fully contained; Tutorial and Settings are exercised end to end |
| LIS-004 | judgment | DESIGN and tabletop UI system | The lobby reads as a compact premium tabletop invitation rather than a generic form or nested dashboard | explicit user verdict after captures | verdict:user-approved-productionization-2026-07-25; report:lobby-product-ux-review-pass-2026-07-25 | pass | User approved the four-row Invitation Card direction and authorized productionization |
| LIS-005 | observable | UI flows and messages-host lessons | Post-send waiting stays informational, joining publishes immediately, and only the selected canonical lobby exposes host start | existing focused tests and harness checks | command:LobbyScreenModelBuilderTests-6-pass-2026-07-25; report:lobby-constraint-audit-pass-2026-07-25 | pass | Model coverage proves passive post-send and selected-host action ownership without changing canonical transport |
<!-- verification-contract:end -->

<!-- fresh-review:start -->
| Reviewer | Required | Verdict | Evidence |
| --- | --- | --- | --- |
| constraint-auditor | yes | pass | Fresh review on 2026-07-25 found LIS-001 through LIS-005 satisfied by the current diff and exact artifacts |
| architecture | no | not-applicable | Trigger only if presentation boundaries or dependency direction change |
| behavioral | yes | pass | Fresh review on 2026-07-25 found canonical routing, roster semantics, copy, and action ownership correct |
| product-ux | yes | pass | Fresh high-detail review on 2026-07-25 found no blocking issues in Send, Join, or Ready |
<!-- fresh-review:end -->

## Living Record

### Progress

- [x] Validation profile, delivery posture, scope, exclusions, and approval gate locked.
- [x] Existing lobby presentation and fixtures audited.
- [x] First paper rules-card direction implemented and rejected by the user.
- [x] Second full-felt physical-seat direction stopped after user correction; it used the gameplay metaphor on the wrong surface.
- [x] Two instruction/invitation probes shaped for direct comparison: Field Guide and Game Night.
- [x] Same-state installed-simulator captures produced for both probes.
- [x] Both probes rejected after repo-system review; neither is a production baseline.
- [x] Replacement Setup Card and Invitation Card probes implemented within the approved Mode 3 tabletop system and captured from the same installed-simulator state.
- [x] User selected Invitation Card over Setup Card and requested a full-host refinement.
- [x] The rejected full-host cream interpretation was replaced with a felt-host composition whose contained invitation card uses the available height.
- [x] User approval recorded for the refined Invitation Card composition, copy, and muted-paper direction.
- [x] User provisionally accepted the neutral-stone card and control surfaces, with a whole-app visual consistency pass still required.
- [x] User explicitly approved productionizing the Invitation Card across the lobby lifecycle.
- [x] Approved direction productionized and fresh standard-profile reviews passed.
- [x] Standard completion gate passed.

### Decisions

- 2026-07-18: The lobby remains an instruction-guide/invitation surface. The correction is not to abandon paper, but to design the paper as a real board-game setup leaflet with editorial hierarchy, useful diagramming, RSVP-style identity, and a progressive Invite → Join → Begin Setup structure.
- 2026-07-18: At the user's request, the next checkpoint compares two genuinely different hierarchies in the same first-invite state: a precise Field Guide led by setup sequence, and a warmer Game Night invitation led by the social promise. Both remain DEBUG-only probes until the user chooses.
- 2026-07-19: Both comparison probes are rejected. They changed palette, typography, and surface archetype instead of branching within the approved tabletop system. The correction must follow the Mode 3 Lobby contract in `docs/design/tabletop-ui-system.md`: existing felt/cream/wood roles, `GameTheme` SF typography, player iconography, and action amber; the lobby adapts those into a welcoming rules/setup card without copying gameplay rails or inventing a separate brand system.
- 2026-07-19: The replacement comparison holds the visual system constant and varies only information hierarchy. Setup Card leads with the canonical Invite → Join → Setup sequence. Invitation Card leads with host/friend participation and keeps setup as the handoff note. Both use `GameTheme`, `GamePhysicalTurnPalette`, the shared wooden name-tile grammar, semantic SF typography, and one wood/amber primary action.
- 2026-07-19: The user selected Invitation Card. Its refinement removes the redundant subtitle, expands the cream invitation surface to fill the Messages host, and adds a compact 44-point Unlucky Sevens dice mark plus a How to Play control that presents the existing rules sheet. The mark is an identity anchor rather than a logo hero; final title, action, and handoff wording remain open at the checkpoint.
- 2026-07-19: The user rejected the edge-to-edge cream interpretation. “Use the whole screen” means allocate the available canvas intentionally, not turn the host into paper. The correction restores the established felt host, keeps cream as a bounded physical invitation card, enlarges the participant region, and anchors identity/send controls at the bottom of the card. No filler copy or new metaphor was added.
- 2026-07-19: The bottom handoff sentence is removed at the user's direction. It repeated the visible invitation flow and previewed a setup state that does not need explanation here. The primary action now ends the card.
- 2026-07-19: The invitation roster changes from a horizontal strip to four stacked rows: You, Friend, Friend, Optional. The generic “3–4 players / Async turns” metadata is removed. A Game Settings disclosure now summarizes the selected supported first-beta contract—Standard rules, Balanced board, 10 points—and opens a read-only settings sheet. Unsupported deferred variants are not presented as working controls.
- 2026-07-19: The tutorial utility is labeled “Tutorial” rather than “How to Play.” The contained card retains the existing cream surface token for this edit; a slightly felt-muted version is the recommended next color comparison because it preserves the established paper role without introducing an unrelated neutral palette.
- 2026-07-19: The user approved trying the color refinement. The Invitation Card now uses a dedicated muted-paper token derived toward the established felt hue; the global cream surface remains unchanged. This is a checkpoint color candidate, not yet a repo-wide token change.
- 2026-07-19: The user approved the muted-paper Invitation Card direction with “That’s great.” This closes the visual-direction gate. Productionization of joined, waiting, ready, and setup-handoff states remains outstanding.
- 2026-07-19: At the user's direction, the invitation neutrals move decisively away from generic warm beige. The card is a low-chroma sage-gray derived from the felt family; open seats, Game Settings, and the name field use a deeper moss-neutral. Amber remains reserved for the host/selection state and dark wood for the primary action.
- 2026-07-19: The visible sage cast was too thematic for the invitation surface. The next checkpoint uses near-neutral stone for both the card and controls, with only a slight green bias to relate them to the felt; amber and wood retain their established semantic roles.
- 2026-07-19: The user provisionally accepted the neutral-stone checkpoint for delivery. This does not close the visual judgment constraint: the lobby must still be reviewed beside the rest of the app before the direction is treated as durable or the completion gate can pass.
- 2026-07-25: The user authorized productionization after confirming the earlier lobby invite work had not yet reached the release path. The approved Invitation Card now becomes the single visual shell for fresh invite, selected guest join, joined/waiting, host-ready, and post-send recovery states; the existing `LobbyScreenModelBuilder` and canonical lobby `STATE` behavior remain unchanged.
- 2026-07-18: The full-felt physical-seat direction is rejected before comparison. Felt is the gameplay table metaphor and is not the right dominant material for the invitation/setup guide.
- 2026-07-18: The first rules-card direction is rejected. It read as a giant beige form with dashboard chips, excessive explanatory copy, and too little sense of a live table. It is not an implementation baseline for round two.
- 2026-07-18: Round two keeps one persistent felt table and uses four physical seat/name markers as the central lobby object. Invite, Join, and Ready change by filling that table rather than swapping card layouts.
- 2026-07-18: The Lobby Invite Screen owns the presentation continuum from first invitation through host readiness, but setup begins only after the existing canonical start transition.
- 2026-07-18: The visual checkpoint uses three representative states rather than treating every lobby branch as a separate design direction.

### Discoveries

- The production code already separates the pre-invite hero from canonical selected-lobby states and has focused presentation-model tests. That implementation is a baseline for the comparison, not approval evidence by itself.
- The Field Guide probe violated the typography contract with monospaced interface labels and fixed oversized display type, and made the entire host a new editorial-paper system.
- The Game Night probe violated the same typography contract with SF Rounded, introduced a navy/coral palette outside established roles, and used an oversized marketing hero explicitly excluded by `DESIGN.md`.
- Installed visual inspection of the replacement probes confirms that both read as the same product family. The input prompt was explicitly darkened to `GameTheme.mutedInk` after the first replacement capture exposed insufficient default placeholder contrast.

## Validation and Outcome

Checkpoint evidence produced on the designated iPhone 17 / iOS 26.5 simulator:

- `bash ./scripts/gen.sh` — passed.
- Generic `MessagesExtension` simulator build — passed.
- `MessagesExtensionDesignSliceUITests/testOpenMessagesExtensionAndCaptureLobbyInviteDirections` — passed after explicitly installing the fresh Messages app bundle, with Field Guide and Game Night attachments captured from the same first-invite state.
- Direct visual inspection — both probes fit the Messages host and preserve a single primary invitation action, but fail repo-system conformance and are rejected.
- Replacement checkpoint: generic Messages-extension build passed; the installed `testOpenMessagesExtensionAndCaptureLobbyInviteDirections` journey passed with final Setup Card and Invitation Card attachments after the prompt-contrast correction. User choice remains pending, so neither branch is productionized and the completion gate remains blocked.
- Selected-direction refinement: `bash ./scripts/gen.sh`, workspace `build-for-testing`, and the installed `testOpenMessagesExtensionAndCaptureLobbyInviteDirections` journey passed on iPhone 17 / iOS 26.5. The fresh Invitation Card attachment shows the cream surface filling the host, the subtitle absent, and the compact brand/tutorial header visible. The UI test also tapped How to Play, asserted the `Game rules` navigation surface, and dismissed it successfully. Final wording and user approval remain pending, so productionization and the completion gate remain blocked.
- Canvas-use correction: isolated layout assessment found a collapsed intrinsic-height stack and passive trailing whitespace; the isolated mechanical scan found no spacing-scale violations. The corrected installed capture restores the felt perimeter and distributes a single contained card into compact identity, flexible participant, and bottom action zones. Project generation, workspace `build-for-testing`, the focused installed UI journey, tutorial-sheet assertion, post-change layout detector (`[]`), and `git diff --check` passed. User approval and final copy remain pending.
- Stacked-roster/settings checkpoint: project generation and workspace `build-for-testing` passed. The installed focused UI journey passed with assertions for four stacked invitation slots, absence of “Async turns,” the Game Settings disclosure, the selected-rule sheet, and the existing tutorial sheet. The captured rule summary is “Standard rules · Balanced board · 10 points.” The first settings assertion run failed because `LabeledContent` exposes its values through accessibility values rather than standalone static text; the assertion was corrected to the visible row labels and the rerun passed.
- Muted-paper color checkpoint: project generation, workspace `build-for-testing`, and the installed focused UI journey passed. The direct capture shows the dedicated invitation surface reading as a desaturated felt-tinted paper while the warmer settings/input surfaces retain their existing hierarchy. Tutorial and settings interactions remain green. The user approved this direction; productionization and the standard completion gate remain pending.
- Sage-form color checkpoint: the card moved further toward a low-chroma sage-gray and the open seats, settings disclosure, and name field now share one explicit moss-neutral surface. Computed contrast is 4.58:1 for muted text on controls and 5.72:1 on the card. Project generation, workspace `build-for-testing`, the installed focused UI journey, and direct capture passed. User verdict on this exact palette remains pending.
- Neutral-stone color checkpoint: the card and secondary controls now use near-neutral stone surfaces with only a slight green bias. Computed contrast is 4.56:1 for muted text on controls and 5.78:1 on the card. Project generation, workspace `build-for-testing`, the installed focused UI journey, and direct capture passed. User verdict on this exact palette remains pending.
- Production closeout: the approved Invitation Card is now the release-path shell for first invite, selected guest join, joined/waiting, host-ready, and post-send states. `LobbyScreenModelBuilderTests` passed 6/6; `testCaptureProductionLobbyLifecycle` passed with exact Send, Join, and Ready attachments and action containment/hittability assertions; and `testOpenMessagesExtensionAndCaptureLobbyInviteDirections` passed through Settings and Tutorial. Fresh constraint, behavioral, and product-UX reviews all passed.
- Standard completion gate: `make completion-gate PLAN=docs/exec-plans/active/lobby-invite-screen.md` passed on 2026-07-25, including verification-contract enforcement, harness audit, `git diff --check`, doc freshness, project generation, and the generic Messages-extension simulator build.

The first failed attempts were stale-installed-extension evidence and a too-tall direct UX panel route. The durable harness uses the compact `States → Lobby` menu and the repo-documented explicit-install recovery. The verification contract, fresh reviews, and standard completion gate are green.
