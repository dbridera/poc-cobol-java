#!/usr/bin/env python3
"""render-dependencies.py — generate Mermaid + Cytoscape.js diagrams from DEPENDENCIES.md.

For each cobol/<module>/DEPENDENCIES.md the script:
  1. Parses the 8-section schema (§1 Programs, §3 CALLs, §4 Copybooks,
     §5 Files, §6 SQL). §2 PERFORM tree and §7 CICS are intentionally
     skipped — see the plan in ~/.claude/plans/ for V1 scope.
  2. Emits a Mermaid block injected between idempotent markers in
     DEPENDENCIES.md (inserts a "## Diagram" section if absent).
  3. Emits cobol/<module>/dependency-graph.html (standalone Cytoscape.js
     dashboard; opens offline; graph data inlined).

Usage:
    ./tools/render-dependencies.py              # render all modules
    ./tools/render-dependencies.py <module>     # render one module
    ./tools/render-dependencies.py --check      # exit 1 if any module's
                                                # generated artifacts drift
                                                # from the current source
                                                # (suitable for CI)

No third-party deps. Python 3.10+.
"""
from __future__ import annotations

import argparse
import json
import re
import sys
from dataclasses import dataclass, field
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent
COBOL_DIR = REPO_ROOT / "cobol"
TEMPLATE_PATH = REPO_ROOT / "tools" / "render-dependencies" / "dashboard.html.tmpl"

MARKER_BEGIN = "<!-- BEGIN AUTO-GENERATED DIAGRAM (render-dependencies.py) -->"
MARKER_END = "<!-- END AUTO-GENERATED DIAGRAM -->"
DIAGRAM_SECTION_HEADER = "## Diagram"


# ---------------------------- data types ------------------------------------

@dataclass
class Node:
    id: str
    type: str   # program | program-nested | copybook | file-in | file-out | sql-table | shim
    label: str


@dataclass
class Edge:
    src: str
    dst: str
    label: str


@dataclass
class Graph:
    module: str
    nodes: list[Node] = field(default_factory=list)
    edges: list[Edge] = field(default_factory=list)

    def add_node(self, nid: str, ntype: str, label: str | None = None) -> None:
        for n in self.nodes:
            if n.id == nid:
                return
        self.nodes.append(Node(nid, ntype, label or nid))

    def add_edge(self, src: str, dst: str, label: str) -> None:
        for e in self.edges:
            if e.src == src and e.dst == dst and e.label == label:
                return
        self.edges.append(Edge(src, dst, label))

    def to_json(self) -> dict:
        return {
            "module": self.module,
            "nodes": [{"id": n.id, "type": n.type, "label": n.label} for n in self.nodes],
            "edges": [{"src": e.src, "dst": e.dst, "label": e.label} for e in self.edges],
        }


# ---------------------------- markdown parsing ------------------------------

SECTION_RE = re.compile(r'^##\s+(\d+)\.\s+(.+?)\s*$', re.MULTILINE)
SEPARATOR_RE = re.compile(r'^\|\s*[:\-]+\s*(\|\s*[:\-]+\s*)+\|\s*$')


def split_sections(text: str) -> dict[int, str]:
    """Return {section_number: section_body_text} from the numbered H2 headers."""
    matches = list(SECTION_RE.finditer(text))
    sections: dict[int, str] = {}
    for i, m in enumerate(matches):
        num = int(m.group(1))
        start = m.end()
        end = matches[i + 1].start() if i + 1 < len(matches) else len(text)
        sections[num] = text[start:end]
    return sections


def find_tables(body: str) -> list[list[list[str]]]:
    """Return a list of tables; each table is rows of cells. First row is the header."""
    lines = body.splitlines()
    tables: list[list[list[str]]] = []
    i = 0
    while i < len(lines):
        if (i + 1 < len(lines)
                and lines[i].lstrip().startswith('|')
                and SEPARATOR_RE.match(lines[i + 1].strip())):
            rows = [parse_row(lines[i])]
            j = i + 2
            while j < len(lines) and lines[j].lstrip().startswith('|'):
                rows.append(parse_row(lines[j]))
                j += 1
            tables.append(rows)
            i = j
        else:
            i += 1
    return tables


