# Outcome backlog — 2026-09-15 review

This dated classification maps every original issue to one authoritative open owner. GitHub owns live status/milestones. A local implementation, source test or tracking closure does not establish shipment. [Release plan](active/marketable-release-plan.md) owns ordering and decisions.

47 original open tickets become **41 open authoritative work/decision/verification tickets** after six tracking consolidations. Four removed items were umbrella epics, not extra implementation jobs. Two were overlapping execution tracking consolidated into their existing owners. **Zero features are claimed newly delivered, zero unique requirements discarded, zero later exclusions selected.**

## Original requirement → authoritative owner

| Original | Authoritative owner | Classification | Dependencies | Importance/rationale |
| --- | --- | --- | --- | --- |
| #2 | #2 | Remaining verification; #7 transferred | Existing session fixes; #44; real accounts | Critical: prove payload/session continuity once, shared by release matrix |
| #3 | #3 | Remaining verification | Approved #13–#19/#22/#25/#26/#42 UI | High: prevent regression of changed surfaces, not another redesign |
| #4 | #4 | Locally implemented; unshipped proof remains | Three accounts; identified fixed candidate | Critical: concurrent joins must not lose players |
| #5 | #5 | Evidence/decision needed | Before/after device profile | High if measured: optimize demonstrated latency only |
| #6 | #6 | Locally implemented; unshipped proof remains | Three accounts; fixed clients | Critical: competing accepts must converge |
| #7 | #2 | Overlapping tracking fully transferred; closed not-planned, not delivered | Successor contains transferred contract; original retained as history | Removes a second queue item without removing acceptance |
| #8 | #8 | Remaining integrated verification | #2/#4/#6/#11/#15/#43/#44/#47; exact build | Critical: assemble multiplayer/device evidence; do not reimplement fixes |
| #9 | #9 | Remaining calculation + UI checkpoint | #41 shared recap; canonical history/compatibility decision | Medium: memorable robber-impact recap; preserve distinct payout attribution |
| #10 | #10 | Remaining implementation | #6/#11/#47 correctness; lifecycle/privacy proof | Medium: less trade waiting; opt-in and secrecy requirements remain |
| #11 | #11 | Local eligibility fix; field diagnosis/proof remains | #6 shared trade evidence; #44/#47 | Critical: funded recipients must be able to accept |
| #12 | #12 | Rules decision then implementation | #46/#20 pacing; approved compatibility and two-player rules | High: smaller groups can play; no invented hybrid rules |
| #13 | #13 | Remaining UI checkpoint | #14 shared purchase surface; Core costs | High: players can plan purchases even when unavailable |
| #14 | #14 | Remaining UI checkpoint | #13 owns costs; owned-card state/legality | High: explain finding and playing cards without duplicate purchase UI |
| #15 | #15 | Shipped actions; local guidance and proof remain | #2 session binding; approved current-game UI | High: players can find resign/draw; do not restore retired game launcher |
| #16 | #16 | Atomic Core already exists; remaining UI checkpoint | Core legal targets; #14 card lifecycle | High: one understandable two-road draft/confirmation |
| #17 | #17 | Remaining copy/UI checkpoint | Core next actor/action; #43 delivery separate | High: async players know who acts next |
| #18 | #18 | Remaining query/UI checkpoint | Core production; #17 continuation; secrecy | High: players understand roll and own gains |
| #19 | #19 | Remaining UI checkpoint | #42/#22 shared orientation; Core public scoring | High: standings visible without revealing hidden VP |
| #20 | #20 | Preset/rules decision then implementation | #46; canonical compatibility; #12 reuse | High: bounded shorter-game choices; standard stays default |
| #21 | #21 | Sound comparison decision then implementation | Audio/lifecycle proof; owner listening checkpoint | Medium: tactile feedback; ambience choice still unresolved |
| #22 | #22 | Audit partly recorded; remediation/proof remain | #42 shared redundant cues; approved fixtures | High: color-independent play is a real usability requirement |
| #23 | #26 | Parent tracking consolidated; closed not-planned, not delivered | Successor contains transferred contract; original retained as history | Removes a second queue item without removing acceptance |
| #24 | #24 | Curriculum checkpoint then implementation | #26 shared entry; settled production controls | High: novices can learn by doing; no forced narrowing to experts |
| #25 | #25 | Remaining controls-tour checkpoint | #26 shared entry; stable controls | High: experienced players learn app interactions quickly |
| #26 | #26 | Remaining reference/shared learning entry; #23 transferred | #24/#25 integrated checkpoint; safe context preservation | High: help where confusion happens; shared entry implemented once |
| #27 | #40 | Parent tracking consolidated; closed not-planned, not delivered | Successor contains transferred contract; original retained as history | Removes a second queue item without removing acceptance |
| #28 | #37 | Parent tracking consolidated; closed not-planned, not delivered | Successor contains transferred contract; original retained as history | Removes a second queue item without removing acceptance |
| #29 | #34 | Parent tracking consolidated; closed not-planned, not delivered | Successor contains transferred contract; original retained as history | Removes a second queue item without removing acceptance |
| #30 | #30 | Data/backend decisions then implementation | #34 contract; #37 service choice; #35 verification; reuse #44 | Medium: answer product questions via aggregates, distinct from bug reports |
| #31 | #31 | Service/UI decision then implementation | #44 preview/export; #34/#37; #35 | High: players can report and receive optional replies without subscribing |
| #32 | #32 | Account decision then implementation; #36 transferred | #37/#39/#33/#38; #35 | High: continuity/migration plus post-first-game invitation in one journey |
| #33 | #33 | Partial display baseline; remaining profile work | #39 authority kept separate; profile UI checkpoint | High: local naming/preferences without registration |
| #34 | #34 | Decision/contract; #29 tracking transferred | #37 coordination; reuse #44 local contract; #38 history semantics | High prerequisite: one purpose/identifier/retention allowlist across services |
| #35 | #35 | Remaining operational/privacy verification | #30/#31/#32/#40 against #34; local #44 reused | Critical when services ship: deletion/consent/disclosures must work |
| #36 | #32 | Overlapping tracking fully transferred; closed not-planned, not delivered | Successor contains transferred contract; original retained as history | Removes a second queue item without removing acceptance |
| #37 | #37 | Architecture decision; #28 tracking transferred | Account/backend comparison; threat and recovery model | High prerequisite: chooses shared infrastructure, not multiple backends |
| #38 | #38 | Already delivered baseline + specific remaining audit | #32/#34 sync model; #39/#47 identity; shared ledger | High: protect existing history, resolve active-growth/reset/legacy gaps |
| #39 | #39 | Identity/migration decision then implementation | #47 evidence; #37 account integration; protocol approval | High: correct seats across devices; distinct from names and cloud profile sync |
| #40 | #40 | Remaining subscriptions/consent; #27 tracking transferred | #37 transport choice; #34 consent; #35 verification; #31 support separate | Medium: intentional game/product/research updates, not automatic enrollment |
| #41 | #41 | Remaining calculation + UI checkpoint | #9 shared recap composition; exact roll history | Medium: understandable dice story; different computation from Nemesis |
| #42 | #42 | Remaining composition checkpoint | #22 non-color cues; #19 public score integration | High: who owns which pieces, without a duplicate roster |
| #43 | #43 | Confirmed field symptom; root cause unconfirmed | #44 diagnosis; #2 host evidence; paired receipt/recovery | Critical: missing updates strand players |
| #44 | #44 | Foundation locally tested; remaining end-user capability | Persistence/hooks; preview checkpoint; privacy and paired evidence | Critical enabler: diagnose #43/#47 without a backend |
| #45 | #45 | Rules decision then implementation | Desert payout/city/ordering/compatibility decisions; #26 reference | Medium: requested variant retained; not silently canceled |
| #46 | #46 | Pacing decision, not duplicate target code | #20 implements targets; #12 informed by pacing | High enabler: decide match length vs async waiting vs local speed |
| #47 | #47 | Reported trigger; diagnosis needed | #44; compare existing-game/new-phone identity/state; #11 overlap | Critical: wrong hand counts and unusable buttons; no assumed cause |
| #48 | #48 | Final assembly/validation | Resolved pre-public scopes + candidate-specific evidence | Critical: truthful public release, not another feature implementation |

