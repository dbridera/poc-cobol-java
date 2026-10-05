#!/usr/bin/env python3
"""run-job.py — execute a multi-step batch module (JCL analogue) against fixtures.

Reads `cobol/<module>/job.json` (see tools/jobman.py) and runs the job either
on the COBOL side (one GnuCOBOL executable per step, DD names mapped through
DD_<name> environment variables) or on the Java side (one Spring Batch JVM per
run). Both sides stage the same fixture inputs into a throw-away sandbox,
write per-step stdout + return code under out/steps/, and leave only the
datasets flagged `capture: true` in the manifest, so the two output trees can
be compared byte for byte by tools/compare-outputs.py.

Usage:
    ./tools/run-job.py [--side cobol|java] <module> [<fixture>]
                       [--plan "run" | --plan "abend-after=<STEP>;resume"]
                       [--keep-sandbox] [--verbose]

Output layout (identical shape to run-cobol.sh / run-java.sh):
    golden-master/<module>/<fixture>/   (side cobol)     java-run/<module>/<fixture>/   (side java)
        exit_code        max return code over every step executed in the job instance
        stdout.txt       per-step stdout concatenated with "=== nn-NAME RC=rrrr ===" headers
        stderr.txt       per-step stderr concatenated with the same headers
        out/run-log.txt  JOB / STEP / ABEND / END lines (byte-identical on both sides)
        out/steps/nn-NAME.stdout.txt, nn-NAME.rc
        out/<captured dataset files>

Plan semantics (JCL COND analogue, identical on both sides):
  - steps run in manifest order; a step whose RC is not in its rc_ok list marks the
    job FAILED and every later step is NOT RUN, except steps flagged `always: true`;
  - "abend-after=X" stops the run right after step X completes (a simulated kill),
    "resume" starts a second run that skips every step already completed;
  - exit code = MAXRC over all executed steps of the instance, so a resumed job
    reports the same code as an unbroken one.

Fixture overrides (cobol/<module>/fixtures/<fixture>/fixture.env, KEY=VALUE lines):
    JOB_PLAN="abend-after=INTCALC;resume"   default "run"
    JOB_PARM_<STEP>=value                   override a step's PARM
    JOB_ENV_<VAR>=value                     override/add a manifest env var
"""
from __future__ import annotations

import argparse
import os
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import jobman  # noqa: E402

REPO_ROOT = Path(__file__).resolve().parent.parent

ABEND_RC = 12


# ----------------------------------------------------------------------------- helpers

def read_env_file(path: Path) -> dict[str, str]:
    """Parse KEY=VALUE lines (optionally double/single quoted) — the subset of
    shell syntax that run-cobol.sh `source`s."""
    out: dict[str, str] = {}
    if not path.exists():
        return out
    for raw in path.read_text().splitlines():
        line = raw.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        k, v = line.split("=", 1)
        v = v.strip()
        if len(v) >= 2 and v[0] == v[-1] and v[0] in "\"'":
            v = v[1:-1]
        out[k.strip()] = v
    return out


def parse_plan(plan: str) -> list[dict]:
    """'run' -> [{'abend_after': None}];
    'abend-after=X;resume' -> [{'abend_after': 'X'}, {'abend_after': None}]."""
    plan = (plan or "run").strip()
    if plan == "run":
        return [{"abend_after": None}]
    runs: list[dict] = []
    for part in plan.split(";"):
        part = part.strip()
        if not part:
            continue
        if part.startswith("abend-after="):
            runs.append({"abend_after": part.split("=", 1)[1].strip()})
        elif part == "resume":
            runs.append({"abend_after": None})
        else:
            raise SystemExit(f"unknown plan element '{part}'")
    return runs


def fmt_rc(rc: int) -> str:
    return f"{rc:04d}"


