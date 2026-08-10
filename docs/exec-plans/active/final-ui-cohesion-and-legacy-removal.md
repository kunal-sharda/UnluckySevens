# Final UI Cohesion, Wiring, and Legacy Removal

## Purpose and Outcome

Bring every production player-facing Messages surface onto the approved tabletop design system, prove that every visible control reaches its intended behavior, and remove retired UI implementations that are no longer reachable from production or needed by the deterministic UX harness. Success is one coherent SF Pro typography hierarchy, stable board geometry, complete interaction coverage, no legacy production branches, current owner documentation, and fresh iPhone/iPad evidence.

## Execution Settings

- Validation profile: `standard`
- Delivery posture: `direct`
- Rationale: The approved visual direction and locked surfaces are settled. This pass is broad and evidence-heavy, but it is not a release or distribution handoff. Mechanical cohesion, wiring, accessibility, and proven-dead-code removal are authorized directly; genuinely new visual choices fall back to a user checkpoint.

## Context and Boundaries

- The recoverable pre-pass checkpoint is commit `e5e9d01` on `ui-ux-single-device-testing` and is pushed to `origin`.
- [Design](../../../DESIGN.md) owns the approved visual language and typography contract.
- [UI flows](../../product-specs/ui-flows.md) owns player-facing behavior; [decisions](../../decisions.md) owns locked compositions.
- [Architecture](../../../ARCHITECTURE.md) owns module boundaries; Core and Transport rules are out of scope.
- [QA](../../quality/qa.md), [Messages host guidance](../../quality/messages-host.md), and [UX Lab](../../quality/ux-lab.md) own validation and simulator behavior.
- Production scope includes lobby, setup, all turn/forced-action states, complete player and maritime Trade UX, Tutorial, Settings/Rules/Strategy, Players/Games, recovery and lifecycle confirmations, terminal states, and collapsed Messages previews.
- DEBUG-only controls remain only where they provide deterministic access to production components. Historical documents and ordinary binary evidence are not rewritten or committed; stale current references are corrected in owner docs and active plans.
- Locked wording, board size and placement, board-number typography, game rules, protocol fields, and canonical state semantics do not change without explicit user direction.

## Milestones / Plan of Work

1. Build a source-backed route/component inventory and classify each suspected legacy implementation as production, harness-only, or proven unreachable.
2. Audit all player-facing typography, icons, overlays, hit targets, navigation ownership, and dismissal/confirmation paths against shared tokens and approved neighboring components.
3. Correct cohesion and wiring defects at the narrowest shared owner, add or repair focused tests, and remove only proven-unreachable legacy source, fixtures, identifiers, and current-doc references.
4. Regenerate once, run the locked focused test set serially, capture the complete iPhone 17 catalog and representative iPad Air states, inspect one batched visual round, and allow at most one confirmation round.
5. Update every affected owner doc and active execution record, run required fresh reviews and the standard completion gate, then commit and push the resulting slice.

## Verification Contract and Fresh Review

<!-- verification-contract:start -->
| ID | Class | Source | Acceptance | Verification | Evidence | Status | Rationale |
| --- | --- | --- | --- | --- | --- | --- | --- |
| UCR-001 | mechanical | DESIGN.md typography contract | All player-facing interface text uses SF Pro through semantic system/GameTheme styles; the board-number token remains the sole serif exception | recursive harness typography audit plus scoped source inspection | command:`python3 scripts/check-harness.py`; report:font-family-source-scan-2026-08-10 | pass | Harness passed; scoped custom/serif/rounded/monospaced-family scan returned no production hits outside the harness-approved board token |
| UCR-002 | mechanical | DESIGN.md approved component vocabulary | No retired lower-tray, shelf, duplicate rules engine, or obsolete production layout branch remains reachable; DEBUG fixtures reference production components rather than duplicate UI | route/component inventory, identifier audit, compiler/build, and deleted-symbol search | report:legacy-symbol-scan-2026-08-10; command:MessagesExtension-build-pass | pass | Removed 27 retired source files plus obsolete shell routing/render branches; deleted-symbol search is empty and generated build passes |
| UCR-003 | observable | user request and UI flows | Every production control has a working open/close/back/cancel/confirm/selection path, including full Trade, Tutorial, robber, Games, lifecycle, and terminal UX | locked focused XCUITest journeys on a freshly installed build | report:three-incomplete-xcresult-bundles-2026-08-10 | blocked | Initial installed-host route plus two bounded retries terminated before XCTest finalized a result bundle; no UI assertion verdict exists |
| UCR-004 | observable | DESIGN.md stable-table contract | Board, water frame, public rail, and turn-object rail retain approved size and position while overlays and nested action surfaces open | existing geometry assertions plus representative screenshot comparison | command:workspace-non-ui-tests-pass; report:visual-proof-blocked-2026-08-10 | blocked | Geometry/unit suite passes, but the required fresh installed-host comparison could not run past the harness circuit breaker |
| UCR-005 | judgment | user request and DESIGN.md | The complete iPhone catalog reads as one cohesive product in typography, hierarchy, materials, icon language, spacing, opacity, and interaction ownership; representative iPad states remain usable | fresh catalog/contact-sheet inspection and product/UX review | report:visual-proof-blocked-2026-08-10 | blocked | No valid fresh iPhone catalog was emitted; iPad was not started after the locked iPhone lane exhausted its retry budget |
| UCR-006 | observable | PRODUCT.md accessibility principles and SwiftUI guidance | Icon controls have names, primary controls meet 44-point targets, Dynamic Type/Reduce Motion paths remain usable, and overlays hide inactive controls from accessibility | focused assertions, source audit, accessibility-size representative states, accessibility review | report:source-a11y-review-2026-08-10; report:installed-proof-blocked-2026-08-10 | blocked | Source and non-UI checks found no new accessibility defect, but installed standard/accessibility-size states remain unverified |
| UCR-007 | mechanical | AGENTS.md and QA | Source, tests, generated workspace, harness audit, diff hygiene, and standard completion gate pass serially | canonical generation, targeted tests, `make build`, doc freshness, completion gate | command:generation-build-unit-harness-diff-doc-passed-2026-08-10 | blocked | All pre-gate mechanical lanes pass; completion gate is prohibited while observable and judgment constraints remain blocked |
| UCR-008 | mechanical | user request and doc ownership rules | All affected owner docs and active plans describe current components, routes, validation, and legacy disposition without depending on committed binary artifacts | semantic doc audit plus `make doc-freshness` | command:`make doc-freshness`; report:owner-doc-audit-2026-08-10 | pass | DESIGN, decisions, UI flows, UX Lab, tech-debt tracker, and active plans now own the changed facts |
<!-- verification-contract:end -->

