#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

find "$ROOT_DIR" -type d \( -name "*.xcodeproj" -o -name "*.xcworkspace" \) -prune -exec rm -rf {} +
rm -rf "$ROOT_DIR/DerivedData"
