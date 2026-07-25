# Settings, Rules, and Click-Through Tutorial

## Purpose and Outcome

Deliver one coherent utility pass: a unified Settings surface with a local Skip Animations preference and read-only game facts, a concise Rules reference, and a sixteen-step click-through Tutorial mounted over the real game shell without publishing game state. Success means the lobby and gameplay entry points are clear, the tutorial accurately covers the playable first-beta loop, and app-authored motion consistently respects both the local preference and system Reduce Motion.

Parent: [Lobby Invite Screen](lobby-invite-screen.md).

Corrective dependency: [Physical Trade Surface Correction](../completed/physical-trade-surface-correction.md). The approved correction replaced the inherited legacy composer and maritime presentation while preserving Tutorial's production-control reuse and read-only behavior.

## Execution Settings

- Validation profile: `standard`
- Delivery posture: `checkpointed`
- Rationale: behavior and content are settled, but callout composition across compact Messages geometry requires user judgment before productionization.

## Context and Boundaries

- Settings owns Skip Animations, read-only Standard/Balanced/10-point facts, and Show Rules. It does not expose Tutorial or editable variants.
- Tutorial is available throughout lobby states only. It opens on the first gameplay lesson under a one-time navigation veil; the first tap dismisses that veil without advancing. Afterward, tapping the left or right half moves backward or forward, while Exit remains visible and the final right-side tap finishes.
- Tutorial data is deterministic and local. It cannot publish canonical state, touch transcript transport, or mutate a real game.
- Skip Animations is device-local and outside Core state, transport payloads, hashes, and Messages authority.
- `ULS_CoreGame`, `ULS_Transport`, protocol fields, rules, and the preserved `game-setup-options` branch are excluded.
- Screenshot evidence remains outside Git.

## Milestones / Plan of Work

1. Establish enum-driven utility routing, local preference ownership, motion policy, Settings, Rules, and the sixteen-step tutorial model.
2. Build the smallest honest DEBUG checkpoint with real components and deterministic fixture data. Prove Settings, one dense middle tutorial step, and the final awards/strategy step.
3. Generate, build, drive the installed Messages harness, capture no more than three representative states, and stop for user review.
4. After approval, productionize all lobby/game routes, complete the animation audit including SceneKit dice completion, add focused tests, update owner docs, run fresh standard reviews, and execute the completion gate.

## Approval Gate

Authority: user.

Proof: direct installed-simulator captures using production components and deterministic fixtures. The current evidence set is the navigation veil plus all sixteen gameplay microsteps.

Round budget: two representative visual rounds by default. The user approved the visual direction on 2026-07-21, retaining invisible navigation and accepting the remaining critique fixes for productionization; the later language audit approved the combined final Strategy card.

## Verification Contract and Fresh Review

