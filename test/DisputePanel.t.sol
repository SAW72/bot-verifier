// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { Test } from "forge-std/Test.sol";
import { DisputePanel } from "../contracts/DisputePanel.sol";

contract DisputePanelTest is Test {
    DisputePanel internal panel;
    address internal arb1 = address(0xA1);
    address internal arb2 = address(0xA2);
    address internal arb3 = address(0xA3);
    address internal stranger = address(0xBEEF);

    function setUp() public {
        panel = new DisputePanel();
        panel.setArbitrator(arb1, true);
        panel.setArbitrator(arb2, true);
        panel.setArbitrator(arb3, true);
    }

    function test_appointedPanelCanResolve() public {
        bytes32 disputeId = keccak256("d1");
        bytes32 subject = keccak256("subject");
        panel.openDispute(disputeId, subject, "false flag");
        vm.prank(arb1);
        panel.vote(disputeId, true);
        vm.prank(arb2);
        panel.vote(disputeId, true);
        vm.prank(arb3);
        panel.vote(disputeId, false);
        (,,,,, bool resolved, bool upheld,) = panel.disputes(disputeId);
        assertTrue(resolved);
        assertTrue(upheld);
        (bool exists, bool outResolved, bool outUpheld, bytes32 outSubject) = panel.outcome(disputeId);
        assertTrue(exists);
        assertTrue(outResolved);
        assertTrue(outUpheld);
        assertEq(outSubject, subject);
    }

    function test_outcomeMissingDispute() public view {
        (bool exists, bool resolved, bool upheld, bytes32 subject) = panel.outcome(keccak256("none"));
        assertFalse(exists);
        assertFalse(resolved);
        assertFalse(upheld);
        assertEq(subject, bytes32(0));
    }

    function test_randomAddressCannotVote() public {
        bytes32 disputeId = keccak256("d-unauth");
        panel.openDispute(disputeId, keccak256("subject"), "nope");
        vm.prank(stranger);
        vm.expectRevert(bytes("not authorized"));
        panel.vote(disputeId, true);
        assertFalse(panel.voted(disputeId, stranger));
    }

    function testFuzz_unappointedCannotVote(address eve) public {
        vm.assume(eve != arb1 && eve != arb2 && eve != arb3);
        vm.assume(eve != address(0));
        bytes32 disputeId = keccak256(abi.encode("d", eve));
        panel.openDispute(disputeId, keccak256("subject"), "fuzz");
        vm.prank(eve);
        vm.expectRevert(bytes("not authorized"));
        panel.vote(disputeId, true);
    }

    function test_revokedArbitratorCannotVote() public {
        bytes32 disputeId = keccak256("d-revoked");
        panel.openDispute(disputeId, keccak256("subject"), "revoked");
        panel.setArbitrator(arb1, false);
        vm.prank(arb1);
        vm.expectRevert(bytes("not authorized"));
        panel.vote(disputeId, true);
    }

    function test_openDisputeRevertsUntilPanelSeated() public {
        DisputePanel fresh = new DisputePanel();
        vm.expectRevert(bytes("panel not seated"));
        fresh.openDispute(keccak256("empty"), keccak256("subject"), "too soon");

        fresh.setArbitrator(arb1, true);
        fresh.setArbitrator(arb2, true);
        assertEq(fresh.arbitratorCount(), 2);
        vm.expectRevert(bytes("panel not seated"));
        fresh.openDispute(keccak256("two"), keccak256("subject"), "still short");

        fresh.setArbitrator(arb3, true);
        assertEq(fresh.arbitratorCount(), 3);
        fresh.openDispute(keccak256("three"), keccak256("subject"), "seated");
        (bool exists,,,) = fresh.outcome(keccak256("three"));
        assertTrue(exists);

        fresh.setArbitrator(arb3, false);
        assertLt(fresh.arbitratorCount(), fresh.PANEL_SIZE());
        vm.expectRevert(bytes("panel not seated"));
        fresh.openDispute(keccak256("revoked"), keccak256("subject"), "dropped below 3");
    }

    function test_strangerCannotAppoint() public {
        vm.prank(stranger);
        vm.expectRevert(bytes("not owner"));
        panel.setArbitrator(stranger, true);
    }
}
