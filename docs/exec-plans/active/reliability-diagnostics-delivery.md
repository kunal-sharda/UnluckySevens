# Reliability reports and participant comparison

## Purpose and Outcome

Implement the user-authorized next step for #44: release-available local collection, a preview/export flow, and an offline comparison of independently obtained participant reports. Friends perform the taps; machines check candidate/game/revision/state agreement. This is not an upload, automatic receipt service, or closure of #8.

## Execution Settings

- Validation profile: `standard`
- Delivery posture: `direct`
- Rationale: User delegated the diagnostic delivery path. Reuse bounded storage and existing Settings navigation; no competing redesign or gameplay changes.

## Context and Boundaries

Preserve unrelated dirty work. Core/Transport remain unchanged. Reports exclude names, contacts, raw participant/game/session IDs, hands/cards/resources, payloads, arbitrary errors and unrelated games. Add only a game-scoped digest of canonical state, typed host trigger/session presence and build/OS/configuration metadata. Persist the existing 128-record/24-hour/64-KiB boundary; cap the entire report at 64 KiB by trimming oldest records. Capture validated received/selected state separately from local encoding/handoff, and never turn send completion into remote delivery. Tutorial/UX fixtures must be marked synthetic or excluded from real evidence. Diagnostics must not gate or mutate gameplay. Exports preview the exact immutable JSON bytes and happen only through user action; clear failure is visible. No automatic upload.

Use Settings → Reliability Report for the currently open game, available in lobby/game and Release. Empty/unavailable states remain explicit. Export uses system file export; closing/canceling never sends. Candidate identifier defaults to unfrozen until a release preparation command supplies the exact candidate; no guessed TestFlight distribution. Report comparison rejects malformed/oversized/private fields, duplicate files, different games/candidates, mismatched revision/hash, synthetic evidence and missing selected-state observations. Separate-account attribution is explicit operator attestation, never inferred from file count.

## Milestones / Plan of Work

1. Implement collection/report projection and schema-focused tests atop existing storage.
2. Wire validated selection and local publication boundaries, add Settings preview/export/clear.
3. Implement offline participant comparison with adversarial tests and a synthetic success fixture clearly labeled as tool-only proof.
4. Run focused Swift/Python tests, one bounded Settings report XCUITest plus inspected screenshots, Release compile, fresh privacy/behavior/UX review, owner-doc updates and standard gate.

## Verification Contract and Fresh Review

<!-- verification-contract:start -->
| ID | Class | Source | Acceptance | Verification | Evidence | Status | Rationale |
| --- | --- | --- | --- | --- | --- | --- | --- |
| DR-001 | mechanical | #44 | Typed private bounded collection and immutable single-game report; failure never changes game | focused diagnostic suites and privacy/source review | report:20 focused Swift tests passed in /tmp/uls-diagnostics-delivery-tests-v3.xcresult; scoped privacy/source review pass | pass | Reuse storage foundation |
| DR-002 | mechanical | user comparison request | Strict comparison requires candidate and independently attributed matching selected-state evidence; no send callback receipt claim | Python adversarial tests; fixture handoff | report:8 adversarial Python tests passed | pass | Tool checks reports, not account ownership |
| DR-003 | observable | #44 | Settings report preview, close, clear/empty and export entry are usable with accessible labels | one focused simulator catalog and inspected attachments | artifact:output/ui-screenshot-harness/20260923T153806Z-iphone; report:1/1 report journey passed and three screenshots inspected | pass | System export completion on real device remains separately scoped |
| DR-004 | mechanical | #44; AGENTS | Production hooks and Release screen compile, docs and standard baseline pass | Release build; source audit; completion gate | artifact:/tmp/uls-reliability-release-v3.log; report:final Release build passed; standard baseline enforced by completion gate | pass | Final gate result recorded below |
<!-- verification-contract:end -->

<!-- fresh-review:start -->
| Reviewer | Required | Verdict | Evidence |
| --- | --- | --- | --- |
| constraint-auditor | yes | pass | report:independent final raw xcresult, source and screenshot review passes frozen scope; mechanical Release/gate evidence recorded separately |
| privacy/behavior | yes | pass | report:independent source re-review and raw 20-test Swift log inspected; no remaining source blockers |
| product-ux | yes | pass | artifact:output/ui-screenshot-harness/20260923T153806Z-iphone; report:independent inspection of preview, contents, clear and test cancellation path |
<!-- fresh-review:end -->

## Living Record

2026-09-22: User authorized implementing diagnostics/export/comparison after agreeing friends can supply manual independent-account participants. Existing foundation/storage are tested; no production hooks exist. Exact proof locked above. Allow at most two corrected UI runs after evidence-based diagnosis for this new report journey, not a reset of prior lifecycle budgets. TestFlight installation, actual participant reports, privacy-policy publication and paired-device export remain subsequent release acceptance of #44, not mock success.

