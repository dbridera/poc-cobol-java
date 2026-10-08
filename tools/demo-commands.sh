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
#   ./tools/demo-commands.sh agentic-eval [module]  # the equivalence-validator AGENT runs the validation headless (claude -p); --replay plays the recorded transcript
#   ./tools/demo-commands.sh explore [module]   # every artifact of a module as clickable links; type a number to open one
#   ./tools/demo-commands.sh conformance  # tools/check-module.sh --all: every module went through the same 5 phases
#   ./tools/demo-commands.sh proof        # validation/reports/*.json + cross-module summary (computed, not hard-coded)
#   ./tools/demo-commands.sh all          # module-0 + module-1b + module-1a + module-2 + module-3 + conformance + proof
#
# Flags (anywhere in the args):
#   --step    stage mode: pause for Enter after every explanation, before every command and before every "moment"
#   --en      narrate in English (default: Spanish — the deck is in Spanish)
#   --quiet   suppress the narrative (terse mode)
#   --replay  agentic-eval: replay docs/demo/transcripts/*.jsonl instead of calling claude (also the automatic fallback)
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
  GREEN=$'\033[32m'; CYAN=$'\033[36m'; YELLOW=$'\033[33m'; RED=$'\033[31m'
  BOLD=$'\033[1m';   DIM=$'\033[2m';   RESET=$'\033[0m'
else
  GREEN=""; CYAN=""; YELLOW=""; RED=""; BOLD=""; DIM=""; RESET=""
fi

QUIET=0; STEP=0; ES=1; REPLAY=0
ARGS=()
for a in "$@"; do
  case "$a" in
    --quiet)  QUIET=1 ;;
    --step)   STEP=1 ;;
    --en)     ES=0 ;;
    --es)     ES=1 ;;
    --replay) REPLAY=1 ;;
    *) ARGS+=("$a") ;;
  esac
done
set -- "${ARGS[@]:-}"

# ----- narrative helpers -----

# T "english" "español" → the text in the narration language
T() { if [[ $ES -eq 1 ]]; then printf '%s' "$2"; else printf '%s' "$1"; fi; }

# have_tty: a terminal we can read from (false under a pipe-only runner such as CI)
have_tty() { ( : < /dev/tty ) 2>/dev/null; }

# pause: in --step mode wait for Enter (read from the terminal, so it works inside pipes too)
pause() {
  [[ $STEP -eq 1 && $QUIET -eq 0 ]] || return 0
  have_tty || return 0
  printf '%s' "${DIM}  ⏎ $(T 'Enter to continue' 'Enter para continuar')${RESET}"
  read -r _ < /dev/tty || true
  printf '\r\033[K'
}

# module_header "0" "title" "add-motor-policy" "stakeholder question"
module_header() {
  local n="$1" title="$2" mod="$3" concern="$4"
  if [[ $QUIET -eq 1 ]]; then echo "==== $(T 'Module' 'Módulo') $n — $title ($mod) ===="; return; fi
  echo
  echo "${CYAN}${BOLD}════════════════════════════════════════════════════════════${RESET}"
  echo "${CYAN}${BOLD}  $(T 'MODULE' 'MÓDULO') $n — $title ($mod)${RESET}"
  echo "${CYAN}  $(T 'Answers the stakeholder concern' 'Responde a la pregunta del banco'): \"$concern\"${RESET}"
  echo "${CYAN}${BOLD}════════════════════════════════════════════════════════════${RESET}"
  pause
}

# phase "A" "title" "what we do" "why it matters" "output path"  — pauses before the command that follows
phase() {
  local letter="$1" title="$2" what="$3" why="$4" output="$5"
  if [[ $QUIET -eq 1 ]]; then return; fi
  echo
  echo "${YELLOW}${BOLD}▶ $(T 'PHASE' 'FASE') $letter — $title${RESET}"
  echo "${DIM}  $(T 'what' 'qué '): $what${RESET}"
  echo "${DIM}  $(T 'why ' 'por qué'): $why${RESET}"
  echo "${DIM}  → $(T 'output' 'salida'): $output${RESET}"
  echo
  pause
}

# moment "title" "line 1" ["line 2" ...] — a narrated highlight, pauses before showing it
moment() {
  local title="$1"; shift
  [[ $QUIET -eq 1 ]] && return 0
  echo
  echo "${CYAN}${BOLD}  $(T 'MOMENT' 'MOMENTO') — $title${RESET}"
  local l; for l in "$@"; do echo "${DIM}    $l${RESET}"; done
  pause
}

# run with the command echoed
run() {
  if [[ $QUIET -eq 0 ]]; then echo "  ${BOLD}\$ $*${RESET}"; fi
  "$@"
}

