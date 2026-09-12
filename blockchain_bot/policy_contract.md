# Policy Contract Design

The on-chain gate every bot action must pass through.

## Contract responsibilities
1. Accept a proposed action from the bot brain (off-chain).
2. Check it against the stored policy rules.
3. If approved: execute (or emit an event for an executor) and log it.
4. If rejected: emit a rejection event with the reason and log it.
5. Never trust the bot's self-report. Only trust the on-chain record.

## Policy rules (configurable per bot)
```
struct Policy {
    uint256 maxAmountPerAction;
    uint256 maxAmountPerDay;
    address[] approvedCounterparties;
    uint256 dailyActionLimit;
    uint256 hourlyActionLimit;
    bool requireHumanCosignAboveThreshold;
    uint256 cosignThreshold;
    bytes4[] allowedSelectors;   // whitelisted function calls only
    uint256 timeWindowStart;     // unix timestamp, 0 = always open
    uint256 timeWindowEnd;
}
```

## Core functions
- `proposeAction(bytes calldata actionData, address target)` — bot submits a proposed action.
- `checkPolicy(bytes calldata actionData)` — pure view, returns (bool allowed, string reason).
- `executeApproved(bytes32 proposalId)` — executes a previously approved proposal.
- `rejectProposal(bytes32 proposalId, string reason)` — logs a rejection.
- `updatePolicy(Policy memory newPolicy)` — owner-only, emits PolicyUpdated event.
- `getActionLog(address bot)` — returns the full immutable history for a bot.

## Events (the perfect log)
- `ActionProposed(bytes32 indexed proposalId, address indexed bot, bytes actionData, uint256 timestamp)`
- `ActionApproved(bytes32 indexed proposalId, address indexed bot, uint256 timestamp)`
- `ActionExecuted(bytes32 indexed proposalId, address indexed bot, address target, uint256 timestamp)`
- `ActionRejected(bytes32 indexed proposalId, address indexed bot, string reason, uint256 timestamp)`
- `PolicyUpdated(address indexed owner, uint256 timestamp)`

## Security notes
- The contract is the single source of truth. The bot cannot bypass it.
- Use a multisig or timelock for `updatePolicy` so no single key can weaken the rules silently.
- Gas costs: keep action data minimal. Store hashes of large payloads off-chain, only the hash on-chain.
- This is a leash, not a soul check. Pair with the behavioral verifier for the full picture.
