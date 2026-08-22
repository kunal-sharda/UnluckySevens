# Maintainability Forgiveness Program

## Purpose and Outcome

Retire the confirmed structural debt from the 2026-08-21 maintainability review without changing gameplay, protocol bytes, game-state authority, Messages host behavior, or the current player-facing UI. Success means the retained defensive behaviors have explicit ownership, dead paths and unused assets are removed, large orchestration files are split by responsibility, and Core/Transport/test-support boundaries are easier to verify independently.

## Execution Settings

- Validation profile: `standard`
- Delivery posture: `direct`
- Rationale: The user approved each keep/remove/solve decision and delegated implementation. The work is structurally broad and state-sensitive, so it requires a fresh constraint audit plus architecture and behavioral review, but no routine approval checkpoint.

## Locked Product and Compatibility Boundaries

- Keep the custom resize shield: game surfaces remain non-resizable and only the intended top strip may drive Messages host resizing.
- Keep host measurement and canonical board fitting. Consolidate duplicated layout calculations only when dimensions, thresholds, ordering, and visuals remain identical.
- Keep the game board live-mounted during host resizing and preserve debounced updates; remove only dead freeze/snapshot plumbing.
- Keep `GameShellView` as the shared state owner while extracting distinct presentation responsibilities. Board identity and game state must not reset during decomposition.
- Keep `LobbyDriverViewModel` as the orchestration facade while extracting focused collaborators incrementally.
- Keep anchored tutorial behavior, compact Open Lobby entrance, recovery-ledger safeguards, and every named XCUITest evidence surface.
- Preserve selection polling semantics exactly: the selected game remains mounted; other-game changes cannot hijack it; only a valid newer state for the selected game may advance it; switching is explicit; cancellation cannot mutate canonical state; polling remains hydration/reselection rather than authority.
- Preserve exact `compactStateV4` encoded bytes and decode compatibility while moving codec ownership to `ULS_Transport`.
- Preserve independent reducer/validator transition orchestration while sharing immutable Core definitions and math primitives.
- Remove unused `BoardTiles`, the unused uncolored `merchant_ship`, and terminal active-plan duplication only after source, bundle, and documentation checks prove they are not runtime dependencies.
- Isolate the DEBUG harness into a reusable design shape, but do not extract a cross-game package before a second game supplies a real consumer.
- No public API, protocol field, serialized data, gameplay rule, copy, accessibility, or visual changes are authorized.

## Ownership and Sequencing

1. Checkpoint the already-validated Core cost/topology work and compact-launch work as separate commits.
2. Run independent worktrees for Core internals, Transport codec ownership, and asset/document hygiene.
3. Integrate those branches, regenerate once, then create the shared testable-support target because it overlaps project configuration and extension source ownership.
4. Perform extension decomposition sequentially: layout/freeze cleanup, `GameShellView`, lobby orchestration and cancellable selection watch, projection/diagnostics, recovery orchestration, and DEBUG harness isolation.
5. Run the locked proof set, obtain fresh reviews, update debt-owner docs, and archive this plan only if every required constraint passes.

## Verification Contract and Fresh Review

