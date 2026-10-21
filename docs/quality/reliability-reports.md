# Reliability reports for coordinated testing

Owner issue: [#44](https://github.com/kunal-sharda/UnluckySevens/issues/44). [QA](qa.md) selects validation; [device runbooks](device-runbooks.md) own real Messages journeys. This guide describes the reporting implementation, not a claim that a candidate has reached TestFlight.

## Participant procedure

1. Install the identified candidate on each device. Record the TestFlight build/install evidence separately; JSON metadata does not prove distribution or signing.
2. Use distinct iMessage accounts and anonymous operator roles (`host`, `guest`, `guest2`). Record the checkpoint start time with its timezone and the expected canonical revision in the scenario notes.
3. Perform the scoped scenario. Each participant opens the latest game bubble after receiving the relevant update. A sender's local send callback is not recipient receipt.
4. Open **Settings → Reliability Report** in that game. Review the exact JSON. Choose **Export This Report** to save it with the system file picker, then share the saved file through an explicitly chosen channel. Nothing is uploaded by the app. Canceling leaves gameplay unchanged.
5. Keep reports and screenshots under ignored output. Compare the reports once all participants have exported. Retain screenshots for visual role, controls and transcript replacement; report equality alone cannot prove those observations.

The report view freezes its bytes when opened; reopen it after a new checkpoint. **Clear Local Reports** removes all local diagnostic games after confirmation, not canonical state or previously exported files. Storage failures and unsuccessful deletion are stated explicitly. No open game produces an unavailable report. DEBUG fixtures/tutorials do not collect real-device events; empty reports cannot satisfy the comparator.

## Candidate preparation

The extension Info.plist embeds `ULSReliabilityCandidate` from the `ULS_RELIABILITY_CANDIDATE` build setting. Default is `unfrozen`, intentionally rejected for evidence comparison. During candidate preparation, supply the frozen full source SHA through `xcodebuild ULS_RELIABILITY_CANDIDATE=<full-SHA>` after canonical generation. Use a new distributed build number; do not relabel a dirty build as that commit. Inspect the archived extension plist, configuration, version and build before upload. This guide does not authorize an upload or manufacture provenance from user-supplied metadata.

A report contains schema version, app version/build/candidate, Debug or Release compilation, OS description, a hashed game correlation, and bounded typed events. Each event may contain a game-scoped digest of canonical state, revision, local sequence/time, category/outcome, membership category, host trigger and session presence. It contains no raw game/participant/session identifier, roster/name/contact, hand/card/resource details, message payload, free-form error or unrelated game. Game/state digests correlate reports for that game; they are not account identity or proof of authenticity.

Retention is 128 records/24 hours, pruned on append/export/reopen. Full report size including metadata is at most 64 KiB, trimming oldest records if needed. The existing protected, backup-excluded local store is reused. A version/build/candidate/configuration fingerprint binds the snapshot to its producing binary; a changed identity discards prior records rather than relabeling them. OS/app metadata plus explicitly user-shared diagnostics need the final distribution privacy review; no backend or automatic upload is added.

## Offline comparison

```bash
python3 scripts/compare-reliability-reports.py \
  --report host=output/reports/host.json \
  --report guest=output/reports/guest.json \
  --candidate FULL_FROZEN_SOURCE_SHA --version 1.0 --build NEXT_BUILD \
  --revision EXPECTED_REVISION --since '2026-09-22T14:00:00-07:00' \
  --separate-accounts
```

Use the actual checkpoint time, candidate and expected revision. Two to four anonymous roles are supported. `--allow-debug` compares only Debug reports and never establishes TestFlight compatibility. The separate-account flag records operator attestation; tools cannot establish independent accounts from two filenames.

- Exit 0: matching game, expected revision and state digest in each latest accepted, bound selected-state observation, within the specified checkpoint, for the reported candidate. This is one checkpoint, not all-message delivery, correct gameplay, account authenticity or visual proof.
- Exit 1: well-formed observations disagree or do not reach the expected revision. Investigate; do not automatically retry or select older matching records.
- Exit 2: unverified input: missing/stale selection, local-handoff-only evidence, duplicate report content, missing candidate, metadata mismatch, different games, invalid schema/size/category, unavailable identity or unbound selection.

The comparison deliberately rejects reformatted copies and arbitrary extra/private fields. Reports are user-controlled evidence, not signed attestations. The tool does not upload data or print private file contents.

## Validation

Focused Swift suites: `ReliabilityDiagnosticBufferTests`, `ReliabilityDiagnosticStoreTests`, `ReliabilityReportTests`, `ReliabilityPublicationPreparationTests`. Offline checks: `python3 -m unittest discover -s scripts/tests -p 'test_reliability_comparison.py'`. UI route: `bash scripts/run-ui-screenshot-catalog.sh iphone scripts/ui-screenshot-catalog-reliability.txt`, following canonical generation and serial execution in the harness. Active proof/status: [delivery plan](../exec-plans/active/reliability-diagnostics-delivery.md). The focused simulator journey now passes preview, system-export cancellation, and confirmed clear/empty, with inspected screenshots. It uses the Ready game fixture; Invitation deliberately has no selected game. Drawer selection uses the current bundle’s exact cell because obsolete same-name installations can coexist. This is synthetic UI proof only.

Collection currently covers validated decoded state/active selection, publication preparation and local send success/failure. Missing active conversation records publication eligibility unavailable; envelope encoding or message-construction failures record encoding failed. Session-resolution failure records recovery unavailable with no session. Preparation acceptance means message construction succeeded, not that Messages accepted a handoff or a recipient received anything. Missing/invalid selection records an unavailable/failed checkpoint against the currently open game when one exists, preventing reuse of an older successful selection. Game-scoped publication observations require a decodable state with a nonnegative revision; malformed outgoing payloads cannot be safely attributed and are not logged against a guessed game. Turn publications retain their typed action category through encoding and local handoff. Trade, discard, setup, board-action, development-card and dice entry rejections record category-only eligibility outcomes; reducer validation records accepted/rejected eligibility separately from send results. Lifecycle binding failures and unavailable explicit resend record recovery unavailable. No resource quantity, target, card type, offer content or unrestricted error is added. Missing active-game context cannot be attributed safely and remains unrecorded. Missing events remain missing evidence. System export completion and independent physical reports still require exact-candidate device proof; simulator cancellation or synthetic JSON is not a substitute.

Apple contracts: [send message](https://developer.apple.com/documentation/messages/msconversation/send(_:completionhandler:)-9krz) reports when sending starts; [file export](https://developer.apple.com/documentation/swiftui/view/fileexporter(ispresented:document:contenttype:defaultfilename:oncompletion:)) is user initiated through a system destination picker.
