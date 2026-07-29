# Lobby Invite Cocktail Table

## Purpose and Outcome

Find a distinctive invitation composition without turning the screen into either a generic form or a literal table diagram. Rounds one and two rejected a symbolic tabletop and a paper artifact. Round three tested a full-canvas lobby scene. The explicitly authorized fourth round replaces its abstract orbit with a believable cocktail-arcade-style physical table: the real numberless board is inset into the tabletop and four player stations attach to its edges.

## Execution Settings

- Validation profile: `standard`
- Delivery posture: `checkpointed`
- Rationale: this began as a high-judgment comparison. The user approved the cocktail-table direction, which is now routed across the production lobby family.

## Context and Boundaries

- [DESIGN.md](../../../DESIGN.md) owns the current felt, paper, wood, amber, type, and masked-robber language.
- The candidate must use `LobbyScreenModel`; it must not invent lobby state or game rules.
- The primary action retains the approved production component.
- Full settings remain in the existing sheet; the invitation exposes only the selected-rules summary.
- Display-name editing remains functional but should read as a compact identity row rather than a form section.
- Generated mock imagery is intentionally excluded because the user asked for actual app artifacts and has rejected generated-looking UI.

## Milestones / Plan of Work

1. Preserve the rejected tabletop as round-one evidence without changing production.
2. Preserve the rejected artifact as round-two evidence without changing production.
3. Preserve the spatial-orbit candidate as round-three evidence without changing production.
4. Add one DEBUG-selectable cocktail-table candidate using the real numberless board, four attached player stations, settings callback, name binding, and invite action.
5. Capture one clean invite-entry state in Messages and pause for user judgment.
6. Productionize the chosen composition across invite, Join, Ready, and waiting states; replace hard-coded settings text/board strategy with the current settings projection; add end-to-end coverage for name entry, Settings, Tutorial, Send Invite, Join, and Start; then run fresh required review and the completion gate.

## Approval Gate

- Authority: user.
- Proof: one clean iPhone Messages capture using the invite-entry fixture and real production components.
- Round budget: four visual rounds, no more than three representative states per round. The user explicitly authorized rounds three and four after reviewing the preceding checkpoints.
- Stop rule: while approval is pending, do not replace the production invitation card, expand the direction across nested lobby states, launch final reviewers, or run the completion gate.
- Status: approved by the user on 2026-07-25 after reviewing the felt-station checkpoint. Productionization, fresh review, and the standard completion gate are complete.

## Verification Contract and Fresh Review

