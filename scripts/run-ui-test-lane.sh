#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
MODE="${1:-quick}"
FEATURE="${2:-smoke}"

run_gameplay_catalog() {
  local catalog="$1"
  UI_GAMEPLAY_ACTION_CATALOG="$ROOT_DIR/scripts/$catalog" \
    bash "$ROOT_DIR/scripts/run-ui-gameplay-action-catalog.sh"
}

run_visual_catalog() {
  local catalog="$1"
  UI_SCREENSHOT_CATALOG="$ROOT_DIR/scripts/$catalog" \
    bash "$ROOT_DIR/scripts/run-ui-screenshot-catalog.sh" iphone
}

print_features() {
  cat <<'EOF'
Quick UI features:
  smoke       Roll, end turn, and a bank/port trade
  trade       Bank/port trade, player offer, and acceptance
  build       Setup placement plus road, settlement, and city builds
  robber      Seven/discard, robber move, and victim selection
  dev-cards   Purchase plus all four playable Development Cards
  guardrails  Cancellation, decline, and waiting-player protections
  recovery    Relaunch, archive/restore, resignation, and recovered games
  match       Setup and production-wired victory bookends
  tutorial    Every tutorial screen
  trade-previews  Tutorial, pending-strip, incoming, and outgoing Trade visuals
  host        Stable Messages-host layout checkpoints
  roll        Roll Dice affordance visual
  gameplay    Every production-control gameplay action
EOF
}

case "$MODE" in
  list)
    print_features
    ;;
  quick)
    case "$FEATURE" in
      smoke) run_gameplay_catalog "ui-gameplay-quick-smoke-catalog-iphone.txt" ;;
      trade) run_gameplay_catalog "ui-gameplay-quick-trade-catalog-iphone.txt" ;;
      build) run_gameplay_catalog "ui-gameplay-quick-build-catalog-iphone.txt" ;;
      robber) run_gameplay_catalog "ui-gameplay-quick-robber-catalog-iphone.txt" ;;
      dev-cards) run_gameplay_catalog "ui-gameplay-quick-dev-cards-catalog-iphone.txt" ;;
      guardrails) run_gameplay_catalog "ui-gameplay-guardrail-catalog-iphone.txt" ;;
      recovery) run_gameplay_catalog "ui-gameplay-recovery-catalog-iphone.txt" ;;
      match) run_gameplay_catalog "ui-gameplay-complete-match-catalog-iphone.txt" ;;
      tutorial) run_visual_catalog "ui-screenshot-catalog-tutorial.txt" ;;
      trade-previews) run_visual_catalog "ui-screenshot-catalog-trade-previews.txt" ;;
      host) run_visual_catalog "ui-screenshot-catalog-stable-host.txt" ;;
      roll) run_visual_catalog "ui-screenshot-catalog-roll.txt" ;;
      gameplay) run_gameplay_catalog "ui-gameplay-action-catalog-iphone.txt" ;;
      *)
        echo "Unknown quick feature: $FEATURE" >&2
        print_features >&2
        exit 2
        ;;
    esac
    ;;
  full)
    run_gameplay_catalog "ui-gameplay-action-catalog-iphone.txt"
    run_gameplay_catalog "ui-gameplay-guardrail-catalog-iphone.txt"
    run_gameplay_catalog "ui-gameplay-recovery-catalog-iphone.txt"
    run_gameplay_catalog "ui-gameplay-complete-match-catalog-iphone.txt"
    run_visual_catalog "ui-screenshot-catalog-iphone.txt"
    ;;
  *)
    echo "Usage: $0 {quick [feature]|full|list}" >&2
    exit 2
    ;;
esac
