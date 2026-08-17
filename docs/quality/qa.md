# QA

This is a living document. Update it whenever UI scope, Messages behavior, validation lanes, or device expectations change. Do not rely on chat memory for what needs to be tested.

## Guide Map

- [Constraint verification](constraint-verification.md): completion contracts, evidence classes, reviewer routing, and completion language.
- [Messages host and gameplay lessons](messages-host.md): durable platform, transport, state, layout, and interaction knowledge.
- [Single-device UX Lab](ux-lab.md): fixture coverage, screenshot controls, limitations, and simulator capture workflow.
- [Device and simulator runbooks](device-runbooks.md): real-device checklists, manual simulator lanes, and host-stability regression checks.

## Practical Gate

The practical gate is the exhaustive release-sized lane for the current MVP engine baseline:

```bash
make practical-gate
```

Expanded gate:

```bash
bash ./scripts/check-doc-freshness.sh
bash ./scripts/gen.sh
swift test --package-path Packages/ULS_CoreGame --skip ULS_CoreGameEvals
swift test --package-path Packages/ULS_CoreGame --filter ULS_CoreGameEvals
swift test --package-path Packages/ULS_Transport
xcodebuild -workspace UnluckySevens.xcworkspace -scheme UnluckySevens -configuration Debug -destination 'generic/platform=iOS' -derivedDataPath DerivedData/MessagesOnlyValidation CODE_SIGNING_ALLOWED=NO build
xcodebuild -workspace UnluckySevens.xcworkspace -scheme MessagesExtension -destination 'generic/platform=iOS Simulator' build
xcodebuild -workspace UnluckySevens.xcworkspace -scheme UnluckySevens-Workspace -destination 'platform=iOS Simulator,name=iPhone 17,OS=latest' -skip-testing:UnluckySevensUITests test
```

Normal ExecPlan completion uses its declared validation profile:

```bash
make completion-gate PLAN=docs/exec-plans/active/<plan>.md
```

Use `make release-gate PLAN=<release-critical-plan>` for release or handoff claims. GitHub Actions runs the doc-freshness gate against the PR base, Swift package tests, and the `make build` MessagesExtension lane in `.github/workflows/ci.yml`. The full local practical gate remains `make practical-gate`.

Before freezing a TestFlight candidate, build the explicit Release configuration for `generic/platform=iOS` and inspect the packaged app and extension rather than inferring distribution readiness from Debug. Record the marketing version/build, bundle IDs, minimum OS, SDK/Xcode, team, signing disposition, and exact commit. The packaged product must contain every required `PrivacyInfo.xcprivacy` entry, an accurate `ITSAppUsesNonExemptEncryption` value, and no DEBUG UX Lab identifiers. Privacy-policy metadata and an easily accessible in-app policy link remain release blockers even when the binary builds successfully.

`ULS_CoreGameEvals` is the deterministic engine eval harness. `ULS_CoreGameTests` remains the normal core test suite.

Run these validation commands serially. Do not run `swift test` or `xcodebuild` in parallel on this repo; the Messages/simulator lane is prone to lock contention and misleading failures when multiple test or build processes overlap.

## Validation Circuit Breaker

Lock the exact commands, journeys, screenshots, and reviewers in the active verification contract before implementation. Validation proves that contract; it does not silently broaden it.

- A failed check may trigger implementation work only when it demonstrates a production defect or a constraint gap traceable to the user request or an authoritative owner doc.
- A newly discovered legitimate constraint requires a dated plan amendment with its source, acceptance boundary, and proof method. Update the user before beginning the expanded work.
- Treat simulator launch failures, stale accessibility references, nondeterministic taps, result-bundle corruption, and other non-product failures as harness instability unless reproduced as a product defect.
- For the same failing command or journey, allow the initial attempt plus at most ten focused reruns. This is a ceiling, not an instruction to retry automatically. After every failure, inspect the xcresult, exported hierarchy/screenshots, simulator still, and runner log; classify the failure as product, harness, assertion/contract, or infrastructure; record the diagnosis and correction in the active plan before another attempt. An unchanged rerun is allowed only for a specifically evidenced infrastructure failure. A rerun after a code or test fix counts toward the ten-rerun budget. When the budget is exhausted, stop, retain the last diagnostic evidence, and report the work as implemented but not verified or blocked as appropriate.
- Do not add adjacent journeys, new assertions, or reviewer-requested proof after implementation unless they close a predeclared constraint or a formally amended contract gap.
- Keep exploratory and failed diagnostic bundles out of final proof. Produce one clean final bundle containing only the contracted tests, or cite independent clean per-test results when bundling is not supported.
- Run the completion gate once after contracted evidence is green. Retry it only after a relevant source/evidence correction or a documented transient infrastructure cause; unrelated failures are reported rather than chased inside the current slice.

