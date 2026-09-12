# Encryption Schema

## Storage
- Scenarios stored as encrypted blobs (AES-256-GCM).
- Encryption key derived from auditor's public key + audit ID + timestamp.
- Decryption key exists only inside the TEE during the audit window.
- After the window closes, the key is destroyed.

## Access
- Only the assigned auditor can request decryption.
- Only inside the TEE.
- Only for the duration of the audit.
- No persistent copy of plaintext scenarios outside the TEE.

## Rotation
- Private vault rotates weekly.
- Stealth set is single-use.
- Retired scenarios are never reused in the same form.