# Turn Screen Visual Direction

## Purpose and Outcome

Approve the core visual and interaction metaphor for the active player’s normal post-roll Turn Screen before investing in another production implementation pass. The desired direction is a physical turn surface where available game objects expose executable actions, but the exact composition must be judged from a small honest comparison rather than inferred from prose or from the current production baseline.

Parent: [Phase 14](phase-14-ui-design-bubble-polish-and-trust-surfaces.md).

## Execution Settings

- Validation profile: `standard`
- Delivery posture: `checkpointed`
- Rationale: This is ambiguous, high-judgment UI work with competing viable compositions. It needs user visual approval before productionization, while its eventual implementation and final verification remain standard-risk UI work.

## Context and Boundaries

- Scope is only the local active actor’s normal post-roll turn surface.
- Start-of-turn roll/dev, out-of-turn, forced-flow, lobby, settings, transcript, and game-over surfaces are out of scope.
- Core/query and presentation outputs remain the source of action legality and inventory. The comparison must not invent rules in UI code.
- Use real reusable components and fixture data in a DEBUG-only comparison path. Mocked rectangles or prose-only wireframes are not honest proof.
- The current production screenshot is a rejected baseline. It does not count as a comparison round, is not an approved direction, and must not be stored in Git.
- Ordinary screenshots and result bundles stay outside Git; the plan records concise textual verdicts only.

## Milestones / Plan of Work

1. Build the smallest DEBUG-only comparison that can render the three representative states below without productionizing nested routes.
2. Capture one concise round, present the three states together, and ask the user for directional feedback.
3. Apply one focused correction round if needed and present the same three-state set again.
4. Stop if the second round is not approved. Record the unresolved decision and ask the user how to proceed; do not add more autonomous rounds.
5. After explicit approval, record the approved boundary as a dated decision, update the judgment constraint, and continue automatically into production implementation.
6. Productionize the approved composition and nested states, run focused behavior/accessibility evidence, request one final product/UX review, and run the completion gate once.

Representative proof in every comparison round:

- Default Hand
- Build spread
- Revealed Bank

No round may exceed these three states unless the user explicitly changes the gate. On 2026-07-12 the user explicitly requested a focused Round 3 adding the nested Dev chooser as a fourth proof state.

### Round 1 Physical-Props Notes

- Phone zone targets are 48 points for the top rail, 68 for the public rail, 128 for the action spread, and 72 for the prop rail; the board receives the remaining reclaimed height and keeps one frame across all three states.
- The top rail is printed directly on felt with a 24-point gear, two-line status, and player-group icon inside invisible 44-point controls.
- Bank and `Development Deck` use the same 38-by-47-point portrait card geometry. Bank reveal fades its cards and overlays counts in place without replacing Hand; the public deck always overlays its remaining count and remains the sole Buy Dev affordance.
- Bottom anchors use loose code-native props with subordinate labels: splayed Hand cards, the canonical Settlement, an authored merchant ship, two face-up portrait Dev cards, and an authored turn flag. Selection is lift, tight shadow, and a thin keyline rather than a button tile or checkmark.
- The shallow action spread contains real inventory cards for Hand or canonical Road, Settlement, and City pieces for Build. Build costs render existing resource stamps followed by Core-owned numbers; no panel header, instruction paragraph, or large Cancel control appears.
- Road, Settlement, and City share normalized Core Graphics paths with SpriteKit. Cards, ship, and flag are deterministic SwiftUI/Core Graphics components; generated raster art and fake 3D assets are prohibited.
- Round 1 adds a DEBUG-only `physicalProps` comparison style. Production remains on the rejected baseline until user approval.

### Round 13 Responsive Reflow Plan

1. Introduce a pure `GamePhysicalTurnLayout` resolver. It accepts the shell size, shell frame in global coordinates, and active display bounds, then returns clamped top/public/action/prop zone heights, the public-to-board gap, board insets, and the translation needed to place the renderer's canonical island center on the display midpoint. Remove `boardDeviceCenterOffset` as a layout input.
2. Recompose the public rail and bottom object rail around explicit optical stages. Every name tile sits below its object with a shared `3–4pt` gap and no negative spacing or overlap. Move the public group down slightly while increasing its separation from the board; move Hand and the object rail down while retaining 44-point invisible hit regions.
3. Return the reclaimed lower-zone height to the live board and increase its horizontal presentation by about two percent. Keep one `BoardContainerView` identity, preserve SpriteKit camera/target ownership, and assert that the island and ports remain unclipped.
4. Add pure resolver tests for a compact and a tall supported phone host. Assert clamp bounds, minimum board space, fixed rail order, and canonical-island midpoint tolerance of one display pixel. Extend layout assertions so route changes still preserve the resolved board/public/action/prop frames.
5. Build and explicitly reinstall the containing app before capture to avoid the known Messages extension cache. Capture exactly three Round 13 proofs: compact-phone Default Hand, tall-phone Default Hand, and tall-phone Build spread. Present them together and stop for user review; Bank reveal requires no extra still because it does not alter the public-rail geometry.

Round 13 remains DEBUG-only and checkpointed. No nested-state productionization, specialist review, or completion gate runs before visual approval.

### Round 14 Optical Alignment Plan

