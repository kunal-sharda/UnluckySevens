# Beta 1.2 trade bubbles

## Purpose and Outcome

User clarified that trade conversation bubbles must be functional parts of the tabletop: actual illustrated resource cards, visible multiplicity (two sheep for one wood), quantities underneath, player names, SF typography and felt. Preserve the in-game trade layout; overlap repair requires demonstrated evidence. Lifecycle redesign remains a separate follow-up.

## Execution Settings

- Validation profile: `standard`
- Delivery posture: `direct`
- Rationale: user specified the exact visual direction and existing production assets.

## Context and Boundaries

Work on beta-1.2. Preserve concurrent supply-clarity edits. Only trade snapshot/receipt presentation and its evidence change; no Core, protocol, hidden-hand data or action eligibility changes. Commit/push the coherent validated slice. Bubble image canvas remains360×260; caption/summary remain the accessible Messages description.

## Plan and Locked Proof

1. Replace ocean with felt, remove count overlays that fade resource artwork, show card quantities below and repeated visible cards for small exchanges; bound large stacks with exact quantities.
2. Render three canonical simulator XCTest snapshot cases: two sheep for one wood, multi-resource/high-count offer, long names/three recipients. Use real production renderer and asset bundle; inspect all three exported attachments. Two visual rounds maximum. Focused bubble-copy tests protect public data semantics. No unrelated UI catalogs or gameplay changes.
3. Fresh constraint/visual review, doc freshness, standard completion gate, scoped commit/push. Each mechanical command initial plus two diagnosed retries.

## Verification Contract

<!-- verification-contract:start -->
| ID | Class | Source | Acceptance | Verification | Evidence | Status | Rationale |
| --- | --- | --- | --- | --- | --- | --- | --- |
| TB-001 | observable | user clarification | Felt, actual full-strength artwork, repeated small quantities, exact counts below and named players fit bubble | three renderer fixtures and pixel inspection | report:round2-three-inspected-attachments | pass | Image itself is the shipped bubble asset |
| TB-002 | mechanical | architecture/secrecy | Public offer only, unchanged caption/summary/protocol/in-game trade | focused copy tests and source review | report:17-tests-and-source-review | pass | No private hand counts |
| TB-003 | mechanical | workflow | Owner docs current, validated commit pushed to beta-1.2 | gate and git evidence | report:pending | pending | Preserve concurrent supply work |
<!-- verification-contract:end -->

<!-- fresh-review:start -->
| Reviewer | Required | Verdict | Evidence |
| --- | --- | --- | --- |
| constraint-auditor | yes | pass | report:readiness_auditor-final-trade-bubbles |
| product-ux | yes | pass | report:readiness_auditor-three-render-inspection |
<!-- fresh-review:end -->

## Living Record

Root cause in existing receipt: it supplies count to GameTabletopPortraitCardView, which deliberately fades the artwork to16% behind overlaid numerals; the snapshot background uses sceneBackground (ocean). Fix at bubble call sites, preserving shared in-game card behavior. Existing receipt is only used by the trade snapshot (verify before edits).

## Validation and Outcome

In progress. DESIGN owns bubble presentation; other product/rules owners unchanged. Screenshots are local output, not durable binary references.

Implementation: ocean replaced with GameTheme.felt; bubble card calls no longer pass count overlays, preserving full-strength illustrations. Small quantities show repeated cards up to3 where space permits; mixed offers print exact quantities below representative cards. Four/five-type offers use two full-width rows. Common card width52 versus previous34. Proposer and named participant responses retained; duplicate recipient header removed. Only transcript receipt calls changed; in-game card rendering and trade surfaces untouched.

Validation: canonical generation succeeded. Round1 and final round2 each passed17 tests (3 renderer fixtures plus14 bubble-copy tests). Final result /tmp/uls-trade-bubbles-round2.xcresult; exported PNGs /tmp/uls-trade-bubbles-round2-images. Root inspected all3 final images: two sheep/one wood, mixed high-count offer, five types with long names. No overlaps; long recipient names truncate in their allocated columns. Images are fixed-size360×260 public-offer artwork, rendered at3x using production assets verified present in test bundle. This proves renderer output, not a new live remote-message send or recipient-host capture. Both allotted visual rounds used; no more polish loop.

Other bubble audit: lobby reuses the actual seat table; ordinary turns use the canonical board. End-game overlays a score strip on the board image and is the next candidate for a conversation-size visual review; source inspection alone does not establish a defect. No other bubble redesigned. Lifecycle redesign remains outside this clarified trade slice.

Fresh constraint/product-UX review passed source, public-only data, all3 pixels and17-test summary. Final singular/plural correction for dense1-card totals source-reviewed; three rendered fixture outputs unaffected. Standard simulator build before commit; gate and delivery evidence follow.
