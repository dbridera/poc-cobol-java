#!/usr/bin/env python3
"""render-traceability.py — side-by-side COBOL ↔ Java viewer per module.

Reads the traceability comments every translated Java class carries
(`// COBOL: <file>.cbl:<start>-<end>` — any comment form), the paragraph
structure of the COBOL sources, and (for job modules) the paragraph coverage
derived from the golden-master traces (tools/gen-coverage.py). Emits:

    cobol/<module>/traceability.json   the index: COBOL files + paragraphs (+coverage), Java files + links
    cobol/<module>/traceability.html   a standalone page (no CDN, works from file://): COBOL on the left,
                                       Java on the right, a click on a Java citation scrolls and highlights the
                                       cited COBOL lines, a click on a COBOL paragraph lists the Java locations
                                       that cite it; coverage badges per paragraph; search over both panes.

Usage:
    ./tools/render-traceability.py              # every module with cobol/<m>/src and java/<m>
    ./tools/render-traceability.py <module>     # one module
    ./tools/render-traceability.py --check      # exit 1 if any generated file drifts from the sources

Stdlib only.
"""
from __future__ import annotations

import importlib
import json
import re
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
gen_coverage = importlib.import_module("gen-coverage")
import jobman  # noqa: E402

REPO_ROOT = Path(__file__).resolve().parent.parent
TEMPLATE = REPO_ROOT / "tools" / "render-traceability" / "viewer.html.tmpl"

# `COBOL: file.cbl:12-34`, optionally followed by `, 56-78` (same file) or `, other.cbl:9-10` continuations
FILE = r"[A-Za-z0-9_./\-]+\.(?:cbl|cpy|CBL|COB|CPY)"
CITE_RE = re.compile(r"COBOL:\s*(" + FILE + r")\s*:\s*(\d+)(?:\s*-\s*(\d+))?((?:\s*,\s*(?:" + FILE + r"\s*:\s*)?\d+(?:\s*-\s*\d+)?)*)")
CONT_RE = re.compile(r"(?:(" + FILE + r")\s*:\s*)?(\d+)(?:\s*-\s*(\d+))?")
# sources a module's Java may cite that live outside cobol/<module>/src: the GenApp originals and the
# src/ of sibling modules (module 1A reuses module 1B's request layout)
def fallback_dirs(module: str) -> list[str]:
    dirs = ["genapp-source"]
    for d in sorted((REPO_ROOT / "cobol").iterdir()):
        if d.name != module and (d / "src").is_dir():
            dirs.append(f"{d.name}/src")
    return dirs


def module_list() -> list[str]:
    out = []
    for d in sorted((REPO_ROOT / "cobol").iterdir()):
        if (d / "src").is_dir() and (REPO_ROOT / "java" / d.name).is_dir():
            out.append(d.name)
    return out


def cobol_files(module: str) -> list[Path]:
    base = REPO_ROOT / "cobol" / module
    files = sorted((base / "src").rglob("*.cbl")) + sorted((base / "src").rglob("*.CBL"))
    cpy = base / "copybooks"
    if cpy.is_dir():
        files += sorted(cpy.glob("*.cpy")) + sorted(cpy.glob("*.CPY"))
    return files


def java_files(module: str) -> list[Path]:
    return sorted((REPO_ROOT / "java" / module / "src" / "main" / "java").rglob("*.java"))


GUIDE_HEADING_RE = re.compile(r"^##\s+(.+?)\s+—\s+(.+?)\s*$")


