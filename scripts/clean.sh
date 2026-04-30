#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DEEP_CLEAN=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --deep)
      DEEP_CLEAN=1
      shift
      ;;
    --help|-h)
      cat <<'EOF'
Usage: bash ./scripts/clean.sh [--deep]

Removes generated Xcode files and local DerivedData.

Options:
  --deep    Also remove SwiftPM package .build directories.
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

find "$ROOT_DIR" -type d \( -name "*.xcodeproj" -o -name "*.xcworkspace" \) -prune -exec rm -rf {} +
rm -rf "$ROOT_DIR/DerivedData"

if (( DEEP_CLEAN > 0 )); then
  find "$ROOT_DIR/Packages" -type d -name ".build" -prune -exec rm -rf {} +
fi
