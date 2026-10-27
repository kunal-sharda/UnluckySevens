# Build and buy tutorial visual checkpoint — #55

## Purpose and Outcome
Show the owner an actual in-app four-choice teaching panel before changing production. Linked issue: https://github.com/kunal-sharda/UnluckySevens/issues/55.

## Execution Settings
- Validation profile: `standard`
- Delivery posture: `checkpointed`
- Rationale: user requests a visual comparison before accepting a new interactive tutorial composition.

## Context and Boundaries
Existing tutorial-controls plan records shipped controls. Subsequent owner feedback rejects the two underlined suppression rows and verbose teaching prose. Candidate: Build & Buy, “Here’s what you can build or buy.”, physical Road/Settlement/City/Dev with canonical costs; 0/1/2 VP, city upgrade explanation, and action or hidden VP wording. Compact Hide this tip checkbox and Turn off all tips footer. Player-header ideas remain separate. Preserve production behavior and board geometry. DEBUG preview choices demonstrate selection only, never purchase or publish; production wiring follows approval.

## Plan of Work
Use the existing preview-cost-build fixture with a new real-component DEBUG composition. One focused iPhone harness journey captures the panel, proves checkbox/selection/dismissal remain local and board geometry stable. At most three captures per round, two rounds. No additional state matrix before approval. Canonical runner owns generation/build/install; initial plus ten diagnosed reruns ceiling, no blind retries.

## Approval Gate
Owner approves actual simulator capture. Stop at this gate before productionization, fresh review or completion gate. Later production proof will be locked after chosen direction and before production edits.

## Verification Contract and Fresh Review
<!-- verification-contract:start -->
| ID | Class | Source | Acceptance | Verification | Evidence | Status | Rationale |
| --- | --- | --- | --- | --- | --- | --- | --- |
| GUIDE-001 | mechanical | user; AGENTS | DEBUG-only composition with real props and Core costs | Generated harness build; diff inspection | artifact:20261027T063538Z-iphone; file:MessagesExtension/Sources/Debug/GameBuildGuidePreviewView.swift | pass | Generated build passed; both preview types DEBUG-only |
| GUIDE-002 | observable | user | Four choices visible; local controls and stable board | Focused iPhone screenshot journey | artifact:20261027T063538Z-iphone | pass | Focused journey passed; screenshot inspected |
| GUIDE-003 | judgment | user | Owner accepts compact composition and copy | Owner screenshot review | report:pending | pending | Approval gate |
<!-- verification-contract:end -->
<!-- fresh-review:start -->
| Reviewer | Required | Verdict | Evidence |
| --- | --- | --- | --- |
| constraint-auditor | yes | pending | deferred until production approval |
| product-ux | yes | pending | deferred until production approval |
<!-- fresh-review:end -->

## Living Record
2026-10-26: locked scope and proof. Two columns preserve readable settlement name and costs. Existing production tutorial, Rules and Settings remain unchanged. This plan owns provisional design; no approved DESIGN or product behavior changes yet.

## Validation and Outcome
Pending capture and owner approval. No completion claim.

First harness run 20261027T063003Z-iphone built and displayed the panel. Journey failed because the root identifier propagated to each child button; exported accessibility hierarchy confirms it. Add an explicit containing accessibility element, matching the existing preview wrapper, and rerun the same journey. Actual simulator still inspected: four choices and footer fit without clipping. This failed run is diagnostic only, not acceptance proof.

Second run 20261027T063538Z-iphone passed: four tappable choices, local selection and checkbox, no canonical mutation, disable/re-enable and stable board frame/mount. Matching build/install verified by catalog. One screenshot inspected: costs, VP labels, city replacement note and compact footer readable; two-column panel is taller than earlier three-piece concept. Owner approval remains pending; no production wiring, fresh review or completion gate run. Simulator shutdown and app closure verified (no booted devices or Simulator process). Doc freshness passed; only this active plan changes because DESIGN, PRODUCT, UI flows and architecture still describe unchanged production behavior. No historical cleanup needed. Save/push the coherent DEBUG preview to beta-1.2.