def parse_guide(module: str) -> dict:
    """cobol/<module>/PARAGRAPHS.md -> {"programs": {PID: {"title", "intro"}}, "paragraphs": {(PID, NAME): {"what", "spec"}}}.
    A heading `## A, B — title` applies to every listed program; the prose under it is the
    program intro; table rows `| Párrafo | Qué hace | Spec |` describe paragraphs."""
    guide = {"programs": {}, "paragraphs": {}}
    path = REPO_ROOT / "cobol" / module / "PARAGRAPHS.md"
    if not path.exists():
        return guide
    pids: list[str] = []
    intro: list[str] = []
    in_table = False
    for raw in path.read_text(encoding="utf-8").splitlines():
        line = raw.strip()
        m = GUIDE_HEADING_RE.match(line)
        if m:
            for pid in pids:
                guide["programs"][pid]["intro"] = " ".join(intro).strip()
            pids = [x.strip().upper() for x in m.group(1).split(",")]
            for pid in pids:
                guide["programs"][pid] = {"title": m.group(2).strip(), "intro": ""}
            intro, in_table = [], False
            continue
        if not pids or line.startswith("# "):
            continue
        if line.startswith("|"):
            cells = [c.strip() for c in line.strip("|").split("|")]
            if len(cells) >= 2 and cells[0] and cells[0] not in ("Párrafo", "Paragraph") and not set(cells[0]) <= set("-: "):
                for pid in pids:
                    guide["paragraphs"][(pid, cells[0].upper())] = {"what": cells[1], "spec": cells[2] if len(cells) > 2 else ""}
            in_table = True
            continue
        if line == "---":
            continue
        if line and not in_table:
            intro.append(line)
    for pid in pids:
        guide["programs"][pid]["intro"] = " ".join(intro).strip()
    return guide


def relpath(p: Path, base: Path) -> str:
    try:
        return str(p.relative_to(base))
    except ValueError:
        return "../" + str(p.relative_to(base.parent))


def build_index(module: str) -> dict:
    base = REPO_ROOT / "cobol" / module
    cfiles = cobol_files(module)
    by_base = {p.name.lower(): p for p in cfiles}
    # originals cited by the Java but living outside the module (modules 1A/1B cite cobol/genapp-source/*.cbl)
    cited_names = set()
    for jp in java_files(module):
        for mt in CITE_RE.finditer(jp.read_text(encoding="utf-8")):
            cited_names.add(Path(mt.group(1)).name.lower())
            for c in CONT_RE.finditer(mt.group(4) or ""):
                if c.group(1):
                    cited_names.add(Path(c.group(1)).name.lower())
    for fb in fallback_dirs(module):
        for p in sorted((REPO_ROOT / "cobol" / fb).glob("*.cbl")):
            if p.name.lower() in cited_names and p.name.lower() not in by_base:
                cfiles.append(p)
                by_base[p.name.lower()] = p

    programs = gen_coverage.parse_programs(base / "src")
    for fb in fallback_dirs(module):
        for pid, info in gen_coverage.parse_programs(REPO_ROOT / "cobol" / fb).items():
            if (REPO_ROOT / "cobol" / fb / Path(info["file"]).name).name.lower() in cited_names:
                programs[pid] = {"file": relpath(REPO_ROOT / "cobol" / fb / Path(info["file"]).name, base),
                                 "paragraphs": info["paragraphs"]}
    guide = parse_guide(module)
    paragraphs_by_file: dict[str, list[dict]] = {}
    program_guide: dict[str, dict] = {}
    for pid, info in programs.items():
        rel = info["file"]
        if pid in guide["programs"]:
            program_guide.setdefault(rel, {})[pid] = guide["programs"][pid]
        for name, (start, end) in info["paragraphs"].items():
            g = guide["paragraphs"].get((pid, name), {})
            paragraphs_by_file.setdefault(rel, []).append(
                {"program": pid, "name": name, "start": start, "end": end, "cited_by": [], "covered": None,
                 "what": g.get("what", ""), "spec": g.get("spec", "")})

    # coverage (job modules with traces)
    fixtures: list[str] = []
    try:
        m = jobman.load(module)
        if m.get("trace"):
            cov = gen_coverage.coverage(module)
            fixtures = cov["fixtures"]
            hits = {(p["program"], r["paragraph"]): r["fixtures"] for p in cov["programs"] for r in p["paragraphs"]}
            for rel, paras in paragraphs_by_file.items():
                for para in paras:
                    para["covered"] = len(hits.get((para["program"], para["name"]), []))
    except jobman.ManifestError:
        pass

    # java links
    jfiles = []
    unresolved = 0
    for jp in java_files(module):
        rel = str(jp.relative_to(REPO_ROOT / "java" / module))
        lines = jp.read_text(encoding="utf-8").splitlines()
        links = []
        for ln_no, text in enumerate(lines, start=1):
            for mt in CITE_RE.finditer(text):
                fname = mt.group(1)
                refs = [(fname, int(mt.group(2)), int(mt.group(3) or mt.group(2)))]
                for c in CONT_RE.finditer(mt.group(4) or ""):
                    fname = c.group(1) or fname          # a bare range continues the previous file
                    refs.append((fname, int(c.group(2)), int(c.group(3) or c.group(2))))
                for fname, start, end in refs:
                    target = by_base.get(Path(fname).name.lower())
                    if target is None:
                        unresolved += 1
                        links.append({"line": ln_no, "cobol": fname, "start": start, "end": end, "resolved": False})
                        continue
                    trel = relpath(target, base)
                    links.append({"line": ln_no, "cobol": trel, "start": start, "end": end, "resolved": True})
                    for para in paragraphs_by_file.get(trel, []):
                        if para["start"] <= end and start <= para["end"]:
                            para["cited_by"].append({"java": rel, "line": ln_no})
        jfiles.append({"path": rel, "lines": lines, "links": links})

    cf = []
    for p in cfiles:
        rel = relpath(p, base)
        cf.append({"path": rel, "lines": p.read_text(encoding="latin-1").splitlines(),
                   "paragraphs": paragraphs_by_file.get(rel, []), "programs": program_guide.get(rel, {})})

    all_paras = [para for f in cf for para in f["paragraphs"]]
    stats = {
        "cobol_files": len(cf), "java_files": len(jfiles),
        "paragraphs": len(all_paras),
        "cited": sum(1 for para in all_paras if para["cited_by"]),
        "covered": sum(1 for para in all_paras if para["covered"]),
        "links": sum(len(j["links"]) for j in jfiles),
        "unresolved_links": unresolved,
        "fixtures": fixtures,
        "described": sum(1 for para in all_paras if para["what"]),
        "guide": bool(guide["programs"]),
    }
    return {"module": module, "stats": stats, "cobol": cf, "java": jfiles}


