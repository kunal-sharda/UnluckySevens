#!/usr/bin/env bash
set -euo pipefail

OPEN_XCODE=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --open)
      OPEN_XCODE=1
      shift
      ;;
    --help|-h)
      cat <<'EOF'
Usage: bash ./scripts/gen.sh [--open]

Generates the Tuist workspace and project files.

Options:
  --open    Open Xcode after generation.
  --help    Show this help text.
EOF
      exit 0
      ;;
    *)
      echo "error: unknown argument '$1'" >&2
      exit 1
      ;;
  esac
done

if (( OPEN_XCODE > 0 )); then
  tuist generate
else
  tuist generate --no-open
fi

bash "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/scripts/patch-standalone-imessage-project.sh"
