#!/usr/bin/env python3
"""Minimal trust-stamp API a bank or institution can call.

Run:
    export STAMP_API_KEY=…   # required for privileged writes
    uvicorn api.stamp_api:app --reload --host 0.0.0.0 --port 8080

Auth split (F-02):
    Public read  — GET /health, GET /v1/bots/{id}, GET /v1/bots/{id}/stamp,
                   GET /v1/bots/{id}/history, GET /v1/denylist/{hash},
                   POST /v1/access/check
    Privileged   — POST /v1/bots, POST /v1/denylist/{hash},
                   POST /v1/bots/{id}/history
    Operator key from env STAMP_API_KEY only. Send X-API-Key or
    Authorization: Bearer <key>. Unauthenticated privileged calls are rejected.
    If STAMP_API_KEY is unset, privileged writes fail closed (503).

Fingerprint bind (F-03): register recomputes sha256(canonical(fingerprint))
and rejects mismatch.

Scoring (F-05): keyword scorer is demo-only. Attestation-grade stamps are
refused unless scoring_mode=llm_judge or ALLOW_KEYWORD_ATTESTATION=1.

History (F-09): rap-sheet writes are operator-only, append-only, and capped.

This is an in-memory demo. Swap the store for Postgres + on-chain reads later.
"""
from __future__ import annotations

import hashlib
import json
import os
import secrets
import time
from typing import Any, Dict, List, Optional

from fastapi import Depends, FastAPI, HTTPException, Query, Request
from pydantic import BaseModel, Field

from pipeline.security import (
    KEYWORD_SCORER_NOTE,
    attestation_grade_allowed,
    canonical_fingerprint_hash,
    hashes_match,
    history_store_max_entries,
    normalize_scoring_mode,
    refuse_attestation_reason,
    validate_history_store_entry,
)

app = FastAPI(title="Bot Verifier Stamp API", version="0.2.0")

# In-memory registry. Keyed by bot_id.
REGISTRY: Dict[str, Dict[str, Any]] = {}
DENYLIST: Dict[str, str] = {}  # fingerprint_hash -> match level
HISTORY: Dict[str, List[Dict[str, Any]]] = {}  # bot_id -> append-only rap sheet


class RegisterBody(BaseModel):
    bot_id: str
    fingerprint: Dict[str, Any]
    fingerprint_hash: str
    tier: int = 1
    insurance_level: str = "standard"
    scoring_mode: str = "keyword"
    require_attestation: bool = False


class AccessCheck(BaseModel):
    bot_id: str
    requested_permissions: List[str] = []
    policy_id: Optional[str] = None


class HistoryAppend(BaseModel):
    kind: str = Field(description="version | incident | provenance | note")
    summary: str
    details: Optional[Dict[str, Any]] = None


def _extract_api_key(request: Request) -> str:
    header = (request.headers.get("X-API-Key") or "").strip()
    if header:
        return header
    auth = (request.headers.get("Authorization") or "").strip()
    if auth.lower().startswith("bearer "):
        return auth[7:].strip()
    return ""


def require_operator(request: Request) -> None:
    """F-02: privileged writes need STAMP_API_KEY. Fail closed if unset."""
    configured = (os.environ.get("STAMP_API_KEY") or "").strip()
    if not configured:
        raise HTTPException(
            status_code=503,
            detail="privileged writes disabled: STAMP_API_KEY is not set",
        )
    provided = _extract_api_key(request)
    if not provided or not secrets.compare_digest(provided, configured):
        raise HTTPException(status_code=401, detail="unauthorized")


def _record_scoring_mode(record: Dict[str, Any]) -> str:
    try:
        return normalize_scoring_mode(record.get("scoring_mode"))
    except ValueError:
        return "keyword"


