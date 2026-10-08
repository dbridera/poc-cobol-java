#!/usr/bin/env bash
# demo-commands.sh — runnable cheat-sheet for the COBOL → Java demo.
#
# Each module subcommand narrates the live demo: prints PHASE A / C / D
# headers explaining what's being done and why, runs the underlying COBOL
# and Java commands, and closes with a RESULT block summarising channels
# diffed and the empirical finding the module surfaced.
#
# Usage:
#   ./tools/demo-commands.sh preflight    # toolchain check + clean state + warm-up (run ~30 min before demo)
#   ./tools/demo-commands.sh module-0     # VSAM / file access — 3 fixtures
#   ./tools/demo-commands.sh module-1b    # DB2 / EXEC SQL → JPA + H2 — 2 fixtures
#   ./tools/demo-commands.sh module-1a    # CICS LINK → Spring service-to-service — 1 fixture
#   ./tools/demo-commands.sh module-2     # Real banking module: CCI ↔ BCP (BCTITSCV) — 3 fixtures
#   ./tools/demo-commands.sh module-3     # Nightly batch: 4-step JCL job (CardDemo), restart + abend — 6 fixtures
#   ./tools/demo-commands.sh negative-control  # two sabotages in module 3 (a rounding mode; "fixing" a legacy bug): field-level red diff + divergent paragraph, revert
#   ./tools/demo-commands.sh conformance  # tools/check-module.sh --all: every module went through the same 5 phases
#   ./tools/demo-commands.sh proof        # validation/reports/*.json + cross-module summary (computed, not hard-coded)
#   ./tools/demo-commands.sh all          # module-0 + module-1b + module-1a + module-2 + module-3 + conformance + proof
#
# Add --quiet to any subcommand to suppress the narrative (terse mode).
#
# Note: deliberately no `pipefail` — `cobc --version | head -1` upstream
# gets SIGPIPE when head closes early, which would tank the toolchain check.
set -eu

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO_ROOT"

export PATH="/usr/local/bin:/usr/local/opt/openjdk@21/bin:${PATH:-}"
export JAVA_HOME="${JAVA_HOME:-/usr/local/opt/openjdk@21}"

# ----- terminal formatting (no-op when not a TTY) -----
if [[ -t 1 ]]; then
  GREEN=$'\033[32m'; CYAN=$'\033[36m'; YELLOW=$'\033[33m'
  BOLD=$'\033[1m';   DIM=$'\033[2m';   RESET=$'\033[0m'
else
  GREEN=""; CYAN=""; YELLOW=""; BOLD=""; DIM=""; RESET=""
fi

QUIET=0
# Strip --quiet from anywhere in the args; pass the rest through.
ARGS=()
for a in "$@"; do
  case "$a" in
    --quiet) QUIET=1 ;;
    *) ARGS+=("$a") ;;
  esac
done
set -- "${ARGS[@]:-}"

# ----- narrative helpers -----

# module_header "0" "VSAM / file access" "add-motor-policy" "how do you handle VSAM?"
module_header() {
  local n="$1" title="$2" mod="$3" concern="$4"
  if [[ $QUIET -eq 1 ]]; then echo "==== Module $n — $title ($mod) ===="; return; fi
  echo
  echo "${CYAN}${BOLD}════════════════════════════════════════════════════════════${RESET}"
  echo "${CYAN}${BOLD}  MODULE $n — $title ($mod)${RESET}"
  echo "${CYAN}  Answers the stakeholder concern: \"$concern\"${RESET}"
  echo "${CYAN}${BOLD}════════════════════════════════════════════════════════════${RESET}"
}

# phase "A" "Capture legacy ground truth" "what we do" "why it matters" "output path"
phase() {
  local letter="$1" title="$2" what="$3" why="$4" output="$5"
  if [[ $QUIET -eq 1 ]]; then return; fi
  echo
  echo "${YELLOW}${BOLD}▶ PHASE $letter — $title${RESET}"
  echo "${DIM}  what: $what${RESET}"
  echo "${DIM}  why : $why${RESET}"
  echo "${DIM}  → output: $output${RESET}"
  echo
}

# run with the command echoed
run() {
  if [[ $QUIET -eq 0 ]]; then echo "  ${BOLD}\$ $*${RESET}"; fi
  "$@"
}