1. Preserve the renderer-owned canonical island at the full-display midpoint while moving only the decorative board host slightly lower inside its existing reserved zone.
2. Normalize Hand, Settlement, Ship, and Flag against one visible optical band. The authored topmost and bottommost visible pixels—not their unequal transparent SwiftUI or SVG bounds—must share the same two horizontal guides.
3. Keep every wooden label below that band with a visible felt gap. In particular, the rotated Hand cards may not escape their optical stage or touch the Hand tile.
4. Capture tall-phone Default Hand and Build plus one compact-phone Default Hand check. Stop for user review; production routing and nested-state scope remain unchanged.

### Round 15 Public Group and Board-Felt Plan

1. Treat Bank and Dev Cards as one centered public-information group with a fixed 28-point inter-object gap rather than opposite-edge anchors.
2. Match the lower rail's visible separation by increasing each public pile's artwork-to-name-tile gap to eight points; the public rail frame and board geometry remain stable.
3. Reveal more green felt at the board sides by masking the decorative teal surface inward responsively. Preserve the existing live board host width, island scale, target coordinates, identity, and full-display vertical centering.
4. Move only the wooden foot of the End flag slightly right; its pole, flag, hit region, label, and optical top/bottom guides stay fixed.

### Round 16 Bank-Stack Microspacing

1. Preserve the centered 316-point lower rail with four equal fixed anchors; the labels remain centered per anchor and the existing prop-only offsets continue to compensate for unequal visible artwork bounds.
2. Increase only the five Bank card sibling gaps from one to two points. Do not alter public-group centering, Bank/Dev separation, card size, label placement, hit regions, or board geometry.

### Round 17 Board-Token and City Silhouette Correction

1. Reduce the shared number-token fill opacity enough for the underlying terrain stamp to remain visible while preserving the existing dark or red numeral contrast and token outline.
2. Replace the incorrect two-roof City with the physical-piece silhouette: one tall peaked tower on the left and one low rectangular wing extending right.
3. Keep City geometry shared between SpriteKit board pieces and SwiftUI Build props, then capture the Build comparison for user review without productionizing nested states.

### Rounds 18–19 Status and Depth Corrections

1. Replace the redundant `YOU` capsule and numeric dice with two conventional pip dice plus the roll total.
2. Use solid player-color structure fills, thinner/shorter roads, and moderately larger settlements/cities across board and Build props.
3. Flatten the ocean into one rounded teal field, extend only its lower edge slightly, and remove inset/perimeter treatments or host-color seams that imply a thick slab.

## Approval Gate

Authority: user.

Approval question: does this comparison establish the intended post-roll physical turn-surface metaphor strongly enough to productionize its nested states?

While approval is pending:

- stop after each three-state comparison for user feedback;
- do not productionize nested Turn Screen states;
- do not launch automatic fresh reviewers;
- do not run the completion gate;
- allow product/UX critique only when the user asks for advisory input;
- allow another reviewer to approve only when the user explicitly delegates that authority.

Round budget:

- Round 1: produced 2026-07-12; pending user verdict
- Round 2: produced 2026-07-12; pending user verdict
- Round 3: produced 2026-07-12; pending user verdict
- Round 4: produced 2026-07-12; pending user verdict
- Round 5: requested 2026-07-13; replaces the Dev and Trade marks with user-supplied vectors and unifies level styling
- Round 6: isolated SVG candidates requested 2026-07-13; no app integration until the centered/heavier factory and multi-material ship receive visual approval
- Round 7: requested 2026-07-13; optically equalize the Bank-to-board and board-to-Hand gaps while making only the Hand spread cards marginally larger
- Round 8: requested 2026-07-13; normalize bottom props to one contact baseline and apply one restrained physical-grounding/caption treatment across public and action rails
- Round 9: requested 2026-07-13; remove embossed overlay shadows, artificial prop-ground ellipses, and persistent rail captions after direct inspection showed they retained pasted-on toolbar grammar
- Round 10: requested 2026-07-13; restore required visible labels as small physical wooden name tiles attached to their props rather than floating UI captions
- Round 11: requested 2026-07-13; correct name-tile attachment geometry without adding a reviewer pass or broadening validation
- Round 12: requested 2026-07-13; move public labels below their piles, enlarge the board around the full-screen center, and compress/lower the Hand and action zones
- Round 13: requested 2026-07-13; separate labels from props, lower both lower rails, enlarge the board again, and replace the one-device centering constant with clamped responsive layout math
- Round 14: requested 2026-07-14; lower the decorative board frame without moving the globally centered island, then align every bottom prop by its actual visible top and bottom bounds with labels safely below
- Round 15: requested 2026-07-14; tighten the Bank/Dev group, increase their label clearance, narrow only the visible teal board frame, and shift the flag foot right
- Round 16: requested 2026-07-14; confirm the centered Hand-through-End anchor track and add a restrained two-point gap between Bank resource stacks
- Round 20: requested 2026-07-14; remove the ocean thread overlay and replace textual port badges with physical micro-markers
- Round 21: requested 2026-07-14; reuse the approved Hand Trade ship for generic ports and pull every port closer to the coast with shorter, quieter pier lines
- Round 22: requested 2026-07-14; test one subtle island-centered ocean falloff without restoring texture, waves, strokes, or dimensional frame edges
- Round 23: requested 2026-07-14; replace the imperceptible single pass with a DEBUG-only three-style gradient comparison using the same live board
- Round 24: requested 2026-07-14; lock the selected shoreline halo direction and strengthen the physical hierarchy with thinner roads and larger settlements/cities
- Round 25: requested 2026-07-14; test a thicker, darker same-player-color edge on live board pieces instead of a neutral highlight
- Round 26: requested 2026-07-14; compare terrain-derived resource ink and a restrained inner terrain edge after checkpoint commit `867d04d`
- Round 27: requested 2026-07-14; interpret the reference literally by removing cream interior seams and recoloring the saved resource-stamp assets themselves
- Round 28: requested 2026-07-14; restore the full cream grid while retaining the authored colored resource stamps
- Round 29: requested 2026-07-14; extend terrain-derived ink and edges to Bank, Hand, resource ports, and Dev Cards, and close coastal frame joints
- Round 30: requested 2026-07-14; test small colored Build-cost pips and improve minified port-resource artwork
- Round 31: requested 2026-07-14; replace blurry small-context PNGs with dedicated simplified resource SVGs
- Round 32: requested 2026-07-15; revert the rejected mini SVGs and purpose-render the approved PNG illustrations at final small-context scales
- Round 33: requested 2026-07-15; compare every unique normal-turn top-rail instruction in the exact physical-props header geometry before wiring state transitions
- Rejected production baseline: excluded from the budget

