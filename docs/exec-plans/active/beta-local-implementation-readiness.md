# Beta 1.1 local implementation readiness

## Purpose and Outcome

2026-10-21: user requests that all Milestone 1 implementation be checked and finished before they perform device testing. This is the local implementation slice of [testing and candidate delivery](testing-streams-implementation.md), not milestone closure or distribution readiness. Preserve existing uncommitted work.

## Execution Settings

- Validation profile: `standard`
- Delivery posture: `direct`
- Rationale: explicitly delegated implementation audit and repairs; physical acceptance and signing/distribution remain separate.

## Context and Boundaries

Milestone 1 is Beta 1.1: #2, #4, #6, #8, #11, #15, #43, #44, #47, #49, #50. Audit existing code against issue acceptance and owner docs; repair demonstrated defects and finish bounded action diagnostics. Do not invent the cause of intermittent remote delivery or new-phone hand symptoms. Preserve Core/Transport boundaries, existing protocol and standard rules. The user owns subsequent real-device testing; no live messages or device installs in this slice.

## Milestones / Plan of Work

1. Audit all eleven issues and record local implementation versus remaining human proof.
2. Finish action-specific eligibility/recovery diagnostics and repair concrete review findings with regressions.
3. Run serial local proof, required independent review and completion gate; provide a focused tester checklist.

## Verification Contract and Fresh Review

Locked proof: full Core tests/evals, Transport tests, extension unit tests after canonical generation, Python harness/comparator tests, unsigned Release build/package inspection, existing simulator evidence for unchanged UI paths, fresh behavioral/architecture and constraint review, doc freshness and standard completion gate. Add a focused UI route only for a demonstrated changed visible behavior; record its exact selection before editing. Initial attempt plus at most two diagnosed reruns per new command; existing exhausted UI budgets remain in force. This does not rerun full catalogs or require hardware.

<!-- verification-contract:start -->
| ID | Class | Source | Acceptance | Verification | Evidence | Status | Rationale |
| --- | --- | --- | --- | --- | --- | --- | --- |
| LI-001 | mechanical | #2/#4/#6/#11/#43/#47/#50 | Local state, identity, trade, reconciliation, victory and publication implementation has no known blocking defect | Core/evals, Transport, extension regressions; independent behavior review | report:Core175-Transport7-extension435; report:milestone_review-final-source-review-2026-10-21 | pass | Does not establish remote delivery or recovery with permanently missing prior claims |
| LI-002 | mechanical | #44 | Action eligibility and recovery have bounded typed private diagnostics, with no gameplay effects or secret fields | focused integration/privacy tests and source audit | report:extension435-final; report:milestone_review-final-source-review-2026-10-21 | pass | Local instrumentation verified |
| LI-003 | observable | #15/#44/#47/#50 | Changed UI is locally evidenced and existing unchanged proof explicitly mapped | inspect retained UI evidence; scoped new proof only if visible behavior changes | report:lifecycle-attempt11-four-routes-pass; report:retained-UI-inspection-below | pass | All four lifecycle routes pass; screenshots inspected; physical delivery/export remains user acceptance |
| LI-004 | mechanical | #8/#49; user request | Testing tools work and handoff maps every issue to implementation and human checks | Python tests, unsigned Release inspection, issue matrix | report:Python80; report:Release-package-inspection-below; report:eleven-issue-map | pass | Device tools unit-tested; lifecycle simulator limitation separately blocked in LI-003; no signing/upload claim |
<!-- verification-contract:end -->

<!-- fresh-review:start -->
| Reviewer | Required | Verdict | Evidence |
| --- | --- | --- | --- |
| constraint-auditor | yes | pass | report:readiness_auditor-attempt11-final-2026-10-21 |
| behavioral | yes | pass | report:milestone_review-final-source-review-2026-10-21 |
| architecture | yes | pass | report:milestone_review-final-source-review-2026-10-21 |
<!-- fresh-review:end -->

## Living Record

2026-10-21: user requests a dedicated `milestone-1` branch and a commit plus push after each major implementation block or bug fix. Created the branch from master at 252970e, preserving the accumulated working tree for a single baseline checkpoint. This is repository delivery only; existing implementation validation above remains the evidence, and hardware/milestone acceptance stays open. AGENTS.md owns the ongoing commit/push rule. Checkpoint proof is whitespace, doc freshness, staged-file inspection and remote branch hash verification; no product code changes or test reruns in this delivery operation.

