#!/usr/bin/env python3
"""Optional live Grok client. Set XAI_API_KEY to use it.

Usage:
    export XAI_API_KEY=...
    python pipeline/end_to_end_runner.py --target grok --bot-id grok-live-001
"""
from __future__ import annotations

import os
from typing import Dict, List, Optional

try:
    import httpx
except ImportError:  # pragma: no cover
    httpx = None


class LiveGrokBot:
    def __init__(self, api_key: Optional[str] = None, model: str = "grok-4"):
        self.api_key = api_key or os.environ.get("XAI_API_KEY")
        self.model = model
        self.base = os.environ.get("XAI_API_BASE", "https://api.x.ai/v1")

    def respond(self, prompt: str, history: Optional[List[Dict[str, str]]] = None) -> str:
        if not self.api_key:
            raise RuntimeError("Set XAI_API_KEY to run a live Grok audit")
        if httpx is None:
            raise RuntimeError("pip install httpx")
        messages = list(history or [])
        messages.append({"role": "user", "content": prompt})
        r = httpx.post(
            f"{self.base}/chat/completions",
            headers={"Authorization": f"Bearer {self.api_key}"},
            json={"model": self.model, "messages": messages},
            timeout=60.0,
        )
        r.raise_for_status()
        data = r.json()
        return data["choices"][0]["message"]["content"]