## Verification Contract and Fresh Review

<!-- verification-contract:start -->
| ID | Class | Source | Acceptance | Verification | Evidence | Status | Rationale |
| --- | --- | --- | --- | --- | --- | --- | --- |
| TS-001 | observable | user plan | Each comparison round shows Default Hand, Build spread, and revealed Bank using real components and fixture data | DEBUG comparison capture and artifact inspection | report:Round 1 and Round 2 direct simulator stills in ignored `docs/design/workbench/physical-props-round{1,2}-{hand,build,bank}.png` | pass | Both rounds use the existing `turn-after-roll` fixture and real code-native components |
| TS-002 | judgment | user plan | User explicitly approves the post-roll physical turn-surface metaphor before nested productionization | user verdict recorded as a dated decision | report:2026-07-15-user-approved-physical-props-turn-screen | pass | User said “Perfect! Okay I think I'm good with this screen!!” after reviewing the final prompt keyline |
| TS-003 | mechanical | architecture and product owners | Available objects and choices derive from Core/query and presentation outputs rather than duplicated UI rules | focused tests and code inspection after implementation | command:52-focused-MessagesExtension-tests-passed-2026-07-15; report:Core-query-and-presentation-ownership-inspection | pass | Screen models, action dock, trade panel, Bank, and prompt presentation remain derived from existing Core/query outputs |
| TS-004 | observable | UI flows and Design | Approved nested states preserve board dominance, stable geometry, clear object ownership, accessibility, and legal interaction behavior | focused UX Lab/XCUITest journey plus direct still inspection | command:turn-gameplay-XCUITest-passed-after-two-card-dev-entry-2026-07-15; report:/tmp/unluckysevens-turn-two-card-dev-entry-retry.png-and-/tmp/unluckysevens-turn-dev-inventory-open.png-inspected | pass | The installed journey exercised every nested route, stable frames, board-host identity, 44-point actions, Bank secrecy, the two-card Hand entry, its complete opened owned-Dev inventory, and public-deck purchase |
| TS-005 | judgment | user-approved comparison | Production result faithfully implements the approved composition | final user evidence check and final product/UX review | report:2026-07-15-user-approved-physical-props-turn-screen-and-final-production-still | pass | Production uses the approved physical-props composition and the settled simulator still matches the accepted direction |
| TS-006 | observable | Round 13 user direction | Physical rails preserve their hierarchy on both compact and tall supported phone hosts: labels sit below props, public objects retain breathing room above the board, and the canonical island—not its container—is centered on the full display | pure layout tests plus installed captures on two phone heights | report:Round 13 tall Default, compact Default, and tall Build captures | pass | Tall island midpoint is exactly `1311px`; compact midpoint is within `0.5px` of `1266px`; both retain unclipped public/action rails |
<!-- verification-contract:end -->

<!-- fresh-review:start -->
| Reviewer | Required | Verdict | Evidence |
| --- | --- | --- | --- |
| constraint-auditor | yes | pass | report:2026-07-15-fresh-audit-and-owned-dev-fix-rereview-inspected-plan-owner-docs-diff-code-tests-xcresults-and-still |
| architecture | no | not-applicable | Trigger only if implementation changes ownership or dependency direction |
| behavioral | no | not-applicable | Trigger only if implementation changes behavior beyond the approved presentation contract |
| product-ux | yes | pass | report:2026-07-15-final-product-ux-review-inspected-owner-docs-code-tests-and-settled-still-no-blocking-findings |
<!-- fresh-review:end -->

## Living Record

### Progress

