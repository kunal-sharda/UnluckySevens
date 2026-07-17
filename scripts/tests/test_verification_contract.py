from __future__ import annotations

from pathlib import Path
import subprocess
import tempfile
import textwrap
import unittest


ROOT = Path(__file__).resolve().parents[2]
CHECKER = ROOT / "scripts/check-verification-contract.py"


def plan(
    status: str = "pass",
    evidence: str = "command:test",
    verdict: str = "pass",
    profile: str = "standard",
    auditor_required: str = "yes",
    legacy_profile_section: bool = False,
    posture: str = "direct",
) -> str:
    settings = (
        f"""## Validation Profile

        - Profile: `{profile}`
        - Delivery posture: `{posture}`
        - Rationale: Fixture profile for contract-checker tests."""
        if legacy_profile_section
        else f"""## Execution Settings

        - Validation profile: `{profile}`
        - Delivery posture: `{posture}`
        - Rationale: Fixture profile for contract-checker tests."""
    )
    return textwrap.dedent(
        f"""
        # Test Plan

        {settings}

        <!-- verification-contract:start -->
        | ID | Class | Source | Acceptance | Verification | Evidence | Status | Rationale |
        | --- | --- | --- | --- | --- | --- | --- | --- |
        | T-001 | mechanical | test | Checker behaves | run checker | {evidence} | {status} | test rationale |
        <!-- verification-contract:end -->

        <!-- fresh-review:start -->
        | Reviewer | Required | Verdict | Evidence |
        | --- | --- | --- | --- |
        | constraint-auditor | {auditor_required} | {verdict} | report:test |
        | architecture | no | not-applicable | not triggered |
        <!-- fresh-review:end -->
        """
    )


class VerificationContractTests(unittest.TestCase):
    def run_checker(
        self,
        contents: str,
        mode: str = "complete",
        print_profile: bool = False,
        directory: Path | None = None,
    ) -> subprocess.CompletedProcess[str]:
        target = directory or ROOT / "docs/exec-plans/active"
        target.mkdir(parents=True, exist_ok=True)
        with tempfile.NamedTemporaryFile("w", suffix=".md", dir=target, delete=False) as handle:
            handle.write(contents)
            path = Path(handle.name)
        try:
            command = ["python3", str(CHECKER), "--plan", str(path), "--mode", mode]
            if print_profile:
                command.append("--print-profile")
            return subprocess.run(
                command,
                cwd=ROOT,
                capture_output=True,
                text=True,
            )
        finally:
            path.unlink(missing_ok=True)

    def test_complete_contract_passes(self) -> None:
        self.assertEqual(self.run_checker(plan()).returncode, 0)

    def test_pending_constraint_blocks_completion(self) -> None:
        self.assertNotEqual(self.run_checker(plan(status="pending", evidence="command:pending")).returncode, 0)

    def test_failed_constraint_blocks_completion(self) -> None:
        self.assertNotEqual(self.run_checker(plan(status="fail", evidence="command:test-failed")).returncode, 0)

    def test_blocked_constraint_blocks_completion(self) -> None:
        self.assertNotEqual(self.run_checker(plan(status="blocked", evidence="report:blocker")).returncode, 0)

    def test_pass_requires_evidence(self) -> None:
        self.assertNotEqual(self.run_checker(plan(evidence="")).returncode, 0)

    def test_pass_rejects_mixed_pending_evidence(self) -> None:
        self.assertNotEqual(self.run_checker(plan(evidence="command:test; report:pending")).returncode, 0)

    def test_required_reviewer_must_pass(self) -> None:
        self.assertNotEqual(self.run_checker(plan(verdict="blocked")).returncode, 0)

    def test_schema_mode_allows_inflight_work(self) -> None:
        self.assertEqual(self.run_checker(plan(status="pending", evidence="command:pending", verdict="pending"), mode="schema").returncode, 0)

    def test_missing_profile_is_rejected(self) -> None:
        self.assertNotEqual(self.run_checker(plan().replace("## Execution Settings", "## Other Settings")).returncode, 0)

    def test_invalid_profile_is_rejected(self) -> None:
        self.assertNotEqual(self.run_checker(plan(profile="everything")).returncode, 0)

    def test_missing_delivery_posture_is_rejected(self) -> None:
        self.assertNotEqual(
            self.run_checker(plan().replace("- Delivery posture: `direct`\n", "")).returncode,
            0,
        )

    def test_invalid_delivery_posture_is_rejected(self) -> None:
        self.assertNotEqual(self.run_checker(plan(posture="sometimes")).returncode, 0)

    def test_print_profile_returns_validated_profile(self) -> None:
        result = self.run_checker(plan(profile="release-critical"), print_profile=True)
        self.assertEqual(result.returncode, 0)
        self.assertEqual(result.stdout.strip(), "release-critical")

    def test_legacy_validation_profile_section_remains_supported(self) -> None:
        self.assertEqual(self.run_checker(plan(legacy_profile_section=True)).returncode, 0)

    def test_lightweight_plan_can_skip_fresh_auditor(self) -> None:
        result = self.run_checker(
            plan(profile="lightweight", auditor_required="no", verdict="not-applicable")
        )
        self.assertEqual(result.returncode, 0)

    def test_standard_plan_cannot_skip_fresh_auditor(self) -> None:
        result = self.run_checker(
            plan(profile="standard", auditor_required="no", verdict="not-applicable")
        )
        self.assertNotEqual(result.returncode, 0)

    def test_root_level_sidecar_plan_is_rejected(self) -> None:
        self.assertNotEqual(self.run_checker(plan(), directory=ROOT).returncode, 0)

    def test_completed_plan_is_rejected(self) -> None:
        self.assertNotEqual(
            self.run_checker(plan(), directory=ROOT / "docs/exec-plans/completed").returncode,
            0,
        )

    def test_external_absolute_plan_is_rejected(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            self.assertNotEqual(self.run_checker(plan(), directory=Path(directory)).returncode, 0)


if __name__ == "__main__":
    unittest.main()
