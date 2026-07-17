#!/usr/bin/env python3
"""Validate the evidence-backed completion tables in an active ExecPlan."""

from __future__ import annotations

import argparse
from pathlib import Path
import re
import sys


ROOT = Path(__file__).resolve().parents[1]
CONTRACT_START = "<!-- verification-contract:start -->"
CONTRACT_END = "<!-- verification-contract:end -->"
REVIEW_START = "<!-- fresh-review:start -->"
REVIEW_END = "<!-- fresh-review:end -->"
CLASSES = {"mechanical", "observable", "judgment"}
STATUSES = {"pending", "pass", "fail", "blocked", "not-applicable"}
VERDICTS = STATUSES
PROFILES = {"lightweight", "standard", "release-critical"}
POSTURES = {"explore", "checkpointed", "direct"}


def fail(message: str) -> None:
    raise ValueError(message)


def section(text: str, start: str, end: str) -> str:
    if text.count(start) != 1 or text.count(end) != 1:
        fail(f"expected exactly one {start} / {end} section")
    before, remainder = text.split(start, 1)
    body, after = remainder.split(end, 1)
    if end in before or start in after:
        fail(f"misordered markers for {start}")
    return body


def table_rows(body: str, expected_header: list[str]) -> list[dict[str, str]]:
    lines = [line.strip() for line in body.splitlines() if line.strip().startswith("|")]
    if len(lines) < 3:
        fail("table must contain a header, separator, and at least one row")

    def cells(line: str) -> list[str]:
        return [part.strip() for part in line.strip().strip("|").split("|")]

    header = cells(lines[0])
    if header != expected_header:
        fail(f"unexpected table header: {header!r}")
    separator = cells(lines[1])
    if len(separator) != len(header) or not all(set(value) <= {"-", ":"} for value in separator):
        fail("invalid Markdown table separator")

    result: list[dict[str, str]] = []
    for line in lines[2:]:
        values = cells(line)
        if len(values) != len(header):
            fail(f"row has {len(values)} cells; expected {len(header)}: {line}")
        result.append(dict(zip(header, values)))
    return result


def verify_file_tokens(evidence: str, root: Path) -> None:
    for token in (part.strip() for part in evidence.split(";")):
        if token.startswith("file:"):
            candidate = root / token.removeprefix("file:")
            if not candidate.exists():
                fail(f"evidence file does not exist: {candidate.relative_to(root)}")


def has_pending_token(evidence: str) -> bool:
    return any(part.strip().endswith(":pending") for part in evidence.split(";"))


def validation_profile(text: str) -> str:
    legacy_sections = re.findall(
        r"^## Validation Profile\s*$\n(.*?)(?=^##\s|\Z)",
        text,
        re.MULTILINE | re.DOTALL,
    )
    compact_sections = re.findall(
        r"^## Execution Settings\s*$\n(.*?)(?=^##\s|\Z)",
        text,
        re.MULTILINE | re.DOTALL,
    )
    if len(legacy_sections) + len(compact_sections) != 1:
        fail("plan must contain exactly one Validation Profile or Execution Settings section")

    if compact_sections:
        body = compact_sections[0]
        matches = re.findall(r"^- Validation profile:\s*`([^`]+)`\s*$", body, re.MULTILINE)
    else:
        body = legacy_sections[0]
        matches = re.findall(r"^- Profile:\s*`([^`]+)`\s*$", body, re.MULTILINE)
    if len(matches) != 1 or matches[0] not in PROFILES:
        fail("plan must declare exactly one valid validation profile")
    postures = re.findall(r"^- Delivery posture:\s*`([^`]+)`\s*$", body, re.MULTILINE)
    if len(postures) != 1 or postures[0] not in POSTURES:
        fail("plan must declare exactly one valid delivery posture")
    rationales = re.findall(r"^- Rationale:\s*(\S.*)$", body, re.MULTILINE)
    if not rationales:
        fail("validation profile requires a non-empty rationale")
    return matches[0]


