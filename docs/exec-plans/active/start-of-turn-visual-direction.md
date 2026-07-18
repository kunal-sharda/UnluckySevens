# Start-of-Turn Visual Direction

## Purpose and Outcome

Establish the active player’s pre-roll ritual as a distinct physical tabletop state: choose a legal owned Dev Card or roll two physical dice, complete any chosen Dev action, then return to a roll-only state before entering the approved post-roll Turn Screen.

Parent: [Phase 14](phase-14-ui-design-bubble-polish-and-trust-surfaces.md).

## Execution Settings

- Validation profile: `standard`
- Delivery posture: `checkpointed`
- Rationale: the rules and reuse boundary are settled, but the transient composition and dice motion require visual judgment before production routing and nested-state completion.

## Context and Boundaries

- Reuse the approved [Tabletop UI System](../../design/tabletop-ui-system.md), one mounted `BoardContainerView`, existing owned-Dev presentation, and the `turn-needs-roll` UX Lab fixture.
- Core/query and presentation outputs remain the sole sources of roll and Dev legality. Dice animation decorates the Core-owned result and never generates randomness.
- The comparison may expose the physical Start-of-Turn composition through the existing DEBUG `Props` style, but production pre-roll routing remains unchanged until approval.
- Forced seven, post-roll, out-of-turn, lobby, setup, settings, transcript, and game-over surfaces are excluded.
- Screenshot and video evidence stays outside Git.

## Milestones / Plan of Work

1. Add a reusable physical dice pair and Start-of-Turn surface using the existing tabletop palette, owned-card props, prompt grammar, and fixed board host.
2. Present Dev Cards and Roll as physical objects when at least one pre-roll Dev action is legal; present Roll alone otherwise or after a Dev action resolves.
3. Reuse the existing Dev chooser and staged selection routes. Closing Dev returns to the choice state without consuming a card.
4. Animate dice with a bounded, code-native SwiftUI bowl sequence that is present in the first post-tap frame. During motion, tapping skips to the exact result; after settling, the overlay remains until the player taps to continue. Reduce Motion crossfades directly to the result but still waits for explicit continuation.
5. Capture no more than three representative proofs: ready choice, opened Dev chooser, and rolling/result transition. Stop for user review.
6. After approval, productionize the pre-roll route, complete staged Dev-return behavior, and run the standard verification gate.

## Approval Gate

Authority: user.

Proof: direct installed-simulator captures of ready choice, Dev chooser, and roll transition using the existing fixture and production components.

Round budget: two visual rounds by default. While approval is pending, do not make the physical Start-of-Turn route the Release default, run fresh specialist review, or run the completion gate.

## Verification Contract and Fresh Review

<!-- verification-contract:start -->
| ID | Class | Source | Acceptance | Verification | Evidence | Status | Rationale |
| --- | --- | --- | --- | --- | --- | --- | --- |
| STR-001 | mechanical | Core/query ownership | Roll and pre-roll Dev availability come from existing engine/query-derived presentation; animation does not choose the roll | focused tests and code inspection | `GameShellView` consumes `actionDock` availability and invokes the existing roll publisher only after decoration | pass | No legality or randomness was added to SwiftUI |
| STR-002 | observable | user direction | Ready state shows physical Dev Cards and Dice, Dev can close back to Roll, and used/unavailable Dev leaves Roll alone | installed UX Lab/XCUITest journey and direct still inspection | installed choice and executable-only Dev chooser captures; full used-Dev return remains post-approval | pending | Visual half proven; production nested return remains gated |
| STR-003 | observable | tabletop system | Board identity and geometry remain stable while the transient Start-of-Turn surface changes | board-host identity/frame assertions | `testOpenMessagesExtensionAndCaptureStartOfTurnComparison` passed with frame and host-value assertions | pass | Same board host survives choice, chooser, and skipped roll |
| STR-004 | observable | accessibility and motion contract | Controls retain 44-point hit regions, stable labels, `Tap to skip` during motion, `Tap to continue` after settling, no automatic dismissal, and Reduce Motion fallback | focused UI assertions and code inspection | focused phase-copy tests and installed two-device review pending | pending | Interaction contract changed after the initial proof |
| STR-005 | judgment | user | The comparison establishes the intended Start-of-Turn ritual strongly enough to productionize | explicit user verdict after captures | pending | pending | Approval gate is open |
<!-- verification-contract:end -->

