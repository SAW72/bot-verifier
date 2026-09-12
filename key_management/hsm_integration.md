# HSM Integration

Hardware Security Module notes for production key storage.

## Recommended
- Use an HSM (e.g., AWS KMS, GCP Cloud HSM, or a dedicated device) for each signer shard.
- Signing operations happen inside the HSM; private keys never leave it.
- Access to the HSM is gated by the same multisig / threshold policy as the ceremony.

## Rotation
- Schedule rotation every 90 days via the gas scheduler in `automation/`.
- On rotation, the old HSM key is disabled after the timelock window.

## Monitoring
- The key monitor bot (see `key_management/key_monitor_bot.md`) watches for unusual signing patterns and alerts on failed or anomalous transactions.