For player-facing visual work, show the user the representative inspected results as soon as the contracted observable proof is green. Administrative review and completion checks may continue afterward, but they must not delay the result update or start another visual iteration without authorization.

`make practical-gate` defaults its simulator unit-test lane to `platform=iOS Simulator,name=iPhone 17,OS=latest`. Override `TEST_SIMULATOR_DESTINATION` when that device family is unavailable; keep the destination explicit so Xcode does not silently request an uninstalled newest runtime for an older simulator model. This lane skips `UnluckySevensUITests` because Messages UI tests require an explicit standalone-app install and controlled app-drawer state; run those through the XCUITest/UX Lab lanes below and attach their verdicts to the completion contract.

Before any canonical Messages screenshot lane, shut down every simulator, boot only the target device, uninstall `com.unluckysevens.app`, install the freshly built `UnluckySevensApp.app`, and restart Messages before `test-without-building`. Installing over a running prior host is not valid evidence because Messages and XCTest can retain extension or accessibility state. The test action refreshes the runner but does not guarantee replacement of the installed host app; record and compare the built and installed `MessagesExtension` executable hashes.

For the repeatable full UI catalog, run `bash ./scripts/run-ui-screenshot-catalog.sh iphone`, then `bash ./scripts/run-ui-screenshot-catalog.sh ipad`. The runner canonically regenerates, builds the app and UI-test runner into one pinned DerivedData root, installs that exact app, restarts Messages so the host discovers the extension, verifies the built and installed extension hashes, and runs each catalog route in its own XCTest process. Its timestamped local evidence directory contains the run manifest, per-route result bundles, exported attachments, and direct simulator stills. A failed route stops the lane; follow the retry budget and circuit breaker below rather than silently continuing.

Recovery journeys that terminate and relaunch Messages must hide DEBUG UX Lab chrome before persistence assertions without reseeding canonical fixtures. The DEBUG hidden-state preference survives extension-process reconstruction, and the existing 44-point Show UX Lab control restores authoring chrome when needed. Do not tap production controls through an expanded UX Lab panel or treat post-relaunch overlay discovery as product recovery proof.

High-coverage catalog routes must load their baseline fixture through a direct clean UX Lab control when one exists. In particular, ordinary-turn coverage uses `uls.uxLab.cleanShot.header.turnAfterRoll`; do not fall back to the SwiftUI States menu for that route.

Stable-host layout checkpoints use `scripts/ui-screenshot-catalog-stable-host.txt` with the same cold lifecycle. `testCaptureNarrowShortResponsiveCheckpoint` attaches the live host diagnostic string; the runner copies it into `run-manifest.txt`. Evidence is invalid if that manifest lacks actual bounds, safe-area insets, usable size, profile, presentation style, settled revision, or matching built/installed hashes. Use the shared tabletop layout assertion for containment, ordering, canonical board aspect/centering, 12-point total bottom clearance, minimum targets, overlay clearance, stable revision, and mounted-board identity.

For a bounded tutorial-only correction, preserve that same cold lifecycle while selecting the focused catalog:

```bash
UI_SCREENSHOT_CATALOG="$PWD/scripts/ui-screenshot-catalog-tutorial.txt" \
  bash ./scripts/run-ui-screenshot-catalog.sh iphone
```

Use `ipad` for the paired tablet lane. The manifest records the selected catalog alongside the device, reset sequence, and built/installed hashes.

For a representative installed-host Dynamic Type check, select the accessibility catalog and an accessibility category explicitly:

```bash
UI_SCREENSHOT_CONTENT_SIZE=accessibility-medium \
  bash ./scripts/run-ui-screenshot-catalog.sh iphone \
  "$PWD/scripts/ui-screenshot-catalog-accessibility-size.txt"
```

The runner asks the target simulator for its current content-size category, applies the requested category only after the clean boot, records both values in the manifest, and restores the original category on exit. The route must prove the fixed lobby composition remains operable, tutorial guidance switches to the complete ordered guide, and a representative terminal surface and primary target remain contained. Do not infer Dynamic Type coverage from default-size screenshots.

Before multi-device gameplay testing, run the deterministic single-device action lane:

```bash
bash ./scripts/run-ui-gameplay-action-catalog.sh
```

This iPhone 17 lane uses the same cold lifecycle and one-XCTest-process-per-journey isolation as the visual catalog. Its catalog covers roll, discard, end turn, maritime trade, player trade offer, player trade acceptance, development-card purchase, setup settlement/road, normal road/settlement/city construction, robber move/victim selection, and the four playable development-card kinds. Victory Point remains passive rather than a playable action. DEBUG fixtures establish secrecy-safe canonical starting states; the test then operates player-facing production controls and attaches before/after evidence containing the canonical revision, phase, turn step, current player, state hash, visible local hand and Dev Cards, remaining pieces, discard submission, robber/victim state, Trade, response, status, and raw-error summaries.

