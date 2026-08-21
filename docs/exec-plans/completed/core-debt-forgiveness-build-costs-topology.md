# Core Debt Forgiveness: Build Costs and Topology Caching

## Purpose and Outcome

Close TD-011 and the fixed-topology reconstruction portion of TD-007 without changing gameplay, protocol, UI, or public APIs. Success means every production build and development-card purchase cost uses `CoreBuildCostsV1`, and the standard topology plus render geometry are lazily cached from one internal geometry build while retaining identical deterministic values.

## Execution Settings

- Validation profile: `standard`
- Delivery posture: `direct`
- Rationale: This is settled structural work across Core, presentation, tests, and debt-owner docs. It changes no player-facing behavior but warrants the standard build lane and a fresh constraint audit because it consolidates rules-adjacent consumers.

## Context and Boundaries

- [Architecture](../../../ARCHITECTURE.md) keeps rules and validation authority in `ULS_CoreGame`; `MessagesExtension` may consume Core-owned costs but must not become a second rules engine.
- [Tech debt tracker](../tech-debt-tracker.md) owns TD-011 and the remaining TD-007 work.
- [Render/performance audit](../../quality/audits/2026-04-12-render-performance.md) is dated historical evidence and will not be rewritten.
- Existing `StandardBoardTopologyV1.standard()` and `renderGeometry()` signatures, cost values, topology IDs/order, serialized state, protocol fields, and UI behavior remain unchanged.
- Adjacency caches, layout caching, render-model memoization, projection decomposition, device profiling, and timing thresholds are out of scope.
- Pre-existing launch-flow and TestFlight changes in the worktree are user-owned and must remain intact.

## Milestones / Plan of Work

1. Route reducer, validation, legal-query, and development-card presentation consumers through `CoreBuildCostsV1`.
2. Cache standard topology and render geometry from one lazy internal geometry value without changing public call sites or deterministic outputs.
3. Add cost-consistency and resolver regression coverage, then run the locked Core, extension, generation, documentation, and completion checks.
4. Record TD-011 as resolved, narrow TD-007 to its remaining findings, add a compact changelog entry, and obtain a fresh constraint audit.

## Verification Contract and Fresh Review

<!-- verification-contract:start -->
| ID | Class | Source | Acceptance | Verification | Evidence | Status | Rationale |
| --- | --- | --- | --- | --- | --- | --- | --- |
| CDF-001 | mechanical | user plan and TD-011 | `CoreBuildCostsV1` is the sole production definition for road, settlement, city, and development-card purchase costs across reducer, validation, legal-query, and extension drafting paths | table-driven Core and extension tests plus targeted source search | command:swift-test-core-139-pass; command:messages-extension-tests-324-pass; file:Packages/ULS_CoreGame/Tests/ULS_CoreGameTests/CoreBuildCostConsistencyV1Tests.swift; file:MessagesExtension/Tests/DevCardInteractionResolverTests.swift | pass | Exact-cost, one-short, reducer, bank, validation, legal-query, empty-deck, phase, and actor cases passed; targeted production literal search returned no matches |
| CDF-002 | mechanical | user plan and TD-007 F1 | `standard()` and `renderGeometry()` retain their public signatures and return deterministic values derived from one lazy cached internal geometry; internal port and coast helpers reuse it | topology tests, source inspection, and fresh constraint audit | command:swift-test-core-139-pass; command:messages-extension-tests-324-pass; file:Packages/ULS_CoreGame/Sources/ULS_CoreGame/StandardBoardTopologyV1.swift | pass | Existing graph and render-geometry invariants passed; source shows both public functions and internal perimeter helpers derive from the same lazy cached geometry |
| CDF-003 | mechanical | compatibility boundary | Gameplay results, validation, topology ordering, identifiers, ports, and render coordinates remain unchanged | Core package tests and full MessagesExtension unit-test lane | command:swift-test-core-139-pass; command:messages-extension-tests-324-pass; artifact:Test-UnluckySevens-Workspace-2026.08.21_02-50-07--0700.xcresult | pass | Clean final lanes passed with zero failures after the invalid cross-target exploratory assertion was removed |
| CDF-004 | mechanical | repo workflow and doc ownership | Canonical generation, standard build, diff hygiene, doc freshness, debt state, and changelog are current | prescribed repository commands and owner-doc inspection | command:bash-gen-passed; command:git-diff-check-passed; command:make-doc-freshness-passed; command:make-harness-audit-passed | pass | Canonical generation and all pre-completion structural and owner-doc checks passed |
<!-- verification-contract:end -->

<!-- fresh-review:start -->
| Reviewer | Required | Verdict | Evidence |
| --- | --- | --- | --- |
| constraint-auditor | yes | pass | report:fresh-constraint-audit-2026-08-21 |
| architecture | no | not-applicable | Public and module boundaries are locked unchanged |
| behavioral | no | not-applicable | No gameplay, secrecy, recovery, or transport behavior change |
| product-ux | no | not-applicable | No player-facing UI, copy, accessibility, or visual change |
<!-- fresh-review:end -->

## Living Record

### Progress

- 2026-08-21: Locked the standard profile, direct posture, scope, compatibility boundary, and exact proof set before implementation.
- 2026-08-21: Centralized production cost consumers, added the shared topology cache, and passed 139 Core tests plus 324 MessagesExtension tests.
- 2026-08-21: Updated TD-011, narrowed TD-007, added the changelog entry, and passed canonical generation, diff hygiene, and doc freshness.
- 2026-08-21: Fresh constraint audit passed CDF-001 through CDF-004 with no blockers; the known TD-004 dependency-scan warning remains non-blocking and out of scope.
- 2026-08-21: The standard completion gate passed after an initial sandbox cache-permission failure was rerun unchanged with approved filesystem access.

### Decisions

- 2026-08-21: Preserve function-shaped topology APIs and use private lazy static cached values so callers and public interfaces do not change.
- 2026-08-21: Prove cache structure through source inspection and deterministic invariants rather than a flaky timing assertion or production test counter.

### Discoveries

- 2026-08-21: Development-card affordability was duplicated in both `DevCardInteractionResolver` and lobby availability; lobby availability can reuse the resolver so only one extension drafting path consumes the Core-owned cost.
- 2026-08-21: A direct `LobbyDriverViewModel` unit assertion cannot link in the duplicated-source `MessagesExtensionTests` target, matching TD-004. Resolver behavior remains executable coverage; the lobby's delegation to that resolver is locked to source inspection without changing test architecture in this slice.

## Validation and Outcome

- Automated: Core package lane passed 139 tests; full MessagesExtension unit lane passed 324 tests; canonical generation, `git diff --check`, `make doc-freshness`, and the standard `make completion-gate` passed.
- Fresh review: constraint auditor passed with no blockers after inspecting the active plan, owner docs, scoped and overlapping diffs, untracked tests, raw test evidence, source searches, and freshness checks.
- Doc freshness: TD-011, TD-007, this plan, and the changelog are affected; architecture, product, design, QA, decisions, and historical audits are intentionally unaffected.
- Deferred: measured device latency and the remaining TD-007 findings.
