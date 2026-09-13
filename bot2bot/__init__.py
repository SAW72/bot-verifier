"""Bot-to-bot handshake package.

Verifies a counterparty's on-chain attestation before a transaction settles.
See handshake.py for the client and verify_counterparty().
"""

from .handshake import (  # noqa: F401
    HandshakeClient,
    HandshakeResult,
    StampClient,
    verify_counterparty,
)

__all__ = [
    "HandshakeClient",
    "HandshakeResult",
    "StampClient",
    "verify_counterparty",
]
