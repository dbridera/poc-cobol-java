#!/usr/bin/env python3
"""gen-coverage.py — paragraph coverage matrix from the paragraph traces.

For a job module with `"trace": true` in cobol/<module>/job.json, every
golden-master fixture carries out/steps/<nn>-<NAME>.trace.txt (one line per
entered paragraph, `PROGRAM Paragraph NAME`, see tools/run-job.py). This tool
reads the paragraph list of every program under cobol/<module>/src/ and those
traces, and writes:

    cobol/<module>/COVERAGE.md       one table per program: paragraph · lines · one column
                                     per fixture (✔ / –) · "covered by N/F fixtures";
                                     plus the list of paragraphs no fixture reaches
    cobol/<module>/README.md         a short summary injected between the markers
                                     <!-- BEGIN AUTO-GENERATED COVERAGE --> … <!-- END AUTO-GENERATED COVERAGE -->

Usage:
    ./tools/gen-coverage.py <module>            # (re)generate
    ./tools/gen-coverage.py <module> --check    # exit 1 if COVERAGE.md / README summary are out of date
    ./tools/gen-coverage.py <module> --json     # print the coverage data as JSON (used by render-traceability.py)

The matrix replaces the hand-written one: it is derived from what GnuCOBOL
actually executed, not from reading the source.
"""
from __future__ import annotations

import json
import re
import sys
from collections import OrderedDict
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import jobman  # noqa: E402

REPO_ROOT = Path(__file__).resolve().parent.parent
MARKER_BEGIN = "<!-- BEGIN AUTO-GENERATED COVERAGE (gen-coverage.py) -->"
MARKER_END = "<!-- END AUTO-GENERATED COVERAGE -->"

PROGRAM_ID_RE = re.compile(r"^\s{7}PROGRAM-ID\.\s+([A-Za-z0-9-]+)", re.IGNORECASE)
LABEL_RE = re.compile(r"^\s{7}([0-9A-Za-z][0-9A-Za-z-]*)(\s+SECTION)?\s*\.\s*$")
NOT_LABELS = {"PROCEDURE DIVISION", "FILE-CONTROL", "FILE SECTION", "WORKING-STORAGE SECTION", "LINKAGE SECTION",
              "CONFIGURATION SECTION", "INPUT-OUTPUT SECTION", "DATA DIVISION", "ENVIRONMENT DIVISION",
              "IDENTIFICATION DIVISION", "SPECIAL-NAMES", "OBJECT-COMPUTER", "SOURCE-COMPUTER"}


def parse_programs(src_dir: Path) -> "OrderedDict[str, dict]":
    """program-id -> {"file": relative path, "paragraphs": OrderedDict{name: (start, end)}}.
    One .cbl file may hold several programs (nested / END PROGRAM)."""
    programs: "OrderedDict[str, dict]" = OrderedDict()
    for cbl in sorted(src_dir.rglob("*.cbl")):
        lines = cbl.read_text(encoding="latin-1").splitlines()
        current = None
        in_procedure = False
        labels: list[tuple[str, int]] = []

        def flush():
            if current is None:
                return
            paras: "OrderedDict[str, tuple[int, int]]" = OrderedDict()
            for i, (name, start) in enumerate(labels):
                end = labels[i + 1][1] - 1 if i + 1 < len(labels) else last_line
                paras[name] = (start, end)
            programs[current] = {"file": str(cbl.relative_to(src_dir.parent)), "paragraphs": paras}

        last_line = len(lines)
        for n, raw in enumerate(lines, start=1):
            line = raw[:72] if len(raw) > 72 else raw      # fixed format: ignore columns 73-80
            if len(line) > 6 and line[6] in "*/":
                continue
            m = PROGRAM_ID_RE.match(line)
            if m:
                flush()
                current = m.group(1).upper()
                in_procedure = False
                labels = []
                continue
            if re.match(r"^\s{7}PROCEDURE DIVISION", line, re.IGNORECASE):
                in_procedure = True
                continue
            if re.match(r"^\s{7}END PROGRAM", line, re.IGNORECASE):
                last_line = n - 1
                flush()
                current = None
                labels = []
                last_line = len(lines)
                continue
            if in_procedure and current:
                lm = LABEL_RE.match(line)
                if lm and lm.group(1).upper() not in NOT_LABELS:
                    labels.append((lm.group(1).upper(), n))
        flush()
    return programs


def read_traces(module: str) -> "OrderedDict[str, dict[str, set[str]]]":
    """fixture -> program -> set of paragraph names entered (any step)."""
    out: "OrderedDict[str, dict[str, set[str]]]" = OrderedDict()
    gm = REPO_ROOT / "golden-master" / module
    if not gm.exists():
        return out
    for fx in sorted(p for p in gm.iterdir() if p.is_dir()):
        per_prog: dict[str, set[str]] = {}
        for tr in sorted((fx / "out" / "steps").glob("*.trace.txt")):
            for ln in tr.read_text(encoding="latin-1").splitlines():
                parts = ln.split()
                if len(parts) == 3 and parts[1] in ("Paragraph", "Section"):
                    per_prog.setdefault(parts[0].upper(), set()).add(parts[2].upper())
        out[fx.name] = per_prog
    return out


