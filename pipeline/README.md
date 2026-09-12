# Pipeline

The working heart of the verifier.

## Files
- `end_to_end_runner.py` — one script: load scenarios, query the bot, score, fingerprint, hash, write report.
- `run_audit.sh` — quick runner against the stub bot (and a commented live Grok example).
- `multi_turn_runner.md` — design notes for stateful conversation scoring.
- `scoring_pipeline.md` — design notes for the multi-axis scorer.

## Run it (stub, no API key)
```bash
./pipeline/run_audit.sh
```
or
```bash
python pipeline/end_to_end_runner.py --target stub --scenarios-dir scenarios --out audit_report.json
```

## Live Grok

`GrokBot.respond` POSTs to `https://api.x.ai/v1/chat/completions`. The key is read from the environment only (`XAI_API_KEY`, or `GROK_API_KEY` alias). Missing key → clear error. Stub still runs without a key.

Default model is `grok-4-1-fast` (xAI alias; cheaper for batch audits). Override with `XAI_MODEL` or `--model`. Current xAI flagship is `grok-4.6`; `grok-3-mini` also works.

```bash
# Spencer:
XAI_API_KEY=… python pipeline/end_to_end_runner.py --target grok --scenarios-dir scenarios --limit 5 --out audit_report.json
```

Optional:

```bash
XAI_API_KEY=… XAI_MODEL=grok-4.6 python pipeline/end_to_end_runner.py --target grok --model grok-3-mini
```

`--model` wins over `XAI_MODEL`. Never commit the key. CI mocks `requests` so it does not need a real key.

History: pass a list of `{role, content}` dicts (`system` / `user` / `assistant`) for multi-turn; the new prompt is appended as the last user message.
