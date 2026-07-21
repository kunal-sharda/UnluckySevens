# Unlucky Sevens Icon Direction

## Purpose and Outcome

Ship the approved grey masked-robber identity across the app icon, iMessage extension icon, live board robber, and collapsed-message/status artwork without duplicating inconsistent geometry.

## Execution Settings

- Validation profile: `standard`
- Delivery posture: `direct`
- Rationale: the approved direction changes production app assets and two user-visible rendering surfaces; the user approved r14 on 2026-07-20 and explicitly requested productionization, commit, and push.

## Comparison Contract

- Five directions: cut purse, stealing hand, robber mask, robber pawn, lockpick tools.
- One shared 1024-point grid, optical weight, felt/parchment/clay/gold palette, and unmistakable `7` construction.
- Resource cards reuse the production wood and brick stamp language.
- Inspect the same artwork at large, 128 px, 60 px, and 32 px.
- Final comparison does not name the concepts on the artwork so recognition can be judged without prompting.

## Verification Contract

<!-- verification-contract:start -->
| ID | Class | Source | Acceptance | Verification | Evidence | Status | Rationale |
| --- | --- | --- | --- | --- | --- | --- | --- |
| ICON-001 | judgment | user direction | Competing directions receive comparable craft before selection | matched comparison plus harsh blind review | report:matched-direction-review-2026-07-20 | pass | Five-direction comparison and subsequent physical-piece iterations established the approved masked robber identity |
| ICON-002 | observable | Messages usage | Approved identity remains recognizable at 60 px and 32 px | exact-size generated asset inspection | report:production-small-size-inspection-2026-07-20 | pass | Production 60 px, 32 px, and smallest iMessage exports retain the grey piece, dark mask mass, and red 7 |
| ICON-003 | judgment | user direction | User approves a direction before productionization | explicit approval gate | report:user-approved-r14-2026-07-20 | pass | User said the refined r14 looks great and requested commit, push, and closeout |
| ICON-004 | mechanical | asset catalogs | Every app and iMessage icon slot has an exact-size generated asset with valid opacity requirements | asset metadata inspection plus build | command:bash ./scripts/generate-icon-assets.sh; command:27 PNG metadata audit alpha_yes=0; command:make build | pass | All 27 catalog PNGs are exact catalog sizes, opaque RGB, and accepted by actool |
| ICON-005 | observable | Messages and board usage | App and iMessage icons, live board robber, and collapsed-message robber/status artwork use the approved identity and remain legible | rendered production assets plus installed Messages drawer, board, and transcript attachment inspection | command:xcodebuild installed-drawer UI test 1 passed; report:production-artifact-inspection-2026-07-20 | pass | The installed drawer icon has no white corners and preserves felt, grey piece, dark mask, and red 7; the near-edge keyline remains in larger assets, and the full board snapshot plus robber transcript card were directly inspected |
| ICON-006 | mechanical | renderer consistency | Board and transcript renderers share one normalized robber geometry contract | focused tests and source inspection | command:xcodebuild focused icon tests 8 passed; file:MessagesExtension/Sources/Presentation/RobberPieceGeometry.swift | pass | Both renderers consume RobberPieceGeometry; normalized bounds and containment tests pass |
<!-- verification-contract:end -->

<!-- fresh-review:start -->
| Reviewer | Required | Verdict | Evidence |
| --- | --- | --- | --- |
| constraint-auditor | yes | pass | report:fresh-icon-constraint-review-2026-07-20 |
| architecture | no | not-applicable | no module or protocol boundary changes planned |
| behavioral | no | not-applicable | no gameplay or transport behavior changes planned |
| product-ux | yes | pass | report:fresh-icon-product-ux-review-2026-07-20 |
<!-- fresh-review:end -->

## Living Record

### Progress

- [x] Lock comparison scope, validation profile, and checkpointed posture.
- [x] Construct the matched five-direction comparison.
- [x] Inspect large and compact renders.
- [x] Run harsh blind review and correct the leading candidate's tie, rupture, and card fan.
- [x] Pause for user approval.
- [x] Compare and refine masked-robber silhouettes after the user reopened that direction.
- [x] Record user approval of r14 and switch to direct productionization.
- [x] Generate exact app and iMessage asset-catalog images from a tracked vector source.
- [x] Share normalized robber geometry between board and transcript/status artwork.
- [x] Capture production icon, board, and transcript proof.
- [x] Complete fresh constraint and product/UX review.
- [ ] Run the standard completion gate, commit, and push.

### Decisions

