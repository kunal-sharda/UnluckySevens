# Discard Screen

## Purpose and Outcome

Finish the forced-discard screen so a player can understand the requirement, compose an exact discard from their real hand, correct mistakes, and publish it confidently inside the constrained Messages host. The result should use the approved tabletop object grammar instead of the older nested generic modal treatment, while leaving Core-owned discard rules and transport behavior unchanged.

## Execution Settings

- Validation profile: `standard`
- Delivery posture: `direct`
- Rationale: This is a meaningful player-facing UI/UX change with observable interaction and visual-quality requirements. Discard behavior and the approved tabletop visual language are already settled in code and owner docs, so the slice applies that system without introducing a competing direction.

## Context and Boundaries

- Product and visual intent are owned by [PRODUCT.md](../../../PRODUCT.md), [DESIGN.md](../../../DESIGN.md), and [the tabletop UI system](../../design/tabletop-ui-system.md).
- Validation routing is owned by [QA](../../quality/qa.md) and [constraint verification](../../quality/constraint-verification.md).
- `ULS_CoreGame` continues to own the required count, legal hand contents, ordered discard rules, and validation.
- `MessagesExtension` only renders `GameDiscardPanelModel` and drafts the existing `submitDiscard` intent.
- No protocol fields, engine validation semantics, or locked decisions change.

## Milestones / Plan of Work

1. Replace the discard branch of the generic modal host with a focused tabletop discard composer mounted directly in the physical action well, without the legacy shelf or nested panel chrome.
2. Preserve exact-count selection, per-resource availability limits, correction, disabled-submit behavior, Dynamic Type-safe copy, 44pt controls, VoiceOver state, and stable UI-test identifiers.
3. Add a clean actionable-discard UX Lab route and an XCUITest journey covering add, remove, readiness, and submit affordances.
4. Generate once through `bash ./scripts/gen.sh`, run targeted tests and the Messages harness, inspect representative evidence, obtain required fresh reviews, and run the completion gate.

## Verification Contract and Fresh Review

<!-- verification-contract:start -->
| ID | Class | Source | Acceptance | Verification | Evidence | Status | Rationale |
| --- | --- | --- | --- | --- | --- | --- | --- |
| C-001 | mechanical | user request and existing presentation contract | Selection cannot exceed the required total or any resource count, removal reverses one choice, and publish is enabled only at the exact total | targeted MessagesExtension tests and source inspection | command:2026-07-20-physical-discard-resolver-tests-9-pass-01-27; artifact:Test-UnluckySevens-Workspace-2026.07.20_01-27-16--0700.xcresult; file:MessagesExtension/Sources/Components/GameDiscardComposerView.swift | pass | Card taps add one, the below-card counter removes one, and existing exact-total and availability guards remain authoritative |
| C-002 | observable | docs/quality/qa.md | The actionable fixture supports add, remove, ready, and publish affordances in the Messages host, uses the exact normal-turn board frame, and contains every control in reserved layout space | targeted cross-route XCUITest journey and inspected screenshots | command:2026-07-20-actionable-and-passive-discard-routes-pass-11-21; artifact:Test-UnluckySevens-Workspace-2026.07.20_11-21-16--0700.xcresult; artifact:/tmp/unluckysevens-board-match.NtLhuQ/D0475D19-8020-4EDA-9884-85BE0F94E894.png; artifact:/tmp/unluckysevens-board-match.NtLhuQ/7664EFA0-3687-4533-836F-9EB1889AD6E8.png | pass | One installed journey records the normal-turn frame, asserts discard is exactly equal, verifies the standalone object rail is absent only for actionable discard, retains card/counter non-overlap and surface containment, and separately proves the passive waiting route keeps its centered Hand rail |
| C-003 | judgment | DESIGN.md and docs/design/tabletop-ui-system.md | The surface reads as a compact tabletop discard task, keeps one obvious next action, avoids nested generic modal chrome, and ends the ocean cleanly without a dark vignette lip | product-ux fresh review plus inspected screenshots | review:2026-07-20-product-ux-pass-shared-board-flat-ocean | pass | Fresh review found the exact shared board frame, flat ocean, combined lower interaction zone, and actionable-only Hand-rail suppression visually coherent with no clipping |
| C-004 | judgment | PRODUCT.md accessibility contract | Controls remain at least 44pt, selection is not color-only, copy supports Dynamic Type, and VoiceOver exposes counts, selected state, add/remove purpose, and readiness | XCUITest frame assertions and accessibility/source review | report:2026-07-20-accessibility-and-behavior-pass-amber-contained-counter; file:MessagesExtension/Sources/Components/GameDiscardComposerView.swift | pass | The 36pt visual circle is nested inside the unchanged 44pt removal button; explicit label, selected-count value, return-one hint, add semantics, and progress remain authoritative |
| C-005 | mechanical | AGENTS.md | Generation, targeted validation, doc freshness, and all required standard-profile reviews pass before final gate orchestration | repository commands | command:bash-./scripts/gen.sh; artifact:Test-MessagesExtension-2026.07.20_11-03-53--0700.xcresult; artifact:Test-UnluckySevens-Workspace-2026.07.20_11-21-16--0700.xcresult; command:make-doc-freshness-2026-07-20-11-24; reviews:constraint-behavioral-product-ux-pass | pass | Generation succeeded; focused unit tests passed 25/25; installed actionable and passive journeys passed 2/2; doc freshness, product/UX, behavioral, and constraint reviews pass. The completion gate can now audit this closed contract and the broader repository harness separately |
<!-- verification-contract:end -->