<!-- verification-contract:start -->
| ID | Class | Source | Acceptance | Verification | Evidence | Status | Rationale |
| --- | --- | --- | --- | --- | --- | --- | --- |
| SRT-001 | mechanical | user request | Skip Animations defaults off, persists locally, never enters canonical state or transport, and yields an immediate authoritative dice result with one completion | focused unit tests and code inspection | test:11-focused-unit-tests; ui:testSkipAnimationsPersistsWhenSettingsReopens; review:behavioral-2026-07-21 | pass | The preference is presentation-local, the motion policy has explicit precedence tests, and the dice completion gate is one-shot |
| SRT-002 | observable | user request | Lobby and gameplay Settings expose Experience, Current Game, and Show Rules with no Tutorial row or editable variants | installed UI journey and direct still inspection | ui:testCaptureSettingsRulesTutorialCheckpoint; ui:testGameplaySettingsOpensOverTheLiveTable; artifact:final-checkpoint-settings | pass | Both routes preserve their visible origin beneath the same centered utility card, and Rules pushes within that card |
| SRT-003 | observable | user request | The tutorial contains exactly sixteen ordered gameplay microsteps, preceded by a transient navigation veil whose first tap only dismisses it; it has no publication path and returns to its lobby origin | focused tests, installed UI journey, and source inspection | test:GameTutorialStepTests; ui:testCaptureEveryTutorialScreen-2026-07-25; ui:testCaptureSettingsRulesTutorialCheckpoint | pass | The navigation veil plus all sixteen lessons passed in the installed Messages host; the inert production shell has no conversation or publication callback |
| SRT-004 | observable | accessibility contract | Callouts remain legible in compact geometry, accessibility sizes fall back to ordered guidance, preview controls are hidden from VoiceOver, and interactive controls remain at least 44 points | UI assertions, source review, and direct still inspection | ui:testPlaceTutorialFirstTapZonesCheckpoint-accessibility-xxxl; ui:testCapturePhysicalTradeCorrectionTutorialCheckpoint; review:language-accessibility-2026-07-25 | pass | The three Trade lessons use concise production-anchored prompts; large-text and spoken language remain aligned with the visible action vocabulary |
| SRT-005 | judgment | user request and design system | Settings reads as a compact utility surface and Tutorial teaches the real game UI without becoming a fake playable shell | explicit user verdict after corrected Trade guidance, compact exit, and combined Strategy review | report:owner-approval-2026-07-25; review:language-product-ux-2026-07-25 | pass | The user approved the concise prompts, compact non-covering exit, helper-text reduction, and final three-tip Strategy card |
| SRT-006 | mechanical | repository boundaries | Core, transport, protocol, rules, and the preserved setup-options branch remain unchanged | git diff inspection and focused tests | command:git-diff-check-2026-07-21; review:constraint-audit-2026-07-21 | pass | Final diff inspection found no Core, transport, protocol, rule, or setup-options changes |
<!-- verification-contract:end -->

<!-- fresh-review:start -->
| Reviewer | Required | Verdict | Evidence |
| --- | --- | --- | --- |
| constraint-auditor | yes | pass | review:constraint-audit-2026-07-21; contract:SRT-001-through-SRT-006 |
| architecture | no | not-applicable | No Core, transport, or protocol change is planned |
| behavioral | yes | pass | review:behavioral-2026-07-21; test:11-focused-unit-tests; ui:persistence-gameplay-and-18-state-replay |
| product-ux | yes | pass | User approved the restored Trade guidance, compact exit, and combined Strategy treatment; the app-language audit records the complete verdict |
<!-- fresh-review:end -->

## Living Record

### Progress

- [x] Validation profile, delivery posture, scope, exclusions, and approval gate locked.
- [x] DEBUG checkpoint implemented and mechanically validated.
- [x] The first two visual directions were inspected and rejected; the checkpoint was revised in place.
- [x] Centered-overlay Settings and board-mounted coach-mark Tutorial captures presented for user verdict.
- [x] Approved Settings/tutorial direction productionized; corrected production Trade inheritance approved and verified by the focused child plan.
- [x] Restore visible, compact, anchored instructions to the three corrected Trade tutorial states and obtain fresh owner approval without changing trade behavior or geometry.
- [x] Replace the invalid full-width tutorial title/Exit strip with a compact exit control in the existing top-left chrome footprint and recapture the installed first board state.
- [x] Obtain owner approval for the compact tutorial exit treatment before closing the corrective slice.

### Decisions

