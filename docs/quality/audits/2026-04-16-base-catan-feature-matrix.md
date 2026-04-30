# 2026-04-16 Base Catan Feature Matrix

Supersession note: this matrix is a historical phase-13 snapshot. Several rows describe temporary `summaryText`, raw-intent, pending-join, and response-application constraints that have since been removed or changed. Use the owner docs, active ExecPlan, QA runbook, and [2026-04-27 Pre-TestFlight Repo Cleanup Audit](./2026-04-27-pre-testflight-repo-cleanup-audit.md) for current TestFlight readiness.

## Summary

This document is the strict feature matrix for the current MVP promise:

- full standard base-game Catan rules
- playable as an async iMessage game
- usable through the product UI rather than debug-only fallbacks

It exists to answer one question precisely:

- which experiences are truly done
- which are only engine-complete
- which are UI-complete but not device-signed off
- which are still blocked by the Messages host/transport substrate

Use this matrix instead of chat memory when deciding whether a feature belongs to:

- phase 13 host/recovery work
- the deferred phase-12 gameplay tail
- or a later polish phase

## Status Guide

### Engine / Protocol

- `Yes`: rules/protocol behavior exists with direct code and test coverage
- `Partial`: some behavior exists, but the full locked contract is not yet covered
- `No`: not implemented

### Product UI

- `Yes`: the product shell exposes a real path for the feature
- `Partial`: some product path exists, but the flow is brittle, incomplete, or still falls back to intent/debug-era behavior
- `No`: not exposed as a real player-facing flow

### Two-Device Confidence

- `Signed off`: completed on real devices with current architecture
- `Not signed off`: code/tests exist, but there is no authoritative real-device completion pass
- `Fragile`: works in some cases but is still architecture-boundary dependent
- `Blocked`: known product failure or known architecture blocker prevents calling it complete

## Base-Game Experience Matrix

