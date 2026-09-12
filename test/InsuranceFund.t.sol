// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { Test } from "forge-std/Test.sol";
import { InsuranceFund } from "../contracts/InsuranceFund.sol";
import { Liability } from "../contracts/Liability.sol";

/// @dev Stranger contract used to prove a non-Liability caller cannot payout.
contract PayoutAttacker {
    function tryPayout(InsuranceFund fund, address payable to, uint256 amount, bytes32 claimId) external {
        fund.payout(to, amount, claimId);
    }
}

contract InsuranceFundTest is Test {
    InsuranceFund internal insurance;
    Liability internal liability;
    PayoutAttacker internal attacker;

    function setUp() public {
        liability = new Liability(address(0));
        insurance = new InsuranceFund(address(liability));
        liability.bindInsurance(address(insurance));
        attacker = new PayoutAttacker();
        insurance.fund{value: 5 ether}();
    }

    function test_liabilityIsImmutable() public view {
        assertEq(insurance.liability(), address(liability));
    }

    function test_constructorRejectsZeroLiability() public {
        vm.expectRevert(bytes("zero liability"));
        new InsuranceFund(address(0));
    }

    function test_liabilityCanPayout() public {
        address payable claimant = payable(address(0xBEEF));
        bytes32 claimId = keccak256("ok");
        liability.fileClaim(claimId, keccak256("bot"), keccak256("inc-ok"), claimant, 1 ether, Liability.Party.Insurance);
        liability.settle(claimId);
        assertEq(claimant.balance, 1 ether);
        assertEq(insurance.balance(), 4 ether);
    }

    function test_ownerCannotPayout() public {
        vm.expectRevert(bytes("not liability"));
        insurance.payout(payable(address(this)), 1 ether, bytes32(0));
    }

    function test_otherContractCannotPayout() public {
        vm.expectRevert(bytes("not liability"));
        attacker.tryPayout(insurance, payable(address(attacker)), 1 ether, bytes32(uint256(1)));
    }

    function testFuzz_randomEOACannotPayout(address eve, uint256 amount) public {
        vm.assume(eve != address(liability));
        vm.assume(eve != address(0));
        amount = bound(amount, 1, insurance.balance());
        uint256 beforeBal = insurance.balance();
        vm.prank(eve);
        vm.expectRevert(bytes("not liability"));
        insurance.payout(payable(eve), amount, keccak256(abi.encode(eve, amount)));
        assertEq(insurance.balance(), beforeBal);
    }

    function testFuzz_randomContractCannotPayout(address target) public {
        vm.assume(target != address(liability));
        PayoutAttacker other = new PayoutAttacker();
        vm.expectRevert(bytes("not liability"));
        other.tryPayout(insurance, payable(target == address(0) ? address(other) : target), 1, bytes32(0));
    }
}