Board-target journeys read the current legal target's normalized coordinate from the DEBUG-only diagnostic value on the already-discoverable `uls.tabletop.boardHost`, then tap that coordinate through the live SpriteKit surface and production gesture/publisher path. Do not create transparent target views, depend on nested SpriteKit accessibility descendants, or replace missing board proof with a DEBUG-only direct action. A newly added route is not part of the pre-multidevice proof until its isolated xcresult and canonical diagnostic pass under the required lifecycle.

This lane covers local wiring only. It does not replace multi-device transport convergence, simultaneous Trade responses, stale transcript ordering, hidden-information checks across Apple Accounts, a complete standard match, or real Messages-host proof.

The action runner records one H.264 simulator video per journey under its ignored timestamped evidence directory. A video is review evidence, not a pass signal: pair it with the journey's passing xcresult and attached canonical before/after diagnostic.

For focused single-iPhone follow-ups, select one of the bounded catalogs rather than appending routes to an already running lane:

```bash
UI_GAMEPLAY_ACTION_CATALOG="$PWD/scripts/ui-gameplay-guardrail-catalog-iphone.txt" bash ./scripts/run-ui-gameplay-action-catalog.sh
UI_GAMEPLAY_ACTION_CATALOG="$PWD/scripts/ui-gameplay-recovery-catalog-iphone.txt" bash ./scripts/run-ui-gameplay-action-catalog.sh
UI_GAMEPLAY_ACTION_CATALOG="$PWD/scripts/ui-gameplay-complete-match-catalog-iphone.txt" bash ./scripts/run-ui-gameplay-action-catalog.sh
```

For the normal human-facing entrypoints, use the Make targets instead of remembering catalog paths:

```sh
make test-features
make test-quick FEATURE=trade
make test-full
```

`test-quick` defaults to the three-route `smoke` slice and accepts `trade`, `build`, `robber`, `dev-cards`, `guardrails`, `recovery`, `match`, `tutorial`, `trade-previews`, `host`, `roll`, or `gameplay`. `trade-previews` is the bounded visual lane for the tutorial Give/Get, tutorial recipients, engine-derived Bank/Port quote, integrated pending strip, incoming offer variants, and outgoing pending offer. Every feature still uses the canonical cold lifecycle, isolated XCTest processes, matching build/install hashes, and retained evidence. `test-full` is the complete single-iPhone lane: all production-control gameplay actions, guardrails, recovery, complete-match bookends, and the full visual catalog. It intentionally does not claim iPad, physical-device, multiplayer, signing, archive, or TestFlight proof; those remain release-gate work.

Each selection still inherits the cold lifecycle, isolated-process rule, and diagnostic-first initial-plus-ten retry ceiling. For attempt 2 or later, set `UI_SCREENSHOT_ATTEMPT_NUMBER`, `UI_SCREENSHOT_RETRY_DIAGNOSIS`, and `UI_SCREENSHOT_RETRY_CORRECTION`; the runner rejects undocumented or out-of-budget reruns. If an XCTest navigation surface such as the Games library is not observable, inspect the retained failure bundle and fix its state transition before rerunning; do not use repeated taps or a prior passing catalog as fresh proof.

When shell environment prefixes are unavailable, the same focused retry metadata may be passed positionally as `bash ./scripts/run-ui-screenshot-catalog.sh <profile> <catalog-path> <attempt-number> <diagnosis> <correction>`. Environment variables remain the preferred form for scripted catalogs; positional and environment forms enforce the same ceiling and manifest fields.

Review movies are derived evidence, never a replacement for xcresults and canonical diagnostics. Use `scripts/stitch-ui-evidence.swift` with a tab-separated title, source recording, and retained-tail duration to create accelerated action movies with rasterized headings. When motion footage cannot be trimmed without exposing DEBUG setup, use `scripts/stills-to-ui-video.swift` with headed final production screenshots instead. Use `scripts/pdf-to-ui-video.swift` for a paced headed catalog movie, then sample the final files with `scripts/extract-ui-video-frames.swift`. Reject an export that cannot be decoded, exposes DEBUG fixture-selection chrome in a production-facing cut, or is dated differently from a claimed same-source run.

For a full live-action review movie, choose the retained tail independently for every journey; a single uniform duration can leak DEBUG fixture setup from shorter routes. Decode and inspect at least one post-heading frame from every stitched segment before delivery, with explicit checks on setup/build geometry, robber/victim targeting, and the final action result. Hand-authored board maps are prohibited for gameplay evidence: derive fixture piece positions through `ULS_CoreGame` and keep the fixture-wide distance/connectivity regression test green.