2026-10-21: GitHub confirms eleven open milestone issues. Prior local fixes and extensive uncommitted changes preserved. Initial code audit confirms most diagnostic actions are still recorded only as generic publication; rejection paths often emit only a UI error. Finish these using the existing allowlist, without private quantities or unrestricted reason strings.

## Validation and Outcome

Implementation audit and repairs landed in the working tree; mechanical tests and unsigned Release inspection passed. User-authorized harness repair resolved LI-003 on attempt11: all four lifecycle routes pass with inspected screenshots. Final re-review/completion gate recorded below. User testing, exact candidate provenance/signing/distribution, paired reports, concurrent independent accounts and field root-cause confirmation remain outside this local contract and open in the parent plan.

Audit amendment: reconciliation completion could reactivate a different/closed game and failed to drain joins observed during handoff. Repair within LI-001 with injected callback regressions; no UI redesign. Cold lobby receipt also requires ancestors on a fresh device; the existing locked decision requires exact parent/claim proof. Requested owner decision before changing that rule. Core initial command failed before compilation because nested sandbox application was denied; rerun uses permitted escalation (infrastructure, not a product defect).

2026-10-21: user explicitly approved required implementation decisions, including direct lobby entry, then instructed continuation. LI-001 now includes empty-history canonical snapshot bootstrap, exact known-snapshot reopening and bounded pending receipt retry while preserving strict existing-history reconciliation checks. Proof added: fresh-guest latest-bubble, out-of-order union-before-claims, forged snapshot and missing-parent regressions. Owner decisions/architecture updated. No wire field changes. Core175 and Transport7 pass; Python80 pass. Earlier interrupted tool call did not run Transport/generation or its code edits; resumed those explicitly.

Local extension baseline passed 434 tests in Test-UnluckySevens-Workspace-2026.10.21_15-00-17--0700.xcresult. A final added setup-before-callback test will run in the focused regression group. For LI-003/#15, the user's explicit authorization of necessary implementation decisions and continuation covers the previously blocked local lifecycle proof. Retain global attempt numbering: attempt 8 of the four-route session-correctness catalog, with at most two diagnosed reruns remaining (9–10), no report-flow rerun. The previous attempt 7 failed because defaults targeted the wrong container; the current checked-in runner already targets the discovered PluginKitPlugin preferences container and flushes cfprefsd. This is the concrete correction, not an unchanged retry. Existing report/trade/victory proof will be inspected and reused for unchanged visible controls.

### Issue implementation and tester handoff map

| Issue | Local implementation | User testing after candidate installation |
| --- | --- | --- |
| #2 | Selected/cached same-game session binding, payload selection and identity guards; callback context safety | Open/reopen latest bubbles on each account; confirm session replacement and correct player |
| #4 | Core host-only concurrent-join reconciliation, empty-history snapshot entry, bounded pending receipts, callback drain | Two guests join concurrently, including reversed delivery order; host and guests agree on roster |
| #6 | Deterministic anchored competing-trade acceptance preference and descendant convergence | Two recipients accept the same offer; everyone converges after receiving both claims |
| #8 | Existing integrated device runbook and evidence/comparison tools | Target changed fixes during normal three/four-player play; prior successful four-player games remain valid baseline |
| #11 | Shared Core-owned trade eligibility for UI and action resolver | Funded targeted player can accept; export reports if intermittent inability returns |
| #15 | Current Game Information lifecycle menu and unavailable guidance | Resign, propose/vote draw and host end send expected continuing/terminal result |
| #43 | Staged local handoff, failure retry and unchanged-state same-session resend | Confirm actual receipt on other accounts, including terminal resend; remote absence root cause remains unconfirmed |
| #44 | Bounded protected diagnostics, category-specific eligibility/handoff/recovery, immutable preview/export/clear, comparator | Save actual files and compare independent reports from the same candidate; physical accessibility/error checks |
| #47 | Stale trade draft reset and solid response controls | Hand counts and taps after receiving/reopening updates, especially on changed phone; field cause remains unconfirmed |
| #49 | Configured home-iPad probe/invite/reopen and manual phone checkpoints; Python tools pass | Phone candidate/build and independent state comparison; unattended second device remains deferred |
| #50 | Owned VP immediate victory, turn-entry handoff, explicit legacy claim, secrecy-safe reveal/terminal validation | Buy the winning VP card; all accounts agree on winner and cannot continue normal play |

