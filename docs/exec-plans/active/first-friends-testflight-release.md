# First Friends TestFlight Release

## Purpose and Outcome

Ship the first externally installable Unlucky Sevens beta to a small invited group through TestFlight. Success means the final UI branch is legacy-free and reproducibly verified, the signed Release build passes the repository gate and real-device multiplayer matrix, Apple processes the exact archived build without unresolved errors, invited friends can install it, and a two-account installed-TestFlight smoke proves the Messages extension still works outside the development install path.

## Execution Settings

- Validation profile: `release-critical`
- Delivery posture: `checkpointed`
- Rationale: The technical direction is settled, but App Store Connect upload, beta review submission, group assignment, and invitations are external distribution actions. Implementation and validation may proceed directly; the user is the authority for the final upload-and-invite checkpoint.

## Context and Boundaries

- This plan depends on the completed [Final UI Cohesion, Wiring, and Legacy Removal](../completed/final-ui-cohesion-and-legacy-removal.md), whose standard completion gate passed on 2026-08-17. That plan owns deletion of dead compiled UI, the repeatable screenshot harness, fresh iPhone/iPad evidence, and final UI/accessibility approval.
- [QA](../../quality/qa.md) selects the release lane; [device runbooks](../../quality/device-runbooks.md) own the hardware journeys; [constraint verification](../../quality/constraint-verification.md) owns completion language.
- [Architecture](../../../ARCHITECTURE.md), [decisions](../../decisions.md), and the product specs own engine, protocol, secrecy, compatibility, and player-facing behavior. This plan does not introduce gameplay, protocol, analytics, monetization, localization, or App Store public-release scope.
- Pre-TestFlight development transcripts are disposable. The first processed TestFlight build establishes the supported compatibility boundary; later protocol-breaking work must explicitly preserve or migrate states created by that build.
- The baseline hardware matrix is one iPhone and one iPad on separate Apple Accounts in one real Messages conversation. The multiplayer gate also requires enough participants/devices to exercise three- and four-player lobby ordering honestly; simulators may supplement but cannot replace the two-account hardware path.
- Apple currently requires an uploaded build to finish processing before testing. External friends require an external TestFlight group, an internal group first, beta test information, and TestFlight App Review for the first external build. Verify the live App Store Connect prompts at execution time: [TestFlight overview](https://developer.apple.com/help/app-store-connect/test-a-beta-version/testflight-overview), [external testers](https://developer.apple.com/help/app-store-connect/test-a-beta-version/invite-external-testers), [build upload](https://developer.apple.com/help/app-store-connect/manage-builds/upload-builds/), and [export compliance](https://developer.apple.com/help/app-store-connect/test-a-beta-version/provide-export-compliance-information-for-beta-builds).
- Secrets, Apple credentials, signing certificates, provisioning profiles, tester email addresses, and local device identifiers remain outside Git and tracked docs.

## Milestones / Plan of Work

1. Close the UI dependency: delete all remaining dead compiled legacy presentation code, add its source guard, harden the single-DerivedData screenshot runner, inspect the complete iPhone catalog and representative iPad set, and pass the standard UI completion gate.
2. Freeze the beta candidate: record commit, bundle identifier, marketing version, unique build number, Xcode/SDK, minimum OS, signing team, and exact Release configuration; confirm no DEBUG UX Lab or retired presentation source ships.
3. Complete App Store Connect readiness without uploading: confirm agreements/access, app record and bundle ID, beta description, features-to-test copy, feedback and beta-review contacts, privacy answers and privacy-policy URL, export-compliance disposition, and any current Apple-required metadata. Review notes must explain that Unlucky Sevens is an iMessage-only app found in the Messages drawer, requires a conversation to exercise, and has no ordinary standalone home-screen experience.
4. Build and install the signed Release candidate on the real-device matrix. Run the shell, lobby, Messages lifecycle, turn-taking, gameplay-cohesion, accessibility, secrecy, and host-resize checks selected by the device runbook.
5. Run the multiplayer release matrix: three- and four-player lobby ordering, ordered seven/discard, mixed decline/counter Trade responses, the near-simultaneous acceptance race, stale-bubble recovery, Games recovery, resignation/draw/host-end lifecycle, session restart, and one complete standard match through victory.
6. Run `make release-gate PLAN=docs/exec-plans/active/first-friends-testflight-release.md`, create and validate the signed archive, and record the exact archive/build identity plus all warnings. Any unresolved validation, signing, privacy, or packaging error blocks distribution.
7. Present the frozen proof summary and exact upload candidate at the approval gate. Do not upload, submit for beta review, create/modify tester groups, or invite anyone before approval.
8. After approval, upload the validated archive, wait for Apple processing, resolve export-compliance prompts, create/confirm the internal group, create the external friends group, attach the build and test information, submit the first external build for TestFlight App Review, and invite only the user-approved friends after approval.
9. On the Apple-processed TestFlight build, perform an installed smoke on both Apple Accounts: install/update, find the app in the Messages drawer, invite/join/start, exchange canonical state across devices, reopen a stale bubble, recover through Games, complete a turn containing Trade or robber interaction, and inspect crashes/sessions/feedback before calling the friends beta live.

## Recovery and Rollback

- If local proof fails, do not archive or upload until the evidenced defect is corrected and affected contract rows rerun.
- If Apple processing or TestFlight App Review fails, retain the rejection/error record, correct only the evidenced packaging, metadata, compliance, or product defect, increment the build number when Apple requires a new upload, and present the replacement candidate again.
- If the installed TestFlight smoke or early friend use finds a release-blocking state fork, data leak, crash loop, unusable Messages entry path, or stranded-game defect, stop testing that build in App Store Connect, notify only the approved tester group, preserve diagnostic evidence, and ship no compatible-state-breaking replacement without an explicit migration decision.
- There is no remote kill switch. Stopping a TestFlight build prevents new testing access but does not substitute for communicating with testers who already installed it.

## Approval Gate

- Authority: User.
- Minimum honest proof: UI dependency passed; release gate passed; signed Release build installed on the hardware matrix; multiplayer matrix and full match passed; archive validation passed; App Store Connect metadata/privacy/export answers drafted; exact commit, version, build number, archive identity, external group name, and intended tester list presented.
- Iteration budget: One frozen upload candidate. If local validation or Apple processing/review fails, correct only the evidenced defect, rerun every affected contract row, and present a replacement candidate.
- Stop condition: Any failed or blocked contract row, unresolved archive/upload warning, unavailable required hardware/account, uncertain privacy/export answer, or missing user approval stops distribution. Never infer permission to invite testers.
- Authorized after approval: Upload the exact candidate, complete App Store Connect processing and first external beta review, add the approved build to the approved group, invite the approved testers, and run the installed-TestFlight smoke.

## Verification Contract and Fresh Review

<!-- verification-contract:start -->
| ID | Class | Source | Acceptance | Verification | Evidence | Status | Rationale |
| --- | --- | --- | --- | --- | --- | --- | --- |
| TFR-001 | mechanical | user request and UI dependency | The final UI plan has every constraint and required review at pass, its completion gate passes, and no dead compiled legacy renderer/component remains | inspect dependency contract and commit; deleted-symbol source guard; dependency completion gate | commit:`27334681ca1c61ebabaea3fda4b24277b3221e7f`; report:`docs/exec-plans/completed/final-ui-cohesion-and-legacy-removal.md` | pass | The completed dependency has UCR-001–009 and all required reviews at pass, its standard gate passed, and the harness deleted-symbol guard is green |
| TFR-002 | mechanical | AGENTS.md and QA | The frozen candidate is reproducible from one commit and records bundle ID, version, unique build number, Xcode/SDK, minimum OS, signing team, configuration, and archive identity without tracked secrets | repository/status audit; Release build settings capture; archive metadata inspection | report:pending | pending | Candidate identity must be exact before device proof or upload |
| TFR-003 | mechanical | QA release-critical profile | Core tests/evals, Transport tests, generic device build, Messages simulator build, workspace tests, harness audit, diff hygiene, and doc freshness pass through the release gate | `make release-gate PLAN=docs/exec-plans/active/first-friends-testflight-release.md` | command:pending | pending | Required exhaustive mechanical gate |
| TFR-004 | observable | device runbook real-device lane | The signed Release candidate installs on iPhone and iPad, appears in the Messages drawer, renders the approved shell without DEBUG surfaces, preserves accessibility/secrecy, and survives compact/expanded host resizing | two-device shell, lifecycle, gameplay-cohesion, accessibility, and secrecy checks with inspected evidence | report:pending | pending | Simulator proof does not establish real Messages-host behavior |
| TFR-005 | observable | phase-13 manual TestFlight gate | Three- and four-player invite, join, rename, reopen, ordering, and start flows converge on the same canonical lobby/game state | real-device multiplayer lobby matrix with transcript/state evidence | report:pending | pending | Friends beta must not begin with broken membership or ordering |
| TFR-006 | observable | device runbook and phase-13 risk list | Ordered seven/discard rejects stale out-of-order publication; mixed Trade responses converge; two acceptances within about one second do not fork or brick the game | real-device discard sequence and Trade race probes with final canonical state/hash comparison | report:pending | pending | These are the highest-risk concurrent player actions |
| TFR-007 | observable | device runbook full standard-match pass | One real-device match runs from lobby through setup, production, building, Trade, dev cards, robber/discard, turn progression, and victory with consistent state and winner summary | complete match log/checklist plus representative screenshots on both accounts | report:pending | pending | Focused tests do not replace an end-to-end game |
| TFR-008 | observable | recovery and terminal owner flows | Stale-bubble reopen, Games recovery, resign-as-active/waiting, draw reject/approve, host end including resigned host, New Game, and session restart behave consistently on both accounts | host-stability regression checklist with canonical-state evidence | report:pending | pending | Recovery and lifecycle failures can strand a beta game |
| TFR-009 | mechanical | Apple build-upload requirements | The signed archive validates; the uploaded build matches the frozen identity, completes Apple processing, and has no unresolved upload error, compliance block, or warning accepted without recorded disposition | archive validation; App Store Connect build metadata/status inspection | report:pending | pending | The distributed binary must be the validated candidate |
| TFR-010 | judgment | Apple TestFlight and privacy requirements | Beta description, features to test, feedback and review contacts, iMessage-only reviewer instructions, privacy answers/policy URL, export-compliance answers, group, and tester list are accurate and user-approved | user approval of the frozen distribution summary against live App Store Connect prompts | approval:pending | pending | External metadata and recipients require human authority |
| TFR-011 | observable | user first-friends beta outcome | Approved friends can install the Apple-processed build; the two-account installed-TestFlight smoke passes invite/join/start, canonical exchange, recovery, and one Trade or robber turn without development tooling | installed TestFlight smoke with build number and inspected evidence | report:pending | pending | Upload success alone does not prove the distributed extension works |
| TFR-012 | mechanical | compatibility and doc-freshness rules | Owner docs record the first supported TestFlight version/build and compatibility boundary; release notes and remaining beta risks are current without tracked credentials/tester data | semantic owner-doc audit; `make doc-freshness` | command:pending | pending | The first beta becomes a durable compatibility boundary |
<!-- verification-contract:end -->

<!-- fresh-review:start -->
| Reviewer | Required | Verdict | Evidence |
| --- | --- | --- | --- |
| constraint-auditor | yes | pending | report:pending |
| behavioral | yes | pending | report:pending |
| product-ux | yes | pending | report:pending |
| accessibility | yes | pending | report:pending |
| architecture | no | not-applicable | No architecture or protocol change is planned; route only if release evidence forces such a change |
<!-- fresh-review:end -->

## Living Record

### Progress

- [ ] Final UI dependency passed; release-preparation evidence required privacy/export and explicit version packaging corrections, so a superseding candidate commit must be frozen after those checks pass.
- [ ] App Store Connect, privacy, export, signing, and build identity ready.
- [ ] Signed Release hardware and multiplayer matrices passed.
- [ ] Release gate and archive validation passed.
- [ ] User approved the exact external distribution candidate and tester group.
- [ ] Apple processing/review and installed-TestFlight smoke passed.

### Decisions

- 2026-08-10: This is a friends-only external TestFlight beta, not a public App Store release.
- 2026-08-10: The plan is release-critical and checkpointed. Local implementation and proof may proceed, but upload, beta-review submission, group mutation, and invitations stop for explicit user approval.
- 2026-08-10: The first processed TestFlight build establishes the compatibility floor; dev-era transcripts remain disposable.
- 2026-08-10: Real devices are authoritative for Messages behavior. Simulator catalogs remain required UI regression evidence but cannot substitute for the hardware multiplayer matrix.
- 2026-08-17: The approved UI baseline is commit `27334681ca1c61ebabaea3fda4b24277b3221e7f`. Release-preparation evidence then required explicit version/build settings plus privacy/export packaging; freeze the superseding product commit after those corrections pass. Intended identity remains app `com.unluckysevens.app`, extension `com.unluckysevens.app.messagesextension`, version `1.0`, build `1`, iOS 17.0 minimum, Release/automatic signing with team `8B83G5AZ22`, Xcode 26.6 (17F113), and iPhoneOS 26.5 SDK. Build-number uniqueness and final archive identity remain pending live App Store Connect/archive inspection.

### Discoveries

- 2026-08-10: Apple’s current external-testing flow requires an internal group before an external group and TestFlight App Review for the first external build; live App Store Connect requirements must be rechecked at execution time.
- 2026-08-17: Apple’s current documentation still requires an app record before upload, processing before the build appears, beta description/review information for external testing, an internal group before the first external group, first-build TestFlight App Review, and a privacy-policy URL for all apps. Missing-compliance builds require export-compliance answers before review.
- 2026-08-17: The Mac currently reports no connected iPhone or iPad, so TFR-004–008 cannot begin. The required hardware matrix remains one iPhone plus one iPad on separate Apple Accounts; simulator proof cannot substitute.
- 2026-08-17: App Store Connect redirected the available browser to an unauthenticated login, and no connected Chrome browser is available. Live app-record, agreements, build-number uniqueness, metadata, privacy, and group readiness remain pending user sign-in.
- 2026-08-17: Local signing is configured for automatic signing and one valid Apple Development identity is installed. No Apple Distribution identity is currently visible; Xcode may provision one during archive, but archive/validation remains downstream of the hardware and approval gates.
- 2026-08-17: The signed Release device build succeeds with automatic development provisioning. Its compiled extension contains no UX Lab/debug strings. The packaged extension now includes `PrivacyInfo.xcprivacy` declaring no tracking or collected data and the app-only `UserDefaults` reason `CA92.1`; the containing app declares `ITSAppUsesNonExemptEncryption=false`. A rebuilt product proves both files are present and valid. Distribution signing remains unproved until archive validation.

### Draft TestFlight Metadata

- Beta description: “Unlucky Sevens is an iMessage-first tabletop strategy game for friends. Invite players in a Messages conversation, build a shared island economy, trade resources, and race to 10 points.”
- What to Test: “Play from invite through victory. Please focus on joining and reopening games, setup placement, rolling and building, player and Bank/Port trades, development cards, robber/discard flows, resign/end-game recovery, and the Games list. Report any state mismatch between players, missing Messages bubble, clipped screen, or action that cannot continue.”
- Review notes: “This is an iMessage-only app. It has no ordinary standalone home-screen experience. In Messages, open a conversation, tap `+`, choose Unlucky Sevens from the apps drawer, and open the extension. Send an invitation into the conversation, then use another participant/device to open the invitation, join, and continue. The game stores recovery state locally and publishes canonical game state through Messages.”
- App privacy draft: “Data Not Collected” by the developer. No accounts, analytics, ads, tracking, developer server, or third-party SDKs. Display names/preferences and recoverable games are stored locally; players deliberately send game state through Apple Messages. Final answers remain subject to the live App Store Connect questionnaire.
- Export compliance draft: no non-exempt encryption; the app implements no cryptography and relies only on Apple operating-system/Messages transport. `ITSAppUsesNonExemptEncryption=false` is packaged.
- Proposed internal group: `Internal Smoke`. Proposed external group: `First Friends`.
- Pending owner inputs: public privacy-policy contact email, feedback email, beta-review contact details/phone, privacy-policy URL publication approval, and exact tester list.

## Validation and Outcome

- Automated: UI dependency contract and standard completion gate pass; release-critical gate waits for the hardware matrix and remaining contract rows.
- Simulator/UI: Current single-device and paired representative simulator evidence is green at UI baseline `2733468`; release-only packaging corrections do not alter product UI.
- Real devices: Blocked because no iPhone or iPad is currently connected to the Mac.
- Archive/App Store Connect: Candidate identity is partially frozen; live App Store Connect inspection is blocked on sign-in and archive/validation remains downstream of device proof.
- Distribution: Not started.

The release is planned but not yet verified or distributed.
