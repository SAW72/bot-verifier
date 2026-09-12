# Human-in-the-Loop Escalation Layer

When the automated system flags something ambiguous — a bot that scores fine but feels off — there must be a defined path for a human expert to review, document, and override.

## The problem
Right now that judgment lives in your head. It needs to live in the system, with a clear trail.

## Components
- `escalation_policy.md` — when to escalate, who reviews, what they can do.
- `review_queue_schema.md` — the queue of flagged items awaiting human review.
- `human_review_template.md` — the form a reviewer fills out.
- `override_log_schema.md` — record of every human override, with reasoning.
- `escalation_bot_prompt.md` — the Grok bot that triages and routes flags to humans.

## Quick start
1. Read `escalation_policy.md`.
2. Define your reviewer pool (you, plus trusted experts).
3. Wire the scoring pipeline to push ambiguous flags into the review queue.
4. Reviewer fills `human_review_template.md`, decision is logged.
5. Overrides feed back into the rubric and scenario library via the evolution loop.

## Status
Policy + schemas + triage bot. Next: define your reviewer pool and wire the first flag.