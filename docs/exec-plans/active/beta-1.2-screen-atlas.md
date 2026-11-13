# Current screen and theme atlas

## Purpose and Outcome
Provide the owner a numbered PDF of the current draft's screens, overlays and theme before any further design decisions. Requested 2026-11-11. Source baseline 94cc3a3, codex/beta-1.2-finish; this is not a shipped build.

## Execution Settings
- Validation profile: `lightweight`
- Delivery posture: `explore`
- Rationale: read-only product inventory and document authoring; no production UI or behavior changes.

## Context and Boundaries
Preserve the original checkout and protected Build Costs components. Use only the iPhone simulator UX Lab harness; no iPad or physical-device installation. Prior product acceptance remains blocked and the previous learning retry ceiling is not reset. This atlas documents existing visual defects, it does not fix them or claim release acceptance.

## Plan of Work and Locked Proof
1. Inventory production routes, DEBUG fixtures, existing iPhone catalog and theme owner/code sources.
2. Run the existing 18-route iPhone screenshot catalog at ordinary large text size. If a route fails, record its evidence and continue only independent unrun routes in a separate catalog; no silent retry or UI fixes. Capture supplemental reachable current screens through existing focused routes. Use clearly labeled historical captures only for unreachable or exhausted journeys.
3. Produce a numbered PDF with theme, screen names, screenshots, factual notes and explicit capture gaps. Inventory overlays/steps within each route; enumerate uncaptured states rather than asserting a screenshot is exhaustive.
4. Render and inspect the PDF, reconcile index/images, run doc freshness and completion gate, shut down the task simulator and close Simulator.

## Verification Contract and Fresh Review
<!-- verification-contract:start -->
| ID | Class | Source | Acceptance | Verification | Evidence | Status | Rationale |
| --- | --- | --- | --- | --- | --- | --- | --- |
| AT-01 | mechanical | user | iPhone only, original checkout and UI source untouched | diff and task simulator inventory | report:application-source-diff-empty; report:target-only-iPhone-run-manifests | pass | Capture and artifact work only |
| AT-02 | observable | user | Numbered screen inventory with theme and honest capture provenance | catalog/source reconciliation and PDF inspection | file:output/pdf/unlucky-sevens-current-screen-atlas.pdf; file:output/pdf/screen-atlas-manifest.json | pass | 69 fresh states and 13 source-only groups, no redesign |
| AT-03 | mechanical | AGENTS | Document validated and task simulators cleaned up | PDF render/text checks and gates | file:output/pdf/pdf-validation.json; report:simulator-shutdown-verified; report:missing-prior-models-bundle | blocked | PDF and cleanup pass; repository-wide gate blocked by unrelated missing historical evidence |
<!-- verification-contract:end -->

<!-- fresh-review:start -->
| Reviewer | Required | Verdict | Evidence |
| --- | --- | --- | --- |
| constraint-auditor | no | not-applicable | report:lightweight-capture-document-slice |
<!-- fresh-review:end -->

## Living Record
- Existing draft remains at 94cc3a3. User rejected the composition; no redesign has been implemented since.
- Full iPhone catalog has 18 journeys with multiple attached states. Learning tour previously exhausted its correction budget; existing captures will be marked historical if included.

## Validation and Outcome
The PDF is prepared and visually checked. Repository completion remains blocked by unrelated historical evidence; this is not a beta acceptance claim.

Inventory reconciliation adds eleven existing supplemental routes for surfaces absent from the older full catalog: compact fresh entry, Reliability Report, supply reveal, new Dev timing, mixed purchase costs, four-player/reference, forced private inspection, gain/no-production receipts, timely Dev/Bank teaching, and draw-vote controls. Exact manifest is retained in the output evidence; no new production route or exhausted controls journey is added. Diagnostics-only screens, OS-owned export/permission sheets and unsupported capture paths will be explicitly separated from player screens.

2026-11-11 capture diagnosis: original catalog stopped at lobby roster identifier (line148) despite the live invitation rendering correctly. Exported hierarchy shows parent identifiers propagating over children. Source/visual review confirms a harness lookup gap, not proof of a missing lobby. Added capture-only atlas methods and `scripts/ui-screenshot-catalog-atlas.txt`: visible-label fallback, explicit missing-control attachments, no layout/gameplay pass assertions. Existing acceptance tests are untouched. This substitutes a capture inventory for the failing legacy catalog; it does not restart the exhausted controls-practice journey. Only XCTest code and documentation change. Full atlas captures normal text size; historical AX proof is not relabeled current.

Capture pass findings: lobby Invitation/Join/Ready are pictured. Settings and individual tips are pictured; Rules/Reliability were not reached because the capture used the outer Messages back button rather than Tutorial Tips' own navigation bar, followed by an offscreen Settings row. Corrected only the atlas navigation and added a settled-element wait. Owned Dev source uses `uls.physicalProps.ownedDevCards`/Owned Dev Cards, corrected the atlas lookup before its focused final capture. Added source-mapped lifecycle/strategy capture methods to cover these discovered inventory gaps. Final supplemental catalog is frozen in the evidence notes; existing receipt/cost/new-card/compact-entry routes cover the remaining representative states. No production UI change.

Beginner capture stopped after its first Trade lesson: the Next tutorial step exists with a full right-half frame but reports non-hittable under the higher-z-order read-only Trade preview. Source confirms the preview disables hit testing and navigation is the advertised right tap zone. The capture-only follow-up taps the known Next zone away from Close and inspects resulting steps; it does not modify the product or rerun controls practice. Reference scroll captures are relabeled from their visible content (owned-card continuation, then costs/turn rules) rather than presumed scroll destinations.

