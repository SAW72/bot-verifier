// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../contracts/Denylist.sol";

contract DenylistTest is Test {
    Denylist d;

    function setUp() public {
        d = new Denylist();
    }

    function testAddExactAndCheck() public {
        bytes32 h = keccak256("weights");
        d.addExact(h);
        Denylist.MatchLevel level = d.check(h, bytes32(0), bytes32(0));
        assertEq(uint256(level), uint256(Denylist.MatchLevel.ExactBlock));
    }

    function testRemoveReverts() public {
        vm.expectRevert(bytes("denylist is irreversible"));
        d.remove(bytes32(0));
    }
}
