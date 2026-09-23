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
    function operator(bytes32 botId) external view returns (address);
    function bots(bytes32) external view returns (
        bytes32 weightHash,
        bytes32 behaviorSig,
        bytes32 promptHash,
        Tier tier,
        bool active,
        uint256 registeredAt
    );
}

interface IDisputePanel {
    function outcome(bytes32 disputeId)
        external
        view
        returns (bool exists, bool resolved, bool upheld, bytes32 subjectHash);
}

/// @title BotAttestationEscrow
/// @notice Escrows value for a bot-to-bot transaction until both sides verify each other.
contract BotAttestationEscrow is Ownable2Step, ReentrancyGuard {
    IDenylist public denylist;
    IVault public vault;
    IDisputePanel public disputePanel;

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
    event DenylistUpdated(address indexed denylist);
    event VaultUpdated(address indexed vault);
    event DisputePanelUpdated(address indexed panel);

    error EscrowNotOpen();
    error EscrowExpired();
    error AttestationFailed(string reason);
    error InvalidParties();
    error Replay();
    error InvalidDispute();
    error DisputePending();
    error ZeroAddress();

    constructor(address _denylist, address _vault, address _panel) Ownable(msg.sender) {
        _setDenylist(_denylist);
        _setVault(_vault);
        _setDisputePanel(_panel);
    }

    /// @notice Re-point denylist after deploy (timelock/owner only).
    function setDenylist(address _denylist) external onlyOwner {
        _setDenylist(_denylist);
    }

    /// @notice Re-point vault after deploy (timelock/owner only).
    function setVault(address _vault) external onlyOwner {
        _setVault(_vault);
    }

    /// @notice Re-point dispute panel after deploy (timelock/owner only).
    function setDisputePanel(address _panel) external onlyOwner {
        _setDisputePanel(_panel);
    }

    function _setDenylist(address _denylist) internal {
        if (_denylist == address(0)) revert ZeroAddress();
        denylist = IDenylist(_denylist);
        emit DenylistUpdated(_denylist);
    }

    function _setVault(address _vault) internal {
        if (_vault == address(0)) revert ZeroAddress();
        vault = IVault(_vault);
        emit VaultUpdated(_vault);
    }

    function _setDisputePanel(address _panel) internal {
        if (_panel == address(0)) revert ZeroAddress();
        disputePanel = IDisputePanel(_panel);
        emit DisputePanelUpdated(_panel);
    }

    /// @notice Create an escrow for a bot-to-bot payment.
    /// @param escrowId Unique id (caller-generated, e.g. hash of intent + nonce).
    /// @param payee Address receiving funds on release. Must be the payee bot's Vault operator.
    /// @param payerBotId On-chain bot id of the paying bot. Caller must be its Vault operator.
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

        // EOA ↔ botId bind: only the Vault operator may lock or receive under a botId.
        if (vault.operator(payerBotId) != msg.sender) revert InvalidParties();
        if (vault.operator(payeeBotId) != payee) revert InvalidParties();

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
    ///      A disputed escrow can release only if the panel upheld the original deal.
    ///      That upheld path stays open after `expiresAt`: expiry must not strand the payee
    ///      or let `refund` pay the payer once the panel has ruled the deal stands.
    function release(bytes32 escrowId) external nonReentrant {
        Escrow storage e = escrows[escrowId];
        bool panelUpheld = false;
        if (e.state == EscrowState.Disputed) {
            _requirePanelUpheld(e, escrowId);
            panelUpheld = true;
        } else if (e.state != EscrowState.Open) {
            revert EscrowNotOpen();
        }
        // Open escrows expire. An upheld dispute does not: release remains the payee path.
        if (!panelUpheld && block.timestamp > e.expiresAt) revert EscrowExpired();

        _requireBoundOperators(e);
        _verifyBot(e.payerBotId, "payer");
        _verifyBot(e.payeeBotId, "payee");

        e.state = EscrowState.Released;
        (bool ok, ) = e.payee.call{value: e.amount}("");
        require(ok, "transfer failed");
        emit EscrowReleased(escrowId, e.amount);
    }

    /// @notice Refund the payer if the escrow expires or the panel rules an unwind.
    /// @dev `Disputed` alone is not enough — that would let either party unwind unilaterally.
    ///      An upheld panel ruling closes refund permanently, including after `expiresAt`.
    ///      Expiry remains the backstop only when the panel has not upheld the deal
    ///      (still pending, or resolved as an unwind).
    function refund(bytes32 escrowId) external nonReentrant {
        Escrow storage e = escrows[escrowId];
        if (e.state == EscrowState.Open) {
            require(block.timestamp > e.expiresAt, "not expired");
        } else if (e.state == EscrowState.Disputed) {
            // Upheld means the original deal stands. Do not let expiry flip that into a payer refund.
            if (_panelUpheld(e, escrowId)) revert DisputePending();
            if (block.timestamp <= e.expiresAt) {
                _requirePanelUnwind(e, escrowId);
            }
            // else: expiry is the timelock backstop when the panel has not upheld
        } else {
            revert EscrowNotOpen();
        }

        e.state = EscrowState.Refunded;
        (bool ok, ) = e.payer.call{value: e.amount}("");
        require(ok, "refund failed");
        emit EscrowRefunded(escrowId, e.amount);
    }

    /// @notice Flag an escrow for dispute. Does not authorize a refund.
    /// @dev `disputeId` must already exist on the DisputePanel with subjectHash == escrowId.
    function dispute(bytes32 escrowId, bytes32 disputeId) external {
        Escrow storage e = escrows[escrowId];
        if (e.state != EscrowState.Open) revert EscrowNotOpen();
        require(msg.sender == e.payer || msg.sender == e.payee, "not a party");
        if (disputeId == bytes32(0)) revert InvalidDispute();
        (bool exists, , , bytes32 subject) = disputePanel.outcome(disputeId);
        if (!exists || subject != escrowId) revert InvalidDispute();
        e.state = EscrowState.Disputed;
        e.disputeId = disputeId;
        emit EscrowDisputed(escrowId, disputeId);
    }

    function _requireBoundOperators(Escrow storage e) internal view {
        if (vault.operator(e.payerBotId) != e.payer) revert InvalidParties();
        if (vault.operator(e.payeeBotId) != e.payee) revert InvalidParties();
    }

    /// @dev True only when this escrow's panel case exists, matches, is resolved, and is upheld.
    function _panelUpheld(Escrow storage e, bytes32 escrowId) internal view returns (bool) {
        (bool exists, bool resolved, bool upheld, bytes32 subject) = disputePanel.outcome(e.disputeId);
        return exists && subject == escrowId && resolved && upheld;
    }

    function _requirePanelUnwind(Escrow storage e, bytes32 escrowId) internal view {
        (bool exists, bool resolved, bool upheld, bytes32 subject) = disputePanel.outcome(e.disputeId);
        if (!exists || subject != escrowId) revert InvalidDispute();
        if (!resolved) revert DisputePending();
        if (upheld) revert DisputePending();
    }

    function _requirePanelUpheld(Escrow storage e, bytes32 escrowId) internal view {
        (bool exists, bool resolved, bool upheld, bytes32 subject) = disputePanel.outcome(e.disputeId);
        if (!exists || subject != escrowId) revert InvalidDispute();
        if (!resolved || !upheld) revert DisputePending();
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
