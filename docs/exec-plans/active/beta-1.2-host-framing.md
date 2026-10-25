# Beta 1.2 host framing — #56

## Purpose and Outcome
Resolve intermittent whole-table displacement blocking Build/Dev tutorial previews. See [purchase plan](beta-1.2-purchase-costs.md) and [issue #56](https://github.com/kunal-sharda/UnluckySevens/issues/56).

## Execution Settings
- Validation profile: `standard`
- Delivery posture: `direct`
- Rationale: owner explicitly requests fixing demonstrated defect; layout acceptance remains unchanged.

## Context and Boundaries
The prior preview retry budget stopped correctly. On 2026-10-24 owner explicitly authorizes a new diagnostic/fix slice. Do not change game rules, transport, tabletop identity or hide failed assertions. Resign/shared bubbles/Road Building remain separate checkpointed plans. Consult symbol-level Apple bounds, convert and safeAreaRegions docs before host changes.

## Milestones / Plan of Work
1. Instrument independent UIKit root/hosting frames and reproduce with minimal fixed SwiftUI markers under existing containment.
2. Classify the displaced layer, make one sourced correction, verify actual Build/Dev and lifecycle.
3. Update owner docs, independent audit, scoped completion gate, commit/push.

## Verification Contract and Fresh Review
Locked proof: one isolated iPhone simulator; minimal host-marker route, actual Build/Dev disable/re-enable routes, lifecycle route; inspect frames, hierarchy and captures. Initial diagnostic batch plus at most two diagnosed correction batches; no unchanged reruns except evidenced infrastructure. Reuse generated build for focused host-layout model tests. A passing single intermittent route is insufficient: minimal/actual geometry must agree and one independent cold confirmation of affected routes must pass. No expanded platform work without new evidence.

<!-- verification-contract:start -->
| ID | Class | Source | Acceptance | Verification | Evidence | Status | Rationale |
| --- | --- | --- | --- | --- | --- | --- | --- |
| HOST-001 | mechanical | #56; AGENTS | Cause classified before correction; no speculative host workaround | Apple symbols; minimal repro; independent UIKit/SwiftUI coordinates | report:minimal-probe-20261025T055444Z; report:apple-symbol-record; file:MessagesExtension/Sources/App/MessagesRootView.swift | pass | Minimal reproduction isolates root boundary; flexible outer frame preserves host snapshot and keyboard policy |
| HOST-002 | observable | #56 | Header contained; Build/Dev toggle preserves board identity and canonical state | minimal marker plus Build/Dev harness and cold confirmation | report:20261025T060522Z-iphone; report:20261025T061141Z-iphone | pass | Build/Dev clean independent cold passes include disable/re-enable frame, mount and canonical assertions |
| HOST-003 | observable | #56 | Unaffected lifecycle remains contained | lifecycle capture and geometry | report:20261025T061141Z-iphone-lifecycle | pass | Captures inspected; recorded header and panel within canvas |
| HOST-004 | mechanical | AGENTS | Build/model tests and owner docs verified | focused layout tests; standard build; doc freshness | report:beta12-component-review-17-pass; command:make-build; command:make-doc-freshness | pass | Mechanical prerequisites passed; final wrapper and push recorded below |
<!-- verification-contract:end -->

<!-- fresh-review:start -->
| Reviewer | Required | Verdict | Evidence |
| --- | --- | --- | --- |
| constraint-auditor | yes | pass | report:host-auditor-2026-10-24 |
| architecture | yes | pass | report:host-auditor-2026-10-24 |
| product-ux | yes | pass | report:host-auditor-2026-10-24 |
<!-- fresh-review:end -->

## Living Record
2026-10-24: prior equal snapshots omitted bounds origin/window placement; both SwiftUI markers shifted together. Record full UIKit geometry before attributing to keyboard or Apple. No correction yet.

## Validation and Outcome
Pending diagnostic reproduction. Not complete.

Initial minimal probe (`20261025T055444Z-iphone`) reproduces displacement with no board/popup: UIKit root/child window y544.33, fixed SwiftUI top y447.83, in compact335pt host. The initial >100 assertion passed but is insufficient for compact containment; inspected screenshot shows top marker clipped. Refine probe to explicitly request expanded presentation and wait for style=expanded, matching affected previews; no layout correction yet. Runner source was edited while the process was active, causing a trailing shell read error after a clean test export; current `bash -n` passes. Do not edit running scripts again. No complete harness pass claimed.

Cause-backed correction candidate: minimal marker reproduction places UIKit root and hosting child identically while SwiftUI fixed root is translated outside those bounds. The outer `MessagesRootView` ZStack reports a fixed content height to its parent. Apple GeometryReader documentation explicitly describes its flexible preferred size. Wrap the existing root in GeometryReader and explicitly frame it to the proposal with top-leading alignment. This changes only the outer layout boundary, preserves existing host measurements/offsets and keyboard safe-area behavior, and does not assume a platform keyboard bug. Validate before retaining. Focused model/render run `output/beta12-component-review.xcresult` passes17 tests (9 host-layout,4 road draft,3 timing/private input,1 shared-result render).

Expanded baseline probe (`20261025T060031Z-iphone`) passes and is visually contained (root/child window y72, SwiftUI y112), confirming intermittency/transition sensitivity rather than a permanently incorrect snapshot. Compact minimal case is the deterministic failing control: new probe asserts SwiftUI top against independent UIKit marker before expansion, then verifies expanded frame. Third diagnostic run tests the flexible-root correction. Actual six-route preview batch follows only if this passes; initial actual batch is separate from minimal repro attempts, with at most two diagnosed correction batches as already locked.

Corrected minimal probe (`20261025T060327Z-iphone`) passes independent UIKit marker containment and expanded header assertions; screenshot inspected. The initially sampled state was already expanded despite the attachment name “Compact root containment”; do not claim this proves a forced compact transition. It does prove the corrected top marker matches UIKit y112 with unchanged root/child y72 and full canvas748. Actual Build/Dev journeys and independent cold confirmation remain required. The compact failing baseline remains diagnostic evidence of the root boundary problem, not a final passing compact claim.

Exact Apple sources consulted before correction: [UIView.bounds](https://developer.apple.com/documentation/uikit/uiview/bounds), [UIView.convert(_:to:)](https://developer.apple.com/documentation/uikit/uiview/convert(_:to:)-2kf3d), [UIHostingController.safeAreaRegions](https://developer.apple.com/documentation/swiftui/uihostingcontroller/safearearegions), and [GeometryReader](https://developer.apple.com/documentation/swiftui/geometryreader). Retrieved symbol Markdown from the corresponding `.md` endpoints on2026-10-24. Bounds is local-coordinate geometry; convert with nil yields window coordinates; hosting safe regions default to all; GeometryReader offers flexible preferred sizing. No platform contract is overridden.

Fresh review identified two genuine gaps against existing HOST-002/003 wording: test only measured board identity after disable, not after Settings re-enable, and lifecycle captures lacked recorded geometry. Added final board frame/mount assertions after re-enable and lifecycle header/panel-vs-canvas measurements. This is test evidence correction, not new product scope. Final confirmation will run lifecycle/Build/Dev with these assertions; no layout or visual edits. Actual first Build/Dev routes passed full flows and frame/header assertions in20261025T060522Z-iphone; inspected Build capture and coordinates match root y72/canvas112/header122.

Mechanical gate structure clarification: HOST-004 records the build/model/doc prerequisites; `make completion-gate PLAN=...` and commit/push remain mandatory final delivery steps below the contract, avoiding a circular requirement to pass the gate before it can run. This does not remove either required command. `make build` passed with canonical generation and doc freshness (`/tmp/uls-host-build.log`). Final independent lifecycle and Build now pass (`20261025T061141Z-iphone`); lifecycle geometry is canvas112..860/header122/panel378.5..593.83. Dev confirmation still pending.

Final independent confirmation `output/ui-screenshot-harness/20261025T061141Z-iphone` passed all3 routes on the second isolated iPhone simulator: lifecycle, Build, Dev. Final tests assert board position/mount after both disable and re-enable plus canonical equality; lifecycle header/panel geometry is within host. Combined first six-route batch also passed (20261025T060522Z-iphone). No product source change since root correction; the separate Road Building visual refinement does not affect these host routes. No device/milestone or forced-compact acceptance claim.

Fresh independent reviewer `host_auditor` (no implementer history) returns PASS for constraint-auditor, architecture and host-containment product-UX. Opened HOST-001..004, root/controller/harness diff, exact Apple symbols, baseline/corrected marker captures/coordinates, actual Build/Dev/lifecycle and final independent xcresult summaries. Independently verified17 component tests and3 final routes pass; ran doc freshness successfully. No blocking findings. Explicitly excludes adjacent preview design approval and forced compact transition claims. Completion gate and commit/push remain mandatory delivery requirements.

`make completion-gate PLAN=docs/exec-plans/active/beta-1.2-host-framing.md` passed (2026-10-24; `/tmp/uls-host-completion.log`): selected contract, harness audit, whitespace, doc freshness, canonical generation and standard simulator build. Adjacent preview approval remains pending and is not part of this completed host-fix contract. Owner docs changed: Messages host lessons and QA; architecture, product rules, DESIGN and README intentionally unaffected by this sizing correction. No historical cleanup or durable binary admission.