# result_summary "0" "Module 0" "3" "3" "channels" "finding"
result_summary() {
  local mod_id="$1" mod_label="$2" passed="$3" total="$4" channels="$5" finding="$6"
  if [[ $QUIET -eq 1 ]]; then return; fi
  local mark="${GREEN}✅${RESET}"
  [[ "$passed" != "$total" ]] && mark="${YELLOW}⚠${RESET}"
  echo
  echo "${GREEN}────────────────────────────────────────────────────────────${RESET}"
  echo "${GREEN}${BOLD}  $(T 'RESULT' 'RESULTADO') — $mod_label: $passed / $total $(T 'fixtures byte-exact equivalent' 'casos de prueba idénticos byte a byte')${RESET} $mark"
  echo "${GREEN}  $(T 'channels diffed' 'canales comparados'): $channels${RESET}"
  echo "${GREEN}  $(T 'bytes diverging' 'bytes distintos'): 0${RESET}"
  echo "${GREEN}  $(T 'empirical finding codified' 'hallazgo codificado en el harness'): $finding${RESET}"
  echo "${GREEN}────────────────────────────────────────────────────────────${RESET}"
}

# red_lines <file>: print, in red and alone, the comparator lines that name the divergence
red_lines() {
  local hits
  hits="$(grep -E "record [0-9]+ \(|trace: first divergence|^\[FAIL" "$1" | awk '!seen[$0]++' | head -6 || true)"
  [[ -z "$hits" ]] && return 0
  echo
  echo "  ${BOLD}$(T 'In one line — what the agentic eval says is wrong:' 'En una línea — qué dice el agentic eval que está mal:')${RESET}"
  echo "$hits" | sed "s/^/${RED}${BOLD}    /; s/\$/${RESET}/"
}

# link <relative path> → OSC-8 hyperlink (clickable in Terminal.app / iTerm2 / VS Code terminal)
link() { printf '\e]8;;file://%s\e\\%s\e]8;;\e\\' "$REPO_ROOT/$1" "$1"; }

# open_path <path>: directories and html in Finder/browser; text in the editor when `code` exists
open_path() {
  local p="$1"
  if [[ -d "$p" || "$p" == *.html ]]; then open "$p"
  elif command -v code >/dev/null 2>&1; then code -r "$p"
  else open "$p"; fi
}

# links "label|path" ... : list the intermediate artifacts of a step as clickable links;
# in --step mode a number opens one (Enter continues). Missing paths are skipped.
links() {
  [[ $QUIET -eq 1 ]] && return 0
  local it label path n=0; local -a paths=()
  for it in "$@"; do
    label="${it%%|*}"; path="${it#*|}"
    [[ -e "$path" ]] || continue
    paths+=("$path"); n=$((n+1))
    printf '    %s%2d%s  %s  %s%s%s\n' "$BOLD" "$n" "$RESET" "$(link "$path")" "$DIM" "$label" "$RESET"
  done
  [[ $n -eq 0 ]] && return 0
  if [[ $STEP -eq 1 ]] && have_tty; then
    local choice
    while true; do
      printf '%s' "${DIM}  $(T 'number to open, Enter to continue' 'número para abrir, Enter para seguir'): ${RESET}"
      read -r choice < /dev/tty || break
      [[ -z "$choice" ]] && break
      if [[ "$choice" =~ ^[0-9]+$ && "$choice" -ge 1 && "$choice" -le $n ]]; then open_path "${paths[$((choice-1))]}"; fi
    done
    printf '\r\033[K'
  fi
}

# links_for <module> <A|C|D|all>: the artifacts a phase leaves behind, in the order the story needs them
links_for() {
  local m="$1" ph="$2" first_gm first_jr; local -a items=()
  first_gm="$(ls -d golden-master/$m/*/ 2>/dev/null | head -1)"; first_gm="${first_gm%/}"
  first_jr="$(ls -d java-run/$m/*/ 2>/dev/null | head -1)"; first_jr="${first_jr%/}"
  echo
  echo "  ${BOLD}$(T 'Intermediate artifacts' 'Artefactos intermedios') ($(T 'click, or a number in --step mode' 'clic, o número en modo --step')):${RESET}"
  if [[ "$ph" == A || "$ph" == all ]]; then
    items+=("$(T 'the COBOL as the bank runs it (verbatim)' 'el COBOL tal como lo corre el banco (sin tocar)')|cobol/$m/src"
            "$(T 'the copybooks (record layouts)' 'los copybooks (diseños de registro)')|cobol/$m/copybooks"
            "$(T 'job manifest: steps, datasets, return codes' 'manifiesto del trabajo: pasos, archivos, códigos de retorno')|cobol/$m/job.json"
            "$(T 'what each program does + dependency graph' 'qué hace cada programa + grafo de dependencias')|cobol/$m/DEPENDENCIES.md"
            "$(T 'dependency graph (html)' 'grafo de dependencias (html)')|cobol/$m/dependency-graph.html"
            "$(T 'spec for the bank analyst (rules, numerics, questions)' 'especificación para el analista del banco (reglas, numérica, preguntas)')|specs/$m.md"
            "$(T 'what each paragraph does' 'qué hace cada párrafo')|cobol/$m/PARAGRAPHS.md"
            "$(T 'test cases (inputs + expectations)' 'casos de prueba (entradas + qué se espera)')|cobol/$m/fixtures"
            "$(T 'COBOL reference output, first case' 'salida de referencia del COBOL, primer caso')|$first_gm")
  fi
  if [[ "$ph" == C || "$ph" == all ]]; then
    items+=("$(T 'the Java translation (every method cites its COBOL lines)' 'la traducción Java (cada método cita sus líneas COBOL)')|java/$m/src/main/java"
            "$(T 'Java output, first case' 'salida del Java, primer caso')|$first_jr")
  fi
  if [[ "$ph" == D || "$ph" == all ]]; then
    items+=("$(T 'agentic eval report (diffs: [] is the contract)' 'informe del agentic eval (diffs: [] es el contrato)')|validation/reports/$m.json"
            "$(T 'COBOL ↔ Java side-by-side viewer' 'visor lado a lado COBOL ↔ Java')|cobol/$m/traceability.html"
            "$(T 'paragraph coverage, generated from the traces' 'cobertura por párrafo, generada desde las trazas')|cobol/$m/COVERAGE.md"
            "$(T 'decisions taken along the way (ADRs)' 'decisiones tomadas en el camino (ADR)')|docs/methodology/DECISIONS.md")
  fi
  links "${items[@]}"
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
  show_version "claude --version" claude --version

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
  module_header "0" "$(T 'VSAM / file access' 'Archivos VSAM: alta de pólizas en lote')" "add-motor-policy" \
    "$(T 'how do you handle VSAM?' '¿cómo manejan los archivos VSAM?')"

  phase "A" "$(T 'Capture legacy ground truth' 'Capturar la salida de referencia del COBOL')" \
    "$(T 're-run original COBOL on GnuCOBOL against 3 test fixtures' 'correr el COBOL original en GnuCOBOL con 3 casos de prueba')" \
    "$(T 'every byte of COBOL output becomes the contract' 'cada byte que produce el COBOL pasa a ser el contrato')" \
    "golden-master/add-motor-policy/"
  run ./tools/run-cobol.sh add-motor-policy

  links_for add-motor-policy A
  phase "C" "$(T 'Exercise the previously-translated Java' 'Correr el Java ya traducido')" \
    "$(T 'build + run Spring Boot 3 / Java 21 / BigDecimal translation' 'compilar y correr la traducción: Spring Boot 3, Java 21, BigDecimal')" \
    "$(T 'prove the Java behaves the same as the COBOL we just captured' 'el Java ya está escrito y revisado; nada se traduce en vivo')" \
    "java-run/add-motor-policy/"
  run ./tools/run-java.sh add-motor-policy

  links_for add-motor-policy C
  phase "D" "$(T 'Byte-exact validation (THE contract)' 'Agentic eval: comparación byte a byte (el contrato)')" \
    "$(T 'diff every byte of every output channel between COBOL and Java' 'comparar cada byte de cada canal de salida entre COBOL y Java')" \
    "$(T '0 diffs = behavioral equivalence proven; non-zero = stop and investigate' '0 diferencias = mismo comportamiento; cualquier otra cosa = parar e investigar')" \
    "validation/reports/add-motor-policy.json"
  run ./tools/compare-outputs.py add-motor-policy

  links_for add-motor-policy D
  result_summary "0" "$(T 'Module 0 (VSAM)' 'Módulo 0 (VSAM)')" "3" "3" \
    "stdout · exit_code · policy.dat · motor.dat · error.log" \
    "$(T 'COBOL ROUNDED defaults to HALF_UP, not HALF_EVEN (ADR-4)' 'el ROUNDED del COBOL redondea HALF_UP, no HALF_EVEN como Java por defecto (ADR-4)')"
}

module-1b() {
  module_header "1B" "$(T 'DB2 / EXEC SQL → JPA + H2' 'Base de datos DB2: guardar la póliza')" "add-policy-db" \
    "$(T 'how do you handle DB2 / databases?' '¿cómo manejan DB2 y las bases de datos?')"

  phase "A" "$(T 'Capture legacy ground truth (DB state)' 'Capturar la salida de referencia (estado de la base)')" \
    "$(T 're-run COBOL → SQLite via libcob_sqlite shim, dump POLICY table' 'correr el COBOL contra SQLite (reemplazo de DB2) y volcar la tabla POLICY')" \
    "$(T 'the dumped table IS the observable output — same harness, DB-aware' 'la tabla volcada es la salida observable: mismo harness, consciente de la base')" \
    "golden-master/add-policy-db/"
  run ./tools/run-cobol-db.sh add-policy-db

  links_for add-policy-db A
  phase "C" "$(T 'Exercise the Java translation (Spring + JPA + H2)' 'Correr la traducción Java (Spring + JPA + H2)')" \
    "$(T 'EntityManager.persist + flush inside @Transactional(REQUIRES_NEW)' 'inserción explícita con transacción propia por solicitud')" \
    "$(T 'JPA against H2; one tx per request — matches CICS pattern' 'una transacción por solicitud, como en CICS')" \
    "java-run/add-policy-db/"
  run ./tools/run-java.sh add-policy-db

  links_for add-policy-db C
  phase "D" "$(T 'Byte-exact validation (stdout + DB table dump)' 'Agentic eval: pantalla + volcado de la tabla')" \
    "$(T 'diff stdout + policy.csv between COBOL and Java' 'comparar la pantalla y policy.csv entre COBOL y Java')" \
    "$(T 'fixture 02 has a duplicate PK — exercises the SQL-error path' 'el caso 02 inserta una clave repetida: tiene que fallar como en el mainframe')" \
    "validation/reports/add-policy-db.json"
  run ./tools/compare-outputs.py add-policy-db

  links_for add-policy-db D
  result_summary "1B" "$(T 'Module 1B (DB2)' 'Módulo 1B (DB2)')" "2" "2" \
    "stdout · exit_code · policy.csv" \
    "$(T 'JpaRepository.save is MERGE not INSERT — use em.persist+flush (ADR-9)' 'el save de JPA es MERGE, no INSERT: una clave repetida no fallaría; se usa persist + flush (ADR-9)')"
}

module-1a() {
  module_header "1A" "$(T 'CICS LINK → Spring service-to-service DI' 'Orquestación CICS: la fachada que llama a otro programa')" "add-policy-facade" \
    "$(T 'how do you handle the COBOL orchestrator?' '¿cómo manejan un programa que invoca a otro (CICS LINK)?')"

  phase "A" "$(T 'Capture chained legacy output' 'Capturar la salida encadenada del COBOL')" \
    "$(T 'outer COBOL facade CALLs nested DB program (GnuCOBOL stand-in for EXEC CICS LINK)' 'la fachada COBOL llama al programa de base de datos (reemplazo GnuCOBOL del EXEC CICS LINK)')" \
    "$(T 'control + payload + return code propagate the same way Spring DI does' 'control, datos y código de retorno viajan igual que entre servicios Spring')" \
    "golden-master/add-policy-facade/"
  run ./tools/run-cobol-db.sh add-policy-facade

  links_for add-policy-facade A
  phase "C" "$(T 'Exercise the Java service chain' 'Correr la cadena de servicios Java')" \
    "PolicyFacadeService → PolicyInsertService" \
    "$(T 'CICS LINK collapses to Spring DI; @Transactional sits on the inner service' 'el CICS LINK se vuelve inyección de dependencias; la transacción vive en el servicio interno')" \
    "java-run/add-policy-facade/"
  run ./tools/run-java.sh add-policy-facade

  links_for add-policy-facade C
  phase "D" "$(T 'Byte-exact validation (chained output)' 'Agentic eval: salida encadenada')" \
    "$(T 'diff stdout from BOTH levels + the resulting POLICY table' 'comparar la pantalla de los dos niveles y la tabla POLICY resultante')" \
    "$(T 'proves the two-program chain preserves observable behavior end-to-end' 'prueba que la cadena de dos programas conserva el comportamiento de punta a punta')" \
    "validation/reports/add-policy-facade.json"
  run ./tools/compare-outputs.py add-policy-facade

  links_for add-policy-facade D
  result_summary "1A" "$(T 'Module 1A (CICS LINK)' 'Módulo 1A (CICS LINK)')" "1" "1" \
    "stdout · exit_code · policy.csv" \
    "$(T 'EXEC CICS LINK → same-JVM Spring DI for this PoC scope (ADR-10)' 'EXEC CICS LINK → servicios Spring en la misma JVM para este alcance (ADR-10)')"
}

module-2() {
  module_header "2" "$(T 'Real banking module — CCI ↔ BCP converter' 'Módulo bancario real: convertidor CCI ↔ BCP')" "cci-account-converter" \
    "$(T 'does this work on a real legacy program, not just GenApp?' '¿funciona con un programa real, no solo con ejemplos?')"

  phase "A" "$(T 'Capture legacy ground truth' 'Capturar la salida de referencia del COBOL')" \
    "$(T 'run the adapted Banco de Crédito del Perú BCTITSCV on GnuCOBOL across 3 fixtures' 'correr el BCTITSCV adaptado del Banco de Crédito del Perú en GnuCOBOL con 3 casos')" \
    "$(T 'real Spanish-language COBOL with mod-10 check-digit math — same harness, no special casing' 'COBOL real en castellano con dígito verificador módulo 10: mismo harness, sin casos especiales')" \
    "golden-master/cci-account-converter/"
  run ./tools/run-cobol.sh cci-account-converter

  links_for cci-account-converter A
  phase "C" "$(T 'Exercise the Java translation' 'Correr la traducción Java')" \
    "$(T 'Spring Boot 3 + Java 21 + BigDecimal everywhere (loop indices and digit accumulators too)' 'Spring Boot 3 + Java 21 + BigDecimal en todo, incluso índices y acumuladores de dígitos')" \
    "$(T 'check digits use RoundingMode.DOWN for integer division and .remainder(TEN) for PIC 9(01) truncation' 'la división entera trunca (DOWN) y el PIC 9(01) se queda con el último dígito')" \
    "java-run/cci-account-converter/"
  run ./tools/run-java.sh cci-account-converter

  links_for cci-account-converter C
  phase "D" "$(T 'Byte-exact validation (stdout + exit_code)' 'Agentic eval: pantalla + código de salida')" \
    "$(T 'diff every byte of the per-call output block (RC / MSG / FAM-RET / BCP-EDIT / CUENTA-ITE)' 'comparar cada byte del bloque de salida por llamada')" \
    "$(T 'fixture 02 exercises the mod-10 check-digit calculation end-to-end' 'el caso 02 ejercita el dígito verificador de punta a punta')" \
    "validation/reports/cci-account-converter.json"
  run ./tools/compare-outputs.py cci-account-converter

  links_for cci-account-converter D
  result_summary "2" "$(T 'Module 2 (real BCP package)' 'Módulo 2 (paquete BCP real)')" "3" "3" \
    "stdout · exit_code" \
    "$(T 'Integer division uses RoundingMode.DOWN, not HALF_UP (ADR-11) + PIC narrow-store truncation as algorithm (ADR-12)' 'la división entera trunca, no redondea (ADR-11); el truncado al guardar en un PIC chico es parte del algoritmo (ADR-12)')"
}

module-3() {
  module_header "3" "$(T 'Nightly batch — 4-step JCL job (AWS CardDemo)' 'Cierre nocturno: trabajo JCL de 4 pasos (AWS CardDemo)')" "nightly-batch" \
    "$(T 'how do you handle real batch: JCL steps, VSAM updated in place, sorts, restart after a crash, abends?' '¿cómo manejan un batch real: pasos JCL, archivos actualizados en el lugar, ordenamientos, reanudación tras una caída?')"

  phase "A" "$(T 'Capture the legacy job, step by step' 'Capturar el trabajo COBOL, paso a paso')" \
    "$(T 'run the 16-step job on GnuCOBOL for 6 fixtures: 6 KSDS loads → POSTTRAN → backup → INTCALC → sort+reload → unload+sort+report → 2 capture unloads' 'correr el trabajo de 16 pasos en GnuCOBOL con 6 casos: cargas → contabilizar → respaldo → intereses → ordenar y recargar → descargar, ordenar y reporte → capturas')" \
    "$(T 'every step'"'"'s stdout + RC, the job log and the 9 datasets the job leaves behind are the contract — one fixture is killed after step 2 and resumed' 'la pantalla y el código de cada paso, el registro del trabajo y los 9 archivos que deja son el contrato; un caso se mata después del paso 2 y se reanuda')" \
    "golden-master/nightly-batch/"
  run ./tools/run-job.sh nightly-batch

  links_for nightly-batch A
  phase "C" "$(T 'Exercise the Spring Batch translation' 'Correr la traducción a Spring Batch')" \
    "$(T 'the same job.json drives one Spring Batch Step per JCL step; KSDS files are H2 tables via JDBC; BigDecimal with DOWN where COBOL truncates' 'el mismo job.json maneja un paso Spring Batch por paso JCL; los archivos indexados son tablas H2; BigDecimal truncando donde el COBOL trunca')" \
    "$(T 'restart = JobRepository skipping COMPLETED steps across two JVM runs; abend = RC 12 and NOT RUN steps, capture unloads still run' 'reanudar = saltar los pasos ya completados en una segunda corrida; caída = código 12 y pasos NOT RUN, las capturas igual corren')" \
    "java-run/nightly-batch/"
  run ./tools/run-java.sh nightly-batch

  links_for nightly-batch C
  phase "D" "$(T 'Byte-exact validation — up to 60 files per fixture' 'Agentic eval: hasta 60 archivos por caso, byte a byte')" \
    "$(T 'diff fixed-length binary datasets (overpunched signs included) with record/field reporting, per-step stdout, RC, the job log and the paragraph trace' 'comparar los archivos binarios de largo fijo (signos del mainframe incluidos) con informe por registro y campo, la pantalla y el código de cada paso, el registro del trabajo y la traza de párrafos')" \
    "$(T 'fixture 05 proves killed-and-resumed ≡ unbroken; fixture 03 holds the numeric edge cases; fixture 06 the abend' 'el caso 05 prueba que matar y reanudar da lo mismo que no cortar; el 03 tiene los bordes numéricos; el 06 la caída')" \
    "validation/reports/nightly-batch.json"
  run ./tools/compare-outputs.py nightly-batch

  links_for nightly-batch D
  if [[ $QUIET -eq 0 ]]; then
    moment "$(T 'restart: the job log of fixture 05 (killed after INTCALC, resumed)' 'reanudación: el registro del caso 05 (matado después de INTCALC, reanudado)')" \
      "$(T 'outputs identical to the unbroken run (check-module.sh enforces it) — on both sides' 'las salidas son idénticas a la corrida sin corte (check-module.sh lo exige), en COBOL y en Java')"
    grep -vE "RC=0000$" golden-master/nightly-batch/05-restart/out/run-log.txt | sed 's/^/    /'

    moment "$(T 'the faithful bug: last account after INTCALC (fixture 01, golden master)' 'el defecto fiel: la última cuenta después de INTCALC (caso 01, salida de referencia)')" \
      "$(T 'CBACT04C.cbl:219-221 — the ELSE that would update the last account never runs: interest transaction written, balance untouched, cycle totals not reset.' 'CBACT04C.cbl:219-221 — el ELSE que actualizaría la última cuenta nunca corre: la transacción de interés se escribe, el saldo no cambia, los acumulados no se reinician.')" \
      "$(T 'The Java reproduces it (CLAUDE.md rule 5); the spec asks the bank what to do with it.' 'El Java lo reproduce (regla 5 del harness); la especificación le pregunta al banco qué hacer con él.')"
    ./tools/make-fixture.py --dump carddemo_account golden-master/nightly-batch/01-happy-small/out/acctfile.unl \
      | tail -1 | python3 -c "import sys,json; r=json.loads(sys.stdin.read()); print('    $(T 'account' 'cuenta')', r['ACCT-ID'], '$(T 'balance' 'saldo')', r['ACCT-CURR-BAL'], '$(T 'cycle credit' 'crédito del ciclo')', r['ACCT-CURR-CYC-CREDIT'], '$(T 'cycle debit' 'débito del ciclo')', r['ACCT-CURR-CYC-DEBIT'])"
    echo "${DIM}    $(T 'where it is written down:' 'dónde está escrito:')${RESET}"
    grep -n "D1" specs/nightly-batch.md | head -2 | sed 's/^/      specs\/nightly-batch.md:/'
    grep -n "1050-UPDATE-ACCOUNT" cobol/nightly-batch/PARAGRAPHS.md | head -1 | cut -c1-160 | sed 's/^/      PARAGRAPHS.md:/'
    grep -rn "CBACT04C.cbl:219-221" java/nightly-batch/src/main/java | head -1 | sed 's|java/nightly-batch/src/main/java/com/example/poc/nightlybatch/||; s/^/      /'

    moment "$(T 'did we translate everything? (paragraph traces, coverage, side-by-side viewer)' '¿tradujimos todo? (traza de párrafos, cobertura, visor lado a lado)')" \
      "$(T 'Every paragraph GnuCOBOL enters is traced; the Java emits the same trace and it is part of the diff.' 'Cada párrafo que entra el COBOL queda en la traza; el Java emite la misma traza y es parte de la comparación.')"
    grep -A3 "BEGIN AUTO-GENERATED COVERAGE" cobol/nightly-batch/README.md | grep -v "^<!--" | sed 's/^/    /'
    echo "    $(T 'viewer' 'visor'): cobol/nightly-batch/traceability.html"
    echo "${DIM}    $(T 'on stage: click a paragraph on the left → the Java that translates it on the right; read its "Qué hace" line' 'en escena: clic en un párrafo a la izquierda → el Java que lo traduce a la derecha; leer su línea "Qué hace"')${RESET}"
    if [[ "$(uname)" == "Darwin" ]]; then open cobol/nightly-batch/traceability.html 2>/dev/null || true; fi
    pause
  fi

  result_summary "3" "$(T 'Module 3 (nightly batch, 4 JCL steps)' 'Módulo 3 (cierre nocturno, 4 pasos JCL)')" "6" "6" \
    "per-step stdout · $(T 'paragraph traces' 'traza de párrafos') · exit_code (MAXRC) · run-log.txt · dalyrejs · tranbkp · systran · combined · tranbkp2 · trandaly · tranrept · acctfile.unl · tcatbal.unl" \
    "$(T 'JCL step = Spring Batch step with step-level restart (ADR-14) · JDBC not JPA for record-at-a-time batch (ADR-13) · COMPUTE without ROUNDED truncates toward zero · faithful defects replicated, never fixed' 'paso JCL = paso Spring Batch con reanudación (ADR-14) · JDBC y no JPA para batch registro a registro (ADR-13) · COMPUTE sin ROUNDED trunca hacia cero · los defectos fieles se replican, nunca se arreglan')"
}

negative-control() {
  module_header "NC" "$(T 'Negative control — does the harness bite?' 'Control negativo: ¿el harness muerde?')" "nightly-batch" \
    "$(T 'how do we know the diff would catch a translation that is wrong by one cent?' '¿cómo sabemos que la comparación atraparía una traducción equivocada en un centavo?')"
  local f=java/nightly-batch/src/main/java/com/example/poc/nightlybatch/service/InterestCalculator.java
  local out; out="$(mktemp)"
  echo
  echo "  ${BOLD}$(T 'sabotage 1:' 'sabotaje 1:')${RESET} $(T 'RoundingMode.DOWN → HALF_UP in InterestCalculator.monthlyInterest — one token, the kind of change a reviewer would wave through' 'RoundingMode.DOWN → HALF_UP en InterestCalculator.monthlyInterest: una palabra, el cambio que un revisor dejaría pasar')"
  pause
  sed -i '' 's/divide(TWELVE_HUNDRED, 2, RoundingMode.DOWN)/divide(TWELVE_HUNDRED, 2, RoundingMode.HALF_UP)/' "$f"
  git --no-pager diff --color=always -U1 -- "$f" | tail -n +5 | sed 's/^/    /'
  ./tools/run-java.sh nightly-batch 03-numeric-boundaries >/dev/null 2>&1 || true
  echo
  run ./tools/compare-outputs.py nightly-batch 03-numeric-boundaries 2>&1 | tee "$out" || true
  red_lines "$out"
  echo
  echo "  ${BOLD}$(T 'revert' 'revertir')${RESET} $(T '(git keeps the real file):' '(git conserva el archivo real):')"
  pause
  git checkout -- "$f"

  local g=java/nightly-batch/src/main/java/com/example/poc/nightlybatch/batch/programs/IntCalcProgram.java
  echo
  echo "  ${BOLD}$(T 'sabotage 2:' 'sabotaje 2:')${RESET} $(T "'fix' the legacy bug — update the last account too (the ELSE that CBACT04C never reaches)" "'arreglar' el defecto del COBOL: actualizar también la última cuenta (el ELSE al que CBACT04C nunca llega)")"
  pause
  python3 - "$g" <<'PY'
import sys
p=sys.argv[1]; s=open(p).read()
m="            // COBOL: CBACT04C.cbl:219-221 — ELSE PERFORM 1050-UPDATE-ACCOUNT is unreachable:"
s=s.replace(m, "            if (!firstTime) calc.updateAccount(accountWs, totalInt);   // SABOTAGE: the 'obvious fix'\n"+m, 1)
open(p,"w").write(s)
PY
  git --no-pager diff --color=always -U1 -- "$g" | tail -n +5 | sed 's/^/    /'
  ./tools/run-java.sh nightly-batch 01-happy-small >/dev/null 2>&1 || true
  echo
  run ./tools/compare-outputs.py nightly-batch 01-happy-small 2>&1 | tee "$out" || true
  red_lines "$out"
  echo
  echo "  ${BOLD}$(T 'revert' 'revertir')${RESET} $(T 'and restore green:' 'y volver al verde:')"
  pause
  git checkout -- "$g"
  ./tools/run-java.sh nightly-batch >/dev/null 2>&1
  run ./tools/compare-outputs.py nightly-batch

  rm -f "$out"
}

# agentic-eval [module]: the validation run by the equivalence-validator agent, headless (claude -p),
# rendered for the stage; --replay (or no `claude`, or a failed call) plays the recorded transcript.
agentic-eval() {
  local m="${1:-nightly-batch}"
  local transcript="docs/demo/transcripts/agentic-eval-$m.jsonl"
  module_header "AE" "$(T 'Agentic eval — the validator is an agent' 'Agentic eval: el validador es un agente')" "$m" \
    "$(T 'who runs the verification, and what can it touch?' '¿quién corre la verificación y qué puede tocar?')"
  if [[ $QUIET -eq 0 ]]; then
    echo
    echo "  ${BOLD}$(T 'the agent, as versioned in the repo:' 'el agente, tal como está versionado en el repo:')${RESET} .claude/agents/equivalence-validator.md"
    echo "${DIM}$(sed -n '/^tools:/p; /^## Constraints/,$p' .claude/agents/equivalence-validator.md | sed 's/^/    /')${RESET}"
    echo
    echo "  ${BOLD}$(T 'what it is allowed to run (nothing else):' 'qué puede ejecutar (nada más):')${RESET} run-cobol.sh · run-java.sh · compare-outputs.py · cat/tail/python3 $(T 'to read the report' 'para leer el informe')"
    echo "  ${BOLD}$(T 'how it is launched:' 'cómo se lanza:')${RESET} claude -p \"…\" --agent equivalence-validator --output-format stream-json"
    echo "${DIM}  $(T 'What you will see: what the agent says, the commands it runs, the tail of each result, and its final report. Nothing is scripted; the agent decides the order.' 'Lo que van a ver: lo que el agente dice, los comandos que corre, el final de cada resultado y su informe. Nada está guionado; el agente decide el orden.')${RESET}"
    pause
  fi
  local allowed="Bash(./tools/run-cobol.sh:*),Bash(./tools/run-cobol-db.sh:*),Bash(./tools/run-java.sh:*),Bash(./tools/compare-outputs.py:*),Bash(tail:*),Bash(cat:*),Bash(echo:*),Bash(python3:*),Bash(ls:*),Read,Grep"
  local prompt
  prompt="$(T "Validate the module $m and report." "Validá el módulo $m e informá. Escribí tus mensajes y el informe final en castellano; mantené el formato de salida del agente (líneas [OK]/[FAIL], RESULT: GREEN o RESULT: RED).")"
  local live_ok=0
  if [[ $REPLAY -eq 0 ]] && command -v claude >/dev/null 2>&1; then
    local fresh; fresh="$(mktemp)"
    echo "  ${BOLD}\$ claude -p \"$prompt\" --agent equivalence-validator --output-format stream-json${RESET}"
    if env -u CLAUDECODE claude -p "$prompt" --agent equivalence-validator --output-format stream-json --verbose \
         --max-turns 30 --allowedTools "$allowed" < /dev/null 2>/dev/null | tee "$fresh" | ./tools/demo-agentic-eval.py --lang "$(T en es)"; then
      live_ok=1
    fi
    if [[ $live_ok -eq 1 ]]; then
      [[ -n "${RECORD:-}" ]] && { mkdir -p "$(dirname "$transcript")"; cp "$fresh" "$transcript"; echo "${DIM}  $(T 'recorded to' 'grabado en') $transcript${RESET}"; }
    else
      echo "${YELLOW}  $(T 'live call did not finish green — replaying the recorded transcript' 'la llamada en vivo no terminó en verde; se reproduce la transcripción grabada')${RESET}"
    fi
    rm -f "$fresh"
  fi
  if [[ $live_ok -eq 0 ]]; then
    if [[ ! -f "$transcript" ]]; then echo "${RED}  $(T 'no recorded transcript at' 'no hay transcripción grabada en') $transcript${RESET}"; return 1; fi
    echo "  ${BOLD}$(T 'replay of' 'reproducción de') $transcript${RESET} ${DIM}($(T 'recorded' 'grabada') $(git log -1 --format=%cd --date=short -- "$transcript" 2>/dev/null || echo '-'))${RESET}"
    ./tools/demo-agentic-eval.py "$transcript" --pace 0.8 --lang "$(T en es)" || true
  fi
  echo
  echo "${GREEN}${BOLD}  $(T 'The agent ran both sides and compared them; a person reads the report and signs the green.' 'El agente corrió los dos lados y los comparó; una persona lee el informe y firma el verde.')${RESET}"
}

# explore <module>: the whole trail of artifacts of a module, to open and read on stage
explore() {
  local m="${1:-nightly-batch}"
  [[ -d "cobol/$m" ]] || { echo "${RED}no such module: $m${RESET}"; return 1; }
  echo "${BOLD}════════════════════════════════════════════════════════════${RESET}"
  echo "${BOLD}  $(T 'EXPLORE' 'EXPLORAR') — $m — $(T 'everything the harness left behind, in reading order' 'todo lo que el harness dejó, en orden de lectura')${RESET}"
  echo "${BOLD}════════════════════════════════════════════════════════════${RESET}"
  STEP=1 links_for "$m" all
}

conformance() {
  echo "${BOLD}════════════════════════════════════════════════════════════${RESET}"
  echo "${BOLD}  $(T 'CONFORMANCE — did every module go through the same five phases with the same tooling?' 'CHECKLIST DE PROCESO — ¿todos los módulos pasaron por las mismas cinco fases con las mismas herramientas?')${RESET}"
  echo "${BOLD}════════════════════════════════════════════════════════════${RESET}"
  pause
  run ./tools/check-module.sh --all
}

proof() {
  echo "${BOLD}════════════════════════════════════════════════════════════${RESET}"
  echo "${BOLD}  $(T 'PROOF — validation/reports/*.json — "diffs": [] is the contract' 'PRUEBA — validation/reports/*.json — "diffs": [] es el contrato')${RESET}"
  echo "${BOLD}════════════════════════════════════════════════════════════${RESET}"
  pause
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
  if [[ $ES -eq 1 ]]; then
    python3 - <<'PY' | sed "s/^/${GREEN}${BOLD}  /; s/\$/${RESET}/"
import json, glob
fx = rec = byt = dif = 0
for f in glob.glob("validation/reports/*.json"):
    for e in json.load(open(f)):
        s = e.get("summary", {}); fx += 1
        rec += s.get("records_compared", 0); byt += s.get("bytes_compared", 0); dif += s.get("bytes_differing", 0)
print(f"En castellano: {fx} casos de prueba · {rec:,} registros y {byt/1e6:.2f} MB comparados · {dif} bytes distintos".replace(",", "."))
PY
  fi
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
  agentic-eval) agentic-eval "${2:-nightly-batch}" ;;
  explore)   explore "${2:-nightly-batch}" ;;
  conformance) conformance ;;
  proof)     proof ;;
  all)       module-0; module-1b; module-1a; module-2; module-3; conformance; proof ;;
  *)
    cat >&2 <<EOF