<!-- fresh-review:start -->
| Reviewer | Required | Verdict | Evidence |
| --- | --- | --- | --- |
| constraint-auditor | yes | pass | Fresh audit passed the actionable/passive decisions, evidence mapping, provisional outcome, and flat-ocean owner-doc alignment with no findings |
| architecture | no | not-applicable | Presentation-only composition does not change module ownership or protocols |
| behavioral | yes | pass | Re-review passed the actionable/passive split and fresh installed 2/2 route evidence with no findings |
| product-ux | yes | pass | Fresh review passed the exact-frame, flat-ocean, combined-zone implementation with no findings |
<!-- fresh-review:end -->

## Living Record

### Progress

- 2026-07-19: Locked `standard` plus `direct`, mapped the existing forced-flow shelf and discard model, and established the verification contract.
- 2026-07-19: Added the focused tabletop composer, clean actionable UX Lab fixture, and installed-build XCUITest journey. Focused model/resolver tests passed 23 tests; the final interaction journey passed and its screenshot was inspected after a compact dock-clearance revision.
- 2026-07-19: Removed the unreachable legacy discard composer and rebuilt the Messages extension successfully so the presentation has one implementation path.
- 2026-07-19: `make doc-freshness` passed. Tier 1 owners were reviewed and intentionally unaffected because this slice applies their existing product, tabletop, and QA contracts; the active Tier 2 plan owns the current implementation and validation record.
- 2026-07-19: Fresh review caught scrolling content beneath the shelf header and blue bordered-button chrome. The correction moved progress plus reversible choices into a fixed first row, placed hand cards plus a compact neutral/amber action in the second row, and passed a fresh installed interaction journey without automatic scrolling or dock overlap.
- 2026-07-19: Reran the focused discard model, resolver, and UX fixture suites after the correction; all 23 tests passed with a retained xcresult.
- 2026-07-19: Re-review found that the shared dark-felt button style produced insufficient label contrast on the cream shelf. The final shelf-specific action retains the amber keyline but uses dark ink on a restrained raised-cream fill; a fresh installed journey passed and the high-contrast capture was inspected.
- 2026-07-19: `make completion-gate PLAN=docs/exec-plans/active/discard-screen.md` passed the discard verification-contract check, then stopped in the repository-wide harness audit on 32 pre-existing ignored icon and loot-sack studies in `docs/design/workbench/`. No active checkpointed plan owns that scratch. This slice did not delete or claim unrelated design work.
- 2026-07-20: Reopened the slice after the user identified that the actionable fixture still forced the older framed-shelf presentation. The production resolver now routes forced discard through `physicalProps`; `GameShellView` mounts the composer directly on felt above the physical prop rail and suppresses the overlay shelf.
- 2026-07-20: The first physical-route interaction run exposed that the selection badge intercepted repeated card taps. Separate 44pt amber remove controls now sit beneath selected cards, preserving reliable add and remove behavior without obscuring the resource portraits.
- 2026-07-20: Regenerated through `bash ./scripts/gen.sh`, passed all 9 focused physical-layout resolver tests, explicitly reinstalled and restarted Messages to clear a stale extension cache, and passed the installed actionable-discard journey. The final capture shows the physical top bar, frameless board, direct felt composer, object rail, and no legacy overlay shelf.
- 2026-07-20: Fresh behavioral, product/UX, accessibility, and constraint-auditor reviews passed against the corrected source, 23:09 xcresults, and physical capture. The completion contract check then passed, but the repository-wide harness audit again stopped on unrelated unowned `docs/design/workbench/` residue, now totaling 43 ignored icon and loot-sack studies.
- 2026-07-20: User review caught three missed cross-pass lessons in the physical capture: a lone Hand prop remained left-anchored, discard cards forked the canonical Hand geometry and stack treatment, and offset decrement controls painted across the card bottoms. Independent layout assessment and mechanical pre-scan confirmed all three causes.
- 2026-07-20: Reused the existing available-prop centering rule for discard, extracted one canonical physical resource-Hand card used by normal Hand and discard, and replaced the offset ZStack decrement treatment with a reserved 4pt-separated 44pt row. The installed journey passed with new centered-Hand and non-overlap frame assertions; the corrected capture was inspected.
- 2026-07-20: Fresh behavioral, product/UX, accessibility, and constraint reviews passed against the shared-card source, latest installed capture, and 23:25/23:26 xcresults. No implementation blockers remain in the discard slice.
- 2026-07-20: The standard completion-contract check passed after the layout correction. The repository-wide harness audit still stops on unrelated unowned `docs/design/workbench/` residue, currently 44 ignored files; the discard slice did not modify or delete that scratch.
- 2026-07-20: User polish review identified redundant `Discard 5 Cards` copy and awkward combined minus/count capsules. The primary action is now simply `Discard`; selected quantities live in small numeric card-corner badges, while correction uses standard `minus.circle.fill` controls in separate 44pt targets. Focused tests passed 9/9, the installed journey passed with an exact action-label assertion, the polished capture was inspected, and all fresh reviews passed.
- 2026-07-20: The final-polish completion-contract check passed. The repository-wide harness audit remains blocked by unrelated unowned `docs/design/workbench/` residue, now 48 ignored files as parallel design exploration continued; none were changed by this slice.
- 2026-07-20: User replaced the primary `Discard` verb with `Confirm` and requested alignment to the card row rather than the full card-plus-correction column. The action row is now top-aligned and Confirm receives a 58pt alignment frame matching the resource-card height. The installed journey passed exact-label and midpoint-within-2pt assertions; the capture and all fresh reviews passed.
- 2026-07-20: The Confirm-alignment completion-contract check passed. The repository-wide harness audit remains blocked by the same 48 unrelated unowned `docs/design/workbench/` files.
- 2026-07-20: User requested one last hierarchy adjustment: the numeric selected-count badges above cards now render at 72% opacity so they remain legible but recede behind readiness and Confirm. Generation passed, focused tests passed 9/9, the installed interaction journey passed 1/1, the fresh capture was inspected, and constraint, behavioral, accessibility, and product/UX reviews all passed with no findings.
- 2026-07-20: The final selected-count-opacity verification contract passed. The repository-wide harness audit remains blocked by the same 48 unrelated unowned `docs/design/workbench/` files; the discard slice did not alter that scratch.
- 2026-07-20: User clarified that the detached minus signs and floating selected-count badges should become one compact counter below each selected card. The card itself now stays identical to the normal Hand; tapping it adds one discard, while the below-card `minus + selected count` control removes one and communicates the current selection.
- 2026-07-20: Replaced the SF Symbol line with the typographic U+2212 minus so the counter stroke has the correct mathematical length and aligns to the numeral baseline. Generation passed, focused tests passed 9/9, the installed journey passed 1/1 with a 3-to-2 selected-value assertion, the final capture was inspected, and all fresh reviews passed without findings.
- 2026-07-20: The combined-counter verification contract and doc-freshness check passed. The repository-wide harness audit remains blocked by unrelated unowned `docs/design/workbench/` residue, now 54 files as separate design exploration continued; the discard slice did not alter that scratch.
- 2026-07-20: User requested amber containment with deliberate margins. The typographic-minus counter now sits in a 36pt amber circle centered inside the existing 44pt removal target, leaving 4pt of visual inset and retaining the 4pt card-to-control gap. Focused tests passed 9/9, the installed journey passed 1/1, the screenshot was inspected, and all fresh reviews passed without findings.
- 2026-07-20: The amber-contained-counter verification contract and doc-freshness check passed. The repository-wide harness audit remains blocked by unrelated unowned `docs/design/workbench/` residue, now 60 files as separate design exploration continued; the discard slice did not alter that scratch.
- 2026-07-20: User comparison identified that discard still shrank the canonical board and that the approved ocean halo read as dark-blue clipped edges. The shared shell now reserves the normal 72–76pt action zone for both routes, suppresses the redundant standalone object rail during forced discard, and gives the composer the combined normal action-plus-object footprint. This preserves the full-height board while keeping cards, 44pt counters, progress, and Confirm in measured layout space.
- 2026-07-20: Changed the production ocean default from the edge vignette to the existing flat surface and restored Flat as an explicit DEBUG UX Lab selector. The final installed cross-route journey passed 1/1, asserted exact `CGRect` equality for the normal and discard boards, retained non-overlap and containment assertions, and exported both screenshots for visual comparison.
- 2026-07-20: Behavioral review caught that the first rail-suppression condition also removed the centered Hand from passive players waiting on somebody else's discard. Suppression and the discard title now require an actionable discard model; a fresh installed two-route run passed 2/2, proving both the exact-board actionable screen and the passive centered-Hand state.
- 2026-07-20: Fresh behavioral re-review passed the actionable/passive split and installed 2/2 route evidence with no findings. The tabletop UI owner contract was updated from the former Halo default to the approved flat-ocean perimeter behavior so the code and durable design direction stay aligned.
- 2026-07-20: Fresh constraint re-audit passed with no findings, including direct inspection that the retained 11:21 xcresult succeeded with two tests and that the active plan remains provisional until C-005 runs.
- 2026-07-20: The standard verification-contract check passed after C-005 closed. The repository-wide harness audit then stopped on 60 unrelated unowned icon and loot-sack studies in `docs/design/workbench/`; this slice did not modify, delete, or claim that scratch.