UX Lab action authoring must prefer its explicitly loaded fixture over transcript or local-ledger states with the same game ID. This isolation is DEBUG-only; production action authoring continues to select the newest canonical state from the transcript/recovery sources.

## Canonical Generation and Tooling Boundaries

For agent validation, `bash ./scripts/gen.sh` is the only canonical project-generation entrypoint. It always runs Tuist with no-open settings and applies the generated-project patching required for the standalone Messages package.

Do not use direct `tuist generate` as a validation substitute. A raw generated workspace can look plausible while missing the repo-specific patch that keeps `UnluckySevensApp` resource-only for standalone Messages packaging.

Do not open Xcode for agent validation or screenshot review. Use command-line builds, simulator commands, XCUITest harnesses, and DEBUG-only UX Lab controls.

`python3 scripts/check-harness.py` recursively checks every production interface Swift source under `App/Sources` and `MessagesExtension/Sources` for the SF Pro family contract. The geometry-bound board number token in `GameBoardScene.swift` is the sole serif exception; stable numeric widths may use `monospacedDigit()` without changing type family.

## Documentation Freshness Gate

Treat documentation freshness as part of validation for non-trivial changes. Each fact should have one owner doc; update that owner when the fact changes and link to it elsewhere.

Doc freshness tiers:

- Tier 1, always-current owner docs: `README.md`, `ARCHITECTURE.md`, `docs/decisions.md`, `docs/product-specs/mvp-contract.md`, `docs/product-specs/ui-flows.md`, and this QA document. Update these in the same slice when their owned facts change.
- Tier 2, active execution docs: `docs/exec-plans/active/` and current design READMEs. Update when active scope, implementation findings, validation deltas, or current design direction changes.
- Tier 3, periodic summary docs: `docs/exec-plans/roadmap.md`, `docs/exec-plans/tech-debt-tracker.md`, and `docs/exec-plans/CHANGELOG.md`. Update only when sequencing changes, durable debt changes, or a major slice lands.
- Tier 4, historical/reference docs: completed ExecPlans, dated audits, old design pass notes, and `docs/product-specs/prd-verbatim.md`. Do not rewrite these for normal changes; add supersession notes or promote durable lessons into owner docs.
- Tier 5, local scratch: ignored files and machine-local notes. Tracked docs should not depend on these.

Before finalizing non-trivial work, run `make doc-freshness` and report the doc-freshness result: owner docs updated, owner docs intentionally unaffected, and any deferred historical/reference cleanup. CI and PR checks pass `DOC_FRESHNESS_BASE=<base-ref>` through Make so the same gate compares against the PR base. If an affected Tier 1 or Tier 2 owner doc is stale, the work is not complete.

The script is a guardrail, not a semantic proof. It classifies changed paths and checks whether Tier 1/2 docs were touched when source/design surfaces changed. If the script flags missing owner-doc changes but the owner docs are intentionally unaffected, rerun with `--allow-no-docs` and explain that decision in the final response.

## When To Run What

Validation profile controls the breadth of the final mechanical gate. Delivery posture controls when implementation is allowed to proceed. They are independent: a checkpointed UI task can still be `standard`, and a direct release task can still be `release-critical`.

- `lightweight`: run the targeted check named by the contract plus doc freshness. Use only for narrow, low-risk work.
- `standard`: run `make build` as the baseline, then the focused package, simulator, XCUITest, or device checks required by the changed surface. Core and transport changes need their affected Swift package tests. Messages UI changes need the relevant UX Lab/XCUITest journey and actual artifact inspection; a build alone does not prove them.
- `release-critical`: run `make release-gate PLAN=<plan>`, the relevant real-device checklists, and at least one two-device end-to-end smoke pass before a UI-ready or TestFlight handoff claim.

For visual work, use the [Single-Device UX Lab](ux-lab.md) and repeatable `MessagesExtensionDesignSliceUITests` captures. For lobby, transcript, recovery, turn-taking, and shell changes, select the matching simulator and real-device runbooks in [device runbooks](device-runbooks.md). Record the exact commands, journeys, and inspected artifacts in the plan contract.

For checkpointed visual work, build only the minimum honest DEBUG comparison needed for the declared approval gate. Use real components and fixture data, show at most three representative states per round, and default to two screenshot-feedback rounds. While approval is pending, do not productionize nested states, run automatic fresh reviews, or run the completion gate. A rejected baseline or pre-existing production screenshot does not count as an approved comparison round. After approval, productionize once, run focused observable evidence, and route the final product/UX review once unless the user asks for advisory input earlier.

Durable lessons and detailed runbooks continue in the linked guides above; keep this file as the short validation index.
