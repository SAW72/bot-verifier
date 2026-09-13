// SPDX-License-Identifier: MIT
// Tests for BotAttestationEscrow using Foundry (forge test).
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {BotAttestationEscrow} from "../contracts/BotAttestationEscrow.sol";
import {Denylist} from "../contracts/Denylist.sol";
import {Vault} from "../contracts/Vault.sol";

contract EtherSink {
    receive() external payable {}
}

contract ReenteringPayee {
    BotAttestationEscrow public escrow;
    bytes32 public escrowId;
    bool public tried;

    constructor(BotAttestationEscrow _escrow) {
        escrow = _escrow;
    }

    function setEscrowId(bytes32 id) external {
        escrowId = id;
    }

    receive() external payable {
        if (!tried) {
            tried = true;
            // Reenter should fail: state already Released / nonReentrant.
            try escrow.release(escrowId) {} catch {}
            try escrow.refund(escrowId) {} catch {}
        }
    }
}

contract BotAttestationEscrowTest is Test {
    Denylist denylist;
    Vault vault;
    BotAttestationEscrow escrow;

    address payer;
    address payee;

    bytes32 payerBot = keccak256("payer-bot");
    bytes32 payeeBot = keccak256("payee-bot");

    function setUp() public {
        denylist = new Denylist();
        vault = new Vault(address(denylist));
        escrow = new BotAttestationEscrow(address(denylist), address(vault));

        payer = makeAddr("payer");
        payee = makeAddr("payee");

        vault.register(payerBot, keccak256("w1"), keccak256("b1"), keccak256("p1"), Vault.Tier.Financial);
        vault.register(payeeBot, keccak256("w2"), keccak256("b2"), keccak256("p2"), Vault.Tier.Financial);

        vm.deal(payer, 10 ether);
    }

    function _create(bytes32 escrowId, uint256 amount, uint256 duration) internal {
        vm.prank(payer);
        escrow.createEscrow{value: amount}(escrowId, payee, payerBot, payeeBot, duration);
    }

    function test_createAndRelease() public {
        bytes32 escrowId = keccak256("deal-1");
        uint256 amount = 1 ether;

        _create(escrowId, amount, 3600);

        uint256 before = payee.balance;
        vm.prank(payer);
        escrow.release(escrowId);
        assertEq(payee.balance, before + amount);
        (,,,,,,, BotAttestationEscrow.EscrowState state,) = _escrowTuple(escrowId);
        assertEq(uint256(state), uint256(BotAttestationEscrow.EscrowState.Released));
    }

    function test_refundOnExpiry() public {
        bytes32 escrowId = keccak256("deal-2");
        uint256 amount = 1 ether;

        _create(escrowId, amount, 100);

        vm.warp(block.timestamp + 101);

        uint256 before = payer.balance;
        vm.prank(payer);
        escrow.refund(escrowId);
        assertEq(payer.balance, before + amount);
    }

    function test_blocksReleaseWhenDenylistedAfterCreate() public {
        bytes32 escrowId = keccak256("deal-3");
        _create(escrowId, 1 ether, 3600);

        // Denylist after lock — release must still fail closed.
        denylist.addExact(keccak256("w2"));

        vm.prank(payer);
        vm.expectRevert(abi.encodeWithSignature("AttestationFailed(string)", "payee bot denylisted"));
        escrow.release(escrowId);
    }

    function test_createRejectsAlreadyDenylistedPayee() public {
        denylist.addExact(keccak256("w2"));

        bytes32 escrowId = keccak256("deal-3b");
        vm.prank(payer);
        vm.expectRevert(abi.encodeWithSignature("AttestationFailed(string)", "payee bot denylisted"));
        escrow.createEscrow{value: 1 ether}(escrowId, payee, payerBot, payeeBot, 3600);
        assertFalse(escrow.usedEscrowIds(escrowId));
    }

    function test_replayRejected() public {
        bytes32 escrowId = keccak256("deal-4");
        _create(escrowId, 1 ether, 3600);

        vm.prank(payer);
        vm.expectRevert(BotAttestationEscrow.Replay.selector);
        escrow.createEscrow{value: 1 ether}(escrowId, payee, payerBot, payeeBot, 3600);
    }

    function test_replayRejectedAfterRefund() public {
        bytes32 escrowId = keccak256("deal-4b");
        _create(escrowId, 1 ether, 100);
        vm.warp(block.timestamp + 101);
        vm.prank(payer);
        escrow.refund(escrowId);

        vm.prank(payer);
        vm.expectRevert(BotAttestationEscrow.Replay.selector);
        escrow.createEscrow{value: 1 ether}(escrowId, payee, payerBot, payeeBot, 3600);
    }

    function test_blocksReleaseWhenBurned() public {
        bytes32 escrowId = keccak256("deal-burn");
        _create(escrowId, 1 ether, 3600);

        vault.burn(payeeBot);

        vm.prank(payer);
        vm.expectRevert(abi.encodeWithSignature("AttestationFailed(string)", "payee bot inactive"));
        escrow.release(escrowId);
    }

    function test_createRejectsChatTier() public {
        bytes32 chatBot = keccak256("chat-bot");
        vault.register(chatBot, keccak256("w3"), keccak256("b3"), keccak256("p3"), Vault.Tier.Chat);

        bytes32 escrowId = keccak256("deal-tier");
        vm.prank(payer);
        vm.expectRevert(abi.encodeWithSignature("AttestationFailed(string)", "payee bot below Financial tier"));
        escrow.createEscrow{value: 1 ether}(escrowId, payee, payerBot, chatBot, 3600);
    }

    function test_releaseRevertsAfterExpiry() public {
        bytes32 escrowId = keccak256("deal-exp");
        _create(escrowId, 1 ether, 100);
        vm.warp(block.timestamp + 101);

        vm.prank(payer);
        vm.expectRevert(BotAttestationEscrow.EscrowExpired.selector);
        escrow.release(escrowId);
    }

    function test_disputeThenRefund() public {
        bytes32 escrowId = keccak256("deal-disp");
        uint256 amount = 1 ether;
        _create(escrowId, amount, 3600);

        bytes32 disputeId = keccak256("d1");
        vm.prank(payer);
        escrow.dispute(escrowId, disputeId);

        uint256 before = payer.balance;
        vm.prank(payer);
        escrow.refund(escrowId);
        assertEq(payer.balance, before + amount);
    }

    function test_strangerCannotDispute() public {
        bytes32 escrowId = keccak256("deal-stranger");
        _create(escrowId, 1 ether, 3600);
        vm.prank(makeAddr("stranger"));
        vm.expectRevert(bytes("not a party"));
        escrow.dispute(escrowId, keccak256("x"));
    }

    function test_zeroValueRejected() public {
        vm.prank(payer);
        vm.expectRevert(abi.encodeWithSignature("AttestationFailed(string)", "zero amount"));
        escrow.createEscrow{value: 0}(keccak256("zero"), payee, payerBot, payeeBot, 3600);
    }

    function test_selfPayeeRejected() public {
        vm.prank(payer);
        vm.expectRevert(BotAttestationEscrow.InvalidParties.selector);
        escrow.createEscrow{value: 1 ether}(keccak256("self"), payer, payerBot, payeeBot, 3600);
    }

    function test_zeroBotIdRejected() public {
        vm.prank(payer);
        vm.expectRevert(BotAttestationEscrow.InvalidParties.selector);
        escrow.createEscrow{value: 1 ether}(keccak256("zbot"), payee, bytes32(0), payeeBot, 3600);
    }

    function test_signatureDenylistBlocksRelease() public {
        bytes32 escrowId = keccak256("deal-sig");
        _create(escrowId, 1 ether, 3600);
        denylist.addSignature(keccak256("b2"));

        vm.prank(payer);
        vm.expectRevert(abi.encodeWithSignature("AttestationFailed(string)", "payee bot denylisted"));
        escrow.release(escrowId);
    }

    function test_promptDenylistBlocksRelease() public {
        bytes32 escrowId = keccak256("deal-prompt");
        _create(escrowId, 1 ether, 3600);
        denylist.addPrompt(keccak256("p2"));

        vm.prank(payer);
        vm.expectRevert(abi.encodeWithSignature("AttestationFailed(string)", "payee bot denylisted"));
        escrow.release(escrowId);
    }

    function test_releaseToReceivingContract() public {
        EtherSink sink = new EtherSink();
        bytes32 escrowId = keccak256("deal-sink");
        uint256 amount = 1 ether;

        vm.prank(payer);
        escrow.createEscrow{value: amount}(escrowId, address(sink), payerBot, payeeBot, 3600);

        vm.prank(payer);
        escrow.release(escrowId);
        assertEq(address(sink).balance, amount);
    }

    function test_reenteringPayeeCannotDoublePay() public {
        ReenteringPayee evil = new ReenteringPayee(escrow);
        bytes32 escrowId = keccak256("deal-reenter");
        uint256 amount = 1 ether;

        vm.prank(payer);
        escrow.createEscrow{value: amount}(escrowId, address(evil), payerBot, payeeBot, 3600);
        evil.setEscrowId(escrowId);

        vm.prank(payer);
        escrow.release(escrowId);
        assertEq(address(evil).balance, amount);
        assertEq(address(escrow).balance, 0);
    }

    function test_doubleReleaseReverts() public {
        bytes32 escrowId = keccak256("deal-dbl");
        _create(escrowId, 1 ether, 3600);
        vm.prank(payer);
        escrow.release(escrowId);
        vm.prank(payer);
        vm.expectRevert(BotAttestationEscrow.EscrowNotOpen.selector);
        escrow.release(escrowId);
    }

    function test_refundBeforeExpiryWithoutDisputeReverts() public {
        bytes32 escrowId = keccak256("deal-early");
        _create(escrowId, 1 ether, 3600);
        vm.prank(payer);
        vm.expectRevert(bytes("not expired or disputed"));
        escrow.refund(escrowId);
    }

    function _escrowTuple(bytes32 escrowId)
        internal
        view
        returns (
            address,
            address,
            bytes32,
            bytes32,
            uint256,
            uint256,
            uint256,
            BotAttestationEscrow.EscrowState,
            bytes32
        )
    {
        return escrow.escrows(escrowId);
    }
}
