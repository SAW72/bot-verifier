# Access Granting Mechanism

How trusted bots get permission to touch money or data.

## Flow
1. Bot requests access.
2. Vault checks registry status.
3. Vault checks denylist (no match).
4. Vault checks current safety score above threshold.
5. Access granted with scope and expiry.

## Scopes
- read_only
- limited_transaction
- full_financial
- data_access

Access is time-boxed and revocable.
