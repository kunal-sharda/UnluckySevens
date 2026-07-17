#!/usr/bin/env python3
"""Audit active contracts, architecture imports, docs links, and design references."""

from __future__ import annotations

import hashlib
import json
import os
from pathlib import Path
import re
import subprocess
import sys


ROOT = Path(__file__).resolve().parents[1]
CONTRACT_CHECKER = Path(__file__).with_name("check-verification-contract.py")
FORBIDDEN_IMPORTS = {"SwiftUI", "UIKit", "Messages", "MessagesUI", "SpriteKit", "AppKit"}
REFERENCE_MAX_FILE_BYTES = 1_048_576
REFERENCE_MAX_TOTAL_BYTES = 10_485_760
LINK = re.compile(r"\[[^\]]+\]\(([^)]+)\)")
BINARY_SUFFIXES = {".png", ".jpg", ".jpeg", ".gif", ".webp", ".pdf", ".mov", ".mp4", ".xcresult", ".trace"}


def error(errors: list[str], message: str) -> None:
    errors.append(message)


def contract_notices(text: str) -> list[str]:
    notices: list[str] = []
    contract = text.split("<!-- verification-contract:start -->", 1)[1].split(
        "<!-- verification-contract:end -->", 1
    )[0]
    rows = [line for line in contract.splitlines() if line.strip().startswith("|")][2:]
    unresolved = []
    for line in rows:
        cells = [cell.strip() for cell in line.strip().strip("|").split("|")]
        if len(cells) == 8 and cells[6] not in {"pass", "not-applicable"}:
            unresolved.append(cells[0])

    review = text.split("<!-- fresh-review:start -->", 1)[1].split(
        "<!-- fresh-review:end -->", 1
    )[0]
    review_rows = [line for line in review.splitlines() if line.strip().startswith("|")][2:]
    pending_reviews = []
    for line in review_rows:
        cells = [cell.strip() for cell in line.strip().strip("|").split("|")]
        if len(cells) == 4 and cells[1] == "yes" and cells[2] != "pass":
            pending_reviews.append(cells[0])

    if unresolved:
        notices.append(f"unresolved constraints: {', '.join(unresolved)}")
    if pending_reviews:
        notices.append(f"pending required reviews: {', '.join(pending_reviews)}")
    return notices


def check_contracts(errors: list[str], notices: list[str]) -> None:
    plans = sorted((ROOT / "docs/exec-plans/active").glob("*.md"))
    for plan in plans:
        text = plan.read_text(encoding="utf-8")
        if "<!-- verification-contract:start -->" not in text:
            error(errors, f"active plan lacks verification contract: {plan.relative_to(ROOT)}")
            continue
        result = subprocess.run(
            [
                sys.executable,
                str(CONTRACT_CHECKER),
                "--plan",
                str(plan),
                "--mode",
                "schema",
                "--root",
                str(ROOT),
            ],
            cwd=ROOT,
            capture_output=True,
            text=True,
        )
        if result.returncode:
            error(errors, result.stderr.strip())
            continue
        plan_notices = contract_notices(text)
        if plan_notices:
            notices.append(f"{plan.relative_to(ROOT)}: {'; '.join(plan_notices)}")


