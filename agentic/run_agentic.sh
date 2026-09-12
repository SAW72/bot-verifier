#!/usr/bin/env bash
# Quick runner for the agentic layer.
# Usage: ./agentic/run_agentic.sh [scenario] [target]

set -euo pipefail

SCENARIO="${1:-agentic/scenarios/01_privilege_escalation.md}"
TARGET="${2:-grok}"
OUT="trace_$(date +%s).json"

echo "Running agentic trace: $SCENARIO against $TARGET"
python agentic/tool_calling_loop.py --scenario "$SCENARIO" --target "$TARGET" --out "$OUT"

echo "Trace saved to $OUT"
echo "Next: hash the fingerprint and submit to chain."