| Experience | Engine / Protocol | Product UI | Two-Device Confidence | Evidence | Main blocker or note | Current owner |
| --- | --- | --- | --- | --- | --- | --- |
| Invite bubble creation and open-game entry | Yes | Yes | Not signed off | `TranscriptTransportSupportTests`, `MessagesRootRouteTests` | Entry works, but transport still relies on the temporary `summaryText` bridge. | Phase 13 |
| Join lobby | N/A | Partial | Fragile | `LobbyScreenModelBuilderTests`, `LobbyDriverViewModelIdentityTests`, [phase boundary audit](./2026-04-16-phase-boundary-audit.md) | Join still depends on surfaced messages plus device-local `pendingJoiners`. | Phase 13 |
| Host start and roster lock | N/A | Partial | Fragile | `LobbyDriverViewModelIdentityTests`, [phase boundary audit](./2026-04-16-phase-boundary-audit.md) | Start path still assembles roster from device-local pending joins instead of a transcript-authoritative ledger. | Phase 13 |
| Snake-order setup placement | Yes | Yes | Not signed off | `SetupStateMachineV1Tests`, `SetupInteractionResolverTests`, `GameBoardCommitCoordinatorTests` | Product board flow exists; full real-device match signoff is still missing. | Phase 13 tail |
| Starting resources after second settlement | Yes | Partial | Not signed off | `SetupStateMachineV1Tests`, `ULS_CoreGame` setup reducer/tests | Resource grant is engine-owned and should surface through state, but there is no dedicated product-level end-to-end signoff yet. | Phase 13 tail |
| Roll and production | Yes | Yes | Not signed off | `TurnResourceDistributionV1Tests`, `GameScreenModelBuilderTests` | Core turn loop exists; still needs full two-device match completion proof. | Phase 13 tail |
| Seven -> discard flow | Yes | Partial | Blocked | `TurnReducerV1`, `GameDiscardPanelModelBuilderTests` | Off-turn discards still rely on surfaced intent handling instead of a robust background progression model. | Phase 13 |
| Robber tile move | Yes | Yes | Not signed off | `TurnReducerV1`, `GameBoardOverlayModelBuilderTests`, `TurnInteractionResolverTests` | Current player board flow exists; needs device signoff under the corrected host substrate. | Phase 13 tail |
| Robber steal victim selection | Yes | Partial | Not signed off | `GameRobberVictimOptionBuilderTests`, `GameBoardOverlayModelBuilderTests`, `TurnInteractionResolverTests` | Legal victims exist in engine/presentation, but final device confidence is still missing. | Phase 13 tail |
| Build road / settlement / city | Yes | Yes | Not signed off | `TurnInteractionResolverTests`, `GameBoardOverlayModelBuilderTests`, `GameBoardCommitCoordinatorTests` | Product path exists; remaining question is match-grade device stability, not missing legality. | Phase 13 tail |
| Buy dev card | Yes | Yes | Not signed off | `TurnReducerV1`, `GameScreenModelBuilderTests` | Build shelf path exists, but full match signoff is still pending. | Phase 13 tail |
| Knight | Yes | Partial | Not signed off | `TurnDevCardsV1Tests`, `DevCardInteractionResolverTests`, `GameDevCardPanelModelBuilderTests` | Core rules exist; product confidence is tied to robber/victim progression and real-device signoff. | Phase 13 tail |
| Monopoly | Yes | Yes | Not signed off | `TurnDevCardsV1Tests`, `DevCardInteractionResolverTests`, `GameDevCardPanelModelBuilderTests`, `GameBankTrayModelBuilderTests` | Choice-driven product path exists; no authoritative device signoff yet. | Phase 13 tail |
| Year of Plenty | Yes | Yes | Not signed off | `TurnDevCardsV1Tests`, `DevCardInteractionResolverTests`, `GameDevCardPanelModelBuilderTests`, `GameBankTrayModelBuilderTests` | Choice-driven product path exists; no authoritative device signoff yet. | Phase 13 tail |
| Road Building | Yes | Yes | Not signed off | `TurnDevCardsV1Tests`, `DevCardInteractionResolverTests`, `GameBoardOverlayModelBuilderTests` | Engine and product selection path exist; no authoritative device signoff yet. | Phase 13 tail |
| Victory Point reveal | Yes | Yes | Not signed off | `TurnDevCardsV1Tests`, `GameDevCardPanelModelBuilderTests` | Winning-only reveal logic exists, but still needs full end-of-match device confirmation. | Phase 13 tail |
| Player-trade proposal | Yes | Yes | Not signed off | `TurnReducerV1`, `TradeInteractionResolverTests`, `GameTradePanelModelBuilderTests` | Self-contained trade panel exists; remaining risk is async response/recovery, not the proposer composer itself. | Phase 13 tail |
| Targeted trade accept / decline / counter | Yes | Partial | Blocked | `TurnReducerV1`, `TradeInteractionResolverTests`, `TurnIntentContextResolverTests`, [phase boundary audit](./2026-04-16-phase-boundary-audit.md) | Response UX is still constrained by surfaced-message authority and does not behave as fully automatic progression. | Phase 13 |
| Maritime / bank trade | Yes | Yes | Not signed off | `TurnMaritimeTradeV1Tests`, `TradeInteractionResolverTests`, `GameTradePanelModelBuilderTests` | Product quick-trade path exists; no authoritative device signoff yet. | Phase 13 tail |
| Largest Army scoring | Yes | Partial | Not signed off | `TurnAwardsV1Tests`, `TurnReducerV1` | Award math exists, but explicit product surfacing is still weak outside derived score/win presentation. | Phase 13 tail |
| Longest Road scoring | Yes | Partial | Not signed off | `TurnAwardsV1Tests`, `TurnReducerV1` | Award math exists, but explicit product surfacing is still weak outside derived score/win presentation. | Phase 13 tail |
| Immediate win at 10 VP | Yes | Yes | Not signed off | `TurnVictoryV1Tests`, `GameScreenModelBuilderTests`, `GameShellStatusLineResolverTests` | Core win logic and minimum winner shell exist; final hardware confirmation is still pending. | Phase 13 tail |
| Final winner / final score / last-turn recap | Yes | Yes | Not signed off | `GameScreenModelBuilderTests`, `GameShellStatusLineResolverTests` | Minimum game-over shell exists, but still needs full device confirmation after the host/recovery overhaul. | Phase 13 tail |
| Secrecy-safe hand and dev-card visibility | Yes | Yes | Not signed off | `GameScreenModelBuilderTests`, `GameDevCardPanelModelBuilderTests`, [engine readiness audit](./2026-03-engine-readiness.md) | Local-vs-opponent visibility is tested, but still needs explicit device-level confidence in full play. | Phase 13 tail |

