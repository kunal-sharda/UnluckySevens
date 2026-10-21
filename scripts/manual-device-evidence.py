#!/usr/bin/env python3
"""Manual Messages evidence collection and read-only preflight. Never drives devices or sends messages."""
import argparse
import datetime as dt
import hashlib
import json
import os
from pathlib import Path
import subprocess
import sys
import uuid

ROOT = Path(__file__).resolve().parents[1]
OUTPUT = ROOT / "output" / "testing-streams"
STEPS = {
    "invite": ("A", "On A, publish a fresh invite in the dedicated test conversation."),
    "receive-invite": ("B", "On B, observe and open that actual incoming invite bubble."),
    "join": ("B", "On B, join from that invite using the production Join control."),
    "reopen-join": ("A", "On A, observe and reopen B's actual join update. Do not start a two-player standard match."),
}


def now():
    return dt.datetime.now(dt.timezone.utc).isoformat()


def save(path, value):
    temporary = path.with_suffix(".tmp")
    temporary.write_text(json.dumps(value, indent=2) + "\n")
    temporary.replace(path)


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()




def new_session(route, candidate):
    OUTPUT.mkdir(parents=True, exist_ok=True)
    directory = OUTPUT / (dt.datetime.now(dt.timezone.utc).strftime("%Y%m%dT%H%M%SZ") + "-" + uuid.uuid4().hex[:8])
    directory.mkdir(mode=0o700)
    save(directory / "session.json", {
        "schema": 1, "route": route, "created_at": now(), "candidate": candidate,
        "observations": {}, "status": "pending",
    })
    return directory


def load_session(directory):
    directory = Path(directory).resolve()
    if not directory.is_relative_to(OUTPUT.resolve()):
        raise ValueError("Session must be under output/testing-streams.")
    data = json.loads((directory / "session.json").read_text())
    if data.get("schema") != 1:
        raise ValueError("Unsupported session schema.")
    return directory, data




def execute(command, log, timeout):
    # No shell interpolation, no implicit retries, bounded process group lifetime.
    with log.open("w") as out:
        process = subprocess.Popen(command, cwd=ROOT, stdout=out, stderr=subprocess.STDOUT,
                                   start_new_session=True)
        try:
            return process.wait(timeout=timeout)
        except (subprocess.TimeoutExpired, KeyboardInterrupt):
            import signal
            os.killpg(process.pid, signal.SIGTERM)
            try:
                process.wait(timeout=5)
            except subprocess.TimeoutExpired:
                os.killpg(process.pid, signal.SIGKILL)
                process.wait()
            return 124




def create_two(version, build, source, mode, separate_accounts):
    if not separate_accounts:
        raise ValueError("Confirm two independent iMessage accounts with --separate-accounts.")
    if not version.strip() or not build.strip() or not source.strip():
        raise ValueError("Version, build, and candidate source reference are required.")
    directory = new_session("two-device", {
        "version": version, "build": build, "source_reference": source,
        "mode": mode, "separate_accounts": "operator-confirmed",
    })
    instructions = [
        "# Two-device invite/join smoke", "",
        "Operator-assisted evidence only. This runner never sends, taps, installs, or remotely controls TestFlight.",
        "Use a dedicated conversation and confirm both devices have this candidate.",
        "A is the host and B is the guest; they must use distinct iMessage accounts.",
        "A remote participant performs their own taps. Keep evidence private in this ignored directory.",
        "Do not include names, addresses, private hands, or secret card/trade data in observation JSON.",
        "Only use available diagnostics for game/revision/hash; leave unavailable fields null rather than guess.", "",
    ]
    template = {
        "result": "pending", "version": version, "build": build,
        "distribution": "testflight" if mode == "remote-testflight" else "development",
        "os_version": "", "game": None, "revision": None, "state_hash": None,
        "roster_count": None, "evidence_file": "",
    }
    for step, (role, instruction) in STEPS.items():
        save(directory / f"{step}.json", {**template, "role": role})
        instructions.extend([f"## {step} (device {role})", instruction,
                             f"Fill {step}.json with observations and an evidence-file path, then run:",
                             f"python3 scripts/manual-device-evidence.py record --session '{directory}' --step {step} --observation '{directory / (step + '.json')}'", ""])
    instructions.extend(["Run report after recording the steps. Missing canonical fields yield pending canonical agreement even if the visual journey passed.",
                         "This two-person lobby journey cannot close three-account concurrent-join or competing-trade proof."])
    (directory / "instructions.md").write_text("\n".join(instructions) + "\n")
    print(directory)
    return directory


