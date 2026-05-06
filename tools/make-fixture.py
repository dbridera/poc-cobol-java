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


FIELDS = [
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
]


def fmt(field, kind, width, value):
    if value is None:
        value = "" if kind == "X" else 0
    if kind == "X":
        s = str(value).ljust(width)[:width]
    else:
        # numeric — right justify, zero-pad
        s = str(int(value)).zfill(width)[:width]
    return s


def render_record(rec: dict) -> str:
    parts = [fmt(name, kind, w, rec.get(name)) for (name, kind, w) in FIELDS]
    line = "".join(parts)
    if len(line) != sum(w for _, _, w in FIELDS):
        raise SystemExit(f"width mismatch: got {len(line)}, expected {sum(w for _,_,w in FIELDS)}")
    return line


def main(argv):
    if len(argv) < 3:
        print("usage: make-fixture.py <spec.json> <out.dat>", file=sys.stderr)
        return 2
    spec_path = Path(argv[1])
    out_path = Path(argv[2])
    spec = json.loads(spec_path.read_text())
    out_path.parent.mkdir(parents=True, exist_ok=True)
    with out_path.open("w") as f:
        for rec in spec["records"]:
            f.write(render_record(rec) + "\n")
    print(f"wrote {len(spec['records'])} records to {out_path}")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
