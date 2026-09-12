// SPDX-License-Identifier: MIT
// Auditor / operator staking. Aligns with economic_security/auditor_staking_schema.md
// and consensus/slash_rules.md. Not audited. For illustration and local testing.
pragma solidity ^0.8.20;

import { AccessControl } from "@openzeppelin/contracts/access/AccessControl.sol";
import { BVT } from "./BVT.sol";
import { IAuditorStakeView, IAuditorSlash, SlashReason } from "./IBVTHooks.sol";

/// @title BVTStaking
/// @notice Auditors lock BVT to participate, earn fees, and get slashed for bad audits.
contract BVTStaking is AccessControl, IAuditorStakeView, IAuditorSlash {
    bytes32 public constant SLASHER_ROLE = keccak256("SLASHER_ROLE");
    bytes32 public constant BOOTSTRAP_ROLE = keccak256("BOOTSTRAP_ROLE");
    bytes32 public constant REWARDER_ROLE = keccak256("REWARDER_ROLE");
    bytes32 public constant GOVERNANCE_ROLE = keccak256("GOVERNANCE_ROLE");

    uint256 public constant BPS_DENOM = 10_000;

    BVT public immutable bvt;

    uint256 public constant MIN_UNSTAKE_COOLDOWN = 1 hours;

    uint256 public minStake = 10_000 ether;
    uint256 public unstakeCooldown = 48 hours;
    uint256 public totalStaked;
    uint256 public rewardReserve;

    mapping(SlashReason => uint256) public slashBps;
    address public insuranceSink;

    struct Auditor {
        uint256 stake;
        uint256 pendingUnstake;
        uint256 unstakeAvailableAt;
        uint256 auditsSubmitted;
        uint256 fraudCount;
        bool active;
        bool banned;
    }

    mapping(address => Auditor) public auditors;

    struct Checkpoint {
        uint256 fromBlock;
        uint256 value;
    }

    mapping(address => Checkpoint[]) private _stakeCheckpoints;
    Checkpoint[] private _totalCheckpoints;

    event Staked(address indexed auditor, uint256 amount);
    event UnstakeRequested(address indexed auditor, uint256 amount, uint256 availableAt);
    event StakeWithdrawn(address indexed auditor, uint256 amount);
    event Slashed(address indexed auditor, uint256 amount, SlashReason reason, address indexed challenger);
    event RewardPaid(address indexed auditor, uint256 amount);
    event OperatorBootstrapped(address indexed operator, uint256 amount);
    event AuditRecorded(address indexed auditor, uint256 auditsSubmitted);
    event MinStakeUpdated(uint256 minStake);
    event UnstakeCooldownUpdated(uint256 cooldown);
    event SlashBpsUpdated(SlashReason reason, uint256 bps);
    event InsuranceSinkUpdated(address sink);
    event Unbanned(address indexed auditor);

    constructor(
        BVT _bvt,
        address admin,
        address _insuranceSink
    ) {
        require(address(_bvt) != address(0) && admin != address(0), "Staking: zero");
        bvt = _bvt;
        insuranceSink = _insuranceSink;
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(GOVERNANCE_ROLE, admin);

        // consensus/slash_rules.md
        slashBps[SlashReason.FakeHash] = BPS_DENOM; // 100%
        slashBps[SlashReason.RiggedScores] = BPS_DENOM; // 100% + ban
        slashBps[SlashReason.BuriedIncidents] = 5_000; // 50%
    }

    function isActiveAuditor(
        address auditor
    ) public view returns (bool) {
        Auditor storage a = auditors[auditor];
        return a.active && !a.banned && a.stake >= minStake;
    }

    function stakeOf(
        address auditor
    ) public view returns (uint256) {
        return auditors[auditor].stake;
    }

    /// @notice Stake at `blockNumber` (inclusive). Used by the governor snapshot.
    function stakeOfAt(
        address auditor,
        uint256 blockNumber
    ) public view returns (uint256) {
        return _lookup(_stakeCheckpoints[auditor], blockNumber);
    }

    function totalStakedAt(
        uint256 blockNumber
    ) public view returns (uint256) {
        return _lookup(_totalCheckpoints, blockNumber);
    }

    function isBanned(
        address auditor
    ) public view returns (bool) {
        return auditors[auditor].banned;
    }

    /// @notice Lock already-held BVT. Becomes active at minStake.
    function stake(
        uint256 amount
    ) external {
        require(amount > 0, "Staking: amount zero");
        Auditor storage a = auditors[msg.sender];
        require(!a.banned, "Staking: banned");
        bvt.lock(msg.sender, amount);
        a.stake += amount;
        totalStaked += amount;
        if (a.stake >= minStake) a.active = true;
        _writeStake(msg.sender, a.stake);
        emit Staked(msg.sender, amount);
    }

    /// @notice Mint-and-lock for a protocol operator. Not a public sale.
    function bootstrapOperator(
        address operator,
        uint256 amount
    ) external onlyRole(BOOTSTRAP_ROLE) {
        require(operator != address(0), "Staking: operator zero");
        require(amount >= minStake, "Staking: below min");
        Auditor storage a = auditors[operator];
        require(!a.banned, "Staking: banned");
        bvt.mint(operator, amount);
        bvt.lock(operator, amount);
        a.stake += amount;
        a.active = true;
        totalStaked += amount;
        _writeStake(operator, a.stake);
        emit OperatorBootstrapped(operator, amount);
        emit Staked(operator, amount);
    }

    /// @notice Start cooldown (default 48h dispute window). Drops below minStake → inactive.
    function requestUnstake(
        uint256 amount
    ) external {
        Auditor storage a = auditors[msg.sender];
        require(amount > 0 && a.stake >= amount, "Staking: bad amount");
        a.stake -= amount;
        a.pendingUnstake += amount;
        a.unstakeAvailableAt = block.timestamp + unstakeCooldown;
        totalStaked -= amount;
        if (a.stake < minStake) a.active = false;
        _writeStake(msg.sender, a.stake);
        emit UnstakeRequested(msg.sender, amount, a.unstakeAvailableAt);
    }

    /// @notice Exit after cooldown. Tokens stay locked until this call.
    function withdrawStake() external {
        Auditor storage a = auditors[msg.sender];
        uint256 amount = a.pendingUnstake;
        require(amount > 0, "Staking: nothing pending");
        require(block.timestamp >= a.unstakeAvailableAt, "Staking: cooldown");
        a.pendingUnstake = 0;
        a.unstakeAvailableAt = 0;
        bvt.unlock(msg.sender, amount);
        emit StakeWithdrawn(msg.sender, amount);
    }

    function slash(
        address auditor,
        SlashReason reason,
        address challenger
    ) external onlyRole(SLASHER_ROLE) {
        uint256 bps = slashBps[reason];
        require(bps > 0 && bps <= BPS_DENOM, "Staking: slash bps");
        Auditor storage a = auditors[auditor];
        uint256 lockedAmount = a.stake + a.pendingUnstake;
        require(lockedAmount > 0, "Staking: no stake");

        uint256 cut = (lockedAmount * bps) / BPS_DENOM;
        _reduceLocked(a, cut);
        a.fraudCount += 1;
        if (reason == SlashReason.FakeHash || reason == SlashReason.RiggedScores || a.stake < minStake) {
            a.active = false;
        }
        if (reason == SlashReason.FakeHash || reason == SlashReason.RiggedScores) {
            a.banned = true;
        }

        _writeStake(auditor, a.stake);
        _distributeSlash(auditor, cut, challenger);
        emit Slashed(auditor, cut, reason, challenger);
    }

    function recordAudit(
        address auditor
    ) external onlyRole(REWARDER_ROLE) {
        require(isActiveAuditor(auditor), "Staking: inactive");
        auditors[auditor].auditsSubmitted += 1;
        emit AuditRecorded(auditor, auditors[auditor].auditsSubmitted);
    }

    function fundRewards(
        uint256 amount
    ) external onlyRole(REWARDER_ROLE) {
        require(amount > 0, "Staking: amount zero");
        require(bvt.transferFrom(msg.sender, address(this), amount), "Staking: transfer");
        rewardReserve += amount;
        emit RewardPaid(address(this), amount);
    }

    function payReward(
        address auditor,
        uint256 amount
    ) external onlyRole(REWARDER_ROLE) {
        require(amount > 0 && rewardReserve >= amount, "Staking: reserve");
        rewardReserve -= amount;
        require(bvt.transfer(auditor, amount), "Staking: reward xfer");
        emit RewardPaid(auditor, amount);
    }

    function setMinStake(
        uint256 next
    ) external onlyRole(GOVERNANCE_ROLE) {
        require(next > 0, "Staking: min zero");
        minStake = next;
        emit MinStakeUpdated(next);
    }

    function setUnstakeCooldown(
        uint256 next
    ) external onlyRole(GOVERNANCE_ROLE) {
        require(next >= MIN_UNSTAKE_COOLDOWN, "Staking: cooldown floor");
        unstakeCooldown = next;
        emit UnstakeCooldownUpdated(next);
    }

    function setSlashBps(
        SlashReason reason,
        uint256 bps
    ) external onlyRole(GOVERNANCE_ROLE) {
        require(bps <= BPS_DENOM, "Staking: bps");
        slashBps[reason] = bps;
        emit SlashBpsUpdated(reason, bps);
    }

    function setInsuranceSink(
        address sink
    ) external onlyRole(GOVERNANCE_ROLE) {
        insuranceSink = sink;
        emit InsuranceSinkUpdated(sink);
    }

    function unban(
        address auditor
    ) external onlyRole(GOVERNANCE_ROLE) {
        auditors[auditor].banned = false;
        emit Unbanned(auditor);
    }

    function _reduceLocked(
        Auditor storage a,
        uint256 cut
    ) internal {
        uint256 fromStake = cut > a.stake ? a.stake : cut;
        a.stake -= fromStake;
        totalStaked -= fromStake;
        uint256 remainder = cut - fromStake;
        if (remainder > 0) {
            require(a.pendingUnstake >= remainder, "Staking: slash math");
            a.pendingUnstake -= remainder;
        }
        if (a.stake < minStake) a.active = false;
    }

    function _writeStake(
        address account,
        uint256 newStake
    ) internal {
        _push(_stakeCheckpoints[account], newStake);
        _push(_totalCheckpoints, totalStaked);
    }

    function _push(
        Checkpoint[] storage cks,
        uint256 value
    ) private {
        uint256 b = block.number;
        uint256 n = cks.length;
        if (n > 0 && cks[n - 1].fromBlock == b) {
            cks[n - 1].value = value;
            return;
        }
        cks.push(Checkpoint({ fromBlock: b, value: value }));
    }

    function _lookup(
        Checkpoint[] storage cks,
        uint256 blockNumber
    ) private view returns (uint256) {
        uint256 n = cks.length;
        if (n == 0 || cks[0].fromBlock > blockNumber) return 0;
        uint256 i = n;
        while (i > 0) {
            unchecked {
                i--;
            }
            if (cks[i].fromBlock <= blockNumber) return cks[i].value;
        }
        return 0;
    }

    /// @dev Challenger 30% (unlocked to them), rest to insurance still locked then unlocked.
    function _distributeSlash(
        address auditor,
        uint256 cut,
        address challenger
    ) internal {
        uint256 toChallenger;
        if (challenger != address(0) && challenger != auditor) {
            toChallenger = (cut * 3_000) / BPS_DENOM;
        }
        uint256 toInsurance = cut - toChallenger;
        if (toChallenger > 0) {
            bvt.moveLocked(auditor, challenger, toChallenger);
            bvt.unlock(challenger, toChallenger);
        }
        if (toInsurance > 0) {
            address sink = insuranceSink == address(0) ? address(this) : insuranceSink;
            if (sink == address(this)) {
                bvt.burnLocked(auditor, toInsurance);
            } else {
                bvt.moveLocked(auditor, sink, toInsurance);
                bvt.unlock(sink, toInsurance);
            }
        }
    }
}
