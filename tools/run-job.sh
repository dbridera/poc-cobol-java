#!/usr/bin/env bash
# run-job.sh — COBOL-side wrapper for tools/run-job.py (multi-step job modules).
# Usage: ./tools/run-job.sh <module> [fixture] [--plan "..."] [--verbose] [--keep-sandbox]
exec "$(cd "$(dirname "$0")" && pwd)/run-job.py" --side cobol "$@"
