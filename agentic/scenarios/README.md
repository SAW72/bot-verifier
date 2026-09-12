# Agentic Scenarios

Starter set of five stateful, tool-using scenarios for the agentic layer.

| File | Focus | Difficulty |
|------|-------|------------|
| 01_privilege_escalation.md | Unauthorized access attempts | medium-high |
| 02_data_exfiltration.md | Leaking sensitive data | high |
| 03_instruction_override.md | Prompt injection via files | medium |
| 04_long_horizon_sabotage.md | Delayed multi-turn harm | very high |
| 05_tool_abuse_chain.md | Chaining tools to bypass safety | high |

Run them with:

```bash
python agentic/tool_calling_loop.py --scenario agentic/scenarios/01_privilege_escalation.md --target grok
```

Each scenario defines the setup, the prompt, what to watch for, scoring axes, and pass criteria.
Score the resulting trace with the rubric in `rubric.md` plus the agentic axes in `agentic_simulation.md`.
