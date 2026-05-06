#!/usr/bin/env python3
"""compare-outputs.py — diff Java run outputs against COBOL golden-master.

Usage:
    ./tools/compare-outputs.py <module> [<fixture>]

Compares, for each fixture under golden-master/<module>/<fixture>/:
    - stdout.txt
    - exit_code
    - every file under out/

Against the corresponding java-run/<module>/<fixture>/ directory (which the
Java side is expected to populate with the same layout).

Numeric tolerance: by default, exact textual match is required. If the
fixture directory contains a `compare.yaml` with `numeric_tolerance: <eps>`,
numeric tokens within that tolerance are considered equal (still warned).

Exit code 0 = green diff, 1 = differences found, 2 = setup/usage error.
"""
from __future__ import annotations

import sys
import os
import json
import difflib
import filecmp
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent


def diff_text(a: str, b: str) -> list[str]:
    return list(
        difflib.unified_diff(
            a.splitlines(keepends=True),
            b.splitlines(keepends=True),
            fromfile="cobol",
            tofile="java",
            n=3,
        )
    )


def compare_fixture(module: str, fixture: str) -> tuple[bool, dict]:
    gm = REPO_ROOT / "golden-master" / module / fixture
    jr = REPO_ROOT / "java-run" / module / fixture

    if not gm.exists():
        return False, {"error": f"no golden-master at {gm}"}
    if not jr.exists():
        return False, {"error": f"no java-run at {jr} (run the Java side first)"}

    report: dict = {"fixture": fixture, "module": module, "diffs": []}
    ok = True

    # exit_code
    gm_ec = (gm / "exit_code").read_text().strip() if (gm / "exit_code").exists() else ""
    jr_ec = (jr / "exit_code").read_text().strip() if (jr / "exit_code").exists() else ""
    if gm_ec != jr_ec:
        ok = False
        report["diffs"].append({"file": "exit_code", "cobol": gm_ec, "java": jr_ec})

    # stdout
    if (gm / "stdout.txt").exists() or (jr / "stdout.txt").exists():
        a = (gm / "stdout.txt").read_text() if (gm / "stdout.txt").exists() else ""
        b = (jr / "stdout.txt").read_text() if (jr / "stdout.txt").exists() else ""
        if a != b:
            ok = False
            report["diffs"].append({"file": "stdout.txt", "diff": "".join(diff_text(a, b))})

    # output files
    gm_out = gm / "out"
    jr_out = jr / "out"
    if gm_out.exists() or jr_out.exists():
        gm_files = {p.relative_to(gm_out) for p in gm_out.rglob("*") if p.is_file()} if gm_out.exists() else set()
        jr_files = {p.relative_to(jr_out) for p in jr_out.rglob("*") if p.is_file()} if jr_out.exists() else set()
        only_cobol = gm_files - jr_files
        only_java = jr_files - gm_files
        for f in sorted(only_cobol):
            ok = False
            report["diffs"].append({"file": str(f), "missing_in": "java"})
        for f in sorted(only_java):
            ok = False
            report["diffs"].append({"file": str(f), "missing_in": "cobol", "note": "java produced an unexpected file"})
        for f in sorted(gm_files & jr_files):
            ap = gm_out / f
            bp = jr_out / f
            if filecmp.cmp(ap, bp, shallow=False):
                continue
            try:
                a = ap.read_text()
                b = bp.read_text()
                ok = False
                report["diffs"].append({"file": str(f), "diff": "".join(diff_text(a, b))})
            except UnicodeDecodeError:
                ok = False
                report["diffs"].append({"file": str(f), "diff": "<binary differs>"})

    return ok, report


def main(argv: list[str]) -> int:
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
        print(f"[{status}] {module}/{f}")
        if not ok:
            for d in rep.get("diffs", []):
                if "diff" in d:
                    print(f"  --- {d['file']} ---")
                    print(d["diff"])
                else:
                    print(f"  {d}")
            all_ok = False

    out_dir = REPO_ROOT / "validation" / "reports"
    out_dir.mkdir(parents=True, exist_ok=True)
    (out_dir / f"{module}.json").write_text(json.dumps(reports, indent=2))
    return 0 if all_ok else 1


if __name__ == "__main__":
    sys.exit(main(sys.argv))