def coverage(module: str) -> dict:
    programs = parse_programs(REPO_ROOT / "cobol" / module / "src")
    traces = read_traces(module)
    fixtures = list(traces.keys())
    data = {"module": module, "fixtures": fixtures, "programs": []}
    for pid, info in programs.items():
        rows = []
        for name, (start, end) in info["paragraphs"].items():
            hits = [fx for fx in fixtures if name in traces[fx].get(pid, set())]
            rows.append({"paragraph": name, "start": start, "end": end, "fixtures": hits})
        data["programs"].append({"program": pid, "file": info["file"], "paragraphs": rows})
    return data


def render_markdown(data: dict) -> str:
    fx = data["fixtures"]
    short = [f[:2] for f in fx]
    lines = [f"# {data['module']} — paragraph coverage (generated by tools/gen-coverage.py)", "",
             "Derived from the GnuCOBOL paragraph traces of every golden-master fixture "
             "(`golden-master/<fixture>/out/steps/*.trace.txt`). ✔ = the paragraph was entered at least once "
             "in that fixture. Do not edit; re-run `./tools/gen-coverage.py " + data["module"] + "`.", "",
             "Fixtures: " + " · ".join(f"**{s}** = `{f}`" for s, f in zip(short, fx)), ""]
    total = covered = 0
    uncovered: list[str] = []
    for prog in data["programs"]:
        if not prog["paragraphs"]:
            continue
        lines.append(f"## {prog['program']} (`{prog['file']}`)")
        lines.append("")
        lines.append("| Paragraph | Lines | " + " | ".join(short) + " | Covered |")
        lines.append("|---|---|" + "---|" * len(short) + "---|")
        for r in prog["paragraphs"]:
            total += 1
            marks = ["✔" if f in r["fixtures"] else "–" for f in fx]
            n = len(r["fixtures"])
            if n:
                covered += 1
            else:
                uncovered.append(f"{prog['program']}.{r['paragraph']} ({r['start']}-{r['end']})")
            lines.append(f"| `{r['paragraph']}` | {r['start']}-{r['end']} | " + " | ".join(marks)
                         + f" | {'**0**' if n == 0 else n}/{len(fx)} |")
        lines.append("")
    lines.append("## Not reached by any fixture")
    lines.append("")
    if uncovered:
        lines += [f"- `{u}`" for u in uncovered]
    else:
        lines.append("- none")
    lines.append("")
    lines.append(f"**Total: {covered} / {total} paragraphs covered by at least one fixture.**")
    lines.append("")
    data["_totals"] = (covered, total, uncovered)
    return "\n".join(lines)


def render_summary(data: dict) -> str:
    covered, total, uncovered = data["_totals"]
    lines = [MARKER_BEGIN,
             f"Coverage from the paragraph traces: **{covered} / {total} paragraphs** of "
             f"{len([p for p in data['programs'] if p['paragraphs']])} programs are entered by at least one of the "
             f"{len(data['fixtures'])} fixtures. Full matrix: [COVERAGE.md](./COVERAGE.md).",
             ""]
    if uncovered:
        lines.append("Not reached by any fixture: " + ", ".join(f"`{u.split(' ')[0]}`" for u in uncovered) + ".")
    else:
        lines.append("Every paragraph is reached by at least one fixture.")
    lines.append(MARKER_END)
    return "\n".join(lines)


def inject_summary(readme: Path, summary: str) -> str:
    text = readme.read_text()
    if MARKER_BEGIN in text and MARKER_END in text:
        pre = text[:text.index(MARKER_BEGIN)]
        post = text[text.index(MARKER_END) + len(MARKER_END):]
        return pre + summary + post
    # first injection: after the "## 6." heading line
    m = re.search(r"^## 6\..*$", text, re.MULTILINE)
    if not m:
        return text.rstrip("\n") + "\n\n" + summary + "\n"
    return text[:m.end()] + "\n\n" + summary + text[m.end():]


def main(argv: list[str]) -> int:
    if len(argv) < 2:
        print(__doc__, file=sys.stderr)
        return 2
    module = argv[1]
    m = jobman.load(module)
    if not m.get("trace"):
        print(f"{module}: manifest has no \"trace\": true — nothing to do")
        return 0
    data = coverage(module)
    md = render_markdown(data)
    summary = render_summary(data)
    if "--json" in argv:
        print(json.dumps({k: v for k, v in data.items() if not k.startswith("_")}, indent=2))
        return 0
    cov_path = REPO_ROOT / "cobol" / module / "COVERAGE.md"
    readme = REPO_ROOT / "cobol" / module / "README.md"
    new_readme = inject_summary(readme, summary)
    drift = []
    if not cov_path.exists() or cov_path.read_text() != md:
        drift.append(str(cov_path.relative_to(REPO_ROOT)))
    if readme.read_text() != new_readme:
        drift.append(str(readme.relative_to(REPO_ROOT)))
    if "--check" in argv:
        for d in drift:
            print(f"OUT OF DATE: {d}")
        print(f"{module}: coverage {'in sync' if not drift else 'drifted'}")
        return 1 if drift else 0
    cov_path.write_text(md)
    readme.write_text(new_readme)
    covered, total, uncovered = data["_totals"]
    print(f"{module}: {covered}/{total} paragraphs covered; {len(uncovered)} unreached; wrote COVERAGE.md"
          + (" + README summary" if "README" in " ".join(drift) else ""))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
