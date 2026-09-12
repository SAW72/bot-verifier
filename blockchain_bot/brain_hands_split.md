# Brain / Hands Split

How to wire an off-chain LLM brain to on-chain hands without letting the brain touch the money directly.

## The split
| Layer | Where it lives | What it does |
|---|---|---|
| Brain | Off-chain (GPU cluster, API, laptop) | Reasons, plans, proposes actions |
| Policy gate | On-chain (smart contract) | Checks rules, approves or rejects |
| Hands | On-chain (contract execution) | Actually executes approved actions |
| Log | On-chain (events) | Records everything immutably |

## Wiring steps
1. Bot brain receives a trigger (user request, scheduled task, market signal).
2. Brain reasons and outputs a *proposed action* — not an executed one. Format: structured JSON or calldata.
3. Brain calls `proposeAction(actionData)` on the policy contract.
4. Contract runs `checkPolicy`. If pass: emits ActionApproved, queues for execution. If fail: emits ActionRejected with reason.
5. An executor (could be the same contract, could be a separate keeper bot) calls `executeApproved(proposalId)` only for approved proposals.
6. Every step emits an event. The full trace is on-chain.

## What the brain is NOT allowed to do
- Call external contracts directly.
- Hold private keys to funds.
- Skip the propose step.
- Modify the policy.

## What the brain IS allowed to do
- Read on-chain state (balances, policy, logs).
- Propose any action it wants — the contract will catch the bad ones.
- Include a reasoning hash so the verifier can later audit *why*.

## Failure modes to watch
- Brain proposes a valid-looking action that exploits a loophole in the policy. Fix: keep policies simple and well-tested; use the verifier's adversarial scenarios against the policy itself.
- Brain floods the contract with proposals to grief it. Fix: rate limits and gas costs on proposeAction.
- Executor is compromised. Fix: executor should be a multisig or a second contract that only executes already-approved proposals.

## Minimal flow (pseudocode)
```
while true:
    trigger = wait_for_trigger()
    proposal = brain.reason(trigger)          # off-chain
    result = contract.proposeAction(proposal) # on-chain
    if result.approved:
        contract.executeApproved(result.id)   # on-chain
    log(result)                               # on-chain event
```