## Shared implementation owners

- Local diagnostics schema, logging/retention and preview/export: **#44**. #30 consumes it for separately approved remote reliability/usage ingestion, #31 consumes it for report attachment, #34 references its local contract, #35 reuses its local privacy proof. No second local diagnostic implementation.
- Player-facing history **#38**, editable local display profile **#33**, game credentials/seat authority **#39**, cloud account continuity and post-game invitation **#32** are separate outcomes. #37 chooses integration/backend; #34 owns data rules; #35 verifies operations.
- Feedback/support **#31**, aggregate usage metrics **#30**, and ongoing subscriptions **#40** can share approved infrastructure while preserving distinct purpose/consent/data boundaries.
- Learning entry/context preservation **#26**, beginner comprehension **#24**, controls familiarity **#25** share the transferred #23 integration checkpoint.
- Canonical purchase costs **#13** support the owned-card journey **#14**; no competing purchase affordance. #9/#41 share recap presentation, not calculations.
- #2 now includes #7 session proof; #8 and #48 reuse exact-build evidence rather than duplicating implementation. Existing session-plan constraints remain binding under #2.

## Player Record evidence and actual remainder

`PlayerRecordModel.swift` is byte-identical to Build 8 (`673813f`; SHA-1 a3d428ce53774cc3cf7d8203ae37c3dcbbb8bb76). Existing model/tests and the Build 8 release record support shipped results, streaks, awards, fastest-win turns and exact-group history. The ledger already has schema migration, corrupt-entry repair, keyed updates and an eight-finished-game cap, with tests. No fresh test execution occurred in this planning review.