def parse_row(line: str) -> list[str]:
    s = line.strip()
    if s.startswith('|'):
        s = s[1:]
    if s.endswith('|'):
        s = s[:-1]
    return [clean_cell(c) for c in s.split('|')]


def clean_cell(s: str) -> str:
    """Strip markdown link syntax and code backticks, leave plain text."""
    s = re.sub(r'\[([^\]]+)\]\([^)]+\)', r'\1', s)
    s = re.sub(r'`([^`]*)`', r'\1', s)
    return s.strip()


def is_none_section(body: str) -> bool:
    return body.strip().lower().startswith('none')


# ---------------------------- section parsers -------------------------------

def parse_programs(body: str) -> list[tuple[str, bool]]:
    """Return [(program_id, is_nested), ...]."""
    tables = find_tables(body)
    if not tables:
        return []
    programs: list[tuple[str, bool]] = []
    for r in tables[0][1:]:
        if not r or not r[0]:
            continue
        pid = r[0]
        rest = ' '.join(r[1:]).lower()
        nested = 'nested' in rest
        programs.append((pid, nested))
    return programs


def parse_calls(body: str, default_caller: str) -> list[tuple[str, str, str]]:
    """Return [(caller_program, callee, callee_kind), ...]. callee_kind: 'program' | 'shim'."""
    if is_none_section(body):
        return []
    tables = find_tables(body)
    if not tables:
        return []
    out: list[tuple[str, str, str]] = []
    for r in tables[0][1:]:
        if len(r) < 3:
            continue
        caller_cell, call_cell, target_cell = r[0], r[1], r[2]
        caller = extract_caller(caller_cell, default_caller)
        callees = extract_callees(call_cell, target_cell)
        for callee in callees:
            kind = 'shim' if is_shim(callee) else 'program'
            out.append((caller, callee, kind))
    return out


CALLER_IN_RE = re.compile(r'\(in\s+([A-Za-z0-9_\-]+)\)')


def extract_caller(cell: str, default: str) -> str:
    m = CALLER_IN_RE.search(cell)
    return m.group(1) if m else default


CALL_QUOTED_ARG_RE = re.compile(r'''CALL\s+["']([^"']+)["']''')
NESTED_NAME_RE = re.compile(r'nested\s+([A-Z][A-Z0-9_\-]+)')


def extract_callees(call_cell: str, target_cell: str) -> list[str]:
    """Collect all callees from a single §3 row.

    Handles the shorthand 'CALL "cob_sqlite_open / _exec / _dump / _close"'
    by expanding each '/' segment beginning with '_' into a full identifier
    sharing the prefix of the first segment.
    """
    callees: list[str] = []
    for arg in CALL_QUOTED_ARG_RE.findall(call_cell):
        callees.extend(_expand_call_arg(arg))
    seen: list[str] = []
    for c in callees:
        if c not in seen:
            seen.append(c)
    if seen:
        return seen
    m = NESTED_NAME_RE.search(target_cell)
    return [m.group(1)] if m else []


def _expand_call_arg(arg: str) -> list[str]:
    parts = [p.strip() for p in arg.split('/')]
    if not parts or not parts[0]:
        return []
    if len(parts) == 1:
        return [parts[0]]
    expanded = [parts[0]]
    prefix_m = re.match(r'^(.*_)[^_]+$', parts[0])
    prefix = prefix_m.group(1) if prefix_m else ''
    for p in parts[1:]:
        if p.startswith('_') and prefix:
            expanded.append(prefix + p.lstrip('_'))
        elif p:
            expanded.append(p)
    return expanded


def is_shim(name: str) -> bool:
    return name.startswith('cob_') or name.startswith('lib') or name.startswith('_')


