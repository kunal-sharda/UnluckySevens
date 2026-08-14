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
| UCR-002 | mechanical | DESIGN.md approved component vocabulary and 2026-08-10 user legacy-free audit request | No retired lower-tray, shelf, duplicate rules engine, obsolete production layout branch, or dead compiled legacy renderer/component remains; DEBUG fixtures reference production components rather than duplicate UI | route/component inventory, identifier audit, compiler/build, deleted-symbol source guard, and independent code audit | command:`python3 scripts/check-harness.py`; report:terra-two-auditor-legacy-scan-2026-08-10 | pass | The unreachable non-physical Trade renderer, single-case layout style, and three unreferenced compiled components were removed; the harness now rejects their symbols if reintroduced |
| UCR-003 | observable | user request and UI flows | Every production control has a working open/close/back/cancel/confirm/selection path, including full Trade, Tutorial, robber, Games, lifecycle, and terminal UX | locked focused XCUITest journeys on a freshly installed build and a freshly built matching UI-test bundle | artifact:`output/ui-screenshot-harness/20260811T003213Z-iphone`; artifact:`output/ui-screenshot-harness/20260811T003804Z-iphone`; artifact:`output/ui-screenshot-harness/20260811T005330Z-iphone`; artifact:`output/ui-screenshot-harness/20260811T011515Z-iphone` | pass | All 18 isolated iPhone catalog routes passed against one pinned app/test build with matching installed extension hashes |
| UCR-004 | observable | DESIGN.md stable-table contract | Board, water frame, public rail, and turn-object rail retain approved size and position while overlays and nested action surfaces open | existing geometry assertions plus representative screenshot comparison | test:`testCapturePhysicalTradeCorrectionTutorialCheckpoint`; report:iphone-contact-sheet-inspection-2026-08-10 | pass | The harness exposed and verified removal of a centering feedback bug; offer, recipient, and maritime Trade now preserve identical tutorial and production board/Hand frames |
| UCR-005 | judgment | user request and DESIGN.md | The complete iPhone catalog reads as one cohesive product in typography, hierarchy, materials, icon language, spacing, opacity, and interaction ownership; representative iPad states remain usable | fresh catalog/contact-sheet inspection and product/UX review | report:iphone-63-capture-contact-sheet-pass-2026-08-10; artifact:`output/ui-screenshot-harness/20260814-stable-host-final-ipad`; artifact:`output/ui-screenshot-harness/20260814-stable-host-final3-ipad` | blocked | Settled-host iPad Normal Turn, Players, Trade, and corrected Setup now pass and are visually centered; the paired checkpoint remains incomplete because Discard exhausted the harness retry budget before its fixture loaded |
| UCR-006 | observable | PRODUCT.md accessibility principles and SwiftUI guidance | Icon controls have names, primary controls meet 44-point targets, Dynamic Type/Reduce Motion paths remain usable, and overlays hide inactive controls from accessibility | focused assertions, source audit, accessibility-size representative states, accessibility review | test:isolated-iphone-ui-catalog-2026-08-10; report:source-a11y-review-2026-08-10 | pass | Installed iPhone journeys passed target-size, naming, containment, and inactive-overlay assertions; the focused Strategy card correctly removes Rules controls from hit testing |
| UCR-007 | mechanical | AGENTS.md and QA | Source, tests, generated workspace, harness audit, diff hygiene, and standard completion gate pass serially | canonical generation, targeted tests, `make build`, doc freshness, completion gate | command:canonical-gen-build-for-testing-and-generic-build-pass; command:harness-unit-tests-22-pass; command:`python3 scripts/check-harness.py`; command:`git diff --check` | blocked | Pre-gate mechanical lanes pass, but the completion gate remains prohibited while UCR-005 is blocked by missing iPad rendered evidence |
| UCR-008 | mechanical | user request and doc ownership rules | All affected owner docs and active plans describe current components, routes, validation, and legacy disposition without depending on committed binary artifacts | semantic doc audit plus `make doc-freshness` | command:`make doc-freshness`; report:owner-doc-audit-2026-08-10 | pass | DESIGN, decisions, UI flows, UX Lab, tech-debt tracker, and active plans now own the changed facts |
<!-- verification-contract:end -->

<!-- fresh-review:start -->
| Reviewer | Required | Verdict | Evidence |
| --- | --- | --- | --- |
| constraint-auditor | yes | blocked | report:contract-audit-2026-08-10; UCR-005 remains blocked by the incomplete stable-host paired checkpoint |
| product-ux | yes | blocked | Settled-host iPad gameplay alignment is corrected, but final Discard/tutorial evidence and owner judgment remain pending |
| accessibility | yes | pass | report:installed-iphone-accessibility-assertions-and-source-review-2026-08-10 |
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
- [ ] Fresh iPhone and iPad evidence inspected within the bounded round budget (iPhone passed; iPad harness fixed and representative run now exposes a gameplay alignment defect).
- [ ] Required reviews and completion gate passed.

### Decisions

- 2026-08-10: Full catalog proof uses iPhone 17 on iOS 26.5. iPad Air receives representative lobby, normal turn, overlay, Trade, Tutorial, and terminal coverage rather than a duplicate exhaustive catalog.
- 2026-08-10: Preserve approved compositions and wording. A new visual principle or competing viable direction requires a user checkpoint; mechanical consistency and wiring corrections do not.
- 2026-08-10: A legacy candidate may be deleted only after production call-site, DEBUG fixture, test, and current-doc searches establish that it is unreachable or superseded.
- 2026-08-10: `output/`, `tmp/`, and `.impeccable/` are local evidence/scratch boundaries and remain outside Git.
- 2026-08-10: After the original screenshot circuit breaker stopped the lane, the user explicitly authorized one fresh cold-restart attempt. This is a new bounded attempt: prove one lobby route first through XcodeBuildMCP, expand only after a valid result, and stop immediately if the restarted host again fails before XCTest produces evidence.

