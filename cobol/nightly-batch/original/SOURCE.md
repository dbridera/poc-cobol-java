# Provenance of `original/`

Everything under this directory is copied **verbatim** from the AWS CardDemo
sample application and is never compiled from here. The compiled copies live in
`../src/` and `../copybooks/`; `tools/check-module.sh` verifies with `cmp` that
the three business programs there are byte-identical to these files.

| | |
|---|---|
| Repository | https://github.com/aws-samples/aws-mainframe-modernization-carddemo |
| Commit | `59cc6c2fd7ebd7ef7925cad552a01a4b8b6e4d5e` (2025-10-16) |
| License | Apache License 2.0 — see `LICENSE` in this directory |
| Taken on | 2026-10-04 |

## What was copied

| Path here | Path in CardDemo | Role in the nightly close |
|---|---|---|
| `cbl/CBTRN02C.cbl` | `app/cbl/CBTRN02C.cbl` | Step 1 — post the day's transactions (POSTTRAN) |
| `cbl/CBACT04C.cbl` | `app/cbl/CBACT04C.cbl` | Step 2 — monthly interest (INTCALC) |
| `cbl/CBTRN03C.cbl` | `app/cbl/CBTRN03C.cbl` | Step 4 — daily transaction report (TRANREPT) |
| `cpy/CVTRA06Y.cpy` | `app/cpy/CVTRA06Y.cpy` | DALYTRAN-RECORD — daily transaction input, 350 B |
| `cpy/CVTRA05Y.cpy` | `app/cpy/CVTRA05Y.cpy` | TRAN-RECORD — transaction master, 350 B |
| `cpy/CVACT03Y.cpy` | `app/cpy/CVACT03Y.cpy` | CARD-XREF-RECORD — card → customer/account, 50 B |
| `cpy/CVACT01Y.cpy` | `app/cpy/CVACT01Y.cpy` | ACCOUNT-RECORD, 300 B |
| `cpy/CVTRA01Y.cpy` | `app/cpy/CVTRA01Y.cpy` | TRAN-CAT-BAL-RECORD — balance per account/type/category, 50 B |
| `cpy/CVTRA02Y.cpy` | `app/cpy/CVTRA02Y.cpy` | DIS-GROUP-RECORD — interest rate per disclosure group, 50 B |
| `cpy/CVTRA03Y.cpy` | `app/cpy/CVTRA03Y.cpy` | TRAN-TYPE-RECORD, 60 B |
| `cpy/CVTRA04Y.cpy` | `app/cpy/CVTRA04Y.cpy` | TRAN-CAT-RECORD, 60 B |
| `cpy/CVTRA07Y.cpy` | `app/cpy/CVTRA07Y.cpy` | Report line layouts (headers, detail, totals) |
| `jcl/POSTTRAN.jcl` | `app/jcl/POSTTRAN.jcl` | JCL for step 1 |
| `jcl/INTCALC.jcl` | `app/jcl/INTCALC.jcl` | JCL for step 2 (PARM='2022071800') |
| `jcl/TRANBKP.jcl` | `app/jcl/TRANBKP.jcl` | Backup/empty the transaction master (REPRO) |
| `jcl/COMBTRAN.jcl` | `app/jcl/COMBTRAN.jcl` | Step 3 — DFSORT merge + REPRO reload |
| `jcl/TRANREPT.jcl` | `app/jcl/TRANREPT.jcl` | Step 4 — REPRO unload, DFSORT filter/sort, report program |
| `jcl/REPROC.prc`, `jcl/REPROCT.ctl` | `app/proc/REPROC.prc`, `app/ctl/REPROCT.ctl` | The REPRO procedure used by TRANBKP/TRANREPT |
| `data/ASCII/*.txt` | `app/data/ASCII/*.txt` | Seed data, EBCDIC→ASCII converted, line-terminated |
| `data/EBCDIC/*.PS` | `app/data/EBCDIC/*.PS` | Seed data, fixed-length EBCDIC (cp037) |
| `data/normalized/*.dat` | *(derived)* | `tools/carddemo-fixture.py normalize` output: fixed-length ASCII, no terminators, cardxref padded 36→50, CR/LF stripped |

## Known differences between the two seed sets

`tools/carddemo-fixture.py normalize --ebcdic` decodes the EBCDIC files with
cp037 and compares them with the normalised ASCII files. Five of seven are
byte-identical; two differ in a single byte each:

| File | Record | Column | ASCII | EBCDIC |
|---|---|---|---|---|
| acctdata | 49 | 103 (`ACCT-ADDR-ZIP`, 1st char) | `A` | `Z` |
| discgrp | 34 | 19 (`DIS-INT-RATE`, 3rd digit) | `0` | `1` |

The ASCII set is the fixture source; the EBCDIC set is used only by the
optional EBCDIC-input fixture, which therefore has its own golden master.

## Not copied

CICS online programs, BMS maps, IDCAMS DEFINE jobs, GDG definitions,
scheduler definitions and the DB2/IMS/MQ variants. The data-load JCL
(ACCTFILE, XREFFILE, TCATBALF, DISCGRP, TRANTYPE, TRANCATG) is replaced by the
generated loaders in `../src/ksds/`.
