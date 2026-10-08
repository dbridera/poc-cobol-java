#!/usr/bin/env bash
# check-module.sh — process-conformance gate.
#
# Proves that a module went through the five phases of the methodology with the
# same artefacts and the same tooling as every other module. It checks the
# *presence and consistency* of the Phase A/B/C/D/E deliverables; the
# behavioural proof itself is validation/reports/<module>.json (Phase D).
#
# Usage:
#   ./tools/check-module.sh <module>      # one module
#   ./tools/check-module.sh --all         # every cobol/<module> with a fixtures/ dir
#
# Output: one [PASS]/[FAIL]/[WARN] line per check, then RESULT: CONFORMANT | NOT CONFORMANT.
# Exit 1 if any check fails. Checks marked (job) apply only to multi-step modules
# (cobol/<module>/job.json present).
set -u
REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO_ROOT"

fails=0; passes=0; warns=0
pass() { echo "[PASS] $*"; passes=$((passes+1)); }
fail() { echo "[FAIL] $*"; fails=$((fails+1)); }
warn() { echo "[WARN] $*"; warns=$((warns+1)); }

check_module() {
  local m="$1"
  local cdir="cobol/$m" jdir="java/$m" spec="specs/$m.md" report="validation/reports/$m.json"
  local is_job=0; [[ -f "$cdir/job.json" ]] && is_job=1
  echo "==== $m $([[ $is_job -eq 1 ]] && echo '(multi-step job)')"

  # 1. README with provenance sections
  if [[ -f "$cdir/README.md" ]]; then
    local missing="" soft=""
    for kw in "Provenance" "Kept verbatim" "Adapted"; do
      grep -qi "$kw" "$cdir/README.md" || missing="$missing '$kw'"
    done
    for kw in "Added" "Removed"; do
      grep -qi "$kw" "$cdir/README.md" || soft="$soft '$kw'"
    done
    [[ -z "$missing" ]] && pass "1 README.md has Provenance / Kept verbatim / Adapted" \
                         || fail "1 README.md missing:$missing"
    [[ -n "$soft" ]] && warn "1 README.md provenance lacks:$soft"
  else
    fail "1 $cdir/README.md missing"
  fi

  # 2. DEPENDENCIES.md with 8 numbered sections + generated diagram, in sync
  if [[ -f "$cdir/DEPENDENCIES.md" ]]; then
    local secs_ok=1
    for n in 1 2 3 4 5 6 7 8; do grep -qE "^## $n\. " "$cdir/DEPENDENCIES.md" || secs_ok=0; done
    grep -q "BEGIN AUTO-GENERATED DIAGRAM" "$cdir/DEPENDENCIES.md" || secs_ok=0
    [[ $secs_ok -eq 1 ]] && pass "2 DEPENDENCIES.md has sections 1-8 and the generated diagram" \
                         || fail "2 DEPENDENCIES.md lacks sections 1-8 or the diagram block"
    if ./tools/render-dependencies.py --check >/dev/null 2>&1; then
      pass "2 render-dependencies.py --check in sync"
    else
      fail "2 render-dependencies.py --check reports drift (run ./tools/render-dependencies.py $m)"
    fi
    if [[ -f "$cdir/traceability.html" ]]; then
      if ./tools/render-traceability.py "$m" --check >/dev/null 2>&1; then
        pass "2 traceability.html / traceability.json in sync with the sources"
      else
        fail "2 traceability viewer drifted (run ./tools/render-traceability.py $m)"
      fi
    else
      warn "2 no traceability.html (run ./tools/render-traceability.py $m)"
    fi
  else
    fail "2 $cdir/DEPENDENCIES.md missing"
  fi

  # 3. Verbatim sources identical to original/  (README declares them: <!-- verbatim: A.cbl B.cbl -->)
  local verbatim
  verbatim="$(grep -oE '<!-- verbatim: [^>]*-->' "$cdir/README.md" 2>/dev/null | sed -E 's/<!-- verbatim: (.*) *-->/\1/')"
  if [[ -n "$verbatim" ]]; then
    local bad=""
    for f in $verbatim; do
      local src="$cdir/src/$f"
      local orig; orig="$(find "$cdir/original" -maxdepth 2 -iname "$f" 2>/dev/null | head -1)"
      if [[ -f "$src" && -n "$orig" ]] && cmp -s "$src" "$orig"; then :; else bad="$bad $f"; fi
    done
    [[ -z "$bad" ]] && pass "3 verbatim sources identical to original/: $verbatim" \
                     || fail "3 verbatim sources differ from original/ or missing:$bad"
  else
    warn "3 README declares no <!-- verbatim: ... --> list (single-program module adapted in place?)"
  fi

  # 4. Fixtures
  local nfix; nfix="$(find "$cdir/fixtures" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | wc -l | tr -d ' ')"
  if [[ "$nfix" -ge 1 ]]; then
    local nin=0; for d in "$cdir"/fixtures/*/; do [[ -d "$d/in" ]] && nin=$((nin+1)); done
    [[ "$nin" -eq "$nfix" ]] && pass "4 $nfix fixtures, each with in/" || fail "4 $nfix fixtures but only $nin have in/"
    [[ "$nfix" -lt 3 ]] && warn "4 fewer than 3 fixtures ($nfix): cobol-analyze asks for happy / validation / numeric-boundary"
  else
    fail "4 no fixtures"
  fi
  if [[ $is_job -eq 1 ]]; then
    ./tools/jobman.py validate "$m" >/dev/null 2>&1 && pass "4 (job) job.json validates" || fail "4 (job) job.json invalid"
    ./tools/gen-ksds-io.py "$m" --check >/dev/null 2>&1 && pass "4 (job) generated KSDS loaders in sync" || fail "4 (job) src/ksds/ out of date (run ./tools/gen-ksds-io.py $m)"
    local nrecipe=0; for d in "$cdir"/fixtures/*/; do [[ -f "$d/fixture.json" ]] && nrecipe=$((nrecipe+1)); done
    [[ "$nrecipe" -eq "$nfix" ]] && pass "4 (job) every fixture has a fixture.json recipe" || warn "4 (job) $nrecipe/$nfix fixtures have fixture.json"
    if python3 -c "import json,sys; sys.exit(0 if json.load(open('$cdir/job.json')).get('trace') else 1)"; then
      local notrace=""
      for d in "$cdir"/fixtures/*/; do
        local f; f="$(basename "$d")"
        ls "golden-master/$m/$f/out/steps/"*.trace.txt >/dev/null 2>&1 || notrace="$notrace $f"
      done
      [[ -z "$notrace" ]] && pass "4 (job) paragraph traces captured for every fixture" || fail "4 (job) fixtures without out/steps/*.trace.txt:$notrace"
      if ./tools/gen-coverage.py "$m" --check >/dev/null 2>&1; then
        pass "4 (job) COVERAGE.md and README summary in sync with the traces"
      else
        fail "4 (job) coverage drifted (run ./tools/gen-coverage.py $m)"
      fi
      local unreached; unreached="$(grep -o 'Not reached by any fixture: .*' "$cdir/README.md" | head -1)"
      [[ -n "$unreached" ]] && warn "4 (job) $unreached"
    fi
  fi

  # 5. Golden master per fixture
  local gm_ok=1
  for d in "$cdir"/fixtures/*/; do
    local f; f="$(basename "$d")"; local g="golden-master/$m/$f"
    [[ -f "$g/exit_code" && -f "$g/stdout.txt" && -d "$g/out" ]] || gm_ok=0
    [[ $is_job -eq 1 && ! -f "$g/out/run-log.txt" ]] && gm_ok=0
  done
  [[ $gm_ok -eq 1 ]] && pass "5 golden-master has exit_code/stdout.txt/out$([[ $is_job -eq 1 ]] && echo '/run-log.txt') for every fixture" \
                     || fail "5 golden-master incomplete for some fixture"

  # 6. Spec
  if [[ -f "$spec" ]]; then
    local sok=1; for n in 1 2 3 4 5 6 7 8 9; do grep -qE "^## $n\. " "$spec" || sok=0; done
    [[ $sok -eq 1 ]] && pass "6 spec has numbered sections 1-9+" || fail "6 spec lacks numbered sections 1-9"
    grep -q "RoundingMode\|HALF_UP\|truncat" "$spec" && pass "6 spec states rounding/truncation" || warn "6 spec does not mention rounding"
  else
    fail "6 $spec missing"
  fi

  # 7. Java module: pom, stdout suppression, traceability, rule 1
  if [[ -f "$jdir/pom.xml" ]]; then
    pass "7 java/$m/pom.xml present"
    local props; props="$(find "$jdir/src/main/resources" -name application.properties | head -1)"
    if [[ -n "$props" ]] && grep -q "spring.main.banner-mode=off" "$props" && grep -q "spring.main.log-startup-info=false" "$props" && grep -q "logging.level.root=OFF" "$props"; then
      pass "7 application.properties suppresses banner/startup/log"
    else
      fail "7 application.properties lacks the three stdout-suppression keys"
    fi
    local untraced soft_untraced
    untraced="$(find "$jdir/src/main/java" \( -path '*/service/*' -o -path '*/batch/*' \) -name '*.java' \
                 ! -name '*Application.java' -print0 2>/dev/null | xargs -0 grep -LE 'COBOL:.*\.(cbl|CBL|COB):?[0-9]|cobol-trace-exempt:' 2>/dev/null)"
    [[ -z "$untraced" ]] && pass "7 every service/batch class cites COBOL: <file>.cbl:<lines>" \
                          || fail "7 service/batch classes without COBOL: <file>.cbl:<lines> traceability: $(echo "$untraced" | sed 's|.*/||' | tr '\n' ' ')"
    soft_untraced="$(find "$jdir/src/main/java" -path '*/domain/*' -name '*.java' -print0 2>/dev/null | xargs -0 grep -LE 'COBOL:|\.cpy|copybook' 2>/dev/null)"
    [[ -n "$soft_untraced" ]] && warn "7 domain classes without a copybook reference: $(echo "$soft_untraced" | sed 's|.*/||' | tr '\n' ' ')"
    local floats
    floats="$(grep -rnE '\b(double|float)\b' "$jdir/src/main/java" 2>/dev/null | grep -v 'cobol-rule1-exempt' | grep -vE '^[^:]*:[0-9]+:\s*(//|\*|/\*)' | head -3)"
    [[ -z "$floats" ]] && pass "7 no double/float in src/main (hard rule 1)" || fail "7 double/float found: $floats"
  else
    fail "7 $jdir/pom.xml missing"
  fi

  # 8. Validation report green and fresh
  if [[ -f "$report" ]]; then
    if python3 - "$report" <<'EOF'
import json,sys
d=json.load(open(sys.argv[1]))
ok = bool(d) and all(("diffs" in e) and not e["diffs"] for e in d)
sys.exit(0 if ok else 1)
EOF
    then pass "8 $report: all fixtures diffs == []"; else fail "8 $report has non-empty diffs or errors"; fi
    local newer
    newer="$(find "golden-master/$m" "java-run/$m" -type f -newer "$report" 2>/dev/null | head -1)"
    [[ -z "$newer" ]] && pass "8 report is newer than golden-master/ and java-run/" || fail "8 stale report: $newer is newer (re-run compare-outputs.py $m)"
  else
    fail "8 $report missing"
  fi

  # 9. Methodology links
  grep -q "$m" docs/methodology/DECISIONS.md && pass "9 DECISIONS.md cites the module" || fail "9 DECISIONS.md never cites $m"
  grep -q "$m" docs/methodology/glossary.yaml && pass "9 glossary.yaml mentions the module" || warn "9 glossary.yaml does not mention $m"

  # 10. Demo script
  grep -q "$m" tools/demo-commands.sh && pass "10 demo-commands.sh runs the module" || fail "10 demo-commands.sh does not mention $m"

  # 11. (job) equivalence invariants between fixtures (restart / EBCDIC variant)
  if [[ $is_job -eq 1 ]]; then
    for d in "$cdir"/fixtures/*/; do
      local f; f="$(basename "$d")"
      [[ -f "$d/fixture.env" ]] || continue
      local eq; eq="$(grep -E '^(RESTART|VARIANT)_EQUIVALENT_TO=' "$d/fixture.env" | head -1 | cut -d= -f2 | tr -d '"')"
      [[ -n "$eq" ]] || continue
      for tree in golden-master java-run; do
        [[ -d "$tree/$m/$f/out" && -d "$tree/$m/$eq/out" ]] || { warn "11 (job) $tree/$m/$f or $eq not captured yet"; continue; }
        if diff -r -x run-log.txt -x steps "$tree/$m/$f/out" "$tree/$m/$eq/out" >/dev/null 2>&1 \
           && cmp -s "$tree/$m/$f/exit_code" "$tree/$m/$eq/exit_code"; then
          pass "11 (job) $tree: $f ≡ $eq (outputs identical except run-log/steps)"
        else
          fail "11 (job) $tree: $f differs from $eq"
        fi
      done
    done
  fi

  # 12. Human-in-the-loop reminder
  echo "[NOTE] 12 run the equivalence-validator subagent on '$m' and require RESULT: GREEN"
}

modules=()
if [[ "${1:-}" == "--all" ]]; then
  for d in cobol/*/; do [[ -d "$d/fixtures" ]] && modules+=("$(basename "$d")"); done
elif [[ -n "${1:-}" ]]; then
  modules+=("$1")
else
  echo "usage: $0 <module> | --all" >&2; exit 2
fi

for m in "${modules[@]}"; do check_module "$m"; done
echo
if [[ $fails -eq 0 ]]; then
  echo "RESULT: CONFORMANT ($passes checks passed, $warns warnings, ${#modules[@]} module(s))"
  exit 0
else
  echo "RESULT: NOT CONFORMANT ($fails failed, $passes passed, $warns warnings)"
  exit 1
fi
