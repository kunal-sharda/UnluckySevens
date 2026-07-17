#!/usr/bin/env bash
set -euo pipefail

while [[ $# -gt 0 ]]; do
  case "$1" in
    --help|-h)
      cat <<'EOF'
Usage: bash ./scripts/gen.sh

Generates the Tuist workspace and project files without opening Xcode, then
patches the generated project for standalone Messages packaging.
EOF
      exit 0
      ;;
    *)
      echo "error: unknown argument '$1'" >&2
      exit 1
      ;;
  esac
done

tuist generate --no-open
bash "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/scripts/patch-standalone-imessage-project.sh"