#38 now focuses on uncapped active/abandoned growth policy, full reset and legacy/host-end/reconciliation semantics proof, privacy separation between the read-only projection and canonical snapshot storage, and eventual sync representation. Timestamp/duration/mode/extra-achievement additions remain explicit candidates to select. These are not reasons to rebuild the shipped record system or claim all history acceptance finished.

## Parallelizable lanes and shared bottlenecks

1. Reliability: #43/#47 investigation, #44 persistence/instrumentation; integrate already-written fixes and focused proof.
2. Gameplay orientation/learning: #17, then shared #13/#14 and #19/#22/#42 compositions; #26/#25/#24 once controls and checkpoint inputs are stable.
3. Account/data decisions: #37 and #39 threat/migration contract alongside #34 allowlist. Then #33/#38 local work and #32/#30/#31/#40 service slices with explicit ownership and shared infrastructure.
4. Game variety/recap: #46/#20/#12/#45 rules decisions; #9/#41 accounting can share a layout after history compatibility is settled.
5. Quality/sensory: #5 measurement and #21 comparison; #35 operational verification follows its service implementations.

Separate agents can own settled, non-overlapping slices; a coordinator serializes repository builds/tests and integrates shared UI/data/protocol changes. Hardware, owner checkpoints, compatibility decisions and inspection remain bottlenecks. More agents do not imply a duration promise or waive device proof. This review starts no new product implementation.

## Exact live-title changes

| Ticket | Previous title | New title |
| --- | --- | --- |
| #2 | Add Messages host-boundary regression coverage | Verify Messages host boundaries and same-game session continuity |
| #9 | Add robber-suppression nemesis insight to the end screen | Show post-game robber impact (Nemesis) |
| #12 | Epic: Add a supported 1v1 game mode | Decide and deliver the supported 1v1 ruleset |
| #13 | Keep build and Dev Card costs visible when actions are unavailable | Show build and Development Card purchase costs when unavailable |
| #14 | Clarify how to buy and when to play Development Cards | Explain where owned Development Cards go and when they can be played |
| #30 | Implement account-linked product insights and privacy-preserving diagnostics | Measure product usage with approved server-side analytics |
| #31 | Add in-app feedback with optional replies and previewable diagnostics | Submit player feedback and handle optional support replies |
| #32 | Implement optional account sync, guest migration, and account lifecycle controls | Deliver optional account continuity, migration and post-game invitation |
| #33 | Create an editable device-local player profile and per-game display names | Edit local player profiles and per-game display names |
| #34 | Define the telemetry, identity-separation, and retention contract | Define data, consent and retention contracts across product services |
| #35 | Complete privacy, deletion, and communications release readiness | Verify account, analytics and communications privacy controls |
| #37 | Decide CloudKit, Sign in with Apple, and account-backend boundaries | Choose the account/backend architecture and integration contract |
| #38 | Audit and address remaining gaps in the shipped local Player Record | Audit remaining Player Record retention, migration and result semantics |
| #39 | Store installation identity in Keychain and introduce game-scoped actor credentials | Define and implement game-scoped identity and device migration |
| #40 | Add separate communication preferences for game, product, and research updates | Manage game, product and research subscriptions and consent |
| #41 | Show post-match roll distribution on the victory screen | Show post-game dice distribution |
| #44 | Add bounded local reliability diagnostics and explicit report export for Beta 1.1 | Capture local reliability diagnostics and preview/export a report |
| #46 | Explore game-speed presets for shorter and longer games | Decide pacing presets; reuse victory-target implementation |

Readback verified all original bodies/titles/memberships: 41 open (9 Beta 1.1, 11 Beta 1.2, 3 Beta 1.3, 17 expanded pre-public, 1 Public 1.0); all six closures use NOT_PLANNED and retain original requirement text plus successor links. The archived #28 child checklist uses plain links to avoid GitHub automatic checking on consolidation. No delivered-feature closure.