def render_html(index: dict) -> str:
    tpl = TEMPLATE.read_text()
    data = json.dumps(index, ensure_ascii=False).replace("</", "<\\/")
    return tpl.replace("__MODULE__", index["module"]).replace("__DATA_JSON__", data)


def render_one(module: str, write: bool) -> list[str]:
    index = build_index(module)
    html = render_html(index)
    js = json.dumps({k: v for k, v in index.items() if k != "cobol" and k != "java"} | {
        "cobol": [{"path": f["path"], "paragraphs": f["paragraphs"], "programs": f["programs"]} for f in index["cobol"]],
        "java": [{"path": f["path"], "links": f["links"]} for f in index["java"]]}, indent=1, ensure_ascii=False)
    base = REPO_ROOT / "cobol" / module
    drift = []
    for path, content in ((base / "traceability.html", html), (base / "traceability.json", js + "\n")):
        if not path.exists() or path.read_text(encoding="utf-8") != content:
            drift.append(str(path.relative_to(REPO_ROOT)))
            if write:
                path.write_text(content, encoding="utf-8")
    s = index["stats"]
    print(f"{module}: {s['paragraphs']} paragraphs, {s['cited']} cited by Java, {s['described']} described, "
          f"{s['covered'] if s['fixtures'] else '-'} covered, {s['links']} links"
          f"{' (' + str(s['unresolved_links']) + ' unresolved)' if s['unresolved_links'] else ''}"
          + ("" if write else (" — DRIFT: " + ", ".join(drift) if drift else " — in sync")))
    return drift


def main(argv: list[str]) -> int:
    check = "--check" in argv
    args = [a for a in argv[1:] if a != "--check"]
    modules = args or module_list()
    drift: list[str] = []
    for mod in modules:
        drift += render_one(mod, write=not check)
    if check:
        print("all modules in sync" if not drift else f"{len(drift)} file(s) out of date")
        return 1 if drift else 0
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
