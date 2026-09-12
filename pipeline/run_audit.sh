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

# Live Grok (Spencer): key from env only — never commit keys or pass them on argv.
# XAI_API_KEY=… python pipeline/end_to_end_runner.py \
#   --target grok \
#   --bot-id "grok-bot-001" \
#   --scenarios-dir scenarios \
#   --limit 5 \
#   --out audit_report.json
# Optional: XAI_MODEL=grok-4.6 or --model grok-3-mini
