# Not Primary Player Visual Direction

## Purpose and Outcome

Turn the approved physical-props Turn Screen into the stable out-of-turn table: preserve the live board and public game context while removing actions the local player cannot execute, then surface only legal responder actions or blocking wait status when the state requires them.

Parent: [Phase 14](../active/phase-14-ui-design-bubble-polish-and-trust-surfaces.md).

Source intake: [Not Primary Player Screen](https://app.notion.com/p/39b159c0c66480a8b8caffc05da0952d), migrated into this repo-native plan on 2026-07-17.

## Execution Settings

- Validation profile: `standard`
- Delivery posture: `checkpointed`
- Rationale: the underlying board, tabletop language, and responder rules already exist, but the out-of-turn hierarchy and incoming-offer composition require visual judgment before production routing changes.

## Context and Boundaries

- Reuse the approved [Tabletop UI System](../../design/tabletop-ui-system.md), production physical-props Turn Screen, one mounted `BoardContainerView`, public Bank/Dev objects, player iconography, and compact status vocabulary.
- Ordinary waiting removes local active-turn props instead of showing a disabled active-player toolbar. Absence communicates unavailability.
- Incoming targeted trade offers expose inspection plus only the existing legal accept, decline, and counter routes. Core/query and presentation outputs remain the sole source of offer contents, recipient eligibility, and actions.
- The forced-seven proof covers a local viewer waiting while another player is the next ordered discarder. If the local viewer becomes the next required discarder, routing belongs to the separate active discard surface rather than this passive state.
- Preserve viewer-scoped secrecy: public information remains public, local private inventory remains scoped to the viewer, and opponents' hidden resources or Dev Cards are never inferred by the screen.
- Do not change Core rules, protocol fields, canonical-state publication, ordered-discard semantics, or trade validation.
- Start-of-turn, active post-roll actions, the local discard composer, robber movement, setup, lobby, settings, transcript, and game-over surfaces are excluded.
- Comparison screenshots and result bundles remain outside Git.

## Milestones / Plan of Work

1. Audit the existing out-of-turn screen projection, physical-props routing, incoming-trade model/actions, discard-order resolver, and UX Lab fixtures. Record the smallest presentation seam that can select passive, responder, and forced-wait compositions without duplicating rules.
2. Build a DEBUG-only comparison on the existing live board and tabletop components. Add fixture support only where the current `waiting-on-alice` and `pending-discard` states do not honestly cover the three proofs.
3. Compose ordinary waiting with stable public information and no unavailable local toolbar; compose an incoming targeted offer with inspect, accept, decline, and counter affordances; compose waiting-on-discard with the next player's status and no local discard affordance.
4. Capture exactly three representative proofs—ordinary waiting, incoming trade, and waiting on another player's forced discard—and stop for user review.
5. Apply at most one focused visual correction round using the same three proofs. If the second round is not approved, record the unresolved decision and ask the user how to proceed.
6. After explicit approval, route production out-of-turn states through the approved composition, add focused presentation/behavior/accessibility coverage, run required fresh reviews, and run the standard completion gate once.

## Approval Gate

Authority: user.

Approval question: do the three states read as one stable shared table that clearly distinguishes passive waiting, an actionable incoming offer, and a blocking forced-action wait without impersonating the active player's toolbar?

Proof: direct installed-simulator captures of ordinary waiting, incoming trade, and waiting on another player's forced discard using real components and fixture data.

Round budget: two visual rounds by default. While approval is pending, do not make the comparison the Release default, productionize additional out-of-turn nested states, launch fresh specialist review, or run the completion gate.

## Verification Contract and Fresh Review

<!-- verification-contract:start -->
| ID | Class | Source | Acceptance | Verification | Evidence | Status | Rationale |
| --- | --- | --- | --- | --- | --- | --- | --- |
| NPP-001 | observable | approved Turn Screen and tabletop system | All three proofs reuse one stable live board, public-table hierarchy, player iconography, and responsive geometry without remounting or resizing the board | installed UX Lab/XCUITest journey with board identity and frame assertions plus direct still inspection | DEBUG comparison: three installed captures; incoming-offer test preserves board frame and board-host value before/after opening the offer | pass | Production routing remains gated by NPP-006, but the comparison satisfies the stable-board constraint |
| NPP-002 | observable | Notion intake and tabletop system | Ordinary waiting shows current-player status and public context while unavailable local turn props are absent rather than disabled | accessibility-tree assertions and direct still inspection | Ordinary-wait capture shows `Maya's Turn`, public Bank/Dev objects, a centered Hand prop, and an empty action well; XCUITest rejects active-turn and action-spread controls | pass | The DEBUG proof expresses unavailability through absence |
| NPP-003 | mechanical | Core/query and presentation ownership | Incoming offer contents and accept, decline, and counter availability come from existing viewer-scoped models and legal-action outputs | focused builder/resolver tests and code inspection | Focused context, fixture, trade-builder, and discard-builder tests pass; physical responder view consumes `GameTradeOfferSummary` and `GameTradeResponderActions`; supplemental five-type offer verifies exact terms from canonical fixture data | pass | No UI-local trade eligibility, canonical state, or hidden opponent information was introduced |
| NPP-004 | mechanical | ordered-discard decision and UI flows | A viewer waiting on another discarder sees the next-player blocking status and no discard action; becoming the next ordered discarder exits this passive composition for the discard flow | focused resolver/builder tests for both actor scopes plus installed passive-state assertions | Fresh resolver/fixture suite proves the passive context for the waiting viewer and rejects it for the local next discarder; installed journey shows `Waiting for Theo to discard`, no Publish Discard action, no action spread, and a noninteractive Hand | pass | Actor-scope routing is deterministic presentation logic and is proved below the unstable Messages debug-state menu; the installed journey proves the resulting passive composition |
| NPP-005 | observable | accessibility and interaction contract | Every responder action has a stable label, hint, selected state where applicable, and at least a 44-point hit region; passive props do not enter the action rotor | focused accessibility assertions and installed inspection | Fresh single- and multi-type offer journeys verify exact offer labels, exact `Answer the Trade Offer` copy, 44×44 minimum responder targets, and prop-rail clearance; passive journeys reject unavailable actions | pass | Installed accessibility proof passed after production routing |
| NPP-006 | judgment | user | The three-state comparison establishes the intended Not Primary Player direction strongly enough to productionize | explicit user verdict recorded in this plan | User approved the corrected direction on 2026-07-18 and asked to finish the task after applying the instruction-title rule | pass | User owns the visual checkpoint |
<!-- verification-contract:end -->

<!-- fresh-review:start -->
| Reviewer | Required | Verdict | Evidence |
| --- | --- | --- | --- |
| constraint-auditor | yes | pass | Fresh review on 2026-07-18 found the contract, production routing, copy rule, responder accessibility, and mixed ordered-discard proof aligned with current code and evidence |
| architecture | no | not-applicable | Trigger only if implementation changes ownership or dependency direction |
| behavioral | yes | pass | Fresh re-review on 2026-07-18 passed after incoming-trade routing required both offer terms and responder actions, with inconsistent-model regression coverage |
| product-ux | yes | pass | Fresh review on 2026-07-18 accepted centered rails, trade clearance, exact copy, multi-type legibility, responder affordances, and the global instruction-title rule; dense multi-type marks remain a nonblocking low-vision watch item |
<!-- fresh-review:end -->

## Living Record

### Progress

- [x] Notion intake read and migrated into a repo-native active ExecPlan.
- [x] Validation profile, delivery posture, exclusions, three-state proof, and approval authority locked.
- [x] Existing presentation seams and fixture coverage audited.
- [x] First DEBUG comparison implemented, captured, inspected, and corrected once.
- [x] User-requested correction round applied: passive props centered, incoming offer lowered, and discard status names the next player.
- [x] User approval recorded.
- [x] Approved direction productionized and focused verification passed.
- [x] Required fresh reviews passed with no blocking findings.
- [x] Standard completion gate passed.

### Decisions

- 2026-07-17: The plan owns the shared-table passive and responder family, not every flow that occurs while the local player is not the turn owner. A local ordered discard remains an active forced-action screen.
- 2026-07-17: Out-of-turn unavailability is expressed by removing active-player props, not by rendering a disabled toolbar.
- 2026-07-17: The plan reuses the approved Turn Screen board and public tabletop instead of creating a second gameplay shell.
- 2026-07-17: A presentation-only context resolver admits ordinary `.needsRoll` waiting, targeted unanswered `.afterRoll` offers, and passive ordered-discard waits into the DEBUG physical table. The next ordered local discarder remains excluded and continues through the active discard surface.
- 2026-07-17: The targeted physical offer surface reserves a 96-point minimum—42 points for exact offer terms, 8 points of separation, and 44 points for legal responder actions—and clears the physical prop rail without moving or remounting the board.
- 2026-07-17: Active turns retain fixed prop slots for positional consistency. Not-primary states collapse unavailable slots and center only the remaining legal props as a compact group.
- 2026-07-17: The incoming-offer surface keeps its 96-point content height but uses six points of prop-rail clearance, moving the whole responder composition eight points lower without changing the board frame.
- 2026-07-17: Passive discard copy names the next ordered player from `GameDiscardPanelModel.waitingPlayers` rather than showing a generic discard wait.
- 2026-07-17: Non-current-player status uses the direct named-turn form (`Maya's Turn`) across the shared status resolver instead of passive `Waiting on Maya` wording.
- 2026-07-17: The actionable responder header uses title case—`Answer the Trade Offer`—and both single- and multi-type installed proofs assert the exact accessible title.
- 2026-07-18: All active physical instruction headers use conventional English Title Case; passive table-status copy remains natural sentence case. The reusable rule lives in the Tabletop UI System and is locked by exhaustive prompt-copy coverage.
- 2026-07-18: During another player's ordered discard, the centered Hand remains visible as table context but becomes a noninteractive accessibility element with `Available after the discard`; it cannot enter the action rotor or open an unusable spread.
- 2026-07-18: Ordered-discard handoff proof is split by evidence class: resolver/builder tests prove actor-scope routing into or out of the passive composition, while the installed journey proves the passive screen's status and absence/noninteraction constraints. The compact Messages debug menu is not treated as authoritative routing evidence.
- 2026-07-18: The user approved the corrected three-state direction and authorized productionization.

### Discoveries

- The repo already provides `waiting-on-alice` and `pending-discard` UX Lab fixtures; the audit must determine whether an honest targeted incoming-offer fixture already exists before adding one.
- Existing screen-model tests cover ordinary waiting and pending-discard status, while trade and discard resolvers already own the action semantics this screen must consume.
- The existing `trade-offer` fixture already provides an honest targeted incoming offer. The existing `pending-discard` fixture makes the local viewer the next discarder, so a separate `waiting-on-discard` fixture is required to prove the passive state without weakening ordered-discard semantics.
- First-round pixel inspection rejected the generic incoming-offer body: the fixed action well showed its title and responder buttons but squeezed the actual give/receive terms out of view. The targeted physical branch therefore uses a compact proposer + exact-card exchange strip above the same legal responder actions.
- Correction-round inspection found that the ordinary 72–76-point action-well frame clipped the lower half of the 44-point responder row. The trade surface now uses its honest 96-point minimum, and XCUITest guards both hit-region size and clearance from the prop rail.
- Messages produced intermittent torn SpriteKit/SwiftUI screenshot composites even while the accessibility hierarchy and board-host identity were stable. Those captures were rejected; the retained comparison uses clean harness attachments only.
- User review found that hidden active-turn slots left passive rails sparse and left-biased, and that the incoming responder surface sat too close to the board. The correction keeps fixed slots only for active turns, centers the visible passive props, and lowers the offer while preserving its verified 44-point actions.
- A supplemental multi-type offer (`1 Wood + 2 Sheep + 1 Wheat` for `2 Brick + 1 Ore`) fits the compact responder strip as five distinct colored count cards around the exchange arrow. The installed capture preserves the board, 44-point actions, and centered Hand/Pending rail without requiring a condensed fallback.

## Validation and Outcome

Checkpoint on 2026-07-17: the DEBUG-only comparison is implemented for ordinary waiting, targeted incoming trade, and waiting on another player's discard. `bash ./scripts/gen.sh` passed. A focused 22-test presentation/fixture suite passed. The three-state Messages XCUITest capture run passed, and the corrected incoming-trade test subsequently passed with stable board-frame/host assertions, 44-point response assertions, and prop-rail clearance assertions (`Test-UnluckySevens-Workspace-2026.07.17_21-07-21--0700.xcresult`). Direct inspection accepted the ordinary and discard proofs and the corrected incoming-offer composition; compositor-torn retries were discarded.

User correction round on 2026-07-17: focused context/fixture tests passed, then all three installed Messages capture tests passed with new centerline assertions for the one- and two-prop passive rails. The incoming test retained its stable board-frame/host, 44-point action, and prop-rail clearance assertions. Direct inspection accepted clean ordinary-wait, incoming-trade, and named discard-wait captures; the layout pre-scan returned no findings. The incoming composition is eight points lower than the first checkpoint, and its Hand/Pending pair is centered as one compact group.

Copy refinement on 2026-07-17: the shared non-current-player status changed from `Waiting on <player>` to `<player>'s Turn`. Focused status-line and screen-model tests passed, and the installed ordinary-wait capture passed with the centered `Maya's Turn` header.

Supplemental edge-case proof on 2026-07-17: a DEBUG multi-type trade fixture and quick state were added for `1 Wood + 2 Sheep + 1 Wheat` offered for `2 Brick + 1 Ore`. Fixture tests and the installed multi-type Messages test passed, including exact offer-term accessibility assertions, stable board frame/host, 44-point responder actions, and prop-rail clearance. This is diagnostic evidence in addition to—not a replacement for—the three approval captures.

Header copy refinement on 2026-07-17: `Answer the trade offer` changed to title-cased `Answer the Trade Offer`. Both retained incoming-offer journeys passed with an exact header-label assertion, and their clean screenshots were refreshed.

Productionization on 2026-07-18: the physical-props layout now becomes the Release default whenever the presentation resolver identifies an eligible not-primary context. `bash ./scripts/gen.sh` passed. An expanded focused 45-test Messages suite passed on the iOS 26.2 iPhone 15 simulator, including exhaustive physical-instruction copy, production layout routing, context resolution, named-turn status, ordered-discard builders, trade builders, and both trade fixtures (`Test-MessagesExtension-2026.07.18_00-54-08--0700.xcresult`). Four installed Messages journeys passed with zero failures: ordinary waiting, single-type incoming offer, multi-type incoming offer, and waiting on discard (`Test-UnluckySevens-Workspace-2026.07.18_00-46-50--0700.xcresult`). A subsequent installed discard run verified the centered passive Hand's noninteractive accessibility value before the Messages debug-state menu clipped the optional local-actor follow-up; the model/builder suite remains the authoritative handoff proof. Fresh reviews and the standard completion gate remain required before closure.

Final focused verification on 2026-07-18: after the behavioral review identified an inconsistent-model edge case, incoming-trade routing was tightened to require both an active offer and responder actions. The seven focused suites then passed 46 tests with zero failures (`Test-MessagesExtension-2026.07.18_01-41-11--0700.xcresult`). Fresh constraint, behavioral, and product/UX reviews all passed; the only watch item is the intentionally dense multi-type resource marks at low vision or larger Dynamic Type.

Completion outcome on 2026-07-18: the standard completion gate passed after its sandbox-only Tuist cache failure was rerun with normal cache access. The gate passed the selected verification contract, harness audit, diff check, doc-freshness check, repository generation, and generic iOS Simulator MessagesExtension build. Task-owned workbench screenshots were deleted as required when the visual decision closed.
