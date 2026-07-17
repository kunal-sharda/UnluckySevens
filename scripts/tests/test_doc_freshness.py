from __future__ import annotations

from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest


SCRIPT = Path(__file__).resolve().parents[1] / "check-doc-freshness.sh"


class DocFreshnessTests(unittest.TestCase):
    def setUp(self) -> None:
        self.temp = tempfile.TemporaryDirectory()
        self.root = Path(self.temp.name)
        (self.root / "scripts").mkdir()
        shutil.copy2(SCRIPT, self.root / "scripts/check-doc-freshness.sh")
        subprocess.run(["git", "init", "-q"], cwd=self.root, check=True)
        (self.root / "README.md").write_text("# Fixture\n", encoding="utf-8")
        subprocess.run(
            ["git", "add", "README.md", "scripts/check-doc-freshness.sh"],
            cwd=self.root,
            check=True,
        )
        subprocess.run(
            [
                "git",
                "-c",
                "user.name=Harness Test",
                "-c",
                "user.email=harness@example.invalid",
                "commit",
                "-qm",
                "fixture",
            ],
            cwd=self.root,
            check=True,
        )

    def tearDown(self) -> None:
        self.temp.cleanup()

    def run_check(self) -> subprocess.CompletedProcess[str]:
        return subprocess.run(
            ["bash", "./scripts/check-doc-freshness.sh"],
            cwd=self.root,
            capture_output=True,
            text=True,
        )

    def test_design_only_change_requires_current_owner_doc(self) -> None:
        candidate = self.root / "docs/design/workbench/candidate.svg"
        candidate.parent.mkdir(parents=True)
        candidate.write_text("<svg/>\n", encoding="utf-8")
        result = self.run_check()
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("No Tier 1/2 docs changed", result.stdout)

    def test_root_design_readme_satisfies_design_freshness(self) -> None:
        candidate = self.root / "docs/design/workbench/candidate.svg"
        candidate.parent.mkdir(parents=True)
        candidate.write_text("<svg/>\n", encoding="utf-8")
        owner = self.root / "docs/design/README.md"
        owner.parent.mkdir(parents=True, exist_ok=True)
        owner.write_text("# Design workspace\n", encoding="utf-8")
        result = self.run_check()
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertIn("docs/design/README.md", result.stdout)


if __name__ == "__main__":
    unittest.main()
