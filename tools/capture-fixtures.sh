#!/usr/bin/env bash
# capture-fixtures.sh — convenience wrapper: run every fixture for every module
# through the COBOL runtime and refresh golden-master/.
#
# Dispatches per module type:
#   cobol/<m>/job.json present      -> tools/run-job.sh      (multi-step job, JCL analogue)
#   cobol/<m>/schema/ present       -> tools/run-cobol-db.sh (EXEC SQL via the SQLite shim)
#   otherwise                       -> tools/run-cobol.sh    (single program, file I/O)
# Directories without a fixtures/ folder (e.g. cobol/genapp-source) are skipped.
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
  if [[ ! -d "cobol/$m/fixtures" ]]; then
    echo "==> module: $m (no fixtures/ — skipped)"
    continue
  fi
  echo "==> module: $m"
  if [[ -f "cobol/$m/job.json" ]]; then
    ./tools/run-job.sh "$m"
  elif [[ -d "cobol/$m/schema" ]]; then
    ./tools/run-cobol-db.sh "$m"
  else
    ./tools/run-cobol.sh "$m"
  fi
done
