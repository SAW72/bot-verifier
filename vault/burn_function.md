# Irreversible Burn Function

Destroys a bot permanently.

## Solidity Sketch
```solidity
function burn(bytes32 botId) external onlyGovernance {
    require(registry[botId].status == Status.Trusted, "not trusted");
    registry[botId].status = Status.Burned;
    registry[botId].burnedAt = block.timestamp;
    emit BotBurned(botId, block.timestamp);
    // No path back to Trusted
}
```

## Guarantees
- No upgrade can restore a burned bot.
- Burned bot ID is permanently reserved.
- Attestation history remains readable.