class JobState:
    """The bash-side JobRepository: `<sandbox>/.jobstate` holds one line per
    completed step: NAME RC RUN."""

    def __init__(self, sandbox: Path):
        self.path = sandbox / ".jobstate"

    def completed(self) -> dict[str, tuple[int, int]]:
        done: dict[str, tuple[int, int]] = {}
        if self.path.exists():
            for line in self.path.read_text().splitlines():
                parts = line.split()
                if len(parts) == 3:
                    done[parts[0]] = (int(parts[1]), int(parts[2]))
        return done

    def record(self, name: str, rc: int, run: int) -> None:
        with self.path.open("a") as fh:
            fh.write(f"{name} {rc} {run}\n")

    def max_rc(self) -> int:
        return max([rc for rc, _ in self.completed().values()] or [0])


# ----------------------------------------------------------------------------- build

def build_cobol(module: str, m: dict, verbose: bool) -> None:
    mod_dir = REPO_ROOT / "cobol" / module
    bin_dir = mod_dir / "bin"
    bin_dir.mkdir(exist_ok=True)
    built = 0
    for name, argv in jobman.build_cmds(m, module):
        target = bin_dir / name
        srcs = [mod_dir / s for s in m["build"]["executables"][name]]
        cpy_dir = mod_dir / "copybooks"
        deps = list(srcs) + (list(cpy_dir.glob("*.cpy")) if cpy_dir.exists() else [])
        if target.exists() and all(target.stat().st_mtime >= d.stat().st_mtime for d in deps):
            continue
        if verbose:
            print("  " + " ".join(argv))
        res = subprocess.run(argv, cwd=mod_dir, capture_output=True, text=True)
        if res.returncode != 0:
            sys.stderr.write(res.stdout + res.stderr)
            raise SystemExit(f"cobc failed for {name}")
        built += 1
    print(f"==> build {module}: {len(m['build']['executables'])} executables ({built} compiled)")


def build_java(module: str) -> Path:
    java_dir = REPO_ROOT / "java" / module
    if not java_dir.exists():
        raise SystemExit(f"no java/ project at {java_dir}")
    print(f"==> building {module}")
    res = subprocess.run(["mvn", "-q", "-B", "-DskipTests", "package"], cwd=java_dir)
    if res.returncode != 0:
        raise SystemExit("maven build failed")
    jars = [p for p in (java_dir / "target").glob("*.jar") if not p.name.endswith(".original")]
    if not jars:
        raise SystemExit(f"JAR not found under {java_dir}/target/")
    return jars[0]


# ----------------------------------------------------------------------------- execution

def stage_inputs(fix_dir: Path, sandbox: Path, m: dict) -> None:
    in_dir = fix_dir / "in"
    if in_dir.exists():
        for p in in_dir.iterdir():
            if p.is_file():
                shutil.copy2(p, sandbox / p.name)
    missing = [p for p in jobman.inputs(m) if not (sandbox / p).exists()]
    if missing:
        raise SystemExit(f"fixture {fix_dir.name} is missing input files: {', '.join(missing)}")
    (sandbox / "out" / "steps").mkdir(parents=True)


