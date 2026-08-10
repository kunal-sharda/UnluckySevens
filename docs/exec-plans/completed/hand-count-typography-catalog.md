# Hand Count, Typography, and Full Screen Catalog

## Purpose and Outcome

Show the local player's total resource-card count on the fixed Hand prop, reconfirm the shared SF Pro typography contract across all production source, clean current owner documentation, and regenerate a complete simulator catalog of every canonical player-facing state including the in-place Games switcher.

## Execution Settings

- Validation profile: `standard`
- Delivery posture: `direct`
- Rationale: the Hand-count direction is settled, typography is already locked, and the complete catalog is a repeatable validation lane. This is a meaningful UI slice with device evidence and fresh review.

## Context and Boundaries

- `DESIGN.md` owns typography and the physical Hand treatment; `docs/product-specs/ui-flows.md` owns player-facing behavior; `docs/quality/ux-lab.md` owns capture routing.
- “Number in Hand” means the total local resource-card count appears on the fixed Hand prop before the hand is opened. Per-resource counts remain on the opened cards.
- All player-facing interface text uses OS-provided SF Pro through system APIs. The geometry-bound board number token remains the sole New York/serif exception; `monospacedDigit()` remains permitted for changing counts.
- Core rules, secrecy, transport, protocol, and board geometry remain unchanged.
- Catalog evidence comes from the checked-in XCUITest/UX Lab routes on the installed iPhone simulator build.

## Milestones / Plan of Work

1. Add the total resource-card count to the Hand prop with semantic SF typography and accessible card-count state.
2. Extend focused coverage and the canonical catalog route for the count and in-place Games state.
3. Clean current owner docs and reconfirm the all-source typography guard.
4. Generate, build, install, run every canonical catalog route, assemble and inspect all screenshots and the review document.
5. Run fresh reviews, documentation freshness, and the standard completion gate.

## Verification Contract and Fresh Review

<!-- verification-contract:start -->
| ID | Class | Source | Acceptance | Verification | Evidence | Status | Rationale |
| --- | --- | --- | --- | --- | --- | --- | --- |
| HCT-001 | observable | user request | The fixed Hand prop shows the local player's total resource-card count and the opened hand retains per-resource counts | focused XCUITest and installed-device screenshots | report:hand-model-13-pass; artifact:screen-28 | pass | Passing model/UI coverage and rendered screen 28 show total 25 plus five per-resource counts of 5 |
| HCT-002 | mechanical | `DESIGN.md` | Every production interface source uses SF Pro, with only the locked board-number serif exception | repository typography guard and detector | report:harness-and-detector-pass | pass | Source-wide guard, 21 harness-audit tests, and final Impeccable type detector pass |
| HCT-003 | observable | user request and QA | Every canonical player-facing root and nested state, including inline Games, is represented in a fresh device catalog | serial XCUITest routes, attachment manifest, contact sheet, and rendered document inspection | artifact:53-screen-contact-sheet-and-54-page-pdf | pass | All 53 named states are represented; clean recovery captures come from a passing three-test result and City comes from the retained passing full-turn route |
| HCT-004 | mechanical | AGENTS.md | Owner docs, canonical generation, build, diff hygiene, doc freshness, and the standard completion gate pass | repository gates | report:generation-build-diff-doc-gates-pass | pass | Canonical generation, installed-app build, diff hygiene, doc freshness, reviews, and pre-completion checks pass; completion gate is the final confirmation |
<!-- verification-contract:end -->

<!-- fresh-review:start -->
| Reviewer | Required | Verdict | Evidence |
| --- | --- | --- | --- |
| constraint-auditor | yes | pass | HCT-001–003 pass; latest strict Game Info-to-City sequence remains explicitly recorded as an unresolved follow-up |
| architecture | no | not-applicable | Presentation-only count and capture changes do not alter runtime boundaries |
| behavioral | yes | pass | Separate passing City device evidence makes the 53-state catalog complete; strict sequence regression remains a declared follow-up |
| product-ux | yes | pass | 54-page PDF and 53-screen contact sheet verified; recovery screens are clean and duplicate scan found none |
<!-- fresh-review:end -->

## Living Record

### Progress

- Confirmed the existing static typography guard recursively scans every Swift file under `MessagesExtension/Sources`.
- Confirmed the current Hand prop has no total-count state even though its opened resource cards show per-resource counts.
- Implemented the total Hand count as a standalone capsule above the fixed physical fan, with numeric accessibility state and a model-level total-count assertion.
- Expanded the typography guard to every production interface root (`App/Sources` and `MessagesExtension/Sources`) and removed the deprecated PRODUCT register field.
- Generated a 53-screen contact sheet and 54-page PDF, then rendered representative pages back to PNG for visual inspection.

### Decisions

- 2026-07-31: Present the total as a compact count badge on the physical Hand card fan and expose “N resource cards” through accessibility. This keeps the fixed `Hand` anchor and does not add another label role.

### Discoveries

- The previous complete catalog predates the in-place Games switcher; the refreshed catalog must include both Game Information modes instead of reusing the old artifact.
- The Messages host replaces a selected SwiftUI button's custom accessibility value with selected-state data. The Hand therefore includes its count in the spoken label (`Hand, N resource cards`) while retaining the same visible count treatment.
- The first full-resolution Hand capture exposed overlap when a two-digit total was drawn inside the narrow center card. The total now uses a standalone capsule badge above the fan so every digit stays visible without widening or moving the rail.
- The earlier catalog did not retain Rules or the major recovery decision surfaces. The refreshed catalog adds Rules, resign confirmation, host-end choice, dedicated Games, and neutral host-end evidence to the canonical gameplay set.
- Back-to-back catalog routes exposed a DEBUG harness race: requesting the clean lobby set `selectedState` to nil while disabling UX Lab ownership, allowing the ledger selection poll to restore the previous game immediately. Clean lobby now keeps UX Lab active with an intentionally nil state, preventing cross-route state leakage without affecting Release.
- Catalog routes may intentionally finish with debug chrome hidden. The shared entry helper now recognizes the existing `Show UX Lab` restore control before looking for the normal toggle, so the next route does not depend on prior chrome state.
- The counted Hand accessibility label required the discard-wait journey to match `Hand, N resource cards` rather than the retired exact `Hand` label. The recovery helper also now waits a full transition window before retrying Games, preventing a successful first tap from being toggled back to Players.
- Direct recovery fixtures now hide DEBUG chrome before capture. The final Games/recovery pages were recaptured from a passing three-test result and contain no `States` or `UX Lab` controls.
- The current combined full-turn route passes and contributes 14 fresh active-turn captures. Its City step may be unavailable after the Game Information Games/Players sequence, while core fixture legality still passes; the catalog therefore retains the separate passing City target capture and records the strict sequence regression instead of concealing it.

## Validation and Outcome

The Hand prop now exposes a legible total count and the open hand retains resource-by-resource counts. The production-source typography guard and detector pass with the locked board-number exception intact. The final catalog contains 53 named player-facing screenshots, a clean contact sheet, and a rendered 54-page PDF. Canonical generation, simulator build/install, focused tests, all required reviews, diff hygiene, and doc freshness pass.

Known follow-up: the strict Game Information → Games → Players → Build → City regression remains sequence-sensitive even though the core City legality test and the retained passing City device route both pass. It does not remove the represented City state from this catalog, but it should remain visible as harness/product debt.
