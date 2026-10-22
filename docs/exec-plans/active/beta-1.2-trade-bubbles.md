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
| TB-001 | observable | user clarification | Felt, actual full-strength artwork, repeated small quantities, exact counts below and named players fit bubble | three renderer fixtures and pixel inspection | report:followup-render-pending | pending | Image itself is the shipped bubble asset |
| TB-002 | mechanical | architecture/secrecy | Public offer only, unchanged caption/summary/protocol/in-game trade | focused copy tests and source review | report:followup-tests-pending | pending | No private hand counts |
| TB-003 | mechanical | workflow | Owner docs current, validated commit pushed to beta-1.2 | gate and git evidence | report:followup-delivery-pending | pending | Preserve concurrent supply work |
<!-- verification-contract:end -->

<!-- fresh-review:start -->
| Reviewer | Required | Verdict | Evidence |
| --- | --- | --- | --- |
| constraint-auditor | yes | pending | report:readiness_auditor-final-trade-bubbles |
| product-ux | yes | pending | report:readiness_auditor-three-render-inspection |
<!-- fresh-review:end -->

## Living Record

Follow-up: user rejects redundant per-side totals and the name/status composition. Reopen standard/direct for a narrow refinement: per-resource quantities only; proposer once in header; recipient names once in footer; collapse identical waiting status into one shared line; improve card spacing. Preserve differing participant responses. Clarify whether "appeared out" means spread/fanned cards while proceeding with the unambiguous cleanup. Locked proof: same three production renderer cases plus copy tests, initial visual round and at most one correction round; fresh constraint/product review, scoped commit/push and standard gate. No in-game trade changes. Prior passing evidence remains historical until refreshed below.

Refinement implementation: removed totals from both layouts; waiting recipient names join into one footer with a single awaiting-reply line, while differing responses remain individual. No answer to optional spread clarification after proceeding with independent cleanup; stated assumption of a gentle fan. Simple-exchange card maximum60 (previous52), shallow7-degree fan steps, wider spacing. Mixed3-type exchanges use a common38-point maximum on both sides to avoid inconsistent sizes. New mixed-response fixture preserves declined versus waiting evidence.

Refinement proof: two rounds each17/17 tests pass; final /tmp/uls-trade-refine-round2.xcresult. Inspected three final PNGs in /tmp/uls-trade-refine-round2-images and retained copies under output/trade-bubbles-review/refined. No totals, full-strength art, no clipping/overlap; long recipient names fit the consolidated footer. No more visual rounds. DESIGN bubble paragraph updated; unrelated supply edits preserved.

Root cause in existing receipt: it supplies count to GameTabletopPortraitCardView, which deliberately fades the artwork to16% behind overlaid numerals; the snapshot background uses sceneBackground (ocean). Fix at bubble call sites, preserving shared in-game card behavior. Existing receipt is only used by the trade snapshot (verify before edits).

## Validation and Outcome

Validated and delivered. DESIGN owns bubble presentation; other product/rules owners unchanged. Screenshots are local output, not durable binary references.

Implementation: ocean replaced with GameTheme.felt; bubble card calls no longer pass count overlays, preserving full-strength illustrations. Small quantities show repeated cards up to3 where space permits; mixed offers print exact quantities below representative cards. Four/five-type offers use two full-width rows. Common card width52 versus previous34. Proposer and named participant responses retained; duplicate recipient header removed. Only transcript receipt calls changed; in-game card rendering and trade surfaces untouched.

Validation: canonical generation succeeded. Round1 and final round2 each passed17 tests (3 renderer fixtures plus14 bubble-copy tests). Final result /tmp/uls-trade-bubbles-round2.xcresult; exported PNGs /tmp/uls-trade-bubbles-round2-images. Root inspected all3 final images: two sheep/one wood, mixed high-count offer, five types with long names. No overlaps; long recipient names truncate in their allocated columns. Images are fixed-size360×260 public-offer artwork, rendered at3x using production assets verified present in test bundle. This proves renderer output, not a new live remote-message send or recipient-host capture. Both allotted visual rounds used; no more polish loop.

Other bubble audit: lobby reuses the actual seat table; ordinary turns use the canonical board. End-game overlays a score strip on the board image and is the next candidate for a conversation-size visual review; source inspection alone does not establish a defect. No other bubble redesigned. Lifecycle redesign remains outside this clarified trade slice.

Fresh constraint/product-UX review passed source, public-only data, all3 pixels and17-test summary. Final singular/plural correction for dense1-card totals source-reviewed; three rendered fixture outputs unaffected. Standard simulator build before commit; gate and delivery evidence follow.

Delivery: simulator build passed after final copy correction. Commit7d37a08 pushed to origin/beta-1.2; staged scope contains only the three bubble source files, renderer tests, this plan and the bubble-only DESIGN paragraph. Supply-clarity edits remain uncommitted and untouched. Initial combined git command failed on sandbox index permissions; separately permitted staging/commit succeeded. Final completion gate follows.

Final standard completion gate passed: contract, harness audit, whitespace, doc freshness, canonical generation and simulator build. All TB constraints and required reviews pass. Local review images retained in ignored output/trade-bubbles-review/. Doc freshness: DESIGN and this ExecPlan updated; architecture, decisions, gameplay/product flows and QA contracts unchanged; no historical cleanup. No live message delivery or hardware acceptance claimed. Implementation7d37a08 is pushed; this evidence-only closeout is committed separately.