<!-- fresh-review:start -->
| Reviewer | Required | Verdict | Evidence |
| --- | --- | --- | --- |
| constraint-auditor | yes | pending | Required after approval and productionization |
| architecture | no | not-applicable | Trigger only if board ownership or dependency direction changes |
| behavioral | yes | pending | Required after productionization because publication timing and Dev return behavior are observable |
| product-ux | yes | pending | Required once after productionization; user owns the comparison gate |
<!-- fresh-review:end -->

## Living Record

### Progress

- [x] Natural-roll correction starts the first die immediately, renders active motion at 60 fps, uses unequal ballistic arcs and settle timing, and blends into the Core-owned result orientation without an end snap.
- [x] Device-review correction replaces the stacked near-black chooser/roll fills with one safe-area-covering translucent charcoal veil and promotes Build cost numerals to primary heavy ink.
- [x] Existing `turn-needs-roll` fixture and Core/query Dev timing inspected.
- [x] Validation profile, checkpointed posture, comparison states, and exclusions locked.
- [x] DEBUG physical comparison implemented.
- [x] Three-state evidence captured for presentation.
- [x] First correction round requested and rendered as a full-table ritual overlay.
- [ ] User approval recorded or final correction requested.

### Decisions

- 2026-07-17: The dimensional bowl remains authored rather than unconstrained physics. Physics-shaped parabolic paths, asymmetric angular decay, a 60 ms second-die stagger, and unequal settling preserve deterministic outcomes while removing waypoint and final-snap artifacts.
- 2026-07-17: Start-of-Turn and dice-roll focus use one translucent charcoal veil rather than opaque black. The board remains faintly legible, the veil covers the entire extension host including safe areas, and chooser/roll layers never stack their dimming fills.
- 2026-07-16: Start of Turn is a distinct transient screen state on the same mounted gameplay table, not another post-roll action-well route and not a second board shell.
- 2026-07-16: Choosing Roll does not forfeit legal post-roll Dev play. Completing a pre-roll Dev action returns to Roll only because the one-card-per-turn limit has been consumed.
- 2026-07-16: A roll requires deliberate player input after Dev resolution; the app never auto-rolls.
- 2026-07-16: The roll overlay never uses `Tap to settle` and never dismisses itself. An unskipped roll lasts 2.4 seconds, motion offers `Tap to skip`, and the settled result waits on `Tap to continue`.
- 2026-07-16: The physical bowl keeps the high angular energy needed for a readable roll but reduces lateral launch energy, adds a continuous tall collision ring inside the wooden rim, and lowers restitution. Dice remain visibly active without escaping or roaming across the table area.
- 2026-07-16: The captured transition proved that mount-time rigid-body physics completed before SceneKit presented a meaningful frame. The comparison now uses a deterministic authored drop, rebound, impact, and settle sequence triggered after the bowl's first rendered frame; the Core-owned result remains unchanged.
- 2026-07-16: A stitched XCUITest frame sequence made the restored SceneKit comparison appear laggy and was incorrectly treated as runtime-performance evidence. User review clarified that the perceived lag was limited to that sampled video. The flat SwiftUI substitute was rejected, and the dimensional SceneKit bowl was restored for direct unattached-device evaluation.

### Discoveries