- 2026-07-20: Raw freehand illustrative SVGs are rejected as a construction method. The comparison uses disciplined symbol geometry, a shared icon grammar, and no decorative detail that disappears at transcript size.
- 2026-07-20: Scratch comparison files remain ignored in `docs/design/workbench/`; production asset catalogs and owner docs are unchanged until approval.
- 2026-07-20: Blind review ranked the cut purse first and found it alone retained a coherent story at 32 px. Hand, mask, pawn, and lockpick directions remain in the sheet as fairly constructed concept evidence but are not recommended for another refinement round.
- 2026-07-20: User reopened the masked-robber direction and identified the pawn body—not the mask—as the defect. The next comparison holds the mask and `7` constant across hooded-bust, standing-cloak, and sack-carrier silhouettes.
- 2026-07-20: Round hood, beanie-avatar, and full dark-face variants were rejected internally as snowman, generic burglar, nun, astronaut, or superhero reads. The surviving construction direction is a forward asymmetric hood with a narrow masked eye window and concealed lower face.
- 2026-07-20: `masked-robber-r8.svg` passes the harsh checkpoint review at 60 px and 32 px. The reviewer found that the compressed eye window, concealed lower face, and enlarged `7` remove the emoji/superhero read while preserving the masked-robber identity.
- 2026-07-20: User rejected the hooded-person interpretation as overtuned and clarified that the target is the physical robber piece itself. Repo inspection found the board currently uses two circles while transcript media uses a generic three-shape pawn; neither captures the physical sphere, pear body, and flared foot. The next study treats the mask and `7` as markings on that object rather than designing a character.
- 2026-07-20: Review selected the balanced physical-piece proportion: round cap, pinched neck, pear body, and short flared foot. The mask was flattened into a painted band for r10 so the object remains primary and the face does not become a character.
- 2026-07-20: `robber-piece-r10.svg` passed the harsh checkpoint gate at full, 60 px, and 32 px. The selected silhouette reads as the tabletop piece; the flattened mask reads as paint and the `7` remains the dominant mark.
- 2026-07-20: The user supplied a direct physical-piece photograph. It supersedes inferred proportions: the piece has a large sphere, smooth upright egg, and short near-cylindrical plinth of approximately the body width. r11 redraws those three masses directly while keeping mask and `7` as surface markings only.
- 2026-07-20: Reference review initially withheld r11 because the base merged into a flared skirt. Shortening the egg and restoring a distinct shoulder plus squat near-vertical plinth passed the second reference-accuracy gate; the silhouette now tracks the supplied photograph at full, 60 px, and 32 px.
- 2026-07-20: User requested the photographed grey piece color and a better mask. r12 holds the accepted silhouette and grey fill constant while comparing a sphere-wrapping band, lean domino, and minimal painted stripe; all enlarge the eye apertures and treat the mask as surface paint rather than eyewear.
- 2026-07-20: Harsh review selected the curved wrap mask. The lean domino read as glasses and the stripe as a visor/censor bar. r13 retains the wrap's small-size mass, enlarges the almond eye openings, and softens the center pinch so it reads as one painted shape.
- 2026-07-20: `robber-piece-grey-r13.svg` passed the final harsh gate at full, 60 px, and 32 px. The cool grey tracks the supplied wooden reference; the curved edge-to-edge mask reads as painted robber marking rather than eyewear.
- 2026-07-20: Removed the faint decorative bottom arc from r13; it read as a bowl or unexplained semicircle and did not support the physical-piece identity.
- 2026-07-20: Final production audit found one required export correction: the shipping app-icon source must use an opaque, full-bleed square background, with the gold keyline inset farther from the system-applied mask. A slightly tighter piece shadow is optional. The accepted grey, curved mask, silhouette, and red `7` should not be reopened.
- 2026-07-20: User supplied a domino-mask reference and reopened only the face marking and keyline. r14 keeps the accepted physical-piece silhouette and `7`, makes the mask warmer-black with lifted brows, pointed almond apertures, and a restrained center notch, changes the border to a thin inset antique-gold keyline, tightens the shadow, and uses the required opaque full-bleed background.
- 2026-07-20: r14 adds a restrained inset contour and short side turn-lines to the mask. These communicate a band wrapping around the spherical head at large and app sizes, remain subordinate at 60 px, and intentionally disappear at 32 px rather than creating transcript-size noise.
- 2026-07-20: The antique-gold keyline moved from a conservative 31-unit inset to a 14-unit inset (about 2.7% of the source width). Its 102-unit corner radius preserves the approximate system-mask tangent, so it reads as a near-edge treatment while retaining clipping tolerance; final production proof still requires the installed iOS icon because the system owns the actual mask.
- 2026-07-20: User approved r14 and requested commit, push, and closeout. Validation moves from lightweight checkpointed comparison to standard direct productionization; scratch paths are no longer acceptable evidence for the shipping constraints.
- 2026-07-20: Quick Look letterboxed the initial 4:3 raster and preserved an alpha channel despite full-bleed artwork. The tracked generator now center-crops the 4:3 thumbnail, uses a CoreGraphics/ImageIO conversion for color-safe opaque RGB masters, and derives every catalog size from those masters. Direct inspection found no white bands and the metadata audit reported zero alpha-bearing PNGs.
- 2026-07-20: The first drawer capture exposed a stale pre-r14 icon cached by the simulator. A targeted uninstall/reinstall of only `com.unluckysevens.app` refreshed the extension registration and exposed a second defect: the legacy system `pngcrush` corrupted chromatic channels while removing alpha. Replacing it with the tracked CoreGraphics/ImageIO converter restored green felt, the grey piece, dark mask, and red `7`; the repeated harness test passed with the correct installed identity. The antique-gold keyline intentionally becomes subpixel at drawer scale and remains visible in larger assets.
- 2026-07-20: The host declares `LSApplicationLaunchProhibited = true`, so it intentionally has no SpringBoard icon surface; the app catalog is verified through exact opaque assets and actool rather than an impossible home-screen capture.

## Validation and Outcome

The comparison, human approval, production assets, shared geometry, focused tests, clean standard build, metadata audit, installed-drawer proof, and direct board/collapsed-message inspection pass. Fresh constraint and product/UX review both pass with no blockers. The standard completion gate, commit, and push remain pending.
