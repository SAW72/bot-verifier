// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { Script, console } from "forge-std/Script.sol";
import { BotAttestationEscrow } from "../contracts/BotAttestationEscrow.sol";

/// @notice Additive deploy of BotAttestationEscrow against an existing core stack.
/// Does not redeploy Denylist / Vault / DisputePanel — pass their addresses via env.
/// After deploy: `transferOwnership(CORE_TIMELOCK)` (Ownable2Step; timelock must
/// `acceptOwnership`). `governance` is that same timelock, passed into the constructor.
/// `createEscrow` and `setDenylist` revert until the timelock has accepted, and
/// `setDenylist` also reverts while ETH is locked (`lockedValue != 0`).
/// Denylist, vault, and panel swaps are timelock events
/// (`DenylistUpdated`, `VaultUpdated`, `DisputePanelUpdated`: previous, new, caller, timestamp).
/// Do not fund before accept.
/// There is no production EOA admin for `setDenylist`.
/// Chainid guard: Base Sepolia (84532) only. Mainnet is always refused.
/// ETH Sepolia (11155111) is documented as a one-line switch — do not enable it
/// here unless you intentionally change ALLOWED_CHAIN_ID.
/// Agents do not --broadcast. Spencer runs the broadcast command locally.
contract DeployBotAttestationEscrow is Script {
    uint256 public constant BASE_SEPOLIA_CHAIN_ID = 84532;
    uint256 public constant ETH_SEPOLIA_CHAIN_ID = 11155111;
    uint256 public constant ETH_MAINNET_CHAIN_ID = 1;
    uint256 public constant ALLOWED_CHAIN_ID = BASE_SEPOLIA_CHAIN_ID;

    function requireAllowedChain() public view {
        if (block.chainid == ETH_MAINNET_CHAIN_ID) {
            revert("DeployEscrow: mainnet forbidden");
        }
        if (block.chainid != ALLOWED_CHAIN_ID) {
            revert("DeployEscrow: Base Sepolia (84532) only; see README to switch to ETH Sepolia (11155111)");
        }
    }

    function requireTimelock(
        address deployer,
        address timelock
    ) public pure {
        if (timelock == address(0)) revert("DeployEscrow: CORE_TIMELOCK unset");
        if (timelock == deployer) revert("DeployEscrow: CORE_TIMELOCK must not be deployer");
    }

    function requireDeps(
        address denylist,
        address vault,
        address panel
    ) public pure {
        if (denylist == address(0)) revert("DeployEscrow: DENYLIST unset");
        if (vault == address(0)) revert("DeployEscrow: VAULT unset");
        if (panel == address(0)) revert("DeployEscrow: DISPUTE_PANEL unset");
    }

    function readAddress(
        string memory key,
        string memory unsetErr
    ) public view returns (address a) {
        try vm.envAddress(key) returns (address set) {
            a = set;
        } catch {
            revert(unsetErr);
        }
        if (a == address(0)) revert(unsetErr);
    }

    /// @notice Deploy + hand ownership to timelock. Used by `run` and by tests (no broadcast).
    function deploy(
        address denylist,
        address vault,
        address panel,
        address timelock
    ) public returns (BotAttestationEscrow escrow) {
        requireDeps(denylist, vault, panel);
        escrow = new BotAttestationEscrow(denylist, vault, panel, timelock);
        escrow.transferOwnership(timelock);
    }

    function run() external {
        requireAllowedChain();

        uint256 deployerKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerKey);
        address timelock = readAddress("CORE_TIMELOCK", "DeployEscrow: CORE_TIMELOCK unset");
        requireTimelock(deployer, timelock);

        address denylist = readAddress("DENYLIST", "DeployEscrow: DENYLIST unset");
        address vault = readAddress("VAULT", "DeployEscrow: VAULT unset");
        address panel = readAddress("DISPUTE_PANEL", "DeployEscrow: DISPUTE_PANEL unset");
        requireDeps(denylist, vault, panel);

        vm.startBroadcast(deployerKey);
        BotAttestationEscrow escrow = deploy(denylist, vault, panel, timelock);
        vm.stopBroadcast();

        console.log("chainid", block.chainid);
        console.log("BotAttestationEscrow", address(escrow));
        console.log("Denylist", denylist);
        console.log("Vault", vault);
        console.log("DisputePanel", panel);
        console.log("CORE_TIMELOCK", timelock);
        console.log("Post the escrow address in contracts/README.md after deploy. Never commit PRIVATE_KEY.");
        console.log("Agents must not --broadcast. Spencer runs forge script ... --broadcast.");
    }
}