def parse_copybooks(body: str) -> list[tuple[str, list[str]]]:
    """Return [(copybook_id, [program_ids]), ...]. Skips audit-only entries."""
    if is_none_section(body):
        return []
    tables = find_tables(body)
    if not tables:
        return []
    out: list[tuple[str, list[str]]] = []
    for r in tables[0][1:]:
        if len(r) < 3:
            continue
        cb_cell, _toplevel, used_by_cell = r[0], r[1], r[2]
        if 'audit-only' in (cb_cell + used_by_cell).lower():
            continue
        cb = derive_copybook_id(cb_cell)
        programs = parse_used_by(used_by_cell)
        if cb and programs:
            out.append((cb, programs))
    return out


COPYBOOK_NAME_RE = re.compile(r'([A-Za-z0-9_\-]+)\.(?:cpy|CPY)')


def derive_copybook_id(cell: str) -> str:
    m = COPYBOOK_NAME_RE.search(cell)
    return m.group(1).upper() if m else ''


USED_BY_PROGRAM_RE = re.compile(r'([A-Z][A-Z0-9_\-]{2,})')


def parse_used_by(cell: str) -> list[str]:
    """E.g. 'DRIVER-BCTITSCV · WORKING-STORAGE; BCTITSCV · LINKAGE'.
    The 'section' tokens (WORKING-STORAGE / LINKAGE / PROCEDURE) are filtered out.
    """
    blacklist = {'WORKING-STORAGE', 'LINKAGE', 'PROCEDURE', 'COPY', 'DATA'}
    programs: list[str] = []
    for part in cell.split(';'):
        for m in USED_BY_PROGRAM_RE.findall(part):
            if m in blacklist or m in programs:
                continue
            programs.append(m)
            break  # first identifier per `;`-segment is the program ID
    return programs


def parse_files(body: str, default_program: str) -> list[tuple[str, str, str, str]]:
    """Return [(program, file_label, direction, file_kind), ...]."""
    if is_none_section(body):
        return []
    tables = find_tables(body)
    if not tables:
        return []
    out: list[tuple[str, str, str, str]] = []
    for r in tables[0][1:]:
        if len(r) < 4:
            continue
        logical_cell, path_cell, _org_cell, open_mode = r[0], r[1], r[2], r[3]
        label = derive_file_label(logical_cell, path_cell)
        if not label:
            continue
        mode = open_mode.upper()
        if 'INPUT' in mode:
            direction, kind = 'in', 'file-in'
        else:
            direction, kind = 'out', 'file-out'
        out.append((default_program, label, direction, kind))
    return out


FILE_NAME_RE = re.compile(r'([A-Za-z0-9_\-/]+\.[A-Za-z0-9]+)')


def derive_file_label(logical: str, path: str) -> str:
    """Use the basename of the path if present (e.g. 'requests.dat')."""
    logical = re.sub(r'^\(out\)\s*', '', logical).strip()
    m = FILE_NAME_RE.search(path)
    if m:
        return m.group(1).rsplit('/', 1)[-1]
    return logical


def parse_sql(body: str, default_program: str) -> list[tuple[str, str, str]]:
    """Return [(issuer_program, table, verb), ...]. Handles 4- and 5-column variants."""
    if is_none_section(body):
        return []
    tables = find_tables(body)
    if not tables:
        return []
    header = [h.lower() for h in tables[0][0]]
    stmt_idx = next((i for i, h in enumerate(header) if 'statement' in h), 0)
    issuer_idx = next((i for i, h in enumerate(header) if 'issued by' in h), None)
    table_idx = next((i for i, h in enumerate(header) if h.strip() == 'table'), None)
    if table_idx is None:
        return []
    out: list[tuple[str, str, str]] = []
    for r in tables[0][1:]:
        if len(r) <= max(stmt_idx, table_idx):
            continue
        stmt = r[stmt_idx]
        table_cell = r[table_idx]
        verb_m = re.match(r'^([A-Za-z]+)', stmt)
        verb = verb_m.group(1).upper() if verb_m else stmt.strip()
        table_m = re.search(r'([A-Z][A-Z0-9_]+)', table_cell)
        if not table_m:
            continue
        table_name = table_m.group(1)
        issuer = default_program
        if issuer_idx is not None and len(r) > issuer_idx:
            m = re.search(r'([A-Z][A-Z0-9_\-]+)', r[issuer_idx])
            if m:
                issuer = m.group(1)
        out.append((issuer, table_name, verb))
    return out