2026-09-22 implementation: collection records validated decoded selections and local encoding/send-handoff separately. Reports add game-scoped state digest, typed trigger/session-presence and binary metadata. Settings uses system file export of frozen preview bytes; no automatic upload. Comparator requires explicit candidate/version/build/revision/checkpoint and operator-attested separate accounts. Eight Python tests passed. Initial compilation succeeded; new focused Swift test compile found missing dice RNG fixture argument, corrected before rerun (no runtime test executed). Apple send(MSMessage) symbol contract confirms completion is start-of-send, not remote receipt.

2026-09-22 review correction: snapshot provenance now binds persisted records to version/build/candidate/configuration; changed identity drops old history instead of relabeling it. Added upgrade regression. Also record unavailable/failed selection against existing active context when payload or validation fails; comparator already refuses any later nonaccepted selection instead of falling back to older success. These correct exact-candidate/fresh-checkpoint constraints, not a new gameplay workstream.

2026-09-22 Swift validation infrastructure: v2 compiled but XCTest stalled before loading its test bundle. One-second stack sample shows Foundation directory-open during bundle loading, no product test executed. Interrupted only this invocation after approximately three minutes. Corrected serial attempt relocates DerivedData from Documents workspace to /tmp, including latest provenance correction. This is the one diagnosed infrastructure retry, not a product-test failure or UI retry. Stop if bundle startup repeats.

2026-09-22 corrected temporary-directory Swift run passed 20/20 with zero failures. Source/privacy review accepted provenance fix and documented boundary limitations. Single report UI catalog running under output/ui-screenshot-harness/20260923T053351Z-iphone; no screenshot verdict yet.

UI attempt 1 stopped before report navigation: observed lobby hierarchy assigns the Settings button the inherited tableSurface identifier, with its exact Settings summary label. Screenshot confirms visible button. Corrected only this new test to select that observed identifier plus exact label, requiring one hittable match. Attempt 2 is the first of two allowed corrected reruns.

UI attempt 2 opened Settings, then failed because the global first ScrollView was an offscreen Messages control. Exported hierarchy confirms one nested Settings ScrollView. Correct the new test to scope Settings scrolling to that surface and report scrolling to the report surface. Attempt 3 is the final allowed corrected UI run; stop and record unverified if it fails.

UI attempt 3 failed at new test line 66: report-entry hittability after three Settings-scoped swipes. Screenshot still shows top Settings content; no report preview/export/clear proof was reached. Raw test details and screenshot are under output/ui-screenshot-harness/20260923T054028Z-iphone/failures/testReliabilityReportPreviewAndCancel. The initial plus two corrected UI runs are exhausted; stop UI retries. This is unresolved navigation/accessibility evidence, not an assertion that export works. Independent Release compilation proceeds without another simulator run.

Fresh final audit inspected attempt-3 summary/details and simulator screenshot: Settings opened; no visible report entry, so preview/export/cancel/clear remain unverified. Evidence does not distinguish gesture/harness failure from product reachability. Constraint and UX verdict blocked; privacy/behavior source verdict pass. No additional UI attempts.

Final independent validation: unsigned generic-device Release build succeeded (/tmp/uls-reliability-release.log), canonical generation performed in the same sequence. Built extension retains candidate unfrozen; no archive/upload/install performed. Completion gate was run and correctly stopped on blocked DR-003 before baseline build. Doc freshness and whitespace checks pass. Implementation remains unverified end-to-end; issue #44 stays open. Owner docs updated: architecture, UI flows, QA/report guide. Existing design language, locked decisions, protocol/Core rules and historical docs intentionally unchanged by this slice.

2026-09-23 user-authorized continuation: user explicitly requested diagnosing/fixing the blocked navigation. Runtime drawer snapshot identifies two equally named installations: obsolete com.unluckysevens.app.messagesextension and current me.ksharda.games.unluckysevens.messagesextension. Existing harness picks first display-name match; retained Settings has no report or privacy row, despite current built debug dylib containing report strings. Classify prior UI evidence as wrong-target harness evidence, not product reachability. Correct shared drawer helper to use observed exact current extension identifier (no display-name fallback). Preserve both installations so the rerun exercises disambiguation. Permit three additional diagnosed attempts, numbered 4–6 globally (under QA ceiling), for the unchanged report journey. Standard/direct and evidence requirements unchanged; source/profile unit proofs reused because production data code is unchanged. Run canonical harness, inspect preview/cancel/clear, fresh audit, doc freshness and completion gate. No TestFlight/device install or upload.

Attempt 4 failure: XCUITest exposes bundle identity on the drawer Cell, whereas runtime snapshot tools normalize it as a text target. Exported hierarchy confirms both bundle IDs in separate cells. The old Stickers-containing collection query also disappears after scrolling Stickers offscreen. Correct to exact bundle Cell and the observed popover collection; attempt 5 retains the same report journey. No production changes.

Attempt 5 reached report surface (line 69 passed), then failed export hittability (line 74). Source confirms Invitation calls activateCleanLobbyInviteEntry and clears selectedState intentionally, so no report is valid there; the test expected export from a no-game state. Correct test setup to existing Ready fixture with selected canonical game. Empty synthetic records remain excluded from real comparison. Retain report hierarchy before export to diagnose any further issue. Attempt 6 is final authorized continuation run.

