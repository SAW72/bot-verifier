// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {Denylist} from "../contracts/Denylist.sol";
import {Vault} from "../contracts/Vault.sol";
import {InsuranceFund} from "../contracts/InsuranceFund.sol";
import {Liability} from "../contracts/Liability.sol";
import {DisputePanel} from "../contracts/DisputePanel.sol";
import {Deploy} from "../script/Deploy.s.sol";

contract SmokeTest is Test {
    Denylist internal denylist;
    Vault internal vault;
    InsuranceFund internal insurance;
    Liability internal liability;
    DisputePanel internal panel;

    function setUp() public {
        denylist = new Denylist();
        vault = new Vault(address(denylist));
        insurance = new InsuranceFund();
        liability = new Liability(address(insurance));
        panel = new DisputePanel();
    }

    function test_deployOrderWiresDependencies() public view {
        assertEq(denylist.owner(), address(this));
        assertEq(address(vault.denylist()), address(denylist));
        assertEq(address(liability.insurance()), address(insurance));
        assertEq(insurance.owner(), address(this));
        assertEq(panel.owner(), address(this));
    }

    function test_denylistAddAndCheck() public {
        bytes32 weight = keccak256("weight");
        bytes32 sig = keccak256("sig");
        bytes32 prompt = keccak256("prompt");
        denylist.addExact(weight);
        assertTrue(denylist.denylistedHashes(weight));
        Denylist.MatchLevel level = denylist.check(weight, sig, prompt);
        assertEq(uint256(level), uint256(Denylist.MatchLevel.ExactBlock));
    }

    function test_denylistRemoveAlwaysReverts() public {
        vm.expectRevert(bytes("denylist is irreversible"));
        denylist.remove(bytes32(uint256(1)));
    }

    function testFuzz_addExactIrreversible(bytes32 h) public {
        denylist.addExact(h);
        assertTrue(denylist.denylistedHashes(h));
        vm.expectRevert(bytes("already denylisted"));
        denylist.addExact(h);
    }

    function test_vaultRegisterGrantAndBurn() public {
        bytes32 botId = keccak256("bot");
        vault.register(botId, keccak256("w"), keccak256("s"), keccak256("p"), Vault.Tier.Chat);
        (,,,, bool active,) = vault.bots(botId);
        assertTrue(active);
        assertTrue(vault.grantAccess(botId, 1));
        vault.burn(botId);
        (,,,, active,) = vault.bots(botId);
        assertFalse(active);
    }

    function test_vaultRejectsDenylisted() public {
        bytes32 weight = keccak256("bad");
        denylist.addExact(weight);
        vm.expectRevert(bytes("bot is denylisted"));
        vault.register(keccak256("bot"), weight, keccak256("s"), keccak256("p"), Vault.Tier.Chat);
    }

    function test_insuranceFundAndLiabilityClaim() public {
        insurance.fund{value: 1 ether}();
        assertEq(insurance.balance(), 1 ether);

        bytes32 claimId = keccak256("claim");
        bytes32 incident = keccak256("incident");
        address payable claimant = payable(address(0xBEEF));
        liability.fileClaim(claimId, keccak256("bot"), incident, claimant, 0.25 ether, Liability.Party.Insurance);
        liability.settle(claimId);
        (,,,,, bool paid,) = liability.claims(claimId);
        assertTrue(paid);
        assertEq(claimant.balance, 0.25 ether);
        assertEq(insurance.balance(), 0.75 ether);
    }

    function test_noDoubleClaimOnIncident() public {
        liability.fileClaim(
            keccak256("c1"),
            keccak256("bot"),
            keccak256("inc"),
            payable(address(this)),
            1,
            Liability.Party.Owner
        );
        vm.expectRevert(bytes("incident already claimed"));
        liability.fileClaim(
            keccak256("c2"),
            keccak256("bot"),
            keccak256("inc"),
            payable(address(this)),
            1,
            Liability.Party.Owner
        );
    }

    function test_disputeResolvesAfterThreeVotes() public {
        bytes32 disputeId = keccak256("d1");
        panel.openDispute(disputeId, keccak256("subject"), "false flag");
        panel.vote(disputeId, true);
        vm.prank(address(0x1));
        panel.vote(disputeId, true);
        vm.prank(address(0x2));
        panel.vote(disputeId, false);
        (,,,,, bool resolved, bool upheld,) = panel.disputes(disputeId);
        assertTrue(resolved);
        assertTrue(upheld);
    }
}

contract DeployGuardTest is Test {
    Deploy internal deploy;

    function setUp() public {
        deploy = new Deploy();
    }

    function test_allowsBaseSepolia() public {
        vm.chainId(84532);
        deploy.requireAllowedChain();
    }

    function test_refusesMainnet() public {
        vm.chainId(1);
        vm.expectRevert(bytes("Deploy: mainnet forbidden"));
        deploy.requireAllowedChain();
    }

    function test_refusesEthSepoliaByDefault() public {
        vm.chainId(11155111);
        vm.expectRevert(bytes("Deploy: Base Sepolia (84532) only; see README to switch to ETH Sepolia (11155111)"));
        deploy.requireAllowedChain();
    }

    function test_refusesAnvil() public {
        vm.chainId(31337);
        vm.expectRevert(bytes("Deploy: Base Sepolia (84532) only; see README to switch to ETH Sepolia (11155111)"));
        deploy.requireAllowedChain();
    }

    function test_constantsDocumentEthSepolia() public view {
        assertEq(deploy.ETH_SEPOLIA_CHAIN_ID(), 11155111);
        assertEq(deploy.ALLOWED_CHAIN_ID(), 84532);
    }
}
