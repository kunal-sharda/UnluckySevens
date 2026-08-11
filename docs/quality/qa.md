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

`ULS_CoreGameEvals` is the deterministic engine eval harness. `ULS_CoreGameTests` remains the normal core test suite.

Run these validation commands serially. Do not run `swift test` or `xcodebuild` in parallel on this repo; the Messages/simulator lane is prone to lock contention and misleading failures when multiple test or build processes overlap.

## Validation Circuit Breaker

Lock the exact commands, journeys, screenshots, and reviewers in the active verification contract before implementation. Validation proves that contract; it does not silently broaden it.

- A failed check may trigger implementation work only when it demonstrates a production defect or a constraint gap traceable to the user request or an authoritative owner doc.
- A newly discovered legitimate constraint requires a dated plan amendment with its source, acceptance boundary, and proof method. Update the user before beginning the expanded work.
- Treat simulator launch failures, stale accessibility references, nondeterministic taps, result-bundle corruption, and other non-product failures as harness instability unless reproduced as a product defect.
- For the same failing command or journey, allow the initial attempt plus at most two focused reruns. A rerun after a code or test fix counts toward that budget. When the budget is exhausted, stop, record the last evidence, and report the work as implemented but not verified or blocked as appropriate.
- Do not add adjacent journeys, new assertions, or reviewer-requested proof after implementation unless they close a predeclared constraint or a formally amended contract gap.
- Keep exploratory and failed diagnostic bundles out of final proof. Produce one clean final bundle containing only the contracted tests, or cite independent clean per-test results when bundling is not supported.
- Run the completion gate once after contracted evidence is green. Retry it only after a relevant source/evidence correction or a documented transient infrastructure cause; unrelated failures are reported rather than chased inside the current slice.

For player-facing visual work, show the user the representative inspected results as soon as the contracted observable proof is green. Administrative review and completion checks may continue afterward, but they must not delay the result update or start another visual iteration without authorization.

`make practical-gate` defaults its simulator unit-test lane to `platform=iOS Simulator,name=iPhone 17,OS=latest`. Override `TEST_SIMULATOR_DESTINATION` when that device family is unavailable; keep the destination explicit so Xcode does not silently request an uninstalled newest runtime for an older simulator model. This lane skips `UnluckySevensUITests` because Messages UI tests require an explicit standalone-app install and controlled app-drawer state; run those through the XCUITest/UX Lab lanes below and attach their verdicts to the completion contract.

After rebuilding `MessagesExtension` or the standalone Messages app, explicitly install the freshly built `UnluckySevensApp.app` with `xcrun simctl install` before any `test-without-building` screenshot run. That test action refreshes the test runner but does not guarantee that Messages replaces an already installed host app; compare the built and installed `MessagesExtension` executable hashes when a capture contradicts the current source.

For the repeatable full UI catalog, run `bash ./scripts/run-ui-screenshot-catalog.sh iphone`, then `bash ./scripts/run-ui-screenshot-catalog.sh ipad`. The runner canonically regenerates, builds the app and UI-test runner into one pinned DerivedData root, installs that exact app, restarts Messages so the host discovers the extension, verifies the built and installed extension hashes, and runs each catalog route in its own XCTest process. Its timestamped local evidence directory contains the run manifest, per-route result bundles, exported attachments, and direct simulator stills. A failed route stops the lane; follow the retry budget and circuit breaker below rather than silently continuing.

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
