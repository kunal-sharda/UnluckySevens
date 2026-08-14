#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
PROFILE="${1:-iphone}"
RUN_STAMP="$(date -u +%Y%m%dT%H%M%SZ)"
DERIVED_DATA_PATH="${UI_SCREENSHOT_DERIVED_DATA:-$ROOT_DIR/DerivedData/UIScreenshotHarness/$RUN_STAMP}"
RESULT_ROOT="${UI_SCREENSHOT_RESULT_ROOT:-$ROOT_DIR/output/ui-screenshot-harness/$RUN_STAMP-$PROFILE}"

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

CATALOG="${UI_SCREENSHOT_CATALOG:-$CATALOG}"
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

mkdir -p "$DERIVED_DATA_PATH" "$RESULT_ROOT/results" "$RESULT_ROOT/attachments" "$RESULT_ROOT/stills"

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

  printf 'running=%s\n' "$TEST_NAME" | tee -a "$RESULT_ROOT/run-manifest.txt"
  xcodebuild \
    test-without-building \
    -xctestrun "$XCTESTRUN_PATH" \
    -destination "id=$DEVICE_ID" \
    -only-testing:"UnluckySevensUITests/MessagesExtensionDesignSliceUITests/$TEST_NAME" \
    -resultBundlePath "$RESULT_PATH" \
    -quiet

  mkdir -p "$ATTACHMENT_PATH"
  xcrun xcresulttool export attachments \
    --path "$RESULT_PATH" \
    --output-path "$ATTACHMENT_PATH"
  xcrun simctl io "$DEVICE_ID" screenshot "$RESULT_ROOT/stills/$TEST_NAME.png"
  printf 'passed=%s\n' "$TEST_NAME" | tee -a "$RESULT_ROOT/run-manifest.txt"
done < "$CATALOG"

printf 'finished_at_utc=%s\n' "$(date -u +%Y%m%dT%H%M%SZ)" >> "$RESULT_ROOT/run-manifest.txt"
printf 'UI screenshot catalog passed: %s\n' "$RESULT_ROOT"
