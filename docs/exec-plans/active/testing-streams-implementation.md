# Beta 1.1 testing and candidate delivery

## Purpose and Outcome

One working plan for Beta 1.1 testing, diagnostic candidate distribution and shared device evidence. GitHub issues retain individual bug/acceptance ownership. Existing diagnostic, session and trade plans retain scoped technical contracts and prior evidence; they are references, not extra serial prerequisites for a diagnostic TestFlight candidate.

## Execution Settings

- Validation profile: `standard`
- Delivery posture: `direct`
- Rationale: User explicitly authorized simplifying the testing paths and candidate gates on 2026-09-28. The current implementation phase repairs the authorized product defects and prepares evidence for a diagnostic candidate; it does not declare the milestone reliable. Final milestone/public release remains release-critical under QA.

## Context and Boundaries

Use the USB home iPad driver plus a human phone on a separate iMessage account. Automate local checks, home-side UI steps and report comparison; stop at phone receive/join/export checkpoints. No third owner-controlled device, unattended phone control, new rules, backend or parallel diagnostics framework is required. Friends supply three-/four-account checks after candidate distribution. Exact conversation selectors and device identity remain in ignored configuration. Live sends remain explicit operator checkpoints; local fixture and callback tests do not contact players.

[QA](../../quality/qa.md#diagnostic-testflight-candidate-versus-milestone-release) owns candidate/release gates. [Device runbook](../../quality/device-runbooks.md) owns executable steps. [Reliability reports](../../quality/reliability-reports.md) owns comparison. Do not guess candidate identity or infer delivery from local success.

## Milestones / Plan of Work

2026-10-21: user requests local implementation readiness first and will perform device testing afterward. The [local implementation readiness slice](beta-local-implementation-readiness.md) owns the current audit, remaining code repairs and local checks. Existing field/candidate acceptance below remains open; it does not block doing this local work.

1. **Make home testing executable now:** existing physical driver gains a read-only preflight with no build/install/send. Run it against private home configuration. Keep existing probe/invite/inspect/reopen paths and strict installation-preserving resume. No repeat of already valid checks without source changes or a different required candidate.
2. **Distribute a diagnostic candidate:** identify included fixes and known bugs; finish only the candidate requirements in QA, freeze source/build, archive/sign and distribute. #43/#47 diagnosis and #8 live matrix can remain open. Do not require the full milestone matrix to obtain the very candidate used to collect it.
3. **Two-device session:** automate iPad invite; human phone receives/joins; automate exact host reopen and one declared repeat. Save independent reports and compare. Confirm actual phone build/install separately; a development iPad plus TestFlight phone is mixed-distribution evidence.
4. **Friend session:** same candidate, distinct accounts; concurrent joins in both arrival orders (#4), competing trade accepts (#6/#11), lifecycle actions (#15), three-/four-player matrix and completed match (#8). Reuse matched evidence for #2/#49 rather than repeating journeys per ticket.
5. **Fix and finish:** use diagnostics for missing updates (#43) and trade UI (#47); validate each demonstrated fix. Close individual issues only against their own acceptance. Run final release-critical integrated acceptance to close Beta 1.1.

### Issue map and closure boundary

| Work | Owner | Closure boundary |
| --- | --- | --- |
| Home-side automation and remote-human checkpoints | #49 | Proven configured iPad driver, preserved installation, remote-human roundtrip and declared repeat with available independent candidate/state evidence; no second automated device required |
| Local diagnostics/export/comparison | #44 | Required collection/privacy/UI and physical export evidence; missing branches stay explicit |
| Host/session continuity | #2 | Exact-candidate host/selection/session observations; reuse #49 journey |
| Concurrent joins and trade accepts | #4/#6/#11 | Local implementation plus required independent account proof; no synthetic delivery claims |
| Lifecycle guidance | #15 | Focused real controls and candidate/device proof |
| Missing update and trade-screen defects | #43/#47 | Diagnosis, demonstrated fix/recovery and focused regression evidence |
| Victory detection | #50 | Focused Core regression and integrated winner-state evidence on the candidate |
| Integrated release acceptance | #8 | Shared candidate matrix, including three/four players and completed match |

Fully unattended second-device automation is deferred capability, not Beta 1.1 acceptance. This revises #49's former hardware-dependent requirement; it does not waive real independent-account evidence in product tickets.

## Verification Contract and Fresh Review

2026-09-29 implementation phase replaces the completed routing contract. Standard/direct; user authorizes the full repair plan. Prior BT-001–004 routing proof remains recorded below, not proof of new product fixes. Work proceeds victory → publication/recovery → trades → remaining integration. Candidate preparation and live evidence remain separately reported; do not require them to start local fixes.

<!-- verification-contract:start -->
| ID | Class | Source | Acceptance | Verification | Evidence | Status | Rationale |
| --- | --- | --- | --- | --- | --- | --- | --- |
| BF-001 | mechanical | #50; user implementation approval | Purchase-to-win, own-turn entry and explicit legacy-state recovery count owned VP correctly; public queries preserve secrecy; canonical validation rejects tampering | failing then passing focused Core regressions, full Core tests/evals and Transport suite; independent rules/constraint review | report:Core175-Transport7-extension423; file:Packages/ULS_CoreGame/Tests/ULS_CoreGameTests/TurnVictoryV1Tests.swift | pass | No wire field changes; old clients may reject corrected transitions, candidate participants must update |
| BF-002 | mechanical | #43 | Publication does not commit early and safe resend preserves canonical lineage/session | focused publication/recovery tests, Apple symbol contracts, source review | report:handoff-final2-source-review; file:MessagesExtension/Tests/StatePublicationHandoffTests.swift | pass | Remote absence remains device evidence |
| BF-003 | observable | #47/#11; user trade clarification | Demonstrated stale drafts repaired; Accept/Decline/Counter use solid backgrounds per explicit user clarification | focused trade tests, bounded affected UI captures/review | file:MessagesExtension/Tests/GameTradeDraftRefreshTests.swift; report:focused-draft2-pass; report:trade-solid-ui2-pass | pending | Stale draft and clarified transparent response backgrounds repaired locally; broader hand field symptom remains unverified |
| BF-004 | mechanical | #4/#6/#15/#44 | Existing fixes integrated with required diagnostics and affected regression proof | selected Core/extension tests and source review | report:Core175-extension423-source-review | pass | No new general harness |
| BF-005 | observable | candidate contract | Identified Release candidate with scoped package/privacy/local smoke proof | QA diagnostic candidate checks | report:pending | pending | Not a milestone-completion claim |
<!-- verification-contract:end -->

<!-- fresh-review:start -->
| Reviewer | Required | Verdict | Evidence |
| --- | --- | --- | --- |
| constraint-auditor | yes | pass | report:2026-09-29-final-source-behavior-UI-audit; report:trade-solid-source-and-two-capture-audit; broader BF-003/BF-005 pending |
<!-- fresh-review:end -->

## Living Record

2026-09-28: User is home and authorizes automation-path simplification. Standard/direct retained. Exact proof locked before edits: physical-driver/manual-recorder/comparator unit tests, one real read-only preflight (one diagnosed correction at most), fresh source/release-policy review, issue body readback, doc freshness and standard gate. No UI harness rerun, fresh invite, install or upload in this tooling/policy slice. Existing hardware UI retry accounting is unchanged.

### Retained prior evidence and limitations

- Redundant one-device wrapper was removed; existing simulator catalogs remain the local route. Prior evidence recorder tests and CLI smoke passed; synthetic sessions are tooling proof only.
- On 2026-09-22 physical development iPad probe/invite and human-phone join passed. Original-host reopen and one cold-reopen repeat passed with identical home game/revision/hash. Private artifacts: output/physical-messages/20260922T210733Z-18d365d5 and 20260922T210854Z-b1e87695. Ten driver tests, physical build-for-testing and scoped reviews passed.
- Earlier weak-role run was invalidated: it showed the inviter as a guest after reinstalls. Continuation now installs only the test runner, uses destination artifacts and checks retained app/installation identity. Default bubble targeting is unique; duplicate labels require explicitly observed occurrence/count. Never restore newest-message or arbitrary-coordinate fallback.
- Old aggregate TI-004/PD-003 remained blocked on phone build and cross-device canonical agreement. Those facts remain unverified under #49/#8; this contract replacement does not relabel them passed. Second automated-device work is now deferred by the owner. Hardware/third-account evidence is not a precondition for unrelated diagnostic candidate distribution.
- Report preview/cancel/clear, 22 diagnostics tests, 8 comparison tests and Release/standard checks passed in prior slices; actual physical save and independent same-candidate reports remain unverified.

## Validation and Outcome

Route simplification slice complete: usable read-only preflight, aligned candidate gates/tickets and a single execution entrypoint. Candidate freeze, upload, human phone checkpoints, friend-session proof and product fixes remain subsequent work in this plan.

2026-09-28: 35 focused Python tests passed. Live `make test-home` passed with one bounded devicectl app query; no build/install/UI/send occurred. Existing app reports 1.0 (8); no candidate/TestFlight equivalence inferred. Exact real result retained privately above. Shared-plan links and #49 scope amendment prepared for all eleven current milestone issues; no closures.

All eleven open Beta 1.1 issues were updated and exact body/state readbacks verified. #49 acceptance now excludes a second automated device; all product acceptance and issue-open states preserved. New #50 victory report is included as a scoped bug owner in the shared map, not silently treated as fixed. Doc freshness, whitespace and harness audit pass; final standard gate awaits fresh final policy verdict.

Final standard completion gate passed in /tmp/uls-testing-paths-gate.log: contract, harness audit, whitespace, doc freshness, canonical generation and simulator baseline build. The 35 focused Python tests and real iPad app query passed; fresh preflight/privacy-of-evidence and release-policy review passed. This is tooling/policy completion only. No current UI/device journey, new invite, app installation, candidate freeze or upload performed. Owner docs updated: AGENTS, QA, constraint verification, device runbook, decisions and README; plan/profile guidance, roadmap and deferred-device debt aligned. Product/rules/transport/design owners intentionally unchanged; historical references remain intact.

2026-09-29 user approved implementing the repair plan. Four-player functionality is user-confirmed existing playtest evidence, not new implementation work; retain only affected regression/candidate checks. Trade-control symptom is being clarified after user corrected “opaque”; no opacity/visual interpretation is assumed. Exact initial proof: #50 Core victory/dev-card regressions, full Core tests/evals, Transport tests, affected extension/UI checks once integration is known, fresh correctness review. No expansion of testing infrastructure. Official CATAN FAQ confirms own-turn immediate victory including before roll; existing multi-reveal/afterRoll-only behavior contradicts the requested fix. Legacy active snapshots will not be silently rewritten on decode.

#50 initial regression reproduced both hidden/revealed prior-card variants failing to end at the second purchase (/tmp/uls-victory-red.log). New winning transition uses exact reducer replay (same approach as lifecycle validation), revealing only winner VP cards. Fresh review identified resignation handoff and forced-step/public-only legacy recovery gaps; included because they are sourced own-turn/recovery acceptance, not new game scope. Add bounded existing Hand-win and new Game Information Declare Victory UI journeys in scripts/ui-screenshot-catalog-victory.txt, at most initial plus two diagnosed retries each; report-flow exhausted budget is untouched. Old snapshots remain unchanged until explicit action; all participants must update for corrected transition validation. Trade-control clarification remains pending.

#50 focused final Core victory/dev-card/lifecycle regression: 31 tests pass (/tmp/uls-victory-focused-final.log). Initial full Core run had 173 tests and one test-only nil-versus-normalized-zero assertion; fixed to assert opponent reveal count preserved. Final full suite and Transport rerun in flight. Actual changes: hidden VP win detection, exact winning replay validation, lifecycle handoff, explicit Declare Victory, terminal bubble copy. No shipping/device claim.

#43 code inspection demonstrated immediate state advancement before asynchronous send acceptance. Apple exact MSConversation.send(_:completionHandler:) and MSMessage.session docs consulted (local JSON snapshots /tmp/uls-apple-send.json and /tmp/uls-apple-session.json): callback means local sending starts, not recipient delivery. Generic production sends now stage and commit on acceptance with overlap protection and conversation invalidation; explicit resend keeps snapshot/session. Focused proof includes StatePublicationTransaction tests, existing state-selection/session tests, extension compilation and a bounded resend UI check (initial + two diagnosed retries). No undocumented-platform workaround is assumed. Remaining remote absence remains live candidate evidence.

#47 source-backed draft defect: GameShellView.synchronizeTradeOverlay only handles a removed panel/live offer; an open player/counter draft survives canonical state changes with old selected quantities and no offer anchor. A counter can therefore be submitted against a replacement offer, or selected quantities exceed the new hand. Scope the repair to discarding the stale local draft on canonical/visible-hand change, returning to the current offer/chooser and clearing recipient overlay. This is a demonstrated stale-draft boundary, not proof of the reported new-phone root cause. Focused route tests plus existing trade regression/catalog evidence; arbitrary opacity changes remain excluded.

Validation update: final Core/evals175 pass (/tmp/uls-victory-core-final.log), Transport7 pass (/tmp/uls-victory-transport.log), extension423 pass (/tmp/uls-beta-repairs-extension.log). Subsequent focused handoff/transaction/draft/reconciliation9 pass (/tmp/uls-beta-repairs-handoff.log); initial new-test compilation lacked CompactState SPI import and was corrected. Fresh source review passes #50/#47 and #43 after draining lobby claims that arrived during another send. Pending-claim drain is source-audited, not simulated by the new handoff test. Settings also exposes the guarded resend for lobby/setup/game over; no Player Record publication path is added. Three-route UI catalog in flight with the declared budget; Release/candidate and real devices remain unverified.

Primary publication contracts: [MSConversation.send(_:completionHandler:)](https://developer.apple.com/documentation/messages/msconversation/send(_:completionhandler:)-9krz), [MSMessage.session](https://developer.apple.com/documentation/messages/msmessage/session). Primary victory rule: [CATAN base-game FAQ](https://www.catan.com/faq/basegame).

UI attempt1 failed before app entry: selected outer Messages conversation cell did not navigate; screenshot/hierarchy retain nested outer/inner cells and the exact participant label. Evidence: output/ui-screenshot-harness/20260929T075322Z-iphone. Retry2 targets that observed child label, with no coordinate fallback or product scope change. Remaining routes have not run yet. No report-flow retry.

UI attempt2 Hand winning route passed with matching build/install hashes. Observed finished-game screen has no Settings entry, blocking resend/report access after terminal publication. This is a sourced #43 recovery gap: add Settings to existing final-score actions and use remaining focused UI budget to verify it. No new report-flow test or opacity redesign. Retain the first route's before-change proof separately; final visual proof must include this change.

All three UI routes passed on attempt2: output/ui-screenshot-harness/20260929T075626Z-iphone, with matched built/installed hashes and independent per-route results. Final terminal Settings addition requires only the winning route rerun (attempt3), extended to resend the winning snapshot through Settings and assert unchanged hash/revision/winner. Legacy-claim and in-game resend mechanics are unchanged and reuse attempt2 proof. The new final callback integration test also verifies persisted state, received successor preservation and navigation-away behavior. No broader catalogs rerun.

Final terminal Settings/winning-snapshot resend route passed on attempt3: output/ui-screenshot-harness/20260929T080209Z-iphone (matched build/install hashes, unchanged terminal hash/revision/winner). Winning, legacy claim and unchanged in-game resend UI proof now covered by clean scoped per-route bundles; no remaining retry is needed or authorized in this slice. All source constraints reviewed; final visual audit and unsigned Release device build in flight. App Store Connect was opened and observed at Apple sign-in; requested operator login for live build identity/distribution access. No version/build identity guessed, no candidate freeze/sign/upload, no ticket closure.

Owner docs changed: architecture (winning and publication boundaries), decisions, UI flows, QA command route, device manual steps, and this plan. Product scope and visual language owners intentionally unchanged; no historical documents rewritten. Doc freshness and harness audit pass; final completion gate remains subject to BF-003/BF-005, so no whole-plan completion claim.

Final fresh constraint/behavior/UI audit passes scoped repairs: raw unit logs, matched-hash UI manifests, terminal canonical evidence and final screenshot inspected. Settings gear and two-line New game label fit without clipping. This audit does not waive pending broader trade symptom or candidate/distribution proof.

Unsigned Release device build passes: /tmp/uls-beta-repairs-release.log. Inspected app/extension IDs match expected standalone Messages package; app encryption declaration false, extension privacy manifest present with tracking false/no collected-data entries, DEBUG fixture launch/clean-shot and injected handoff symbols absent. This is deliberately still version1.0/build8 with candidate=unfrozen; not unique candidate, signed archive, upload or tester-install proof. App Store Connect remains at operator sign-in with a pending request; no authentication secrets requested in chat.

GitHub #50/#43/#47 bodies updated with local repair/evidence and remaining boundaries, then read back as OPEN with the expected implementation section. Final doc-freshness and whitespace pass; harness audit passed. Full-plan make completion-gate was run (/tmp/uls-beta-repairs-completion-gate.log) and correctly stopped at pending BF-003 (BF-005 also remains pending). This is not a failed code test and does not turn broader field/three-account acceptance into a pre-upload prerequisite: QA's scoped diagnostic-candidate contract still applies when candidate identity/signing can be prepared. No milestone completion, signed readiness or distribution claim.

2026-09-29 trade clarification supersedes earlier opacity ambiguity: user explicitly reports transparent Accept/Decline/Counter backgrounds. Standard/direct; repair only responder-button appearance using existing wooden fill, preserving eligibility and other shared-style consumers. Exact proof: existing incoming-trade and multi-type incoming-trade UI captures on iPhone, source review of enabled/disabled/pressed paths, fresh constraint audit, doc freshness and completion gate. Initial run plus at most two diagnosed retries; no report-flow or victory reruns.

Trade visual attempt1 stopped before generation/build because the sandbox denied CoreSimulator service access. Attempt2 uses the same existing harness with simulator permissions; no product workaround or scope expansion. Solid background is opt-in only for the responder row; disabled dimming is label-only and pressed feedback darkens the opaque fill. DESIGN owns this clarified appearance.

Trade appearance proof: both existing incoming-trade UI routes pass in output/ui-screenshot-harness/20260929T082156Z-iphone with matching built/installed hashes; enabled fills/labels/layout visually inspected. Disabled/pressed opacity paths source-reviewed, not separately UI-exercised. No new unit tests for this styling-only repair. Broader #47 field/hand symptoms and BF-005 remain pending; local fix is not shipped. Doc freshness and whitespace pass.

Fresh trade constraint/visual review passes both canonical captures, matching hashes and raw test result. DESIGN and active plan updated; architecture, protocol, gameplay/product-flow and QA owners intentionally unchanged by this appearance-only slice; no historical cleanup needed.

Trade-slice final gate invoked: /tmp/uls-trade-solid-completion-gate.log. Whole-plan completion remains blocked by pending broader BF-003 (and BF-005); focused appearance checks pass. Issue #47 updated/read back OPEN with the two-route evidence. No live-device install or TestFlight upload in this slice.

2026-09-29 user reconfirms multiple successful four-player end-to-end games with friends; encountered general bugs are already filed. This is accepted user-observed baseline coverage, with exact build/session unspecified. Four-player support is not missing implementation. Next candidate/friend checks target changed fixes and races, not another blanket proof that a four-player game can run. Remaining implementation uncertainty: #43 remote-delivery cause and #47/#11 intermittent trade/hand symptom not fully established; #44 still lists action-specific diagnostic coverage gaps. Candidate preparation/distribution and focused validation remain next.

2026-10-21 local readiness audit (user will test devices afterward): repaired reconciliation callback navigation/newer-state safety and queued-join drain; added approved fresh-device lobby snapshot bootstrap plus bounded out-of-order receipt quarantine; expanded typed action/rejection/recovery diagnostics. Owner decision revised explicitly, no wire fields changed. Core175, Transport7, Python80 and extension434 baseline pass. Focused final tests, Release inspection and final auditor are tracked in the linked readiness slice. Lifecycle UI revealed DEBUG launch-state clearing and cross-route preference ordering defects; corrected within the bounded catalog budget. No hardware install, invite/send, upload or issue closure.

Final local readiness update: extension435 pass, Core175/Transport7/Python80 pass, unsigned Release package inspection passes within its local scope (version1.0/build8, unfrozen). Architecture/behavior source re-review passes. Lifecycle attempt10 still retained the preceding Setup fixture on the non-host route; setup-host passed but draw/host-end routes were not reached. Retry budget exhausted, LI-003 blocked; this is not a full implementation-verification or milestone-completion claim. Known-history lobby receipts still need exact parent/claim evidence and can remain quarantined when earlier updates never arrive. See the readiness plan for all eleven issue handoff checks and final gate outcome.

Superseding lifecycle update: user requested repair after attempt10. The runner's suppressed simctl-spawn killall calls never ran (iOS runtime lacks killall). Replaced with target shutdown, offline plist editing/readback and boot per route. Attempt11 passed all four lifecycle routes with matching hashes and inspected screenshots in output/ui-screenshot-harness/20261021T223743Z-iphone. No gameplay changes. Local LI-003 proof is now pass; prior device/candidate acceptance boundaries remain open.

Readiness slice final constraint review and standard completion gate pass after the harness repair. Local contract complete; this parent remains open for its device/candidate acceptance. No upload or physical installation performed.
