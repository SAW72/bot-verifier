// SPDX-License-Identifier: MIT
// Bots pay BVT to register, get audited, and access the vault.
// Usage earn mints BVT to the auditor who did the work.
// Not audited. For illustration and local testing.
pragma solidity ^0.8.20;

import { AccessControl } from "@openzeppelin/contracts/access/AccessControl.sol";
import { BVT } from "./BVT.sol";
import { BVTStaking } from "./BVTStaking.sol";
import { FeeKind, IBVTFeeGate } from "./IBVTHooks.sol";

/// @title BVTFeeRouter
/// @notice Collects protocol fees and mints usage rewards. Vault/Denylist hook later via IBVTFeeGate.
contract BVTFeeRouter is AccessControl, IBVTFeeGate {
    bytes32 public constant EARNER_ROLE = keccak256("EARNER_ROLE");
    bytes32 public constant GOVERNANCE_ROLE = keccak256("GOVERNANCE_ROLE");

    uint256 public constant BPS_DENOM = 10_000;

    BVT public immutable bvt;
    BVTStaking public staking;

    address public insuranceSink;
    address public treasury;

    uint256 public auditorBps = 7_000; // 70% — honest auditor / reward path
    uint256 public insuranceBps = 2_000; // 20% — insurance backstop
    // remainder (10%) → treasury

    mapping(FeeKind => uint256) public feeOf;
    mapping(uint8 => uint256) public vaultFeeByTier; // Vault.Tier ordinal
    mapping(bytes32 => mapping(FeeKind => bool)) internal _paid;
    mapping(bytes32 => uint8) internal _vaultTierPaid;
    mapping(bytes32 => bool) internal _settled;

    uint256 public usageReward; // default earn mint on settleAudit

    event FeePaid(bytes32 indexed botId, FeeKind kind, address indexed payer, uint256 amount, address auditor);
    event UsageEarned(address indexed auditor, uint256 amount, bytes32 indexed botId);
    event AuditSettled(bytes32 indexed botId, address indexed auditor, uint256 earnAmount);
    event FeeUpdated(FeeKind kind, uint256 amount);
    event VaultTierFeeUpdated(uint8 tier, uint256 amount);
    event SplitUpdated(uint256 auditorBps, uint256 insuranceBps);
    event SinksUpdated(address insuranceSink, address treasury);
    event UsageRewardUpdated(uint256 amount);

    constructor(
        BVT _bvt,
        BVTStaking _staking,
        address admin,
        address _insuranceSink,
        address _treasury
    ) {
        require(address(_bvt) != address(0) && address(_staking) != address(0), "Fee: zero");
        require(admin != address(0) && _insuranceSink != address(0) && _treasury != address(0), "Fee: sink zero");
        bvt = _bvt;
        staking = _staking;
        insuranceSink = _insuranceSink;
        treasury = _treasury;
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(GOVERNANCE_ROLE, admin);
        _grantRole(EARNER_ROLE, admin);

        feeOf[FeeKind.Registration] = 100 ether;
        feeOf[FeeKind.Audit] = 250 ether;
        feeOf[FeeKind.VaultAccess] = 50 ether;
        usageReward = 50 ether;

        // Vault.Tier { None, Chat, DataTools, Financial, Critical }
        vaultFeeByTier[1] = 50 ether;
        vaultFeeByTier[2] = 100 ether;
        vaultFeeByTier[3] = 250 ether;
        vaultFeeByTier[4] = 500 ether;
    }

    function hasPaid(
        bytes32 botId,
        FeeKind kind
    ) public view returns (bool) {
        return _paid[botId][kind];
    }

    function requirePaid(
        bytes32 botId,
        FeeKind kind
    ) external view {
        require(_paid[botId][kind], "Fee: unpaid");
    }

    function vaultTierPaid(
        bytes32 botId
    ) external view returns (uint8) {
        return _vaultTierPaid[botId];
    }

    function isSettled(
        bytes32 botId
    ) public view returns (bool) {
        return _settled[botId];
    }

    /// @notice Bot (or payer) spends unlocked BVT. Auditor share parks in treasury if no auditor.
    function pay(
        bytes32 botId,
        FeeKind kind
    ) external {
        _collect(botId, kind, feeOf[kind], address(0));
    }

    function payAudit(
        bytes32 botId,
        address auditor
    ) external {
        require(staking.isActiveAuditor(auditor), "Fee: inactive auditor");
        _collect(botId, FeeKind.Audit, feeOf[FeeKind.Audit], auditor);
    }

    function payVaultAccess(
        bytes32 botId,
        uint8 tier
    ) external {
        uint256 fee = vaultFeeByTier[tier];
        require(fee > 0, "Fee: tier unset");
        _collect(botId, FeeKind.VaultAccess, fee, address(0));
        _vaultTierPaid[botId] = tier;
    }

    /// @notice Protocol-attested earn path: mint BVT to the auditor after the audit fee is paid.
    function settleAudit(
        bytes32 botId,
        address auditor,
        uint256 earnAmount
    ) external onlyRole(EARNER_ROLE) {
        require(_paid[botId][FeeKind.Audit], "Fee: audit unpaid");
        require(!_settled[botId], "Fee: already settled");
        require(staking.isActiveAuditor(auditor), "Fee: inactive auditor");
        _settled[botId] = true;
        staking.recordAudit(auditor);
        uint256 minted = earnAmount;
        if (minted == 0) minted = usageReward;
        if (minted > 0) {
            bvt.mint(auditor, minted);
            emit UsageEarned(auditor, minted, botId);
        }
        emit AuditSettled(botId, auditor, minted);
    }

    /// @notice Direct usage mint (scenario contribution, meta-audit, etc.). Not a sale.
    function awardUsage(
        address to,
        uint256 amount,
        bytes32 reason
    ) external onlyRole(EARNER_ROLE) {
        require(to != address(0) && amount > 0, "Fee: bad award");
        bvt.mint(to, amount);
        emit UsageEarned(to, amount, reason);
    }

    function setFee(
        FeeKind kind,
        uint256 amount
    ) external onlyRole(GOVERNANCE_ROLE) {
        feeOf[kind] = amount;
        emit FeeUpdated(kind, amount);
    }

    function setVaultTierFee(
        uint8 tier,
        uint256 amount
    ) external onlyRole(GOVERNANCE_ROLE) {
        vaultFeeByTier[tier] = amount;
        emit VaultTierFeeUpdated(tier, amount);
    }

    function setSplit(
        uint256 _auditorBps,
        uint256 _insuranceBps
    ) external onlyRole(GOVERNANCE_ROLE) {
        require(_auditorBps + _insuranceBps <= BPS_DENOM, "Fee: split");
        auditorBps = _auditorBps;
        insuranceBps = _insuranceBps;
        emit SplitUpdated(_auditorBps, _insuranceBps);
    }

    function setSinks(
        address _insuranceSink,
        address _treasury
    ) external onlyRole(GOVERNANCE_ROLE) {
        require(_insuranceSink != address(0) && _treasury != address(0), "Fee: sink zero");
        insuranceSink = _insuranceSink;
        treasury = _treasury;
        emit SinksUpdated(_insuranceSink, _treasury);
    }

    function setStaking(
        BVTStaking next
    ) external onlyRole(GOVERNANCE_ROLE) {
        require(address(next) != address(0), "Fee: staking zero");
        staking = next;
    }

    function setUsageReward(
        uint256 amount
    ) external onlyRole(GOVERNANCE_ROLE) {
        usageReward = amount;
        emit UsageRewardUpdated(amount);
    }

    function _collect(
        bytes32 botId,
        FeeKind kind,
        uint256 fee,
        address auditor
    ) internal {
        require(fee > 0, "Fee: unset");
        require(!_paid[botId][kind], "Fee: already paid");
        _paid[botId][kind] = true;
        require(bvt.transferFrom(msg.sender, address(this), fee), "Fee: transfer");

        uint256 forAuditor = (fee * auditorBps) / BPS_DENOM;
        uint256 forInsurance = (fee * insuranceBps) / BPS_DENOM;
        uint256 forTreasury = fee - forAuditor - forInsurance;

        if (forAuditor > 0) {
            address dest = auditor == address(0) ? treasury : auditor;
            require(bvt.transfer(dest, forAuditor), "Fee: auditor");
        }
        if (forInsurance > 0) {
            require(bvt.transfer(insuranceSink, forInsurance), "Fee: insurance");
        }
        if (forTreasury > 0) {
            require(bvt.transfer(treasury, forTreasury), "Fee: treasury");
        }
        emit FeePaid(botId, kind, msg.sender, fee, auditor);
    }
}