- 2026-07-20: Settings includes Skip Animations, read-only game facts, and Show Rules. Tutorial remains a distinct lobby-only destination.
- 2026-07-20: Tutorial uses real non-interactive UI previews, with anchored callouts at standard sizes and ordered guidance at accessibility sizes.
- 2026-07-20: The last step owns VP sources, Longest Road, Largest Army, winning at ten, and brief strategy.
- 2026-07-20: Tutorial progress is not persisted; Exit and Done return to the invoking lobby state.
- 2026-07-20: User rejected round one because its tutorial was a diagrammatic mock and Settings looked like a generic system form. Round two must use the production board renderer and the game-overlay visual language.
- 2026-07-20: User clarified that Settings must be a centered card over the exact lobby/game surface that opened it, not a replacement sheet. The tutorial must keep one main board visible and teach actions with small overlays and highlights, not a separate explanatory page or paragraph card.
- 2026-07-20: User clarified that the production board renderer alone is still not the actual board experience. The checkpoint must mount coach marks over the full production `GameShellView`, position each instruction beside its real target, replace marks on advance, and use left/right screen tap zones instead of persistent Back/Next controls. A transient opening veil teaches the tap convention; Exit remains visible and accessibility exposes explicit navigation actions.
- 2026-07-21: Invitation is not a tutorial lesson. A transient split navigation veil appears over the setup board first; its first tap dismisses the veil without advancing, then the screen halves provide back/next navigation.
- 2026-07-21: Each instruction must be adjacent to one real action target, so the original broad lessons were decomposed into seventeen gameplay microsteps rather than crowding unrelated phases into one screen. The sequence covers setup, rolling/production, hand/building, three trade states, three seven/robber states, development cards, ending/sending, strategy, and final scoring/awards.
- 2026-07-21: The user requested evidence for every tutorial state. This corrective approval round therefore includes eighteen tutorial captures (navigation veil plus seventeen microsteps) as an explicit exception to the representative-capture cap.
- 2026-07-21: The user approved the board-mounted tutorial and centered Settings direction. Invisible left/right tutorial navigation is an intentional interaction and remains; the opening veil is its one-time explanation. Productionization must address the other accepted critique findings: coach/target collisions, causal copy, final-step overload, accessibility-equivalent guidance, lighter Settings treatment, and DEBUG/release preview parity.
- 2026-07-21: The later Trade walkthrough exposed that the reused production player composer and maritime routes still carried legacy panel styling. SRT-005 and product/UX review are reopened and depend on the focused Physical Trade Surface Correction plan; prior non-Trade evidence remains valid.
- 2026-07-23: The user approved the corrected production Trade family. Tutorial continues to mount the actual production controls and board with no trade-specific callout boxes or publication path, resolving the reopened SRT-005 dependency.
- 2026-07-24: Follow-up inspection found that removing the rejected Trade callout boxes also removed all visible task guidance from the Give/Get, recipient, and maritime tutorial states. Reopen only SRT-004/SRT-005; restore one concise game-styled prompt adjacent to each actual production action, keep the trade family and board geometry unchanged, and stop after three inspected captures for owner approval.
- 2026-07-24: The all-screen review rejected the full-width tutorial title/Exit strip because it covers the production surface and teaches a geometry players never use. Remove the duplicate visible title strip; place a compact circular Exit control over the inert top-left settings footprint on non-Trade steps, retain the production Trade close control, and preserve lesson title/guidance for accessibility.
- 2026-07-24: The replacement compiled, the all-screen replay passed 18/18 after explicitly installing the fresh Messages extension, and the focused first-screen checkpoint passed after updating UI assertions to use the nonvisual progress accessibility marker. The inspected capture shows an opaque circular × replacing the disabled settings gear with unchanged board geometry; owner verdict remains the checkpoint gate.
- 2026-07-25: Supersede the separate strategy and final-scoring microsteps with one final `Strategy` lesson. It dims the still-mounted board and presents one centered tabletop card with three ordered rows for probability dots, purposeful Road/Dev Card investment, and scoring. This reduces the implemented sequence from seventeen lessons to sixteen and requires fresh navigation, accessibility-order, and all-screen proof after productionization.
- 2026-07-25: The owner approved the restored Trade prompts, compact non-covering exit, helper-text policy, first-pair-only setup guidance, passive discard treatment, and combined Strategy card. The installed navigation veil plus sixteen-lesson replay, accessibility language review, and standard app-language completion gate passed.

### Discoveries

