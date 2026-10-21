# Local reliability diagnostics storage

## Purpose and Outcome

Advance [issue #44](https://github.com/kunal-sharda/UnluckySevens/issues/44) without physical devices: add bounded device-local persistence and corruption recovery to the existing typed diagnostic foundation. Parent: [foundation](reliability-diagnostics-foundation.md). This slice does not claim field collection, UI export, or ticket closure.

## Execution Settings

- Validation profile: `standard`
- Delivery posture: `direct`
- Rationale: Settled mechanical storage boundary; user authorized iPad-free Beta 1.1 work. Export UI location is a separate pending question and will not block this independent slice.

## Context and Boundaries

Preserve unrelated dirty work. Diagnostics stay in MessagesExtension, outside Core/Transport and canonical state. Preserve the existing typed allowlist, game-scoped correlation, 128-record/24-hour limits, 64-KiB ceiling and single-game export. Store only this schema, atomically in a caller-supplied local directory; production collection wiring is deferred. No networking, account identifiers, UI or automatic upload. Corrupt/oversized/unknown-version data is discarded. Non-finite or future/expired records cannot survive restore. Storage failures return typed status and leave in-memory diagnostics usable; no raw error strings enter records. Clear empties memory and attempts deletion, reporting failure honestly.

## Milestones / Plan of Work

1. Add versioned bounded restore/snapshot and local store with atomic persistence, lazy pruning and clear.
2. Add focused tests for reopen, adversarial schema/corruption, age/size/count limits, isolated export, clear and I/O failure.
3. Run canonical generation, selected diagnostic unit suites, fresh constraint/privacy review, owner-doc updates and standard completion gate.

## Verification Contract and Fresh Review

<!-- verification-contract:start -->
| ID | Class | Source | Acceptance | Verification | Evidence | Status | Rationale |
| --- | --- | --- | --- | --- | --- | --- | --- |
| DS-001 | mechanical | #44 privacy and retention | Restored schema remains typed, versioned, bounded and excludes raw/private data; export includes only requested game | diagnostic buffer/store tests; source/privacy review | artifact:/tmp/uls-diagnostics-storage-final-tests.xcresult; report:15 focused tests passed | pass | No new untyped data channel |
| DS-002 | mechanical | #44 storage recovery | Reopen, expiry, corruption, oversize, clear and failed writes have deterministic safe behavior | temporary-directory diagnostic store tests | artifact:/tmp/uls-diagnostics-storage-final-tests.xcresult; report:8 filesystem store tests passed | pass | Actual filesystem boundary exercised without hardware |
| DS-003 | mechanical | user iPad-free request; architecture | No gameplay, transport, collection or UI hooks; docs and standard baseline pass | scoped source review; make completion-gate PLAN=docs/exec-plans/active/reliability-diagnostics-storage.md | report:scoped source review; command:make doc-freshness passed; command:git diff --check passed | pass | No hooks or UI; standard baseline is enforced by completion-gate below |
<!-- verification-contract:end -->

<!-- fresh-review:start -->
| Reviewer | Required | Verdict | Evidence |
| --- | --- | --- | --- |
| constraint-auditor | yes | pass | report:review_storage independently inspected sources/tests/owner docs and final raw 15-test log; DS-001/002 pass, DS-003 source/docs pass; gate follows |
| privacy | yes | pass | report:review_storage typed allowlist, bounded read/restore, game isolation, no hooks/upload; no remaining findings |
<!-- fresh-review:end -->

## Living Record

2026-09-20: Locked standard/direct before code changes. Exact proof: existing buffer suite plus new store suite through generated MessagesExtensionTests, source/privacy review, doc freshness, standard gate. No UI or device proof is required for this unconnected storage component. One diagnosed retry for infrastructure failure; stop on repeated failure. Existing session UI retry ceiling is unchanged.

2026-09-20: Implemented snapshot validation and a single-owner store with bounded FileHandle reads, atomic protected writes, backup exclusion, restore pruning, typed failure status and explicit clear. Mandatory source/privacy review found an existence-check ambiguity under denied filesystem access; replaced existence probes with direct read/delete and added real permission-failure coverage. Canonical generation required normal cache access outside the workspace sandbox and succeeded after escalation. Doc freshness and whitespace checks passed. Focused tests pending; no lifecycle UI retries were used.

## Validation and Outcome

Focused final run passed 15/15 tests (7 buffer, 8 store) with zero failures in `/tmp/uls-diagnostics-storage-final-tests.xcresult`; raw output is `/tmp/uls-diagnostics-storage-final-tests.log`. The earlier 14-test run passed but is superseded by the corrected permission-failure coverage. Fresh constraint/privacy review passed after independently opening source, tests, owner docs and the final raw test log. The standard completion gate passed (exit 0), including contract validation, harness audit, whitespace, doc freshness, canonical generation and baseline extension build; output: `/tmp/uls-diagnostics-storage-gate.log`. This bounded storage slice is complete. #2/#4/#6/#8/#11/#15 retain distributed-build/physical acceptance; #43/#47 causes are unconfirmed. #44 storage is the selected independent deliverable. No existing ticket is closed by this slice.

Doc freshness: ARCHITECTURE.md and docs/quality/qa.md updated for storage ownership and proof; this plan and the foundation handoff updated. Product, design, decisions, protocol, and release documentation are intentionally unaffected because there is no production wiring or UI change. No historical cleanup required. No physical-device, Messages UI, release, or recipient-delivery validation ran. UI-location question remains unanswered; preview/export work is not implemented by this storage slice.