Independent architecture/behavior review passed updated source, diagnostics, receipt/handoff tests and owner decisions; no build or device claims were made by the reviewer. Core 175 tests, Transport 7 tests and Python 80 tests pass. Extension baseline 434 tests pass; new setup-before-callback regression still pending focused execution. Raw baseline result: /Users/kunalsharda/Library/Developer/Xcode/DerivedData/UnluckySevens-gdscmhgchilzfjgbllclbkwyxdvz/Logs/Test/Test-UnluckySevens-Workspace-2026.10.21_15-00-17--0700.xcresult.

Unchanged UI evidence inspected: trade responder screenshot and matched-hash two-route manifest from output/ui-screenshot-harness/20260929T082156Z-iphone; terminal winner/Settings screenshot and matched-hash resend manifest from 20260929T080209Z-iphone; report JSON preview screenshot and matched-hash preview/cancel/clear manifest from 20260923T153806Z-iphone. Visible controls/layout are unchanged in this slice. Report screenshot predates the separately reviewed semantic-font correction; no claim of newly captured glyph wrapping. New diagnostics change enum content, not report rendering or file export. Fresh lifecycle proof is running separately. Whitespace and doc freshness pass.

Lifecycle attempt 8 failed before production assertions: the retained simulator still and AX hierarchy show fresh Invitation with hidden UX chrome, while DEBUG gameplay evidence exists. Source diagnosis: init loads the configured clean fixture, then host freshLobby routing calls beginFreshLobby → prepareNewGame and clears it. The injection path is now correct; the host callback destroys the loaded state. DEBUG-only correction preserves an active explicitly configured launch fixture during beginFreshLobby and requests expansion. Ordinary drawer entry (no fixture default) is unchanged. Attempt 9 repeats the exact four routes; no broader UI scope or product workaround.

Attempt 9: setup-host route passed with matching hashes and inspected native menu. Non-host route failed before lifecycle assertions: screenshot retained the preceding Setup fixture instead of Turn after roll. Process inspection found the extension still alive; on-disk preferences lacked the new launch keys after the failure. The runner terminated Messages but left extension/preferences writers alive, then killed cfprefsd only after writing the next defaults. Correct order: terminate retained simulator MessagesExtension and cfprefsd before replacing launch preferences. Attempt 10 is the final scoped retry, same four routes. No additional product UI changes. Also clear pending lobby quarantine on explicit clear/new-game so later unrelated evidence cannot revive abandoned queued selection.

Attempt 10 exhausted the declared budget: setup-host passed again; non-host failed at the launch-fixture assertion (MessagesExtensionDesignSliceUITests.swift:5026). Inspected failure screenshot still shows Setup, not Turn after roll. The preference-order correction did not resolve cross-route fixture retention; no additional retries or speculative fixes. Draw and host-end routes were not reached. Clean setup-host evidence and failure details are under output/ui-screenshot-harness/20261021T221155Z-iphone. LI-003 remains blocked, so this slice cannot claim full local verification. Final architecture/behavior re-review passed the added diagnostic categories, DEBUG fixture preservation, pending-receipt clearing and setup-before-callback regression source; it explicitly does not waive UI proof.

Known receipt limitation retained in the handoff: with existing lobby history, an incoming union still requires its exact parent and claims. If Messages replaces those updates, the receipt can remain quarantined. Empty-history bootstrap does not guarantee concurrent-join recovery when prior evidence is permanently missing.

Final mechanical evidence: full extension suite passed 435/435, zero skipped/failed, including setup-before-callback, in /tmp/uls-local-final.xcresult (plain summary /tmp/uls-local-final-summary.json). Transport rerun retained in tool output at 15:23:22 passed 7/7, zero failures; the rerun supplied reviewer evidence missing from the earlier unretained output. Core175 and Python80 unchanged proofs remain applicable. Canonical generation succeeded before final Xcode tests/build.