- Existing DEBUG fixtures already cover lobby, setup, pre/post-roll, trade, discard, robber, and game-over states, but production tutorial data must remain independent of DEBUG-only fixtures.
- The current gameplay Settings button is only a callback hook, and the existing lobby rules sheet is a four-row stub; neither is a production destination for this contract.
- The iOS 26.5 simulator runtime twice terminated CoreSimulatorService during Messages-host automation. The established iOS 26.0 simulator rendered the same installed checkpoint; the earlier eight-step draft reached its final state in a focused continuation journey before the invitation lesson was removed.
- Round one exposed the wrong abstraction: reusing individual props did not satisfy the board-first contract. Round two composes deterministic data through the production `BoardSceneView`, with real terrain, tokens, structures, roads, ports, robber, and legal highlights.
- Round-two Settings uses a transparent modal backdrop and a single felt command panel rather than an inset grouped list, keeping the system Toggle while matching the tabletop hierarchy.
- The Settings card initially lived inside a full-screen `NavigationStack`; that stack painted an opaque gray canvas and visually erased the origin despite the overlay route. Constraining navigation to the centered card preserves the exact invitation/game surface around the panel and keeps Rules in the same utility context.
- Mounting Settings directly in `LobbyShellView` preserves the originating invitation/lobby beneath it; a restrained scrim and compact centered card keep that origin legible. Tutorial steps now vary highlights, action props, and at most three coach marks while retaining the same production board surface.
- The third tutorial checkpoint uses an inert `GameShellView` driven by deterministic UX fixtures, so the visual hierarchy is the exact gameplay shell rather than a parallel board composition. A transparent navigation layer consumes all tutorial taps before they can reach gameplay.
- Production uses a dedicated deterministic local state composer rather than DEBUG fixtures. The tutorial view model renders that state directly with a `.tutorial` source, while the production shell is hit-test disabled and exposes only a preview summary plus ordered coach content to accessibility.
- The largest accessibility Dynamic Type run exposed an oversized navigation veil. Tutorial chrome is now capped at the largest non-accessibility size, the inert production preview renders at a stable readable size, and the instructional content switches to an ordered large-text guide.
- The corrected production Trade family retained its real controls but the three Trade tutorial definitions had empty callout arrays. Restoring one compact prompt per state required the stable production panel anchors; a button-local maritime anchor did not propagate through the trade surface, while the existing maritime panel anchor rendered the prompt immediately above the exchange and confirmation action.
- Repeated checkpoint runs revealed that the Trade walkthrough test inherited the gameplay fixture it loads after completing its geometry comparison. The journey now restores DEBUG chrome and explicitly loads the invitation lobby fixture before opening Tutorial, making the checkpoint independent of simulator history.

## Validation and Outcome

Settings and the board-mounted Tutorial are productionized. The inherited Trade visual acceptance was resolved by the approved Physical Trade Surface Correction; the evidence below remains the route and non-Trade proof for this parent slice.

Validated on 2026-07-20:

