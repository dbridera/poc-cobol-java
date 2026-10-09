#!/usr/bin/env python3
"""demo-agentic-eval.py — render a `claude -p --output-format stream-json` transcript for the stage.

Reads the stream (live from stdin, or a recorded .jsonl file) and prints only what an
audience needs to follow an agent at work: what the agent says, which commands it runs,
the tail of each result, and the final report. Everything else in the stream (hooks,
rate-limit events, task bookkeeping) is dropped.

    claude -p "..." --agent equivalence-validator --output-format stream-json --verbose | ./tools/demo-agentic-eval.py
    ./tools/demo-agentic-eval.py docs/demo/transcripts/agentic-eval-nightly-batch.jsonl --pace 0.8   # replay

Options:
    --pace S     replay pacing: seconds to wait before each agent message / command (default 0 = live)
    --lang es|en labels language (default es)
    --tail N     lines of each command result to show (default 4)

Stdlib only; exit code 0 when the final line of the report says RESULT: GREEN, 1 otherwise.
"""
from __future__ import annotations

import json
import sys
import textwrap
import time

TTY = sys.stdout.isatty()
G, R, C, Y, B, D, X = ("\033[32m", "\033[31m", "\033[36m", "\033[33m", "\033[1m", "\033[2m", "\033[0m") if TTY else ("",) * 7

LABELS = {
    "es": {"agent": "agente", "model": "modelo", "tools": "herramientas", "mode": "permisos",
           "ran": "corrió", "read": "lee", "grep": "busca", "turns": "turnos", "duration": "duración",
           "report": "INFORME DEL AGENTE", "error": "el agente terminó con error"},
    "en": {"agent": "agent", "model": "model", "tools": "tools", "mode": "permissions",
           "ran": "ran", "read": "reads", "grep": "greps", "turns": "turns", "duration": "duration",
           "report": "AGENT REPORT", "error": "the agent ended with an error"},
}


def main(argv: list[str]) -> int:
    pace, lang, tail, path = 0.0, "es", 4, None
    args = iter(argv[1:])
    for a in args:
        if a == "--pace":
            pace = float(next(args))
        elif a == "--lang":
            lang = next(args)
        elif a == "--tail":
            tail = int(next(args))
        else:
            path = a
    L = LABELS[lang]
    stream = open(path, encoding="utf-8") if path else sys.stdin
    green = False
    for raw in stream:
        raw = raw.strip()
        if not raw:
            continue
        try:
            e = json.loads(raw)
        except json.JSONDecodeError:
            continue
        t, st = e.get("type"), e.get("subtype")
        if t == "system" and st == "init":
            print(f"{D}  {L['agent']}: {e.get('agent') or 'equivalence-validator'} · {L['model']}: {e.get('model')} · "
                  f"{L['tools']}: {', '.join(e.get('tools', []))} · {L['mode']}: {e.get('permissionMode')}{X}")
            sys.stdout.flush()
            continue
        msg = e.get("message", {})
        content = msg.get("content") if isinstance(msg, dict) else None
        if t == "assistant" and isinstance(content, list):
            for b in content:
                if b.get("type") == "text" and b["text"].strip():
                    if "RESULT: GREEN" in b["text"] or "RESULT: RED" in b["text"]:
                        continue          # the final report: printed once, formatted, from the result event
                    if pace:
                        time.sleep(pace)
                    print()
                    for line in textwrap.wrap(b["text"].strip(), 110):
                        print(f"{C}  🤖 {line}{X}")
                elif b.get("type") == "tool_use":
                    if pace:
                        time.sleep(pace)
                    inp = b.get("input", {})
                    if b["name"] == "Bash":
                        desc = inp.get("description")
                        print(f"{B}  $ {inp.get('command', '')}{X}" + (f"  {D}# {desc}{X}" if desc else ""))
                    elif b["name"] == "Read":
                        print(f"{B}  {L['read']} {inp.get('file_path', '')}{X}")
                    elif b["name"] == "Grep":
                        print(f"{B}  {L['grep']} {inp.get('pattern', '')} {inp.get('path', '')}{X}")
                    else:
                        print(f"{B}  {b['name']} {json.dumps(inp)[:120]}{X}")
                sys.stdout.flush()
        elif t == "user" and isinstance(content, list):
            for b in content:
                if b.get("type") != "tool_result":
                    continue
                c = b.get("content")
                text = c if isinstance(c, str) else "\n".join(x.get("text", "") for x in (c or []) if isinstance(x, dict))
                lines = [ln for ln in text.splitlines() if ln.strip()]
                shown = lines[-tail:] if tail else []
                if len(lines) > len(shown):
                    print(f"{D}    … ({len(lines) - len(shown)} {'líneas más' if lang == 'es' else 'more lines'}){X}")
                for ln in shown:
                    print(f"{D}    {ln[:140]}{X}")
                if pace:
                    time.sleep(pace / 2)
                sys.stdout.flush()
        elif t == "result":
            print()
            dur = e.get("duration_ms", 0) / 1000
            print(f"{D}  {L['turns']}: {e.get('num_turns')} · {L['duration']}: {dur:.0f}s{X}")
            if e.get("is_error"):
                print(f"{R}{B}  {L['error']}{X}")
            result = str(e.get("result") or "").strip()
            if result:
                print(f"{B}  ── {L['report']} ──{X}")
                for ln in result.splitlines():
                    s = ln.rstrip()
                    if "RESULT: GREEN" in s:
                        green = True
                        print(f"{G}{B}  {s}{X}")
                    elif "RESULT: RED" in s or s.lstrip().startswith("[FAIL]"):
                        print(f"{R}{B}  {s}{X}")
                    elif s.lstrip().startswith("[OK]"):
                        print(f"{G}  {s}{X}")
                    else:
                        print(f"  {s}")
            sys.stdout.flush()
    return 0 if green else 1


if __name__ == "__main__":
    sys.exit(main(sys.argv))
