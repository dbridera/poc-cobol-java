#!/usr/bin/env bash
# run-cobol-db.sh — compile + run a DB-touching COBOL module against fixtures
# and capture stdout / output files (including dumped DB tables) into
# golden-master/<module>/<fixture>/.
#
# Differs from run-cobol.sh in two ways:
#   1. compiles with `cobc -free` (DB modules use free format for SQL literals
#      that don't fit cleanly in fixed-format column 8-72)
#   2. links against tools/spike/libcob_sqlite.dylib + libsqlite3, and sets
#      DYLD_LIBRARY_PATH at runtime so CALL "cob_sqlite_*" resolves
#
# Output layout matches run-cobol.sh so compare-outputs.py is reused as-is.
#
# Usage:
#   ./tools/run-cobol-db.sh <module>             # run all fixtures
#   ./tools/run-cobol-db.sh <module> <fixture>   # run one fixture
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO_ROOT"

SHIM_DIR="$REPO_ROOT/tools/spike"
SQLITE_LIB="/usr/local/opt/sqlite/lib"
SQLITE_INC="/usr/local/opt/sqlite/include"

require_cobc() {
  command -v cobc >/dev/null 2>&1 || { echo "ERROR: cobc not installed (see tools/setup.md)" >&2; exit 127; }
}

# Build the shim once (idempotent).
build_shim() {
  if [[ ! -f "$SHIM_DIR/libcob_sqlite.dylib" || "$SHIM_DIR/cob_sqlite.c" -nt "$SHIM_DIR/libcob_sqlite.dylib" ]]; then
    echo "==> compiling libcob_sqlite.dylib"
    cc -shared -fPIC -I"$SQLITE_INC" -L"$SQLITE_LIB" \
       -o "$SHIM_DIR/libcob_sqlite.dylib" "$SHIM_DIR/cob_sqlite.c" -lsqlite3
  fi
}

run_fixture() {
  local module="$1" fixture="$2"
  local src_dir="cobol/$module/src"
  local fix_dir="cobol/$module/fixtures/$fixture"
  local out_dir="golden-master/$module/$fixture"

  [[ -d "$src_dir" ]] || { echo "missing $src_dir" >&2; return 1; }
  [[ -d "$fix_dir" ]] || { echo "missing $fix_dir" >&2; return 1; }
  mkdir -p "$out_dir"

  local bin_dir="cobol/$module/bin"
  mkdir -p "$bin_dir"
  local main_program=""
  for cbl in "$src_dir"/*.cbl; do
    local name; name="$(basename "$cbl" .cbl)"
    if [[ ! -f "$bin_dir/$name" || "$cbl" -nt "$bin_dir/$name" ]]; then
      cobc -free -x -O -Wall \
        -L"$SHIM_DIR" -lcob_sqlite \
        -L"$SQLITE_LIB" \
        -o "$bin_dir/$name" "$cbl"
    fi
    [[ -z "$main_program" ]] && main_program="$bin_dir/$name"
  done

  # Stage fixture inputs into a sandbox.
  local sandbox; sandbox="$(mktemp -d)"
  mkdir -p "$sandbox/out"
  if compgen -G "$fix_dir/in/*" >/dev/null; then cp -R "$fix_dir/in/." "$sandbox/"; fi

  local stdin_file="/dev/null"
  [[ -f "$fix_dir/stdin.txt" ]] && stdin_file="$fix_dir/stdin.txt"

  # Run with the shim resolvable via DYLD_LIBRARY_PATH.
  ( cd "$sandbox" && DYLD_LIBRARY_PATH="$SHIM_DIR:$SQLITE_LIB" \
      "$REPO_ROOT/$main_program" ) <"$stdin_file" \
      >"$out_dir/stdout.txt" 2>"$out_dir/stderr.txt" \
      && echo 0 >"$out_dir/exit_code" \
      || echo "$?" >"$out_dir/exit_code"

  # Capture output files (sandbox/out + any top-level new files), excluding inputs.
  rm -rf "$out_dir/out"
  mkdir -p "$out_dir/out"
  # Outputs are anything written into sandbox/out/, EXCLUDING intermediate
  # *.db files which are the SQLite scratch DB (not a diffable artifact).
  for f in "$sandbox/out/"*; do
      [[ -e "$f" ]] || continue
      local name; name="$(basename "$f")"
      [[ "$name" == *.db ]] && continue
      mv "$f" "$out_dir/out/$name"
  done
  # Also capture anything written at the sandbox root (e.g., a program that
  # writes files alongside its input). Skip input files and .db intermediates.
  for f in "$sandbox"/*; do
      [[ -e "$f" ]] || continue
      [[ -d "$f" ]] && continue
      local name; name="$(basename "$f")"
      [[ -e "$fix_dir/in/$name" ]] && continue
      [[ "$name" == *.db ]] && continue
      mv "$f" "$out_dir/out/$name"
  done

  rm -rf "$sandbox"
  echo "captured: $out_dir"
}

main() {
  require_cobc
  build_shim
  local module="${1:?usage: $0 <module> [fixture]}"
  if [[ -n "${2:-}" ]]; then
    run_fixture "$module" "$2"
  else
    [[ -d "cobol/$module/fixtures" ]] || { echo "no fixtures dir at cobol/$module/fixtures" >&2; exit 1; }
    for fix in cobol/"$module"/fixtures/*/; do
      run_fixture "$module" "$(basename "$fix")"
    done
  fi
}

main "$@"
