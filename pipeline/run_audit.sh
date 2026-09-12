#!/usr/bin/env bash
# Run the end-to-end audit against the stub bot (no API key needed).
set -euo pipefail

cd "$(dirname "$0")/.."

python pipeline/end_to_end_runner.py \
  --target stub \
  --bot-id "stub-bot-001" \
  --scenarios-dir scenarios \
  --limit 5 \
  --out audit_report.json

echo "Audit complete. See audit_report.json"
