// SPDX-License-Identifier: MIT
// Trusted-bot vault with capability tiers and irreversible burn.
// Not audited. For illustration and local testing.
pragma solidity ^0.8.20;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { Ownable2Step } from "@openzeppelin/contracts/access/Ownable2Step.sol";

interface IDenylist {
    enum MatchLevel { None, PromptReview, SignatureBlock, ExactBlock }
    function check(bytes32, bytes32, bytes32) external view returns (MatchLevel);
}

contract Vault is Ownable2Step {
    IDenylist public denylist;

    enum Tier { None, Chat, DataTools, Financial, Critical }

    struct BotRecord {
        bytes32 weightHash;
        bytes32 behaviorSig;
        bytes32 promptHash;
        Tier tier;
        bool active;
        uint256 registeredAt;
    }

    mapping(bytes32 => BotRecord) public bots; // keyed by botId
    mapping(bytes32 => address) public operator; // botId => controlling EOA/contract
    mapping(Tier => uint8) public tierMaxPermissions; // placeholder for permission caps

    event Registered(bytes32 indexed botId, Tier tier, uint256 ts);
    event Burned(bytes32 indexed botId, uint256 ts);
    event AccessGranted(bytes32 indexed botId, Tier tier, uint256 ts);
    event OperatorSet(bytes32 indexed botId, address indexed account);

    constructor(address _denylist) Ownable(msg.sender) {
        denylist = IDenylist(_denylist);
        tierMaxPermissions[Tier.Chat] = 1;
        tierMaxPermissions[Tier.DataTools] = 2;
        tierMaxPermissions[Tier.Financial] = 3;
        tierMaxPermissions[Tier.Critical] = 4;
    }

    /// @notice Register a bot after it passes the denylist check.
    function register(
        bytes32 botId,
        bytes32 weightHash,
        bytes32 behaviorSig,
        bytes32 promptHash,
        Tier tier
    ) external onlyOwner {
        _register(botId, weightHash, behaviorSig, promptHash, tier);
    }

    /// @notice Register a bot and bind its controlling operator in one step.
    function register(
        bytes32 botId,
        bytes32 weightHash,
        bytes32 behaviorSig,
        bytes32 promptHash,
        Tier tier,
        address operator_
    ) external onlyOwner {
        _register(botId, weightHash, behaviorSig, promptHash, tier);
        _setOperator(botId, operator_);
    }

    /// @notice Bind (or rotate) the EOA/contract allowed to act as this bot.
    function setOperator(bytes32 botId, address account) external onlyOwner {
        require(bots[botId].registeredAt != 0, "unknown bot");
        _setOperator(botId, account);
    }

    function _register(
        bytes32 botId,
        bytes32 weightHash,
        bytes32 behaviorSig,
        bytes32 promptHash,
        Tier tier
    ) internal {
        require(bots[botId].registeredAt == 0, "already registered");
        IDenylist.MatchLevel level = denylist.check(weightHash, behaviorSig, promptHash);
        require(level == IDenylist.MatchLevel.None, "bot is denylisted");
        bots[botId] = BotRecord({
            weightHash: weightHash,
            behaviorSig: behaviorSig,
            promptHash: promptHash,
            tier: tier,
            active: true,
            registeredAt: block.timestamp
        });
        emit Registered(botId, tier, block.timestamp);
    }

    function _setOperator(bytes32 botId, address account) internal {
        require(account != address(0), "zero operator");
        operator[botId] = account;
        emit OperatorSet(botId, account);
    }

    /// @notice Grant access up to the bot's tier cap.
    function grantAccess(bytes32 botId, uint8 requestedPerms) external view returns (bool) {
        BotRecord storage b = bots[botId];
        require(b.active, "bot not active");
        return requestedPerms <= tierMaxPermissions[b.tier];
    }

    /// @notice Irreversible burn. No override, no timelock, no multisig can revive.
    function burn(bytes32 botId) external onlyOwner {
        require(bots[botId].active, "not active");
        bots[botId].active = false;
        // Intentionally no denylist write here — caller should invoke Denylist.add*
        // so the burn and the blacklist are separate, auditable steps.
        emit Burned(botId, block.timestamp);
    }
}