<!-- verification-contract:start -->
| ID | Class | Source | Acceptance | Verification | Evidence | Status | Rationale |
| --- | --- | --- | --- | --- | --- | --- | --- |
| LTC-001 | observable | user direction | The candidate reads as a game-table invitation rather than a generic form/list card | installed Messages capture and user judgment | artifact:/tmp/unluckysevens-lobby-tabletop-candidate-r3; report:user-rejected-generic-form-2026-07-25 | not-applicable | Superseded exploratory direction; LTC-009 owns the approved composition |
| LTC-002 | observable | user direction | Player seats are the memorable centerpiece and open seats remain understandable | installed capture inspection and accessibility hierarchy | artifact:/tmp/unluckysevens-lobby-tabletop-candidate-r3; command:testCaptureLobbyTabletopInviteCandidate-pass-2026-07-25-164637; report:user-rejected-table-and-spacing-2026-07-25 | not-applicable | Superseded exploratory direction; LTC-009 owns the approved composition |
| LTC-003 | observable | user direction | Game Settings is compact while Display Name and the primary action remain conventional and stable | before/candidate capture inspection | artifact:/tmp/unluckysevens-lobby-tabletop-candidate-r3 | pass | Settings is a bordered rules row; the approved name field and Send Invite components remain the lower edge |
| LTC-004 | mechanical | architecture | Candidate consumes presentation models and preserves existing callbacks; no rules or transport changes | source inspection and focused UI test | file:MessagesExtension/Sources/Features/Lobby/LobbyTabletopInvitationProbeView.swift; command:testCaptureLobbyTabletopInviteCandidate-pass-2026-07-25-164637 | pass | DEBUG direction consumes LobbyScreenModel and forwards existing settings, tutorial, and invite callbacks |
| LTC-005 | observable | user direction | The round-two artifact is visually dominant, contains recognizable Unlucky Sevens identity and seat/rules context, and leaves only a compact identity editor plus Send Invite beneath it | installed Messages capture and user judgment | artifact:/tmp/unluckysevens-lobby-artifact-candidate-r2/BD3AAC25-A0DE-4269-96E6-A215D589B911.png; report:user-rejected-form-and-real-estate-2026-07-25 | not-applicable | Superseded exploratory direction; LTC-009 owns the approved composition |
| LTC-006 | mechanical | architecture | The artifact candidate uses real SwiftUI assets, bindings, and existing callbacks without changing lobby behavior | source inspection and focused UI test | file:MessagesExtension/Sources/Features/Lobby/LobbyArtifactInvitationProbeView.swift; command:testCaptureLobbyArtifactInviteCandidate-pass-2026-07-25-170408 | pass | DEBUG-only direction consumes LobbyScreenModel, binds the name field, and forwards settings, tutorial, and invite callbacks |
| LTC-007 | observable | user direction | The spatial candidate uses the available canvas, avoids a form/card silhouette, and makes the robber plus player seats the visual scene | installed Messages capture and user judgment | artifact:/tmp/unluckysevens-lobby-spatial-candidate-r3c/2C63F1D8-5DFE-4716-8B7B-EF2EE9D24A8E.png | not-applicable | Superseded exploratory direction; LTC-009 owns the approved composition |
| LTC-008 | mechanical | architecture | The spatial candidate uses real SwiftUI assets, bindings, and existing callbacks without changing lobby behavior | source inspection and focused UI test | file:MessagesExtension/Sources/Features/Lobby/LobbySpatialInvitationProbeView.swift; command:testCaptureLobbySpatialInviteCandidate-pass-2026-07-25-172343 | pass | DEBUG-only direction consumes LobbyScreenModel, binds the name field, and forwards settings, tutorial, and invite callbacks |
| LTC-009 | observable | user direction | The cocktail-table candidate reads as one physical multiplayer table, uses the real numberless board, and attaches four understandable player stations to its edges | installed Messages capture and user judgment | artifact:/tmp/unluckysevens-lobby-cocktail-table-r4i/F977BBE1-44A8-414D-B6B8-904A2831B9A4.png; report:user-approved-good-enough-2026-07-25 | pass | The user approved the centered heading, clean terrain, attached raised-felt stations, and restrained wooden frame for productionization |
| LTC-010 | mechanical | architecture | The cocktail-table direction reuses the production board renderer and existing lobby bindings/callbacks without changing rules or transport | source inspection and focused UI test | file:MessagesExtension/Sources/Features/Lobby/LobbyCocktailTableView.swift; command:testCaptureLobbyCocktailTableInviteCandidate-pass-2026-07-25-191527 | pass | The approved direction builds a numberless presentation model from the deterministic standard generator, renders it with BoardSceneView, and forwards existing lobby bindings/callbacks |
| LTC-011 | observable | approved production direction | Invite, Join, Ready, and waiting states use the approved cocktail-table family with functional Games, Settings, Tutorial, identity, and primary actions | focused installed lifecycle journey | command:testCaptureProductionLobbyLifecycle-pass-2026-07-29; command:testCaptureProductionLobbyAccessibilityLayout-AXXXL-pass-2026-07-29 | pass | Fresh installed standard-size Invite, Join, and Ready states passed; the invite surface also passed at accessibility-extra-extra-large with expected scrolling |
| LTC-012 | mechanical | AGENTS.md | Standard completion and documentation freshness gates pass | completion gate | command:completion-gate-2026-07-29 | pass | Contract is terminal and the final gate is the closing command for this plan |
<!-- verification-contract:end -->

<!-- fresh-review:start -->
| Reviewer | Required | Verdict | Evidence |
| --- | --- | --- | --- |
| constraint-auditor | yes | pass | Fresh 2026-07-29 audit found the production family, settings projection, lifecycle proof, and accessibility proof closure-ready |
| product-ux | yes | pass | Fresh 2026-07-29 review found no UX or accessibility blockers after Dynamic Type and current-settings fixes |
<!-- fresh-review:end -->

## Living Record

### Progress

- [x] Validation profile, delivery posture, scope, and approval authority locked.
- [x] DEBUG candidate implemented.
- [x] Invite-entry capture inspected.
- [x] Round-two artifact candidate implemented and inspected.
- [x] Round-three spatial candidate implemented and inspected.
- [x] Round-four cocktail-table candidate implemented and inspected.
- [x] User approval recorded.
- [x] Production state family implemented.
- [x] Fresh review.
- [x] Completion gate.

### Decisions