<!-- verification-contract:start -->
| ID | Class | Source | Acceptance | Verification | Evidence | Status | Rationale |
| --- | --- | --- | --- | --- | --- | --- | --- |
| MFP-001 | observable | user decisions | Resize shield, host measurement, canonical board fit, tutorial, compact entrance, live board identity, and named evidence surfaces behave exactly as before | existing focused tests, full extension unit lane, source inspection, and behavioral review | command:MessagesExtensionTests-336-pass; report:behavioral-pass | pass | Retained defensive behavior survived cleanup |
| MFP-002 | mechanical | user decisions | Dead freeze plumbing, duplicate layout calculations, unused `BoardTiles`, and unused uncolored merchant-ship asset are absent without bundle/reference regressions | targeted source/bundle scans, generated build, and extension tests | inspection:removed-symbol-and-asset-scans-clean; command:gen-and-extension-lane-pass | pass | Removed paths are absent and retained assets still build |
| MFP-003 | mechanical | TD-004 and user decisions | `compactStateV4` lives in Transport with byte-identical fixtures; testable extension sources compile through one shared library target rather than duplicate target membership | Transport fixture tests, project inspection, generation, extension tests, and architecture review | command:ULS_Transport-7-pass; inspection:static-support-single-source-and-release-package; report:architecture-pass | pass | Protocol compatibility and single ownership are verified |
| MFP-004 | observable | user decisions | Game selection watch is lifecycle-cancellable and retains same-game, newer-state-only, explicit-switch, and non-authoritative polling semantics | focused state-transition tests and behavioral review | command:selection-watch-tests-in-336-pass; report:behavioral-pass | pass | Cancellation is generation-gated and remains non-authoritative |
| MFP-005 | mechanical | user decisions | `GameShellView`, lobby orchestration, projection diagnostics, recovery orchestration, and DEBUG harness are decomposed by responsibility without introducing alternate state or rules authority | source structure inspection, existing state/recovery tests, extension lane, and architecture review | inspection:responsibility-and-authority-boundaries; command:recovery-projection-fixture-tests-in-336-pass; report:architecture-pass | pass | Decomposition preserved the existing state and rules owners |
| MFP-006 | observable | user decisions | Core reducer/validation internals are organized by rules domain, shared only at immutable definitions/math boundaries, and retain deterministic outcomes plus independent cross-checking | Core package suite and behavioral review | command:ULS_CoreGame-139-pass; report:behavioral-pass | pass | Deterministic reducer and independent validation paths remain green |
| MFP-007 | mechanical | repo workflow | Debt tracker, changelog, active-plan archive state, generation, diff hygiene, doc freshness, and completion gate are current | owner-doc inspection and prescribed repository commands | command:gen-pass; command:diff-check-pass; command:doc-freshness-pass; command:completion-gate-pass | pass | Owner docs and prescribed closure checks are current |
<!-- verification-contract:end -->

<!-- fresh-review:start -->
| Reviewer | Required | Verdict | Evidence |
| --- | --- | --- | --- |
| constraint-auditor | yes | pass | Final source/docs audit: MFP-001 through MFP-006 pass; historical Core public API restored; relocated codec is SPI-only |
| architecture | yes | pass | Static support packaging, thin Apple host, Core/Transport direction, runtime authority, and topology cache all pass |
| behavioral | yes | pass | Core, codec, selection watch, recovery, board mounting, shell decomposition, diagnostics, and DEBUG fixture behavior all pass |
| product-ux | no | not-applicable | No UI, copy, accessibility, or visual change is authorized; trigger only if implementation crosses that boundary |
<!-- fresh-review:end -->

## Locked Proof Set

- `swift test --package-path Packages/ULS_CoreGame --skip ULS_CoreGameEvals`
- `swift test --package-path Packages/ULS_Transport`
- `bash ./scripts/gen.sh`
- Full `MessagesExtensionTests` simulator lane with `UnluckySevensUITests` skipped.
- Focused existing tests for resize policy/layout geometry, launch routing, game selection lifecycle, recovery behavior, compact-state fixtures, and DEBUG evidence identifiers.
- Targeted source and bundle-reference scans for removed freeze plumbing, `BoardTiles`, uncolored `merchant_ship`, codec duplication, and duplicated test target sources.
- `git diff --check`
- `make doc-freshness`
- `make completion-gate PLAN=docs/exec-plans/active/maintainability-forgiveness-program.md`
- Fresh constraint-auditor, architecture, and behavioral passes after implementation and final validation.

The validation circuit breaker applies: a harness failure receives only the bounded retry and regeneration route documented in `docs/quality/qa.md`; it does not authorize new product work.

## Living Record

### Progress

