# Tech Debt Tracker

Track only durable debt that is worth revisiting. Do not use this file for scratch tasks or ephemeral cleanup notes.

## Format

- `ID`
- `Title`
- `Area`
- `Why it matters`
- `Current cost or risk`
- `Proposed fix shape`
- `When to address`
- `Links`

## Open Debt

### TD-001 — No transcript-level automated Messages UI checks

- Area: `MessagesExtension`, QA
- Why it matters: the engine is well covered, but transcript selection and host-extension behavior still rely on manual smoke checks.
- Current cost or risk: regressions in bubble selection, session behavior, or app-extension handoff may be caught late.
- Proposed fix shape: add simulator-oriented transcript smoke harnesses before investing in real-device automation.
- When to address: phase 10 or immediately after the first real UI shell lands.
- Links: [QA](/Users/kunalsharda/Documents/Code/UnluckySevens/docs/quality/qa.md)

### TD-002 — No production board snapshot coverage yet

- Area: board UI, transcript bubble rendering
- Why it matters: the bubble is a first-class product surface, but there is no stable snapshot regression layer for the future board renderer yet.
- Current cost or risk: visual regressions may slip through even when engine tests are green.
- Proposed fix shape: add snapshot fixtures and snapshot-oriented harnesses alongside the SpriteKit board work.
- When to address: phase 11.
- Links: [README](/Users/kunalsharda/Documents/Code/UnluckySevens/README.md)

### TD-003 — `MessagesExtension` still needs feature-level internal decomposition

- Area: UI architecture
- Why it matters: the engine boundaries are clean, but the extension target is still vulnerable to becoming monolithic during phase 10 work.
- Current cost or risk: slower UI iteration, duplicated presentation logic, and harder reviewability.
- Proposed fix shape: split the extension internally by feature, presentation, board, components, and debug surfaces.
- When to address: phase 10.
- Links: [ARCHITECTURE.md](/Users/kunalsharda/Documents/Code/UnluckySevens/ARCHITECTURE.md)

### TD-004 — `MessagesExtensionTests` duplicates selected extension sources

- Area: build/test architecture
- Why it matters: Xcode dependency scanning recognizes that the tests import `MessagesExtension`, but Tuist does not allow a direct unit-test dependency on an iMessage extension target in the current project shape.
- Current cost or risk: the workspace test lane emits a persistent warning, and the duplicated-source setup makes future test architecture changes easier to get wrong.
- Proposed fix shape: extract the testable presentation/board seams into a shared library target the extension and tests can both depend on, then remove the duplicated extension sources from the test target.
- When to address: after phase 12 gameplay flows are stable, before deeper UI expansion makes the duplicated-source pattern more expensive.
- Links: [ARCHITECTURE.md](/Users/kunalsharda/Documents/Code/UnluckySevens/ARCHITECTURE.md), [Phase 12 Plan](/Users/kunalsharda/Documents/Code/UnluckySevens/docs/exec-plans/active/phase-12-gameplay-flows.md)