# result_summary "0" "Module 0" "3" "3" "stdout · exit_code · policy.dat · motor.dat · error.log" "COBOL ROUNDED defaults to HALF_UP (ADR-4)"
result_summary() {
  local mod_id="$1" mod_label="$2" passed="$3" total="$4" channels="$5" finding="$6"
  if [[ $QUIET -eq 1 ]]; then return; fi
  local mark="${GREEN}✅${RESET}"
  [[ "$passed" != "$total" ]] && mark="${YELLOW}⚠${RESET}"
  echo
  echo "${GREEN}────────────────────────────────────────────────────────────${RESET}"
  echo "${GREEN}${BOLD}  RESULT — $mod_label: $passed / $total fixtures byte-exact equivalent${RESET} $mark"
  echo "${GREEN}  channels diffed: $channels${RESET}"
  echo "${GREEN}  bytes diverging: 0${RESET}"
  echo "${GREEN}  empirical finding codified: $finding${RESET}"
  echo "${GREEN}────────────────────────────────────────────────────────────${RESET}"
}

# show_version "cobc --version" cobc --version
show_version() {
  local label="$1"; shift
  echo "${BOLD}\$ $label${RESET}"
  local out
  out="$("$@" 2>&1 | head -1 || true)"
  echo "  $out"
}

# ----- subcommands -----

preflight() {
  echo "${BOLD}==== Pre-flight: toolchain ====${RESET}"
  show_version "cobc --version" cobc --version
  show_version "java -version" java -version
  show_version "mvn -v"        mvn -v

  echo
  echo "${BOLD}==== Clean state (so live run feels fresh) ====${RESET}"
  echo "  ${BOLD}\$ rm -rf java-run cobol/*/bin${RESET}"
  rm -rf java-run cobol/add-motor-policy/bin cobol/add-policy-db/bin cobol/add-policy-facade/bin cobol/cci-account-converter/bin cobol/nightly-batch/bin

  echo
  echo "${BOLD}==== Warm-up: all five modules end-to-end ====${RESET}"
  QUIET=1 module-0
  QUIET=1 module-1b
  QUIET=1 module-1a
  QUIET=1 module-2
  QUIET=1 module-3

  echo
  echo "${GREEN}${BOLD}Pre-flight complete. Fifteen fixtures byte-exact equivalent.${RESET}"
  echo "${GREEN}You're ready for the live demo.${RESET}"
}

module-0() {
  module_header "0" "VSAM / file access" "add-motor-policy" "how do you handle VSAM?"

  phase "A" "Capture legacy ground truth" \
    "re-run original COBOL on GnuCOBOL against 3 test fixtures" \
    "every byte of COBOL output becomes the contract" \
    "golden-master/add-motor-policy/"
  run ./tools/run-cobol.sh add-motor-policy

  phase "C" "Exercise the previously-translated Java" \
    "build + run Spring Boot 3 / Java 21 / BigDecimal translation" \
    "prove the Java behaves the same as the COBOL we just captured" \
    "java-run/add-motor-policy/"
  run ./tools/run-java.sh add-motor-policy

  phase "D" "Byte-exact validation (THE contract)" \
    "diff every byte of every output channel between COBOL and Java" \
    "0 diffs = behavioral equivalence proven; non-zero = stop and investigate" \
    "validation/reports/add-motor-policy.json"
  run ./tools/compare-outputs.py add-motor-policy

  result_summary "0" "Module 0 (VSAM)" "3" "3" \
    "stdout · exit_code · policy.dat · motor.dat · error.log" \
    "COBOL ROUNDED defaults to HALF_UP, not HALF_EVEN (ADR-4)"
}

module-1b() {
  module_header "1B" "DB2 / EXEC SQL → JPA + H2" "add-policy-db" "how do you handle DB2 / databases?"

  phase "A" "Capture legacy ground truth (DB state)" \
    "re-run COBOL → SQLite via libcob_sqlite shim, dump POLICY table" \
    "the dumped table IS the observable output — same harness, DB-aware" \
    "golden-master/add-policy-db/"
  run ./tools/run-cobol-db.sh add-policy-db

  phase "C" "Exercise the Java translation (Spring + JPA + H2)" \
    "EntityManager.persist + flush inside @Transactional(REQUIRES_NEW)" \
    "JPA against H2; one tx per request — matches CICS pattern" \
    "java-run/add-policy-db/"
  run ./tools/run-java.sh add-policy-db

  phase "D" "Byte-exact validation (stdout + DB table dump)" \
    "diff stdout + policy.csv between COBOL and Java" \
    "fixture 02 has a duplicate PK — exercises the SQL-error path" \
    "validation/reports/add-policy-db.json"
  run ./tools/compare-outputs.py add-policy-db

  result_summary "1B" "Module 1B (DB2)" "2" "2" \
    "stdout · exit_code · policy.csv" \
    "JpaRepository.save is MERGE not INSERT — use em.persist+flush (ADR-9)"
}