def run_cobol_job(module: str, m: dict, sandbox: Path, runs: list[dict], overrides: dict[str, str],
                  stderr_chunks: list[str], verbose: bool) -> int:
    bin_dir = REPO_ROOT / "cobol" / module / "bin"
    steps = jobman.steps(m)
    state = JobState(sandbox)
    log_lines: list[str] = []
    job = m["job"]

    for run_no, run in enumerate(runs, start=1):
        log_lines.append(f"JOB {job} RUN {run_no}")
        done = state.completed()
        failed = False
        for st in steps:
            tag = f"STEP {st['nn']} {st['name']}"
            if st["name"] in done:
                line = f"{tag} SKIPPED (COMPLETED IN RUN {done[st['name']][1]})"
                log_lines.append(line)
                if verbose:
                    print("  " + line)
                continue
            if failed and not st["always"]:
                line = f"{tag} NOT RUN (JOB FAILED)"
                log_lines.append(line)
                if verbose:
                    print("  " + line)
                continue

            env = dict(os.environ)
            env.update(jobman.step_env(m, st, sandbox))
            for k, v in overrides.items():
                if k.startswith("JOB_ENV_"):
                    env[k[len("JOB_ENV_"):]] = v
            parm_override = overrides.get(f"JOB_PARM_{st['name']}")
            if parm_override is not None:
                env["PARM"] = parm_override

            out_file = sandbox / "out" / "steps" / f"{st['nn']}-{st['name']}.stdout.txt"
            with out_file.open("wb") as fh_out, open(os.devnull, "rb") as fh_in:
                res = subprocess.run([str(bin_dir / st["exec"])], cwd=sandbox, env=env,
                                     stdin=fh_in, stdout=fh_out, stderr=subprocess.PIPE)
            rc = res.returncode
            if res.stderr:
                stderr_chunks.append(f"=== {st['nn']}-{st['name']} ===\n" + res.stderr.decode("latin-1"))
            (sandbox / "out" / "steps" / f"{st['nn']}-{st['name']}.rc").write_text(f"{rc}\n")
            state.record(st["name"], rc, run_no)
            line = f"{tag} RC={fmt_rc(rc)}"
            log_lines.append(line)
            if verbose:
                print("  " + line)
            if rc not in st["rc_ok"]:
                failed = True
            if run["abend_after"] == st["name"]:
                line = f"ABEND AFTER {st['name']} (injected)"
                log_lines.append(line)
                if verbose:
                    print("  " + line)
                break
        else:
            # finished the step list without an injected abend
            pass

    max_rc = state.max_rc()
    log_lines.append(f"JOB {job} END MAXRC={fmt_rc(max_rc)}")
    (sandbox / "out" / "run-log.txt").write_text("\n".join(log_lines) + "\n")
    return max_rc


def run_java_job(module: str, m: dict, jar: Path, sandbox: Path, runs: list[dict], overrides: dict[str, str],
                 fixture: str, stderr_chunks: list[str], verbose: bool) -> int:
    """One JVM per run. The Spring Batch application mirrors the COBOL-side
    semantics (step order, rc_ok, always, skip-completed on restart) and
    writes out/steps/* and out/run-log.txt itself; its exit code is MAXRC."""
    manifest = jobman.manifest_path(module)
    last_rc = 0
    for run_no, run in enumerate(runs, start=1):
        argv = ["java", "-jar", str(jar),
                f"--manifest={manifest}", f"--workdir={sandbox}", f"--fixture={fixture}", f"--run={run_no}"]
        if run_no == len(runs):
            argv.append("--last-run=true")   # the JVM that writes the JOB ... END MAXRC line
        if run["abend_after"]:
            argv.append(f"--abend-after={run['abend_after']}")
        for k, v in overrides.items():
            if k.startswith("JOB_PARM_"):
                argv.append(f"--parm.{k[len('JOB_PARM_'):]}={v}")
            elif k.startswith("JOB_ENV_"):
                argv.append(f"--env.{k[len('JOB_ENV_'):]}={v}")
        if verbose:
            print("  " + " ".join(argv))
        with open(os.devnull, "rb") as fh_in:
            res = subprocess.run(argv, cwd=sandbox, stdin=fh_in, capture_output=True)
        if res.stderr:
            stderr_chunks.append(f"=== run {run_no} ===\n" + res.stderr.decode("latin-1"))
        if res.stdout and verbose:
            sys.stdout.write(res.stdout.decode("latin-1"))
        last_rc = res.returncode
    return last_rc


def compose_stdout(m: dict, sandbox: Path) -> str:
    """Concatenate per-step stdout files in manifest order with RC headers.
    Done in Python for BOTH sides so the framing can never differ."""
    parts: list[str] = []
    steps_dir = sandbox / "out" / "steps"
    for st in jobman.steps(m):
        out_file = steps_dir / f"{st['nn']}-{st['name']}.stdout.txt"
        rc_file = steps_dir / f"{st['nn']}-{st['name']}.rc"
        if not out_file.exists():
            continue
        rc = int(rc_file.read_text().strip()) if rc_file.exists() else 0
        parts.append(f"=== {st['nn']}-{st['name']} RC={fmt_rc(rc)} ===\n")
        parts.append(out_file.read_text(encoding="latin-1"))
    return "".join(parts)


