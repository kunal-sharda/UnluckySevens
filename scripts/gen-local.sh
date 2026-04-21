#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WORKSPACE_PATH="$ROOT_DIR/UnluckySevens.xcworkspace"
OPEN_XCODE_INSTANCES=2
RUN_CLEAN=0
OPEN_XCODE=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --clean)
      RUN_CLEAN=1
      shift
      ;;
    --open)
      OPEN_XCODE=1
      shift
      ;;
    --no-open)
      OPEN_XCODE=0
      shift
      ;;
    --instances)
      if [[ $# -lt 2 ]]; then
        echo "error: --instances requires a value" >&2
        exit 1
      fi
      OPEN_XCODE_INSTANCES="$2"
      shift 2
      ;;
    *)
      echo "error: unknown argument '$1'" >&2
      exit 1
      ;;
  esac
done

if [[ ! "$OPEN_XCODE_INSTANCES" =~ ^[0-9]+$ ]]; then
  echo "error: --instances must be a non-negative integer" >&2
  exit 1
fi

if (( RUN_CLEAN > 0 )); then
  bash "$ROOT_DIR/scripts/clean.sh"
fi

bash "$ROOT_DIR/scripts/gen.sh"

if (( OPEN_XCODE == 0 || OPEN_XCODE_INSTANCES == 0 )); then
  exit 0
fi

for ((instance = 1; instance <= OPEN_XCODE_INSTANCES; instance++)); do
  open -na Xcode "$WORKSPACE_PATH"
done