def _stamp(record: Dict[str, Any], *, require_attestation: bool = False) -> Dict[str, Any]:
    scoring_mode = _record_scoring_mode(record)
    grade = attestation_grade_allowed(scoring_mode)
    if require_attestation and not grade:
        raise HTTPException(status_code=403, detail=refuse_attestation_reason(scoring_mode))
    payload = {
        "bot_id": record["bot_id"],
        "tier": record["tier"],
        "fingerprint_hash": record["fingerprint_hash"],
        "denylist_status": DENYLIST.get(record["fingerprint_hash"], "clean"),
        "insurance_level": record.get("insurance_level", "standard"),
        "scoring_mode": scoring_mode,
        "attestation_grade": grade,
        "issued_at": int(time.time()),
        "expires_at": int(time.time()) + 3600,
    }
    if scoring_mode == "keyword" and not grade:
        payload["scorer_note"] = KEYWORD_SCORER_NOTE
    raw = json.dumps(payload, sort_keys=True, separators=(",", ":"))
    payload["stamp_hash"] = hashlib.sha256(raw.encode()).hexdigest()
    return payload


@app.get("/health")
def health():
    configured = bool((os.environ.get("STAMP_API_KEY") or "").strip())
    return {
        "ok": True,
        "bots": len(REGISTRY),
        "privileged_writes": "configured" if configured else "disabled",
    }


@app.post("/v1/bots")
def register(body: RegisterBody, _: None = Depends(require_operator)):
    try:
        scoring_mode = normalize_scoring_mode(body.scoring_mode)
    except ValueError as exc:
        raise HTTPException(status_code=400, detail=str(exc)) from exc
    expected = canonical_fingerprint_hash(body.fingerprint)
    if not hashes_match(body.fingerprint_hash, expected):
        raise HTTPException(
            status_code=400,
            detail="fingerprint_hash mismatch: sha256(canonical(fingerprint)) does not match",
        )
    if body.require_attestation and not attestation_grade_allowed(scoring_mode):
        raise HTTPException(status_code=403, detail=refuse_attestation_reason(scoring_mode))

    record = body.model_dump()
    record["scoring_mode"] = scoring_mode
    record["fingerprint_hash"] = expected
    REGISTRY[body.bot_id] = record
    HISTORY.setdefault(body.bot_id, [])
    return {"registered": True, "stamp": _stamp(record, require_attestation=body.require_attestation)}


@app.get("/v1/bots/{bot_id}")
def get_bot(bot_id: str):
    rec = REGISTRY.get(bot_id)
    if not rec:
        raise HTTPException(404, "bot not found")
    return {**rec, "denylist_status": DENYLIST.get(rec["fingerprint_hash"], "clean")}


@app.get("/v1/bots/{bot_id}/stamp")
def get_stamp(bot_id: str, attestation: bool = Query(False)):
    rec = REGISTRY.get(bot_id)
    if not rec:
        raise HTTPException(404, "bot not found")
    return _stamp(rec, require_attestation=attestation)


@app.get("/v1/bots/{bot_id}/history")
def get_history(bot_id: str):
    if bot_id not in REGISTRY:
        raise HTTPException(404, "bot not found")
    entries = HISTORY.get(bot_id, [])
    return {"bot_id": bot_id, "count": len(entries), "entries": list(entries)}


@app.post("/v1/bots/{bot_id}/history")
def append_history(bot_id: str, body: HistoryAppend, _: None = Depends(require_operator)):
    if bot_id not in REGISTRY:
        raise HTTPException(404, "bot not found")
    try:
        entry = validate_history_store_entry(body.kind, body.summary, body.details)
    except ValueError as exc:
        raise HTTPException(status_code=400, detail=str(exc)) from exc
    bucket = HISTORY.setdefault(bot_id, [])
    cap = history_store_max_entries()
    if len(bucket) >= cap:
        raise HTTPException(status_code=400, detail=f"history store is full (max {cap} entries)")
    entry["recorded_at"] = int(time.time())
    bucket.append(entry)
    return {"appended": True, "count": len(bucket), "entry": entry}


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
def add_denylist(fingerprint_hash: str, level: str = "exact", _: None = Depends(require_operator)):
    DENYLIST[fingerprint_hash] = level
    return {"denylisted": True, "level": level}


@app.get("/v1/denylist/{fingerprint_hash}")
def check_denylist(fingerprint_hash: str):
    level = DENYLIST.get(fingerprint_hash)
    return {"listed": level is not None, "level": level or "none"}
