#!/usr/bin/env python3
"""make-fixture.py — emit (and read back) fixed-width COBOL records from JSON specs.

Field kinds
    X   alphanumeric, left-justified, space-padded
    9   unsigned numeric, right-justified, zero-padded (optional implied decimals: scale)
    S   signed numeric DISPLAY with trailing EBCDIC overpunch sign — the way
        mainframe data arrives in ASCII dumps: +504.77 in S9(9)V99 is '0000005047G',
        -919.00 is '0000009190}'. GnuCOBOL reads/writes it with `-fsign=EBCDIC`.

Layouts are named after the COBOL copybook they mirror; CardDemo layouts use
the COBOL data names as keys so fixture recipes can refer to fields by name.

Usage:
    ./tools/make-fixture.py <spec.json> <out.dat>          # spec: {"layout": ..., "records": [...], "newline": true|false}
    ./tools/make-fixture.py --dump <layout> <file.dat>      # print each record as one JSON object (inspect binary fixtures/golden masters)
    ./tools/make-fixture.py --layouts                       # list layouts and record lengths
"""
from __future__ import annotations

import json
import sys
from decimal import Decimal, ROUND_DOWN
from pathlib import Path

# Field tuple: (name, kind, width) or (name, kind, width, scale)
LAYOUTS: dict[str, list[tuple]] = {
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
    # ---- AWS CardDemo (module 3, nightly-batch). Record-sequential, no line terminators.
    # CVTRA05Y TRAN-RECORD / CVTRA06Y DALYTRAN-RECORD (same shape, DALYTRAN-* names), 350 bytes
    "carddemo_tran": [
        ("TRAN-ID",            "X", 16),
        ("TRAN-TYPE-CD",       "X", 2),
        ("TRAN-CAT-CD",        "9", 4),
        ("TRAN-SOURCE",        "X", 10),
        ("TRAN-DESC",          "X", 100),
        ("TRAN-AMT",           "S", 11, 2),
        ("TRAN-MERCHANT-ID",   "9", 9),
        ("TRAN-MERCHANT-NAME", "X", 50),
        ("TRAN-MERCHANT-CITY", "X", 50),
        ("TRAN-MERCHANT-ZIP",  "X", 10),
        ("TRAN-CARD-NUM",      "X", 16),
        ("TRAN-ORIG-TS",       "X", 26),
        ("TRAN-PROC-TS",       "X", 26),
        ("FILLER",             "X", 20),
    ],
    # CVACT01Y ACCOUNT-RECORD, 300 bytes
    "carddemo_account": [
        ("ACCT-ID",                "9", 11),
        ("ACCT-ACTIVE-STATUS",     "X", 1),
        ("ACCT-CURR-BAL",          "S", 12, 2),
        ("ACCT-CREDIT-LIMIT",      "S", 12, 2),
        ("ACCT-CASH-CREDIT-LIMIT", "S", 12, 2),
        ("ACCT-OPEN-DATE",         "X", 10),
        ("ACCT-EXPIRAION-DATE",    "X", 10),   # sic — spelled this way in the copybook
        ("ACCT-REISSUE-DATE",      "X", 10),
        ("ACCT-CURR-CYC-CREDIT",   "S", 12, 2),
        ("ACCT-CURR-CYC-DEBIT",    "S", 12, 2),
        ("ACCT-ADDR-ZIP",          "X", 10),
        ("ACCT-GROUP-ID",          "X", 10),
        ("FILLER",                 "X", 178),
    ],
    # CVACT03Y CARD-XREF-RECORD, 50 bytes
    "carddemo_xref": [
        ("XREF-CARD-NUM", "X", 16),
        ("XREF-CUST-ID",  "9", 9),
        ("XREF-ACCT-ID",  "9", 11),
        ("FILLER",        "X", 14),
    ],
    # CVTRA01Y TRAN-CAT-BAL-RECORD, 50 bytes
    "carddemo_tcatbal": [
        ("TRANCAT-ACCT-ID", "9", 11),
        ("TRANCAT-TYPE-CD", "X", 2),
        ("TRANCAT-CD",      "9", 4),
        ("TRAN-CAT-BAL",    "S", 11, 2),
        ("FILLER",          "X", 22),
    ],
    # CVTRA02Y DIS-GROUP-RECORD, 50 bytes
    "carddemo_discgrp": [
        ("DIS-ACCT-GROUP-ID", "X", 10),
        ("DIS-TRAN-TYPE-CD",  "X", 2),
        ("DIS-TRAN-CAT-CD",   "9", 4),
        ("DIS-INT-RATE",      "S", 6, 2),
        ("FILLER",            "X", 28),
    ],
    # CVTRA03Y TRAN-TYPE-RECORD, 60 bytes
    "carddemo_trantype": [
        ("TRAN-TYPE",      "X", 2),
        ("TRAN-TYPE-DESC", "X", 50),
        ("FILLER",         "X", 8),
    ],
    # CVTRA04Y TRAN-CAT-RECORD, 60 bytes
    "carddemo_trancatg": [
        ("TRAN-TYPE-CD",       "X", 2),
        ("TRAN-CAT-CD",        "9", 4),
        ("TRAN-CAT-TYPE-DESC", "X", 50),
        ("FILLER",             "X", 4),
    ],
    # CBTRN03C WS-DATEPARM-RECORD read INTO from an 80-byte record
    "carddemo_dateparm": [
        ("WS-START-DATE", "X", 10),
        ("FILLER",        "X", 1),
        ("WS-END-DATE",   "X", 10),
        ("FILLER-2",      "X", 59),
    ],
}
FIELDS = LAYOUTS["add_motor_policy"]  # back-compat default for existing callers

