// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { Script, console } from "forge-std/Script.sol";
import { BVT } from "../contracts/bvt/BVT.sol";
import { BVTStaking } from "../contracts/bvt/BVTStaking.sol";
import { BVTFeeRouter } from "../contracts/bvt/BVTFeeRouter.sol";
import { BVTTimelock } from "../contracts/bvt/BVTTimelock.sol";
import { BVTGovernor } from "../contracts/bvt/BVTGovernor.sol";

/// @notice Deploy the additive BVT stack. Does not touch Denylist/Vault/Liability.
/// Chainid guard: Base Sepolia (84532) only. Mainnet (1) always reverts.
/// Agents do not --broadcast. Spencer runs the broadcast command locally.
///
/// Testnet role graph (intentional): the deployer keeps DEFAULT_ADMIN on BVT,
/// BVTStaking, and BVTFeeRouter, plus BOOTSTRAP_ROLE, SLASHER_ROLE, and
/// EARNER_ROLE (constructor). Timelock also gets GOVERNANCE / SLASHER / EARNER.
/// Before any mainnet discussion: grant those roles to the timelock (and
/// DisputePanel for slash), then `renounceRole` the deployer keys. This script
/// does not auto-renounce — Sepolia stays operable for Spencer.
contract DeployBVT is Script {
    uint256 public constant BASE_SEPOLIA_CHAIN_ID = 84532;
    uint256 public constant ETH_SEPOLIA_CHAIN_ID = 11155111;
    uint256 public constant ETH_MAINNET_CHAIN_ID = 1;
    uint256 public constant ALLOWED_CHAIN_ID = BASE_SEPOLIA_CHAIN_ID;

    function requireAllowedChain() public view {
        if (block.chainid == ETH_MAINNET_CHAIN_ID) {
            revert("DeployBVT: mainnet forbidden");
        }
        if (block.chainid != ALLOWED_CHAIN_ID) {
            revert("DeployBVT: Base Sepolia (84532) only; see README to switch to ETH Sepolia (11155111)");
        }
    }

    function run() external {
        requireAllowedChain();

        uint256 deployerKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerKey);

        address insuranceSink = _optionalAddr("BVT_INSURANCE_SINK", deployer);
        address treasury = _optionalAddr("BVT_TREASURY", deployer);
        address guardian = _optionalAddr("BVT_GUARDIAN", deployer);

        vm.startBroadcast(deployerKey);

        BVT bvt = new BVT(deployer);
        BVTTimelock timelock = new BVTTimelock(deployer, guardian);
        BVTStaking staking = new BVTStaking(bvt, deployer, insuranceSink);
        BVTFeeRouter fees = new BVTFeeRouter(bvt, staking, deployer, insuranceSink, treasury);
        BVTGovernor governor = new BVTGovernor(staking, timelock, deployer);

        wire(bvt, staking, fees, timelock, governor, deployer);

        vm.stopBroadcast();

        console.log("chainid", block.chainid);
        console.log("BVT", address(bvt));
        console.log("BVTStaking", address(staking));
        console.log("BVTFeeRouter", address(fees));
        console.log("BVTTimelock", address(timelock));
        console.log("BVTGovernor", address(governor));
        console.log("insuranceSink", insuranceSink);
        console.log("treasury", treasury);
        console.log("totalSupply (must be 0)", bvt.totalSupply());
        console.log("Post these addresses in contracts/README.md after deploy. Never commit PRIVATE_KEY.");
        console.log("No premine: bootstrap operators via BVTStaking.bootstrapOperator (locks immediately).");
    }

    /// @dev Shared wiring so tests can assert the same role graph as production deploy.
    /// Deployer retains admin/bootstrap/slash/earn on testnet. Mainnet must
    /// move those to the timelock (slash → DisputePanel) and renounce deployer.
    function wire(
        BVT bvt,
        BVTStaking staking,
        BVTFeeRouter fees,
        BVTTimelock timelock,
        BVTGovernor governor,
        address deployer
    ) internal {
        bvt.grantRole(bvt.MINTER_ROLE(), address(staking));
        bvt.grantRole(bvt.MINTER_ROLE(), address(fees));
        bvt.grantRole(bvt.LOCKER_ROLE(), address(staking));

        staking.grantRole(staking.BOOTSTRAP_ROLE(), deployer);
        staking.grantRole(staking.SLASHER_ROLE(), address(timelock));
        staking.grantRole(staking.SLASHER_ROLE(), deployer); // testnet: move to DisputePanel later
        staking.grantRole(staking.REWARDER_ROLE(), address(fees));
        staking.grantRole(staking.GOVERNANCE_ROLE(), address(timelock));

        fees.grantRole(fees.GOVERNANCE_ROLE(), address(timelock));
        fees.grantRole(fees.EARNER_ROLE(), address(timelock));

        timelock.setGovernor(address(governor));
    }

    function _optionalAddr(
        string memory key,
        address fallbackAddr
    ) internal view returns (address) {
        try vm.envAddress(key) returns (address set) {
            if (set != address(0)) return set;
        } catch { }
        return fallbackAddr;
    }
}
