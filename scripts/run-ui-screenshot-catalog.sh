#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
PROFILE="${1:-iphone}"
CATALOG_ARGUMENT="${2:-}"
ATTEMPT_ARGUMENT="${3:-}"
DIAGNOSIS_ARGUMENT="${4:-}"
CORRECTION_ARGUMENT="${5:-}"
RUN_STAMP="$(date -u +%Y%m%dT%H%M%SZ)"
DERIVED_DATA_PATH="${UI_SCREENSHOT_DERIVED_DATA:-$ROOT_DIR/DerivedData/UIScreenshotHarness/$RUN_STAMP}"
RESULT_ROOT="${UI_SCREENSHOT_RESULT_ROOT:-$ROOT_DIR/output/ui-screenshot-harness/$RUN_STAMP-$PROFILE}"
MAX_FOCUSED_RERUNS="${UI_SCREENSHOT_MAX_FOCUSED_RERUNS:-10}"
ATTEMPT_NUMBER="${ATTEMPT_ARGUMENT:-${UI_SCREENSHOT_ATTEMPT_NUMBER:-1}}"
RETRY_DIAGNOSIS="${DIAGNOSIS_ARGUMENT:-${UI_SCREENSHOT_RETRY_DIAGNOSIS:-}}"
RETRY_CORRECTION="${CORRECTION_ARGUMENT:-${UI_SCREENSHOT_RETRY_CORRECTION:-}}"
CONTENT_SIZE="${UI_SCREENSHOT_CONTENT_SIZE:-}"
ORIGINAL_CONTENT_SIZE=""

restore_content_size() {
  if [[ -n "$ORIGINAL_CONTENT_SIZE" && -n "${DEVICE_ID:-}" ]]; then
    xcrun simctl ui "$DEVICE_ID" content_size "$ORIGINAL_CONTENT_SIZE" >/dev/null 2>&1 || true
  fi
}

trap restore_content_size EXIT

if ! [[ "$MAX_FOCUSED_RERUNS" =~ ^[0-9]+$ && "$ATTEMPT_NUMBER" =~ ^[0-9]+$ ]]; then
  echo "Retry limits and attempt numbers must be nonnegative integers." >&2
  exit 64
fi
MAX_ATTEMPTS=$((MAX_FOCUSED_RERUNS + 1))
if (( ATTEMPT_NUMBER < 1 || ATTEMPT_NUMBER > MAX_ATTEMPTS )); then
  echo "Attempt $ATTEMPT_NUMBER exceeds the initial plus $MAX_FOCUSED_RERUNS focused-rerun ceiling." >&2
  exit 64
fi
if (( ATTEMPT_NUMBER > 1 )) && { [[ -z "$RETRY_DIAGNOSIS" ]] || [[ -z "$RETRY_CORRECTION" ]]; }; then
  echo "Attempt $ATTEMPT_NUMBER requires UI_SCREENSHOT_RETRY_DIAGNOSIS and UI_SCREENSHOT_RETRY_CORRECTION." >&2
  exit 64
fi

case "$PROFILE" in
  iphone)
    DEVICE_NAME="${UI_SCREENSHOT_DEVICE_NAME:-iPhone 17}"
    CATALOG="$ROOT_DIR/scripts/ui-screenshot-catalog-iphone.txt"
    ;;
  ipad)
    DEVICE_NAME="${UI_SCREENSHOT_DEVICE_NAME:-iPad Air 11-inch (M4)}"
    CATALOG="$ROOT_DIR/scripts/ui-screenshot-catalog-ipad.txt"
    ;;
  *)
    echo "Usage: $0 [iphone|ipad]" >&2
    exit 64
    ;;
esac

CATALOG="${CATALOG_ARGUMENT:-${UI_SCREENSHOT_CATALOG:-$CATALOG}}"
if [[ ! -f "$CATALOG" ]]; then
  echo "Screenshot catalog not found: $CATALOG" >&2
  exit 66
fi

if [[ -n "${UI_SCREENSHOT_DEVICE_ID:-}" ]]; then
  DEVICE_ID="$UI_SCREENSHOT_DEVICE_ID"
else
  DEVICE_ID="$(
    xcrun simctl list devices available |
      sed -n "s/^[[:space:]]*$DEVICE_NAME (\([0-9A-F-]*\)).*$/\1/p" |
      head -n 1
  )"
fi

if [[ -z "$DEVICE_ID" ]]; then
  echo "No available simulator matched: $DEVICE_NAME" >&2
  exit 69
fi

mkdir -p \
  "$DERIVED_DATA_PATH" \
  "$RESULT_ROOT/results" \
  "$RESULT_ROOT/attachments" \
  "$RESULT_ROOT/stills" \
  "$RESULT_ROOT/logs" \
  "$RESULT_ROOT/failures"
