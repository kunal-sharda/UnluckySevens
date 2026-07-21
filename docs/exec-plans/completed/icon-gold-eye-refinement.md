# Icon Gold-Eye Refinement

## Purpose and Outcome

Ship the user-approved icon refinement: retain the cool-grey physical robber, warm-black wrap mask, clay-red `7`, and dark felt; remove the outer antique-gold keyline and use antique gold only as a restrained outline around the mask apertures. The app and iMessage icon families must derive from exact tracked SVG masters and remain legible and opaque at catalog sizes.

## Execution Settings

- Validation profile: `lightweight`
- Delivery posture: `direct`
- Rationale: the user selected one settled, narrowly scoped visual refinement after direct SVG comparison. The change affects two vector masters and their mechanically generated catalog PNGs without changing gameplay, layout, protocol, or shared robber geometry.

## Context and Boundaries

- [DESIGN.md](../../../DESIGN.md) owns the durable product-identity language.
- [QA](../../quality/qa.md) owns validation routing; `scripts/generate-icon-assets.sh` is the canonical catalog generator.
- Preserve the accepted piece silhouette, proportions, mask mass and wrap contours, `7` geometry and color, felt background, and shadow.
- Do not add a desert hex or outer keyline.
- Apply the gold aperture outline to both tracked icon SVG masters. Board and transcript geometry remain unchanged; tiny uses may omit this icon-only accent while retaining the shared silhouette, mask mass, and `7`.
- Preserve all unrelated dirty-worktree changes.

## Plan of Work

1. Update the square and wide SVG masters with the selected aperture outline and no outer border.
2. Regenerate every app and iMessage catalog PNG through the canonical generator, correcting its rasterization path if the generated 1024 assets reveal upscaling.
3. Inspect full-size and compact outputs, audit exact dimensions and opacity, update `DESIGN.md`, and run the lightweight completion gate.

## Verification Contract and Fresh Review

<!-- verification-contract:start -->
| ID | Class | Source | Acceptance | Verification | Evidence | Status | Rationale |
| --- | --- | --- | --- | --- | --- | --- | --- |
| IGR-001 | judgment | user-approved direction | Both production masters use no hex or outer app-frame keyline and use restrained antique-gold aperture and mask-silhouette edging without changing the approved robber construction | direct SVG and generated 1024, 180, 60, and 32 px inspection | file:scripts/assets/unlucky-sevens-icon.svg; file:scripts/assets/unlucky-sevens-imessage-icon.svg; report:final-mask-contour-product-ux-pass-2026-07-21 | pass | The 1.4-unit aperture and quieter 1.2-unit outer-mask edging read as painted detail at full size, recede at compact sizes, and avoid the goggle read |
| IGR-002 | mechanical | asset catalogs | All 27 generated PNGs have their declared dimensions and no alpha channel | canonical generator plus metadata audit | command:bash-./scripts/generate-icon-assets.sh-passed; command:27-PNG-sips-metadata-audit-alpha-no; command:MessagesExtension-generic-simulator-build-passed | pass | WebKit renders exact 1024 masters, catalog downsizing is explicit, all outputs are opaque, and actool accepts both catalogs |
| IGR-003 | observable | Messages icon usage | The selected identity remains readable in the smallest square and wide iMessage exports | exact-size generated asset inspection plus focused shared-geometry tests | report:1024-180-60-and-54x40-production-artifact-inspection-2026-07-21; command:RobberPieceGeometryTests-2-passed | pass | The mask mass, grey pawn silhouette, and red 7 remain clean while the gold detail intentionally recedes; the shared board/transcript geometry retains valid bounds |
<!-- verification-contract:end -->

<!-- fresh-review:start -->
| Reviewer | Required | Verdict | Evidence |
| --- | --- | --- | --- |
| constraint-auditor | no | not-applicable | lightweight narrow asset refinement |
| architecture | no | not-applicable | no boundaries, dependencies, or protocols change |
| behavioral | no | not-applicable | no gameplay or transport behavior changes |
| product-ux | yes | pass | report:final-mask-contour-product-ux-pass-2026-07-21 |
<!-- fresh-review:end -->

## Living Record

### Progress

- [x] User selected no hex, gold aperture outlines, and no outer border from exact SVG candidates.
- [x] Production SVG masters updated.
- [x] Catalog assets regenerated and inspected.
- [x] Owner doc and completion evidence updated.
- [x] Rejected icon studies removed from the ignored workbench after selection.
- [x] Repository completion gate passed from the clean implementation commit.

### Decisions

- 2026-07-21: Gold is retained only at the mask apertures. Removing the outer keyline makes the robber itself the identity and avoids an artwork-inside-a-frame composition.
- 2026-07-21: Harsh full-size review rejected the initial 2.2-unit opaque aperture stroke as aviator-goggle-like. The production accent is reduced to a 1.4-unit stroke at 72% opacity so it reads as painted edging at large sizes and may disappear cleanly at compact sizes.
- 2026-07-21: The user approved a final 1.2-unit, 55%-opacity antique-gold contour around the entire mask silhouette. The quieter outer contour complements the aperture edging without adding gradient shading or restoring the rejected app-frame keyline.

### Discoveries

- The comparison must be derived directly from the tracked 520-point SVG construction; reconstructed comparison SVGs changed filter and scaling behavior and were rejected as misleading evidence.
- The canonical generator's Quick Look path rasterized the 520-point SVG near its intrinsic coordinate size and enlarged that result to 1024, producing visible stair-stepping in the shipping master. The generator now uses WebKit's SVG pipeline at the requested output dimensions before the existing opaque-RGB conversion and exact catalog downsizing.

## Validation and Outcome

The square and wide production SVG masters now present the masked robber directly on felt with no hex or outer app frame. The mask apertures use a 1.4-unit antique-gold stroke at 72% opacity, while the entire mask silhouette uses a quieter 1.2-unit stroke at 55% opacity. No indentation or shine gradient was added to the robber or mask. The generator now rasterizes SVGs through WebKit at native 1024 output dimensions instead of enlarging Quick Look thumbnails, eliminating the observed pixelation before exact catalog downsizing. The canonical generator passed, all 27 PNGs are opaque at their declared sizes, direct 1024/180/60/54x40 inspection passed, `RobberPieceGeometryTests` passed 2 tests, the harsh product/UX re-review passed with no blockers, and the generated workspace MessagesExtension build including both asset catalogs succeeded.

The shared dirty worktree's first completion attempt stopped on unrelated settings/tutorial plan and workbench state. After the scoped implementation commit `9d16361`, `make completion-gate PLAN=docs/exec-plans/active/icon-gold-eye-refinement.md` passed from a clean detached worktree at that exact commit. Unrelated in-flight files were neither staged nor changed.
