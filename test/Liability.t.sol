// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { Test } from "forge-std/Test.sol";
import { InsuranceFund } from "../contracts/InsuranceFund.sol";
import { Liability } from "../contracts/Liability.sol";

contract LiabilityTest is Test {
    Liability internal liability;
    InsuranceFund internal insurance;

    bytes32 internal constant BOT = keccak256("bot");
    address payable internal claimant = payable(address(0xBEEF));

    function setUp() public {
        liability = new Liability(address(0));
        insurance = new InsuranceFund(address(liability));
    }

    function test_constructorLeavesInsuranceUnbound() public view {
        assertEq(liability.owner(), address(this));
        assertEq(address(liability.insurance()), address(0));
    }

    function test_constructorBindsNonZeroInsurance() public {
        Liability bound = new Liability(address(insurance));
        assertEq(address(bound.insurance()), address(insurance));
        assertEq(bound.owner(), address(this));
        vm.expectRevert(bytes("insurance already bound"));
        bound.bindInsurance(address(0x1234));
    }

    function test_bindInsuranceFailClosed() public {
        vm.expectRevert(bytes("zero insurance"));
        liability.bindInsurance(address(0));
        assertEq(address(liability.insurance()), address(0));

        vm.prank(address(0xBAD));
        vm.expectRevert(bytes("not owner"));
        liability.bindInsurance(address(insurance));

        liability.bindInsurance(address(insurance));
        assertEq(address(liability.insurance()), address(insurance));

        vm.expectRevert(bytes("insurance already bound"));
        liability.bindInsurance(address(0x1234));
        assertEq(address(liability.insurance()), address(insurance));
    }

    function test_settleInsuranceRevertsUntilBound() public {
        bytes32 claimId = keccak256("unbound");
        liability.fileClaim(claimId, BOT, keccak256("inc-unbound"), claimant, 1, Liability.Party.Insurance);
        vm.expectRevert(bytes("insurance unset"));
        liability.settle(claimId);
        (,,,,, bool paid,) = liability.claims(claimId);
        assertFalse(paid);
    }

    function test_bindThenInsuranceSettlePaysClaimant() public {
        liability.bindInsurance(address(insurance));
        insurance.fund{ value: 1 ether }();

        bytes32 claimId = keccak256("paid");
        liability.fileClaim(claimId, BOT, keccak256("inc-paid"), claimant, 0.4 ether, Liability.Party.Insurance);
        liability.settle(claimId);

        (,,,,, bool paid,) = liability.claims(claimId);
        assertTrue(paid);
        assertEq(claimant.balance, 0.4 ether);
        assertEq(insurance.balance(), 0.6 ether);
    }

    function test_setOwnerHandoff() public {
        address timelock = address(0x71C0);
        vm.expectRevert(bytes("owner zero"));
        liability.setOwner(address(0));

        vm.prank(address(0xBAD));
        vm.expectRevert(bytes("not owner"));
        liability.setOwner(timelock);

        liability.setOwner(timelock);
        assertEq(liability.owner(), timelock);

        vm.expectRevert(bytes("not owner"));
        liability.fileClaim(keccak256("old"), BOT, keccak256("inc-old"), claimant, 1, Liability.Party.Owner);
        vm.expectRevert(bytes("not owner"));
        liability.bindInsurance(address(insurance));

        vm.prank(timelock);
        liability.bindInsurance(address(insurance));
        assertEq(address(liability.insurance()), address(insurance));

        vm.prank(timelock);
        liability.fileClaim(keccak256("new"), BOT, keccak256("inc-new"), claimant, 1, Liability.Party.Owner);
        (,,, uint256 amount,,,) = liability.claims(keccak256("new"));
        assertEq(amount, 1);
    }

    function test_fileClaimRejectsOverwrite() public {
        bytes32 claimId = keccak256("once");
        liability.fileClaim(claimId, BOT, keccak256("inc-a"), claimant, 1 ether, Liability.Party.Owner);

        vm.expectRevert(bytes("claim exists"));
        liability.fileClaim(claimId, BOT, keccak256("inc-b"), payable(address(0xCAFE)), 9 ether, Liability.Party.Insurance);

        (bytes32 botId, bytes32 incident,, uint256 amount, Liability.Party liable, bool paid,) =
            liability.claims(claimId);
        assertEq(botId, BOT);
        assertEq(incident, keccak256("inc-a"));
        assertEq(amount, 1 ether);
        assertEq(uint256(liable), uint256(Liability.Party.Owner));
        assertFalse(paid);
        assertFalse(liability.incidentKnown(keccak256("inc-b")));
    }

    function test_fileClaimRejectsTimestampZero() public {
        vm.warp(0);
        vm.expectRevert(bytes("timestamp unset"));
        liability.fileClaim(keccak256("ts0"), BOT, keccak256("inc-ts0"), claimant, 1, Liability.Party.Owner);
        (,,,,,, uint256 createdAt) = liability.claims(keccak256("ts0"));
        assertEq(createdAt, 0);
    }

    function test_ownerSettlePaysFromBalance() public {
        liability.fileClaim(keccak256("owner"), BOT, keccak256("inc-owner"), claimant, 0.2 ether, Liability.Party.Owner);
        vm.deal(address(liability), 0.2 ether);
        liability.settle(keccak256("owner"));
        assertEq(claimant.balance, 0.2 ether);
        (,,,,, bool paid,) = liability.claims(keccak256("owner"));
        assertTrue(paid);
    }

    function test_auditorSettleStaysFailClosed() public {
        bytes32 claimId = keccak256("auditor");
        liability.fileClaim(claimId, BOT, keccak256("inc-aud"), claimant, 1, Liability.Party.Auditor);
        vm.expectRevert(bytes("Liability: auditor slash/escrow unset"));
        liability.settle(claimId);
        (,,,,, bool paid,) = liability.claims(claimId);
        assertFalse(paid);
    }

    function test_unknownPartyReverts() public {
        bytes32 claimId = keccak256("none");
        liability.fileClaim(claimId, BOT, keccak256("inc-none"), claimant, 1, Liability.Party.None);
        vm.expectRevert(bytes("unknown liable party"));
        liability.settle(claimId);
    }

    function test_incidentCannotBeClaimedTwice() public {
        liability.fileClaim(keccak256("c1"), BOT, keccak256("same"), claimant, 1, Liability.Party.Owner);
        vm.expectRevert(bytes("incident already claimed"));
        liability.fileClaim(keccak256("c2"), BOT, keccak256("same"), claimant, 1, Liability.Party.Owner);
    }
}
