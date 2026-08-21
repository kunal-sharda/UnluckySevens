#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BASE_REF="HEAD"
ALLOW_NO_DOCS=0
MAX_LIST=40

usage() {
  cat <<'EOF'
Usage: bash ./scripts/check-doc-freshness.sh [--base <ref>] [--allow-no-docs]

Classifies changed files against the repo's documentation freshness tiers.

The check is intentionally conservative: it cannot prove the docs are correct,
but it makes the affected owner-doc review explicit before work is finalized.

Options:
  --base <ref>      Compare tracked changes against <ref>. Default: HEAD.
  --allow-no-docs  Exit 0 even when source/design changes have no Tier 1/2 doc changes.
  --help, -h       Show this help text.
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --base)
      BASE_REF="${2:-}"
      if [[ -z "$BASE_REF" ]]; then
        echo "error: --base requires a ref" >&2
        exit 2
      fi
      shift 2
      ;;
    --allow-no-docs)
      ALLOW_NO_DOCS=1
      shift
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    *)
      echo "error: unknown argument '$1'" >&2
      usage >&2
      exit 2
      ;;
  esac
done

cd "$ROOT_DIR"

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "error: not inside a git work tree" >&2
  exit 2
fi

changed_file="$(mktemp "${TMPDIR:-/tmp}/uls-doc-freshness.XXXXXX")"
trap 'rm -f "$changed_file"' EXIT

{
  git diff --name-only "$BASE_REF" --
  git ls-files --others --exclude-standard
} | sed '/^$/d' | sort -u > "$changed_file"

total_count="$(wc -l < "$changed_file" | tr -d ' ')"

count_matching() {
  local pattern="$1"
  local count
  count="$(grep -E "$pattern" "$changed_file" | wc -l | tr -d ' ' || true)"
  echo "$count"
}

list_matching() {
  local pattern="$1"
  grep -E "$pattern" "$changed_file" | head -n "$MAX_LIST" || true
}

tier1_pattern='^(README\.md|PRODUCT\.md|DESIGN\.md|ARCHITECTURE\.md|docs/decisions\.md|docs/product-specs/(mvp-contract|ui-flows)\.md|docs/quality/(qa|constraint-verification|messages-host|ux-lab|device-runbooks)\.md)$'
tier2_pattern='^(docs/exec-plans/active/.*\.md|docs/design/(.*/)?README\.md)$'
tier3_pattern='^(docs/exec-plans/(roadmap|tech-debt-tracker|CHANGELOG)\.md)$'
tier4_pattern='^(docs/exec-plans/completed/.*\.md|docs/quality/audits/.*\.md|docs/design/.*/notes\.md|docs/product-specs/prd-verbatim\.md)$'

source_pattern='^((App|MessagesExtension|Packages|Tuist)(/|$)|Project\.swift$|Workspace\.swift$|Tuist\.swift$|scripts/|\.github/workflows/|Makefile$|Config/)'
workflow_pattern='^(scripts/|\.github/workflows/|Makefile$|Project\.swift$|Workspace\.swift$|Tuist\.swift$|Tuist/)'
core_transport_pattern='^(Packages/ULS_(CoreGame|Transport)/|MessagesExtension/Sources/Presentation/Transcript|MessagesExtension/Sources/.*Transport)'
ui_pattern='^(MessagesExtension/Sources/|MessagesExtension/Resources/)'
design_pattern='^docs/design/'
product_pattern='^(MessagesExtension/Sources/|docs/product-specs/)'

tier1_count="$(count_matching "$tier1_pattern")"
tier2_count="$(count_matching "$tier2_pattern")"
tier3_count="$(count_matching "$tier3_pattern")"
tier4_count="$(count_matching "$tier4_pattern")"

source_count="$(count_matching "$source_pattern")"
workflow_count="$(count_matching "$workflow_pattern")"
core_transport_count="$(count_matching "$core_transport_pattern")"
ui_count="$(count_matching "$ui_pattern")"
design_count="$(count_matching "$design_pattern")"
product_count="$(count_matching "$product_pattern")"

echo "Doc freshness check"
echo "Base ref: $BASE_REF"
echo "Changed files: $total_count"
echo

if [[ "$total_count" == "0" ]]; then
  echo "No changed files detected."
  exit 0
fi

echo "Changed current-doc tiers:"
echo "- Tier 1 owner docs: $tier1_count"
echo "- Tier 2 active/current-design docs: $tier2_count"
echo "- Tier 3 periodic summaries: $tier3_count"
echo "- Tier 4 historical/reference docs: $tier4_count"
echo

echo "Changed surface categories:"
echo "- source/build/workflow files: $source_count"
echo "- generation/CI/tooling files: $workflow_count"
echo "- core/transport/protocol-adjacent files: $core_transport_count"
echo "- UI/assets files: $ui_count"
echo "- design artifact files: $design_count"
echo

echo "Owner-doc review prompts:"
if (( workflow_count > 0 )); then
  echo "- Workflow/tooling changed: review README.md and docs/quality/qa.md."
fi
if (( core_transport_count > 0 )); then
  echo "- Core/transport/protocol-adjacent changes: review ARCHITECTURE.md, docs/decisions.md, and docs/quality/qa.md."
fi
if (( ui_count > 0 || product_count > 0 )); then
  echo "- UI/product behavior may have changed: review PRODUCT.md, DESIGN.md, product specs, and the relevant docs/quality owner guide."
fi
if (( design_count > 0 )); then
  echo "- Design artifacts changed: review the current design README and active ExecPlan."
fi
if (( source_count == 0 && design_count == 0 )); then
  echo "- Docs-only or metadata-only change: ensure the edited doc is the owner doc or clearly historical/reference evidence."
fi
echo

if (( tier1_count > 0 || tier2_count > 0 || (source_count == 0 && design_count == 0) )); then
  echo "Touched Tier 1/2 docs or no source/design changes detected. Still verify the content semantically."
else
  echo "No Tier 1/2 docs changed while source/design files changed."
  echo "Either update the relevant owner doc, or rerun with --allow-no-docs only when the final response will explicitly state why owner docs are unaffected."
  echo
  echo "Changed files sample:"
  head -n "$MAX_LIST" "$changed_file"
  if (( ALLOW_NO_DOCS > 0 )); then
    echo
    echo "Acknowledged with --allow-no-docs."
  else
    exit 1
  fi
fi

echo
echo "Tier 1/2 files touched:"
{
  list_matching "$tier1_pattern"
  list_matching "$tier2_pattern"
} | sed '/^$/d' || true
