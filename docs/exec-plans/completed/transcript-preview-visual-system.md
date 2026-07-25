# Transcript Preview Visual System

## Purpose and Outcome

Replace the generic nested-card artwork used by collapsed Messages previews with snapshots of the real lobby table and production board. The current rich message should show canonical state clearly after the Messages host scales it down, while prior messages collapse to their summaries through the existing per-game session.

Parent: [Phase 14](phase-14-ui-design-bubble-polish-and-trust-surfaces.md).

## Execution Settings

- Validation profile: `standard`
- Delivery posture: `direct`
- Rationale: The user approved the five-family direction and explicitly asked to close the slice, so the previously checkpointed trade and game-over compositions are productionized and verified.

## Context and Boundaries

- `MSMessage.url`, transcript caption, and summary remain canonical/presentation boundaries; this work changes image artwork only.
- The image stays full bleed and carries no embedded action label because Messages supplies a separate caption.
- Lobby images must render the production `LobbySeatTableView` from canonical roster state.
- Board images must render through `GameBoardSnapshotRenderer`; setup withholds number tokens and post-setup states include them.
- The production robber continues to reuse `RobberPieceGeometry` through the board snapshot renderer.
- Screenshot evidence remains outside Git.

## Milestones / Plan of Work

1. Audit and reject the prior handcrafted preview system through two checkpointed visual rounds.
2. Obtain user approval for a real-component snapshot architecture.
3. Route lobby updates to the real seat table, setup to a numberless production board, and later states to the current production board.
4. Inspect representative renderer artifacts, verify transport/session invariants, update owner docs, and run standard-profile verification.
5. Document the shared player-facing state-language matrix and render one canonical five-family comparison using production components.
6. Route live trade messages to the shared receipt and game-over messages to the final board plus compact score strip after approval.

## Approval Gate

Authority: user.

Proof: no more than three inspected representative captures using the shipping renderer size and real production geometry. The real Messages host is used for at least the invite state so scaling and system caption behavior remain honest.

Round budget: two visual rounds by default. The user explicitly requested all five families in the comparison and approved closeout after inspecting the direction. The approval gate is satisfied.

## Verification Contract and Fresh Review

<!-- verification-contract:start -->
| ID | Class | Source | Acceptance | Verification | Evidence | Status | Rationale |
| --- | --- | --- | --- | --- | --- | --- | --- |
| TPV-001 | mechanical | architecture and UI flows | Production changes remain presentation-only and preserve URL payload, captions, summaries, fail-soft behavior, and per-game session selection | source diff plus focused copy, renderer, transport, and compact-state tests | command:xcodebuildmcp-focused-tests-2026-07-24 | pass | Twenty focused tests passed across copy/rendering and transport/session behavior; no protocol or engine code changed |
| TPV-002 | observable | QA and Messages-host lessons | Waiting lobby, joined lobby, numberless setup board, and normal board render at the shipping canvas size without clipping or raster degradation | renderer attachments and direct artifact inspection | artifact:/private/tmp/unlucky-sevens-real-transcript-v2-attachments | pass | All four production-component artifacts were inspected at the 360×260 logical canvas; lobby PNGs use 720×520 backing pixels and board PNGs use 1080×780, with roster labels, open seats, board edges, ports, tokens, pieces, and robber clear |
| TPV-003 | judgment | DESIGN and user direction | Transcript images reuse actual lobby and board components rather than maintaining a parallel illustration system | explicit user verdict after architecture correction | report:user-approved-real-component-snapshots-2026-07-24 | pass | User approved dynamic lobby-table and real-board snapshots and authorized implementation |
| TPV-004 | mechanical | checkpoint boundary | Productionization removes superseded handcrafted artwork and maps every lobby/setup/turn/game-over state to production components | source inspection and focused tests | command:TranscriptBubbleCopyTests+TranscriptBubbleImageRendererTests | pass | Handcrafted action kinds/drawing were removed; lobby, numberless setup, and numbered board routing are covered |
| TPV-005 | observable | user follow-up and adaptive UI guidance | Shared robber artwork is smaller and centered on its tile at compact transcript, standard phone, and larger board reference sizes | scene assertions plus direct rendered artifacts at each reference size | artifact:/private/tmp/UnluckySevensRobberSizes-v1.xcresult | pass | Robber geometry is centered and radius-scaled at 240×180, 360×260, and 768×600; all three direct renders were inspected |
| TPV-006 | observable | user follow-up and Messages-host lessons | The shared host wrapper is audited in Messages, while representative setup, turn, and game-over artwork/captions are audited through their shipping renderer and copy paths | installed-host capture, direct renderer artifacts, and focused copy tests | artifact:/private/tmp/UnluckySevensRobberEvidence-v1.xcresult | pass | The host crop/caption treatment is state-invariant and already proven by the installed invite; setup, turn, and game-over now each have a direct shipping-renderer test, with setup numberless and later states using the numbered current board |
| TPV-007 | mechanical | UI flows and presentation ownership | One owner-doc matrix maps canonical game conditions to forward-looking amber prompts, past-tense transcript outcomes, and preview families without changing engine or protocol semantics | exhaustive switch/publish-call audit plus documentation inspection | report:docs/product-specs/ui-flows.md-2026-07-24 | pass | Bubble Experience inventories all 28 current semantic outcomes, separates amber instructions from transcript receipts, defines live/resolved trade routing, and excludes non-published local or derived state |
| TPV-008 | judgment | user-approved preview family direction | Lobby, setup, gameplay, trade, and game-over comparisons reuse actual app components and one canonical fixture without invented illustration or inconsistent board seeds | five-family renderer artifacts and explicit user verdict | artifact:/private/tmp/UnluckySevensTranscriptCloseout-v3.xcresult | pass | User approved closeout; all five shipping 360×260 families were rerendered from the Avery/Maya/Theo fixture, and the live trade receipt plus final score strip were directly inspected |
<!-- verification-contract:end -->

