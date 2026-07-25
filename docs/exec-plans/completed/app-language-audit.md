# App Language Audit

## Purpose and Outcome

Audit every player-facing phrase in Unlucky Sevens so the app sounds like one concise, playful, trustworthy game host rather than a mixture of implementation labels, rulebook prose, and generated tutorial copy. Success means the current language is inventoried by surface, high-impact problems are prioritized, and a proposed voice and rewrite sequence are ready for owner approval.

## Execution Settings

- Validation profile: `standard`
- Delivery posture: `checkpointed`
- Rationale: the audit is broad and evidence-based, while the eventual voice and shipping rewrites require owner judgment.

## Context and Boundaries

- [UI Flows](../../product-specs/ui-flows.md) owns player-facing behavior and flow requirements.
- [Design](../../../DESIGN.md) owns the current visual language but does not yet define a complete verbal voice.
- This slice audits tutorial titles, guidance, coach marks, lobby copy, action labels, upper instructions, waiting/status text, trade/discard/dev-card language, transcript receipts, settings/rules, errors, and accessibility copy.
- Debug-only fixture labels, developer diagnostics, transport logs, code identifiers, and test descriptions are excluded unless they can leak into the player experience.
- The audit does not rewrite shipping strings before the owner approves the voice and priority set.

## Milestones / Plan of Work

1. Extract and classify the complete player-facing language inventory.
2. Review tutorial language separately for teaching sequence, warmth, clarity, brevity, and transfer to the real UI.
3. Identify systemic voice problems, contradictions, robotic phrasing, terminology drift, and accessibility mismatches.
4. Present a concise voice proposal, representative rewrites, and a prioritized implementation sequence for owner approval.
5. Implement the approved tutorial, lobby, error, Trade, Dev Card, recovery, transcript, and accessibility language.
6. Update focused copy tests and validate the affected journeys under the standard profile.

## Approval Gate

- Authority: user
- Minimum honest proof: full surface inventory, exact current tutorial language, prioritized findings, and representative before/after copy
- Iteration budget: two review rounds by default
- Stop condition: do not modify shipping language or locked gameplay terminology before owner approval
- Authorized after approval: centralize approved vocabulary, rewrite selected surfaces, update exhaustive copy tests, and validate affected journeys

## Verification Contract and Fresh Review

<!-- verification-contract:start -->
| ID | Class | Source | Acceptance | Verification | Evidence | Status | Rationale |
| --- | --- | --- | --- | --- | --- | --- | --- |
| LANG-001 | mechanical | app source | Every player-facing copy surface is represented or explicitly excluded | source extraction and surface inventory | `docs/design/app-language-audit.md`; 99 production Swift files scanned | pass | Inventory covers tutorial, lobby, play, trade, Dev Cards, forced flows, transcript, utility, error, recovery, and accessibility surfaces |
| LANG-002 | mechanical | current tutorial source | All tutorial titles, guidance, callouts, and accessibility descriptions are captured accurately | source-to-audit comparison | `GameTutorialStep.swift`, `GameTutorialPreviewView.swift`, and tutorial inventory in the audit | pass | The audit distinguishes normally visible callouts from large-text and accessibility language |
| LANG-003 | judgment | user request and product context | Proposed voice feels concise, playful, human, and precise | owner review of representative rewrites | owner approved the complete decision set on 2026-07-25 | pass | Voice, vocabulary, lobby structure, tutorial direction, status hierarchy, and surface cleanup were reviewed directly |
| LANG-004 | mechanical | UI flow contract | Approved copy does not change rules, action semantics, privacy, or publishing behavior | contract cross-check and focused tests | `ui-flows.md`; 262-test MessagesExtension suite; 17-state tutorial replay; passive-discard installed-host journey | pass | The implementation changes presentation copy and first-pair guidance only; canonical rules, protocol, and publication behavior remain unchanged |
| LANG-005 | judgment | accessibility contract | Visible and accessibility language remain aligned while adding needed context | accessibility source review, focused tests, and installed-host replay | `GameTutorialStepTests`; `PlayerFacingErrorCopyTests`; tutorial accessibility markers exercised across all 16 lessons; fresh Terra-medium review | pass | Spoken labels use the same action vocabulary, remove synthetic `The real...` descriptions and semicolon joins, and retain added state/consequence where useful |
<!-- verification-contract:end -->

