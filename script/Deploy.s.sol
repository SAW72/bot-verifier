// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {Denylist} from "../contracts/Denylist.sol";
import {Vault} from "../contracts/Vault.sol";
import {InsuranceFund} from "../contracts/InsuranceFund.sol";
import {Liability} from "../contracts/Liability.sol";
import {DisputePanel} from "../contracts/DisputePanel.sol";

/// @notice Deploy Denylist → Vault → InsuranceFund → Liability → DisputePanel.
/// Chainid guard: Base Sepolia (84532) only. Mainnet is always refused.
/// ETH Sepolia (11155111) is documented as a one-line switch — do not enable it
/// here unless you intentionally change ALLOWED_CHAIN_ID.
contract Deploy is Script {
    uint256 public constant BASE_SEPOLIA_CHAIN_ID = 84532;
    uint256 public constant ETH_SEPOLIA_CHAIN_ID = 11155111;
    uint256 public constant ETH_MAINNET_CHAIN_ID = 1;
    uint256 public constant ALLOWED_CHAIN_ID = BASE_SEPOLIA_CHAIN_ID;

    function requireAllowedChain() public view {
        if (block.chainid == ETH_MAINNET_CHAIN_ID) {
            revert("Deploy: mainnet forbidden");
        }
        if (block.chainid != ALLOWED_CHAIN_ID) {
            revert("Deploy: Base Sepolia (84532) only; see README to switch to ETH Sepolia (11155111)");
        }
    }

    function run() external {
        requireAllowedChain();

        uint256 deployerKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerKey);

        Denylist denylist = new Denylist();
        Vault vault = new Vault(address(denylist));
        InsuranceFund insurance = new InsuranceFund();
        Liability liability = new Liability(address(insurance));
        DisputePanel panel = new DisputePanel();

        vm.stopBroadcast();

        console.log("chainid", block.chainid);
        console.log("Denylist", address(denylist));
        console.log("Vault", address(vault));
        console.log("InsuranceFund", address(insurance));
        console.log("Liability", address(liability));
        console.log("DisputePanel", address(panel));
        console.log("Post these addresses in contracts/README.md after deploy. Never commit PRIVATE_KEY.");
    }
}
