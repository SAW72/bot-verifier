#!/usr/bin/env python3
"""Stub verifier for TEE-attested audit reports.

Checks the structure and hashes. Real TEE quote verification requires the
provider's attestation library (e.g. AWS Nitro CLI, GCP attestation API).
This stub proves the *logic*; swap in real verification for production.
"""
import json
import hashlib
import sys


def sha256_hex(obj):
    s = json.dumps(obj, sort_keys=True, separators=(",", ":"))
    return hashlib.sha256(s.encode()).hexdigest()


def verify_report(report: dict, expected_measurement: str) -> dict:
    errors = []

    # 1. Required fields
    required = ["report_id", "bot_id", "scenario_set_hash", "rubric_hash",
                "fingerprint", "fingerprint_hash", "tee_quote", "tee_measurement",
                "tee_provider", "application_signature", "timestamp_start", "timestamp_end"]
    for f in required:
        if f not in report:
            errors.append(f"missing field: {f}")

    # 2. Fingerprint hash matches
    if "fingerprint" in report and "fingerprint_hash" in report:
        if sha256_hex(report["fingerprint"]) != report["fingerprint_hash"]:
            errors.append("fingerprint_hash mismatch")

    # 3. TEE measurement matches expected
    if report.get("tee_measurement") != expected_measurement:
        errors.append("tee_measurement does not match expected (code may have been tampered)")

    # 4. Timestamps sane
    if report.get("timestamp_start") and report.get("timestamp_end"):
        if report["timestamp_end"] < report["timestamp_start"]:
            errors.append("timestamp_end before timestamp_start")

    # 5. TEE quote present (real verification is provider-specific)
    if not report.get("tee_quote"):
        errors.append("no tee_quote — cannot prove hardware attestation")

    ok = len(errors) == 0
    return {"valid": ok, "errors": errors}


if __name__ == "__main__":
    if len(sys.argv) < 3:
        print("Usage: verify_attestation.py <report.json> <expected_measurement>")
        sys.exit(2)
    with open(sys.argv[1]) as f:
        report = json.load(f)
    result = verify_report(report, sys.argv[2])
    print(json.dumps(result, indent=2))
    sys.exit(0 if result["valid"] else 1)