## Async iMessage Surface Matrix

These are not base Catan rules, but they are part of the MVP product promise because the game is async and iMessage-first.

| Surface | Engine / Protocol | Product UI | Two-Device Confidence | Evidence | Main blocker or note | Current owner |
| --- | --- | --- | --- | --- | --- | --- |
| Recover correct active game on reopen | Partial | Partial | Fragile | `TranscriptStateSelectionTests`, `TurnIntentContextResolverTests`, [phase boundary audit](./2026-04-16-phase-boundary-audit.md) | Recovery still leans on selected bubble plus opportunistic cache recovery instead of a durable per-game ledger. | Phase 13 |
| Stay in original bubble and progress when later responses arrive | No | No | Blocked | Apple Messages API behavior, [phase boundary audit](./2026-04-16-phase-boundary-audit.md) | Older selected state bubbles are not live subscriptions to later messages. | Phase 13 |
| Join progression without bubble hopping | Partial | Partial | Fragile | `LobbyScreenModelBuilderTests`, [phase boundary audit](./2026-04-16-phase-boundary-audit.md) | Join bridge exists in some surfaced cases, but not with durable transcript-authoritative recovery yet. | Phase 13 |
| Trade-response progression without manual transcript bookkeeping | Partial | Partial | Blocked | `TurnIntentContextResolverTests`, `GameTradePanelModelBuilderTests`, [phase boundary audit](./2026-04-16-phase-boundary-audit.md) | Current-player auto-apply exists only after response surfacing; staying on an older bubble is not a reliable path. | Phase 13 |
| Transcript-authoritative lobby roster | No | No | Blocked | `LobbyDriverViewModelIdentityTests`, [phase boundary audit](./2026-04-16-phase-boundary-audit.md) | Roster assembly still depends on device-local `pendingJoiners`. | Phase 13 |
| Transport without temporary `summaryText` mirror | Partial | Partial | Blocked | `TranscriptTransportSupportTests`, [2026-04-13 transport reliability plan](./2026-04-13-transport-reliability.md) | Canonical payload still needs the temporary mirror bridge for real-device reliability. | Phase 13 |
| Raw intent fallback only as diagnostics, not normal UX | Partial | Partial | Fragile | `GameShellProjectionBuilderTests`, [phase boundary audit](./2026-04-16-phase-boundary-audit.md) | Recoverable cases can still fall into raw-intent/open-game shells. | Phase 13 |

## Conclusion

The strict answer is:

- the repo has broad base-game rule coverage
- the repo has many real product UI paths for those rules
- the repo does **not** yet have every full user experience implemented and signed off for the MVP promise

The biggest gaps are not ordinary missing rules. They are:

- join/start authority and recovery
- trade-response progression
- off-turn surfaced-intent handling
- transcript-authoritative roster and active-game recovery
- transport reliability without the temporary bridge
- full two-device standard-match signoff after those substrate fixes land

That is why the active execution gate has moved to phase 13. The remaining phase-12 work is now best understood as:

- the rows above marked `Phase 13 tail`
- completed only after the phase-13 host/transport/recovery substrate is corrected
