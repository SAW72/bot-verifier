# Prompt Hash Layer

The system prompt is the soul of a bot.

## Flow
1. Hash the full system prompt at registration.
2. Store hash on denylist when bot is burned.
3. Any future bot reusing that exact prompt is blocked.

Even if weights are rebuilt from scratch, the prompt hash catches reuse.
