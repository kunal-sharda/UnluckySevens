# Recovery and Terminal Lifecycle — Pass 2 UI Polish

## Purpose and Outcome

Polish the functional recovery and lifecycle surfaces from Pass 1 into one coherent, production-grade Physical Props family, then stop for one user approval checkpoint. Success at the checkpoint means three freshly installed states make game recovery, non-terminal resignation, and neutral game ending feel trustworthy and native to Unlucky Sevens without changing lifecycle, transport, or ledger behavior.

> Closed direction 2026-07-29: the replacement lifecycle is locked and implemented in Pass 1. Earlier terminal-resignation and co-winner checkpoint artifacts remain rejected historical evidence. The user authorized formal completion after the corrected Games placement, continuation copy, draw-first host-end flow, and refined result composition were implemented.

## Execution Settings

- Validation profile: `standard`
- Delivery posture: `checkpointed`
- Rationale: Behavior was settled, while Games management and the final-result hierarchy required calibrated visual judgment. The comparison remained DEBUG-only until the user approved it; the approved family is now production-routed.

## Context and Boundaries

- [Design](../../../DESIGN.md) and the [Tabletop UI System](../../design/tabletop-ui-system.md) own the visual language.
- [UI flows](../../product-specs/ui-flows.md) owns Games, recovery, resignation, victory, and New Game behavior.
- Pass 1 owns the functional APIs and state semantics; this pass must not reopen Core lifecycle rules, compact transport, ledger retention, or recovery selection.
- Recovery is a same-visual-family utility surface: calm hierarchy, standard controls, and trust-first language rather than ornamental props or transport jargon.
- The final live board remains visible. Victory or neutral result facts, final scores, recap, and New Game must not compete with or obscure it.
- The previously rejected segmented beige result rail and generic large cream card are prohibited directions. They remain DEBUG-only historical experiments and are not approval evidence.
- Existing dirty lobby work belongs to the user and must not be reverted.

## Milestones / Plan of Work

1. Audit the Pass 1 baseline against `GameTheme`, the Physical Props state grammar, Dynamic Type, 44-point targets, VoiceOver, reduced motion, and compact-host constraints.
2. Build one DEBUG-only polished family using real production components and deterministic fixture data.
3. Capture no more than three installed simulator states: dedicated Active/Finished Games; non-terminal Resign confirmation; host End Game decision or neutral draw/host-end result with final scores and New Game.
4. Present that single round to the user and stop. Do not productionize nested surfaces, launch final reviews, or run the completion gate while approval is pending.
5. After approval, route the approved family in production, remove superseded comparison routes, run focused XCUITest and accessibility evidence, then run fresh reviews, the standard completion gate, and doc freshness.

## Approval Gate

Authority: user.

Proof: one approval round containing no more than three freshly installed simulator states:

1. Active and Finished Games management.
2. Non-terminal Resign destructive confirmation.
3. Host End Game decision with draw-first soft guard, or one neutral draw/host-end result with final scores and New Game.

Round budget: one requested approval round. If the user rejects it or asks for a materially different direction, record the verdict and pause to agree on the next comparison rather than silently expanding scope.

Stop rule: while approval is pending, keep the polished family DEBUG-only. Do not productionize it, run automatic fresh review, or run the completion gate.

## Verification Contract and Fresh Review

<!-- verification-contract:start -->
| ID | Class | Source | Acceptance | Verification | Evidence | Status | Rationale |
| --- | --- | --- | --- | --- | --- | --- | --- |
| RTL2-001 | mechanical | Pass 1 and architecture | Visual work preserves all functional callbacks, Core-owned lifecycle semantics, STATE-only transport, and ledger behavior | focused regression tests and source diff | command:MessagesExtensionTests-284-pass-2026-07-29; report:fresh-architecture-behavior-review-2026-07-29 | pass | The presentation consumes Core results and existing callbacks without changing STATE-only transport or ledger semantics |
| RTL2-002 | observable | corrected user direction | Games management lives on the loading/home surface rather than over gameplay, with current-game navigation available from the game bar | installed state inspection and focused XCUITest | command:installed-lifecycle-5-pass-2026-07-29; command:production-lobby-lifecycle-pass-2026-07-29 | pass | Games is available from lobby/loading and both game top bars and remains absent from the terminal board |
| RTL2-003 | observable | corrected user direction | Resign uses an explicit confirmation that accurately describes non-terminal continuation | installed state inspection and focused XCUITest | command:installed-resignation-confirmation-pass-2026-07-29 | pass | Confirmation says the player leaves active play, pieces remain, and other players continue |
| RTL2-004 | observable | corrected user direction | Victory, host-end, and any approved draw result preserve the final board and show accurate result facts, scores, recap, and New Game | installed state inspection and focused XCUITest | command:end-screen-standard-and-AX-pass-2026-07-29; command:GameScreenModelBuilderTests-13-pass-2026-07-29 | pass | Victory and neutral outcomes use the approved board-first composition; neutral results suppress a fabricated winner score |
| RTL2-005 | observable | accessibility and Tabletop UI System | Controls retain 44-point targets, semantic labels, non-color state, readable contrast, Dynamic Type containment, and reduced-motion behavior | accessibility assertions plus installed accessibility-size inspection | command:production-lobby-AXXXL-pass-2026-07-29; command:end-screen-AXXXL-pass-2026-07-29 | pass | Adaptive header/rules layouts, scaled stations, scroll containment, semantic labels, and 44-point actions passed focused installed checks |
| RTL2-006 | judgment | user | The three-state family is approved before production routing | explicit user verdict | report:user-formal-completion-authorization-2026-07-29; report:victory-result-approval-2026-07-28 | pass | User approved the refined result direction and then explicitly requested formal completion of the corrected recovery/end-state work |
| RTL2-007 | mechanical | AGENTS.md | Standard completion and documentation freshness gates pass after approval | completion gate | command:completion-gate-2026-07-29 | pass | Contract is terminal and the final gate is the closing command for this plan |
<!-- verification-contract:end -->

