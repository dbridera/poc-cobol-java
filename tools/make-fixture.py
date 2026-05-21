#!/usr/bin/env python3
"""make-fixture.py — emit fixed-width add-motor-policy request records.

The COBOL FD lays out REQUEST-RECORD as 143 chars:
    REQUEST-ID         X(6)
    CUSTOMER-NUM       9(10)
    POLICY-NUM         9(10)   (caller-supplied; 0 for new)
    ISSUE-DATE         X(10)
    EXPIRY-DATE        X(10)
    BROKER-ID          9(10)
    BROKERS-REF        X(10)
    PAYMENT            9(6)
    MAKE               X(15)
    MODEL              X(15)
    VALUE              9(6)
    REGNUMBER          X(7)
    COLOUR             X(8)
    CC                 9(4)
    MANUFACTURED       X(10)
    ACCIDENTS          9(6)

Usage: see fixture *.spec.json files which list record dicts. This script
reads a spec, emits requests.dat with fixed-width fields.
"""
from __future__ import annotations
import json
import sys
from pathlib import Path


LAYOUTS = {
    # Module zero: ADDMPOL.cbl, 143 chars (motor policy add).
    "add_motor_policy": [
        ("request_id",    "X", 6),
        ("customer_num",  "9", 10),
        ("policy_num",    "9", 10),
        ("issue_date",    "X", 10),
        ("expiry_date",   "X", 10),
        ("broker_id",     "9", 10),
        ("brokers_ref",   "X", 10),
        ("payment",       "9", 6),
        ("make",          "X", 15),
        ("model",         "X", 15),
        ("value",         "9", 6),
        ("regnumber",     "X", 7),
        ("colour",        "X", 8),
        ("cc",            "9", 4),
        ("manufactured",  "X", 10),
        ("accidents",     "9", 6),
    ],
    # Module 1B: ADDPOLDB.cbl, 99 chars (POLICY-table insert via shim).
    # Includes fixture-controlled policy_num + lastchanged to keep both
    # COBOL and Java sides byte-deterministic without DB-side defaults.
    "add_policy_db": [
        ("request_id",    "X", 6),
        ("policy_num",    "9", 10),
        ("customer_num",  "9", 10),
        ("issue_date",    "X", 10),
        ("expiry_date",   "X", 10),
        ("policy_type",   "X", 1),
        ("lastchanged",   "X", 26),
        ("broker_id",     "9", 10),
        ("brokers_ref",   "X", 10),
        ("payment",       "9", 6),
    ],
}
FIELDS = LAYOUTS["add_motor_policy"]  # back-compat default for existing callers


def fmt(field, kind, width, value):
    if value is None:
        value = "" if kind == "X" else 0
    if kind == "X":
        s = str(value).ljust(width)[:width]
    else:
        # numeric — right justify, zero-pad
        s = str(int(value)).zfill(width)[:width]
    return s


def render_record(rec: dict, fields) -> str:
    parts = [fmt(name, kind, w, rec.get(name)) for (name, kind, w) in fields]
    line = "".join(parts)
    expected = sum(w for _, _, w in fields)
    if len(line) != expected:
        raise SystemExit(f"width mismatch: got {len(line)}, expected {expected}")
    return line


def main(argv):
    if len(argv) < 3:
        print("usage: make-fixture.py <spec.json> <out.dat>", file=sys.stderr)
        return 2
    spec_path = Path(argv[1])
    out_path = Path(argv[2])
    spec = json.loads(spec_path.read_text())
    layout_name = spec.get("layout", "add_motor_policy")
    if layout_name not in LAYOUTS:
        raise SystemExit(f"unknown layout: {layout_name!r} (known: {sorted(LAYOUTS)})")
    fields = LAYOUTS[layout_name]
    out_path.parent.mkdir(parents=True, exist_ok=True)
    with out_path.open("w") as f:
        for rec in spec["records"]:
            f.write(render_record(rec, fields) + "\n")
    print(f"wrote {len(spec['records'])} records ({layout_name}) to {out_path}")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