- 2026-08-21: Locked the standard profile, direct posture, retained behaviors, removals, decomposition boundaries, sequencing, and proof set from the user's one-by-one decisions.
- 2026-08-21: Read-only parallel mapping found Core, Transport, and hygiene safe to implement independently; shared test-support extraction and extension decomposition must remain sequential because they overlap `Project.swift` and extension source ownership.
- 2026-08-21: Baseline Core tests (139), MessagesExtension tests (324), canonical generation, diff hygiene, and doc freshness passed with zero failures.
- 2026-08-21: Checkpointed the completed Core debt-forgiveness slice and compact fresh-launch slice as separate commits before beginning new structural work.
- 2026-08-21: Integrated the Core rules-primitives/audit split after 139 tests, removed dead resize-freeze plumbing, and precomputed immutable `GameBoardLayout` geometry; the post-change 324-test extension lane passed.
- 2026-08-21: Moved the unchanged compact-state codec implementation into `ULS_Transport`, added captured compact/raw compatibility fixtures, and passed the seven-test Transport package lane.
- 2026-08-21: Removed the superseded `BoardTiles` catalog and uncolored merchant ship, made `BoardStamps`/`BoardMiniStamps` explicit in owner docs, and archived four plans whose own completion contracts were terminal.
- 2026-08-21: Replaced controller token recursion with a deterministic, scheduler-tested cancellable selection watch; cancellation and selection replacement are generation-gated and the callback remains the existing hydration path.
- 2026-08-21: Split GameShell trade layout/views and pure trade/discard transforms while retaining all shared `@State` and the mounted board in `GameShellView`.
- 2026-08-21: Made the production shell projection immutable, removed its writable lobby facade and duplicate legacy summary helpers, and moved non-product string formatting to a separate DEBUG diagnostics projection without changing UX evidence keys.
- 2026-08-21: Added a DEBUG-only game-agnostic fixture descriptor/registry seam while retaining all Catan fixture state, actions, IDs, accessibility contracts, and reducer provenance in the game-specific harness.
- 2026-08-21: Extracted pure recovery lifecycle policy while leaving conversation publication, ledger/session mutation, UI status, and Core authority in their existing owners; removed the remaining no-caller board reload reconstruction route without touching mounted-board resize settling.
- 2026-08-21: Replaced duplicated test-source membership with extension-safe static `MessagesExtensionSupport`; the shipping target retains only Apple host/resize-shield glue, tests consume the same compiled implementation, Release embeds no support framework, and the missing-dependency warning is gone.
- 2026-08-21: Final package lanes passed 139 Core tests and 7 Transport tests; canonical generation passed; the integrated simulator lane passed 336 extension tests with UI tests skipped; the generic Release build and static-support packaging inspection passed.
- 2026-08-21: Fresh constraint, architecture, and behavioral reviews passed. The constraint audit caught and corrected ordinary-public exposure of the relocated codec while preserving the pre-existing public Core build-cost API.
- 2026-08-21: Updated the harness dependency guard to enforce the approved one-way `ULS_Transport` to `ULS_CoreGame` schema dependency while keeping Core dependency-free; all 45 harness tests passed.
- 2026-08-21: The standard completion gate passed contract validation, harness audit, diff hygiene, doc freshness, canonical generation, and the generic MessagesExtension simulator build. All verification constraints are closed and this plan is archived.

### Decisions

- 2026-08-21: Decompose by independently testable responsibility and state ownership, not by line count.
- 2026-08-21: Treat the resize shield, polling invariants, recovery ledger, and DEBUG evidence harness as purposeful safeguards; simplify their implementation without deleting their guarantees.
- 2026-08-21: Keep the reusable harness work at the design/isolated-component level until another game demonstrates the correct shared package boundary.

### Discoveries

- 2026-08-21: The current dirty tree contains two coherent slices with one file overlap: Core cost/topology forgiveness and compact fresh-launch/TestFlight work. They will be checkpointed separately.
- 2026-08-21: Transport codec relocation can run beside Core work, but shared test-target extraction must follow Transport integration and share one extension owner.
- 2026-08-21: JSON object-key order from Foundation encoding is not a stable golden-byte fixture across processes. Compatibility is therefore proved by the 99%-similarity source move, an unchanged encoder implementation, canonical compact-schema fixture equality, and legacy compact/raw decode fixtures; production encoding was not changed merely to make key ordering deterministic.
- 2026-08-21: After the codec moved, the legacy duplicated-source test target could no longer compile because it still listed the removed extension-local codec path. This is the expected TD-004 dependency and is now the immediate shared-support-target integration gate, not a product regression or permission to alter codec behavior.

## Doc Freshness Ownership

- Affected: this active plan, `docs/exec-plans/tech-debt-tracker.md`, `docs/exec-plans/CHANGELOG.md`, and active-plan archive state.
- Updated: `ARCHITECTURE.md` for the Core-dependent Transport codec and static extension-support boundary.
- Intentionally unaffected: `docs/decisions.md` and `docs/quality/`; no locked decision or validation policy changed.
- Updated: `DESIGN.md` only to keep the board-art source of truth accurate after removing superseded assets; no visual direction changed.
- Intentionally unaffected: product specs and `PRODUCT.md`; dated audits remain unchanged historical evidence.
