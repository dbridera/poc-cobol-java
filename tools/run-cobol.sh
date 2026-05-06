#!/usr/bin/env bash
# run-cobol.sh — compile + run a COBOL module against an input fixture and
# capture stdout/files into golden-master/<module>/<fixture>/.
#
# Usage:
#   ./tools/run-cobol.sh <module>                  # run all fixtures for module
#   ./tools/run-cobol.sh <module> <fixture>        # run a single fixture
#   ./tools/run-cobol.sh --self-test               # compile+run a hello-world to verify GnuCOBOL works
#
# Layout assumed:
#   cobol/<module>/src/*.cbl           main programs
#   cobol/<module>/copybooks/*.cpy     copybooks (added to -I)
#   cobol/<module>/fixtures/<name>/    each fixture has stdin.txt + input files
#   golden-master/<module>/<name>/     written here: stdout.txt + output files
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO_ROOT"

require_cobc() {
  if ! command -v cobc >/dev/null 2>&1; then
    echo "ERROR: cobc (GnuCOBOL) not installed. See tools/setup.md" >&2
    exit 127
  fi
}

self_test() {
  require_cobc
  local tmp; tmp="$(mktemp -d)"
  cat >"$tmp/hello.cbl" <<'EOF'
       IDENTIFICATION DIVISION.
       PROGRAM-ID. HELLO.
       PROCEDURE DIVISION.
           DISPLAY "GnuCOBOL OK".
           STOP RUN.
EOF
  cobc -x -o "$tmp/hello" "$tmp/hello.cbl"
  "$tmp/hello"
  rm -rf "$tmp"
}

run_fixture() {
  local module="$1" fixture="$2"
  local src_dir="cobol/$module/src"
  local cpy_dir="cobol/$module/copybooks"
  local fix_dir="cobol/$module/fixtures/$fixture"
  local out_dir="golden-master/$module/$fixture"

  [[ -d "$src_dir" ]]  || { echo "missing $src_dir" >&2; return 1; }
  [[ -d "$fix_dir" ]]  || { echo "missing $fix_dir" >&2; return 1; }
  mkdir -p "$out_dir"

  # Compile every .cbl in src/ once into a per-module bin dir.
  local bin_dir="cobol/$module/bin"
  mkdir -p "$bin_dir"
  local main_program=""
  for cbl in "$src_dir"/*.cbl; do
    local name; name="$(basename "$cbl" .cbl)"
    if [[ ! -f "$bin_dir/$name" || "$cbl" -nt "$bin_dir/$name" ]]; then
      cobc -x -O -Wall \
        ${cpy_dir:+-I "$cpy_dir"} \
        -o "$bin_dir/$name" "$cbl"
    fi
    [[ -z "$main_program" ]] && main_program="$bin_dir/$name"
  done

  # Convention: a fixture may declare PROGRAM= in fixture.env to override which binary to run.
  if [[ -f "$fix_dir/fixture.env" ]]; then
    # shellcheck disable=SC1090
    source "$fix_dir/fixture.env"
    [[ -n "${PROGRAM:-}" ]] && main_program="$bin_dir/$PROGRAM"
  fi

  # Stage input files into a sandbox so the program can read/write without polluting the repo.
  local sandbox; sandbox="$(mktemp -d)"
  if compgen -G "$fix_dir/in/*" >/dev/null; then cp -R "$fix_dir/in/." "$sandbox/"; fi

  local stdin_file="/dev/null"
  [[ -f "$fix_dir/stdin.txt" ]] && stdin_file="$fix_dir/stdin.txt"

  # Run, capture stdout and exit code.
  ( cd "$sandbox" && "$REPO_ROOT/$main_program" ) <"$stdin_file" \
      >"$out_dir/stdout.txt" 2>"$out_dir/stderr.txt" \
      && echo 0 >"$out_dir/exit_code" \
      || echo "$?" >"$out_dir/exit_code"

  # Capture any output files the program wrote in the sandbox, EXCLUDING the
  # input files that we staged in (those are not "outputs" from the run).
  rm -rf "$out_dir/out"
  mkdir -p "$out_dir/out"
  for f in "$sandbox"/*; do
      [[ -e "$f" ]] || continue
      name="$(basename "$f")"
      # Skip anything that was staged from $fix_dir/in/.
      if [[ -e "$fix_dir/in/$name" ]]; then continue; fi
      mv "$f" "$out_dir/out/$name"
  done

  rm -rf "$sandbox"
  echo "captured: $out_dir"
}

main() {
  if [[ "${1:-}" == "--self-test" ]]; then self_test; return; fi
  require_cobc
  local module="${1:?usage: $0 <module> [fixture]}"
  if [[ -n "${2:-}" ]]; then
    run_fixture "$module" "$2"
  else
    if [[ ! -d "cobol/$module/fixtures" ]]; then
      echo "no fixtures dir at cobol/$module/fixtures" >&2; exit 1
    fi
    for fix in cobol/"$module"/fixtures/*/; do
      run_fixture "$module" "$(basename "$fix")"
    done
  fi
}

main "$@"
