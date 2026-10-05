#!/usr/bin/env python3
"""jobman.py — helper for the multi-step job manifest `cobol/<module>/job.json`.

The manifest is the JCL analogue of a batch module: it lists the datasets
(name, organization, record length, key, sandbox path, whether it is a fixture
input or a captured output) and the ordered steps (program to run, DD-name →
dataset mapping, PARM, acceptable return codes).  Both `tools/run-job.py` (the
COBOL side) and the Java module read the same file, so step order, DD mapping
and capture rules can never drift between the two sides.

Usage:
    ./tools/jobman.py validate   <module>            # schema + cross-reference checks, exit 1 on error
    ./tools/jobman.py steps      <module>            # TSV: nn  name  group  exec  rc_ok  always
    ./tools/jobman.py captures   <module>            # sandbox paths that leave the sandbox (capture:true)
    ./tools/jobman.py inputs     <module>            # sandbox paths that must be staged from fixtures/<f>/in/
    ./tools/jobman.py lrecl      <module> <path>     # record length of a dataset given its sandbox path (basename)
    ./tools/jobman.py env        <module> <step>     # DD_<dd>=<path> lines + manifest env for a step
    ./tools/jobman.py build-cmds <module>            # cobc command lines, one per executable

Stdlib only (python 3.9).
"""
from __future__ import annotations

import json
import os
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent

VALID_ORG = {"ksds", "seq", "lseq"}


class ManifestError(Exception):
    pass


def manifest_path(module: str) -> Path:
    return REPO_ROOT / "cobol" / module / "job.json"


def load(module: str) -> dict:
    p = manifest_path(module)
    if not p.exists():
        raise ManifestError(f"no manifest at {p}")
    with p.open() as fh:
        return json.load(fh)


def validate(m: dict) -> list[str]:
    """Return a list of problems (empty = valid)."""
    errs: list[str] = []
    for key in ("job", "build", "datasets", "steps"):
        if key not in m:
            errs.append(f"missing top-level key '{key}'")
    if errs:
        return errs

    build = m["build"]
    if "executables" not in build or not isinstance(build["executables"], dict):
        errs.append("build.executables must be an object {name: [sources...]}")
    for name, srcs in build.get("executables", {}).items():
        if not isinstance(srcs, list) or not srcs:
            errs.append(f"executable '{name}' must list at least one source file")

    datasets = m["datasets"]
    paths_seen: dict[str, str] = {}
    for name, ds in datasets.items():
        org = ds.get("org")
        if org not in VALID_ORG:
            errs.append(f"dataset '{name}': org must be one of {sorted(VALID_ORG)}")
        lrecl = ds.get("lrecl")
        if not isinstance(lrecl, int) or lrecl <= 0:
            errs.append(f"dataset '{name}': lrecl must be a positive integer")
        path = ds.get("path")
        if not path or "/" in path or path.startswith("."):
            errs.append(f"dataset '{name}': path must be a plain file name inside the sandbox")
        elif path in paths_seen:
            errs.append(f"dataset '{name}': path '{path}' already used by dataset '{paths_seen[path]}'")
        else:
            paths_seen[path] = name
        if org == "ksds":
            key = ds.get("key")
            if not (isinstance(key, list) and len(key) == 2 and all(isinstance(k, int) for k in key)):
                errs.append(f"dataset '{name}': ksds needs key [offset, length]")
            for ak in ds.get("alt_keys", []):
                if not (isinstance(ak, list) and len(ak) == 2):
                    errs.append(f"dataset '{name}': alt_keys entries must be [offset, length]")
            if ds.get("capture"):
                errs.append(f"dataset '{name}': ksds files are never captured — add an UNLD step and capture its sequential output")
        if ds.get("input") and ds.get("capture"):
            errs.append(f"dataset '{name}': cannot be both input and capture")

    names_seen: set[str] = set()
    for i, st in enumerate(m["steps"], start=1):
        label = f"step {i} ({st.get('name', '?')})"
        for key in ("name", "exec", "dd"):
            if key not in st:
                errs.append(f"{label}: missing '{key}'")
        if st.get("name") in names_seen:
            errs.append(f"{label}: duplicate step name")
        names_seen.add(st.get("name", ""))
        if st.get("exec") not in build.get("executables", {}):
            errs.append(f"{label}: exec '{st.get('exec')}' is not in build.executables")
        for dd, ds in st.get("dd", {}).items():
            if ds not in datasets:
                errs.append(f"{label}: DD {dd} → unknown dataset '{ds}'")
        rc_ok = st.get("rc_ok", [0])
        if not (isinstance(rc_ok, list) and all(isinstance(r, int) for r in rc_ok)):
            errs.append(f"{label}: rc_ok must be a list of integers")
    return errs


