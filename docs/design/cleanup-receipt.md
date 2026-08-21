# Design-Artifact Cleanup Receipt

This receipt records the 2026-07-10 deletion of the untracked numbered tree-design study. It is evidence for the active harness plan, not a replacement for [DESIGN.md](../../DESIGN.md) or production assets.

## Admission Result

- Starting durable-design candidate tree: 424 files, approximately 154 MB.
- Retained from the numbered study: no binary design copies and no rejected/candidate pass notes.
- Current `docs/design/` set immediately after cleanup: `README.md` and `references/manifest.json`, 8 KB on disk.
- Archive created: no. Superseded iterations were deleted as requested.
- Production source of truth: `MessagesExtension/Resources/Assets.xcassets`.

Before the 2026-08-21 hygiene removal, each selected pass-10 tile export was compared byte-for-byte with the then-production `BoardTiles` PNG. All six pairs matched; these hashes are retained as historical evidence for the removed files:

| Production tile | SHA-256 before | SHA-256 after |
| --- | --- | --- |
| `tile_brick.png` | `6cfeda69c57c191985e0791a200194b03167d28d269831a64b8d9b56005e9767` | removed |
| `tile_desert.png` | `5836bb620432f930482715f2e65c0cafa2d84eaaee54ae8dd88494afb4bcf432` | removed |
| `tile_ore.png` | `0ede0f1ffd4720d74276dee351f54610736a52558eb67709c1614fd71e5776de` | removed |
| `tile_sheep.png` | `aa731fa17e71497e9da2479120cb265051833690314b099b32ae7f53a6e1c252` | removed |
| `tile_wheat.png` | `8182e4650af60ad4c56885e411bc30ad0c878bfbda0fd17af28325af072a8369` | removed |
| `tile_wood.png` | `0040acb5f67e84694da4218fb0921a4ba7de5f12765447996c3aea078dc71d2b` | removed |

The 2026-08-21 audit verified that runtime source and generated bundle inputs reference `BoardStamps`/`BoardMiniStamps`, not `BoardTiles`; all six `BoardTiles` imagesets and the uncolored `merchant_ship` imageset were removed. Future candidates belong in ignored `docs/design/workbench/`; durable binary admission follows `references/manifest.json` and requires explicit user approval.
