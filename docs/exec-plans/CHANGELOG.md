# Changelog

This is compact retrospective history, not live execution state. GitHub milestones and Issues own current release scope and tasks.

## [Unreleased]

### Changed

- Adopted proportional work tracking: GitHub Issues own discrete work, milestones own release scope, and ExecPlans are reserved for broad, risky, release-sensitive, or resumable orchestration.
- Reconciled the post-launch documentation backlog, archived terminal and superseded plans, and moved confirmed Beta 1.1 follow-up into deduplicated issues.

## [1.0 (8) TestFlight Beta] - 2026-08-26

### Released

- Build `1.0 (8)` completed TestFlight Beta App Review and launched to the First Friends external-testing group under `me.ksharda.games.unluckysevens`.
- Established Build `1.0 (8)` as the first supported transcript compatibility boundary; pre-TestFlight development bubbles remain unsupported.
- Published the privacy policy, TestFlight metadata, export-compliance answers, and Data Not Collected declaration; the distributed binary exposes its privacy link in Settings.

### Product

- Shipped standard 3–4 player Catan through the iMessage timeline: lobby, setup, turn play, building, Trade, robber/discard, Dev Cards, awards, resignation, draw, host end, and victory.
- Replaced unsafe saved-game continuation with a read-only Player Record. Gameplay and lifecycle publication resume only from a real game bubble with a bound Messages session.
- Shipped the tabletop visual system, canonical SpriteKit board, Physical Props interactions, responsive Messages-host layout, sixteen-lesson tutorial, accessible controls, and bubble-specific public previews.

### Reliability and Maintainability

- Kept Core authoritative for rules, determinism, validation, secrecy-safe queries, costs, and topology; kept Transport authoritative for message encoding and compatibility.
- Isolated extension responsibilities, shared one compiled support module between shipping code and tests, made selection polling lifecycle-cancellable, and separated production projection from DEBUG diagnostics.
- Removed superseded UI branches, unused board assets, dead reconstruction paths, and redundant cost/topology construction without changing gameplay or protocol fields.

### Validation

- The frozen candidate passed the release mechanical lane, deterministic full-match and victory coverage, signed archive validation, and clean iPhone/iPad installation and smoke checks.
- Installed-TestFlight multi-device edge observations intentionally deferred at launch are tracked in [GitHub issue #8](https://github.com/kunal-sharda/UnluckySevens/issues/8), not represented as completed proof.

## Pre-Beta Foundation - 2026-03 through 2026-08

- Built the pure `ULS_CoreGame` and `ULS_Transport` packages, canonical state hashing, standard board generation, complete reducer/query coverage, deterministic scripted matches, and the Messages extension host.
- Added canonical generation, package/workspace tests, XCUITest/UX Lab catalogs, device runbooks, evidence retention rules, completion contracts, and release gates.
- Iterated the product and design through phases 0–14. Detailed decisions, rejected directions, commands, and evidence remain in [completed ExecPlans](completed/) and dated [quality audits](../quality/audits/).
