#!/usr/bin/env python3
"""carddemo-fixture.py — build nightly-batch fixtures from AWS CardDemo seed data.

CardDemo ships its seed data twice: `app/data/ASCII/*.txt` (EBCDIC→ASCII
converted, line-terminated, some files CRLF, cardxref trimmed to 36 bytes) and
`app/data/EBCDIC/*.PS` (true fixed-length EBCDIC). The batch programs read
ORGANIZATION SEQUENTIAL files (fixed length, no terminators), so the data has
to be normalised before GnuCOBOL can load it.

Commands
    normalize <carddemo-root> <out-dir> [--ebcdic]
        Write fixed-length <name>.dat files (padded, CR/LF stripped). With
        --ebcdic also decode the .PS files (cp037) and assert they are
        byte-identical to the normalised ASCII — a consistency check of the two
        seed sets, and the proof that the EBCDIC path yields the same bytes.

    build <fixture-dir>
        Read <fixture-dir>/fixture.json and write <fixture-dir>/in/*.dat:
          {
            "source":     "../04-full-carddemo/in",          # normalised full set (default)
            "accounts":   [1, 2, 3, 4, 5],                    # subset by ACCT-ID (omit = all)
            "date_range": ["2022-07-18", "2022-07-18"],       # -> dateparm.dat
            "edits": [
              {"file": "acctdata", "where": {"ACCT-ID": 3}, "set": {"ACCT-EXPIRAION-DATE": "2022-01-01"}},
              {"file": "dailytran", "index": 4, "set": {"TRAN-CARD-NUM": "9999999999999999"}},
              {"file": "dailytran", "append": {"TRAN-ID": "...", "TRAN-AMT": "-919.00", ...}},
              {"file": "dailytran", "delete": {"where": {"TRAN-CARD-NUM": "..."}}},
              {"file": "dailytran", "keep": 12}               # truncate to the first N records
            ]
          }
        Subsetting keeps accounts, their cross-reference rows (by XREF-ACCT-ID),
        their category balances, and the daily transactions whose card belongs
        to a kept account. discgrp / trantype / trancatg are copied whole.

    dump <file.dat>
        Print the records of a known CardDemo file as JSON lines.

Stdlib only; record encoding lives in tools/make-fixture.py.
"""
from __future__ import annotations

import json
import shutil
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import importlib  # noqa: E402

mf = importlib.import_module("make-fixture")

# file stem -> (CardDemo ASCII source, EBCDIC source, layout)
FILES = {
    "acctdata":  ("acctdata.txt",  "AWS.M2.CARDDEMO.ACCTDATA.PS", "carddemo_account"),
    "cardxref":  ("cardxref.txt",  "AWS.M2.CARDDEMO.CARDXREF.PS", "carddemo_xref"),
    "tcatbal":   ("tcatbal.txt",   "AWS.M2.CARDDEMO.TCATBALF.PS", "carddemo_tcatbal"),
    "discgrp":   ("discgrp.txt",   "AWS.M2.CARDDEMO.DISCGRP.PS",  "carddemo_discgrp"),
    "trantype":  ("trantype.txt",  "AWS.M2.CARDDEMO.TRANTYPE.PS", "carddemo_trantype"),
    "trancatg":  ("trancatg.txt",  "AWS.M2.CARDDEMO.TRANCATG.PS", "carddemo_trancatg"),
    "dailytran": ("dailytran.txt", "AWS.M2.CARDDEMO.DALYTRAN.PS", "carddemo_tran"),
}
DATEPARM_LAYOUT = "carddemo_dateparm"


def layout_for(stem: str):
    if stem == "dateparm":
        return mf.LAYOUTS[DATEPARM_LAYOUT]
    return mf.LAYOUTS[FILES[stem][2]]


# ----------------------------------------------------------------------------- normalize

def normalize(root: Path, out_dir: Path, check_ebcdic: bool) -> int:
    out_dir.mkdir(parents=True, exist_ok=True)
    rc = 0
    for stem, (ascii_name, ebcdic_name, layout_name) in FILES.items():
        fields = mf.LAYOUTS[layout_name]
        lrecl = mf.record_length(fields)
        src = root / "app" / "data" / "ASCII" / ascii_name
        raw = src.read_bytes().decode("latin-1")
        lines = [ln.rstrip("\r") for ln in raw.split("\n")]
        if lines and lines[-1] == "":
            lines.pop()
        records = []
        for i, ln in enumerate(lines, start=1):
            if len(ln) > lrecl:
                raise SystemExit(f"{src.name} line {i}: {len(ln)} bytes > lrecl {lrecl}")
            records.append(ln.ljust(lrecl))
        mf.write_records(out_dir / f"{stem}.dat", records, newline=False)
        msg = f"{stem:<10} {len(records):>4} records x {lrecl:>3} bytes"
        if check_ebcdic:
            ps = root / "app" / "data" / "EBCDIC" / ebcdic_name
            eb = ps.read_bytes().decode("cp037")
            eb_records = [eb[i:i + lrecl] for i in range(0, len(eb), lrecl)]
            same = eb_records == records
            msg += f"  | EBCDIC {ps.name}: {len(eb_records)} records, {'IDENTICAL' if same else 'DIFFERENT'}"
            if not same:
                rc = 1
                for i, (a, b) in enumerate(zip(records, eb_records), start=1):
                    if a != b:
                        col = next(j for j in range(lrecl) if a[j] != b[j]) + 1
                        msg += f"\n           first difference record {i} column {col}: ascii={a[col-1]!r} ebcdic={b[col-1]!r}"
                        break
        print(msg)
    return rc