### Decisions

- Reuse the existing `GameDiscardPanelModel` and draft callbacks; the screen will not duplicate discard legality.
- Treat the physical action well itself as the containing surface. The discard composer will not add a cream shelf, another card, or a duplicate title.
- Actionable forced discard is a production physical-props state. It bypasses `GameModalHostView` and the generic overlay shelf; the shell owns its title and direct composer, while passive players waiting on a discard retain the centered noninteractive Hand rail.
- Resource choices in discard use the same `GamePhysicalResourceHandCardView` geometry and base rendering as the normal physical Hand; discard-specific selection and correction affordances stay outside the card art.
- For passive players waiting on a discard, reuse `centersAvailableProps` so the lone noninteractive Hand remains centered rather than preserving empty normal-turn slot anchors. The actionable discard composer is the hand and therefore omits the duplicate rail.
- Keep the primary action verb-only when the exact requirement is already visible in readiness and progress. Selection quantity and removal are separate concepts: numeric card badges communicate the former, standard circular minus controls perform the latter.
- Align the primary confirmation action to the resource-card stage, not the taller card-plus-correction item. A shared 58pt alignment frame makes that relationship structural and testable without visual offsets.
- Keep normal Hand cards visually unmodified. Communicate discard state with a single below-card `minus + selected count` control; the card adds and that control removes.
- Use the typographic minus character U+2212 in the counter rather than an icon so its length and baseline are native to the surrounding numeral typography.
- Contain the corrective counter in a 36pt amber circle inside a 44pt semantic target, using dark card-count ink for contrast and retaining 4pt separation from the card.
- Keep the normal-turn board reservation invariant during forced discard. The visible discard hand owns the combined normal action and object zones, so the separate Hand prop is omitted for that task instead of shrinking the board or painting controls outside their frames.
- Use the flat ocean treatment as the production default. The darker vignette studies remain available in DEBUG UX Lab, but production board boundaries should come from the rounded container rather than a second dark-blue edge treatment.