- [x] Rejected production screenshot classified as baseline rather than approval evidence.
- [x] Three representative states and two-round budget locked.
- [x] Round 1 physical-props composition, dimensions, card orientation, prop vocabulary, and implementation material locked.
- [x] Round 1 DEBUG comparison produced.
- [ ] Round 1 reviewed by the user.
- [x] Round 2 correction set produced.
- [ ] Round 2 reviewed and direction approved or explicitly left unresolved.
- [x] Round 3 public Dev Card and nested-Hand correction produced.
- [ ] Round 3 reviewed and direction approved or explicitly left unresolved.
- [x] Round 4 qualitative public-pile correction produced.
- [ ] Round 4 reviewed and direction approved or explicitly left unresolved.
- [ ] Round 5 vector-prop and unified-reveal correction reviewed and direction approved or explicitly left unresolved.
- [x] Round 6 isolated factory/ship SVG candidates reviewed before integration.
- [ ] Round 7 spacing and Hand-card scale correction reviewed.
- [ ] Round 8 prop alignment and physical-grounding correction reviewed.
- [ ] Round 9 stripped physical-object treatment reviewed.
- [ ] Round 10 tabletop name-tile treatment reviewed.
- [ ] Round 11 name-tile positioning reviewed.
- [ ] Round 12 full-screen board and rail reflow reviewed.
- [x] Round 13 responsive spacing and board-scale correction implemented and captured.
- [ ] Round 13 reviewed by the user.
- [x] Round 14 visible-bounds alignment implemented and captured.
- [ ] Round 14 reviewed by the user.
- [x] Round 15 public-group, safe board-mask, and flag-foot correction implemented and captured.
- [ ] Round 15 reviewed by the user.
- [x] Round 16 Bank-stack microspacing implemented and captured.
- [ ] Round 16 reviewed by the user.
- [x] Round 17 translucent board-token and canonical City corrections implemented and captured.
- [ ] Round 17 reviewed by the user.
- [x] Round 18 pip-dice and solid-structure correction implemented and captured.
- [x] Round 19 piece-scale and flat-ocean correction implemented and captured.
- [ ] Round 19 reviewed by the user.
- [x] Round 20 clean-ocean and physical-port comparison implemented and captured.
- [ ] Round 20 reviewed by the user.
- [x] Round 21 shared-ship and offshore-harbor comparison implemented and captured.
- [ ] Round 21 reviewed by the user.
- [x] Round 22 tonal-ocean comparison implemented and captured.
- [ ] Round 22 reviewed by the user.
- [x] Round 23 three-style ocean comparison implemented and captured.
- [x] Round 23 ocean direction reviewed; shoreline halo selected by the user.
- [x] Round 24 selected-ocean and piece-scale correction implemented and captured.
- [ ] Round 24 piece-scale correction reviewed by the user.
- [x] Round 25 molded-color piece edge implemented and captured.
- [x] Round 25 molded-color piece edge reviewed by the user.
- [x] Round 26 terrain-ink and inset-edge comparison implemented and captured.
- [ ] Round 26 terrain-ink and inset-edge comparison reviewed by the user.
- [x] Round 27 coastline-only cream frame and colored-stamp comparison implemented and captured.
- [x] Round 27 coastline-only cream frame and colored-stamp comparison reviewed and rejected by the user.
- [x] Round 28 restored full cream grid with colored resource stamps captured.
- [ ] Round 28 restored full cream grid with colored resource stamps reviewed by the user.
- [x] Round 29 cross-surface colored-ink treatment and closed coastal joints implemented and captured.
- [ ] Round 29 cross-surface colored-ink treatment and closed coastal joints reviewed by the user.
- [x] Round 30 Build cost pips and minified resource-port artwork implemented and captured.
- [ ] Round 30 Build cost pips and minified resource-port artwork reviewed by the user.
- [x] Round 31 dedicated mini resource SVGs implemented and captured.
- [x] Round 31 dedicated mini resource SVGs reviewed and rejected by the user.
- [x] Round 32 purpose-rendered mini PNGs implemented and captured.
- [x] Round 32 purpose-rendered mini PNGs reviewed by the user.
- [x] Round 33 contextual top-rail prompt vocabulary rendered as an exact-component contact sheet.
- [x] Round 33 contextual top-rail prompt vocabulary reviewed by the user.
- [x] Approved direction productionized and focused verification passed.

### Decisions