def validate_observation(value, candidate, step):
    expected = {"role", "result", "version", "build", "distribution", "os_version",
                "game", "revision", "state_hash", "roster_count", "evidence_file"}
    if set(value) != expected:
        raise ValueError("Observation fields must match the generated template exactly.")
    if value["role"] != STEPS[step][0]:
        raise ValueError("Wrong device role for checkpoint.")
    if value["result"] not in ("pass", "fail", "blocked"):
        raise ValueError("Record an actual pass, fail, or blocked observation.")
    if (value["version"], value["build"]) != (candidate["version"], candidate["build"]):
        raise ValueError("Observed build does not match this candidate; create a separate session.")
    if value["distribution"] not in ("development", "testflight"):
        raise ValueError("Distribution must be development or testflight.")
    if candidate["mode"] == "remote-testflight" and value["distribution"] != "testflight":
        raise ValueError("Remote TestFlight route requires TestFlight observations on both devices.")
    if not isinstance(value["os_version"], str) or not value["os_version"].strip():
        raise ValueError("Record the observed OS version.")
    for key in ("revision", "roster_count"):
        item = value[key]
        if item is not None and (type(item) is not int or item < 0):
            raise ValueError(f"{key} must be a nonnegative integer or null.")
    for key in ("game", "state_hash"):
        item = value[key]
        if item is not None and (not isinstance(item, str) or not item.strip() or len(item) > 128):
            raise ValueError(f"{key} must be a bounded correlation value or null.")


def record(directory, step, observation):
    directory, data = load_session(directory)
    if data["route"] != "two-device":
        raise ValueError("Not a two-device session.")
    value = json.loads(Path(observation).read_text())
    validate_observation(value, data["candidate"], step)
    previous = list(STEPS)[:list(STEPS).index(step)]
    if any(data["observations"].get(k, {}).get("result") != "pass" for k in previous):
        raise ValueError("Record preceding successful checkpoints first.")
    if step in data["observations"]:
        raise ValueError("Checkpoint is immutable; create a new session for a retry.")
    path = Path(value["evidence_file"]).expanduser().resolve()
    if not path.is_file() or path.stat().st_size == 0:
        raise ValueError("A nonempty evidence file is required, including for failure reports.")
    # Copy exact evidence bytes, rather than retaining a mutable external reference.
    evidence = directory / f"evidence-{step}{path.suffix}"
    evidence.write_bytes(path.read_bytes())
    value.update(evidence_file=evidence.name, evidence_sha256=digest(evidence),
                 recorded_at=now(), evidence_class="operator-observed")
    data["observations"][step] = value
    data["status"] = "failed" if value["result"] == "fail" else "blocked" if value["result"] == "blocked" else "pending"
    save(directory / "session.json", data)


