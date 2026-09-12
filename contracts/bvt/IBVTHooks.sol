// SPDX-License-Identifier: MIT
// Additive hooks so Denylist / Vault / DisputePanel can gate on BVT later
// without changing today's go-live contracts.
// Not audited. For illustration and local testing.
pragma solidity ^0.8.20;

/// @notice Fee kinds bots pay in BVT to use the verifier stack.
enum FeeKind {
    Registration,
    Audit,
    VaultAccess
}

/// @notice Vault / Denylist can call this before register / grantAccess / add*.
interface IBVTFeeGate {
    function hasPaid(
        bytes32 botId,
        FeeKind kind
    ) external view returns (bool);

    function requirePaid(
        bytes32 botId,
        FeeKind kind
    ) external view;

    function vaultTierPaid(
        bytes32 botId
    ) external view returns (uint8);
}

/// @notice Vault / DisputePanel / Liability can read auditor skin-in-the-game.
interface IAuditorStakeView {
    function isActiveAuditor(
        address auditor
    ) external view returns (bool);

    function stakeOf(
        address auditor
    ) external view returns (uint256);

    function minStake() external view returns (uint256);

    function isBanned(
        address auditor
    ) external view returns (bool);
}

/// @notice DisputePanel (or a future slash council) can hold SLASHER_ROLE.
enum SlashReason {
    FakeHash,
    RiggedScores,
    BuriedIncidents
}

interface IAuditorSlash {
    function slash(
        address auditor,
        SlashReason reason,
        address challenger
    ) external;
}

/// @notice Future path: transfer Denylist/Vault `owner` to the BVT timelock so
/// denylist upgrades and tier changes are proposal + delay, not a hot key.
interface IOwnableHook {
    function owner() external view returns (address);

    function setOwner(
        address newOwner
    ) external;
}