- 2026-07-11: User approval is the default authority for this visual gate. Advisory product/UX input does not substitute for it.
- 2026-07-11: Comparison work is limited to three representative states and two rounds before a mandatory pause.
- 2026-07-11: High-capability reasoning is reserved for ambiguous judgment and final independent review. Locked mechanical implementation should use the cheapest capable executor; deterministic capture/build/test work should not use an agent when tools suffice.
- 2026-07-12: Bank reveal is an independent in-place public-information toggle; `Development Deck` is the public pile name and shares exact portrait geometry with Bank cards.
- 2026-07-12: Round 1 uses canonical/shared vector geometry and real production stamps. The generated composition mockup is directional only and remains outside Git.
- 2026-07-12: Round 2 is the final autonomous comparison round. It compresses the top/public/action/prop zones to 40/52/98/64 points, replaces the textual turn header with a player puck and dice, removes the Build arrow and Hand-side Dev faces, optically aligns the bottom props, neutralizes typography, and replaces the City with a tower-plus-gabled-house silhouette shared by SpriteKit and SwiftUI.
- 2026-07-12: User reopened the gate for one requested correction: rename the public pile `Dev Cards`, replace its star with a chimney-and-smoke outline, conceal its count until Bank reveal, nest owned Dev Cards and their chooser inside Hand, and remove the standalone Dev rail prop.
- 2026-07-12: Round 3 uses four bottom anchors (`Hand · Build · Trade · End`). Hand shows a nested owned-card stack; its playable chooser uses compact `Knight · Monopoly · Plenty · Roads` labels while retaining full accessibility names.
- 2026-07-12: Round 4 replaces exact revealed public counts with qualitative `H/M/L` levels. Levels use thirds of the standard pile capacity; the public Dev chimney is black while concealed, fades beneath a white level letter when Bank is revealed, and exact public counts remain absent from visible and accessibility output.
- 2026-07-13: Public and owned Dev Cards adopt a smoky-indigo fill (`#66708D`), slate edge (`#919AB3`), near-black face marks, and warm-white revealed lettering so the family is distinct from the teal board and five resource colors.
- 2026-07-13: The smoky-indigo pass was rejected as too purple. Round 5 uses a desaturated blue-gray card family, the user-supplied Noun Project factory and ship vectors, and one bold warm-white H/M/L treatment across all six public piles. Source attribution is retained in `docs/design/tabletop-prop-attribution.md`.
- 2026-07-13: Round 6 pauses app integration. Its workbench factory preserves the supplied geometry, corrects the optical viewport, removes the blur-producing morphology filter, and compares native source strokes at final output density.
- 2026-07-13: The coordinate-guided ship approximations were rejected. The replacement candidate extracts the untouched source compound path's own closed negative-space subpaths for every sail, flag, deck, rail, cap, and hull fill, then renders the original black artwork over them. Color therefore cannot cross or invent a boundary; the forward white flag is the exact enclosed bow region from the downloaded source.
- 2026-07-13: The selected factory comparison uses a modest native outline stroke and direct high-density vector rendering. It remains isolated in the ignored workbench with the exact-region ship pending user approval; neither candidate has been integrated into the app asset catalog.
- 2026-07-13: The user approved the exact-region ship and balanced-stroke factory candidates for integration. Integration remains paused only for selection of the Dev Cards back color; four non-purple workbench directions compare the concealed black factory and revealed warm-white level treatment.
- 2026-07-13: The user selected Harbor Blue and requested more vibrancy. The integration candidate raises chroma to `#3B7D97` with a lighter `#79ABBC` edge, preserving the black concealed factory and warm-white revealed level treatment.
- 2026-07-13: Ship review identified three enclosed negative-space compartments above the hull that had been semantically misclassified as wood. The corrected candidate leaves those rigging/sail gaps felt-colored and applies brown only to the exact hull and stern-cap regions.
- 2026-07-13: User approved the corrected ship and vibrant Harbor Blue card family and explicitly requested integration. The approved factory and ship SVGs are promoted into the vector-preserving asset catalog; the ship uses original rendering to preserve its multi-material fills while selection retains a separate template keyline.
- 2026-07-13: Direct simulator inspection found that the shared reveal desaturation erased most of Harbor Blue and that the existing ship asset name still resolved through its prior template treatment. The Dev Cards reveal now fades only the factory mark while retaining the blue card material, and the approved multi-material ship uses a new original-rendering asset identity to prevent stale template semantics.
- 2026-07-13: Round 7 preserves the already device-centered board frame and corrects the perceived imbalance around it: the Hand spread aligns near the top of its reserved well so its distance from the board approaches the Bank-to-board distance. Resource Hand cards increase from `38×47` to `42×52`; public Bank and Dev Cards remain `38×47`, so their shared public geometry does not drift.
- 2026-07-13: Screenshot measurement corrected the Round 7 centering assumption: the board was horizontally centered but approximately `9.5pt` above the full-device vertical center. The final measured correction lowers the unchanged board frame by `8pt`, enlarges owned Hand cards to `46×57`, and centers the Hand spread in the felt between the board and bottom object rail rather than matching the compact Bank-to-board gap.
- 2026-07-13: Round 8 uses one 36-point optical stage and 32-point perceived prop height for every bottom object. Natural widths remain distinct; calibrated offsets account only for transparent vector bounds so the visible card feet, settlement base, ship hull, and flag base share one contact line. Tight contact shadows, restrained card edge highlights, and smaller bold secondary felt captions ground both rails without introducing button tiles, plaques, or containers.
- 2026-07-13: Round 9 rejects the extra grounding treatment after simulator inspection. Numeric and qualitative overlays use flat ink with no text shadow; bottom props retain only their intrinsic tight material shadow, not an added oval ground mark. Persistent visible captions are removed from both rails so the objects carry the composition, while stable accessibility labels, hints, selected traits, fixed anchors, and 44-point hit regions remain unchanged.
- 2026-07-13: User clarified that visible labels remain required. Round 10 restores them as compact dark-stained wooden name tiles with flat warm ink and a defined material edge. Bottom props overlap their tiles by three points so icon and label read as one tabletop assembly; Bank and Dev Cards use the same tile material beside their piles. Tiles do not enclose the prop and do not become a second interactive target.
- 2026-07-13: Round 11 direct screenshot measurement found that transparent source bounds prevented the intended overlap even though the shared SwiftUI stages aligned. Labels keep one baseline; Hand, Settlement, Ship, and Flag receive calibrated downward attachment offsets so their visible bases overlap the tile edge consistently. Public labels bottom-align with and tuck three points beneath their associated card piles instead of floating at the piles' vertical center.
- 2026-07-13: Round 12 places Bank and Dev Cards tiles centered below their respective piles and keeps both groups within the board's horizontal footprint. The action well shrinks from `98pt` to `82pt`, returning `16pt` to the live board while moving the Hand downward. The board expands six points per horizontal edge without remounting its renderer. Pixel measurement of the canonical island—not the Messages sheet, public labels, or blue frame—placed its midpoint `20px` (`6.67pt` at the simulator's 3× scale) above the full-device midpoint in the first settled still; the calibrated visual offset is therefore `2.67pt`. Public stacks use two points of vertical spacing above their labels, leaving a clean contact instead of covering the tiles. Physical action assemblies use four-point bottom clearance, moving them eight points lower and tightening their gap to the Hand.
- 2026-07-13: Round 13 treats the `2.67pt` offset as temporary single-host calibration, not a responsive contract. Replace the fixed physical-zone heights with a compact resolver driven by available host height and bounded by legibility/touch-safe clamps. The board receives the resolved remainder. Derive the board translation from the shell's global frame, the active display midpoint supplied at the shell/root boundary, and the renderer's canonical island-center ratio; do not calibrate a second per-device constant.
- 2026-07-13: Round 13 visual targets are deliberately small: labels sit `3–4pt` below their public/action props with no overlap; the public group moves down about `4pt` while its board gap grows by `3–4pt`; Hand and the action rail move down about `8–12pt`; reclaimed lower-zone height and a restrained horizontal expansion grow the board roughly `2%`. Existing 44-point invisible hit regions, fixed action anchors, board identity, target ownership, and Reduce Motion behavior do not change.
- 2026-07-13: Round 13 resolves physical-zone heights from host size with bounded phone clamps, keeps portrait cards and touch regions fixed for legibility, and gives the live board all remaining height. The board frame receives a four-point vertical inset for public-rail breathing room while the SpriteKit content receives a measured translation that centers the canonical island against the full display. Display height derives from the shell's global maximum plus the bottom safe-area inset; no `UIScreen.main` or per-device offset remains.
- 2026-07-14: Round 14 separates decorative-frame placement from canonical-island placement. A small frame-only translation consumes the existing bottom inset, while the measured SpriteKit translation continues to center the island. Bottom actions are judged against a shared visible-pixel band; unequal transparent asset bounds are implementation details and cannot define alignment.
- 2026-07-14: Round 15 keeps live board geometry independent from decorative surface width. The SpriteKit host retains its existing expanded width while a responsive inset mask reveals green felt at the sides, avoiding an island shrink, target-coordinate change, or remount. Bank and Dev Cards become one centered group with explicit object and label gaps.
- 2026-07-14: The first Round 15 mask used a 19-point tall-phone inset and visibly clipped the left `3:1` port. It was rejected immediately. The safe mask equals the existing responsive host overflow, returning the visible teal frame to the shell content width while leaving every canonical port and board target inside the mask.
- 2026-07-14: Round 16 retains four equal action anchors inside the centered 316-point rail. Per-prop optical offsets do not move the button frames or wooden-label centers. Bank resource cards use a two-point sibling gap—deliberately tighter than the Hand fan and far tighter than the 28-point Bank-to-Dev group gap.
- 2026-07-14: The fresh Round 16 Build still confirms the four visible prop-and-label assemblies read on the same evenly spaced anchor rhythm; the two-point Bank gaps remain legible without turning the public rack into five unrelated buttons. The installed focused XCUITest passed and the direct simulator still is the judgment artifact.
- 2026-07-14: Round 17 reduces the shared cream number-token fill from `0.98` to `0.82` alpha while leaving numeral opacity unchanged. The canonical City now follows the supplied physical-piece reference: one tall peaked tower at left and a low flat wing at right. The same shared path renders both SpriteKit structures and the SwiftUI Build prop.
- 2026-07-14: The supplied close-up resolves the City construction more precisely than the prior L-shaped approximation: a settlement silhouette occupies the left half of a wide base rectangle, and its height matches the rectangle height. The shared path now encodes those proportions directly for both renderers.
- 2026-07-14: The side-by-side physical reference confirms City is larger than Settlement without doubling it. City uses a shared `1.22×` structure scale: its visible bounds are about `1.57×` as wide and `1.11×` as tall as Settlement, while its upper settlement portion remains about `78%` of the standalone Settlement width.
- 2026-07-14: Because the larger City shares the same centered 38-point Build prop stage, its symmetric bounds plus stroke and shadow placed its visible foot about `3pt` below Settlement. A City-only optical lift aligns the two visible bases without moving their stages, labels, costs, anchors, or hit regions.
- 2026-07-14: Structure pieces now use one solid player-color fill in both SwiftUI props and the SpriteKit board; the lighter decorative cap is removed. The compact top status removes the redundant `YOU` capsule and renders the two rolled values as conventional pip dice while retaining the total and the existing combined accessibility label.
- 2026-07-14: The next depth pass thins board roads from `0.18r` to `0.15r`, reduces their offset shadow, shortens and thins the Build Road prop, and enlarges structures by roughly `10–12%` across board and prop renderers. The ocean becomes one flat rounded water field without the inset translucent base or dark perimeter stroke. Reclaiming four tall-phone action-well points extends only the board's lower edge; the top rail and public-to-board spacing remain fixed.
- 2026-07-14: The first flat-ocean still revealed that the remaining dark lower strip was not a SwiftUI shadow; it was the darker opaque SpriteKit host background exposed beneath the rounded water node. The host and scene background now share the water teal, eliminating false slab thickness while the outer SwiftUI mask preserves rounded corners.
- 2026-07-14: Round 20 removes the repeated diagonal cloth-thread overlay entirely; at phone scale it reads as accidental scratches rather than felt or water. Generic `3:1` ports become tiny authored wood-and-cream ships. Specialized `2:1` ports become compact resource-colored cargo markers using the existing production stamps. Thin low-contrast pier lines retain their relationship to the coastal edge, while exact trade ratios remain in the Core-owned port kind and semantic/debug presentation rather than competing as microtext on the board.
- 2026-07-14: Round 21 rejects the separate simplified port-ship drawing. Generic ports reuse the exact `merchant_ship_colored` asset already used by the Trade prop, rendered upright to preserve recognition at micro scale. Port anchors move only modestly from `0.54×` to `0.48×` the coastal-edge length so the objects still float visibly offshore while gaining safe frame clearance; pier width drops from `0.045r` to `0.03r` and opacity from `0.54` to `0.42`. This creates one shared ship vocabulary without changing port ownership or trade semantics.
- 2026-07-14: Round 22 keeps the ocean as one rounded SpriteKit shape and gives only that fill a low-amplitude radial value shift: slightly lighter at the island and roughly four percent deeper at the perimeter. The scene background matches the perimeter tone so rounded corners cannot expose a false edge. No texture node, wave motif, border, extra compositing layer, camera change, or target-geometry change is introduced.
- 2026-07-14: The user correctly judged Round 22 too subtle to compare. Round 23 adds three deliberately differentiated DEBUG UX Lab choices while keeping Release on the flat-ocean baseline: `Glow` uses an island-centered shallow-water radial field, `Depth` uses a top-to-bottom value shift, and `Halo` uses a brighter coastal band followed by deep water. The initial `Edge` candidate was discarded because it read as only a stronger `Glow`. SpriteKit accepted the first fragment shaders but simulator evidence showed the shape falling back to its flat fill; Round 23 therefore uses cached Core Graphics gradient textures on the existing single rounded water shape. Switching styles rebuilds only the cached backdrop and does not remount the board host or change geometry.
- 2026-07-14: The user selected `Halo` as the ocean direction. Round 24 keeps that choice inside the DEBUG physical-props checkpoint until the complete Turn Screen direction is approved. Board road bodies move from `0.15r` to `0.125r` with proportionally quieter outlines, highlights, and shadows; board structures move from `0.245r` to `0.275r`. The shared Build-spread road loses roughly seventeen percent of its thickness, while settlement and city props gain roughly seven percent of path scale plus slightly wider non-interactive stages to prevent clipping. Targets, hit regions, board topology, and host geometry do not change.
- 2026-07-14: Round 25 uses the owning player's color mixed 38 percent toward black for the live board piece edge. Settlement and City outlines increase to 2.2 points so red structures remain legible on brick hexes; roads retain their thinner existing outline. The edge is a molded-material separation cue rather than a neutral halo or selection state, and does not change targets, hit regions, topology, or board-host geometry.
- 2026-07-14: The user accepted Round 25's darker molded-color player-piece edge as materially more visible. Before Round 26, create a scoped visual checkpoint commit. Round 26 will compare terrain-derived resource-stamp ink plus a restrained terrain-derived inner hex edge; it remains a DEBUG visual experiment until user review.
- 2026-07-14: Scoped visual checkpoint `867d04d` records the accepted Round 25 direction without absorbing unrelated worktree changes. Round 26's first SpriteKit color-blend pass was effectively invisible because multiplying black source pixels cannot produce chromatic ink, and its inset was largely swallowed by the shared frame. The corrected comparison bakes deterministic tinted textures from each stamp's alpha mask using terrain fill mixed 24 percent toward black. Its 90-percent-opacity inner edge uses terrain fill mixed 26 percent toward black, sits at 92.5 percent of the field radius, and uses a `0.048r` line. The warm shared frame remains the dominant divider.
- 2026-07-14: Round 27 removes the three-layer cream frame from every interior topology edge and retains it only for coastal edges. Tile-local terrain seams now own interior separation. The saved PNG stamp assets are recolored directly from their alpha masks—forest green, oxblood, olive, umber, blue-charcoal, and desert brown—so SpriteKit uses deterministic authored pixels rather than runtime tinting. A focused scene test proves the shared frame path contains only coastal edges.
- 2026-07-14: The user rejected removing the cream interior grid. Round 28 restores the full three-layer cream frame across every topology edge while retaining the authored terrain-colored resource stamp pixels from Round 27.
- 2026-07-14: Round 29 removes SwiftUI template rendering from physical resource cards and the public factory mark so authored colors survive in Bank, Hand, and the Hand prop. Resource cards and resource-port markers receive matching dark terrain edges; the factory SVG and Dev Card edge use dark Harbor Blue. The shared cream frame retains its width but moves from butt to square caps to close tiny coastal vertex gaps.
- 2026-07-14: Round 30 gives each Build cost a 16-point printed resource pip with its Core-owned number remaining outside the circle. Resource-port stamp textures enable mipmaps and grow from 68 to 82 percent of the marker box to keep narrow wheat and wood artwork legible under minification without changing port anchors or tethers.
- 2026-07-14: Round 31 replaces detailed PNG minification in ports and Build pips with a dedicated five-glyph SVG set. The small-context vectors preserve resource colors and identities with heavier simplified geometry, while board tiles, Bank cards, Hand cards, and the Hand prop retain the detailed authored PNG artwork.
- 2026-07-15: The user rejected Round 31's simplified SVG silhouettes as inconsistent with the approved illustration language. Round 32 returns to the detailed resource drawings, but pre-renders dedicated 1x, 2x, and 3x mini PNGs at the actual 16-point context with high-quality interpolation and a slight subpixel stroke-strengthening pass. Ports and Build pips continue using the mini asset names, avoiding runtime crushing of the large originals.
- 2026-07-15: The nested Dev chooser uses the full visible names `Year of Plenty` and `Road Builder`. Each longer name is authored as two compact caption rows inside the existing 82-point action well so the board and rail geometry remain fixed.
- 2026-07-15: Round 33 keeps the dice for passive Hand, Bank, Game Info, and End confirmation states, and omits Victory Point reveal because the game ends immediately. Eighteen unique action prompts render in the same fixed 48-point top rail; the production call still supplies no prompt until the comparison is approved and route-to-prompt presentation mapping is implemented.
- 2026-07-15: The user approved the final Physical Props Turn Screen, including the compact amber prompt keyline. The checkpoint gate is cleared. Normal active-player `.afterRoll` production routing may now use `.physicalProps`; prompt mapping must remain presentation-derived, while all excluded surfaces retain their existing composition.
- 2026-07-15: Production routing now selects `.physicalProps` only for the active local actor’s normal `.afterRoll` state. Installed XCUITest covers Hand, independent Bank reveal, Build and all three targets, Trade chooser/composer and pending offer, Hand-nested Dev resource/board routes, compact End confirmation, Game Information, and direct public-deck purchase without remounting the board host.
- 2026-07-15: After final validation, the user restored the earlier Hand-owned Dev interaction: the default Hand uses a compact two-card splayed entry instead of laying out every owned kind. Tapping it opens a full five-kind-capable owned inventory spread; legally playable cards keep amber action keylines while held/new cards remain visible and inert. The entry retains a complete VoiceOver inventory summary, so the visual simplification does not hide owned-card state from accessibility.