def validate(plan: Path, mode: str, root: Path = ROOT) -> str:
    text = plan.read_text(encoding="utf-8")
    profile = validation_profile(text)
    constraints = table_rows(
        section(text, CONTRACT_START, CONTRACT_END),
        ["ID", "Class", "Source", "Acceptance", "Verification", "Evidence", "Status", "Rationale"],
    )
    reviews = table_rows(
        section(text, REVIEW_START, REVIEW_END),
        ["Reviewer", "Required", "Verdict", "Evidence"],
    )

    seen: set[str] = set()
    for row in constraints:
        identifier = row["ID"]
        if not identifier or identifier in seen:
            fail(f"constraint ID is empty or duplicated: {identifier!r}")
        seen.add(identifier)
        if row["Class"] not in CLASSES:
            fail(f"{identifier}: invalid class {row['Class']!r}")
        if row["Status"] not in STATUSES:
            fail(f"{identifier}: invalid status {row['Status']!r}")
        for field in ("Source", "Acceptance", "Verification"):
            if not row[field]:
                fail(f"{identifier}: {field} is required")
        if row["Status"] == "pass":
            if not row["Evidence"] or has_pending_token(row["Evidence"]):
                fail(f"{identifier}: pass requires concrete evidence")
            verify_file_tokens(row["Evidence"], root)
        if row["Status"] == "not-applicable" and not row["Rationale"]:
            fail(f"{identifier}: not-applicable requires rationale")
        if mode == "complete" and row["Status"] not in {"pass", "not-applicable"}:
            fail(f"{identifier}: completion blocked by status {row['Status']!r}")

    reviewer_names: set[str] = set()
    for row in reviews:
        name = row["Reviewer"]
        if not name or name in reviewer_names:
            fail(f"reviewer is empty or duplicated: {name!r}")
        reviewer_names.add(name)
        if row["Required"] not in {"yes", "no"}:
            fail(f"{name}: Required must be yes or no")
        if row["Verdict"] not in VERDICTS:
            fail(f"{name}: invalid verdict {row['Verdict']!r}")
        if row["Required"] == "yes" and mode == "complete":
            if row["Verdict"] != "pass":
                fail(f"{name}: required reviewer has verdict {row['Verdict']!r}")
            if not row["Evidence"] or has_pending_token(row["Evidence"]):
                fail(f"{name}: pass requires review evidence")
            verify_file_tokens(row["Evidence"], root)

    if "constraint-auditor" not in reviewer_names:
        fail("fresh-review table must include constraint-auditor")
    auditor = next(row for row in reviews if row["Reviewer"] == "constraint-auditor")
    if profile == "lightweight":
        if auditor["Required"] == "yes" and mode == "complete" and auditor["Verdict"] != "pass":
            fail("required lightweight constraint-auditor must pass")
    elif auditor["Required"] != "yes":
        fail(f"constraint-auditor must be required for {profile} plans")
    return profile


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--plan", required=True, type=Path)
    parser.add_argument("--mode", choices=("schema", "complete"), default="schema")
    parser.add_argument("--print-profile", action="store_true")
    parser.add_argument("--root", type=Path, default=ROOT, help=argparse.SUPPRESS)
    args = parser.parse_args()
    root = args.root.resolve()
    raw_plan = args.plan if args.plan.is_absolute() else root / args.plan
    plan = raw_plan.resolve()
    try:
        if not plan.is_file():
            fail(f"plan does not exist: {plan}")
        active_root = (root / "docs/exec-plans/active").resolve()
        if raw_plan.is_symlink() or plan.parent != active_root or plan.suffix != ".md":
            fail("selected plan must be a direct, non-symlinked Markdown child of docs/exec-plans/active")
        profile = validate(plan, "schema" if args.print_profile else args.mode, root)
    except (OSError, ValueError) as error:
        print(f"verification contract failed: {error}", file=sys.stderr)
        return 1
    if args.print_profile:
        print(profile)
    else:
        try:
            label = plan.relative_to(root)
        except ValueError:
            label = plan
        print(f"verification contract {args.mode} check passed: {label} [{profile}]")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