if [[ "${UI_SCREENSHOT_RECORD_VIDEO:-0}" == "1" ]]; then
  mkdir -p "$RESULT_ROOT/videos"
fi

cd "$ROOT_DIR"
bash ./scripts/gen.sh

xcodebuild \
  -workspace UnluckySevens.xcworkspace \
  -scheme UnluckySevens \
  -destination "id=$DEVICE_ID" \
  -derivedDataPath "$DERIVED_DATA_PATH" \
  build-for-testing \
  -quiet

APP_PATH="$DERIVED_DATA_PATH/Build/Products/Debug-iphonesimulator/UnluckySevensApp.app"
XCTESTRUN_PATH="$(find "$DERIVED_DATA_PATH/Build/Products" -name '*.xctestrun' -print -quit)"
if [[ ! -d "$APP_PATH" || -z "$XCTESTRUN_PATH" ]]; then
  echo "Expected app or xctestrun was not produced in $DERIVED_DATA_PATH" >&2
  exit 66
fi

xcrun simctl shutdown all >/dev/null 2>&1 || true
xcrun simctl boot "$DEVICE_ID"
xcrun simctl bootstatus "$DEVICE_ID" -b
if [[ -n "$CONTENT_SIZE" ]]; then
  ORIGINAL_CONTENT_SIZE="$(xcrun simctl ui "$DEVICE_ID" content_size)"
  xcrun simctl ui "$DEVICE_ID" content_size "$CONTENT_SIZE"
fi
xcrun simctl uninstall "$DEVICE_ID" com.unluckysevens.app >/dev/null 2>&1 || true
xcrun simctl install "$DEVICE_ID" "$APP_PATH"
xcrun simctl terminate "$DEVICE_ID" com.apple.MobileSMS >/dev/null 2>&1 || true
xcrun simctl launch "$DEVICE_ID" com.apple.MobileSMS >/dev/null
sleep 2
xcrun simctl terminate "$DEVICE_ID" com.apple.MobileSMS >/dev/null 2>&1 || true
INSTALLED_APP_PATH="$(xcrun simctl get_app_container "$DEVICE_ID" com.unluckysevens.app app)"
BUILT_EXTENSION="$APP_PATH/PlugIns/MessagesExtension.appex/MessagesExtension"
INSTALLED_EXTENSION="$INSTALLED_APP_PATH/PlugIns/MessagesExtension.appex/MessagesExtension"
BUILT_HASH="$(shasum -a 256 "$BUILT_EXTENSION" | awk '{print $1}')"
INSTALLED_HASH="$(shasum -a 256 "$INSTALLED_EXTENSION" | awk '{print $1}')"
if [[ "$BUILT_HASH" != "$INSTALLED_HASH" ]]; then
  echo "Installed extension hash does not match the built extension." >&2
  exit 65
fi

{
  printf 'profile=%s\n' "$PROFILE"
  printf 'device_name=%s\n' "$DEVICE_NAME"
  printf 'device_id=%s\n' "$DEVICE_ID"
  printf 'derived_data=%s\n' "$DERIVED_DATA_PATH"
  printf 'xctestrun=%s\n' "$XCTESTRUN_PATH"
  printf 'catalog=%s\n' "$CATALOG"
  printf 'built_extension_sha256=%s\n' "$BUILT_HASH"
  printf 'installed_extension_sha256=%s\n' "$INSTALLED_HASH"
  printf 'started_at_utc=%s\n' "$RUN_STAMP"
  printf 'simulator_reset=shutdown-all,boot-target,uninstall-app,install-fresh,restart-messages\n'
  printf 'retry_policy=diagnostic-first\n'
  printf 'max_focused_reruns=%s\n' "$MAX_FOCUSED_RERUNS"
  printf 'attempt_number=%s\n' "$ATTEMPT_NUMBER"
  if [[ -n "$CONTENT_SIZE" ]]; then
    printf 'content_size=%s\n' "$CONTENT_SIZE"
    printf 'restored_content_size=%s\n' "$ORIGINAL_CONTENT_SIZE"
  fi
  if (( ATTEMPT_NUMBER > 1 )); then
    printf 'retry_diagnosis=%s\n' "${RETRY_DIAGNOSIS//$'\n'/ }"
    printf 'retry_correction=%s\n' "${RETRY_CORRECTION//$'\n'/ }"
  fi
} > "$RESULT_ROOT/run-manifest.txt"

START_AT="${UI_SCREENSHOT_START_AT:-}"
HAS_STARTED=0
[[ -z "$START_AT" ]] && HAS_STARTED=1

