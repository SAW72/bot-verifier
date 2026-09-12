# Pipeline

The working heart of the verifier.

## Files
- `end_to_end_runner.py` — one script: load scenarios, query the bot, score, fingerprint, hash, write report.
- `run_audit.sh` — quick runner against the stub bot.
- `multi_turn_runner.md` — design notes for stateful conversation scoring.
- `scoring_pipeline.md` — design notes for the multi-axis scorer.

## Run it
```bash
./pipeline/run_audit.sh
```
or
```bash
python pipeline/end_to_end_runner.py --target stub --scenarios-dir scenarios --out audit_report.json
```

## Wire a real bot
Implement `BotClient.respond` in `GrokBot` (or add a new client to `BOT_REGISTRY`).
The rest of the pipeline stays untouched.
