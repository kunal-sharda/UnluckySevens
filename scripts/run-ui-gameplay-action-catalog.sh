#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
RUN_STAMP="$(date -u +%Y%m%dT%H%M%SZ)"

export UI_SCREENSHOT_CATALOG="${UI_GAMEPLAY_ACTION_CATALOG:-$ROOT_DIR/scripts/ui-gameplay-action-catalog-iphone.txt}"
export UI_SCREENSHOT_RESULT_ROOT="${UI_GAMEPLAY_ACTION_RESULT_ROOT:-$ROOT_DIR/output/ui-gameplay-action-harness/$RUN_STAMP-iphone}"
export UI_SCREENSHOT_DERIVED_DATA="${UI_GAMEPLAY_ACTION_DERIVED_DATA:-$ROOT_DIR/DerivedData/UIGameplayActionHarness/$RUN_STAMP}"
export UI_SCREENSHOT_RECORD_VIDEO="${UI_GAMEPLAY_ACTION_RECORD_VIDEO:-1}"

exec bash "$ROOT_DIR/scripts/run-ui-screenshot-catalog.sh" iphone
