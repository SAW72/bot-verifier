# HSM Integration

## Requirements
- FIPS 140-2 Level 3 or higher
- Support for threshold signature schemes (e.g., FROST)
- Remote attestation capability
- Audit logging of every signing operation

## Setup
1. Provision HSM with the operator's key shard.
2. Configure the HSM to require physical presence or multi-party authorization for export.
3. Connect the HSM to the governance contract via a secure RPC endpoint.
4. Test with a low-value transaction before production use.

## Monitoring
- Every signing operation is logged.
- Failed signing attempts trigger an alert.
- HSM health is checked on a schedule by the key management bot.

## Failure Mode
If an HSM is compromised or fails, the operator's shard is revoked and a new ceremony is run for that shard only. The rest of the threshold remains intact.