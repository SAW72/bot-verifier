#!/usr/bin/env python3
"""Bot-to-bot attestation handshake client.

Before a bot pays another bot, it calls this to verify the counterparty's
on-chain stamp: valid hash, not expired, not denylisted, tier sufficient.
If it passes, the bot can create an escrow on-chain and release funds.

Usage:
    from bot2bot.handshake import verify_counterparty, HandshakeClient
    ok, reason = verify_counterparty(stamp_api_url, counterparty_bot_id, required_tier=3)
    if ok:
        escrow_id = client.create_escrow(...)
"""

from __future__ import annotations

import json
import time
from dataclasses import dataclass
from typing import Any, Dict, List, Optional, Tuple

try:
    import requests
except ImportError:  # pragma: no cover
    requests = None  # type: ignore[assignment]


class StampClient:
    """Thin client for the stamp API (api/stamp_api.py)."""

    def __init__(self, base_url: str, api_key: Optional[str] = None, timeout: float = 10.0):
        self.base_url = base_url.rstrip("/")
        self.api_key = (api_key or "").strip()
        self.timeout = timeout

    def _headers(self) -> Dict[str, str]:
        h = {"Accept": "application/json"}
        if self.api_key:
            h["X-API-Key"] = self.api_key
        return h

    def get_stamp(self, bot_id: str, attestation: bool = True) -> Dict[str, Any]:
        if requests is None:
            raise RuntimeError("requests is required for StampClient")
        r = requests.get(
            f"{self.base_url}/v1/bots/{bot_id}/stamp",
            params={"attestation": str(attestation).lower()},
            headers=self._headers(),
            timeout=self.timeout,
        )
        if r.status_code == 404:
            raise KeyError(f"bot {bot_id} not registered")
        r.raise_for_status()
        return r.json()

    def access_check(self, bot_id: str, permissions: List[str]) -> Dict[str, Any]:
        if requests is None:
            raise RuntimeError("requests is required for StampClient")
        r = requests.post(
            f"{self.base_url}/v1/access/check",
            json={"bot_id": bot_id, "requested_permissions": permissions},
            headers=self._headers(),
            timeout=self.timeout,
        )
        r.raise_for_status()
        return r.json()

    def check_denylist(self, fingerprint_hash: str) -> Dict[str, Any]:
        if requests is None:
            raise RuntimeError("requests is required for StampClient")
        r = requests.get(
            f"{self.base_url}/v1/denylist/{fingerprint_hash}",
            headers=self._headers(),
            timeout=self.timeout,
        )
        r.raise_for_status()
        return r.json()


def verify_counterparty(
    stamp: StampClient,
    bot_id: str,
    *,
    required_tier: int = 3,
    required_permissions: Optional[List[str]] = None,
    max_age_seconds: int = 3600,
) -> Tuple[bool, str]:
    """Verify a counterparty bot is safe to transact with.

    Checks, in order:
      1. Stamp exists and is attestation-grade.
      2. Not expired (issued_at + max_age within tolerance).
      3. Not denylisted.
      4. Tier meets the required minimum.
      5. Access check passes for the requested permissions.
    """
    perms = required_permissions or ["transfer"]
    try:
        stamp_data = stamp.get_stamp(bot_id, attestation=True)
    except KeyError:
        return False, "unknown_bot"
    except Exception as exc:  # noqa: BLE001
        return False, f"stamp_fetch_failed:{exc}"

    if not stamp_data.get("attestation_grade"):
        return False, "not_attestation_grade"

    issued = int(stamp_data.get("issued_at") or 0)
    if issued <= 0 or (time.time() - issued) > max_age_seconds:
        return False, "stamp_expired"

    fp_hash = stamp_data.get("fingerprint_hash") or ""
    if fp_hash:
        try:
            dl = stamp.check_denylist(fp_hash)
        except Exception as exc:  # noqa: BLE001
            return False, f"denylist_check_failed:{exc}"
        if dl.get("listed"):
            return False, f"denylisted:{dl.get('level')}"

    tier = int(stamp_data.get("tier") or 0)
    if tier < required_tier:
        return False, f"tier_too_low:{tier}<{required_tier}"

    try:
        access = stamp.access_check(bot_id, perms)
    except Exception as exc:  # noqa: BLE001
        return False, f"access_check_failed:{exc}"
    if not access.get("allowed"):
        return False, f"access_denied:{access.get('reason')}"

    return True, "ok"


@dataclass
class HandshakeResult:
    counterparty: str
    allowed: bool
    reason: str
    stamp: Dict[str, Any]
    checked_at: float

    def to_json(self) -> str:
        return json.dumps(
            {
                "counterparty": self.counterparty,
                "allowed": self.allowed,
                "reason": self.reason,
                "stamp": self.stamp,
                "checked_at": self.checked_at,
            },
            indent=2,
        )


class HandshakeClient:
    """High-level client: verify counterparty, then optionally open an escrow."""

    def __init__(
        self,
        stamp: StampClient,
        escrow_contract: Optional[Any] = None,
        default_tier: int = 3,
        default_permissions: Optional[List[str]] = None,
    ):
        self.stamp = stamp
        self.escrow = escrow_contract
        self.default_tier = default_tier
        self.default_permissions = default_permissions or ["transfer"]

    def verify(
        self,
        counterparty_bot_id: str,
        *,
        required_tier: Optional[int] = None,
        required_permissions: Optional[List[str]] = None,
    ) -> HandshakeResult:
        ok, reason = verify_counterparty(
            self.stamp,
            counterparty_bot_id,
            required_tier=required_tier or self.default_tier,
            required_permissions=required_permissions or self.default_permissions,
        )
        stamp_data: Dict[str, Any] = {}
        try:
            stamp_data = self.stamp.get_stamp(counterparty_bot_id, attestation=True)
        except Exception:  # noqa: BLE001
            pass
        return HandshakeResult(
            counterparty=counterparty_bot_id,
            allowed=ok,
            reason=reason,
            stamp=stamp_data,
            checked_at=time.time(),
        )

    def transact(
        self,
        counterparty_bot_id: str,
        amount_wei: int,
        *,
        escrow_id: Optional[str] = None,
        payer_bot_id: str = "",
        duration_seconds: int = 3600,
    ) -> Dict[str, Any]:
        """Verify the counterparty, then create an on-chain escrow if one is wired."""
        result = self.verify(counterparty_bot_id)
        if not result.allowed:
            return {"ok": False, "stage": "verify", "reason": result.reason}
        if self.escrow is None:
            return {
                "ok": True,
                "stage": "verified_only",
                "reason": result.reason,
                "note": "no escrow contract wired; funds not moved",
            }
        # Escrow creation is left to the caller / web3 binding; we just report readiness.
        return {
            "ok": True,
            "stage": "ready_for_escrow",
            "counterparty": counterparty_bot_id,
            "amount_wei": amount_wei,
            "payer_bot_id": payer_bot_id,
            "duration_seconds": duration_seconds,
            "escrow_id": escrow_id,
        }
