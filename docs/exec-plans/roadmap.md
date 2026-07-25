# Roadmap

This file is the coarse sequencing surface for work after the current closeout. Use it to answer "what comes next" without pretending future phases are already fully planned.

Use the tracked planning surfaces this way:

- use `docs/exec-plans/active/` for live execution state
- use `docs/exec-plans/completed/` for historical reconstructions
- use this file for future phase sequencing
- use `docs/exec-plans/tech-debt-tracker.md` for durable cross-phase debt

## Current Position

### Phase 14 — Active

- Active plan: [Phase 14 Plan](/Users/kunalsharda/Documents/Code/UnluckySevens/docs/exec-plans/active/phase-14-ui-design-bubble-polish-and-trust-surfaces.md)
- Current slice:
  - transcript previews, language, Settings, Rules, Tutorial, forced discard, and the masked-robber identity are closed
  - the approved first-invite card still needs release productionization across the lobby lifecycle
  - responsive host adaptation still needs both real-iPad entry-path checks and owner approval

The next broad phase after this active polish work remains structural cleanup, unless TestFlight evidence forces a different priority.

## Sequenced Next Phases

### Phase 15 — Extension Decomposition, Test Architecture, and Structural Performance

Why this phase comes after phase 14:

- the app is now shippable enough that structural cleanup should follow visible product polish, not block it
- the remaining architecture debt is real, but it is no longer the main thing standing between the current build and outside testers
- once UI polish settles, decomposition and test architecture can be done against a more stable product surface

Priority focus:

- split `MessagesExtension` more cleanly by lifecycle, transport adaptation, orchestration, and debug tooling
- remove duplicated-source test architecture
- retire superseded presentation branches and projection/debug facades after their release routes are mapped
- deepen board/bubble visual regression coverage
- fix remaining structural performance and layout-scaling issues
- bound and version local transcript-recovery persistence

Primary debt links:

- [TD-002](/Users/kunalsharda/Documents/Code/UnluckySevens/docs/exec-plans/tech-debt-tracker.md)
- [TD-003](/Users/kunalsharda/Documents/Code/UnluckySevens/docs/exec-plans/tech-debt-tracker.md)
- [TD-004](/Users/kunalsharda/Documents/Code/UnluckySevens/docs/exec-plans/tech-debt-tracker.md)
- [TD-007](/Users/kunalsharda/Documents/Code/UnluckySevens/docs/exec-plans/tech-debt-tracker.md)
- [TD-010](/Users/kunalsharda/Documents/Code/UnluckySevens/docs/exec-plans/tech-debt-tracker.md)
- [TD-011](/Users/kunalsharda/Documents/Code/UnluckySevens/docs/exec-plans/tech-debt-tracker.md)
- [TD-014](/Users/kunalsharda/Documents/Code/UnluckySevens/docs/exec-plans/tech-debt-tracker.md)
- [TD-015](/Users/kunalsharda/Documents/Code/UnluckySevens/docs/exec-plans/tech-debt-tracker.md)

### Phase 16 — Beta-Driven Follow-On

Why this phase is intentionally last:

- the next unknowns should come from TestFlight evidence, not speculation
- some follow-on work may matter a lot once real players touch the build, but it is wasteful to pre-commit to those changes before seeing that evidence

Priority focus:

- only the highest-signal fixes or additions that emerge from beta usage
- any externally discovered blocker that is too real to leave as backlog noise

Potential debt links:

- [TD-009](/Users/kunalsharda/Documents/Code/UnluckySevens/docs/exec-plans/tech-debt-tracker.md)

## Priority Order

If time is constrained, prioritize remaining work in this order:

1. Real-device TestFlight gate on the current build.
2. Phase 14 product polish that improves player trust and first-use clarity.
3. Direct cleanup of proven-orphan source plus resolution of the board-art source-of-truth mismatch.
4. Phase 15 structural cleanup that improves long-term iteration speed and regression safety.
5. Phase 16 only if beta evidence forces it.

## Not Yet Phased

These items should stay out of the main sequence until post-TestFlight evidence says otherwise:

- deferred product items in [docs/product-specs/deferred-prd-items.md](/Users/kunalsharda/Documents/Code/UnluckySevens/docs/product-specs/deferred-prd-items.md)
- non-MVP platform work such as analytics, crash reporting, localization, monetization, or privacy/compliance expansion
- gameplay variants, tabletop realism / hard mode, 2-player support, AI fill-ins, or scenario-map work

## Update Rules

- update this file when future sequencing changes or a new phase becomes concrete enough to name
- update the active ExecPlan when execution status changes
- update the tech-debt tracker when durable debt is discovered, re-scoped, or resolved