def check_imports(errors: list[str]) -> None:
    for package in ("ULS_CoreGame", "ULS_Transport"):
        source = ROOT / "Packages" / package / "Sources"
        for swift_file in source.rglob("*.swift"):
            for line in swift_file.read_text(encoding="utf-8").splitlines():
                match = re.match(r"\s*(?:@\w+(?:\([^)]*\))?\s+)*import\s+(\w+)", line)
                if match and match.group(1) in FORBIDDEN_IMPORTS:
                    error(errors, f"forbidden {package} import {match.group(1)}: {swift_file.relative_to(ROOT)}")

    for package in ("ULS_CoreGame", "ULS_Transport"):
        package_root = ROOT / "Packages" / package
        if not (package_root / "Package.swift").is_file():
            continue
        harness_cache = ROOT / "Derived/Harness/SwiftPM"
        harness_cache.mkdir(parents=True, exist_ok=True)
        environment = os.environ.copy()
        environment.update(
            {
                "HOME": str(harness_cache / "home"),
                "CLANG_MODULE_CACHE_PATH": str(harness_cache / "clang-modules"),
                "SWIFTPM_MODULECACHE_OVERRIDE": str(harness_cache / "swiftpm-modules"),
            }
        )
        result = subprocess.run(
            ["swift", "package", "--disable-sandbox", "dump-package", "--package-path", str(package_root)],
            cwd=ROOT,
            capture_output=True,
            text=True,
            env=environment,
        )
        if result.returncode:
            error(errors, f"could not inspect {package} manifest: {result.stderr.strip()}")
            continue
        try:
            payload = json.loads(result.stdout)
        except json.JSONDecodeError as exc:
            error(errors, f"invalid dump-package output for {package}: {exc}")
            continue
        production = next((target for target in payload.get("targets", []) if target.get("name") == package), None)
        if production is None:
            error(errors, f"missing production target in {package} manifest")
        elif production.get("dependencies"):
            error(errors, f"{package} production target must remain dependency-free")
        if package == "ULS_CoreGame" and payload.get("dependencies"):
            error(errors, "ULS_CoreGame package must not declare package dependencies")

    project = ROOT / "Project.swift"
    if project.is_file():
        project_text = project.read_text(encoding="utf-8")
        for product in ("ULS_CoreGame", "ULS_Transport"):
            if f'.package(product: "{product}")' not in project_text:
                error(errors, f"MessagesExtension project wiring must consume {product}")


def check_links(errors: list[str]) -> None:
    for markdown in ROOT.rglob("*.md"):
        if any(part in {".git", "Derived", "DerivedData"} for part in markdown.parts):
            continue
        relative = markdown.relative_to(ROOT)
        if relative.parts[:3] in {
            ("docs", "exec-plans", "completed"),
            ("docs", "quality", "audits"),
        } or relative == Path("docs/product-specs/prd-verbatim.md"):
            continue
        text = markdown.read_text(encoding="utf-8", errors="replace")
        for target in LINK.findall(text):
            target = target.strip()
            if not target or target.startswith(("#", "http://", "https://", "mailto:")):
                continue
            target = target.split("#", 1)[0]
            if target.startswith("<") and target.endswith(">"):
                target = target[1:-1]
            candidate = Path(target)
            if not candidate.is_absolute():
                candidate = markdown.parent / candidate
            if not candidate.exists():
                error(errors, f"broken Markdown link in {markdown.relative_to(ROOT)}: {target}")


def active_workbench_owners() -> list[Path]:
    owners: list[Path] = []
    for plan in sorted((ROOT / "docs/exec-plans/active").glob("*.md")):
        text = plan.read_text(encoding="utf-8", errors="replace")
        checkpointed = bool(
            re.search(r"^- Delivery posture:\s*`checkpointed`\s*$", text, re.MULTILINE)
        )
        explicitly_uses_workbench = "docs/design/workbench/" in text
        pending_judgment = False
        if "<!-- verification-contract:start -->" in text and "<!-- verification-contract:end -->" in text:
            contract = text.split("<!-- verification-contract:start -->", 1)[1].split(
                "<!-- verification-contract:end -->", 1
            )[0]
            rows = [line for line in contract.splitlines() if line.strip().startswith("|")][2:]
            for line in rows:
                cells = [cell.strip() for cell in line.strip().strip("|").split("|")]
                if len(cells) == 8 and cells[1] == "judgment" and cells[6] in {"pending", "blocked"}:
                    pending_judgment = True
                    break
        if checkpointed and explicitly_uses_workbench and pending_judgment:
            owners.append(plan.relative_to(ROOT))
    return owners