# ---------------------------- graph build -----------------------------------

def build_graph(module: str, md_path: Path) -> Graph:
    text = md_path.read_text()
    sections = split_sections(text)
    g = Graph(module=module)

    programs = parse_programs(sections.get(1, ''))
    if not programs:
        return g
    default_program = programs[0][0]

    for pid, nested in programs:
        g.add_node(pid, 'program-nested' if nested else 'program', pid)

    for caller, callee, kind in parse_calls(sections.get(3, ''), default_program):
        g.add_node(callee, kind, callee)
        g.add_node(caller, 'program', caller)
        g.add_edge(caller, callee, 'CALL')

    for cb, programs_using in parse_copybooks(sections.get(4, '')):
        g.add_node(cb, 'copybook', cb)
        for p in programs_using:
            g.add_node(p, 'program', p)
            g.add_edge(p, cb, 'COPY')

    for program, file_label, direction, kind in parse_files(sections.get(5, ''), default_program):
        g.add_node(file_label, kind, file_label)
        if direction == 'in':
            g.add_edge(file_label, program, 'READ')
        else:
            g.add_edge(program, file_label, 'WRITE')

    for issuer, table, verb in parse_sql(sections.get(6, ''), default_program):
        g.add_node(table, 'sql-table', table)
        g.add_node(issuer, 'program', issuer)
        g.add_edge(issuer, table, verb)

    return g


# ---------------------------- renderers -------------------------------------

CLASS_MAP = {
    'program':        'program',
    'program-nested': 'programNested',
    'copybook':       'copybook',
    'file-in':        'fileIn',
    'file-out':       'fileOut',
    'sql-table':      'sqlTable',
    'shim':           'shim',
}

MERMAID_CLASSDEFS = [
    "classDef program fill:#cfe2ff,stroke:#0d6efd,stroke-width:2px,color:#0a3678",
    "classDef programNested fill:#bcd6fb,stroke:#0d6efd,stroke-width:2px,stroke-dasharray:5 3,color:#0a3678",
    "classDef copybook fill:#d1e7dd,stroke:#198754,stroke-width:2px,color:#0f4d2e",
    "classDef fileIn fill:#fff3cd,stroke:#fd7e14,stroke-width:2px,color:#7a3a02",
    "classDef fileOut fill:#fcd5b5,stroke:#fd7e14,stroke-width:2px,color:#7a3a02",
    "classDef sqlTable fill:#e2d6f5,stroke:#6f42c1,stroke-width:2px,color:#3d2367",
    "classDef shim fill:#e9ecef,stroke:#6c757d,stroke-width:2px,color:#495057",
]


def mermaid_id(name: str) -> str:
    return re.sub(r'[^A-Za-z0-9]', '_', name) or 'NODE'


def emit_mermaid(g: Graph) -> str:
    out: list[str] = ["```mermaid", "flowchart LR"]
    for cd in MERMAID_CLASSDEFS:
        out.append("    " + cd)
    if not g.nodes:
        out.append('    empty["(no dependencies found)"]')
        out.append("```")
        return "\n".join(out)
    for n in g.nodes:
        cls = CLASS_MAP.get(n.type, 'program')
        out.append(f'    {mermaid_id(n.id)}["{n.label}"]:::{cls}')
    for e in g.edges:
        out.append(f'    {mermaid_id(e.src)} -->|{e.label}| {mermaid_id(e.dst)}')
    out.append("```")
    return "\n".join(out)


def render_html(g: Graph) -> str:
    tpl = TEMPLATE_PATH.read_text()
    return (tpl
            .replace('__MODULE__', g.module)
            .replace('__GRAPH_JSON__', json.dumps(g.to_json(), indent=2)))


# ---------------------------- markdown injection ----------------------------

BLOCK_RE = re.compile(re.escape(MARKER_BEGIN) + r'.*?' + re.escape(MARKER_END),
                      re.DOTALL)


