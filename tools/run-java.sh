#!/usr/bin/env bash
# run-java.sh — package the Java module and run it against every fixture,
# capturing outputs into java-run/<module>/<fixture>/ in the same shape as
# golden-master/. Then compare-outputs.py can diff the two trees.
#
# Usage:
#   ./tools/run-java.sh <module>                # all fixtures
#   ./tools/run-java.sh <module> <fixture>      # single fixture
set -euo pipefail
REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO_ROOT"

export PATH="/usr/local/bin:/usr/local/opt/openjdk@21/bin:${PATH:-}"
export JAVA_HOME="${JAVA_HOME:-/usr/local/opt/openjdk@21}"

MODULE="${1:?usage: $0 <module> [fixture]}"
FIXTURE="${2:-}"

JAVA_DIR="java/$MODULE"
[[ -d "$JAVA_DIR" ]] || { echo "no java/ project at $JAVA_DIR"; exit 2; }

# Multi-step job modules (JCL analogue) declare cobol/<module>/job.json and are
# executed by run-job.py; everything below stays the single-program path.
if [[ -f "cobol/$MODULE/job.json" ]]; then
  exec "$REPO_ROOT/tools/run-job.py" --side java "$MODULE" ${FIXTURE:+"$FIXTURE"}
fi

# Build a runnable JAR (skip tests on this path; tests are validated separately).
echo "==> building $MODULE"
( cd "$JAVA_DIR" && mvn -q -B -DskipTests package )
JAR="$(ls "$JAVA_DIR"/target/*.jar | grep -v '\.original' | head -1)"
[[ -f "$JAR" ]] || { echo "JAR not found under $JAVA_DIR/target/"; exit 2; }

run_fixture() {
  local fix="$1"
  local fix_dir="cobol/$MODULE/fixtures/$fix"
  local out_dir="java-run/$MODULE/$fix"
  [[ -d "$fix_dir" ]] || { echo "no fixture $fix at $fix_dir"; return 1; }

  echo "==> running fixture $fix"
  rm -rf "$out_dir"; mkdir -p "$out_dir/out"

  local sandbox; sandbox="$(mktemp -d)"
  if compgen -G "$fix_dir/in/*" >/dev/null; then cp -R "$fix_dir/in/." "$sandbox/"; fi

  # Main input: fixture.env INPUT= if set, else the single file under in/, else requests.dat.
  local input="requests.dat"
  if [[ -f "$fix_dir/fixture.env" ]]; then
    # shellcheck disable=SC1090
    source "$fix_dir/fixture.env"
    [[ -n "${INPUT:-}" ]] && input="$INPUT"
  elif [[ -d "$fix_dir/in" ]] && [[ "$(ls -1 "$fix_dir/in" | wc -l | tr -d ' ')" == "1" ]]; then
    input="$(ls -1 "$fix_dir/in")"
  fi

  ( cd "$sandbox" && java -jar "$REPO_ROOT/$JAR" "$input" . ) \
      > "$out_dir/stdout.txt" 2> "$out_dir/stderr.txt" \
      && echo 0 > "$out_dir/exit_code" \
      || echo "$?" > "$out_dir/exit_code"

  # The Java side writes its output files into the sandbox alongside the inputs.
  # Move every non-input artifact to out/ so the diff has the same shape as
  # golden-master/ (same exclusion rule as run-cobol.sh: anything staged from in/).
  for f in "$sandbox"/*; do
      [[ -e "$f" ]] || continue
      name="$(basename "$f")"
      if [[ -e "$fix_dir/in/$name" ]]; then continue; fi
      mv "$f" "$out_dir/out/$name"
  done
  rm -rf "$sandbox"
  echo "captured: $out_dir"
}

if [[ -n "$FIXTURE" ]]; then
  run_fixture "$FIXTURE"
else
  for d in cobol/"$MODULE"/fixtures/*/; do
      run_fixture "$(basename "$d")"
  done
fi