- `bash ./scripts/gen.sh` succeeded.
- MessagesExtension simulator build succeeded.
- Focused Settings/Tutorial unit suite passed 10 tests with zero failures.
- UI test build succeeded on iPhone 16e / iOS 26.0.
- `testAdvanceOpenTutorialToVictoryCheckpoint` passed with zero failures.
- `git diff --check` passed.
- Three local, ignored workbench captures from the earlier eight-step draft were inspected: Settings, Trade, and VP/Awards/Winning/Strategy. They were superseded by the current sixteen-microstep all-screen capture set.
- Round two generated and built successfully, and `testAdvanceOpenTutorialFourStepsToVictoryCheckpoint` passed with zero failures in 10.895 seconds.
- Three round-two captures were inspected: game-styled Settings overlay, actual-board build step, and actual-board VP/Awards/Winning/Strategy step.
- The clarified checkpoint passed focused installed-host journeys for opening centered Settings from a clean invitation fixture (7.081 seconds) and advancing the visible tutorial controls to the build step (8.274 seconds). The self-contained Settings placement journey also passed after the card was tightened (27.960 seconds). Local evidence is `settings-centered-intro.png` and `tutorial-overlay-build.png`.
- The actual-shell revision passed a first-screen tap-zone journey (25.117 seconds), a self-contained advance-to-Trade journey (32.608 seconds), and a continuation advance-to-Trade journey (8.688 seconds). The first step teaches left/back and right/next without rendering Back/Next controls; Trade opens the real production chooser and anchors its coach marks beside Player Trade and Maritime / Bank. Local evidence is `tutorial-actual-shell-tap-zones.png` and `tutorial-actual-shell-trade.png`.
- On 2026-07-21, the final installed-host `testCaptureEveryTutorialScreen` replay passed in 80.870 seconds with the navigation veil and all sixteen gameplay microsteps. Direct inspection drove repairs to the build, recipient, bank, and final scoring states; all now use the production shell and real action surfaces. Evidence is `/tmp/uls-tutorial-all-final-20260721.xcresult` and the ignored `all-final` workbench directory.
- After the Settings navigation-stack correction, `bash ./scripts/gen.sh`, the `UnluckySevens-Workspace` UI-test build, focused `GameTutorialStepTests` (3/3), `git diff --check`, and `testCaptureSettingsRulesTutorialCheckpoint` all passed. The checkpoint journey took 71.361 seconds and proved centered Settings over the visible invitation, Rules navigation/back, step 8 Player Trade, step 16 victory, Done, and return to origin. Evidence is `/tmp/uls-settings-checkpoint-fixed2-20260721.xcresult` and the ignored `checkpoint-final` workbench directory.
- After splitting strategy from scoring/awards, the 18-state replay (navigation veil plus 17 lessons) passed in 92.044 seconds. Evidence is `/tmp/uls-tutorial-polish-retry-20260721.xcresult`.
- Productionization moved utility routing to `MessagesRootView`, made Settings available over lobby and gameplay, and replaced the release-only board fallback with a dedicated local-only tutorial state composer feeding the same production `GameShellView` in DEBUG and release. Debug and Release simulator builds passed.
- The final focused unit suite passed 11 tests with zero failures, covering preference default/persistence, motion precedence, settings summaries, the exact seventeen-step sequence and final split, and one-shot dice completion.
- `testSkipAnimationsPersistsWhenSettingsReopens` passed in 28.743 seconds. `testGameplaySettingsOpensOverTheLiveTable` passed in 32.055 seconds.
- The final production-shell `testCaptureEveryTutorialScreen` replay passed in 79.398 seconds and captured the navigation veil plus all seventeen lessons. The final checkpoint passed in 67.602 seconds and direct inspection confirmed the centered Settings card, real Trade surface, single final scoring coach, correct player label, and no hidden Hand artifact.
- At accessibility-extra-extra-extra-large, `testPlaceTutorialFirstTapZonesCheckpoint` passed in 30.006 seconds after the veil and preview typography correction. Direct inspection confirmed the ordered guide remains legible over the stable production board.
- Fresh constraint, behavioral, and product/UX audits passed. They inspected SRT-001 through SRT-006, the owner docs, the final diff, focused test output, the three final checkpoint captures, and the accessibility capture. No blocking finding remains.
- `make completion-gate PLAN=docs/exec-plans/active/settings-rules-tutorial.md` passed under the standard profile after removing 275 ignored iterative workbench artifacts (160 MB) required by the repository cleanup policy.

Corrective Trade-guidance checkpoint on 2026-07-24:

- `bash ./scripts/gen.sh` succeeded.
- Focused `GameTutorialStepTests` passed 4/4, including an assertion that every Trade lesson owns a production-anchored prompt.
- `testCapturePhysicalTradeCorrectionTutorialCheckpoint` passed in 88.817 seconds after the journey was made fixture-independent. It traversed the real Messages host, captured Give/Get, recipient selection, and maritime exchange, completed the tutorial, and rechecked production geometry.
- Direct inspection of the three fresh attachments confirmed that each concise prompt is visible beside the actual production action without shrinking or replacing the approved Trade UI. Evidence is `Test-UnluckySevens-Workspace-2026.07.24_01-38-03--0700.xcresult` and `/tmp/uls-tutorial-trade-guidance-approved.oFhcb6`.
- The owner approved the restored prompts and compact exit during the complete language/tutorial review. The later installed replay covered the navigation veil plus all sixteen lessons, the 262-test MessagesExtension suite passed, and the standard [App Language Audit](app-language-audit.md) completion gate passed with fresh product/UX, accessibility, and constraint review.

The final delivery response records the same validation and doc-freshness outcome.
