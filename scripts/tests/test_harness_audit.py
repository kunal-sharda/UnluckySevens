from __future__ import annotations

import importlib.util
import json
from pathlib import Path
import tempfile
import unittest
import hashlib


SCRIPT = Path(__file__).resolve().parents[1] / "check-harness.py"
SPEC = importlib.util.spec_from_file_location("check_harness", SCRIPT)
assert SPEC and SPEC.loader
check_harness = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(check_harness)


class HarnessAuditTests(unittest.TestCase):
    def setUp(self) -> None:
        self.original_root = check_harness.ROOT
        self.temp = tempfile.TemporaryDirectory()
        self.root = Path(self.temp.name).resolve()
        check_harness.ROOT = self.root

    def tearDown(self) -> None:
        check_harness.ROOT = self.original_root
        self.temp.cleanup()

    def write(self, relative: str, contents: str | bytes) -> Path:
        path = self.root / relative
        path.parent.mkdir(parents=True, exist_ok=True)
        if isinstance(contents, bytes):
            path.write_bytes(contents)
        else:
            path.write_text(contents, encoding="utf-8")
        return path

    def make_manifests(self) -> None:
        self.write(
            "Packages/ULS_Transport/Package.swift",
            '// swift-tools-version: 5.9\nimport PackageDescription\nlet package = Package(name: "ULS_Transport", targets: [.target(name: "ULS_Transport")])\n',
        )
        self.write(
            "Packages/ULS_CoreGame/Package.swift",
            '// swift-tools-version: 5.9\nimport PackageDescription\nlet package = Package(name: "ULS_CoreGame", targets: [.target(name: "ULS_CoreGame")])\n',
        )

    def write_reference_manifest(self, artifacts: list[dict], **overrides: int) -> None:
        self.write(
            "docs/design/references/manifest.json",
            json.dumps(
                {
                    "version": 1,
                    "max_file_bytes": overrides.get("max_file_bytes", check_harness.REFERENCE_MAX_FILE_BYTES),
                    "max_total_bytes": overrides.get("max_total_bytes", check_harness.REFERENCE_MAX_TOTAL_BYTES),
                    "artifacts": artifacts,
                }
            ),
        )

    def reference_item(self, path: str, payload: bytes, purpose: str = "approved baseline") -> dict:
        return {
            "path": path,
            "purpose": purpose,
            "owner_doc": "DESIGN.md",
            "approved_by": "user",
            "approved_on": "2026-07-10",
            "source_task": "test",
            "sha256": hashlib.sha256(payload).hexdigest(),
            "size_bytes": len(payload),
            "status": "current",
        }
    def test_forbidden_core_import_is_reported(self) -> None:
        self.make_manifests()
        self.write("Packages/ULS_CoreGame/Sources/ULS_CoreGame/Bad.swift", "import SwiftUI\n")
        errors: list[str] = []
        check_harness.check_imports(errors)
        self.assertTrue(any("forbidden ULS_CoreGame import SwiftUI" in item for item in errors))

    def test_clean_package_boundaries_pass(self) -> None:
        self.make_manifests()
        self.write("Packages/ULS_CoreGame/Sources/ULS_CoreGame/Good.swift", "import Foundation\n")
        self.write("Packages/ULS_Transport/Sources/ULS_Transport/Good.swift", "import Foundation\n")
        errors: list[str] = []
        check_harness.check_imports(errors)
        self.assertEqual(errors, [])

    def test_retired_gameplay_layout_route_is_reported(self) -> None:
        self.write(
            "MessagesExtension/Sources/Presentation/GameTabletopLayoutStyle.swift",
            "let style = GameTabletopLayoutStyle.framedShelf\n",
        )
        errors: list[str] = []
        check_harness.check_retired_gameplay_routes(errors)
        self.assertTrue(any("retired gameplay layout or symbol" in item for item in errors))

    def test_retired_gameplay_symbol_is_reported(self) -> None:
        self.write(
            "MessagesExtension/Sources/Features/Legacy.swift",
            "let usesPhysicalProps = true\n",
        )
        errors: list[str] = []
        check_harness.check_retired_gameplay_routes(errors)
        self.assertTrue(any("retired gameplay layout or symbol" in item for item in errors))

    def test_canonical_gameplay_source_passes(self) -> None:
        self.write(
            "MessagesExtension/Sources/Features/Canonical.swift",
            "let route = GameShellRoute.none\n",
        )
        errors: list[str] = []
        check_harness.check_retired_gameplay_routes(errors)
        self.assertEqual(errors, [])

    def test_non_sf_pro_interface_typography_is_reported(self) -> None:
        self.write(
            "MessagesExtension/Sources/Features/BadTypography.swift",
            'Text("Bad").font(.system(.body, design: .rounded))\n',
        )
        errors: list[str] = []
        check_harness.check_interface_typography(errors)
        self.assertTrue(any("non-SF-Pro interface typography" in item for item in errors))

    def test_board_number_serif_is_the_only_typography_exception(self) -> None:
        self.write(
            "MessagesExtension/Sources/Board/GameBoardScene.swift",
            "let descriptor = systemFont.fontDescriptor.withDesign(.serif)\n",
        )
        self.write(
            "MessagesExtension/Sources/Features/GoodTypography.swift",
            'Text("Count").font(.body).monospacedDigit()\n',
        )
        errors: list[str] = []
        check_harness.check_interface_typography(errors)
        self.assertEqual(errors, [])

    def test_additional_serif_usage_is_reported(self) -> None:
        self.write(
            "MessagesExtension/Sources/Features/BadTypography.swift",
            "let descriptor = systemFont.fontDescriptor.withDesign(.serif)\n",
        )
        errors: list[str] = []
        check_harness.check_interface_typography(errors)
        self.assertTrue(any("non-SF-Pro interface typography" in item for item in errors))

    def test_core_target_dependency_is_reported(self) -> None:
        self.make_manifests()
        self.write(
            "Packages/ULS_CoreGame/Package.swift",
            '// swift-tools-version: 5.9\nimport PackageDescription\nlet package = Package(name: "ULS_CoreGame", targets: [.target(name: "Bad"), .target(name: "ULS_CoreGame", dependencies: ["Bad"])])\n',
        )
        errors: list[str] = []
        check_harness.check_imports(errors)
        self.assertTrue(any("production target must remain dependency-free" in item for item in errors))

    def test_unmanifested_design_binary_is_reported(self) -> None:
        self.write(
            "docs/design/references/manifest.json",
            json.dumps(
                {
                    "version": 1,
                    "max_file_bytes": check_harness.REFERENCE_MAX_FILE_BYTES,
                    "max_total_bytes": check_harness.REFERENCE_MAX_TOTAL_BYTES,
                    "artifacts": [],
                }
            ),
        )
        self.write("docs/design/references/orphan.png", b"png")
        errors: list[str] = []
        check_harness.check_references(errors)
        self.assertTrue(any("unmanifested durable binary" in item for item in errors))

    def test_reference_budget_is_enforced(self) -> None:
        payload = b"x" * (check_harness.REFERENCE_MAX_FILE_BYTES + 1)
        artifact = self.write("docs/design/references/approved.png", payload)
        owner = self.write("DESIGN.md", "docs/design/references/approved.png\n")
        self.write(
            "docs/design/references/manifest.json",
            json.dumps(
                {
                    "version": 1,
                    "max_file_bytes": check_harness.REFERENCE_MAX_FILE_BYTES,
                    "max_total_bytes": check_harness.REFERENCE_MAX_TOTAL_BYTES,
                    "artifacts": [
                        {
                            "path": str(artifact.relative_to(self.root)),
                            "purpose": "approved baseline",
                            "owner_doc": str(owner.relative_to(self.root)),
                            "approved_by": "user",
                            "approved_on": "2026-07-10",
                            "source_task": "test",
                            "sha256": hashlib.sha256(payload).hexdigest(),
                            "size_bytes": len(payload),
                            "status": "current",
                        }
                    ],
                }
            ),
        )
        errors: list[str] = []
        check_harness.check_references(errors)
        self.assertTrue(any("size mismatch or budget violation" in item for item in errors))

    def test_reference_path_escape_is_reported(self) -> None:
        payload = b"approved"
        self.write_reference_manifest([self.reference_item("../outside.png", payload)])
        errors: list[str] = []
        check_harness.check_references(errors)
        self.assertTrue(any("repository-relative" in item for item in errors))

    def test_reference_owner_must_link_artifact(self) -> None:
        payload = b"approved"
        self.write("docs/design/references/approved.png", payload)
        self.write("DESIGN.md", "# Design\n")
        self.write_reference_manifest(
            [self.reference_item("docs/design/references/approved.png", payload)]
        )
        errors: list[str] = []
        check_harness.check_references(errors)
        self.assertTrue(any("owner does not link" in item for item in errors))

    def test_duplicate_purpose_is_reported(self) -> None:
        first = b"first"
        second = b"second"
        self.write("docs/design/references/first.png", first)
        self.write("docs/design/references/second.png", second)
        self.write(
            "DESIGN.md",
            "[first](docs/design/references/first.png)\n[second](docs/design/references/second.png)\n",
        )
        self.write_reference_manifest(
            [
                self.reference_item("docs/design/references/first.png", first, purpose="same proof"),
                self.reference_item("docs/design/references/second.png", second, purpose="same proof"),
            ]
        )
        errors: list[str] = []
        check_harness.check_references(errors)
        self.assertTrue(any("duplicate durable-reference purpose" in item for item in errors))

    def test_superseded_or_hash_mismatched_reference_is_reported(self) -> None:
        payload = b"approved"
        self.write("docs/design/references/approved.png", payload)
        self.write("DESIGN.md", "[approved](docs/design/references/approved.png)\n")
        item = self.reference_item("docs/design/references/approved.png", payload)
        item["status"] = "superseded"
        item["sha256"] = "0" * 64
        self.write_reference_manifest([item])
        errors: list[str] = []
        check_harness.check_references(errors)
        self.assertTrue(any("not explicitly user-approved/current" in entry for entry in errors))
        self.assertTrue(any("hash mismatch" in entry for entry in errors))

    def test_manifest_cannot_raise_reference_budgets(self) -> None:
        self.write(
            "docs/design/references/manifest.json",
            json.dumps({"version": 1, "max_file_bytes": 2_000_000, "max_total_bytes": 20_000_000, "artifacts": []}),
        )
        errors: list[str] = []
        check_harness.check_references(errors)
        self.assertTrue(any("fixed 1 MB" in item for item in errors))

    def test_unowned_workbench_residue_is_reported(self) -> None:
        self.write_reference_manifest([])
        self.write("docs/design/workbench/candidate.png", b"candidate")
        errors: list[str] = []
        check_harness.check_references(errors)
        self.assertTrue(any("unowned design workbench residue" in item for item in errors))

    def test_active_checkpoint_can_own_ignored_workbench_files(self) -> None:
        self.write_reference_manifest([])
        self.write("docs/design/workbench/candidate.png", b"candidate")
        self.write(
            "docs/exec-plans/active/visual-checkpoint.md",
            """# Visual checkpoint

## Execution Settings

- Validation profile: `standard`
- Delivery posture: `checkpointed`
- Rationale: Compare a visual direction.

Evidence remains in `docs/design/workbench/candidate.png` while approval is pending.

<!-- verification-contract:start -->
| ID | Class | Source | Acceptance | Verification | Evidence | Status | Rationale |
| --- | --- | --- | --- | --- | --- | --- | --- |
| V-001 | judgment | user | direction approved | owner review | report:pending | pending | approval gate |
<!-- verification-contract:end -->
""",
        )
        errors: list[str] = []
        notices: list[str] = []
        check_harness.check_references(errors, notices)
        self.assertEqual(errors, [])
        self.assertTrue(any("owned by active checkpoint" in item for item in notices))

    def test_checkpoint_without_pending_judgment_does_not_own_workbench(self) -> None:
        self.write_reference_manifest([])
        self.write("docs/design/workbench/candidate.png", b"candidate")
        self.write(
            "docs/exec-plans/active/finished-checkpoint.md",
            """# Finished checkpoint

## Execution Settings

- Validation profile: `standard`
- Delivery posture: `checkpointed`
- Rationale: Comparison was approved.

Evidence was stored in `docs/design/workbench/candidate.png`.

<!-- verification-contract:start -->
| ID | Class | Source | Acceptance | Verification | Evidence | Status | Rationale |
| --- | --- | --- | --- | --- | --- | --- | --- |
| V-001 | judgment | user | direction approved | owner review | report:approved | pass | approval recorded |
<!-- verification-contract:end -->
""",
        )
        errors: list[str] = []
        check_harness.check_references(errors)
        self.assertTrue(any("unowned design workbench residue" in item for item in errors))

    def test_historical_links_are_not_current_link_failures(self) -> None:
        self.write("docs/exec-plans/completed/old.md", "[removed](missing.swift)\n")
        self.write("README.md", "[current](DESIGN.md)\n")
        self.write("DESIGN.md", "# Design\n")
        errors: list[str] = []
        check_harness.check_links(errors)
        self.assertEqual(errors, [])

    def test_pending_active_plan_is_a_notice_not_an_error(self) -> None:
        self.write(
            "docs/exec-plans/active/in-progress.md",
            """# In progress

## Validation Profile

- Profile: `standard`
- Delivery posture: `direct`
- Rationale: Test fixture.

<!-- verification-contract:start -->
| ID | Class | Source | Acceptance | Verification | Evidence | Status | Rationale |
| --- | --- | --- | --- | --- | --- | --- | --- |
| T-001 | mechanical | test | works | checker | command:pending | pending | in flight |
<!-- verification-contract:end -->

<!-- fresh-review:start -->
| Reviewer | Required | Verdict | Evidence |
| --- | --- | --- | --- |
| constraint-auditor | yes | pending | report:pending |
<!-- fresh-review:end -->
""",
        )
        errors: list[str] = []
        notices: list[str] = []
        check_harness.check_contracts(errors, notices)
        self.assertEqual(errors, [])
        self.assertTrue(any("T-001" in item and "constraint-auditor" in item for item in notices))

    def test_malformed_active_plan_is_an_error(self) -> None:
        self.write(
            "docs/exec-plans/active/malformed.md",
            """# Malformed

<!-- verification-contract:start -->
not a contract
<!-- verification-contract:end -->
""",
        )
        errors: list[str] = []
        notices: list[str] = []
        check_harness.check_contracts(errors, notices)
        self.assertTrue(errors)


if __name__ == "__main__":
    unittest.main()
