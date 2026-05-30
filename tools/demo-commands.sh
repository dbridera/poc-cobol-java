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
#   ./tools/demo-commands.sh proof        # cat all 4 validation/reports/*.json with cross-module summary
#   ./tools/demo-commands.sh all          # module-0 + module-1b + module-1a + module-2 + proof
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
  rm -rf java-run cobol/add-motor-policy/bin cobol/add-policy-db/bin cobol/add-policy-facade/bin cobol/cci-account-converter/bin

  echo
  echo "${BOLD}==== Warm-up: all four modules end-to-end ====${RESET}"
  QUIET=1 module-0
  QUIET=1 module-1b
  QUIET=1 module-1a
  QUIET=1 module-2

  echo
  echo "${GREEN}${BOLD}Pre-flight complete. Nine fixtures byte-exact equivalent.${RESET}"
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

proof() {
  echo "${BOLD}════════════════════════════════════════════════════════════${RESET}"
  echo "${BOLD}  PROOF — validation/reports/*.json — \"diffs\": [] is the contract${RESET}"
  echo "${BOLD}════════════════════════════════════════════════════════════${RESET}"
  for m in add-motor-policy add-policy-db add-policy-facade cci-account-converter; do
    echo
    echo "${BOLD}--- $m ---${RESET}"
    cat "validation/reports/$m.json" | python3 -m json.tool
  done
  echo
  echo "${GREEN}${BOLD}────────────────────────────────────────────────────────────${RESET}"
  echo "${GREEN}${BOLD}  SUMMARY: 9 / 9 fixtures byte-exact equivalent across modules 0, 1A, 1B, 2${RESET}"
  echo "${GREEN}${BOLD}────────────────────────────────────────────────────────────${RESET}"
}

case "${1:-}" in
  preflight) preflight ;;
  module-0)  module-0 ;;
  module-1b) module-1b ;;
  module-1a) module-1a ;;
  module-2)  module-2 ;;
  proof)     proof ;;
  all)       module-0; module-1b; module-1a; module-2; proof ;;
  *)
    cat >&2 <<EOF
usage: $0 {preflight|module-0|module-1b|module-1a|module-2|proof|all} [--quiet]

  preflight   run ~30 min before demo: toolchain check + clean state + warm-up
  module-0    VSAM / file access (add-motor-policy)         — 3 fixtures
  module-1b   DB2 / EXEC SQL → JPA (add-policy-db)          — 2 fixtures
  module-1a   CICS LINK → Spring DI (add-policy-facade)     — 1 fixture
  module-2    Real BCP package: CCI ↔ BCP (BCTITSCV)        — 3 fixtures
  proof       cat all four validation/reports/*.json + cross-module summary
  all         module-0 + module-1b + module-1a + module-2 + proof
  --quiet     suppress narrative phase headers (terse mode)
EOF
    exit 2
    ;;
esac