def steps(m: dict) -> list[dict]:
    out = []
    for i, st in enumerate(m["steps"], start=1):
        out.append({
            "nn": f"{i:02d}",
            "name": st["name"],
            "group": st.get("group", ""),
            "exec": st["exec"],
            "rc_ok": st.get("rc_ok", [0]),
            "always": bool(st.get("always", False)),
            "parm": st.get("parm"),
            "dd": st.get("dd", {}),
        })
    return out


def captures(m: dict) -> list[str]:
    return sorted(ds["path"] for ds in m["datasets"].values() if ds.get("capture"))


def inputs(m: dict) -> list[str]:
    return sorted(ds["path"] for ds in m["datasets"].values() if ds.get("input"))


def lrecl_by_path(m: dict, path: str) -> int | None:
    base = os.path.basename(path)
    for ds in m["datasets"].values():
        if ds["path"] == base:
            return int(ds["lrecl"])
    return None


def step_env(m: dict, step: dict, sandbox: Path) -> dict[str, str]:
    env: dict[str, str] = {}
    env.update({k: str(v) for k, v in m.get("env", {}).items()})
    for dd, ds in step["dd"].items():
        env[f"DD_{dd}"] = str(sandbox / m["datasets"][ds]["path"])
    if step.get("parm") is not None:
        env["PARM"] = str(step["parm"])
    return env


def build_cmds(m: dict, module: str) -> list[tuple[str, list[str]]]:
    """[(executable_name, argv)] — argv is relative to cobol/<module>/."""
    flags = m["build"].get("cobc_flags", ["-x", "-O", "-Wall"])
    cmds = []
    for name, srcs in m["build"]["executables"].items():
        cmds.append((name, ["cobc", *flags, "-o", f"bin/{name}", *srcs]))
    return cmds


def main(argv: list[str]) -> int:
    if len(argv) < 3:
        print(__doc__, file=sys.stderr)
        return 2
    cmd, module = argv[1], argv[2]
    try:
        m = load(module)
    except ManifestError as e:
        print(f"ERROR: {e}", file=sys.stderr)
        return 1

    if cmd == "validate":
        errs = validate(m)
        for e in errs:
            print(f"ERROR: {e}")
        if errs:
            return 1
        print(f"OK: {manifest_path(module)} — {len(m['steps'])} steps, {len(m['datasets'])} datasets, "
              f"{len(captures(m))} captured outputs, {len(inputs(m))} inputs")
        return 0
    if cmd == "steps":
        for st in steps(m):
            print(f"{st['nn']}\t{st['name']}\t{st['group']}\t{st['exec']}\t{','.join(map(str, st['rc_ok']))}\t{'always' if st['always'] else ''}")
        return 0
    if cmd == "captures":
        print("\n".join(captures(m)))
        return 0
    if cmd == "inputs":
        print("\n".join(inputs(m)))
        return 0
    if cmd == "lrecl":
        if len(argv) < 4:
            print("usage: jobman.py lrecl <module> <path>", file=sys.stderr)
            return 2
        n = lrecl_by_path(m, argv[3])
        if n is None:
            return 1
        print(n)
        return 0
    if cmd == "env":
        if len(argv) < 4:
            print("usage: jobman.py env <module> <step>", file=sys.stderr)
            return 2
        for st in steps(m):
            if st["name"] == argv[3]:
                for k, v in step_env(m, st, Path("<sandbox>")).items():
                    print(f"{k}={v}")
                return 0
        print(f"no step named {argv[3]}", file=sys.stderr)
        return 1
    if cmd == "build-cmds":
        for name, cmdline in build_cmds(m, module):
            print(" ".join(cmdline))
        return 0
    print(f"unknown command {cmd}", file=sys.stderr)
    return 2


if __name__ == "__main__":
    sys.exit(main(sys.argv))