<!-- fresh-review:start -->
| Reviewer | Required | Verdict | Evidence |
| --- | --- | --- | --- |
| constraint-auditor | yes | pass | Fresh Terra-medium follow-up review found no functional or boundary violations; two P2 evidence gaps were resolved with direct three-size and game-over render artifacts |
| architecture | no | not-applicable | Presentation-only prototype does not change boundaries |
| behavioral | no | not-applicable | No product or transport behavior changes |
| product-ux | yes | pass | Fresh review found lobby hierarchy crisp and scannable and both board states full-bleed, legible, and unclipped |
<!-- fresh-review:end -->

## Living Record

### Progress

- [x] Validation profile, checkpoint boundary, representative states, and approval authority locked.
- [x] Existing eighteen-state gallery and one real sent invite bubble audited.
- [x] DEBUG-only three-state comparison implemented and inspected.
- [x] User direction approved.
- [x] Approved system productionized and representative artifacts inspected.
- [x] Fresh review passed.
- [x] Completion gate passed.
- [x] Follow-up robber adaptation and remaining preview-family audit passed.
- [x] Player-facing state-language matrix documented.
- [x] Five-family production-component comparison rendered for approval.
- [x] Trade/game-over routing productionized after approval.

### Decisions

- 2026-07-24: The comparison removes the inset card, top stripe, circular `7` badge, and embedded action label. Apple’s caption owns readable status; the image owns one physical moment.
- 2026-07-24: Lobby Invite, Roll Seven, and Robber are the representative archetypes because together they exercise identity, dice/action, and character/state imagery.
- 2026-07-24: A four-settlement lobby alternative was rendered and rejected during the first round because the separated pieces read as generic clip-art. Round one temporarily retained the robber-and-dice composition before the user redirected the invite in round two.
- 2026-07-24: User rejected the prototype shadows and requested a static board without tiles for the first invite. Round two removes both ground shadows and die drop shadows from all three states. Lobby Invite now shows a fixed top-down frame with nineteen empty hex sockets; it does not derive from or imply live game state.
- 2026-07-24: The user rejected maintaining newly drawn preview materials and approved a real-component snapshot system. Lobby images render the actual lobby seat table from the canonical roster, setup images render the real SpriteKit board without number tokens, and turn/game-over images render the actual current board. Prior handcrafted checkpoint artwork is superseded and should be removed.
- 2026-07-24: Reusing the same `MSSession` remains essential. Apple’s documented behavior replaces the prior rich message with its summary and moves the newest rich state to the bottom, so each canonical lobby update may carry the freshly rendered roster without leaving a stack of large images.
- 2026-07-24: Follow-up audit found the shared board robber oversized at compact sizes because a 30-point floor dominated radius-based scaling, and its explicit negative-Y offset prevented tile centering. The correction must live in `GameBoardScene`, not in transcript-only rendering.
- 2026-07-24: The follow-up uses one installed Messages capture to verify the state-invariant host crop/caption wrapper, then verifies each state-specific image through the shipping renderer. A temporary attempt to publish UX Lab fixtures was removed because the lab intentionally guarantees local, no-send behavior; no capture-only production or DEBUG behavior remains.
- 2026-07-24: The user requested a durable state-language contract plus five preview families. The slice returns to checkpointed delivery because trade and game-over require new component compositions; lobby, setup, and gameplay remain locked.
- 2026-07-24: The comprehensive event audit found 28 current semantic outcomes: three lobby publications, five setup outcomes, nineteen turn intents, and one game-over override. Live trades use a conversation-wide, non-interactive receipt; accepted or fully declined trades return to the board. Prompt-only states, errors, drafts, private hand changes, payouts, and award side effects do not create independent transcript events.
- 2026-07-24: The user approved closeout. Shipping routing now uses the neutral public receipt for offers, counters, and partial declines while an offer remains live; accepted and final-declined outcomes return to the numbered board. Game over renders the final board with a compact winner and score strip.