# EBCDIC overpunch of the last digit (as it appears after EBCDIC→ASCII conversion)
_POS = "{ABCDEFGHI"
_NEG = "}JKLMNOPQR"
_DECODE_SIGN = {c: (i, 1) for i, c in enumerate(_POS)}
_DECODE_SIGN.update({c: (i, -1) for i, c in enumerate(_NEG)})
_DECODE_SIGN.update({str(i): (i, 1) for i in range(10)})   # plain digit = positive (unsigned source)


def _field(f: tuple) -> tuple[str, str, int, int]:
    name, kind, width = f[0], f[1], f[2]
    scale = f[3] if len(f) > 3 else 0
    return name, kind, width, scale


def record_length(fields) -> int:
    return sum(_field(f)[2] for f in fields)


def encode_field(kind: str, width: int, scale: int, value) -> str:
    if value is None:
        value = "" if kind == "X" else 0
    if kind == "X":
        return str(value).ljust(width)[:width]
    q = Decimal(str(value)).scaleb(scale).quantize(Decimal(1), rounding=ROUND_DOWN)
    digits = str(abs(int(q))).zfill(width)
    if len(digits) > width:
        raise SystemExit(f"value {value} does not fit in {kind}({width}) scale {scale}")
    if kind == "9":
        return digits
    if kind == "S":
        last = int(digits[-1])
        sign_char = _NEG[last] if q < 0 else _POS[last]
        return digits[:-1] + sign_char
    raise SystemExit(f"unknown field kind {kind!r}")


def decode_field(kind: str, width: int, scale: int, raw: str):
    if kind == "X":
        return raw.rstrip()
    if kind == "9":
        return _scaled(int(raw) if raw.strip() else 0, scale)
    if kind == "S":
        body, last = raw[:-1], raw[-1]
        digit, sign = _DECODE_SIGN.get(last, (0, 1))
        n = int(body + str(digit)) if body.strip() else digit
        return _scaled(sign * n, scale)
    raise SystemExit(f"unknown field kind {kind!r}")


def _scaled(n: int, scale: int) -> str:
    if scale == 0:
        return str(n)
    s = str(Decimal(n).scaleb(-scale))
    return s


def render_record(rec: dict, fields) -> str:
    parts = []
    for f in fields:
        name, kind, width, scale = _field(f)
        parts.append(encode_field(kind, width, scale, rec.get(name)))
    line = "".join(parts)
    expected = record_length(fields)
    if len(line) != expected:
        raise SystemExit(f"width mismatch: got {len(line)}, expected {expected}")
    return line


def parse_record(line: str, fields) -> dict:
    out: dict = {}
    pos = 0
    for f in fields:
        name, kind, width, scale = _field(f)
        out[name] = decode_field(kind, width, scale, line[pos:pos + width])
        pos += width
    return out


def read_records(path: Path, fields, newline: bool | None = None) -> list[str]:
    """Return raw record strings. Auto-detects line-terminated vs fixed files
    unless `newline` is given."""
    raw = path.read_bytes().decode("latin-1")
    lrecl = record_length(fields)
    if newline is None:
        newline = "\n" in raw and len(raw) % lrecl != 0
    if newline:
        return [ln.rstrip("\r\n") for ln in raw.splitlines()]
    if len(raw) % lrecl:
        raise SystemExit(f"{path}: size {len(raw)} is not a multiple of lrecl {lrecl}")
    return [raw[i:i + lrecl] for i in range(0, len(raw), lrecl)]


def write_records(path: Path, records: list[str], newline: bool) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    data = ("\n".join(records) + ("\n" if records else "")) if newline else "".join(records)
    path.write_bytes(data.encode("latin-1"))


def main(argv):
    if len(argv) >= 2 and argv[1] == "--layouts":
        for name, fields in LAYOUTS.items():
            print(f"{name:<22} {record_length(fields):>4} bytes  {len(fields)} fields")
        return 0
    if len(argv) >= 4 and argv[1] == "--dump":
        layout_name, path = argv[2], Path(argv[3])
        fields = LAYOUTS[layout_name]
        for raw in read_records(path, fields):
            print(json.dumps(parse_record(raw, fields)))
        return 0
    if len(argv) < 3:
        print(__doc__, file=sys.stderr)
        return 2
    spec_path = Path(argv[1])
    out_path = Path(argv[2])
    spec = json.loads(spec_path.read_text())
    layout_name = spec.get("layout", "add_motor_policy")
    if layout_name not in LAYOUTS:
        raise SystemExit(f"unknown layout: {layout_name!r} (known: {sorted(LAYOUTS)})")
    fields = LAYOUTS[layout_name]
    records = [render_record(rec, fields) for rec in spec["records"]]
    write_records(out_path, records, newline=spec.get("newline", True))
    print(f"wrote {len(records)} records ({layout_name}) to {out_path}")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