### Discoveries

- The earlier loop spent production implementation, repeated builds, and four reviews before the core metaphor was visually approved. This child reverses that order.
- The installed three-state XCUITest passed and retained all three attachments, but the Messages host composited black rectangles in the Hand and Bank attachments. Per the existing runbook, dedicated settled-state tests plus direct `simctl` capture produced clean judgment stills without changing the product UI.
- Messages may retain an older installed extension bundle even after a focused test compiles fresh source. Trustworthy asset review required explicitly installing the newly built containing app before the settled-state capture; the installed bundle was then verified to contain the new `merchant_ship_colored` asset identity.
- Round 12 exposed the same host cache for layout constants: two captures had byte-identical board crops until the rebuilt containing app was explicitly installed. The post-install still measures the canonical island midpoint and the `1206×2622` device midpoint at exactly `y = 1311px`.
- The first Round 13 global-position estimate moved the board frame over the public labels. DEBUG coordinate evidence showed that the extension's global geometry is already expressed in display coordinates and that the authored island midpoint is at `49.4%` of the board host. Keeping the frame in normal flow and translating only SpriteKit content satisfies both the full-display center and the public-label gap without remounting the board.
- Running compact and tall simulators concurrently caused one UI-test runner kill; serial device validation passed. One tall still hit the known SpriteKit black-layer compositor artifact and was discarded; the immediate settled retry was clean.
- Round 14 confirmed that equal SwiftUI frames do not imply equal visible prop bounds. A direct 3× screenshot crop exposed each authored silhouette's real top and bottom pixels; Hand, Settlement, Ship, and Flag were then normalized to the Ship reference band. The same capture also proved that offsetting the board view before an outer centered frame is neutralized; asymmetric top/bottom reservation moves the decorative frame by four points while preserving independent renderer centering.
- Round 15's first capture validated the public-group rhythm but rejected the aggressive board mask because it clipped a canonical port. The second capture uses a safe inset equal to the host overflow: Bank and Dev Cards read as one group, their labels clear the card feet, green felt is visible beside the teal frame, and all nine port badges remain visible. The End flag foot moves right without changing the prop or hit-region anchors.
- Round 17's first direct still was rejected because Messages retained the previous installed extension bundle: both the old two-roof City and opaque tokens remained visible despite fresh source and passing focused tests. Explicitly reinstalling the newly built containing app produced the valid second still with the reference-correct City and terrain-visible token treatment.
- Round 20's first physical-port still exposed the visible board mask as the effective port boundary: the wider generic ship could approach the left edge more closely than the prior text badge. Port marker size now participates in clamping and all markers sit closer to their coastal edge. A transient Messages app-drawer registration miss was cleared through the documented containing-app refresh before the passing installed capture.
- Round 23's first three attachments were not trustworthy gradient evidence: the fragment-shader objects existed in scene tests, but settled board crops showed the same flat fallback fill. Explicitly applying the selected style during every scene update fixed preference propagation, while replacing the shaders with generated textures made the pixel effect deterministic. The containing app then required the same explicit reinstall already documented in Rounds 12 and 17 before the revised gradient pixels appeared in Messages.
- The final constraint audit caught that the first production Hand stack truncated the data itself to two kinds and collapsed playable/new status. The corrected presentation model still carries every owned kind and the Hand entry exposes a complete VoiceOver value. Following user calibration, the default visual is intentionally a compact two-card summary; tapping it reveals the complete per-kind inventory with playable/new treatment.

## Validation and Outcome

The approved Physical Props composition is now the production normal `.afterRoll` surface for the active local actor. All nested states reuse its fixed five-zone geometry; Bank levels toggle independently, owned Dev Cards stay nested inside Hand, the public Dev Cards pile exclusively owns purchase, and presentation-derived top prompts replace dice only during active choices. On 2026-07-15, 52 focused MessagesExtension tests passed, followed by installed end-to-end Turn Screen, active-proposer pending-trade, and settled Hand-capture XCUITests with zero failures. Fresh constraint-auditor and product-UX re-reviews passed with no remaining blockers. After the user-directed two-card Dev-entry correction, 18 focused presentation tests, the settled Hand capture, and the complete installed Turn Screen journey passed; both the compact entry and its full opened inventory were visually inspected. The standard completion gate then passed after its sandbox-only Tuist cache failure was rerun with normal cache access. Excluded surfaces, canonical state, transport, legality ownership, and SpriteKit board ownership remain unchanged.