module-1a() {
  module_header "1A" "CICS LINK → Spring service-to-service DI" "add-policy-facade" "how do you handle the COBOL orchestrator?"

  phase "A" "Capture chained legacy output" \
    "outer COBOL facade CALLs nested DB program (GnuCOBOL stand-in for EXEC CICS LINK)" \
    "control + payload + return code propagate the same way Spring DI does" \
    "golden-master/add-policy-facade/"
  run ./tools/run-cobol-db.sh add-policy-facade

  phase "C" "Exercise the Java service chain" \
    "PolicyFacadeService → @Autowired PolicyInsertService" \
    "CICS LINK collapses to Spring DI; @Transactional sits on the inner service" \
    "java-run/add-policy-facade/"
  run ./tools/run-java.sh add-policy-facade

  phase "D" "Byte-exact validation (chained output)" \
    "diff stdout from BOTH levels + the resulting POLICY table" \
    "proves the two-program chain preserves observable behavior end-to-end" \
    "validation/reports/add-policy-facade.json"
  run ./tools/compare-outputs.py add-policy-facade

  result_summary "1A" "Module 1A (CICS LINK)" "1" "1" \
    "stdout · exit_code · policy.csv" \
    "EXEC CICS LINK → same-JVM Spring DI for this PoC scope (ADR-10)"
}

module-2() {
  module_header "2" "Real banking module — CCI ↔ BCP converter" "cci-account-converter" \
    "does this work on a real legacy program, not just GenApp?"

  phase "A" "Capture legacy ground truth" \
    "run the adapted Banco de Crédito del Perú BCTITSCV on GnuCOBOL across 3 fixtures" \
    "real Spanish-language COBOL with mod-10 check-digit math — same harness, no special casing" \
    "golden-master/cci-account-converter/"
  run ./tools/run-cobol.sh cci-account-converter

  phase "C" "Exercise the Java translation" \
    "Spring Boot 3 + Java 21 + BigDecimal everywhere (loop indices and digit accumulators too)" \
    "check digits use RoundingMode.DOWN for integer division and .remainder(TEN) for PIC 9(01) truncation" \
    "java-run/cci-account-converter/"
  run ./tools/run-java.sh cci-account-converter

  phase "D" "Byte-exact validation (stdout + exit_code)" \
    "diff every byte of the per-call output block (RC / MSG / FAM-RET / BCP-EDIT / CUENTA-ITE)" \
    "fixture 02 exercises the mod-10 check-digit calculation end-to-end" \
    "validation/reports/cci-account-converter.json"
  run ./tools/compare-outputs.py cci-account-converter

  result_summary "2" "Module 2 (real BCP package)" "3" "3" \
    "stdout · exit_code" \
    "Integer division uses RoundingMode.DOWN, not HALF_UP (ADR-11) + PIC narrow-store truncation as algorithm (ADR-12)"
}