<!-- fresh-review:start -->
| Reviewer | Required | Verdict | Evidence |
| --- | --- | --- | --- |
| constraint-auditor | yes | pass | Fresh audit rerun after corrected production routing and terminal contract closure |
| architecture | yes | pass | Fresh 2026-07-29 review confirmed presentation/Core/Transport boundaries |
| behavioral | yes | pass | Fresh 2026-07-29 review found no lifecycle or recovery behavior blocker |
| product-ux | yes | pass | Fresh 2026-07-29 review found no UX or accessibility blockers after adaptive-layout and settings-projection fixes |
<!-- fresh-review:end -->

## Living Record

### Progress

- [x] Corrected Pass 1 functional baseline and owner contracts inspected.
- [x] Standard validation profile and checkpointed posture locked.
- [x] Corrected polished family implemented and production-routed.
- [x] Corrected installed lifecycle and accessibility checkpoints captured.
- [x] Initial invalid user checkpoint verdict recorded and superseded.
- [x] Narrow victory-result cleanup removed Games management from gameplay and terminal routes, simplified the terminal top bar, and refreshed the score card.
- [x] User-authorized final-board refinement restores normal gameplay board geometry, fans the local player's canonically recorded played development cards above it, and treats the score card as the reverse of the player aid.
- [x] The approved victory-result refinement is production-routed with a winner-first outcome, grouped local development cards, the gameplay board-size contract, and a compact final-score ledger.
- [x] Follow-up distillation consolidates the outcome and decisive play above the board, limits the visible score aid to standings and New Game, and uses a representative four-card victory fixture instead of an extreme ten-card history.
- [x] Structural layout follow-up replaces the undersized stacked top rails with one side-by-side result tableau and replaces the cream double-keyline footer with a single-keyline wooden score slip.
- [x] Typography follow-up routes the result lockup and score slip through the shared semantic type ramp, equalizes every player column, shortens the decisive line, and seats the score slip lower in the table.
- [x] Final action polish replaces the outlined New Game control with a compact cream tabletop tab, semantic type, a replay icon, a 44-point minimum target, and pressed-state feedback.
- [x] Corrected family approved and production-routed.
- [x] Fresh product/UX verdict.
- [x] Completion gate.

### Decisions