- The existing `turn-needs-roll` fixture already exposes playable Knight, Monopoly, Year of Plenty, and Road Builder cards while keeping a newly bought Victory Point card non-actionable.
- The existing DEBUG `physicalProps` style can host the comparison without a second fixture or harness.
- The initial chooser exposed a newly bought Victory Point card. The pre-roll comparison now applies the existing executable-only presentation filter so held/new inventory remains in Hand rather than appearing as a disabled action.
- The first comparison still read as ordinary controls below the board. The correction mounts a dark modal veil at the outer shell, enlarges and centers the physical Dev and dice props, hides the underlying table from interaction/accessibility, and keeps the Dev chooser inside the same ritual layer.
- The follow-up correction renames the ritual heading to `Your Turn`, deepens the veil from 72% to 82%, and replaces the loose dice pair with a code-native wooden dice tray. The tray rocks while the existing independently rotating 3D dice tumble inside; tap-to-skip and Reduce Motion publication remain unchanged.
- The tray comparison was rejected as insufficiently three-dimensional. The current checkpoint restores loose dice on the choice surface, obtains the deterministic Core-owned result, then mounts a full-screen SceneKit bowl before publishing that same result. Two beveled six-faced dice use rigid-body collisions and angular impulses before a controlled settle onto the exact Core result; the animation never chooses randomness. Tap settles immediately, Reduce Motion crossfades to the result, and the bowl unmounts before the post-roll screen resumes.
- The first SceneKit material pass read as a separate realistic/cool visual system. The corrected checkpoint uses an orthographic camera, the tabletop cream/brown/felt palette, flat dark-brown pips, authored brown edge keylines, flatter warm light, and a shallower outlined wooden bowl. The roll is now previewed through a pure Core apply, mounted, and published on the next main-actor turn so the shell transition cannot erase the in-flight decoration; the published result must equal the preview or the overlay dismisses.
- The first settled result dismissed itself after a short delay and used `Tap to settle` during motion. The revised state machine sustains visible motion longer, offers only skip while rolling, and requires explicit continuation after the deterministic result is displayed.
- The direct video exposed a cold-render defect: `Rolling` remained visible while the SceneKit surface was absent, then the settled bowl appeared without readable travel. The overlay now waits for the SceneKit choreography to report completion instead of running an independent wall-clock sleep, so cold shader/view startup cannot consume the animation.
- The authored choreography itself was not the source of the follow-up lag. Each die previously assembled 21 pip cylinders and 12 edge cylinders, producing roughly 66 die subnodes in addition to a high-segment bowl. The correction renders each die as one chamfered box with cached six-face tabletop textures, reduces bowl tessellation and antialiasing, warms the SceneKit surface behind the choice state, renders the active roll at 30 fps, and stops rendering after settle. The approved path, timing, Core-owned result, tap behavior, and visual palette remain unchanged.
- Focused XCUITest frame sequences proved that the optimized SceneKit surface still remained blank for several captured frames after `Rolling` appeared. SwiftUI opacity removal, direct `SCNView.alpha`, and a continuously rendered pre-mounted surface did not change that presentation delay, indicating a Messages/Metal compositing boundary rather than scene construction cost.
- The screenshot-sequence MP4 sampled the interface roughly every 0.3 seconds and repeated those samples into a nominal 30-fps file. It was valid for state ordering but invalid for judging animation smoothness. Simulator recording and XCUITest attachment are no longer accepted as performance verdicts for this checkpoint; the evaluation target is an unattached build on physical hardware, followed by Release-on-device only if Debug remains questionable.

## Validation and Outcome

Installed DEBUG evidence:

- ready choice: `/tmp/unluckysevens-start-turn-choice-final-retry.png`
- executable-only Dev chooser: `/tmp/unluckysevens-start-turn-dev-chooser-final.png`
- roll motion source: `/tmp/unluckysevens-start-turn-roll-full.mp4`
- correction-round ready choice: `/tmp/unluckysevens-start-turn-rpg-installed.png`
- correction-round Dev chooser: `/tmp/unluckysevens-start-turn-rpg-dev-chooser.png`
- darker `Your Turn` choice with dice tray: `/tmp/unluckysevens-your-turn-dice-tray.png`
- full-screen 3D bowl result: `/tmp/unluckysevens-dice-bowl-v5-attachments/94DA1135-1736-4F58-B297-16D56E37664F.png`
- tabletop-styled 3D bowl result: `/tmp/unluckysevens-dice-stylized-final-attachments/D5D8A5D4-E942-48EB-88B8-2A98D3BB7A9B.png`
- authored first-frame roll comparison: `/tmp/unluckysevens-dice-roll-authored-comparison.mp4`
- optimized settled bowl: `/tmp/unluckysevens-dice-roll-optimized-final.png`
- optimized short roll capture: `/tmp/unluckysevens-dice-roll-optimized-short.mp4`
- immediate SwiftUI roll frame sequence: `/private/tmp/UnluckyDiceFrameCaptureV10.xcresult`
- rejected sampled chooser-to-result MP4: `/private/tmp/unlucky-sevens-dice-roll-v11.mp4` (state-order evidence only; not performance evidence)
- restored unattached iPhone Debug build: `/private/tmp/UnluckySevensDeviceDebug/Build/Products/Debug-iphoneos/UnluckySevensApp.app`

`bash ./scripts/gen.sh`, the focused generic-simulator `MessagesExtension` build, and a signed Debug build for the paired iPhone 16 Pro passed after restoring the dimensional SceneKit renderer. The unattached Debug app was installed directly through `devicectl`; no debugger or XCUITest is attached. STR-004 remains pending on direct device review of perceived smoothness, skip/continue behavior, and absence of automatic dismissal. Pending user approval; the completion gate remains intentionally blocked while STR-002, STR-004, and STR-005 are pending.
