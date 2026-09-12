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
/// After `wire`, `harden` grants hot roles to the timelock and the deployer
/// renounces EARNER / BOOTSTRAP / SLASHER / GOVERNANCE / DEFAULT_ADMIN and
/// hands timelock+governor admin to the timelock. Insurance/treasury default
/// to the timelock (override with BVT_INSURANCE_SINK / BVT_TREASURY).
/// Guardian may stay an EOA for delay-window cancel only — set BVT_GUARDIAN
/// to a multisig for any long-lived/valued deploy.
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

        vm.startBroadcast(deployerKey);

        address guardian = _optionalAddr("BVT_GUARDIAN", deployer);
        BVT bvt = new BVT(deployer);
        BVTTimelock timelock = new BVTTimelock(deployer, guardian);

        address insuranceSink = _optionalAddr("BVT_INSURANCE_SINK", address(timelock));
        address treasury = _optionalAddr("BVT_TREASURY", address(timelock));

        BVTStaking staking = new BVTStaking(bvt, deployer, insuranceSink);
        BVTFeeRouter fees = new BVTFeeRouter(bvt, staking, deployer, insuranceSink, treasury);
        BVTGovernor governor = new BVTGovernor(staking, timelock, deployer);

        wire(bvt, staking, fees, timelock, governor, deployer);
        harden(bvt, staking, fees, timelock, governor, deployer);

        vm.stopBroadcast();

        console.log("chainid", block.chainid);
        console.log("BVT", address(bvt));
        console.log("BVTStaking", address(staking));
        console.log("BVTFeeRouter", address(fees));
        console.log("BVTTimelock", address(timelock));
        console.log("BVTGovernor", address(governor));
        console.log("insuranceSink", insuranceSink);
        console.log("treasury", treasury);
        console.log("guardian", guardian);
        console.log("totalSupply (must be 0)", bvt.totalSupply());
        console.log("Post these addresses in contracts/README.md after deploy. Never commit PRIVATE_KEY.");
        console.log("Hardened: deployer renounced mint/slash/admin. Bootstrap/earn/slash go through the timelock.");
    }

    /// @dev Grant protocol roles. Does not leave BOOTSTRAP/SLASHER on the deployer.
    function wire(
        BVT bvt,
        BVTStaking staking,
        BVTFeeRouter fees,
        BVTTimelock timelock,
        BVTGovernor governor,
        address /* deployer */
    ) public {
        bvt.grantRole(bvt.MINTER_ROLE(), address(staking));
        bvt.grantRole(bvt.MINTER_ROLE(), address(fees));
        bvt.grantRole(bvt.LOCKER_ROLE(), address(staking));

        staking.grantRole(staking.BOOTSTRAP_ROLE(), address(timelock));
        staking.grantRole(staking.SLASHER_ROLE(), address(timelock));
        staking.grantRole(staking.REWARDER_ROLE(), address(fees));
        staking.grantRole(staking.GOVERNANCE_ROLE(), address(timelock));

        fees.grantRole(fees.GOVERNANCE_ROLE(), address(timelock));
        fees.grantRole(fees.EARNER_ROLE(), address(timelock));

        timelock.setGovernor(address(governor));
    }

    /// @dev Caller must be current DEFAULT_ADMIN / timelock admin (the deployer during broadcast).
    function harden(
        BVT bvt,
        BVTStaking staking,
        BVTFeeRouter fees,
        BVTTimelock timelock,
        BVTGovernor governor,
        address deployer
    ) public {
        bytes32 adminRole = bvt.DEFAULT_ADMIN_ROLE();

        bvt.grantRole(adminRole, address(timelock));
        staking.grantRole(adminRole, address(timelock));
        fees.grantRole(adminRole, address(timelock));

        governor.setAdmin(address(timelock));
        timelock.transferAdmin(address(timelock));

        staking.renounceRole(staking.GOVERNANCE_ROLE(), deployer);
        staking.renounceRole(adminRole, deployer);
        fees.renounceRole(fees.EARNER_ROLE(), deployer);
        fees.renounceRole(fees.GOVERNANCE_ROLE(), deployer);
        fees.renounceRole(adminRole, deployer);
        bvt.renounceRole(adminRole, deployer);
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
