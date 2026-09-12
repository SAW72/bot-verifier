# Distributed Key Ceremony

Run once at genesis. After this, keys live in HSMs and are never assembled in one place.

## Steps
1. Gather N independent operators (recommend N >= 5 for production).
2. Each operator generates a keypair in an air-gapped environment.
3. Each operator's public key is recorded on-chain in the governance contract.
4. The threshold is set (recommend 3-of-5 or 5-of-7).
5. A test transaction is signed by the threshold to prove the ceremony worked.
6. All private key material is destroyed from the ceremony machines.
7. The ceremony is recorded on-chain as an immutable event.

## Rules
- No single operator ever sees another operator's private key.
- The ceremony is witnessed by at least two independent observers.
- The full transcript is published for transparency.

## After Ceremony
- Keys move to HSMs immediately.
- Rotation schedule begins (see `key_rotation.md`).