Source inventory found controls practice otherwise had no current picture. The owner's new request for every current screen authorizes a normal-size entry-only capture: open Reference, open Controls, attach the initial surface and stop. This does not repeat the failed AX/full-eight-actions/return-state journey, reset its retry ceiling, or claim acceptance. All subsequent controls interaction states remain explicitly unverified/source-listed.

Incoming/pending trade fixture review showed the normal table (and automatic Dev teaching), not the actual offer panel. The focused capture now dismisses teaching and opens the existing Pending offer control before naming the screenshot an offer. Earlier misleading captures are excluded from the PDF, as is the earlier public-purchase capture mislabeled owned inventory. Hand toggle capture is relabeled Hand closed. Duplicate unchanged Player Record and baseline table pictures are omitted. These are capture corrections, not UI fixes.

Repository-wide harness audit currently fails on an unrelated historical evidence path: `output/beta12-production-models-final.xcresult` is missing. This report will not recreate or fabricate that acceptance evidence. The final completion-gate invocation will record that limitation separately from PDF inspection and this inventory's evidence.


Capture/source map: MessagesRootRoute supplies Lobby and Game; AppUtilitySheetRoute supplies Settings, beginner tutorial, Learn & Reference, and Player Record. GameShellRoute supplies Build, owned Dev, Trade chooser/player draft/maritime/live offer, End Turn confirmation, and Game Information. Phase fixtures supply setup, pre-roll, discard, robber/victim, waiting and results. Nested utility destinations include individual tips, Rules, Strategy and Reliability. Contextual teaching, purchase inspection, roll receipts, lifecycle confirmations and controls practice are explicitly represented as overlays/steps rather than additional independent root screens. Transcript bridges/images, system destinations, developer previews and uncaptured effect/error variants are source-listed coverage groups.

The ordinary draw-vote fixture renders the table until Current game actions is opened. Exclude that baseline mislabeled draw-vote image; use the existing focused current-game draw-vote harness for the actual actions panel. This is the last inventory-route addition. No additional exploration or product changes are authorized by a screenshot failure.


Trade actor reconciliation: fixture source confirms Alice/Maya proposes both offers and host/Kunal receives them. The executed focused catalog captured the proposer in testAtlasIncoming/testAtlasMultiTrade and recipient in testAtlasPending. PDF titles follow the visible role, not the test names: proposer pending, multi-resource proposer, incoming offer. The checked-in reusable catalog now uses host for Incoming/MultiTrade and Alice for Pending. No extra capture round is added for this data-label correction. The current run's exact catalog is preserved with its evidence.


## Final Artifact and Evidence — 2026-11-11
- Deliverable: `output/pdf/unlucky-sevens-current-screen-atlas.pdf`, 91 pages, S01–S69 fresh screenshots and G01–G13 source-only coverage groups. Clickable index has 82 links. No historical screenshots or proposed UI mockups are included. `screen-atlas-manifest.json` maps every screenshot number to its full-resolution attachment, fixture, actor and capture run.
- Main capture pass: `output/ui-screenshot-harness/20261111T101158Z-iphone`, 20/20 methods returned successfully. Focused pass: `output/ui-screenshot-harness/20261111T103842Z-iphone`, 15/15 returned successfully. Capture-only success is not a gameplay/layout acceptance claim. The five existing behavioral routes in the focused pass also passed their assertions; the exact run manifest remains authoritative.
- The initial legacy catalog failed on inherited lobby AX lookup; its diagnostic images are excluded. Focused navigation corrections resolved the meaningful destination gaps. Remaining `uls.purchase.close` gap attachments are optional dismissals when no teaching panel was present. Duplicate baseline/unchanged images and mislabeled intermediate images are excluded. The source-only list includes transient dice presentation as well as uncaptured interaction/OS/error variants.
- PDF checks: all 91 pages rendered; all captured states and page layouts visually inspected, changed final captions re-inspected; text bounds, index links, numbered page targets and source paths verified. No PDF validation problems. Final SHA-256: `fca865153c4b8d7449a4f3582c593cd132190c61de07abacf8a1b6f2ad937e02`.
- Cleanup verified: task simulator DECD82B7-69B6-4343-B201-01797C544C6A is Shutdown, no booted devices, Simulator process absent. No iPad or physical-device installation. Content size restored by the harness.
- Application/Build Costs source diff against 94cc3a3 is empty. Only capture harness, catalog and documentation change. The unused baseline-only draw capture method was removed after the focused build; the existing draw-vote route supplies the actual action-panel evidence. The final cleanup deletion passed Swift syntax parsing and the diff check.
- Owner docs: updated `docs/quality/ux-lab.md` for capture-only inventory semantics and this active plan for evidence. PRODUCT, DESIGN, architecture, decisions, product flows and main QA policy are intentionally unchanged because the application and validation policy did not change. Historical plans/results were not rewritten or fabricated; the missing older models bundle remains deferred.


Final checks: `make doc-freshness` passed; `git diff --check` and `swiftc -frontend -parse UnluckySevensUITests/MessagesExtensionDesignSliceUITests.swift` passed. `make harness-audit` failed on the pre-existing missing `output/beta12-production-models-final.xcresult`. Accordingly AT-03 remains blocked; `make completion-gate PLAN=docs/exec-plans/active/beta-1.2-screen-atlas.md` was run and correctly stopped on that explicit blocked contract row. No full completion or release acceptance is claimed. Lightweight artifact/capture scope did not require a fresh constraint-auditor; no new agent review was used.
