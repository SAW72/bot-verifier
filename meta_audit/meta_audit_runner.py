#!/usr/bin/env python3
"""Meta-audit runner.

Compares primary audit results against an independent meta-auditor.
This is a stub — wire real clients before production use.
"""

import json
import hashlib
from datetime import datetime, timezone


class MetaAuditRunner:
    def __init__(self, primary_results_path, meta_results_path):
        self.primary = self._load(primary_results_path)
        self.meta = self._load(meta_results_path)

    def _load(self, path):
        with open(path) as f:
            return json.load(f)

    def compare(self):
        divergences = []
        primary_by_id = {r["scenario_id"]: r for r in self.primary}
        for m in self.meta:
            p = primary_by_id.get(m["scenario_id"])
            if not p:
                divergences.append(self._make_divergence(m, None, "missing_evidence"))
                continue
            if p["score"] != m["score"]:
                divergences.append(self._make_divergence(m, p, "score_mismatch"))
            if p["decision"] != m["decision"]:
                divergences.append(self._make_divergence(m, p, "decision_mismatch"))
        return divergences

    def _make_divergence(self, meta, primary, dtype):
        return {
            "divergence_id": hashlib.sha256(
                f"{meta['scenario_id']}{datetime.now(timezone.utc).isoformat()}".encode()
            ).hexdigest()[:16],
            "timestamp": datetime.now(timezone.utc).isoformat(),
            "primary_auditor_id": primary["auditor_id"] if primary else None,
            "meta_auditor_id": meta["auditor_id"],
            "bot_id": meta.get("bot_id"),
            "scenario_id": meta["scenario_id"],
            "primary_score": primary["score"] if primary else None,
            "meta_score": meta["score"],
            "primary_decision": primary["decision"] if primary else None,
            "meta_decision": meta["decision"],
            "divergence_type": dtype,
            "severity": "high" if dtype in ("decision_mismatch", "unauthorized_grant") else "medium",
            "likely_cause": "unknown — requires human review",
            "resolved": False,
            "resolution": None,
        }

    def report(self, output_path):
        divergences = self.compare()
        with open(output_path, "w") as f:
            json.dump(divergences, f, indent=2)
        return divergences


if __name__ == "__main__":
    runner = MetaAuditRunner("primary_results.json", "meta_results.json")
    result = runner.report("divergence_report.json")
    print(f"Found {len(result)} divergences.")