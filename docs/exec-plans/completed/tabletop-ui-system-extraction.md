# Tabletop UI System Extraction Plan

## Purpose and Outcome

Extract the durable visual, interaction, layout, accessibility, and ownership system approved through the Physical Props Turn Screen so every remaining Unlucky Sevens surface starts from shared rules and existing components rather than rediscovering the design language.

This active ExecPlan tracks the work and approval checkpoint. It is not a second design specification and will eventually be archived. The durable deliverable is [Tabletop UI System](../../design/tabletop-ui-system.md), which is the document product and design work should use.

Parent: [Phase 14](phase-14-ui-design-bubble-polish-and-trust-surfaces.md).

## Execution Settings

- Validation profile: `lightweight`
- Delivery posture: `checkpointed`
- Rationale: This is a documentation-first extraction of approved production behavior plus two narrow appearance-conformance fixes. It does not change gameplay, protocol, ownership, or layout geometry. The user will review one consolidated draft before it becomes the approved starting reference for later screen plans.

## Context and Boundaries

- [DESIGN.md](../../../DESIGN.md) remains the concise owner of current visual direction.
- [Tabletop UI System](../../design/tabletop-ui-system.md) holds the detailed reusable contract and maps intent to production sources.
- The approved Turn Screen and its production components are evidence, not a template that every surface must copy wholesale.
- Core/query outputs continue to own legality, availability, inventory, public/private projections, and action targets.
- SpriteKit continues to own the live board, canonical pieces, targets, camera, and interaction host. SwiftUI owns surrounding props and chrome.
- No new fixture, harness, artwork, gameplay behavior, protocol field, or broad component refactor belongs in this draft. Narrow fixes that make production match an already approved visual decision may be included for review.
- Ordinary screenshots and result bundles remain outside Git.

## Milestones / Plan of Work

1. Inventory the approved semantic tokens, components, state treatments, responsive geometry, artwork rules, and accessibility behavior in production code.
2. Distinguish reusable system rules from Turn Screen-only composition.
3. Define plain-language reuse modes for every remaining Current Notion surface.
4. Record code-to-contract mappings and correct narrow conformance gaps without silently redesigning the approved screen.
5. Present one consolidated contract to the user and pause for review.
6. After approval, lock the contract in `DESIGN.md`, resolve or route accepted conformance gaps, update the Notion task, and run the lightweight completion gate.

## Approval Gate

Authority: user.

Proof: one consolidated contract covering tokens, primitives, state grammar, layout/ownership, accessibility/motion, artwork fidelity, reuse modes, code sources, and conformance fixes.

Round budget: one user review and one focused correction round if requested. While approval is pending, later screen plans may inspect the draft but must not cite it as approved product truth.

## Verification Contract and Fresh Review

<!-- verification-contract:start -->
| ID | Class | Source | Acceptance | Verification | Evidence | Status | Rationale |
| --- | --- | --- | --- | --- | --- | --- | --- |
| TSC-001 | mechanical | production code | Every reusable token and primitive names its current implementation source; Turn Screen-only composition is not generalized accidentally | code inventory and doc inspection | file:docs/design/tabletop-ui-system.md | pass | Draft maps semantic roles to existing SwiftUI, SpriteKit, asset, layout, and presentation sources |
| TSC-002 | judgment | user direction | The contract faithfully captures the approved tactile language and is a useful starting point for remaining screens | one consolidated user review | report:2026-07-15-product-owner-approval-with-final-pending-label-correction | pass | User approved the system after shortening the anchored pending label to `Pending` |
| TSC-003 | observable | Current Notion tasks | Every remaining surface has an explicit reuse mode and preserved boundary | Notion task readback plus contract matrix inspection | report:2026-07-15-current-unlucky-sevens-task-scope-readback | pass | Matrix covers all ten Current items and treats this contract as the foundation |
| TSC-004 | mechanical | architecture and product owners | Contract preserves Core legality, SpriteKit board ownership, secrecy, transport, and excluded-surface behavior | owner-doc, focused test, and diff inspection | file:ARCHITECTURE.md; file:docs/product-specs/ui-flows.md; test:GameBoardSceneTests/testApprovedHaloIsProductionOceanDefault | pass | Runtime changes are limited to approved visual conformance and do not change gameplay or ownership |
<!-- verification-contract:end -->

<!-- fresh-review:start -->
| Reviewer | Required | Verdict | Evidence |
| --- | --- | --- | --- |
| constraint-auditor | no | not-applicable | Lightweight documentation extraction; user judgment is the only pending gate |
| architecture | no | not-applicable | Runtime ownership and dependencies do not change |
| behavioral | no | not-applicable | Gameplay behavior does not change |
| product-ux | no | not-applicable | User is the named approval authority for the consolidated contract |
<!-- fresh-review:end -->

## Living Record

### Progress

- [x] Read all Current Notion tasks labeled Unlucky Sevens.
- [x] Inventory approved production tokens, components, layouts, states, and ownership boundaries.
- [x] Draft reusable contract and screen-reuse matrix.
- [x] Resolve the approved Halo default and undersized Pending marker gaps for review.
- [x] User reviews the consolidated contract.
- [x] Accepted corrections applied and contract locked.
- [x] Matching Notion task moved from `Current` to `Done 🙌` and read back.
- [x] Lightweight completion gate passes.

### Decisions

- 2026-07-15: The contract is documentation-first. Extract only patterns already used with shared intent; do not create speculative abstractions for future screens.
- 2026-07-15: Amber is a semantic action-context color, not decoration and not a mandatory outline around every tappable object.
- 2026-07-15: Remaining screens use one of three reuse modes—not adoption or quality tiers: same gameplay table, board-guided flow, or same visual family.
- 2026-07-15: Product-owner review approved the durable contract after the pending-trade label was simplified to `Pending` and inline trade actions were aligned with tabletop typography.

### Discoveries

- The production system already has stable semantic sources, but intent is split across `GameTheme`, `GamePhysicalTurnPalette`, `GameBoardPalette`, layout metrics, reusable prop/card views, and the Turn Screen plan.
- The approved shoreline Halo had remained a DEBUG preference while the Release fallback resolved to Flat; `productionDefault` now makes Halo explicit and testable while preserving DEBUG comparisons.
- The Trade `Pending` marker was visually detached from its prop; pending state now uses the anchored `Pending` wooden label while preserving the stable `Trade` accessibility label and `Pending offer` value.
- Physical-props `Replace Offer` inherited blue bordered-button typography. It now shares the reusable tabletop inline-action style with End confirmation actions.

## Validation and Outcome

The durable contract is approved, its narrow appearance-conformance fixes are settled, the matching Notion task is `Done 🙌`, and the lightweight completion gate passed.

Focused checkpoint evidence:

- `bash ./scripts/gen.sh` passed.
- `GameBoardSceneTests` passed 14/14, including `testApprovedHaloIsProductionOceanDefault`.
- The installed `testSettleTurnPendingTradeForDirectStill` XCUITest passed after the correction, preserving the stable `Trade` accessibility label and `Pending offer` value.
- Direct simulator still `/tmp/unluckysevens-tabletop-contract-pending-final.png` was inspected: `Pending` is anchored in the existing wooden label below the ship, and `Replace Offer` uses a compact centered cream Caption treatment with the amber action keyline.
- Notion page `39e159c0c66481e0a4dfcd92320382db` was updated to `Done 🙌` and verified by readback.
- `make completion-gate PLAN=docs/exec-plans/active/tabletop-ui-system-extraction.md` passed before this plan was archived.