def check_references(errors: list[str], notices: list[str] | None = None) -> None:
    design_root = ROOT / "docs/design"
    references = design_root / "references"
    manifest_path = references / "manifest.json"
    if not manifest_path.is_file():
        error(errors, "missing docs/design/references/manifest.json")
        return
    try:
        manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
    except json.JSONDecodeError as exc:
        error(errors, f"invalid reference manifest: {exc}")
        return

    max_file = manifest.get("max_file_bytes")
    max_total = manifest.get("max_total_bytes")
    artifacts = manifest.get("artifacts")
    if not isinstance(max_file, int) or not isinstance(max_total, int) or not isinstance(artifacts, list):
        error(errors, "reference manifest budgets/artifacts are malformed")
        return
    if max_file != REFERENCE_MAX_FILE_BYTES or max_total != REFERENCE_MAX_TOTAL_BYTES:
        error(errors, "reference manifest must preserve the fixed 1 MB per-file and 10 MB aggregate budgets")

    declared: set[Path] = set()
    purposes: set[str] = set()
    total = 0
    for item in artifacts:
        required = {"path", "purpose", "owner_doc", "approved_by", "approved_on", "source_task", "sha256", "size_bytes", "status"}
        if not isinstance(item, dict) or not required.issubset(item):
            error(errors, f"reference manifest item lacks required fields: {item!r}")
            continue
        if item["approved_by"] != "user" or item["status"] != "current":
            error(errors, f"reference is not explicitly user-approved/current: {item['path']}")
        purpose = item["purpose"]
        if purpose in purposes:
            error(errors, f"duplicate durable-reference purpose: {purpose}")
        purposes.add(purpose)
        raw_path = Path(item["path"])
        if raw_path.is_absolute() or ".." in raw_path.parts:
            error(errors, f"reference path must be repository-relative: {item['path']}")
            continue
        path = (ROOT / raw_path).resolve()
        if not path.is_relative_to(references.resolve()):
            error(errors, f"reference must live under docs/design/references: {item['path']}")
            continue
        declared.add(path)
        if not path.is_file():
            error(errors, f"declared reference is missing: {item['path']}")
            continue
        owner_raw = Path(item["owner_doc"])
        owner = (ROOT / owner_raw).resolve()
        owner_is_current = (
            not owner_raw.is_absolute()
            and ".." not in owner_raw.parts
            and owner.is_relative_to(ROOT.resolve())
            and owner.suffix == ".md"
            and "completed" not in owner_raw.parts
            and "audits" not in owner_raw.parts
        )
        owner_targets: set[Path] = set()
        if owner_is_current and owner.is_file():
            for target in LINK.findall(owner.read_text(encoding="utf-8", errors="replace")):
                target = target.split("#", 1)[0].strip("<>")
                if target and not target.startswith(("http://", "https://", "mailto:", "#")):
                    owner_targets.add((owner.parent / target).resolve())
        if not owner_is_current or not owner.is_file() or path not in owner_targets:
            error(errors, f"reference owner does not link artifact: {item['path']}")
        size = path.stat().st_size
        total += size
        if size != item["size_bytes"] or size > max_file:
            error(errors, f"reference size mismatch or budget violation: {item['path']}")
        digest = hashlib.sha256(path.read_bytes()).hexdigest()
        if digest != item["sha256"]:
            error(errors, f"reference hash mismatch: {item['path']}")
    if total > max_total:
        error(errors, f"durable references exceed aggregate budget: {total} > {max_total}")

    actual = {
        path.resolve()
        for path in references.rglob("*")
        if path.is_file() and path != manifest_path and path.suffix.lower() in BINARY_SUFFIXES
    }
    for path in sorted(actual - declared):
        error(errors, f"unmanifested durable binary: {path.relative_to(ROOT)}")

    workbench_root = design_root / "workbench"
    workbench_owners = active_workbench_owners()
    workbench_files: list[Path] = []
    for path in design_root.rglob("*"):
        if not path.is_file() or references in path.parents:
            continue
        if workbench_root in path.parents:
            if workbench_owners:
                workbench_files.append(path.relative_to(ROOT))
            else:
                error(errors, f"unowned design workbench residue: {path.relative_to(ROOT)}")
            continue
        if path.suffix.lower() in BINARY_SUFFIXES:
            error(errors, f"design binary must live in approved references or production assets: {path.relative_to(ROOT)}")

    if workbench_files and notices is not None:
        owners = ", ".join(str(path) for path in workbench_owners)
        notices.append(
            f"{len(workbench_files)} ignored design workbench files are owned by active checkpoint: {owners}"
        )


def main() -> int:
    errors: list[str] = []
    notices: list[str] = []
    check_contracts(errors, notices)
    check_imports(errors)
    check_links(errors)
    check_references(errors, notices)
    if errors:
        print("Harness audit failed:", file=sys.stderr)
        for item in errors:
            print(f"- {item}", file=sys.stderr)
        return 1
    if notices:
        print("Harness audit notices (expected for in-progress plans):")
        for item in notices:
            print(f"- {item}")
    print(
        "Harness audit passed: active-plan schema/profiles, current-doc links and status boundaries, "
        "selected mechanical architecture checks, workbench ownership, and design-reference admission/budgets passed. "
        "Selected-plan completion and semantic ownership remain separate hard gates."
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