module-3() {
  module_header "3" "Nightly batch — a 4-step JCL job (CardDemo nightly close)" "nightly-batch" \
    "how do you handle real batch: JCL steps, VSAM updated in place, sorts, restart after a crash, abends?"

  phase "A" "Capture the legacy job, step by step" \
    "run the 16-step job on GnuCOBOL for 6 fixtures: 6 KSDS loads → POSTTRAN → backup → INTCALC → sort+reload → unload+sort+report → 2 capture unloads" \
    "every step's stdout + RC, the job log and the 9 datasets the job leaves behind are the contract — one fixture is killed after step 2 and resumed" \
    "golden-master/nightly-batch/"
  run ./tools/run-job.sh nightly-batch

  phase "C" "Exercise the Spring Batch translation" \
    "the same job.json drives one Spring Batch Step per JCL step; KSDS files are H2 tables via JDBC; BigDecimal with DOWN where COBOL truncates" \
    "restart = JobRepository skipping COMPLETED steps across two JVM runs; abend = RC 12 and NOT RUN steps, capture unloads still run" \
    "java-run/nightly-batch/"
  run ./tools/run-java.sh nightly-batch

  phase "D" "Byte-exact validation — 44 files per fixture" \
    "diff fixed-length binary datasets (overpunched signs included) with record/column/hex reporting, per-step stdout, RC and the job log" \
    "fixture 05 proves killed-and-resumed ≡ unbroken; fixture 03 holds the numeric edge cases; fixture 06 the abend" \
    "validation/reports/nightly-batch.json"
  run ./tools/compare-outputs.py nightly-batch

  if [[ $QUIET -eq 0 ]]; then
    echo
    echo "${CYAN}${BOLD}  MOMENT 1 — restart: the job log of fixture 05 (killed after INTCALC, resumed)${RESET}"
    grep -vE "RC=0000$" golden-master/nightly-batch/05-restart/out/run-log.txt | sed 's/^/    /'
    echo "${DIM}    outputs identical to the unbroken run (check-module.sh enforces it) — on both sides${RESET}"
    echo
    echo "${CYAN}${BOLD}  MOMENT 2 — the faithful bug: last account after INTCALC (fixture 01, golden master)${RESET}"
    echo "${DIM}    CBACT04C.cbl:219-221 — the ELSE that would update the last account never runs: interest transaction written,${RESET}"
    echo "${DIM}    balance untouched, cycle totals not reset. The Java reproduces it (CLAUDE.md rule 5) and the SME checklist asks about it.${RESET}"
    ./tools/make-fixture.py --dump carddemo_account golden-master/nightly-batch/01-happy-small/out/acctfile.unl \
      | tail -1 | python3 -c "import sys,json; r=json.loads(sys.stdin.read()); print('    account', r['ACCT-ID'], 'balance', r['ACCT-CURR-BAL'], 'cycle credit', r['ACCT-CURR-CYC-CREDIT'], 'cycle debit', r['ACCT-CURR-CYC-DEBIT'])"
    echo
    echo "${CYAN}${BOLD}  MOMENT 3 — did we translate everything? (paragraph traces, coverage, side-by-side viewer)${RESET}"
    echo "${DIM}    Every paragraph GnuCOBOL enters is traced; the Java emits the same trace and it is part of the diff.${RESET}"
    grep -A3 "BEGIN AUTO-GENERATED COVERAGE" cobol/nightly-batch/README.md | grep -v "^<!--" | sed 's/^/    /'
    echo "    viewer: cobol/nightly-batch/traceability.html  (COBOL left, Java right; click a paragraph → the Java that translates it,"
    echo "            with a 'Qué hace' line per paragraph from cobol/nightly-batch/PARAGRAPHS.md)"
    if [[ "$(uname)" == "Darwin" ]]; then open cobol/nightly-batch/traceability.html 2>/dev/null || true; fi
  fi

  result_summary "3" "Module 3 (nightly batch, 4 JCL steps)" "6" "6" \
    "per-step stdout · paragraph traces · exit_code (MAXRC) · run-log.txt · dalyrejs · tranbkp · systran · combined · tranbkp2 · trandaly · tranrept · acctfile.unl · tcatbal.unl" \
    "JCL step = Spring Batch step with step-level restart (ADR-14) · JDBC not JPA for record-at-a-time batch (ADR-13) · COMPUTE without ROUNDED truncates toward zero · faithful defects replicated, never fixed"
}

