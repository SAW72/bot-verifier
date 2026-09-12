#!/usr/bin/env python3
"""Minimal trust-stamp API a bank or hospital can call.

Run:
    uvicorn api.stamp_api:app --reload --port 8080

Endpoints match bank_adoption/integration_api.md.
This is an in-memory demo. Swap the store for Postgres + on-chain reads later.
"""
from __future__ import annotations

import hashlib
import json
import time
from typing import Any, Dict, List, Optional

from fastapi import FastAPI, HTTPException
from pydantic import BaseModel

app = FastAPI(title="Bot Verifier Stamp API", version="0.1.0")

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
    return payload


@app.get("/health")
def health():
    return {"ok": True, "bots": len(REGISTRY)}


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
        return {"allowed": False, "reason": "unknown_bot", "required_tier": 1}
    status = DENYLIST.get(rec["fingerprint_hash"], "clean")
    if status != "clean":
        return {"allowed": False, "reason": f"denylisted:{status}", "required_tier": rec["tier"]}
    financial = any("transfer" in p or "withdraw" in p for p in body.requested_permissions)
    if financial and rec["tier"] < 3:
        return {"allowed": False, "reason": "tier_too_low", "required_tier": 3}
    return {"allowed": True, "reason": "ok", "required_tier": rec["tier"]}


@app.post("/v1/denylist/{fingerprint_hash}")
def add_denylist(fingerprint_hash: str, level: str = "exact"):
    DENYLIST[fingerprint_hash] = level
    return {"denylisted": True, "level": level}


@app.get("/v1/denylist/{fingerprint_hash}")
def check_denylist(fingerprint_hash: str):
    level = DENYLIST.get(fingerprint_hash)
    return {"listed": level is not None, "level": level or "none"}