while IFS= read -r TEST_NAME; do
  [[ -z "$TEST_NAME" || "$TEST_NAME" == \#* ]] && continue
  if [[ "$HAS_STARTED" -eq 0 ]]; then
    [[ "$TEST_NAME" == "$START_AT" ]] || continue
    HAS_STARTED=1
  fi
  RESULT_PATH="$RESULT_ROOT/results/$TEST_NAME.xcresult"
  ATTACHMENT_PATH="$RESULT_ROOT/attachments/$TEST_NAME"
  TEST_LOG="$RESULT_ROOT/logs/$TEST_NAME.log"
  FAILURE_PATH="$RESULT_ROOT/failures/$TEST_NAME"

  printf 'running=%s\n' "$TEST_NAME" | tee -a "$RESULT_ROOT/run-manifest.txt"
  VIDEO_PID=""
  if [[ "${UI_SCREENSHOT_RECORD_VIDEO:-0}" == "1" ]]; then
    xcrun simctl io "$DEVICE_ID" recordVideo \
      --codec=h264 \
      "$RESULT_ROOT/videos/$TEST_NAME.mp4" \
      >/dev/null 2>&1 &
    VIDEO_PID="$!"
    sleep 1
  fi

  set +e
  xcodebuild \
    test-without-building \
    -xctestrun "$XCTESTRUN_PATH" \
    -destination "id=$DEVICE_ID" \
    -only-testing:"UnluckySevensUITests/MessagesExtensionDesignSliceUITests/$TEST_NAME" \
    -resultBundlePath "$RESULT_PATH" \
    -quiet \
    2>&1 | tee "$TEST_LOG"
  TEST_STATUS="${PIPESTATUS[0]}"
  set -e

  if [[ -n "$VIDEO_PID" ]]; then
    kill -INT "$VIDEO_PID" >/dev/null 2>&1 || true
    wait "$VIDEO_PID" >/dev/null 2>&1 || true
  fi

  if [[ "$TEST_STATUS" -ne 0 ]]; then
    mkdir -p "$FAILURE_PATH"
    xcrun xcresulttool export attachments \
      --path "$RESULT_PATH" \
      --output-path "$FAILURE_PATH/attachments" \
      >"$FAILURE_PATH/attachment-export.log" 2>&1 || true
    xcrun xcresulttool get test-results summary \
      --path "$RESULT_PATH" \
      >"$FAILURE_PATH/test-summary.json" 2>"$FAILURE_PATH/test-summary-error.log" || true
    xcrun xcresulttool get test-results tests \
      --path "$RESULT_PATH" \
      >"$FAILURE_PATH/test-details.json" 2>"$FAILURE_PATH/test-details-error.log" || true
    xcrun simctl io "$DEVICE_ID" screenshot "$FAILURE_PATH/simulator.png" >/dev/null 2>&1 || true
    {
      printf 'failed=%s\n' "$TEST_NAME"
      printf 'failure_attempt=%s\n' "$ATTEMPT_NUMBER"
      printf 'failure_diagnostics=%s\n' "$FAILURE_PATH"
    } >> "$RESULT_ROOT/run-manifest.txt"
    exit "$TEST_STATUS"
  fi

  mkdir -p "$ATTACHMENT_PATH"
  xcrun xcresulttool export attachments \
    --path "$RESULT_PATH" \
    --output-path "$ATTACHMENT_PATH"
  HOST_DIAGNOSTIC_FILE="$(
    jq -r \
      '.[].attachments[]? | select(.suggestedHumanReadableName | contains("Host Layout Diagnostics")) | .exportedFileName' \
      "$ATTACHMENT_PATH/manifest.json" |
      head -n 1
  )"
  if [[ -n "$HOST_DIAGNOSTIC_FILE" && -f "$ATTACHMENT_PATH/$HOST_DIAGNOSTIC_FILE" ]]; then
    HOST_DIAGNOSTIC_VALUE="$(tr '\n' ' ' < "$ATTACHMENT_PATH/$HOST_DIAGNOSTIC_FILE")"
    printf 'host_layout.%s=%s\n' "$TEST_NAME" "$HOST_DIAGNOSTIC_VALUE" \
      >> "$RESULT_ROOT/run-manifest.txt"
  fi
  xcrun simctl io "$DEVICE_ID" screenshot "$RESULT_ROOT/stills/$TEST_NAME.png"
  printf 'passed=%s\n' "$TEST_NAME" | tee -a "$RESULT_ROOT/run-manifest.txt"
done < "$CATALOG"

printf 'finished_at_utc=%s\n' "$(date -u +%Y%m%dT%H%M%SZ)" >> "$RESULT_ROOT/run-manifest.txt"
printf 'UI screenshot catalog passed: %s\n' "$RESULT_ROOT"
