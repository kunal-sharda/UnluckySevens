import contextlib
import importlib.util
import io
import json
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch

SPEC = importlib.util.spec_from_file_location("streams", Path(__file__).parents[1] / "manual-device-evidence.py")
streams = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(streams)


class StreamTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.output = Path(self.temp.name)
        self.output_patch = patch.object(streams, "OUTPUT", self.output)
        self.output_patch.start()
        self.addCleanup(self.output_patch.stop)
        self.quiet = contextlib.redirect_stdout(io.StringIO())
        self.quiet.__enter__()
        self.addCleanup(self.quiet.__exit__, None, None, None)

    def session(self, mode="local"):
        return streams.create_two("1.0", "9", "candidate-commit-plus-digest", mode, True)

    def observation(self, directory, step, **changes):
        initial = step in ("invite", "receive-invite")
        evidence = self.output / (step + ".txt")
        evidence.write_text("Synthetic unit-test observation; never real hardware proof.")
        value = dict(role=streams.STEPS[step][0], result="pass", version="1.0", build="9",
                     distribution="development", os_version="test-os", game="test-game",
                     revision=0 if initial else 1, state_hash="a" * 64 if initial else "b" * 64,
                     roster_count=1 if initial else 2, evidence_file=str(evidence))
        value.update(changes)
        path = self.output / (step + "-observation.json")
        path.write_text(json.dumps(value))
        return path

    def complete_session(self, **last_changes):
        directory = self.session()
        for step in streams.STEPS:
            extra = last_changes if step == "reopen-join" else {}
            streams.record(directory, step, self.observation(directory, step, **extra))
        return directory

    def verdict(self, directory):
        return streams.evaluate(streams.load_session(directory)[1], directory)

    def test_empty_session_cannot_pass(self):
        self.assertEqual(self.verdict(self.session())["status"], "pending")

    def test_report_revalidates_recorded_build(self):
        directory = self.complete_session()
        data = streams.load_session(directory)[1]
        data["observations"]["join"]["build"] = "8"
        self.assertEqual(streams.evaluate(data, directory)["status"], "failed")


    def test_valid_observations_are_manual_not_automated(self):
        result = self.verdict(self.complete_session())
        self.assertEqual(result["status"], "passed")
        self.assertEqual(result["execution"], "operator-assisted")
        self.assertEqual(result["three_account_concurrency"], "not-tested")

    def test_missing_canonical_diagnostics_stay_pending(self):
        result = self.verdict(self.complete_session(state_hash=None))
        self.assertEqual(result["visual_journey"], "operator-reported-pass")
        self.assertEqual(result["canonical_agreement"], "pending")
        self.assertEqual(result["status"], "pending")

    def test_different_game_revision_hash_and_roster_fail(self):
        for changes in ({"game": "other"}, {"revision": 2}, {"state_hash": "c" * 64}, {"roster_count": 3}):
            with self.subTest(changes=changes):
                self.assertEqual(self.verdict(self.complete_session(**changes))["status"], "failed")

    def test_build_role_schema_and_mode_mismatch_rejected(self):
        for changes in ({"build": "8"}, {"role": "B"}, {"private_hand": [1, 2]}, {"revision": True}, {"roster_count": -1}):
            with self.subTest(changes=changes):
                directory = self.session()
                with self.assertRaises(ValueError):
                    streams.record(directory, "invite", self.observation(directory, "invite", **changes))
        directory = self.session("remote-testflight")
        with self.assertRaises(ValueError):
            streams.record(directory, "invite", self.observation(directory, "invite"))

    def test_out_of_order_or_overwritten_checkpoint_rejected(self):
        directory = self.session()
        with self.assertRaises(ValueError):
            streams.record(directory, "join", self.observation(directory, "join"))
        observation = self.observation(directory, "invite")
        streams.record(directory, "invite", observation)
        with self.assertRaises(ValueError):
            streams.record(directory, "invite", observation)

    def test_evidence_is_copied_and_tamper_is_detected(self):
        directory = self.complete_session()
        (self.output / "invite.txt").write_text("External evidence changed")
        self.assertEqual(self.verdict(directory)["status"], "passed")
        (directory / "evidence-invite.txt").write_text("Retained evidence changed")
        self.assertEqual(self.verdict(directory)["status"], "failed")

    def test_missing_empty_evidence_cannot_record_success(self):
        directory = self.session()
        for path in [self.output / "missing", self.output / "empty"]:
            if path.name == "empty":
                path.touch()
            with self.assertRaises(ValueError):
                streams.record(directory, "invite", self.observation(directory, "invite", evidence_file=str(path)))

    def test_no_separate_accounts_confirmation_rejected(self):
        with self.assertRaises(ValueError):
            streams.create_two("1.0", "9", "commit", "local", False)

    def test_failed_step_prevents_advancing(self):
        directory = self.session()
        streams.record(directory, "invite", self.observation(directory, "invite", result="fail"))
        with self.assertRaises(ValueError):
            streams.record(directory, "receive-invite", self.observation(directory, "receive-invite"))
        self.assertNotEqual(self.verdict(directory)["status"], "passed")





    def test_device_error_is_blocked_and_does_not_retry(self):
        calls = []
        def executor(command, log, timeout):
            calls.append(command)
            return 1
        self.assertEqual(streams.preflight("test-device", executor), 1)
        self.assertEqual(len(calls), 1)
        data = json.loads(next(self.output.glob("*/session.json")).read_text())
        self.assertEqual(data["status"], "blocked")
        self.assertEqual(data["ui_automation"], "not-run")

    def test_report_nonzero_when_pending(self):
        self.assertEqual(streams.main(["report", "--session", str(self.session())]), 1)

    def test_reject_external_session(self):
        with self.assertRaises(ValueError):
            streams.load_session(self.output.parent)


if __name__ == "__main__":
    unittest.main()