- 2026-07-25: Use a real SwiftUI comparison direction rather than generated mocks or rasterized UI.
- 2026-07-25: Keep production unchanged through the first judgment gate.
- 2026-07-25: Let the paper invitation wrap its real content instead of forcing a full-height form surface; this removes the dead internal band and leaves felt around the artifact.
- 2026-07-25: Reject the literal tabletop candidate. Do not productionize it or extend it across lobby states.
- 2026-07-25: Round two follows artifact-first minimalism: one branded invitation object, one compact identity row, and one primary action.
- 2026-07-25: Reject the artifact-card candidate. Do not refine its title or seat tokens in place; its card-and-rows composition is the underlying failure.
- 2026-07-25: The user explicitly authorized a third visual round with a new spatial premise: no paper container, no stacked settings row, and no dead lower canvas.
- 2026-07-25: Keep the full-canvas premise but replace the abstract pawn orbit with a physical cocktail table. The real numberless board is the tabletop content; player stations belong to the table edges.
- 2026-07-25: Refine the accepted direction around a compact brand bar: robber logo plus “Unlucky Sevens” at top left, Tutorial at top right, and a left-aligned “Invite to Table.” Lower the complete physical table into the viewport center, slim its rim and stations, and retain the centered 320-point identity/action column.
- 2026-07-25: Treat the invitation title and table as one hero composition rather than leaving the title attached to the utility header. Keep the brand row independently anchored, then use deliberate 36-point entry space above the title and 32 points between the title and table.
- 2026-07-25: User review reversed the left-aligned title treatment. Center “Invite to Table” over the physical table as a true display heading, using the shared semantic display font and one short amber geometric rule; retain no subtitle.
- 2026-07-25: Spend the user-authorized single refinement pass on root causes below the heading: inset every station into the wooden rim, reuse the rim’s wooden material for open stations, reduce the Optional station’s geometry and contrast, and omit port decoration from this lobby-scale numberless board while retaining the real board renderer and generated terrain.
- 2026-07-25: User review found the wooden open stations overextended the table material. Preserve their improved rim overlap and geometry, but return non-host stations to raised felt with a restrained amber contour so wood remains exclusive to the physical table frame.
- 2026-07-25: User approved the raised-felt station checkpoint as good enough. Exit the visual exploration gate and carry this direction into production invite, waiting, Join, and Ready states.

### Discoveries

- `LobbySeatTableView` already maps `LobbyScreenModel` into four seat states, but its 2×2 card grid is transcript-oriented and does not provide the physical tabletop composition needed here.
- The first internal render exposed host-label collision, a poker-like oval, and malformed overlay dividers. The reviewed candidate uses a smaller rounded tabletop, separated seats, explicit horizontal rules, and content-wrapping paper.
- Even after cleanup, a symbolic table surrounded by controls still reads as a diagram embedded in a form. The next direction should separate the compact setup utility from the branded invitation artifact instead of making the form itself imitate a table.
- The first artifact-candidate test exposed an accessibility identifier on the paper container that grouped away the title. Removing the redundant container identifier preserved the child semantics; the rerun passed without changing the visual composition.
- The installed artifact capture is clearer and more distinctive than the literal table, but the large wrapped title and plus-circle seats still borrow too much generic settings/form language. Those are the two judgment points at the approval gate.
- User review confirmed that the round-two artifact is worse: it uses the available canvas poorly and remains recognizably form-shaped. A replacement must change the spatial model, not restyle the card.
- The first spatial capture removed the card but reintroduced dead space through a flexible spacer. Replacing it with fixed rhythm and sizing the scene against the Messages viewport produced a complete, unscrolled hierarchy.
- A taller second render forced the harness to scroll and clipped the header, so it was rejected as invalid proof. The final checkpoint keeps the scene prominent while preserving the title, controls, and primary action in one viewport.
- The first cocktail-table render used the production board renderer correctly but left visible gaps between the table and player stations. Moving each station inward until it overlaps the rim created the intended single physical object without changing the viewport fit.
- The final checkpoint uses independent hierarchy and scene placement: the brand and invitation title remain left anchored while a 48-point scene lead-in lowers the physical table. The first capture exposed Tutorial compression at the narrow Messages width; explicit brand scaling and fixed tutorial sizing preserved both top-row anchors in the corrected capture.
- Separating the utility header and invitation hero improves the title’s placement, but the physical metaphor is not fully resolved: the station tabs still feel attached rather than constructed into the table, the production board’s ports and ships create high lobby-scale detail, and the Optional station competes with actual open seats.
- The single refinement pass resolves those three visible defects without introducing a new visual language: stations reuse the existing wooden name-tile material and overlap the rim, Optional uses smaller/lower-contrast treatment, and the preview omits only port decoration while preserving real generated terrain, robber geometry, and BoardSceneView rendering.

## Validation and Outcome

All four DEBUG directions build. The refined focused cocktail-table test passes on iPhone 17 / iOS 26.5 from `Test-UnluckySevens-2026.07.25_19-14-49--0700.xcresult`; its inspected approval artifact is `/tmp/unluckysevens-lobby-cocktail-table-r4i/F977BBE1-44A8-414D-B6B8-904A2831B9A4.png`.

The approved cocktail-table composition is routed across the production invite, Join, Ready, and waiting family. It projects the current board strategy and rules summary, passed a fresh installed lifecycle journey, passed an accessibility-extra-extra-large invite check, passed fresh constraint and product/UX review, and passed `make completion-gate PLAN=docs/exec-plans/active/lobby-invite-artifact-candidate.md`.