negative-control() {
  module_header "NC" "Negative control — does the harness bite?" "nightly-batch" \
    "how do we know the diff would catch a translation that is wrong by one cent?"
  local f=java/nightly-batch/src/main/java/com/example/poc/nightlybatch/service/InterestCalculator.java
  echo
  echo "  ${BOLD}sabotage:${RESET} RoundingMode.DOWN → HALF_UP in InterestCalculator.monthlyInterest — one token, the kind of change a reviewer would wave through"
  sed -i '' 's/divide(TWELVE_HUNDRED, 2, RoundingMode.DOWN)/divide(TWELVE_HUNDRED, 2, RoundingMode.HALF_UP)/' "$f"
  grep -n "RoundingMode.HALF_UP" "$f" | sed 's/^/    /'
  ./tools/run-java.sh nightly-batch 03-numeric-boundaries >/dev/null 2>&1 || true
  echo
  run ./tools/compare-outputs.py nightly-batch 03-numeric-boundaries || true
  echo
  echo "  ${BOLD}revert${RESET} (git keeps the real file):"
  git checkout -- "$f"

  local g=java/nightly-batch/src/main/java/com/example/poc/nightlybatch/batch/programs/IntCalcProgram.java
  echo
  echo "  ${BOLD}sabotage 2:${RESET} 'fix' the legacy bug — update the last account too (the ELSE that CBACT04C never reaches)"
  python3 - "$g" <<'PY'
import sys
p=sys.argv[1]; s=open(p).read()
m="            // COBOL: CBACT04C.cbl:219-221 — ELSE PERFORM 1050-UPDATE-ACCOUNT is unreachable:"
s=s.replace(m, "            if (!firstTime) calc.updateAccount(accountWs, totalInt);   // SABOTAGE: the 'obvious fix'\n"+m, 1)
open(p,"w").write(s)
PY
  grep -n "SABOTAGE" "$g" | sed 's/^/    /'
  ./tools/run-java.sh nightly-batch 01-happy-small >/dev/null 2>&1 || true
  echo
  run ./tools/compare-outputs.py nightly-batch 01-happy-small || true
  echo
  echo "  ${BOLD}revert${RESET} and restore green:"
  git checkout -- "$g"
  ./tools/run-java.sh nightly-batch >/dev/null 2>&1
  run ./tools/compare-outputs.py nightly-batch
}

conformance() {
  echo "${BOLD}════════════════════════════════════════════════════════════${RESET}"
  echo "${BOLD}  CONFORMANCE — did every module go through the same five phases with the same tooling?${RESET}"
  echo "${BOLD}════════════════════════════════════════════════════════════${RESET}"
  run ./tools/check-module.sh --all
}

proof() {
  echo "${BOLD}════════════════════════════════════════════════════════════${RESET}"
  echo "${BOLD}  PROOF — validation/reports/*.json — \"diffs\": [] is the contract${RESET}"
  echo "${BOLD}════════════════════════════════════════════════════════════${RESET}"
  for f in validation/reports/*.json; do
    local m; m="$(basename "$f" .json)"
    echo
    echo "${BOLD}--- $m ---${RESET}"
    python3 - "$f" <<'PY'
import json, sys
for e in json.load(open(sys.argv[1])):
    s = e.get("summary", {})
    status = "diffs: []" if not e.get("diffs") else f"diffs: {len(e['diffs'])}"
    print(f"  {e.get('fixture','?'):<26} {status:<10} records {s.get('records_compared',0):>5} · bytes {s.get('bytes_compared',0):>7} · differing {s.get('bytes_differing',0)}")
PY
  done
  echo
  echo "${GREEN}${BOLD}────────────────────────────────────────────────────────────${RESET}"
  ./tools/compare-outputs.py --summary | sed "s/^/${GREEN}${BOLD}  /; s/\$/${RESET}/"
  echo "${GREEN}${BOLD}────────────────────────────────────────────────────────────${RESET}"
}

case "${1:-}" in
  preflight) preflight ;;
  module-0)  module-0 ;;
  module-1b) module-1b ;;
  module-1a) module-1a ;;
  module-2)  module-2 ;;
  module-3)  module-3 ;;
  negative-control) negative-control ;;
  conformance) conformance ;;
  proof)     proof ;;
  all)       module-0; module-1b; module-1a; module-2; module-3; conformance; proof ;;
  *)
    cat >&2 <<EOF
usage: $0 {preflight|module-0|module-1b|module-1a|module-2|module-3|negative-control|conformance|proof|all} [--quiet]

  preflight         run ~30 min before demo: toolchain check + clean state + warm-up
  module-0          VSAM / file access (add-motor-policy)                 — 3 fixtures
  module-1b         DB2 / EXEC SQL → JPA (add-policy-db)                  — 2 fixtures
  module-1a         CICS LINK → Spring DI (add-policy-facade)             — 1 fixture
  module-2          Real BCP package: CCI ↔ BCP (BCTITSCV)                — 3 fixtures
  module-3          Nightly batch: 4-step JCL job, restart, abend (CardDemo) — 6 fixtures
  negative-control  two sabotages in module 3 → field-level red diff (one cent) and a divergent paragraph → revert
  conformance       tools/check-module.sh --all (same five phases, same tooling, every module)
  proof             validation/reports/*.json + cross-module summary (computed)
  all               all five modules + conformance + proof
  --quiet     suppress narrative phase headers (terse mode)
EOF
    exit 2
    ;;
esac
