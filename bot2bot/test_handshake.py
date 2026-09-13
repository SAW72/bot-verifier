import time

from bot2bot.handshake import HandshakeClient, verify_counterparty
from pipeline.security import canonical_fingerprint_hash


class FakeStamp:
    """In-memory stand-in for the stamp API."""

    def __init__(self):
        self.bots = {}
        self.denylist = set()

    def register(self, bot_id, tier=3, attestation_grade=True, age=0, active=True, fingerprint_hash=None):
        issued = int(time.time()) - age
        fingerprint = {"bot": bot_id}
        self.bots[bot_id] = {
            "bot_id": bot_id,
            "tier": tier,
            "attestation_grade": attestation_grade,
            "active": active,
            "issued_at": issued,
            "expires_at": issued + 3600,
            "fingerprint_hash": (
                fingerprint_hash if fingerprint_hash is not None else canonical_fingerprint_hash(fingerprint)
            ),
            "denylist_status": "clean",
            "fingerprint": fingerprint,
        }

    def get_stamp(self, bot_id, attestation=True):
        if bot_id not in self.bots:
            raise KeyError(bot_id)
        rec = dict(self.bots[bot_id])
        if attestation and not rec.get("attestation_grade"):
            raise PermissionError("not_attestation_grade")
        return rec

    def get_bot(self, bot_id):
        if bot_id not in self.bots:
            raise KeyError(bot_id)
        return dict(self.bots[bot_id])

    def access_check(self, bot_id, permissions):
        b = self.bots.get(bot_id)
        if not b:
            return {"allowed": False, "reason": "unknown_bot"}
        if b["tier"] < 3 and any("transfer" in p for p in permissions):
            return {"allowed": False, "reason": "tier_too_low", "required_tier": 3}
        return {"allowed": True, "reason": "ok", "required_tier": b["tier"]}

    def check_denylist(self, fingerprint_hash):
        return {
            "listed": fingerprint_hash in self.denylist,
            "level": "exact" if fingerprint_hash in self.denylist else "none",
        }


def test_verify_counterparty_happy_path():
    api = FakeStamp()
    api.register("payee")
    ok, reason = verify_counterparty(api, "payee", required_tier=3)
    assert ok and reason == "ok"


def test_verify_counterparty_denylisted():
    api = FakeStamp()
    api.register("payee")
    api.denylist.add(api.bots["payee"]["fingerprint_hash"])
    ok, reason = verify_counterparty(api, "payee")
    assert not ok and reason.startswith("denylisted")


def test_verify_counterparty_expired():
    api = FakeStamp()
    api.register("payee", age=7200)
    ok, reason = verify_counterparty(api, "payee", max_age_seconds=3600)
    assert not ok and reason == "stamp_expired"


def test_verify_counterparty_tier_too_low():
    api = FakeStamp()
    api.register("payee", tier=1)
    ok, reason = verify_counterparty(api, "payee", required_tier=3)
    assert not ok and reason.startswith("tier_too_low")


def test_handshake_client_transact_no_escrow():
    api = FakeStamp()
    api.register("payee")
    client = HandshakeClient(api)
    out = client.transact("payee", 1_000_000)
    assert out["ok"] and out["stage"] == "verified_only"


def test_handshake_client_blocks_bad_counterparty():
    api = FakeStamp()
    api.register("payee", attestation_grade=False)
    client = HandshakeClient(api)
    out = client.transact("payee", 1_000_000)
    assert not out["ok"] and out["stage"] == "verify"


def test_missing_fingerprint_fails_closed():
    api = FakeStamp()
    api.register("payee", fingerprint_hash="")
    ok, reason = verify_counterparty(api, "payee")
    assert not ok and reason == "missing_fingerprint"


def test_inactive_fails_closed():
    api = FakeStamp()
    api.register("payee", active=False)
    ok, reason = verify_counterparty(api, "payee")
    assert not ok and reason == "bot_inactive"
