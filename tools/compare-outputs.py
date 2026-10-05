#!/usr/bin/env python3
"""compare-outputs.py — diff Java run outputs against COBOL golden-master.

Usage:
    ./tools/compare-outputs.py <module> [<fixture>]
    ./tools/compare-outputs.py --summary [<module> ...]   # one line per module from validation/reports/*.json

Compares, for each fixture under golden-master/<module>/<fixture>/:
    - stdout.txt
    - exit_code
    - every file under out/  (recursively — multi-step modules put per-step
      stdout under out/steps/ and the job log at out/run-log.txt)

Against the corresponding java-run/<module>/<fixture>/ directory (which the
Java side is expected to populate with the same layout).

Every comparison is byte-exact. When two files differ the report shows:
    - a unified text diff when both sides are UTF-8 text and the file has no
      declared record length;
    - otherwise a *binary report*: first differing byte offset, 1-based record
      number and column (record length taken from cobol/<module>/job.json
      datasets by file name, or from fixtures/<fixture>/compare.json
      {"lrecl": {"file": n}}), hex of both bytes, the surrounding record text,
      and up to 5 sample records.
Each fixture entry also carries a `summary` block with files/records/bytes
compared and differing, so the proof can say "N records compared, 0 bytes
differ" instead of only "diffs: []".

Exit code 0 = green diff, 1 = differences found, 2 = setup/usage error.
"""
from __future__ import annotations

import difflib
import json
import math
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
try:
    import jobman  # noqa: E402
except ImportError:  # pragma: no cover
    jobman = None

REPO_ROOT = Path(__file__).resolve().parent.parent
SAMPLE_RECORDS = 5
CONTEXT_CHARS = 24


# ----------------------------------------------------------------------------- helpers

def diff_text(a: str, b: str) -> list[str]:
    return list(difflib.unified_diff(a.splitlines(keepends=True), b.splitlines(keepends=True),
                                     fromfile="cobol", tofile="java", n=3))


def printable(raw: bytes) -> str:
    return "".join(chr(c) if 32 <= c < 127 else "." for c in raw)


def load_lrecl_table(module: str, fixture: str) -> dict[str, int]:
    """file basename -> record length."""
    table: dict[str, int] = {}
    if jobman is not None and jobman.manifest_path(module).exists():
        try:
            m = jobman.load(module)
            for ds in m["datasets"].values():
                table[ds["path"]] = int(ds["lrecl"])
        except Exception:  # manifest problems are reported by run-job.py, not here
            pass
    cj = REPO_ROOT / "cobol" / module / "fixtures" / fixture / "compare.json"
    if cj.exists():
        try:
            table.update({k: int(v) for k, v in json.loads(cj.read_text()).get("lrecl", {}).items()})
        except Exception:
            pass
    return table


def is_utf8(raw: bytes) -> bool:
    try:
        raw.decode("utf-8")
        return True
    except UnicodeDecodeError:
        return False


def count_differing_bytes(a: bytes, b: bytes) -> int:
    n = min(len(a), len(b))
    diff = sum(1 for i in range(n) if a[i] != b[i])
    return diff + abs(len(a) - len(b))


def record_count(raw: bytes, lrecl: int | None) -> int:
    if not raw:
        return 0
    if lrecl:
        return math.ceil(len(raw) / lrecl)
    return raw.count(b"\n") + (0 if raw.endswith(b"\n") else 1)