<!-- fresh-review:start -->
| Reviewer | Required | Verdict | Evidence |
| --- | --- | --- | --- |
| constraint-auditor | yes | pass | fresh Terra-medium review found three vocabulary leaks; all were corrected and the focused recheck passed |
| product-ux | yes | pass | user approved the complete voice, vocabulary, lobby, tutorial, status, and cleanup set |
| accessibility | yes | pass | natural-language source review plus focused accessibility-copy tests and the complete installed tutorial replay |
| behavioral | no | not-applicable | Audit-only checkpoint does not change behavior |
<!-- fresh-review:end -->

## Living Record

### Progress

- [x] Scope, exclusions, profile, posture, and owner gate locked.
- [x] Player-facing language inventory complete.
- [x] Tutorial language critique complete.
- [x] Voice proposal and representative rewrites presented.
- [x] Owner approval gate passed.
- [x] Approved shipping language implemented.
- [x] Focused tests, installed-host journeys, accessibility review, and fresh constraint review passed.
- [x] Completion gate passed.

### Decisions

- 2026-07-24: Audit the entire app, but treat the tutorial as a distinct teaching voice rather than applying one generic shortening pass everywhere.
- 2026-07-24: Preserve canonical game terms where precision matters; improve the surrounding sentence rather than replacing established vocabulary with cute synonyms.
- 2026-07-25: Remove semicolons from proposed player-facing copy. The strategy lesson should teach that more probability dots under a number indicate a stronger spot for that resource and must point to a numbered resource tile.
- 2026-07-25: Upper amber instructions remain terse action language rather than adopting the tutorial teaching voice. The checkpoint proposes seven wording changes, two removals of unused cases, and twelve unchanged headings.
- 2026-07-25: Merge the separate strategy and scoring lessons into one final `Strategy` overlay. A single centered tabletop card over a dark board scrim contains three rows: probability dots, purposeful Road/Dev Card investment, and the requested scoring summary.
- 2026-07-25: Passive discard waiting uses the upper amber instruction `Waiting for Other Players`. Active discard and robber actions retain their blocking or in-board guidance.
- 2026-07-25: The trade chooser uses `Choose How to Trade`, distinguishing the choice between a player offer and a Bank or Port trade.
- 2026-07-25: A selected Road or Settlement target uses `Tap Again to Build`, describing the result of the confirmation tap.
- 2026-07-25: Maritime trade uses `Trade with Bank or Port` so the heading covers controlled port rates as well as the default bank rate.
- 2026-07-25: A sent player trade uses `Waiting for Replies`, naming the response the sender is waiting for.
- 2026-07-25: A targeted incoming trade uses `Review the Offer`, covering accept, decline, and counter without sounding procedural.
- 2026-07-25: Road Building uses `Place the First Road` and `Place the Second Road`, restoring natural spoken grammar.
- 2026-07-25: Remove the unused `Choose Dev or Roll` case. The pre-roll choices explain themselves without an additional amber heading.
- 2026-07-25: Player-facing copy uses `table` instead of `roster` or `pending roster`. Roster remains valid internal implementation vocabulary.
- 2026-07-25: Player-facing copy uses `send` and `sent` instead of `publish` and `publication`. Publishing remains internal protocol vocabulary.
- 2026-07-25: Action copy uses `available` or `glowing` when the board already visualizes valid targets. Reserve `legal` for rules explanations where the distinction matters.
- 2026-07-25: Use `Dev Cards` in compact controls and headings, and spell out `development cards` in explanatory prose.
- 2026-07-25: Use `Victory Point card` in normal prose. Reserve `VP` for genuinely compact scoring displays.
- 2026-07-25: Visible trade copy uses `players` or actual player names instead of protocol terms such as `recipients` or `targeted players`.
- 2026-07-25: `Victim` is acceptable player-facing game vocabulary. Do not mechanically replace it with a longer phrase.
- 2026-07-25: Visible copy says `your hand` or `your cards` instead of exposing privacy mechanics such as `current hidden hand`.
- 2026-07-25: Keep the tutorial lesson title `Choose a Victim`; the longer `Choose Who to Steal From` is unnecessary.
- 2026-07-25: Player-visible errors use a short human explanation plus one recovery action. Raw technical diagnostics remain available only through DEBUG logging.
- 2026-07-25: Known failure families receive specific recovery messages. Only unknown failures use a generic fallback.
- 2026-07-25: Simplify each lobby state to one invitation sentence, one name prompt, one table-status sentence, and one primary action. Show recovery instructions only when recovery is needed.
- 2026-07-25: A guest opening an invite sees the heading `Join the Table`.
- 2026-07-25: The guest invitation sentence is `[Host] invited you to play Unlucky Sevens.`, using the host's displayed name.
- 2026-07-25: Keep the lobby field label `Display Name`; a more conversational prompt is unnecessary.
- 2026-07-25: Lobby status uses the live form `[Count] player(s) at the table`, with natural singular and plural handling.
- 2026-07-25: After joining, a guest sees `You're In` and `Waiting for [Host] to start.` This avoids repeating `table`.
- 2026-07-25: The fresh host-invite heading is `Start an Unlucky Sevens Game`.
- 2026-07-25: The fresh host-invite screen has no subtitle; the heading and `Send Invite` action are sufficient.
- 2026-07-25: After sending, the host sees `Waiting for Players` above the live player list and count until the game can start.
- 2026-07-25: Once the minimum player count is met, use `Ready to Start` with `Start Game` and remove its redundant subtitle and helper text.
- 2026-07-25: The owner approved the remaining language decisions as a batch: lobby helper reduction, concise post-send recovery, tutorial and accessibility rewrites, Trade and Dev Card simplification, player-centered recovery rows, transcript normalization, preservation of Settings/rules/game-over structure, and `Year of Plenty` capitalization.
- 2026-07-25: Setup retains glowing targets in both rounds. Only the first settlement-and-road pair receives explanatory copy. Forced discard uses exact-count copy for the active player and `Waiting for Other Players` with no subtitle for passive players.

