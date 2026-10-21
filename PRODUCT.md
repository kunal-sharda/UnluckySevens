# Product

<!-- impeccable:product-schema 1 -->

This is concise design-facing product context. Current player-facing behavior remains owned by the [MVP contract](docs/product-specs/mvp-contract.md) and [UI flows](docs/product-specs/ui-flows.md); locked calls live in [Decisions](docs/decisions.md), runtime boundaries live in [Architecture](ARCHITECTURE.md), and the visual language lives in [Design](DESIGN.md).

## Platform

ios

## Users

Unlucky Sevens is for groups of 3–4 friends who want to play asynchronous standard Catan inside an existing iMessage conversation. It serves both casual or newer Catan players who need contextual guidance and experienced players who primarily need the Messages-specific controls explained.

Players interact in short, interrupted sessions and often return from a transcript bubble after time away. They need to identify the table, players, current actor, pending obligation, and next legal action quickly without reconstructing the game from message history.

## Product Purpose

The product brings the full standard-Catan loop to Messages while preserving deterministic rules, canonical state, and hidden-information boundaries. Success means players can invite, join, set up, play turns, trade, build, use Development Cards, resume from the real game bubble, inspect device-local results, leave play without stopping everyone else, and finish by victory, unanimous draw, or host end without leaving the Messages-first flow.

## Positioning

Unlucky Sevens is not a generic mobile board-game lobby with chat attached. The iMessage conversation is the social and transport context, each game advances through its message session, and the opened extension presents a compact physical tabletop. The product pairs full-game rules and secrecy with asynchronous message-native play rather than requiring a separate matchmaking destination.

## Operating Context

- The shipped surface is a standalone Messages app extension on iPhone and iPad; there is no independent gameplay destination outside Messages.
- A real game bubble establishes the active gameplay context. Local history is read-only and cannot silently reopen or publish a game.
- Messages may provide compact, expanded, or transcript presentation with constrained and changing space. The product must preserve continuity and avoid recomposing canonical state during host resizing.
- The table is shared asynchronously. Multiple players may act from different devices after delays, so state selection, publication, recovery, and secrecy must remain trustworthy without a central live match server in the current product.
- Physical-table affordances should replace missing in-person context only when they reduce cognitive work. Persistent identity cues must stay quiet; detailed roster information belongs behind the existing Players/Game Information surface.

## Capabilities and Constraints

- The current supported game is standard 3–4-player Catan. AI opponents, 1v1 rules, house rules, and Game Center are not current shipped capabilities.
- `ULS_CoreGame` owns rules, legality, determinism, and secrecy-safe queries. Presentation does not become a second rules engine.
- `ULS_Transport` owns the compact message/protocol boundary. Messages lifecycle and presentation remain extension concerns.
- Canonical state travels through Messages; private information must not leak through transcript copy, accessibility, preview art, history, or diagnostics.
- The device-local ledger supports state resolution and a read-only Player Record. It is not an account, recovery service, gameplay launcher, or server analytics store.
- The current product has no required backend account. Confirmed backlog direction keeps local profile and history useful without registration, offers optional account continuity only after a first completed game, and keeps gameplay, analytics, support, and communications identities purpose-separated.
- Display names communicate table identity but are not security credentials. Game-scoped actor identity, installation continuity, account identity, and communication contact information have different contracts.
- Product analytics, account sync, email updates, and Game Center remain planned or undecided until their linked GitHub issues establish architecture, consent, retention, and deletion behavior.

## Brand Commitments

The product is named **Unlucky Sevens**. Its voice and behavior should feel compact, tactile, and trustworthy: a premium tabletop compressed into Messages, physical enough to orient players and restrained enough for repeated asynchronous play. Product identity, current assets, typography, materials, and calibrated anti-references are owned by [Design](DESIGN.md).

## Evidence on Hand

- The source, engine tests, transport tests, presentation tests, and simulator/device harnesses are the primary evidence of current behavior.
- [UI flows](docs/product-specs/ui-flows.md) records the current end-to-end journey, including Player Record, lifecycle actions, Messages-host adaptation, and known gaps.
- [Architecture](ARCHITECTURE.md) records the state-first runtime, message-session boundary, local ledger, and cooperative fixed-client authority model.
- [GitHub Issues](https://github.com/kunal-sharda/UnluckySevens/issues) contains discrete TestFlight feedback and unscheduled product requests; an issue is not proof that its feature has shipped.
- Friend and TestFlight feedback has established recurring clarity needs around costs, learning, player identity, current action, trades, and post-game understanding. No fabricated usage benchmarks, testimonials, or retention claims should be introduced.

## Product Principles

- **Messages first.** Starting, returning, acting, and understanding should fit the conversation rather than imitate a standalone game hub.
- **Reorient immediately.** The table should reveal which game this is, who is involved, whose turn it is, what changed, and what happens next with minimal reopening work.
- **Rules and secrecy stay trustworthy.** Deterministic Core behavior, explicit publication, and private-information boundaries outrank presentation convenience.
- **Physical affordances earn their space.** Use tabletop objects, seating, and material cues when they make ownership or action clearer; collapse or remove them when they become ornamental noise.
- **Local value before registration.** Profiles, preferences, and history should remain useful on-device; optional continuity and communication must provide visible benefit and reversible choices.

## Accessibility & Inclusion

Important state and player identity cannot rely on color alone. Interactive targets must remain usable with VoiceOver, Dynamic Type, Increase Contrast, Reduce Motion, compact and expanded Messages hosts, and localization expansion. New and casual Catan players need contextual learning and an always-available reference path, while experienced players need a short controls-focused route.
