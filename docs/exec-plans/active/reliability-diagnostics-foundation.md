# Local reliability diagnostics foundation

## Purpose and Outcome

Implement the settled mechanical foundation of #44 so #43 and #47 can later collect bounded, privacy-safe observations. This is an in-memory buffer and export projection, not finished field diagnostics. No collection hooks, disk persistence, export UI or upload ships from this slice.

## Execution Settings

- Validation profile: `standard`
- Delivery posture: `direct`
- Rationale: Typed local data/retention is settled; export UI keeps its separate owner checkpoint. No gameplay, protocol, or rules change.

## Context and Boundaries

Parent: [marketable release plan](marketable-release-plan.md), issue #44. Preserve existing dirty fixes. Allow only schema version, event sequence, timestamp, SHA-256 domain-separated game token, revision, typed action/boundary/outcome and actor-membership classification. No raw game IDs, participant IDs, names, hand counts/resources, trade contents, free-form errors or installation identifiers. Correlation is game-scoped, not a credential or anonymous-privacy claim. Default retention: 128 records, 24 hours (lazy pruning on append/export, no idle timer); export one game only, max 64 KiB. Consecutive identical observations within one second coalesce. Clear discards everything. Clock rollback/future entries and expired records are discarded. Schema rejects unknown enum values by construction (no decoding/import interface).

## Milestones / Plan of Work

1. Implement typed correlation/event/buffer and bounded single-game export.
2. Add focused adversarial tests for allowlist, bounded retention, expiry/clock rollback, coalescing, clear, isolation and output size.
3. Run canonical generation, focused MessagesExtension tests serially, baseline build, fresh constraint/privacy review, doc freshness and completion gate.

## Verification Contract and Fresh Review

<!-- verification-contract:start -->
| ID | Class | Source | Acceptance | Verification | Evidence | Status | Rationale |
| --- | --- | --- | --- | --- | --- | --- | --- |
| DF-001 | mechanical | issue 44 privacy scope | Schema exports only typed allowlisted fields and game-scoped correlation, excluding unrelated games and raw inputs | focused schema/export tests and source review | report:7 focused tests passed; scoped privacy/source review passed | pass | No free-form logging |
| DF-002 | mechanical | issue 44 retention | Count/age/size bounded; coalescing, clear and rollback behavior deterministic | focused tests | report:7 focused tests passed including expiry, rollback, coalescing and bounds | pass | Local buffer cannot grow without bound |
| DF-003 | mechanical | approved foundation scope | No gameplay mutation, persistence, upload or collection hooks; build/tests/review/docs pass | source review and completion gate | report:focused test build passed; no call sites/I-O; architecture/QA owner docs updated; scoped review passed | pass | Do not claim field diagnostics shipped |
<!-- verification-contract:end -->

<!-- fresh-review:start -->
| Reviewer | Required | Verdict | Evidence |
| --- | --- | --- | --- |
| constraint-auditor | yes | pass | report:review_diagnostics_foundation scoped source/test review passed |
| privacy | yes | pass | report:review_diagnostics_foundation allowlist/correlation review passed; lazy expiry wording corrected |
<!-- fresh-review:end -->

## Living Record

2026-09-14: Locked standard/direct and exact proof set above before implementation. Focused tests only for this model, baseline build, fresh review and completion gate; no simulator UI, hardware, existing flaky catalogs or protocol tests required because there are no UI/hooks/protocol changes. Hardware-blocked parent acceptance remains pending separately.

## Validation and Outcome

Foundation slice complete; #44 remains open. Remaining #44 work: disk retention/corrupt recovery, observed boundary instrumentation, build/OS metadata, preview/export UI approval and implementation, disclosure review, and sender/recipient evidence. #43/#47 causes are unconfirmed.

2026-09-14: Focused generated-workspace test run passed 7/7 with zero failures in `/tmp/uls-diagnostics-foundation-tests.xcresult`; test log confirms exact selected suite, no UI or physical journey. Source/privacy review passed; expiry docs clarified as lazy pruning on append/export. Architecture and QA owner docs updated; product/visual/rules/protocol docs intentionally unaffected. Standard completion gate is next. An additional read-only xcresult summary command was sandbox-denied when its cache tried to write; the xcodebuild log already contains exact suite/test-count evidence, so no test rerun is needed.

Final standard completion gate passed on 2026-09-14 (contract, harness audit, whitespace, doc freshness, canonical generation and baseline build). No gameplay UI, device, release or network behavior was exercised or changed. Existing dirty work preserved. Next bounded #44 slice is persisted retention/corrupt recovery and approved boundary hooks; preview/export composition requires its checkpoint before productionization.

2026-09-20 handoff: the independent [storage slice](reliability-diagnostics-storage.md) now supplies validated persistence, reopen pruning, corruption recovery and clear/error behavior, with 15 focused tests and the standard gate passing. Production directory/lifecycle wiring, collection hooks, build/OS metadata and preview/export remain unimplemented; the parent #44 device/disclosure acceptance stays open.
