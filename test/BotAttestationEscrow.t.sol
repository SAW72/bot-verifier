// SPDX-License-Identifier: MIT
// Tests for BotAttestationEscrow using Foundry (forge test).
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {BotAttestationEscrow} from "../contracts/BotAttestationEscrow.sol";
import {Denylist} from "../contracts/Denylist.sol";
import {Vault} from "../contracts/Vault.sol";

contract BotAttestationEscrowTest is Test {
    Denylist denylist;
    Vault vault;
    BotAttestationEscrow escrow;

    address owner = address(this);
    address payer = address(0x1);
    address payee = address(0x2);

    bytes32 payerBot = keccak256("payer-bot");
    bytes32 payeeBot = keccak256("payee-bot");

    function setUp() public {
        denylist = new Denylist();
        vault = new Vault(address(denylist));
        escrow = new BotAttestationEscrow(address(denylist), address(vault));

        // Register both bots at Financial tier (enum value 3).
        vault.register(payerBot, keccak256("w1"), keccak256("b1"), keccak256("p1"), Vault.Tier.Financial);
        vault.register(payeeBot, keccak256("w2"), keccak256("b2"), keccak256("p2"), Vault.Tier.Financial);

        vm.deal(payer, 10 ether);
    }

    function test_createAndRelease() public {
        bytes32 escrowId = keccak256("deal-1");
        uint256 amount = 1 ether;

        vm.prank(payer);
        escrow.createEscrow{value: amount}(escrowId, payee, payerBot, payeeBot, 3600);

        uint256 before = payee.balance;
        vm.prank(payer);
        escrow.release(escrowId);
        assertEq(payee.balance, before + amount);
    }

    function test_refundOnExpiry() public {
        bytes32 escrowId = keccak256("deal-2");
        uint256 amount = 1 ether;

        vm.prank(payer);
        escrow.createEscrow{value: amount}(escrowId, payee, payerBot, payeeBot, 100);

        vm.warp(block.timestamp + 101);

        uint256 before = payer.balance;
        vm.prank(payer);
        escrow.refund(escrowId);
        assertEq(payer.balance, before + amount);
    }

    function test_blocksReleaseWhenDenylisted() public {
        denylist.addExact(keccak256("w2"));

        bytes32 escrowId = keccak256("deal-3");
        vm.prank(payer);
        escrow.createEscrow{value: 1 ether}(escrowId, payee, payerBot, payeeBot, 3600);

        vm.prank(payer);
        vm.expectRevert(abi.encodeWithSignature("AttestationFailed(string)", "payee bot denylisted"));
        escrow.release(escrowId);
    }

    function test_replayRejected() public {
        bytes32 escrowId = keccak256("deal-4");
        vm.prank(payer);
        escrow.createEscrow{value: 1 ether}(escrowId, payee, payerBot, payeeBot, 3600);

        vm.prank(payer);
        vm.expectRevert(BotAttestationEscrow.Replay.selector);
        escrow.createEscrow{value: 1 ether}(escrowId, payee, payerBot, payeeBot, 3600);
    }
}
