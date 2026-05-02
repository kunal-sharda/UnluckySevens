#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROJECT_FILE="$ROOT_DIR/UnluckySevens.xcodeproj/project.pbxproj"
TARGET_NAME="UnluckySevensApp"
NORMAL_PRODUCT_TYPE='productType = "com.apple.product-type.application";'
MESSAGES_PRODUCT_TYPE='productType = "com.apple.product-type.application.messages";'

if [[ ! -f "$PROJECT_FILE" ]]; then
  echo "error: generated project not found at $PROJECT_FILE" >&2
  echo "run 'bash ./scripts/gen.sh' first" >&2
  exit 1
fi

/usr/bin/python3 - "$PROJECT_FILE" "$TARGET_NAME" "$NORMAL_PRODUCT_TYPE" "$MESSAGES_PRODUCT_TYPE" <<'PY'
from __future__ import annotations

import re
import sys
from pathlib import Path

project_path = Path(sys.argv[1])
target_name = sys.argv[2]
normal_product_type = sys.argv[3]
messages_product_type = sys.argv[4]

contents = project_path.read_text()
target_pattern = re.compile(
    rf"(?P<body>[ \t]*[A-F0-9]+ /\* {re.escape(target_name)} \*/ = \{{"
    rf".*?name = {re.escape(target_name)};.*?"
    rf"productName = {re.escape(target_name)};.*?"
    rf"(?P<productType>[ \t]*productType = \"com\.apple\.product-type\.application(?:\.messages)?\";)"
    rf".*?[ \t]*\}};)",
    re.DOTALL,
)

match = target_pattern.search(contents)
if match is None:
    print(f"error: could not find native target '{target_name}' in generated project", file=sys.stderr)
    sys.exit(1)

target_body = match.group("body")
changed = False

if messages_product_type in target_body:
    print("standalone iMessage product type already applied")
elif normal_product_type in target_body:
    target_body = target_body.replace(normal_product_type, messages_product_type, 1)
    contents = contents[: match.start("body")] + target_body + contents[match.end("body") :]
    changed = True
    print("patched UnluckySevensApp to com.apple.product-type.application.messages")
else:
    print("error: app target product type was not the expected application/messages value", file=sys.stderr)
    sys.exit(1)

source_phase_id_match = re.search(r"([A-F0-9]+) /\* Sources \*/", target_body)
if source_phase_id_match is None:
    print("error: could not find app target source phase", file=sys.stderr)
    sys.exit(1)

source_phase_id = source_phase_id_match.group(1)
source_phase_pattern = re.compile(
    rf"(?P<body>[ \t]*{source_phase_id} /\* Sources \*/ = \{{"
    rf".*?files = \(\n"
    rf")(?P<files>.*?)"
    rf"(?P<tail>[ \t]*\);\n[ \t]*runOnlyForDeploymentPostprocessing = 0;\n[ \t]*\}};)",
    re.DOTALL,
)
source_phase_match = source_phase_pattern.search(contents)
if source_phase_match is None:
    print("error: could not find app target source phase body", file=sys.stderr)
    sys.exit(1)

source_files = source_phase_match.group("files")
if source_files.strip():
    contents = (
        contents[: source_phase_match.start("files")]
        + ""
        + contents[source_phase_match.end("files") :]
    )
    changed = True
    print("removed generated app-target Swift sources for standalone Messages packaging")

if changed:
    project_path.write_text(contents)
PY
