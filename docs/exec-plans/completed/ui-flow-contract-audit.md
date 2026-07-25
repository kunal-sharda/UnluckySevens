# UI Flow Contract Audit and Restructure

## Purpose and Outcome

Make [UI Flows](../../product-specs/ui-flows.md) the readable, evidence-backed contract for the complete player journey. Success means a reader can quickly tell what is required, which flows exist, how they connect, what is intentionally invariant, and where the current UI is known or suspected to violate the contract.

Parent: [Phase 14 — UI Design, Bubble Polish, and Trust Surfaces](phase-14-ui-design-bubble-polish-and-trust-surfaces.md).

## Execution Settings

- Validation profile: `standard`
- Delivery posture: `checkpointed`
- Rationale: restructuring the owner document is settled, but resolving discovered product/UI conflicts requires owner judgment and must not be hidden inside a documentation cleanup.

## Context and Boundaries

- Code, tests, and current fixtures establish actual behavior.
- [Decisions](../../decisions.md) owns locked calls; [Architecture](../../../ARCHITECTURE.md) owns runtime boundaries; [MVP Contract](../../product-specs/mvp-contract.md) owns scope.
- This slice may restructure and correct `ui-flows.md`, but it does not change Core rules, transport, protocol fields, canonical state, or shipping UI behavior.
- A mismatch is recorded explicitly as a known violation or unresolved question. Documentation must not be weakened merely to match an implementation defect.
- Ordinary audit logs and captures remain outside Git.

## Milestones / Plan of Work

1. Inventory every current UI-flow claim and group it by player journey rather than implementation chronology.
2. Check material claims against code, tests, locked decisions, architecture, and MVP scope.
3. Rewrite `ui-flows.md` with a clear reading guide, end-to-end flow map, per-flow contracts, invariants, and a visible known-violations section.
4. Run documentation and consistency checks, present the rewritten contract and violation inventory, and pause for owner direction on any product/implementation conflicts.

## Approval Gate

Authority: user.

Proof: the rewritten `ui-flows.md`, source/test evidence for material corrections, and a short list of current violations or unresolved conflicts.

Stop rule: do not change shipping UI behavior, locked decisions, protocol, or rules until the user approves the relevant correction.

## Verification Contract and Fresh Review

<!-- verification-contract:start -->
| ID | Class | Source | Acceptance | Verification | Evidence | Status | Rationale |
| --- | --- | --- | --- | --- | --- | --- | --- |
| UFC-001 | judgment | user request | Importance and hierarchy are obvious without reading every paragraph | direct document inspection and owner verdict | report:owner-flow-and-language-review-2026-07-25 | pass | The owner reviewed the full flow map, amber instruction contract, tutorial language, subtitles, and transcript preview families |
| UFC-002 | mechanical | repository source-of-truth ladder | Material behavior claims match code/tests or are explicitly labeled as gaps | source/test/doc cross-check | focused source inventory plus 262 passing MessagesExtension tests | pass | Current behavior is stated as current; the release invite violation and real-iPad proof remain explicitly labeled |
| UFC-003 | mechanical | MVP and current UI surface | Lobby, setup, turn, forced actions, trade, game over, bubbles, utility, tutorial, resize, and recovery are covered | section inventory inspection | `docs/product-specs/ui-flows.md` end-to-end journey and dedicated flow sections | pass | The contract now covers the full journey, not only tutorial navigation |
| UFC-004 | judgment | user request | Current contract violations are visible and not normalized away | owner review of violation inventory | report:owner-gap-review-2026-07-25 | pass | The owner closed the tutorial checkpoint and retained invite productionization plus real-iPad proof as active work |
| UFC-005 | mechanical | doc ownership rules | No architecture, rules, QA, or visual-language detail is duplicated unnecessarily | owner-doc consistency and doc-freshness checks | `git diff --check`; `make doc-freshness` | pass | The rewrite links to owner docs and avoids implementation chronology |
<!-- verification-contract:end -->

<!-- fresh-review:start -->
| Reviewer | Required | Verdict | Evidence |
| --- | --- | --- | --- |
| constraint-auditor | yes | pass | The standard app-language completion gate cross-checked the revised UI-flow contract against source, tests, and owner decisions |
| behavioral | yes | pass | Source inventory plus two focused test slices: 68 tests and 62 tests, all passing |
| product-ux | yes | pass | Owner approved the restructured contract, amber headings, tutorial treatment, and helper-text boundaries |
| architecture | no | not-applicable | No runtime-boundary change is authorized |
<!-- fresh-review:end -->

## Living Record

### Progress

- [x] Validation profile, delivery posture, scope, exclusions, and owner gate locked.
- [x] Material claims inventoried and checked.
- [x] Owner document restructured.
- [x] Known violations and unresolved questions presented for direction.

### Decisions

- 2026-07-24: The document will distinguish durable requirements, normal journey sequence, and known violations. Implementation defects will not silently redefine the contract.
- 2026-07-24: The rewrite covers the complete Messages-first experience, including turn behavior and recovery—not only Settings or Tutorial.
- 2026-07-24: A full player-facing audit/history view is explicitly out of scope. The current contract keeps one short previous-turn recap. A skippable previous-turn board replay on bubble open is a separate deferred concept, not a current requirement.
- 2026-07-24: The upper amber instruction is a dedicated interaction surface, not a synonym for every instruction in the app. The contract now records its precedence, semantics, exclusions, and complete emitted heading map.
- 2026-07-25: Owner review closed the tutorial and language checkpoint. The invite release mismatch and real-iPad proof remain owned by their focused active plans.

### Discoveries

- The existing 160-line document is organized as long bullet streams. It mixes game rules, UI requirements, visual composition, accessibility, host behavior, event taxonomy, and known direction without indicating relative importance or implementation status.
- The approved first-invite Invitation Card remains guarded by `#if DEBUG`; release still routes the empty invite through the generic lobby table.
- Canonical state carries an audit log, but the shipping game-information surface intentionally exposes public player summaries and only a short previous-turn recap. The owner explicitly declined a full history surface, resolving the former product question.
- Responsive host behavior has source and focused-test evidence, but the existing plan still requires connected-iPad visual approval.
- The restored Trade tutorial lessons and compact non-covering exit passed owner review and the complete installed tutorial replay.
- `GamePhysicalTurnHeaderPrompt` declares 21 headings, while the resolver and non-primary-player context can emit 19. `Choose Dev or Roll` and `Waiting for Discard` are retained in source and exhaustiveness tests but do not currently reach the upper amber instruction surface.
- The current UI excludes setup, start-of-turn, and forced-seven surfaces from the upper amber instruction. Whether forced actions should share the amber header is a product boundary requiring owner review, not something the audit can infer from implementation alone.

## Validation and Outcome

Generation succeeded through `bash ./scripts/gen.sh`.

Two focused `UnluckySevens-Workspace` test slices passed:

- 68 tests covering lobby presentation, board commit, game screen/discard/trade presentation, bubbles, recovery, responsive layout, and tutorial steps.
- 62 tests covering transport/session selection, ledger recovery, board rendering/resizing, lobby identity and membership, setup, turn, and Dev Card interactions.
- 14 tests covering the upper amber prompt resolver and non-primary-player routing.

`git diff --check` and `make doc-freshness` passed.

No shipping UI behavior changed in this documentation slice. Owner review approved the contract structure and disposed of the tutorial checkpoint. The remaining invite and real-iPad gaps stay visible in `ui-flows.md` and are owned by focused active plans. The later standard app-language completion gate regenerated the project, passed the complete 262-test MessagesExtension suite and installed tutorial replay, and cross-checked the revised contract.
