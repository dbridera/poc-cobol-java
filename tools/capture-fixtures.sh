#!/usr/bin/env bash
# capture-fixtures.sh — convenience wrapper: run every fixture for every module
# through the COBOL runtime and refresh golden-master/.
#
# Usage:
#   ./tools/capture-fixtures.sh                # all modules, all fixtures
#   ./tools/capture-fixtures.sh <module>       # one module, all fixtures
set -euo pipefail
REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO_ROOT"

modules=()
if [[ -n "${1:-}" ]]; then
  modules+=("$1")
else
  for d in cobol/*/; do modules+=("$(basename "$d")"); done
fi

for m in "${modules[@]}"; do
  echo "==> module: $m"
  ./tools/run-cobol.sh "$m"
done
