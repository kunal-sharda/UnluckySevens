#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WORKSPACE_PATH="$ROOT_DIR/UnluckySevens.xcworkspace"
DERIVED_DATA_PATH="$ROOT_DIR/DerivedData/DevicePipeline"
LOCAL_SIGNING_XCCONFIG="$ROOT_DIR/Config/LocalSigning.xcconfig"
SCHEME="UnluckySevensApp"
CONFIGURATION="Debug"
RUN_CLEAN=0
RUN_GEN=1
SHOULD_LAUNCH=0
ALLOW_PROVISIONING_UPDATES=0
DISCOVERY_TIMEOUT=8
DEVICE_IDS=()
TEAM_ID=""

usage() {
  cat <<'EOF'
Usage: bash ./scripts/install-connected-devices.sh [options]

Builds the standalone iMessage app bundle for generic iOS and installs it onto every
connected iPhone/iPad. Open it from the Messages app drawer after install.

Options:
  --debug                        Build/install the Debug configuration. Default.
  --release                      Build/install the Release configuration.
  --clean                        Remove generated Xcode files and DerivedData first.
  --skip-gen                     Skip workspace generation.
  --launch                       Ignored for standalone iMessage apps.
  --no-launch                    Install only; do not launch the app after install.
  --allow-provisioning-updates   Pass -allowProvisioningUpdates to xcodebuild.
  --team <team-id>               Override DEVELOPMENT_TEAM for this build.
  --device <udid>                Install only to the specified device. Repeatable.
  --timeout <seconds>            Device discovery timeout for xcdevice list. Default: 8.
  --help                         Show this help.
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --debug)
      CONFIGURATION="Debug"
      shift
      ;;
    --release)
      CONFIGURATION="Release"
      shift
      ;;
    --clean)
      RUN_CLEAN=1
      shift
      ;;
    --skip-gen)
      RUN_GEN=0
      shift
      ;;
    --no-launch)
      SHOULD_LAUNCH=0
      shift
      ;;
    --launch)
      SHOULD_LAUNCH=1
      shift
      ;;
    --allow-provisioning-updates)
      ALLOW_PROVISIONING_UPDATES=1
      shift
      ;;
    --team)
      if [[ $# -lt 2 ]]; then
        echo "error: --team requires a value" >&2
        exit 1
      fi
      TEAM_ID="$2"
      shift 2
      ;;
    --device)
      if [[ $# -lt 2 ]]; then
        echo "error: --device requires a UDID or device identifier" >&2
        exit 1
      fi
      DEVICE_IDS+=("$2")
      shift 2
      ;;
    --timeout)
      if [[ $# -lt 2 ]]; then
        echo "error: --timeout requires a value" >&2
        exit 1
      fi
      DISCOVERY_TIMEOUT="$2"
      shift 2
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    *)
      echo "error: unknown argument '$1'" >&2
      usage >&2
      exit 1
      ;;
  esac
done

if [[ ! "$DISCOVERY_TIMEOUT" =~ ^[0-9]+$ ]]; then
  echo "error: --timeout must be a non-negative integer" >&2
  exit 1
fi

resolve_team_id() {
  if [[ -n "$TEAM_ID" ]]; then
    printf '%s\n' "$TEAM_ID"
    return 0
  fi

  if [[ ! -f "$LOCAL_SIGNING_XCCONFIG" ]]; then
    echo "error: local signing file not found at $LOCAL_SIGNING_XCCONFIG" >&2
    echo "create it locally and set DEVELOPMENT_TEAM before installing to devices" >&2
    exit 1
  fi

  local resolved
  resolved="$(sed -nE 's/^[[:space:]]*DEVELOPMENT_TEAM[[:space:]]*=[[:space:]]*([A-Z0-9]+)[[:space:]]*$/\1/p' "$LOCAL_SIGNING_XCCONFIG" | head -n 1)"

  if [[ -z "$resolved" ]]; then
    echo "error: DEVELOPMENT_TEAM is not set in $LOCAL_SIGNING_XCCONFIG" >&2
    echo "uncomment the DEVELOPMENT_TEAM line and set your real Apple Team ID, or pass --team <TEAMID>" >&2
    exit 1
  fi

  printf '%s\n' "$resolved"
}

TEAM_ID="$(resolve_team_id)"

if (( SHOULD_LAUNCH > 0 )); then
  echo "warning: standalone iMessage apps cannot be launched directly; ignoring --launch" >&2
  SHOULD_LAUNCH=0
fi

if (( RUN_CLEAN > 0 )); then
  bash "$ROOT_DIR/scripts/clean.sh"
fi

if (( RUN_GEN > 0 )); then
  bash "$ROOT_DIR/scripts/gen.sh"
fi

if [[ ! -d "$WORKSPACE_PATH" ]]; then
  echo "error: workspace not found at $WORKSPACE_PATH" >&2
  echo "run 'bash ./scripts/gen.sh' first or omit --skip-gen" >&2
  exit 1
fi

discover_connected_devices() {
  /usr/bin/python3 - "$1" <<'PY'
import json
import subprocess
import sys

timeout = sys.argv[1]
try:
    raw = subprocess.check_output(
        ["xcrun", "xcdevice", "list", f"--timeout={timeout}"],
        text=True,
        stderr=subprocess.DEVNULL,
    )
except subprocess.CalledProcessError as exc:
    print(f"error: failed to enumerate connected devices via xcdevice ({exc.returncode})", file=sys.stderr)
    sys.exit(1)

try:
    devices = json.loads(raw)
except json.JSONDecodeError:
    print("error: xcdevice output was not valid JSON; cannot auto-discover devices", file=sys.stderr)
    sys.exit(1)

eligible = []
for device in devices:
    if not isinstance(device, dict):
        continue
    if not device.get("available", False):
        continue
    if device.get("simulator", False):
        continue
    if device.get("platform") != "com.apple.platform.iphoneos":
        continue
    identifier = device.get("identifier")
    if not identifier:
        continue
    eligible.append(identifier)

for identifier in eligible:
    print(identifier)
PY
}

if (( ${#DEVICE_IDS[@]} == 0 )); then
  while IFS= read -r identifier; do
    [[ -n "$identifier" ]] && DEVICE_IDS+=("$identifier")
  done < <(discover_connected_devices "$DISCOVERY_TIMEOUT")
fi

if (( ${#DEVICE_IDS[@]} == 0 )); then
  echo "error: no connected iPhone/iPad devices found" >&2
  exit 1
fi

echo "==> Building standalone iMessage app bundle $SCHEME ($CONFIGURATION) for generic iOS"
BUILD_CMD=(
  xcodebuild
  -workspace "$WORKSPACE_PATH"
  -scheme "$SCHEME"
  -configuration "$CONFIGURATION"
  -destination "generic/platform=iOS"
  -derivedDataPath "$DERIVED_DATA_PATH"
  "DEVELOPMENT_TEAM=$TEAM_ID"
  "CODE_SIGN_STYLE=Automatic"
  build
)

if (( ALLOW_PROVISIONING_UPDATES > 0 )); then
  BUILD_CMD+=(-allowProvisioningUpdates)
fi

"${BUILD_CMD[@]}"

APP_PATH="$DERIVED_DATA_PATH/Build/Products/${CONFIGURATION}-iphoneos/${SCHEME}.app"

if [[ ! -d "$APP_PATH" ]]; then
  echo "error: built app not found at $APP_PATH" >&2
  exit 1
fi

for device_id in "${DEVICE_IDS[@]}"; do
  echo "==> Installing on $device_id"
  xcrun devicectl device install app --device "$device_id" "$APP_PATH"
done

echo "==> Done"
echo "==> Open Messages and select Unlucky Sevens from the app drawer on each device"