Attempt 6 reaches preview and system file picker; assertion fails only because Cancel is Other in exported AX, not Button. No export runtime failure demonstrated. Correct exact label + observed type. Inspected preview shows black navigation title against dark green; scoped readability fix sets dark navigation-bar color scheme and explicit background (DR-003 accessibility acceptance). Add contracted exact-contents screenshot while preview scrolled. User continuation is diagnosis-driven: replace the self-imposed three-run continuation estimate with QA's existing hard ceiling of initial plus ten (attempts remain globally numbered, six consumed). This is not a reset; no unchanged reruns. Attempt 7 checks observed picker Cancel and clear. Recompile Release for toolbar-only change; unchanged diagnostics unit proofs reused.

Attempt 7 failed before extension launch: retained screenshot/hierarchies remain ConversationList, but openExistingConversation returned after tapping a label without verifying navigation. Correct to the observed known-conversation Cell in ConversationList and assert its composer add button before continuing; the new known-cell branch fails immediately if it remains in the conversation list (legacy fallback branches remain outside this correction). Attempt 8 stays within initial-plus-ten QA ceiling. Report flow/toolbar changes were not exercised on attempt 7.

Attempt 8 reached preview and contents with corrected contrast. It failed waiting for picker Cancel; failure hierarchy shows report still open, no picker. Unlike successful picker entry in attempt 6, newly added contents capture introduced scroll-down/up immediately before export tap. Remove this unnecessary detour: retain contents screenshot during the already required clear-scroll after picker cancellation. Reuse observed Cancel selector. Attempt 9 does not change production UI or add retries within a run.

Attempt 9 picker entry succeeds. Observed host Other/Cancel has exactly the same frame as remote picker More; tapping it opens More menu, not cancellation. Screenshot confirms More menu. Correct harness to cancel via the visible system sheet dismissal gesture, anchored to observed FullDocumentManagerViewControllerNavigationBar; require picker disappearance before any report interaction. No app-side workaround, no save/share. Attempt 10 retains cancellation semantics and no-send contract.

Attempt 10 proves picker dismissal and return to report; final empty assertion fails with confirmation Sheet still present. Original immediate global button query can select underlying clear trigger before sheet presentation. Scope confirmation to observed Sheet and wait for appearance/disappearance. Attempt 11 is the hard QA final run; no further retry if this fails. Transient direct simulator still showed spinner but raw result establishes execution reached final assertion; do not classify this run as launch failure.

2026-09-23 final report UI passed on attempt 11 (hard ceiling, no further runs). Clean evidence output/ui-screenshot-harness/20260923T153806Z-iphone: Settings entry, immutable preview, file-picker entry/dismissal, return, confirmed clear/empty; three screenshots inspected. Root blocker was obsolete same-name extension selection, followed by incorrect no-game fixture and unscoped system-control assertions. Report toolbar contrast corrected. Synthetic records remain empty/unfrozen, not real delivery proof. Final Release/gate/reviewer status below.

Final unsigned Release rebuild passed after toolbar correction: /tmp/uls-reliability-release-v2.log. No data collector changes since 20 Swift / 8 Python test proof. No TestFlight upload, physical install, candidate freeze, or ticket closure.

Fresh reviewer passed scoped UX and constraint audit after directly inspecting final 1/1 xcresult, manifest, all three screenshots and assertions. Light toolbar, exact JSON, picker cancellation and confirmed clear meet frozen scope. Physical file saving, independent reports, TestFlight and expanded accessibility profiles remain unclaimed.

Final gate found sourced DESIGN.md typography violation in JSON Text: SF Mono is disallowed. Correct to semantic SF Pro caption; no report bytes, controls, identifiers or flow changed. Existing 1/1 UI behaviour proof retained, screenshots predate only this font-family correction (no claim that they show final JSON font). Fresh source/design review plus harness typography audit and final compile validate the mechanical style correction. UI retry ceiling remains exhausted; no additional journey run. Rerun final Release/gate for changed source.

Final font correction source/design review passed: semantic caption satisfies DESIGN.md; existing UI run supports unchanged behavior, while final glyph wrapping is not recaptured. Release v3 and standalone harness/typography audit passed. Prior failed gate superseded only after this sourced correction.

2026-09-23 standard completion gate passed after typography correction: /tmp/uls-reliability-completion-gate-v2.log. Contract, independent reviews, harness audit, whitespace, doc freshness, canonical generation and baseline simulator build passed. This closes the bounded local implementation/verification slice, not all #44 acceptance. Owner docs updated: QA/report guide and active delivery/release plans; earlier architecture/UI-flow updates remain accurate. DESIGN/decisions/Core/Transport contracts unchanged; historical docs intentionally untouched. Final screenshots predate only the mechanical JSON font-family correction, reviewed separately.
