# Beta 1.2 kickoff and implementation sequence

## Purpose and Outcome

Start [Beta 1.2](https://github.com/kunal-sharda/UnluckySevens/milestone/2) on a dedicated branch using the milestone name. Preserve Beta 1.1 as the reliability candidate line. This kickoff establishes current membership and the first implementation boundary; it does not deliver the twelve product issues.

## Execution Settings

- Validation profile: `lightweight`
- Delivery posture: `direct`
- Rationale: branch organization, source inspection and execution planning only. Product implementation requires its own standard contract and any issue-specific visual approval gate before editing.

## Context and Boundaries

The user authorized starting the next milestone on 2026-10-21. GitHub identifies it as Beta 1.2. Renamed `milestone-1` to `beta-1.1` locally and remotely. `beta-1.2` branches from the existing Beta 1.1 checkpoint fb55281, so it inherits reliability fixes. Beta 1.1 hardware acceptance and distribution remain open; new Beta 1.2 changes must not enter its candidate implicitly. AGENTS.md owns milestone branch names and commit/push cadence.

## Milestones / Plan of Work

Current GitHub membership, read back 2026-10-21: twelve open issues.

1. #51: Trade/Bank supply clarity. First bounded implementation slice; inspect stock versus selected quantities, reuse public supply thresholds and distinguish empty supply.
2. #13/#14: shared cost/purchase composition, then owned Development Card arrival and timing. Checkpoint representative states before production routing.
3. #16: Road Building draft and explicit atomic confirmation, with its own interaction checkpoint.
4. #17/#18: public continuation and private roll/resource feedback; keep private information out of shared metadata.
5. #42/#19/#22: coordinate quiet seat identity, public standings and redundant accessibility cues in one mounted-table composition. Reuse the existing color-accessibility audit as evidence, not acceptance of unbuilt fixes.
6. #26/#25: common Reference/Learn entry and controls tour; preserve the integrated learning checkpoint and #24's separate ownership of beginner scenarios.
7. #3: deepen deterministic board/bubble assertions alongside the changed surfaces, then integrate milestone proof.

Order reflects dependency and boundedness; issue bodies remain authoritative. No issue closure, rules change, new protocol, or candidate distribution is implied.

## Verification Contract and Fresh Review

Locked kickoff proof: GitHub milestone and issue readback; source inspection of supply mapping and Trade bindings; local/remote branch verification; whitespace, doc freshness and lightweight completion gate. No runtime changes, builds or simulator captures in the kickoff.

<!-- verification-contract:start -->
| ID | Class | Source | Acceptance | Verification | Evidence | Status | Rationale |
| --- | --- | --- | --- | --- | --- | --- | --- |
| B12-001 | mechanical | user branch request | Milestone-named branches preserve the Beta 1.1 baseline and isolate Beta 1.2 | Git refs and remote readback | report:GitHub-rename-beta-1.1; report:beta-1.2-created-from-fb55281 | pass | Remote kickoff publication is checked after commit |
| B12-002 | mechanical | milestone 2 and issue 51 | Current scope and first source-backed boundary recorded without production claims | GitHub issue inventory and source inspection | report:twelve-open-issues; report:supply-audit-below | pass | Product implementation uses a subsequent standard contract |
<!-- verification-contract:end -->

<!-- fresh-review:start -->
| Reviewer | Required | Verdict | Evidence |
| --- | --- | --- | --- |
| constraint-auditor | no | not-applicable | Lightweight repository organization and intake; no runtime edits |
<!-- fresh-review:end -->

## Living Record

### Progress

Branch rename and local Beta 1.2 creation succeeded. First source audit located `GamePublicPileLevel`, `GamePhysicalTradeSurfaceView`, and `GameTabletopBankStackView`. Existing mapping uses H/M/L, not the requested Hi/Med/Lo. Resource capacity is 19: High starts at 13, Medium at 7, Low includes 0–6. Zero therefore currently needs an explicit exhausted presentation. Dev piles share the resolver with capacity 25; avoid accidentally changing unrelated Dev presentation.

Trade's requested-resource row converts `bankChips` into `GameHandChip` values. The shared chip control displays both selected quantities and exact availability, including in its accessibility value. Preserve local hand counts, selected Give/Get amounts and Core eligibility while separating public stock labels. `GameTabletopBankStackView` also renders exact counts when requested; trace its callers before deciding which surface changes.

### Next implementation boundary

Open a standard #51 child plan before editing UI, read all relevant component call sites and existing tests, and lock focused mapping/semantics tests plus representative high/medium/low/empty simulator states. Use existing typography and layout; if clarity requires a new composition, build a DEBUG comparison and obtain the existing owner visual approval before production routing. Do not treat this kickoff as visual approval.

## Validation and Outcome

The lightweight completion gate passed on 2026-10-21: contract validation, harness audit, whitespace and doc freshness. Existing unfinished plans produced expected audit notices. AGENTS.md and this execution record own the changed workflow/status facts. Product, design, architecture, decisions and QA facts are unaffected by this intake. No historical cleanup, product tests, simulator runs, signed candidate work or milestone acceptance in this slice.
