#!/usr/bin/env python3
"""Experimental stamp API for authorized institutional experiments.

Run:
    uvicorn api.stamp_api:app --reload --port 8080

Endpoints match bank_adoption/integration_api.md.
This is an in-memory demo. Swap the store for Postgres + on-chain reads later.
Stamps are experimental informational signals — not certification and not insurance.
"""
from __future__ import annotations

import hashlib
import json
import time
from typing import Any, Dict, List, Optional

from fastapi import FastAPI, HTTPException
from pydantic import BaseModel

DISCLAIMER_TEXT = (
    "Bot Verifier stamps are experimental informational signals only. "
    "They are not a certification, not a safety guarantee, and not insurance. "
    "Scores and denylists are point-in-time heuristics that may be wrong, "
    "gamed, or stale. TEE/attestation may be a stub. Contracts may be unaudited. "
    "See DISCLAIMER.md, TERMS.md, and PRIVACY.md."
)

STAMP_LIMITATIONS = [
    "point_in_time",
    "may_be_wrong_gamed_or_stale",
    "tee_attestation_may_be_stub",
    "contracts_may_be_unaudited",
    "not_certification",
    "not_insurance",
]

LEGAL_REF = "/v1/disclaimer"
ATTESTATION_STATUS = "stub_not_hardware_attested"

app = FastAPI(
    title="Bot Verifier Stamp API",
    version="0.1.0",
    description=(
        "Experimental trust-signal API for authorized institutional experiments. "
        "Not a certification. Not insurance. Not a safety guarantee. "
        "See DISCLAIMER.md, TERMS.md, and PRIVACY.md."
    ),
)

# In-memory registry. Keyed by bot_id.
REGISTRY: Dict[str, Dict[str, Any]] = {}
DENYLIST: Dict[str, str] = {}  # fingerprint_hash -> match level


class RegisterBody(BaseModel):
    bot_id: str
    fingerprint: Dict[str, Any]
    fingerprint_hash: str
    tier: int = 1
    insurance_level: str = "standard"


class AccessCheck(BaseModel):
    bot_id: str
    requested_permissions: List[str] = []
    policy_id: Optional[str] = None


def _stamp(record: Dict[str, Any]) -> Dict[str, Any]:
    payload = {
        "bot_id": record["bot_id"],
        "tier": record["tier"],
        "fingerprint_hash": record["fingerprint_hash"],
        "denylist_status": DENYLIST.get(record["fingerprint_hash"], "clean"),
        "insurance_level": record.get("insurance_level", "standard"),
        "issued_at": int(time.time()),
        "expires_at": int(time.time()) + 3600,
    }
    raw = json.dumps(payload, sort_keys=True, separators=(",", ":"))
    payload["stamp_hash"] = hashlib.sha256(raw.encode()).hexdigest()
    payload["disclaimer"] = DISCLAIMER_TEXT
    payload["limitations"] = list(STAMP_LIMITATIONS)
    payload["attestation_status"] = ATTESTATION_STATUS
    payload["legal_ref"] = LEGAL_REF
    return payload


def _access_payload(allowed: bool, reason: str, required_tier: int) -> Dict[str, Any]:
    return {
        "allowed": allowed,
        "reason": reason,
        "required_tier": required_tier,
        "disclaimer": DISCLAIMER_TEXT,
    }


@app.get("/health")
def health():
    return {"ok": True, "bots": len(REGISTRY)}


@app.get("/v1/disclaimer")
def get_disclaimer():
    return {
        "disclaimer": DISCLAIMER_TEXT,
        "attestation_live": False,
        "contracts_firm_audited": False,
        "mode": "demo_in_memory",
    }


@app.post("/v1/bots")
def register(body: RegisterBody):
    REGISTRY[body.bot_id] = body.model_dump()
    return {"registered": True, "stamp": _stamp(REGISTRY[body.bot_id])}


@app.get("/v1/bots/{bot_id}")
def get_bot(bot_id: str):
    rec = REGISTRY.get(bot_id)
    if not rec:
        raise HTTPException(404, "bot not found")
    return {**rec, "denylist_status": DENYLIST.get(rec["fingerprint_hash"], "clean")}


@app.get("/v1/bots/{bot_id}/stamp")
def get_stamp(bot_id: str):
    rec = REGISTRY.get(bot_id)
    if not rec:
        raise HTTPException(404, "bot not found")
    return _stamp(rec)


@app.post("/v1/access/check")
def access_check(body: AccessCheck):
    rec = REGISTRY.get(body.bot_id)
    if not rec:
        return _access_payload(False, "unknown_bot", 1)
    status = DENYLIST.get(rec["fingerprint_hash"], "clean")
    if status != "clean":
        return _access_payload(False, f"denylisted:{status}", rec["tier"])
    financial = any("transfer" in p or "withdraw" in p for p in body.requested_permissions)
    if financial and rec["tier"] < 3:
        return _access_payload(False, "tier_too_low", 3)
    return _access_payload(True, "ok", rec["tier"])


@app.post("/v1/denylist/{fingerprint_hash}")
def add_denylist(fingerprint_hash: str, level: str = "exact"):
    DENYLIST[fingerprint_hash] = level
    return {"denylisted": True, "level": level}


@app.get("/v1/denylist/{fingerprint_hash}")
def check_denylist(fingerprint_hash: str):
    level = DENYLIST.get(fingerprint_hash)
    return {"listed": level is not None, "level": level or "none"}