def capture(m: dict, sandbox: Path, dest: Path, exit_code: int, stdout_text: str, stderr_chunks: list[str]) -> None:
    if dest.exists():
        shutil.rmtree(dest)
    (dest / "out").mkdir(parents=True)
    # per-step artifacts + run log
    shutil.copytree(sandbox / "out", dest / "out", dirs_exist_ok=True)
    # captured datasets only (never BDB files, never inputs, never the H2 database)
    for rel in jobman.captures(m):
        src = sandbox / rel
        if src.exists():
            shutil.copy2(src, dest / "out" / rel)
    (dest / "exit_code").write_text(f"{exit_code}\n")
    (dest / "stdout.txt").write_text(stdout_text, encoding="latin-1")
    (dest / "stderr.txt").write_text("".join(stderr_chunks), encoding="latin-1")


def run_fixture(side: str, module: str, m: dict, fixture: str, plan_arg: str | None, jar: Path | None,
                keep: bool, verbose: bool) -> None:
    fix_dir = REPO_ROOT / "cobol" / module / "fixtures" / fixture
    if not fix_dir.is_dir():
        raise SystemExit(f"missing fixture dir {fix_dir}")
    overrides = read_env_file(fix_dir / "fixture.env")
    plan = plan_arg or overrides.get("JOB_PLAN", "run")
    runs = parse_plan(plan)
    dest_root = "golden-master" if side == "cobol" else "java-run"
    dest = REPO_ROOT / dest_root / module / fixture

    sandbox = Path(tempfile.mkdtemp(prefix=f"job-{module}-"))
    print(f"==> fixture {fixture}  plan={plan}")
    stderr_chunks: list[str] = []
    try:
        stage_inputs(fix_dir, sandbox, m)
        if side == "cobol":
            exit_code = run_cobol_job(module, m, sandbox, runs, overrides, stderr_chunks, verbose)
        else:
            exit_code = run_java_job(module, m, jar, sandbox, runs, overrides, fixture, stderr_chunks, verbose)
        stdout_text = compose_stdout(m, sandbox)
        capture(m, sandbox, dest, exit_code, stdout_text, stderr_chunks)
        print(f"captured: {dest.relative_to(REPO_ROOT)}  (exit_code={exit_code})")
    finally:
        if keep:
            print(f"sandbox kept at {sandbox}")
        else:
            shutil.rmtree(sandbox, ignore_errors=True)


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--side", choices=["cobol", "java"], default="cobol")
    ap.add_argument("module")
    ap.add_argument("fixture", nargs="?")
    ap.add_argument("--plan", help='override the fixture plan, e.g. "abend-after=INTCALC;resume"')
    ap.add_argument("--keep-sandbox", action="store_true")
    ap.add_argument("--verbose", "-v", action="store_true")
    args = ap.parse_args()

    try:
        m = jobman.load(args.module)
    except jobman.ManifestError as e:
        raise SystemExit(f"ERROR: {e}")
    errs = jobman.validate(m)
    if errs:
        for e in errs:
            print(f"ERROR: {e}", file=sys.stderr)
        return 2

    jar = None
    if args.side == "cobol":
        if shutil.which("cobc") is None:
            raise SystemExit("ERROR: cobc (GnuCOBOL) not installed. See tools/setup.md")
        build_cobol(args.module, m, args.verbose)
    else:
        jar = build_java(args.module)

    fixtures_dir = REPO_ROOT / "cobol" / args.module / "fixtures"
    fixtures = [args.fixture] if args.fixture else sorted(p.name for p in fixtures_dir.iterdir() if p.is_dir())
    for f in fixtures:
        run_fixture(args.side, args.module, m, f, args.plan, jar, args.keep_sandbox, args.verbose)
    return 0


if __name__ == "__main__":
    sys.exit(main())