usage: $0 {preflight|module-0|module-1b|module-1a|module-2|module-3|negative-control|agentic-eval [module]|explore [module]|conformance|proof|all} [--step] [--en] [--quiet] [--replay]

  preflight         run ~30 min before demo: toolchain check + clean state + warm-up
  module-0          VSAM / file access (add-motor-policy)                 — 3 fixtures
  module-1b         DB2 / EXEC SQL → JPA (add-policy-db)                  — 2 fixtures
  module-1a         CICS LINK → Spring DI (add-policy-facade)             — 1 fixture
  module-2          Real BCP package: CCI ↔ BCP (BCTITSCV)                — 3 fixtures
  module-3          Nightly batch: 4-step JCL job, restart, abend (CardDemo) — 6 fixtures
  negative-control  two sabotages in module 3 → field-level red diff (one cent) and a divergent paragraph → revert
  agentic-eval      the equivalence-validator agent validates a module headless (claude -p), rendered live; --replay plays the recording
  explore           list every artifact of a module as clickable links; a number opens it (viewer, spec, report, outputs…)
  conformance       tools/check-module.sh --all (same five phases, same tooling, every module)
  proof             validation/reports/*.json + cross-module summary (computed)
  all               all five modules + conformance + proof
  --step      stage mode: pause for Enter after each explanation and before each command / moment
  --en        narrate in English (default Spanish)
  --quiet     suppress narrative phase headers (terse mode)
  --replay    agentic-eval: replay the recorded transcript instead of calling claude
  RECORD=1    agentic-eval: save a green live transcript to docs/demo/transcripts/
EOF
    exit 2
    ;;
esac