# ----------------------------------------------------------------------------- build

def _match(rec: dict, where: dict, fields) -> bool:
    fmap = {mf._field(f)[0]: mf._field(f) for f in fields}
    for k, v in where.items():
        name, kind, width, scale = fmap[k]
        if mf.encode_field(kind, width, scale, v) != mf.encode_field(kind, width, scale, rec[k]):
            return False
    return True


def _apply_set(rec: dict, values: dict, fields) -> dict:
    names = {mf._field(f)[0] for f in fields}
    for k in values:
        if k not in names:
            raise SystemExit(f"unknown field {k!r}; known: {sorted(names)}")
    new = dict(rec)
    new.update(values)
    return new


def build(fix_dir: Path) -> int:
    spec = json.loads((fix_dir / "fixture.json").read_text())
    source = (fix_dir / spec.get("source", "../04-full-carddemo/in")).resolve()
    in_dir = fix_dir / "in"
    in_dir.mkdir(exist_ok=True)

    data: dict[str, list[dict]] = {}
    for stem in FILES:
        fields = layout_for(stem)
        data[stem] = [mf.parse_record(r, fields) for r in mf.read_records(source / f"{stem}.dat", fields, newline=False)]

    accounts = spec.get("accounts")
    if accounts:
        keep_ids = {mf.encode_field("9", 11, 0, a) for a in accounts}
        data["acctdata"] = [r for r in data["acctdata"] if mf.encode_field("9", 11, 0, r["ACCT-ID"]) in keep_ids]
        data["cardxref"] = [r for r in data["cardxref"] if mf.encode_field("9", 11, 0, r["XREF-ACCT-ID"]) in keep_ids]
        data["tcatbal"] = [r for r in data["tcatbal"] if mf.encode_field("9", 11, 0, r["TRANCAT-ACCT-ID"]) in keep_ids]
        cards = {r["XREF-CARD-NUM"] for r in data["cardxref"]}
        data["dailytran"] = [r for r in data["dailytran"] if r["TRAN-CARD-NUM"] in cards]

    for edit in spec.get("edits", []):
        stem = edit["file"]
        fields = layout_for(stem)
        rows = data[stem]
        if "append" in edit:
            rows.append(mf.parse_record(mf.render_record(edit["append"], fields), fields))
        elif "delete" in edit:
            where = edit["delete"]["where"]
            before = len(rows)
            rows[:] = [r for r in rows if not _match(r, where, fields)]
            if len(rows) == before:
                raise SystemExit(f"delete matched nothing: {edit}")
        elif "keep" in edit:
            rows[:] = rows[: int(edit["keep"])]
        elif edit.get("clear"):
            rows.clear()
        else:
            targets = [edit["index"]] if "index" in edit else \
                [i for i, r in enumerate(rows) if _match(r, edit["where"], fields)]
            if not targets:
                raise SystemExit(f"edit matched nothing: {edit}")
            for i in targets:
                rows[i] = _apply_set(rows[i], edit["set"], fields)

    for stem in FILES:
        fields = layout_for(stem)
        mf.write_records(in_dir / f"{stem}.dat", [mf.render_record(r, fields) for r in data[stem]], newline=False)
        print(f"{stem:<10} {len(data[stem]):>4} records -> {in_dir / (stem + '.dat')}")

    start, end = spec.get("date_range", ["2022-07-18", "2022-07-18"])
    dp_fields = layout_for("dateparm")
    mf.write_records(in_dir / "dateparm.dat",
                     [mf.render_record({"WS-START-DATE": start, "WS-END-DATE": end}, dp_fields)], newline=False)
    print(f"dateparm   {start} to {end} -> {in_dir / 'dateparm.dat'}")
    return 0


def dump(path: Path) -> int:
    stem = path.stem
    fields = layout_for(stem)
    for raw in mf.read_records(path, fields, newline=False):
        print(json.dumps(mf.parse_record(raw, fields)))
    return 0


def main(argv: list[str]) -> int:
    if len(argv) < 3:
        print(__doc__, file=sys.stderr)
        return 2
    cmd = argv[1]
    if cmd == "normalize":
        if len(argv) < 4:
            print("usage: carddemo-fixture.py normalize <carddemo-root> <out-dir> [--ebcdic]", file=sys.stderr)
            return 2
        return normalize(Path(argv[2]), Path(argv[3]), "--ebcdic" in argv[4:])
    if cmd == "build":
        return build(Path(argv[2]))
    if cmd == "dump":
        return dump(Path(argv[2]))
    print(f"unknown command {cmd}", file=sys.stderr)
    return 2


if __name__ == "__main__":
    sys.exit(main(sys.argv))