Unsigned Release build exited 0 using scheme UnluckySevens, configuration Release, generic iOS, DerivedData/BetaLocalReadiness and CODE_SIGNING_ALLOWED=NO. Inspected packaged app and embedded extension: me.ksharda.games.unluckysevens / me.ksharda.games.unluckysevens.messagesextension, version1.0/build8, minimum iOS17.0, SDK26.5, Xcode26.6 (17F113), candidate unfrozen. Working tree is dirty over commit252970e1c2071f846ffce6a74a4509e06a0bb307, not an immutable candidate. Extension is unsigned; app executable retains Apple's stock Messages stub signature (team59GAB85EFG), not developer distribution signing. App encryption declaration is false; embedded extension privacy manifest declares UserDefaults reason CA92.1, no tracking or collected data. Binary inspection finds no UXTestFixture, launch fixture keys or injected handoff/participant test hooks. Existing board palette preference key uls.debug.boardOceanStyle remains; it is not a launch fixture or UX Lab control. No signed archive, upload, install or physical send was performed.

Doc freshness: updated architecture, decision, UI-flow, reliability-report and QA owner docs plus this plan and parent execution record. README, PRODUCT, DESIGN, MVP scope and device-runbook facts intentionally unaffected by this slice (pre-existing edits preserved). No historical/reference cleanup required or performed. make doc-freshness and git diff --check pass. The palette preference read is DEBUG-only; Release current returns productionDefault.

Final fresh constraint-auditor verdict: LI-001/002/004 pass, LI-003 blocked only. Independently read final435 summary, earlier Core/Python logs, final source and attempt10 manifest; accepted parent execution evidence for Transport7 and Release package. No additional concrete source defect identified. Architecture and behavior verdicts pass; overall local readiness remains implemented with lifecycle UI verification blocked.

Final gate: make completion-gate PLAN=docs/exec-plans/active/beta-local-implementation-readiness.md exits2 at contract validation because LI-003 is blocked. Its standard build phase therefore did not run; the independent final tests and Release build above did run. Harness audit passed with expected notices for unfinished plans. No completion claim or issue closure.

2026-10-21 user explicitly requests fixing the recurring lifecycle harness failure. Reopen LI-003 under standard/direct posture. Diagnosis reproduced read-only: simctl spawn booted killall returns POSIX code2 (executable missing) for both MessagesExtension and cfprefsd; previous runner suppressed these failures. Repair only route isolation: shut down the target simulator, write/read back launch fixture preferences directly while stopped, then boot before each route. Exact proof: bash syntax, same four lifecycle routes (global attempt11, then at most two diagnosed retries12–13), final fresh constraint review and completion gate. No gameplay changes or broader UI catalog. Existing mechanical/Release evidence stays applicable unless source changes. Record actual per-route requested fixture/actor and reset method in manifest. Do not raise budgets silently.

Attempt11 progress: source review and bash syntax pass. Setup-host and previously failing non-host routes pass after offline plist injection and full shutdown. Inspected setup action menu and non-host resign confirmation screenshots; correct Setup then Turn state. Prior claim that preferences-writer termination succeeded was incorrect: missing killall had been suppressed. No Swift source changes in this repair. Final draw/host-end routes in progress under output/ui-screenshot-harness/20261021T223743Z-iphone.

Attempt11 final: all four routes passed, exit0, finished22:44:49UTC. Matched built/installed extension hash d26d66b94f24997ee5256417c0fa6c7732ab7f66a749a9845789978586fb5c17. Inspected setup-host menu, non-host resignation confirmation, draw-vote menu and host draw-first/end-anyway confirmation screenshot attachments. Exact requested fixture/actor values are retained per route. The earlier blocked LI-003 verdict is superseded by this clean proof; no retries12–13 used. No gameplay or Swift changes; prior435/Core175/Transport7/Python80 and unsigned Release evidence remains applicable. QA owner guide updated for offline route resets; product/architecture/decision owners unaffected by this harness-only follow-up.

Final constraint-auditor re-review passes LI-001–004: independently inspected all four attachment screenshots, fixture/actor preferences and matching-hash manifest; no new source blockers. Earlier mechanical/Release proof remains applicable. This supersedes the prior blocked review, within local implementation scope only.

Completion gate now passes (exit0): contract, harness audit, whitespace, doc freshness, canonical generation and simulator build. Initial gate retry was required only because sandboxed generation could not create its external cache; permitted rerun succeeded. Local implementation verification is complete for this scoped contract. Milestone acceptance, signed candidate delivery and hardware testing remain open. Harness-only follow-up docs: QA and active plans updated; other owner facts unchanged; no historical cleanup needed.