- 2026-07-26: This plan absorbs the unresolved end-screen visual direction into one recovery-and-results family; the rejected score rail and generic cream card remain prohibited.
- 2026-07-26: Recovery uses familiar iOS management and destructive-confirmation affordances inside the tabletop material vocabulary. It does not simulate gameplay props.
- 2026-07-26: The final board stays dominant, while the terminal layer presents result facts as one coherent outcome rather than repeated player cards.
- 2026-07-26: User rejected placing the Active/Finished ledger over live gameplay. The proposed revision is to make the full ledger a loading/lobby destination and expose only current-game navigation/actions from the game top bar.
- 2026-07-26: User accepted the resignation-confirmation interaction in principle but rejected its sentence construction. The corrected copy must explain leaving active play while everyone else continues.
- 2026-07-26: User liked the visual concept behind the co-winner result, but the state itself was invalidated by the corrected lifecycle and is not reusable approval evidence.
- 2026-07-26: User then corrected the underlying lifecycle contract: a player's resignation is non-terminal, only the host can explicitly end the game, and remaining players need a continuation or agreed-draw path. This invalidates the resignation result fixture despite the visual concept feedback.
- 2026-07-26: While the broader lifecycle pass remains blocked, the user separately authorized a narrow victory-result refinement. Games management now appears only on the lobby route. The terminal route keeps the final board, a centered Final board label, the score track, recap, and New Game.
- 2026-07-26: The second terminal polish pass shifts the island upward within the final-board surface and removes the duplicate roll action from the recap when a roll total is already shown.
- 2026-07-26: The user replaced the end-only island shift with the gameplay board-size contract and requested a visible fan of their played development cards, including revealed victory-point cards. The final fan is presentation-only and reads Core's audit log, knight counter, and revealed-VP counter without adding protocol state.
- 2026-07-28: The user approved the refined victory-result direction for implementation. The production terminal route now leads with the local outcome, groups repeated played development cards, preserves the gameplay board geometry, and uses a winner-first score ledger with a compact decisive recap. This approval remains narrow and does not unblock the superseded resignation lifecycle contract.
- 2026-07-28: The first implemented proof exposed excessive terminal density and an implausibly development-card-heavy fixture. The visible score recipe and award labels were removed from the standard-size card, while their semantic detail remains in accessibility labels. The top now reads as one outcome story, and the fixture shows one Knight, one Road Building, and two victory-point cards.
- 2026-07-28: The distilled proof still looked compressed because the top's intrinsic content exceeded its separate 40-point and 52–56-point rail contracts. The replacement preserves their combined height and the gameplay board geometry, but lays outcome copy and the card fan side by side. The result rail now uses the existing dark wood palette, one border, vertical score columns, and an outlined New Game action.
- 2026-07-28: The result lockup's raw title style and the winner-only score weights made the otherwise improved tableau feel uneven. All visible terminal typography now uses `GameTheme`'s semantic fonts, every player name and point value uses the same roles and contrast, the winner seal carries the distinction, and the score slip moves down by the standard inline spacing token.
- 2026-07-29: The user accepted the end-screen composition and requested one final New Game refinement. The action now reads as a warm inset tabletop tab within the wooden score slip rather than an outlined form control, while retaining semantic sizing and a 44-point minimum target.

### Discoveries

- The earlier terminal-resignation Pass 1 evidence is superseded. Pass 2 may resume only after the corrected Pass 1 completion gate is green.
- The functional production fallback is intentionally restrained; the existing DEBUG end-screen candidate is rejected prior art, not a production starting point.
- The Messages host can retain a stale extension binary across rapid test installs; terminating the host and reinstalling the freshly built app restored deterministic fixture routing.
- The former co-winner fixture and assertions were removed because resignation is non-terminal.
- `MSConversation` exposes the active conversation and its participant identifiers, but no durable conversation identifier. The current ledger therefore spans every locally retained Unlucky Sevens game; exact transcript scoping would require a product-owned participant fingerprint and still could not distinguish two chats containing the same participants.

## Validation and Outcome

The first DEBUG-only checkpoint exposed a product-contract mismatch. Its Games placement was rejected, and its terminal resignation confirmation/result remain semantically invalid historical evidence. The corrected family uses non-terminal resignation, unanimous draw, host-only explicit end, lobby/loading Games management, and the approved board-first result composition.

Narrow victory-result proof:

- Freshly installed focused end-screen XCUITest at standard text size: 1 test, 0 failures.
- Freshly installed focused end-screen XCUITest at accessibility-extra-extra-large: 1 test, 0 failures.
- Focused `GameScreenModelBuilderTests`: 12 tests, 0 failures.
- The focused assertion confirms Games management is absent from the terminal route.
- The end-screen model assertion confirms the local card fan is derived from played action records, the Knight counter, and revealed victory-point cards.
- Inspected fresh-install capture: `/private/tmp/UnluckySevensEndScreenFreshInstall/90C3A9A6-FA9C-4012-B0B7-CEE02055E00A.png`.
- Inspected distilled fresh-install capture: `/private/tmp/UnluckySevensEndScreenDistilled/E3108E23-B923-41CE-A126-D88297BB2DC8.png`.
- Inspected structural-layout capture: `/private/tmp/UnluckySevensEndScreenTableauFresh/843D960D-F48F-45D6-BFED-E92BC5F7FCAC.png`.
- Inspected typography-polish capture: `/private/tmp/UnluckySevensEndScreenTypePolish/197F3E0A-F035-4451-8FCA-E649DAD66A64.png`.
- Inspected final New Game polish capture: `/private/tmp/UnluckySevensEndScreenNewGameFresh/2B0EE453-5173-43D3-960D-543A697DF4B2.png`.
- Final New Game polish focused XCUITest at standard and accessibility-extra-extra-large text sizes: 1 test, 0 failures at each size.
- Fresh constraint, architecture/behavioral, and product/UX reviews passed.
- `make completion-gate PLAN=docs/exec-plans/active/recovery-terminal-lifecycle-pass-2-ui-polish.md`: passed on 2026-07-29.
- Pass 2 is complete and intentionally does not claim TestFlight readiness.
