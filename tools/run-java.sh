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

  ( cd "$sandbox" && java -jar "$REPO_ROOT/$JAR" requests.dat . ) \
      > "$out_dir/stdout.txt" 2> "$out_dir/stderr.txt" \
      && echo 0 > "$out_dir/exit_code" \
      || echo "$?" > "$out_dir/exit_code"

  # The Java side writes policy.dat / motor.dat / error.log into the sandbox alongside requests.dat.
  # Move all non-input artifacts to out/ so the diff has the same shape as golden-master/.
  for f in "$sandbox"/*; do
      name="$(basename "$f")"
      [[ "$name" == "requests.dat" ]] && continue
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
