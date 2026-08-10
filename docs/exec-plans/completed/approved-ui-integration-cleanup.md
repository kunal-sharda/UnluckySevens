# Approved UI Integration Cleanup

## Purpose and Outcome

Close the remaining production-integration gap after repository baseline `b9f49a8`: retire the selectable legacy gameplay layouts, prevent their return with a static guard, prove the production Messages journey through the checked-in harness, and install the validated build on the user's connected iPhone for physical review.

## Execution Settings

- Validation profile: `standard`
- Delivery posture: `direct`
- Rationale: the approved Physical Props direction is already settled. This slice is a production-routing and deletion cleanup with meaningful UI risk, so it requires focused observable evidence and a fresh constraint audit but no new visual comparison gate.

## Context and Boundaries

- [Design](../../../DESIGN.md) owns the approved tabletop vocabulary.
- [Architecture](../../../ARCHITECTURE.md) owns Core, transport, and Messages presentation boundaries.
- [QA](../../quality/qa.md), [UX Lab](../../quality/ux-lab.md), and [device runbooks](../../quality/device-runbooks.md) own validation.
- `ULS_CoreGame` and `ULS_Transport` remain unchanged.
- Production routing must use the approved Physical Props shell. DEBUG UX Lab controls may select fixtures, but may not restore retired gameplay layout families.
- The user's untracked `.impeccable/` directory is out of scope and must remain untouched.

## Milestones / Plan of Work

1. Remove retired `framedShelf`, `framelessShelf`, and `feltTools` layout selections and make Physical Props the sole gameplay layout.
2. Remove unreachable legacy shell/fallback components and their comparison controls/tests.
3. Add a repository static guard that rejects retired gameplay layout identifiers in production source.
4. Generate through `bash ./scripts/gen.sh`, run focused tests and the integrated Messages journey, and inspect the resulting artifact.
5. Run the standard completion gate and doc freshness.
6. Build, sign, and install the validated app on the connected physical iPhone for user review.

## Verification Contract and Fresh Review

<!-- verification-contract:start -->
| ID | Class | Source | Acceptance | Verification | Evidence | Status | Rationale |
| --- | --- | --- | --- | --- | --- | --- | --- |
| AUI-001 | mechanical | user request | Retired gameplay layout cases and selectable DEBUG comparisons are absent from production source | static guard and source inspection | `python3 scripts/check-harness.py`; focused retired-identifier source search returned no matches | pass | Production source and UX Lab no longer expose a retired layout route; the guard has focused rejection/pass tests |
| AUI-002 | mechanical | architecture and design owners | Physical Props is the sole gameplay layout and Core or transport contracts do not change | focused unit tests and diff inspection | `xcodebuild ... -only-testing:MessagesExtensionTests/GamePhysicalNotPrimaryPlayerContextTests test` (9 tests passed); `git diff -- Packages/ULS_CoreGame Packages/ULS_Transport` empty | pass | Resolver always returns Physical Props; no Core or transport files changed |
| AUI-003 | observable | user request and QA | Invitation through lobby, setup, turn, forced seven, recovery/settings, and end states remain reachable through the Messages harness | focused XCUITest/UX Lab journey and artifact inspection | `xcodebuild ... -only-testing:UnluckySevensUITests/MessagesExtensionDesignSliceUITests/testApprovedProductionJourneyUsesPhysicalPropsOnly test` (passed in 85.488 seconds; xcresult `Test-UnluckySevens-2026.07.30_01-40-14--0700.xcresult`) | pass | One continuous harness journey observed all required surfaces and asserted that the retired overlay shelf never appeared |
| AUI-004 | mechanical | AGENTS.md | Standard completion gate and documentation freshness pass | profile-aware completion gate | `make completion-gate PLAN=docs/exec-plans/active/approved-ui-integration-cleanup.md` passed after an escalated rerun allowed Tuist cache creation | pass | Contract, harness audit, diff check, doc freshness, generation, and generic simulator build all passed |
| AUI-005 | observable | user request | Validated signed build is installed on the connected iPhone | device discovery, install, and launch/install receipt | `bash ./scripts/install-connected-devices.sh --skip-gen --debug --allow-provisioning-updates --device B3F7F35C-334B-5BAB-803E-6F5BE8B066C7`; `devicectl device info apps` lists `Unlucky Sevens`, bundle `com.unluckysevens.app`, version `1.0 (1)` | pass | Signed Debug container and Messages extension installed successfully on Kunal's paired iPhone 16 Pro |
<!-- verification-contract:end -->

<!-- fresh-review:start -->
| Reviewer | Required | Verdict | Evidence |
| --- | --- | --- | --- |
| constraint-auditor | yes | pass | Local fresh contract audit mapped every acceptance row to its required evidence class; no pending, failed, or unverified row remains |
| architecture | no | not-applicable | No module or protocol boundary change planned |
| behavioral | yes | pass | Focused resolver suite and the 85.488-second integrated Messages journey passed |
| product-ux | yes | pass | Integrated journey observed lobby Join/Ready, setup, start turn, normal turn, actionable discard, Settings, Recovery Games, and End Screen in the approved family |
<!-- fresh-review:end -->

## Living Record

### Progress

- [x] Baseline confirmed at `b9f49a8`; worktree contains only the user's unrelated untracked `.impeccable/` directory.
- [x] Legacy route owners identified in `GameTabletopLayoutStyle`, `GameShellView`, the freeze overlay, DEBUG UX Lab comparisons, and focused resolver tests.
- [x] Production routing cleanup implemented; retired comparison components remain source-internal only where the live shell still shares implementation, and are unreachable as layout routes.
- [x] Static guard implemented and covered by focused tests.
- [x] Focused resolver, integrated Messages journey, and standard completion gate passed.
- [x] Physical iPhone install completed and verified in the device app registry.

### Decisions

- 2026-07-30: Use `standard` plus `direct`. The user explicitly requested implementation, and the Physical Props direction is already approved.

### Discoveries

- `feltTools` currently names both a retired selectable layout and implementation/accessibility identifiers reused by Physical Props. The cleanup must distinguish obsolete routing from still-live physical components, renaming live vocabulary where needed rather than deleting behavior blindly.
- The checked-in device installer named the generated target (`UnluckySevensApp`) as though it were a shared scheme. The generated workspace exposes `UnluckySevens`; the script now separates the build scheme from the `.app` product name.

## Validation and Outcome

Production and DEBUG fixture routing now have one supported gameplay family: Physical Props. The retired layout cases and comparison controls/tests are gone, a harness audit guard blocks their reintroduction in production source, and focused unit/XCUITest evidence covers resolver behavior plus the integrated Messages journey. A signed Debug build is installed on the paired iPhone 16 Pro for the user's physical review.

The standard completion gate passed after the in-sandbox attempt was retried with the filesystem access required by Tuist's cache. This plan is closed and moved to completed history.
