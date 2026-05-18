#!/usr/bin/env bash
# Module 1 spike runner.
#
# Runs the COBOL side (libcob_sqlite + SQLite) and the Java side (Spring
# Boot + JPA + H2) against the same logical inputs and diffs their
# outputs byte-exactly.
#
# Exit 0 = spike GREEN. Exit non-zero = spike RED with diagnostic.
set -euo pipefail

SPIKE_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SPIKE_DIR"

export PATH="/usr/local/bin:/usr/local/opt/openjdk@21/bin:$PATH"
export JAVA_HOME="/usr/local/opt/openjdk@21"
export DYLD_LIBRARY_PATH="$SPIKE_DIR:/usr/local/opt/sqlite/lib"

# ----- Build (idempotent) -----
if [[ ! -f libcob_sqlite.dylib || cob_sqlite.c -nt libcob_sqlite.dylib ]]; then
    echo "==> compiling cob_sqlite.c -> libcob_sqlite.dylib"
    cc -shared -fPIC \
       -I/usr/local/opt/sqlite/include \
       -L/usr/local/opt/sqlite/lib \
       -o libcob_sqlite.dylib cob_sqlite.c -lsqlite3
fi

if [[ ! -f hello-db || hello-db.cbl -nt hello-db ]]; then
    echo "==> compiling hello-db.cbl -> hello-db"
    cobc -free -x -o hello-db hello-db.cbl \
         -L. -lcob_sqlite -L/usr/local/opt/sqlite/lib
fi

JAR="java-spike/target/spike-hello-db-0.1.0-SNAPSHOT.jar"
if [[ ! -f "$JAR" || java-spike/src/main/java/com/example/spike/HelloDbApp.java -nt "$JAR" ]]; then
    echo "==> building Java spike"
    (cd java-spike && mvn -B -q package)
fi

# ----- Reset state (deterministic) -----
rm -f out/spike.db out/widget-cobol.txt out/widget-java.txt \
      out/stdout-cobol.txt out/stdout-java.txt \
      java-spike/target/h2-spike.mv.db java-spike/target/h2-spike.trace.db
mkdir -p out

# ----- Run COBOL -----
echo "==> running COBOL spike"
./hello-db > out/stdout-cobol.txt
mv out/widget.txt out/widget-cobol.txt

# ----- Run Java -----
echo "==> running Java spike"
java -jar "$JAR" out/widget-java.txt > out/stdout-java.txt

# ----- Diff -----
echo "==> diffing"
fail=0
if ! diff -u out/stdout-cobol.txt out/stdout-java.txt; then
    echo "RED: stdout differs"; fail=1
fi
if ! diff -u out/widget-cobol.txt out/widget-java.txt; then
    echo "RED: widget dump differs"; fail=1
fi

if [[ $fail -eq 0 ]]; then
    echo
    echo "GREEN: COBOL and Java produce byte-identical output"
    echo "  stdout:     $(wc -c < out/stdout-cobol.txt | tr -d ' ') bytes (match)"
    echo "  widget:     $(wc -c < out/widget-cobol.txt | tr -d ' ') bytes (match)"
    exit 0
else
    exit 1
fi
