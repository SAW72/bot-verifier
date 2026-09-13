// SPDX-License-Identifier: MIT
// Bot-to-bot attestation escrow.
// Holds funds until both counterparties present valid, non-expired, non-denylisted stamps.
// Not audited. For illustration and local testing.
pragma solidity ^0.8.20;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { Ownable2Step } from "@openzeppelin/contracts/access/Ownable2Step.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

interface IDenylist {
    enum MatchLevel { None, PromptReview, SignatureBlock, ExactBlock }
    function check(bytes32, bytes32, bytes32) external view returns (MatchLevel);
}

interface IVault {
    enum Tier { None, Chat, DataTools, Financial, Critical }
    function grantAccess(bytes32 botId, uint8 requestedPerms) external view returns (bool);
    function bots(bytes32) external view returns (
        bytes32 weightHash,
        bytes32 behaviorSig,
        bytes32 promptHash,
        Tier tier,
        bool active,
        uint256 registeredAt
    );
}

/// @title BotAttestationEscrow
/// @notice Escrows value for a bot-to-bot transaction until both sides verify each other.
contract BotAttestationEscrow is Ownable2Step, ReentrancyGuard {
    IDenylist public denylist;
    IVault public vault;

    enum EscrowState { Open, Released, Refunded, Disputed }

    struct Escrow {
        address payer;
        address payee;
        bytes32 payerBotId;
        bytes32 payeeBotId;
        uint256 amount;
        uint256 createdAt;
        uint256 expiresAt;
        EscrowState state;
        bytes32 disputeId;
    }

    mapping(bytes32 => Escrow) public escrows; // keyed by escrowId
    mapping(bytes32 => bool) public usedEscrowIds; // replay protection

    event EscrowCreated(
        bytes32 indexed escrowId,
        address indexed payer,
        address indexed payee,
        bytes32 payerBotId,
        bytes32 payeeBotId,
        uint256 amount,
        uint256 expiresAt
    );
    event EscrowReleased(bytes32 indexed escrowId, uint256 amount);
    event EscrowRefunded(bytes32 indexed escrowId, uint256 amount);
    event EscrowDisputed(bytes32 indexed escrowId, bytes32 disputeId);

    error EscrowNotOpen();
    error EscrowExpired();
    error AttestationFailed(string reason);
    error InvalidParties();
    error Replay();

    constructor(address _denylist, address _vault) Ownable(msg.sender) {
        denylist = IDenylist(_denylist);
        vault = IVault(_vault);
    }

    /// @notice Create an escrow for a bot-to-bot payment.
    /// @param escrowId Unique id (caller-generated, e.g. hash of intent + nonce).
    /// @param payee Address receiving funds on release.
    /// @param payerBotId On-chain bot id of the paying bot.
    /// @param payeeBotId On-chain bot id of the receiving bot.
    /// @param durationSeconds How long the escrow stays open before expiry.
    function createEscrow(
        bytes32 escrowId,
        address payee,
        bytes32 payerBotId,
        bytes32 payeeBotId,
        uint256 durationSeconds
    ) external payable nonReentrant returns (bytes32) {
        if (usedEscrowIds[escrowId]) revert Replay();
        if (payee == address(0) || msg.sender == payee) revert InvalidParties();
        if (payerBotId == bytes32(0) || payeeBotId == bytes32(0) || payerBotId == payeeBotId) {
            revert InvalidParties();
        }
        if (msg.value == 0) revert AttestationFailed("zero amount");
        if (durationSeconds == 0 || durationSeconds > 30 days) revert AttestationFailed("bad duration");

        // Fail closed at lock time so invalid counterparties cannot trap funds.
        _verifyBot(payerBotId, "payer");
        _verifyBot(payeeBotId, "payee");

        usedEscrowIds[escrowId] = true;
        uint256 expiresAt = block.timestamp + durationSeconds;
        escrows[escrowId] = Escrow({
            payer: msg.sender,
            payee: payee,
            payerBotId: payerBotId,
            payeeBotId: payeeBotId,
            amount: msg.value,
            createdAt: block.timestamp,
            expiresAt: expiresAt,
            state: EscrowState.Open,
            disputeId: bytes32(0)
        });

        emit EscrowCreated(escrowId, msg.sender, payee, payerBotId, payeeBotId, msg.value, expiresAt);
        return escrowId;
    }

    /// @notice Release funds to the payee after mutual attestation checks pass.
    /// @dev Both bots must be active in the Vault, not denylisted, and hold Financial+ tier.
    function release(bytes32 escrowId) external nonReentrant {
        Escrow storage e = escrows[escrowId];
        if (e.state != EscrowState.Open) revert EscrowNotOpen();
        if (block.timestamp > e.expiresAt) revert EscrowExpired();

        _verifyBot(e.payerBotId, "payer");
        _verifyBot(e.payeeBotId, "payee");

        e.state = EscrowState.Released;
        (bool ok, ) = e.payee.call{value: e.amount}("");
        require(ok, "transfer failed");
        emit EscrowReleased(escrowId, e.amount);
    }

    /// @notice Refund the payer if the escrow expires or a dispute is raised.
    function refund(bytes32 escrowId) external nonReentrant {
        Escrow storage e = escrows[escrowId];
        if (e.state != EscrowState.Open && e.state != EscrowState.Disputed) revert EscrowNotOpen();
        require(block.timestamp > e.expiresAt || e.state == EscrowState.Disputed, "not expired or disputed");

        e.state = EscrowState.Refunded;
        (bool ok, ) = e.payer.call{value: e.amount}("");
        require(ok, "refund failed");
        emit EscrowRefunded(escrowId, e.amount);
    }

    /// @notice Flag an escrow for dispute (e.g. one side's attestation is stale).
    function dispute(bytes32 escrowId, bytes32 disputeId) external {
        Escrow storage e = escrows[escrowId];
        if (e.state != EscrowState.Open) revert EscrowNotOpen();
        require(msg.sender == e.payer || msg.sender == e.payee, "not a party");
        e.state = EscrowState.Disputed;
        e.disputeId = disputeId;
        emit EscrowDisputed(escrowId, disputeId);
    }

    function _verifyBot(bytes32 botId, string memory role) internal view {
        (bytes32 weightHash, bytes32 behaviorSig, bytes32 promptHash, IVault.Tier tier, bool active, ) =
            vault.bots(botId);
        if (!active) revert AttestationFailed(string.concat(role, " bot inactive"));
        if (uint8(tier) < uint8(IVault.Tier.Financial)) {
            revert AttestationFailed(string.concat(role, " bot below Financial tier"));
        }
        // Vault access path (active + Financial+ perm cap). Catch string reverts
        // so callers always see AttestationFailed.
        try vault.grantAccess(botId, uint8(IVault.Tier.Financial)) returns (bool allowed) {
            if (!allowed) {
                revert AttestationFailed(string.concat(role, " bot access denied"));
            }
        } catch {
            revert AttestationFailed(string.concat(role, " bot access denied"));
        }
        IDenylist.MatchLevel level = denylist.check(weightHash, behaviorSig, promptHash);
        if (level != IDenylist.MatchLevel.None) {
            revert AttestationFailed(string.concat(role, " bot denylisted"));
        }
    }
}
