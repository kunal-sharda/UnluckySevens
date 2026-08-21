# Tutorial Language Redraft

## Purpose and Outcome

Rewrite the full sixteen-step tutorial in a conversational teaching voice whose visible coach marks carry every rule or action a sighted player needs. Record the complete proposal in the app-language audit, pause for owner approval, and only then synchronize the approved copy into production and verify all tutorial screens.

## Execution Settings

- Validation profile: `standard`
- Delivery posture: `checkpointed`
- Rationale: Tutorial wording is a meaningful player-facing UX change. The Markdown proposal is reversible, but productionization and screenshot validation must wait for the owner's explicit copy approval.

## Context and Boundaries

- [App Language Audit](../../design/app-language-audit.md) is the human editing worksheet; Swift remains runtime truth until approval.
- [UI Flows](../../product-specs/ui-flows.md) owns tutorial behavior, [Design](../../../DESIGN.md) owns the learning-surface language, and [QA](../../quality/qa.md) owns simulator proof.
- Visible coach marks must be understandable without the accessibility guidance. Accessibility guidance may add precision but cannot carry a rule omitted from visible copy.
- Preserve all sixteen lesson IDs, ordering, gameplay rules, production layouts, board geometry, valid tutorial pieces, and the locked typography contract.
- Do not alter production source, tests, or fixtures before the approval gate.

## Milestones / Plan of Work

1. Redraft every tutorial title, visible coach mark, accessibility guidance string, preview description, Strategy-card line, and navigation instruction in the Markdown worksheet.
2. Present the complete proposal to the owner and stop for approval or revisions.
3. After approval, synchronize production strings and copy-sensitive tests without changing gameplay or layout.
4. Run the focused copy/model tests and the seventeen-state tutorial simulator capture on the canonical iPhone 17 with iOS 26.5, inspect the contracted proof, and complete required reviews.

## Approval Gate

- Authority: solo owner
- Minimum honest proof: the complete sixteen-step Markdown proposal, including Strategy and navigation text
- Iteration budget: one consolidated proposal and up to two consolidated revision rounds
- Stop condition: production source, routine fresh review, and the completion gate remain blocked while `TLR-001` is pending
- Authorized after approval: production copy synchronization, focused tests, and the locked seventeen-state simulator proof

## Verification Contract and Fresh Review

<!-- verification-contract:start -->
| ID | Class | Source | Acceptance | Verification | Evidence | Status | Rationale |
| --- | --- | --- | --- | --- | --- | --- | --- |
| TLR-001 | judgment | user request | The owner approves one complete tutorial wording set before production changes | owner review of Markdown worksheet | report:owner-approved-2026-08-08 | pass | Owner approved the consolidated set plus the final connected-road and bought-card timing refinements |
| TLR-002 | mechanical | user request and app-language audit | Production tutorial strings and copy-sensitive tests exactly match the approved worksheet | focused source and test comparison | command:GameTutorialStepTests-pass-2026-08-08; file:MessagesExtension/Sources/Presentation/GameTutorialStep.swift; file:MessagesExtension/Sources/Features/Tutorial/GameTutorialStrategyCardView.swift; file:MessagesExtension/Sources/Features/Tutorial/GameTutorialView.swift | pass | Approved titles, guidance, callouts, preview descriptions, Strategy card, navigation, and UI-test expectations were synchronized; five focused model tests pass |
| TLR-003 | observable | user request and QA | All navigation plus sixteen lessons render legibly with no clipped or missing visible guidance on the canonical iPhone 17 simulator | focused seventeen-state XCUITest capture and artifact inspection | report:pending | pending | Blocked on TLR-001 |
| TLR-004 | mechanical | AGENTS.md | Canonical generation, focused tests, diff hygiene, and documentation freshness pass | repository commands | command:gen-pass; command:GameTutorialStepTests-pass; command:git-diff-check-pass; command:doc-freshness-pass; command:impeccable-detector-zero-findings | pass | Canonical generation, focused iPhone 17 iOS 26.5 test build, five model tests, detector, diff hygiene, and documentation freshness passed |
<!-- verification-contract:end -->

<!-- fresh-review:start -->
| Reviewer | Required | Verdict | Evidence |
| --- | --- | --- | --- |
| constraint-auditor | yes | pending | report:pending |
| product-ux | yes | pending | report:pending |
| accessibility | yes | pending | report:pending |
| architecture | no | not-applicable | Copy-only change does not affect module or protocol boundaries |
| behavioral | no | not-applicable | Gameplay rules and state transitions are unchanged |
<!-- fresh-review:end -->

## Relationship Notes

- Tutorial fixture legality and piece provenance are historical evidence in [Tutorial Piece Validity](../completed/tutorial-piece-validity.md); this plan owns wording and its remaining visual/readability proof only.

## Living Record

### Progress

- 2026-08-07: Locked the standard profile and checkpointed posture before the consolidated Markdown redraft.
- 2026-08-07: Recorded the complete sixteen-lesson, Strategy-card, and navigation proposal in the app-language audit. Production remains unchanged while owner approval is pending.
- 2026-08-08: Updated the proposed Strategy card with owner-specified Longest Road (5+), Largest Army (3+), and plain-language scoring copy. The full-set approval gate remains open.
- 2026-08-08: Owner approved the full wording set with two final precision edits. Synchronized the approved audit into the tutorial step model, Strategy card, navigation veil, and affected UI-test expectations.
- 2026-08-08: Canonical generation passed. The focused iPhone 17 iOS 26.5 test initially found one stale capitalization assertion, then passed all five `GameTutorialStepTests` after the narrow assertion correction. The Impeccable detector, doc freshness, and diff hygiene passed.

### Decisions

- 2026-08-07: Visible coach marks are the primary tutorial. They must stand alone because most players will not encounter the accessible guide.
- 2026-08-07: Step 1 ends with `Round two goes in reverse order.`
- 2026-08-08: Final visible wording uses `connected to your settlement` and `Bought cards wait until next turn.`

### Discoveries

- 2026-08-07: Standard coach bubbles are 174 by 68 points with a three-line limit. Trade bubbles are 154 by 46 points with a two-line limit. Large accessibility sizes use a separate guide with four-line coach marks.

## Validation and Outcome

- Automated: canonical generation and five focused `GameTutorialStepTests` passed on iPhone 17 with iOS 26.5; the relevant SwiftUI sources and UI-test target compiled.
- Simulator: no screenshot journey run in this bounded implementation turn; `TLR-003` remains pending.
- Judgment: owner wording approval passed; final product/UX and accessibility reviews remain pending until observable proof exists.
- Documentation: approved worksheet and active plan updated; `make doc-freshness` and `git diff --check` passed.
- Deferred: the seventeen-state tutorial screenshot inspection, required fresh reviews, and completion gate.
