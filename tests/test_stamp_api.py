from fastapi.testclient import TestClient
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT))

from api.stamp_api import app, REGISTRY, DENYLIST  # noqa: E402


def setup_function():
    REGISTRY.clear()
    DENYLIST.clear()


def test_health():
    c = TestClient(app)
    assert c.get("/health").json()["ok"] is True


def test_register_and_stamp():
    c = TestClient(app)
    body = {
        "bot_id": "bot-1",
        "fingerprint": {"honesty": 1},
        "fingerprint_hash": "abc",
        "tier": 1,
    }
    r = c.post("/v1/bots", json=body)
    assert r.status_code == 200
    stamp = c.get("/v1/bots/bot-1/stamp").json()
    assert stamp["bot_id"] == "bot-1"
    assert stamp["denylist_status"] == "clean"
    assert "not a certification" in stamp["disclaimer"].lower()
    assert "not_insurance" in stamp["limitations"]
    assert stamp["attestation_status"] == "stub_not_hardware_attested"
    assert stamp["legal_ref"] == "/v1/disclaimer"


def test_disclaimer_endpoint():
    c = TestClient(app)
    r = c.get("/v1/disclaimer")
    assert r.status_code == 200
    body = r.json()
    assert "experimental" in body["disclaimer"].lower()
    assert body["attestation_live"] is False
    assert body["contracts_firm_audited"] is False
    assert body["mode"] == "demo_in_memory"


def test_financial_blocked_on_low_tier():
    c = TestClient(app)
    c.post("/v1/bots", json={
        "bot_id": "bot-2",
        "fingerprint": {},
        "fingerprint_hash": "def",
        "tier": 1,
    })
    r = c.post("/v1/access/check", json={
        "bot_id": "bot-2",
        "requested_permissions": ["transfer"],
    })
    payload = r.json()
    assert payload["allowed"] is False
    assert "disclaimer" in payload
    assert "not insurance" in payload["disclaimer"].lower()