<!-- fresh-review:start -->
| Reviewer | Required | Verdict | Evidence |
| --- | --- | --- | --- |
| constraint-auditor | yes | blocked | report:contract-audit-2026-08-10; UCR-003 through UCR-007 cannot pass without installed-host evidence |
| product-ux | yes | blocked | report:no-fresh-rendered-catalog-2026-08-10 |
| accessibility | yes | blocked | report:source-audit-clean-but-installed-accessibility-proof-unavailable-2026-08-10 |
| architecture | no | not-applicable | No engine, transport, protocol, or ownership-boundary change is authorized |
| behavioral | no | not-applicable | Route wiring is verified by declared observable journeys; gameplay semantics remain unchanged |
<!-- fresh-review:end -->

## Living Record

### Progress

- [x] Validation profile, delivery posture, scope, and exact proof classes locked.
- [x] Recoverable pre-pass checkpoint committed and pushed.
- [x] Production route/component and legacy-candidate inventory completed.
- [x] Cohesion and legacy cleanup implemented; installed interaction/accessibility proof remains blocked.
- [x] Owner documentation updated.
- [ ] Fresh iPhone and iPad evidence inspected within the bounded round budget.
- [ ] Required reviews and completion gate passed.

### Decisions

- 2026-08-10: Full catalog proof uses iPhone 17 on iOS 26.5. iPad Air receives representative lobby, normal turn, overlay, Trade, Tutorial, and terminal coverage rather than a duplicate exhaustive catalog.
- 2026-08-10: Preserve approved compositions and wording. A new visual principle or competing viable direction requires a user checkpoint; mechanical consistency and wiring corrections do not.
- 2026-08-10: A legacy candidate may be deleted only after production call-site, DEBUG fixture, test, and current-doc searches establish that it is unreachable or superseded.
- 2026-08-10: `output/`, `tmp/`, and `.impeccable/` are local evidence/scratch boundaries and remain outside Git.

### Discoveries

- 2026-08-10: The pre-pass worktree contained large local screenshot/video/PDF collections under `output/` and local PDF helpers under `tmp/`; these were excluded from the checkpoint and added to `.gitignore`.
- 2026-08-10: The shell-level resize freeze path rebuilt the board inside a retired header/tray/shelf composition. It was unreachable during ordinary physical turns but could replace the canonical shell during host resizing; removing that fallback also allowed the obsolete lower-shelf route and component family to be deleted.
- 2026-08-10: The first locked iPhone journey and two permitted retries all terminated before writing an `Info.plist` into their `.xcresult` bundle, including after simulator reboot and current-app reinstall. The circuit breaker stopped further iPhone routes and the dependent iPad lane.

## Validation and Outcome

- Automated: canonical generation, MessagesExtension build, full non-UI workspace tests, harness audit, typography/deleted-symbol scans, diff check, and doc freshness passed.
- Simulator: blocked. `/tmp/uls-final-ui-20260810/` contains three incomplete lobby-route result bundles; none is valid evidence.
- iPad: not run because the locked iPhone lane exhausted its retry budget first.
- Judgment: blocked without fresh rendered iPhone/iPad evidence.
- Documentation: affected owner docs updated and freshness gate passed.
- Completion gate: intentionally not run because the verification contract contains blocked observable and judgment constraints.
- Deferred: real two-device multiplayer validation remains release-lane work unless this pass exposes a device-only production defect.