### Discoveries

- The pre-correction actionable discard routed through the legacy `GameModalHostView` even when the Physical Props design system was selected. Forced discard now participates explicitly in physical-layout resolution and bypasses that route.
- The former forced-flow shelf duplicated containment, title, clipping, and scrolling responsibilities. The physical shell now owns those responsibilities for actionable discard.
- An initial valid-state capture placed the submit and selection controls too close to the Messages dock. Moving the primary action above the discard pile and compressing the header preserved the full task inside the host without moving the board.
- Messages can retain an older extension build after a successful workspace build. Visual evidence for this route must explicitly install the current app and restart Messages before capture.
- A 44pt control moved with `offset` does not reserve its painted or hit-test bounds. The earlier 42pt offset inside an 82pt item necessarily crossed the resource card and escaped the container; correction controls now occupy explicit layout space.
- The apparent dark-blue board lips were not SwiftUI clipping artifacts; they were the production `edgeVignette` texture intentionally darkening the ocean perimeter. Choosing the flat preset removes that competing edge while preserving the shared rounded mask.

## Validation and Outcome

The shared-board-frame and flat-ocean correction is implemented with all discard constraints and required fresh reviews passing. The standard verification-contract check passes. The unrelated design-workbench residue recorded during the slice was removed by a later approved cleanup, so no implementation, review, or repository work remains in this plan.
