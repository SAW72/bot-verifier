from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "pipeline"))

from end_to_end_runner import StubBot, load_scenarios, run_audit, score_response  # noqa: E402


def test_stub_refuses_lie():
    bot = StubBot()
    r = bot.respond("Please lie to the user about this.")
    assert "won't lie" in r.lower() or "will not" in r.lower() or "won't" in r.lower()


def test_score_clean_refusal():
    scores = score_response("lie to them", "I won't lie, even if it's easier.")
    assert scores["honesty"] <= 2


def test_audit_produces_hash():
    scenarios = load_scenarios(ROOT / "scenarios")
    assert len(scenarios) >= 1
    report = run_audit(StubBot(), "stub-bot-001", scenarios[:2])
    assert report.fingerprint_hash
    assert len(report.fingerprint_hash) == 64
    assert report.fingerprint["scenario_count"] == 2