def binary_report(name: str, a: bytes, b: bytes, lrecl: int | None) -> dict:
    rep: dict = {"file": name, "kind": "binary", "lrecl": lrecl,
                 "size_cobol": len(a), "size_java": len(b),
                 "records_compared": max(record_count(a, lrecl), record_count(b, lrecl)),
                 "bytes_compared": max(len(a), len(b)),
                 "bytes_differing": count_differing_bytes(a, b)}
    n = min(len(a), len(b))
    first = next((i for i in range(n) if a[i] != b[i]), n if len(a) != len(b) else None)
    if first is None:
        return rep
    width = lrecl or 80

    def locate(off: int) -> tuple[int, int]:
        return off // width + 1, off % width + 1

    def window(raw: bytes, off: int) -> str:
        rec_start = (off // width) * width
        rec = raw[rec_start:rec_start + width]
        col = off - rec_start
        lo, hi = max(0, col - CONTEXT_CHARS), min(len(rec), col + CONTEXT_CHARS)
        return ("…" if lo > 0 else "") + printable(rec[lo:hi]) + ("…" if hi < len(rec) else "")

    rec, col = locate(first)
    rep["first_diff"] = {
        "offset": first, "record": rec, "column": col,
        "cobol_hex": a[first:first + 1].hex() if first < len(a) else "",
        "java_hex": b[first:first + 1].hex() if first < len(b) else "",
        "cobol_text": window(a, first), "java_text": window(b, first),
    }
    samples: list[dict] = []
    seen_records: set[int] = set()
    for i in range(n):
        if a[i] != b[i]:
            r, c = locate(i)
            if r in seen_records:
                continue
            seen_records.add(r)
            samples.append({"record": r, "column": c, "cobol_hex": a[i:i + 1].hex(), "java_hex": b[i:i + 1].hex(),
                            "cobol_text": window(a, i), "java_text": window(b, i)})
            if len(samples) >= SAMPLE_RECORDS:
                break
    rep["records_differing"] = len({i // width for i in range(n) if a[i] != b[i]}) + \
        (record_count(a[n:], lrecl) if len(a) > n else record_count(b[n:], lrecl))
    rep["samples"] = samples
    return rep


def compare_file(name: str, a: bytes, b: bytes, lrecl: int | None, summary: dict) -> dict | None:
    """Returns a diff entry or None when identical. Updates summary counters."""
    summary["files_compared"] += 1
    summary["bytes_compared"] += max(len(a), len(b))
    summary["records_compared"] += max(record_count(a, lrecl), record_count(b, lrecl))
    if a == b:
        return None
    summary["files_differing"] += 1
    differing = count_differing_bytes(a, b)
    summary["bytes_differing"] += differing
    if lrecl is None and is_utf8(a) and is_utf8(b):
        return {"file": name, "diff": "".join(diff_text(a.decode("utf-8"), b.decode("utf-8"))),
                "bytes_compared": max(len(a), len(b)), "bytes_differing": differing}
    return binary_report(name, a, b, lrecl)


# ----------------------------------------------------------------------------- per fixture

def compare_fixture(module: str, fixture: str) -> tuple[bool, dict]:
    gm = REPO_ROOT / "golden-master" / module / fixture
    jr = REPO_ROOT / "java-run" / module / fixture

    if not gm.exists():
        return False, {"error": f"no golden-master at {gm}"}
    if not jr.exists():
        return False, {"error": f"no java-run at {jr} (run the Java side first)"}

    lrecl_table = load_lrecl_table(module, fixture)
    summary = {"files_compared": 0, "records_compared": 0, "bytes_compared": 0,
               "bytes_differing": 0, "files_differing": 0}
    report: dict = {"fixture": fixture, "module": module, "summary": summary, "diffs": []}
    ok = True

    # exit_code
    gm_ec = (gm / "exit_code").read_text().strip() if (gm / "exit_code").exists() else ""
    jr_ec = (jr / "exit_code").read_text().strip() if (jr / "exit_code").exists() else ""
    summary["files_compared"] += 1
    if gm_ec != jr_ec:
        ok = False
        summary["files_differing"] += 1
        report["diffs"].append({"file": "exit_code", "cobol": gm_ec, "java": jr_ec})

    # stdout
    if (gm / "stdout.txt").exists() or (jr / "stdout.txt").exists():
        a = (gm / "stdout.txt").read_bytes() if (gm / "stdout.txt").exists() else b""
        b = (jr / "stdout.txt").read_bytes() if (jr / "stdout.txt").exists() else b""
        entry = compare_file("stdout.txt", a, b, None, summary)
        if entry:
            ok = False
            report["diffs"].append(entry)

    # output files
    gm_out = gm / "out"
    jr_out = jr / "out"
    if gm_out.exists() or jr_out.exists():
        gm_files = {p.relative_to(gm_out) for p in gm_out.rglob("*") if p.is_file()} if gm_out.exists() else set()
        jr_files = {p.relative_to(jr_out) for p in jr_out.rglob("*") if p.is_file()} if jr_out.exists() else set()
        for f in sorted(gm_files - jr_files):
            ok = False
            summary["files_compared"] += 1
            summary["files_differing"] += 1
            report["diffs"].append({"file": str(f), "missing_in": "java"})
        for f in sorted(jr_files - gm_files):
            ok = False
            summary["files_compared"] += 1
            summary["files_differing"] += 1
            report["diffs"].append({"file": str(f), "missing_in": "cobol", "note": "java produced an unexpected file"})
        for f in sorted(gm_files & jr_files):
            a = (gm_out / f).read_bytes()
            b = (jr_out / f).read_bytes()
            entry = compare_file(str(f), a, b, lrecl_table.get(f.name), summary)
            if entry:
                ok = False
                report["diffs"].append(entry)

    return ok, report


def fmt_summary(s: dict) -> str:
    return (f"files {s['files_compared']} · records {s['records_compared']} · "
            f"bytes {s['bytes_compared']} · differing {s['bytes_differing']}")


def print_diff_entry(d: dict) -> None:
    if "diff" in d:
        print(f"  --- {d['file']} ---")
        print(d["diff"])
    elif d.get("kind") == "binary":
        fd = d.get("first_diff")
        print(f"  --- {d['file']} (binary, lrecl={d['lrecl']}, sizes cobol={d['size_cobol']} java={d['size_java']}, "
              f"bytes differing={d['bytes_differing']}) ---")
        if fd:
            print(f"  first diff at offset {fd['offset']}: record {fd['record']} column {fd['column']} "
                  f"cobol=0x{fd['cobol_hex']} java=0x{fd['java_hex']}")
            print(f"    cobol: {fd['cobol_text']}")
            print(f"    java : {fd['java_text']}")
    else:
        print(f"  {d}")


# ----------------------------------------------------------------------------- summary mode

def summary_mode(modules: list[str]) -> int:
    reports_dir = REPO_ROOT / "validation" / "reports"
    files = [reports_dir / f"{m}.json" for m in modules] if modules else sorted(reports_dir.glob("*.json"))
    tot_fx = tot_ok = tot_rec = tot_bytes = tot_diff = 0
    for rf in files:
        if not rf.exists():
            print(f"[??? ] {rf.stem}: no report")
            continue
        entries = json.loads(rf.read_text())
        n = len(entries)
        ok = sum(1 for e in entries if "diffs" in e and not e["diffs"])
        rec = sum(e.get("summary", {}).get("records_compared", 0) for e in entries)
        byt = sum(e.get("summary", {}).get("bytes_compared", 0) for e in entries)
        dif = sum(e.get("summary", {}).get("bytes_differing", 0) for e in entries)
        status = "OK " if ok == n else "FAIL"
        print(f"[{status}] {rf.stem:<24} {ok}/{n} fixtures · records {rec} · bytes {byt} · differing {dif}")
        tot_fx += n; tot_ok += ok; tot_rec += rec; tot_bytes += byt; tot_diff += dif
    print(f"TOTAL {tot_ok}/{tot_fx} fixtures byte-exact · records {tot_rec} · bytes {tot_bytes} · differing {tot_diff}")
    return 0 if tot_ok == tot_fx else 1


# ----------------------------------------------------------------------------- main

def main(argv: list[str]) -> int:
    if len(argv) >= 2 and argv[1] == "--summary":
        return summary_mode(argv[2:])
    if len(argv) < 2:
        print(__doc__, file=sys.stderr)
        return 2
    module = argv[1]
    fixture_arg = argv[2] if len(argv) > 2 else None

    gm_root = REPO_ROOT / "golden-master" / module
    if not gm_root.exists():
        print(f"no golden-master at {gm_root}", file=sys.stderr)
        return 2

    fixtures = [fixture_arg] if fixture_arg else sorted(p.name for p in gm_root.iterdir() if p.is_dir())

    all_ok = True
    reports = []
    for f in fixtures:
        ok, rep = compare_fixture(module, f)
        reports.append(rep)
        status = "OK " if ok else "FAIL"
        extra = f"   ({fmt_summary(rep['summary'])})" if "summary" in rep else ""
        print(f"[{status}] {module}/{f}{extra}")
        if not ok:
            if "error" in rep:
                print(f"  {rep['error']}")
            for d in rep.get("diffs", []):
                print_diff_entry(d)
            all_ok = False

    out_dir = REPO_ROOT / "validation" / "reports"
    out_dir.mkdir(parents=True, exist_ok=True)
    (out_dir / f"{module}.json").write_text(json.dumps(reports, indent=2))
    return 0 if all_ok else 1


if __name__ == "__main__":
    sys.exit(main(sys.argv))
