// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { Test } from "forge-std/Test.sol";
import { DisputePanel } from "../contracts/DisputePanel.sol";
import { BVT } from "../contracts/bvt/BVT.sol";
import { BVTStaking } from "../contracts/bvt/BVTStaking.sol";

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
        panel.openDispute(disputeId, keccak256("subject"), "false flag");
        vm.prank(arb1);
        panel.vote(disputeId, true);
        vm.prank(arb2);
        panel.vote(disputeId, true);
        vm.prank(arb3);
        panel.vote(disputeId, false);
        (,,,,, bool resolved, bool upheld,) = panel.disputes(disputeId);
        assertTrue(resolved);
        assertTrue(upheld);
    }

    function test_randomAddressCannotVote() public {
        bytes32 disputeId = keccak256("d-unauth");
        panel.openDispute(disputeId, keccak256("subject"), "nope");
        vm.prank(stranger);
        vm.expectRevert(bytes("not authorized"));
        panel.vote(disputeId, true);
        assertFalse(panel.voted(disputeId, stranger));
    }

    function testFuzz_unappointedUnstakedCannotVote(address eve) public {
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

    function test_strangerCannotAppoint() public {
        vm.prank(stranger);
        vm.expectRevert(bytes("not owner"));
        panel.setArbitrator(stranger, true);
    }

    function test_activeStakedAuditorCanVote() public {
        BVT bvt = new BVT(address(this));
        BVTStaking staking = new BVTStaking(bvt, address(this), address(this));
        bvt.grantRole(bvt.MINTER_ROLE(), address(staking));
        bvt.grantRole(bvt.LOCKER_ROLE(), address(staking));
        staking.grantRole(staking.BOOTSTRAP_ROLE(), address(this));
        address auditor = address(0xA0D1);
        staking.bootstrapOperator(auditor, 10_000 ether);
        panel.setStakes(address(staking));

        bytes32 disputeId = keccak256("d-stake");
        panel.openDispute(disputeId, keccak256("subject"), "staked");
        vm.prank(auditor);
        panel.vote(disputeId, true);
        assertTrue(panel.voted(disputeId, auditor));
    }

    function test_unstakedCannotVoteEvenWithStakesWired() public {
        BVT bvt = new BVT(address(this));
        BVTStaking staking = new BVTStaking(bvt, address(this), address(this));
        panel.setStakes(address(staking));
        bytes32 disputeId = keccak256("d-no-stake");
        panel.openDispute(disputeId, keccak256("subject"), "unstaked");
        vm.prank(stranger);
        vm.expectRevert(bytes("not authorized"));
        panel.vote(disputeId, true);
    }
}
