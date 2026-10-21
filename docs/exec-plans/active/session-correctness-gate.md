# Session Correctness Gate

## Purpose and Outcome

Close the evidence-backed portion of GitHub issues [#2](https://github.com/kunal-sharda/UnluckySevens/issues/2), [#7](https://github.com/kunal-sharda/UnluckySevens/issues/7), and [#15](https://github.com/kunal-sharda/UnluckySevens/issues/15): strengthen deterministic Messages host-boundary coverage, remove the obsolete fresh-session state-publication helper, and restore current Game Information lifecycle proof without changing Core rules, Transport fields, or authority semantics.

## Execution Settings

- Validation profile: `standard`
- Delivery posture: `direct`
- Rationale: The requested behavior and owner-doc contracts are settled, but the work crosses host lifecycle, session continuity, UI discoverability, and test/runbook surfaces. Targeted automated and observable evidence plus a fresh constraint audit are required.

## Context and Boundaries

- Code and tests are authoritative, followed by [decisions](../../decisions.md), [architecture](../../../ARCHITECTURE.md), [UI flows](../../product-specs/ui-flows.md), and [QA](../../quality/qa.md).
- Canonical `.state(gameId:)` publication may use only the selected same-game `MSSession` or an in-memory cached session. It must fail closed when neither exists.
- `.new` and `.newState(gameId:)` remain the only policies allowed to create a fresh session.
- Resign, draw proposal/vote, and host end remain Core-authored canonical state transitions published through the current bubble-bound game session.
- Player Record remains read-only and cannot establish gameplay or publication authority.
- No Core rules, Transport protocol, secrecy behavior, trade behavior, or lobby convergence policy changes are in scope.

## Milestones / Plan of Work

1. Map every session-policy caller and remove any obsolete helper that can mint a fresh session for `.state(gameId:)`; lock the fail-closed policy with focused tests.
2. Add deterministic host-boundary diagnostics/contract coverage and an operator-assisted two-account proof procedure for the hardware-only lifecycle boundary.
3. Replace skipped current-game lifecycle UI proof with focused setup/turn, host/non-host, confirmation/cancel, draw-vote, and unavailable-binding coverage where the simulator harness can honestly prove it.
4. Update owner docs and debt status, run the locked focused proof, obtain fresh constraint review, then run the standard completion gate only if every required row has evidence.

## Verification Contract and Fresh Review

The exact proof set below is locked before implementation. Hardware-only rows may remain deferred; if so, this plan and its issues remain open and no completion claim is allowed.

<!-- verification-contract:start -->
| ID | Class | Source | Acceptance | Verification | Evidence | Status | Rationale |
| --- | --- | --- | --- | --- | --- | --- | --- |
| SC-001 | mechanical | #7; decisions §8; architecture session rules | `.state(gameId:)` never creates a replacement `MSSession`; matching selected or cached sessions resolve, otherwise publication is unbound | focused `TranscriptGameSessionBindingTests` and source call-site audit | command:17/17 host-boundary group pass | pass | Selected/cached/unbound policy covered after one simulator cold-start retry |
| SC-002 | mechanical | #2 | Selection, payload source, session presence, and active-context disposition have deterministic coverage without changing runtime protocol | focused MessagesExtension host-boundary unit tests | command:host-boundary group pass; `/tmp/UnluckySevens-session-focused.xcresult` | pass | DEBUG diagnostics now redact the raw participant identifier |
| SC-003 | observable | #15; UI flows resignation/terminal states | Current Game Information exposes discoverable lifecycle actions for eligible setup/turn host and non-host actors, including confirmation/cancel and draw vote | focused XCUITest journey and retained result bundle/screenshot inspection | artifact:pending | pending | A build cannot prove the migrated player path |
| SC-004 | mechanical | #15 | Lifecycle availability rejects unbound/incompatible contexts, produces accurate private recovery guidance, and preserves existing Core legality/authority for resign, draw, vote, and host end | focused resolver, guidance, and session tests | command:`/tmp/UnluckySevens-session-focused.xcresult` (12/12 pass) | pass | Guidance and transcript support focused suites pass |
| SC-005 | observable | #2; #7; #15 | Two Apple accounts confirm payload source, selection/reopen lifecycle, session continuity/collapse, participant identity, lifecycle receipts, and continuing/terminal results | operator-assisted connected-device runbook with captured diagnostics | device-report:pending | pending | `MSSession` and transcript behavior cannot be proven in simulator |
| SC-006 | mechanical | AGENTS.md completion discipline | Harness, docs, source formatting, build, and verification contract pass | `make doc-freshness`; `make completion-gate PLAN=docs/exec-plans/active/session-correctness-gate.md` | command:pending | pending | Standard profile baseline and completion enforcement |
<!-- verification-contract:end -->

<!-- fresh-review:start -->
| Reviewer | Required | Verdict | Evidence |
| --- | --- | --- | --- |
| constraint-auditor | yes | pending | report:pending |
| Messages host/session specialist | yes | pending | report:pending |
| SwiftUI accessibility/interaction review | yes | pending | report:pending |
<!-- fresh-review:end -->

## Living Record

### Progress

- [x] Locked standard/direct execution settings, scope, proof set, and verification contract before implementation.
- [x] Session publication policy and deterministic host-boundary coverage updated; validation pending root-serialized lane.
- [x] Current-game lifecycle UI proof restored; execution and artifact inspection pending root-serialized lane.
- [x] Owner docs and debt index reconciled.
- [ ] Focused automated and observable proof run.
- [ ] Hardware proof and required fresh reviews recorded.
- [ ] Completion gate passed.

### Decisions

- 2026-08-28: Treat connected-device transcript behavior as required evidence, not something simulator tests may substitute for.
- 2026-08-28: Preserve existing Core, Transport, authority, and session-continuity contracts; this slice may only remove contradictory fallback code, improve private recovery guidance, and add proof.

### Discoveries

- 2026-08-28: The production `session(for:)` path already fails closed through `TranscriptGameSessionBinding`; an unused `TranscriptTransportSupport.preferredStateSession` helper and its test still encode the obsolete fresh-session fallback described by #7.
- 2026-08-28: Current Game Information still owns lifecycle actions, but its replacement XCUITest is skipped and asserts identifiers from the removed recovery/Your Games UI.
- 2026-08-28: The first combined host-boundary unit attempt exited before XCTest established its connection (`xctest` terminated during bootstrapping; zero product tests ran). Classified as simulator infrastructure. One focused retry is authorized after a simulator cold restart; unchanged retries beyond that are not authorized.
- 2026-08-28: The first lifecycle XCUITest stopped in shared launch setup before loading a contracted fixture: XCTest synthesized the Open Lobby tap, but the compact gate remained visible. The retained screenshot and hierarchy show the expected enabled button and no lifecycle surface. Classified as a Messages-host/harness transition failure rather than evidence about the new lifecycle UI. One catalog retry is authorized under the runner's cold lifecycle; a repeated failure blocks observable proof and does not authorize tap workarounds.
- 2026-08-28: Catalog attempt 2 passed the setup-host journey, then proved the new guest fixture controls were below the non-scrollable iOS Menu cutoff. This is a DEBUG evidence-authoring defect: the production lifecycle surface was never loaded. Move the two fixture controls into the existing visible menu section, regenerate, and run one corrected full-catalog attempt.
- 2026-08-28: Catalog attempt 3 still showed the host's truncated menu without the newly reordered entries even though the freshly built DEBUG binary contained them and built/installed hashes matched. Avoid the host-controlled menu entirely for these fixtures: expose two bounded DEBUG direct buttons in the existing UX Lab chrome, which the harness already prefers before menu navigation.
- 2026-08-28: Catalog attempt 4 proved compact top-chrome buttons are clipped/non-hittable at the installed host width, so XCTest again fell back to the menu. Remove duplicate identifiers from clipped/menu controls and place the two direct fixture chips inside the visible 316-point UX Lab panel, matching established direct-control patterns.
- 2026-08-28: Catalog attempt 5 reached the lobby with no UX Lab controls because the preceding clean screenshot intentionally persisted hidden DEBUG chrome across the isolated route. Restore chrome explicitly at the start of the two later lifecycle journeys before activating their direct fixtures, matching the repository recovery-journey rule.
- 2026-08-28: Catalog attempt 6 restored chrome, then proved the expanded panel's new top row sits outside the installed Messages viewport. Use the existing visible Lobby submenu and `activateUXLabNestedQuickState` helper for the two guest fixtures; remove the unreachable panel controls rather than adding tap workarounds.
- 2026-08-28: A bounded DEBUG draw-vote fixture and three isolated current-game lifecycle journeys cover setup host actions, turn non-host actions and resign cancel, draw voting, and the host draw-first confirmation without depending on Player Record.
- 2026-08-28: After six catalog attempts, the validation circuit breaker stopped further lifecycle UI retries. Setup-host proof succeeded, but the non-host and draw-vote routes remain unproven because the Messages host could not reliably expose the contracted DEBUG fixture controls. Another attempt requires explicit owner authorization after this disclosure.
- 2026-08-28: Fresh review requested that retained diagnostics not contain persistent participant identifiers. The diagnostic now records only `participant=known|missing`, and the focused unit test locks the redaction.
- 2026-08-29: Owner explicitly authorized one further lifecycle catalog attempt after the circuit-breaker disclosure. Attempt 7 replaced menu discovery with catalog-declared DEBUG launch defaults and split the prior two-state journey into isolated tests.
- 2026-08-29: Attempt 7 failed before production assertions because `simctl spawn ... defaults write <extension-bundle-id>` did not enter the Messages extension's PluginKitPlugin preferences container. The retained screenshot shows the default Turn-after-roll UX Lab panel, and launch evidence did not contain `Setup placement`. This is a fixture-injection boundary failure, not nondeterministic product state. The plugin data container is dynamically assigned and is not exposed through `simctl get_app_container`; no further retry is authorized in this plan.

## Validation and Outcome

- Automated: `git diff --check` passed; the focused host-boundary group passed 17 tests after one cold-start retry; `/tmp/UnluckySevens-session-focused.xcresult` passed 12 guidance/transport tests after the redaction change.
- Observable/judgment: setup-host lifecycle had passed in an earlier attempt. Owner-authorized attempt 7 failed at DEBUG launch-fixture injection before any production lifecycle assertion; retained evidence is under `output/ui-screenshot-harness/20260829T070213Z-iphone`. Non-host, draw-vote, and host-end artifacts remain blocked, and no further retry is authorized without owner approval.
- Deferred: two-account connected-device proof is required and will be reported honestly if no devices are available in this run.

No completion claim is permitted until every required contract row and reviewer passes.

- 2026-09-15 tracking consolidation: issue #7 closed as consolidated/not-planned with all outstanding session acceptance transferred to #2. This plan’s evidence and constraints remain active; the tracking closure does not mean session proof passed or reset any retry budget.