def build_block(mermaid: str) -> str:
    return f"{MARKER_BEGIN}\n\n{mermaid}\n\n{MARKER_END}"


def inject_diagram(md_path: Path, mermaid: str) -> bool:
    """Inject the Mermaid block; returns True if file content changed."""
    text = md_path.read_text()
    block = build_block(mermaid)
    if MARKER_BEGIN in text and MARKER_END in text:
        new_text = BLOCK_RE.sub(block.replace('\\', r'\\'), text)
    else:
        # Insert a new "## Diagram" section after the first "---" rule
        # (which separates the title prose from §1). Falls back to appending.
        section = f"\n{DIAGRAM_SECTION_HEADER}\n\n{block}\n\n---\n"
        first_rule = re.search(r'^---\s*$', text, re.MULTILINE)
        if first_rule:
            new_text = text[:first_rule.end()] + "\n" + section + text[first_rule.end():]
        else:
            new_text = text.rstrip() + "\n\n" + section
    if new_text != text:
        md_path.write_text(new_text)
        return True
    return False


# ---------------------------- driver ----------------------------------------

def iter_modules() -> list[Path]:
    return sorted(p for p in COBOL_DIR.iterdir()
                  if p.is_dir() and (p / "DEPENDENCIES.md").exists())


def render_one(module_dir: Path, write: bool = True) -> tuple[bool, bool]:
    """Render Mermaid + HTML for one module. Returns (md_changed, html_changed)."""
    module = module_dir.name
    md = module_dir / "DEPENDENCIES.md"
    g = build_graph(module, md)
    mermaid = emit_mermaid(g)
    html = render_html(g)
    html_path = module_dir / "dependency-graph.html"

    if write:
        md_changed = inject_diagram(md, mermaid)
        html_changed = (not html_path.exists()) or (html_path.read_text() != html)
        if html_changed:
            html_path.write_text(html)
    else:
        existing_md = md.read_text()
        expected_md = existing_md
        m = BLOCK_RE.search(existing_md)
        if m:
            expected_md = existing_md[:m.start()] + build_block(mermaid) + existing_md[m.end():]
        else:
            # no marker yet => drift
            expected_md = existing_md + "DRIFT-NO-BLOCK"
        md_changed = expected_md != existing_md
        html_changed = (not html_path.exists()) or (html_path.read_text() != html)

    return md_changed, html_changed


def cmd_render(target: str | None) -> int:
    modules = iter_modules()
    if target:
        modules = [m for m in modules if m.name == target]
        if not modules:
            print(f"no module '{target}' under {COBOL_DIR}", file=sys.stderr)
            return 2
    for module_dir in modules:
        md_changed, html_changed = render_one(module_dir, write=True)
        flags = []
        if md_changed:
            flags.append("DEPENDENCIES.md")
        if html_changed:
            flags.append("dependency-graph.html")
        if flags:
            print(f"updated {module_dir.name}: {', '.join(flags)}")
        else:
            print(f"unchanged {module_dir.name}")
    return 0


def cmd_check() -> int:
    drift: list[str] = []
    for module_dir in iter_modules():
        md_changed, html_changed = render_one(module_dir, write=False)
        if md_changed or html_changed:
            parts = []
            if md_changed:
                parts.append("DEPENDENCIES.md")
            if html_changed:
                parts.append("dependency-graph.html")
            drift.append(f"{module_dir.name} ({', '.join(parts)})")
    if drift:
        print("out of sync:", file=sys.stderr)
        for d in drift:
            print(f"  - {d}", file=sys.stderr)
        print("\nRun: ./tools/render-dependencies.py", file=sys.stderr)
        return 1
    print("all modules in sync")
    return 0


def main(argv: list[str]) -> int:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument('module', nargs='?', help='module name (default: all)')
    parser.add_argument('--check', action='store_true',
                        help='exit non-zero if any artifact is out of sync')
    args = parser.parse_args(argv)
    if args.check:
        if args.module:
            print("--check does not take a module argument", file=sys.stderr)
            return 2
        return cmd_check()
    return cmd_render(args.module)


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