### Discoveries

- The production source contains 1,248 raw string-literal matches and 803 likely copy-bearing references across 99 Swift files after excluding DEBUG-only developer files. The app has no `.xcstrings`, `.strings`, or other localization catalog.
- Standard-size tutorial screens display the coach-mark callouts, not the lesson title or guidance. Titles and guidance remain important because VoiceOver consumes them and accessibility text sizes render them visibly.
- The strongest existing voice is in transcript receipts and primary controls. The weakest language is concentrated in lobby state explanations, raw errors, Trade, Dev Cards, and tutorial metadata.
- Visible warnings can include `error.localizedDescription`, allowing technical transport or state-machine terms to reach players.

## Validation and Outcome

The approved language contract is implemented across lobby, setup, amber instructions, tutorial, Trade, Dev Cards, discard, recovery, transcript receipts, errors, and accessibility copy.

Validation on 2026-07-25:

- `bash ./scripts/gen.sh` succeeded.
- The complete MessagesExtension suite passed 262 tests with zero failures.
- Final focused tutorial and player-facing-error suites passed 8 tests with zero failures.
- `testCaptureEveryTutorialScreen` passed the navigation veil plus all 16 lessons in the installed Messages host.
- `testCaptureNotPrimaryPlayerWaitingOnDiscard` passed with the exact `Waiting for Other Players` prompt and no discard action.
- Direct stills of the fresh invitation, passive discard state, and final Strategy card were inspected. Copy fit without clipping, the discard state used one amber instruction, and the Strategy card retained the dimmed real board.
- A fresh Terra-medium constraint/UI review identified alternate-path `legal` language, `Play Dev`, and a second-pair setup fallback. All three were removed before the final focused recheck.

`make completion-gate PLAN=docs/exec-plans/active/app-language-audit.md` passed under the `standard` profile after the sandboxed first attempt was rerun with Tuist cache access. The selected verification contract, harness audit, diff check, doc-freshness check, canonical generation, and MessagesExtension simulator build all passed. Notices from unrelated active plans remain tracked by their owners and did not block this selected plan.