def evaluate(data, directory):
    observations = data["observations"]
    result = {"route": "two-device", "execution": "operator-assisted",
              "visual_journey": "pending", "canonical_agreement": "pending",
              "three_account_concurrency": "not-tested", "status": "pending"}
    for step, value in observations.items():
        metadata = {"evidence_sha256", "recorded_at", "evidence_class"}
        try:
            if step not in STEPS or value.get("evidence_class") != "operator-observed":
                raise ValueError("Invalid recorded checkpoint.")
            validate_observation({k: v for k, v in value.items() if k not in metadata},
                                 data["candidate"], step)
            if Path(value["evidence_file"]).name != value["evidence_file"]:
                raise ValueError("Evidence must remain inside the session.")
        except (ValueError, KeyError):
            return {**result, "status": "failed", "reason": "Invalid recorded checkpoint."}
        path = directory / value["evidence_file"]
        if not path.is_file() or digest(path) != value.get("evidence_sha256"):
            return {**result, "status": "failed", "reason": "Evidence missing or changed."}
        if value["result"] in ("fail", "blocked"):
            return {**result, "status": value["result"], "reason": "Checkpoint did not pass."}
    if set(observations) != set(STEPS):
        return result
    result["visual_journey"] = "operator-reported-pass"
    keys = ("game", "revision", "state_hash", "roster_count")
    if any(o.get(k) is None for o in observations.values() for k in keys):
        return {**result, "reason": "Canonical diagnostics unavailable; visual observations are insufficient."}
    a, b, c, d = (observations[k] for k in STEPS)
    same_invite = all(a[k] == b[k] for k in keys)
    same_join = all(c[k] == d[k] for k in keys)
    valid = (same_invite and same_join and a["game"] == c["game"]
             and a["roster_count"] == 1 and c["roster_count"] == 2
             and c["revision"] > a["revision"] and c["state_hash"] != a["state_hash"])
    if not valid:
        return {**result, "status": "failed", "canonical_agreement": "failed", "reason": "State observations diverge or the join did not advance membership."}
    return {**result, "status": "passed", "canonical_agreement": "operator-evidence-matches",
            "distribution": sorted({o["distribution"] for o in observations.values()}),
            "limitation": "Compares operator-supplied values; not an automated capture or release completion gate."}


def preflight(device, executor=execute):
    directory = new_session("device-preflight", {"device": device})
    output = directory / "device-app.json"
    code = executor(["xcrun", "devicectl", "device", "info", "apps", "--device", device,
                     "--bundle-id", "me.ksharda.games.unluckysevens", "--include-all-apps",
                     "--json-output", str(output), "--timeout", "15"], directory / "preflight.log", 25)
    data = json.loads((directory / "session.json").read_text())
    # Inventory success alone is never an installed-build or UI verdict.
    data.update(status="blocked" if code else "inventory-collected", exit_code=code,
                ui_automation="not-run", build_verification="pending-inspection")
    save(directory / "session.json", data)
    print(directory)
    return code if 0 <= code < 126 else 1


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    sub = parser.add_subparsers(dest="command", required=True)
    two = sub.add_parser("two", help="Create a resumable, operator-assisted invite/join session")
    for arg in ("version", "build", "source"):
        two.add_argument("--" + arg, required=True)
    two.add_argument("--mode", choices=("local", "remote-testflight"), required=True)
    two.add_argument("--separate-accounts", action="store_true")
    rec = sub.add_parser("record", help="Record one actual observation and its evidence")
    rec.add_argument("--session", required=True)
    rec.add_argument("--step", choices=STEPS, required=True)
    rec.add_argument("--observation", required=True)
    report = sub.add_parser("report")
    report.add_argument("--session", required=True)
    probe = sub.add_parser("preflight", help="Read-only local app inventory; no install or UI driving")
    probe.add_argument("--device", required=True)
    args = parser.parse_args(argv)
    if args.command == "two":
        create_two(args.version, args.build, args.source, args.mode, args.separate_accounts)
    elif args.command == "record":
        record(args.session, args.step, args.observation)
    elif args.command == "preflight":
        return preflight(args.device)
    else:
        directory, data = load_session(args.session)
        if data["route"] != "two-device":
            raise ValueError("Use session.json for preflight results.")
        result = evaluate(data, directory)
        save(directory / "report.json", result)
        print(json.dumps(result, indent=2))
        return 0 if result["status"] == "passed" else 1
    return 0


if __name__ == "__main__":
    try:
        sys.exit(main())
    except (ValueError, OSError, subprocess.SubprocessError) as error:
        print(f"manual-device-evidence: {error}", file=sys.stderr)
        sys.exit(2)