### Discoveries

- The real Messages host preserves the 360:260 artwork ratio and adds a separate caption below it. The current renderer—not system cropping—is responsible for the cramped nested-card appearance.
- A UI-test pass can still capture a stale installed Messages extension after a successful build. Explicitly reinstalling `UnluckySevensApp.app` and terminating Messages produced the valid host artifact.

## Validation and Outcome

Checkpoint evidence:

- `bash ./scripts/gen.sh` — passed after the production source move.
- `MessagesExtension` simulator build — passed without errors or warnings.
- `TranscriptBubbleCopyTests`, `TranscriptBubbleImageRendererTests`, and the representative production board snapshot test — 10 passed.
- `TranscriptTransportSupportTests` and `CompactStateTransportTests` — 10 passed; URL payload, summary, image, and selected/cached session behavior remain intact.
- `/private/tmp/unlucky-sevens-real-transcript-v2-attachments` — waiting lobby, three-player lobby, numberless setup board, and numbered game board inspected at shipping dimensions.
- Fresh constraint/product-UX review — passed with no functional or visual findings; its one P2 evidence-record correction was applied.
- `make completion-gate PLAN=docs/exec-plans/active/transcript-preview-visual-system.md` — passed for the standard profile.
- `GameBoardSceneTests/testRobberScalesAndCentersAcrossBoardReferenceSizes` plus setup/turn renderer tests — passed; robber centering and scale were checked at 240×180, 360×260, and 768×600.
- `/private/tmp/UnluckySevensRobberAdaptive-v1-attachments` — updated numberless setup and numbered turn boards inspected with the corrected robber.
- `/private/tmp/UnluckySevensRobberSizes-v1.xcresult` — direct 240×180, 360×260, and 768×600 board renders attached and inspected after the reviewer requested explicit cross-size visual proof.
- `/private/tmp/UnluckySevensRobberEvidence-v1.xcresult` — direct setup, turn, and game-over renderer coverage passed.
- `bash ./scripts/gen.sh` — passed for the five-family checkpoint harness.
- `/private/tmp/UnluckySevensFiveFamilyCheckpoint-v7.xcresult` — the five-family production-component gallery test passed and emitted 3× backing-scale lobby, setup, gameplay, trade, and game-over artifacts.
- `bash ./scripts/gen.sh` and the `MessagesExtension` simulator build — passed after productionizing the final trade and game-over renderers.
- `/private/tmp/UnluckySevensTranscriptCloseout-v3.xcresult` — 14 focused copy and renderer tests passed. The five 3× production-family artifacts were exported and inspected; live/resolved multi-recipient trade routing and the final score visual are covered.
- `make completion-gate PLAN=docs/exec-plans/active/transcript-preview-visual-system.md` — passed for the standard profile after the approval gate and production routing landed.

The user approval gate is satisfied, all five preview families route through the shipping renderer, and this plan is closed.