### Discoveries

- 2026-08-10: The pre-pass worktree contained large local screenshot/video/PDF collections under `output/` and local PDF helpers under `tmp/`; these were excluded from the checkpoint and added to `.gitignore`.
- 2026-08-10: The shell-level resize freeze path rebuilt the board inside a retired header/tray/shelf composition. It was unreachable during ordinary physical turns but could replace the canonical shell during host resizing; removing that fallback also allowed the obsolete lower-shelf route and component family to be deleted.
- 2026-08-10: The first locked iPhone journey and two permitted retries all terminated before writing an `Info.plist` into their `.xcresult` bundle, including after simulator reboot and current-app reinstall. The circuit breaker stopped further iPhone routes and the dependent iPad lane.
- 2026-08-10: The user-authorized cold-restart attempt exposed two residual references to deleted legacy helpers and a compiler type-check bottleneck that incremental products had masked. The helper references were removed, the mode-change closure was extracted, and a clean canonical `build-for-testing` passed. The renewed `test-without-building` result was initially misclassified as a Messages-host termination. Direct `xcresulttool` inspection later proved that the extension launched and the test failed normally at `MessagesExtensionDesignSliceUITests.swift:3581`: the installed UI-test runner still expected the retired `Invitation Card` title while current source expects `Invitation`. The app reinstall refreshed the extension but not the stale runner selected from a different DerivedData product. The full catalog remains blocked until the harness pins build, install, xctestrun, and result paths to one root.
- 2026-08-10: Two independent Terra read-only audits confirmed that production routes resolve only to `LobbyShellView` or the canonical `GameShellView`, DEBUG UX Lab code is compile-gated, and no duplicate UI rules engine exists. They also found dead-but-compiled cleanup debt: the single-case `GameTabletopLayoutStyle`, the unreachable non-physical Trade renderer, and unreferenced `HandTrayView`, `BankTrayView`, and `GameTurnObjectButton` files. This is not player-reachable, but it blocks the stronger user-requested claim that no legacy component remains in the shipped binary.
- 2026-08-10: The harness audit found no proven product crash. Earlier isolated UI routes produced valid result bundles on the same day, while the renewed run launched the extension successfully and the XCTest runner later exited voluntarily with status 1. The durable harness should keep the checked-in UX Lab fixtures but add a preflight/manifest lane that records the simulator/runtime, installed extension hash, one drawer/lobby smoke, isolated per-route result bundles, and direct `simctl` stills.
- 2026-08-10: The checked-in catalog runner now pins generation, build, install, xctestrun, hashes, results, and captures to one manifest-backed lane and isolates every route. It produced 63 named iPhone captures across all 18 routes without a Messages-host termination.
- 2026-08-10: The Trade checkpoint found a real board-centering feedback defect: the outer board frame preference was incorrectly adjusted by the inner SpriteKit content offset. Removing that feedback made the correction deterministic and preserved identical board/Hand frames across player offer, recipient selection, maritime Trade, and production gameplay.
- 2026-08-10: On the iPad Air iOS 26.5 simulator, the containing bundle and extension were installed and hash-matched, but Messages drawer automation could not expose the app. Restarting Messages and dismissing the focused keyboard did not cross that host boundary. Three bounded attempts ended at the same drawer lookup, so the validation circuit breaker stopped the lane before product UI launched.
- 2026-08-11: User-provided iPad evidence proved Unlucky Sevens is present in the full Messages apps drawer and corrected the earlier host-registration diagnosis. The intermittent boundary is composer state: the first `+` tap can expose a photo-only surface, while refocusing the message field and tapping `+` again opens the full drawer. The harness now verifies the drawer state and performs that bounded recovery before searching for the extension.
- 2026-08-11: The full drawer is a dedicated 320-point `CollectionView`; whole-window swipes moved the transcript instead of this list. Scoping swipes to the collection that contains `Stickers` made extension launch deterministic. The iPad smoke then passed Lobby, Settings/Rules/Strategy, and every Tutorial screen. The next route demonstrated a product issue rather than a host issue: Game Information and Trade do not share a horizontal center on iPad.

## Validation and Outcome

- Automated: canonical generation, MessagesExtension build, full non-UI workspace tests, harness audit, typography/deleted-symbol scans, diff check, and doc freshness passed.
- Simulator: the isolated iPhone catalog passed all 18 routes and emitted 63 named captures from a hash-matched installed extension. The corrected iPad lane now launches the extension deterministically.
- iPad: Lobby, Settings/Rules/Strategy, and all 17 Tutorial states passed. Gameplay stopped on the first real responsive-cohesion defect: Game Information and Trade have different horizontal centers.
- Judgment: iPhone cohesion passed after full contact-sheet and focused original-resolution inspection; iPad utility/tutorial states pass, while gameplay alignment remains blocked.
- Documentation: affected owner docs updated and freshness gate passed.
- Completion gate: intentionally not run because UCR-005 and therefore UCR-007 remain blocked by the demonstrated iPad gameplay overlay-alignment defect.
- Deferred: real two-device multiplayer validation remains release-lane work unless this pass exposes a device-only production defect.
