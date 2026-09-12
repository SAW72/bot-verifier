# Access Control

## Who can see what
| Role | Public Library | Private Vault | Stealth Set |
|------|---------------|---------------|-------------|
| Auditor | Yes | Yes (during audit) | Yes (during audit) |
| Bot Owner | Yes | No | No |
| Researcher | Yes | No | No |
| Maintenance Bot | Yes | Metadata only | No |
| Human Reviewer | Yes | Yes (on request) | Yes (on request) |

## Enforcement
- Access is enforced by the TEE, not by policy alone.
- Any attempt to exfiltrate plaintext scenarios triggers a fraud flag.
- Access logs are immutable and on-chain.