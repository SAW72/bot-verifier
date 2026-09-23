// SPDX-License-Identifier: MIT
// Tests for BotAttestationEscrow using Foundry (forge test).
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {BotAttestationEscrow} from "../contracts/BotAttestationEscrow.sol";
import {Denylist} from "../contracts/Denylist.sol";
import {Vault} from "../contracts/Vault.sol";
import {DisputePanel} from "../contracts/DisputePanel.sol";
import {DeployBotAttestationEscrow} from "../script/DeployBotAttestationEscrow.s.sol";

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
    DisputePanel panel;
    BotAttestationEscrow escrow;

    address payer;
    address payee;
    address arb1;
    address arb2;
    address arb3;

    bytes32 payerBot = keccak256("payer-bot");
    bytes32 payeeBot = keccak256("payee-bot");

    function setUp() public {
        denylist = new Denylist();
        vault = new Vault(address(denylist));
        panel = new DisputePanel();
        escrow = new BotAttestationEscrow(address(denylist), address(vault), address(panel));

        payer = makeAddr("payer");
        payee = makeAddr("payee");
        arb1 = makeAddr("arb1");
        arb2 = makeAddr("arb2");
        arb3 = makeAddr("arb3");
        panel.setArbitrator(arb1, true);
        panel.setArbitrator(arb2, true);
        panel.setArbitrator(arb3, true);

        vault.register(payerBot, keccak256("w1"), keccak256("b1"), keccak256("p1"), Vault.Tier.Financial, payer);
        vault.register(payeeBot, keccak256("w2"), keccak256("b2"), keccak256("p2"), Vault.Tier.Financial, payee);

        vm.deal(payer, 10 ether);
    }

    function _create(bytes32 escrowId, uint256 amount, uint256 duration) internal {
        vm.prank(payer);
        escrow.createEscrow{value: amount}(escrowId, payee, payerBot, payeeBot, duration);
    }

    function _openPanel(bytes32 escrowId, bytes32 disputeId) internal {
        panel.openDispute(disputeId, escrowId, "attestation stale");
    }

    function _panelRule(bytes32 disputeId, bool uphold) internal {
        // upheld == votesFor >= votesAgainst. support=true counts as votesFor.
        vm.prank(arb1);
        panel.vote(disputeId, uphold);
        vm.prank(arb2);
        panel.vote(disputeId, uphold);
        vm.prank(arb3);
        panel.vote(disputeId, false);
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
        vault.register(chatBot, keccak256("w3"), keccak256("b3"), keccak256("p3"), Vault.Tier.Chat, payee);

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

    function test_disputeDoesNotAllowInstantRefund() public {
        bytes32 escrowId = keccak256("deal-disp-pending");
        uint256 amount = 1 ether;
        _create(escrowId, amount, 3600);

        bytes32 disputeId = keccak256("d-pending");
        _openPanel(escrowId, disputeId);
        vm.prank(payer);
        escrow.dispute(escrowId, disputeId);

        vm.prank(payer);
        vm.expectRevert(BotAttestationEscrow.DisputePending.selector);
        escrow.refund(escrowId);
        assertEq(address(escrow).balance, amount);
    }

    function test_refundAfterPanelUnwind() public {
        bytes32 escrowId = keccak256("deal-disp-unwind");
        uint256 amount = 1 ether;
        _create(escrowId, amount, 3600);

        bytes32 disputeId = keccak256("d-unwind");
        _openPanel(escrowId, disputeId);
        vm.prank(payer);
        escrow.dispute(escrowId, disputeId);
        _panelRule(disputeId, false); // do not uphold — unwind

        uint256 before = payer.balance;
        vm.prank(payer);
        escrow.refund(escrowId);
        assertEq(payer.balance, before + amount);
    }

    function test_refundAfterDisputeOnExpiryTimelock() public {
        bytes32 escrowId = keccak256("deal-disp-tl");
        uint256 amount = 1 ether;
        _create(escrowId, amount, 100);

        bytes32 disputeId = keccak256("d-tl");
        _openPanel(escrowId, disputeId);
        vm.prank(payer);
        escrow.dispute(escrowId, disputeId);

        vm.warp(block.timestamp + 101);
        uint256 before = payer.balance;
        vm.prank(payer);
        escrow.refund(escrowId);
        assertEq(payer.balance, before + amount);
    }

    /// @notice H-1: upheld + past expiresAt pays the payee. Expiry must not refund the payer.
    function test_upheldPastExpiryRefundRevertsReleaseSucceeds() public {
        bytes32 escrowId = keccak256("deal-uphold-expired");
        uint256 amount = 1 ether;
        _create(escrowId, amount, 100);

        bytes32 disputeId = keccak256("d-uphold-expired");
        _openPanel(escrowId, disputeId);
        vm.prank(payee);
        escrow.dispute(escrowId, disputeId);
        _panelRule(disputeId, true);

        vm.warp(block.timestamp + 101);

        uint256 payerBefore = payer.balance;
        vm.prank(payer);
        vm.expectRevert(BotAttestationEscrow.DisputePending.selector);
        escrow.refund(escrowId);
        assertEq(payer.balance, payerBefore);
        assertEq(address(escrow).balance, amount);

        uint256 payeeBefore = payee.balance;
        vm.prank(payee);
        escrow.release(escrowId);
        assertEq(payee.balance, payeeBefore + amount);
        assertEq(address(escrow).balance, 0);
        (,,,,,,, BotAttestationEscrow.EscrowState state,) = _escrowTuple(escrowId);
        assertEq(uint256(state), uint256(BotAttestationEscrow.EscrowState.Released));
    }

    /// @notice Unwind after expiry still refunds. Panel gating for a non-upheld ruling stays.
    function test_unwindPastExpiryStillRefunds() public {
        bytes32 escrowId = keccak256("deal-unwind-expired");
        uint256 amount = 1 ether;
        _create(escrowId, amount, 100);

        bytes32 disputeId = keccak256("d-unwind-expired");
        _openPanel(escrowId, disputeId);
        vm.prank(payer);
        escrow.dispute(escrowId, disputeId);
        _panelRule(disputeId, false);

        vm.warp(block.timestamp + 101);

        vm.prank(payee);
        vm.expectRevert(BotAttestationEscrow.DisputePending.selector);
        escrow.release(escrowId);

        uint256 before = payer.balance;
        vm.prank(payer);
        escrow.refund(escrowId);
        assertEq(payer.balance, before + amount);
        assertEq(address(escrow).balance, 0);
    }

    function test_panelUpholdBlocksRefundAllowsRelease() public {
        bytes32 escrowId = keccak256("deal-disp-uphold");
        uint256 amount = 1 ether;
        _create(escrowId, amount, 3600);

        bytes32 disputeId = keccak256("d-uphold");
        _openPanel(escrowId, disputeId);
        vm.prank(payee);
        escrow.dispute(escrowId, disputeId);
        _panelRule(disputeId, true); // original deal stands

        vm.prank(payer);
        vm.expectRevert(BotAttestationEscrow.DisputePending.selector);
        escrow.refund(escrowId);

        uint256 before = payee.balance;
        vm.prank(payer);
        escrow.release(escrowId);
        assertEq(payee.balance, before + amount);
    }

    function test_disputeRequiresPanelCaseForThisEscrow() public {
        bytes32 escrowId = keccak256("deal-bad-id");
        _create(escrowId, 1 ether, 3600);

        vm.prank(payer);
        vm.expectRevert(BotAttestationEscrow.InvalidDispute.selector);
        escrow.dispute(escrowId, keccak256("never-opened"));

        bytes32 other = keccak256("other-escrow");
        bytes32 disputeId = keccak256("d-wrong-subject");
        panel.openDispute(disputeId, other, "wrong subject");
        vm.prank(payer);
        vm.expectRevert(BotAttestationEscrow.InvalidDispute.selector);
        escrow.dispute(escrowId, disputeId);
    }

    function test_unboundEoaCannotCreateUnderForeignBotId() public {
        address eve = makeAddr("eve");
        vm.deal(eve, 1 ether);
        vm.prank(eve);
        vm.expectRevert(BotAttestationEscrow.InvalidParties.selector);
        escrow.createEscrow{value: 1 ether}(keccak256("steal"), payee, payerBot, payeeBot, 3600);
    }

    function test_unboundPayeeRejected() public {
        address evePayee = makeAddr("evePayee");
        vm.prank(payer);
        vm.expectRevert(BotAttestationEscrow.InvalidParties.selector);
        escrow.createEscrow{value: 1 ether}(keccak256("bad-payee"), evePayee, payerBot, payeeBot, 3600);
    }

    function test_createRejectsUnboundBot() public {
        bytes32 unbound = keccak256("no-operator");
        vault.register(unbound, keccak256("w4"), keccak256("b4"), keccak256("p4"), Vault.Tier.Financial);
        assertEq(vault.operator(unbound), address(0));

        vm.prank(payer);
        vm.expectRevert(BotAttestationEscrow.InvalidParties.selector);
        escrow.createEscrow{value: 1 ether}(keccak256("unbound"), payee, payerBot, unbound, 3600);
    }

    function test_releaseRevertsIfOperatorRotated() public {
        bytes32 escrowId = keccak256("deal-rotate");
        _create(escrowId, 1 ether, 3600);
        vault.setOperator(payeeBot, makeAddr("new-payee"));

        vm.prank(payer);
        vm.expectRevert(BotAttestationEscrow.InvalidParties.selector);
        escrow.release(escrowId);
    }

    function test_strangerCannotDispute() public {
        bytes32 escrowId = keccak256("deal-stranger");
        _create(escrowId, 1 ether, 3600);
        bytes32 disputeId = keccak256("x");
        _openPanel(escrowId, disputeId);
        vm.prank(makeAddr("stranger"));
        vm.expectRevert(bytes("not a party"));
        escrow.dispute(escrowId, disputeId);
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
        vault.setOperator(payeeBot, address(sink));
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
        vault.setOperator(payeeBot, address(evil));
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
        vm.expectRevert(bytes("not expired"));
        escrow.refund(escrowId);
    }

    function test_constructorRejectsZeroPanel() public {
        vm.expectRevert(BotAttestationEscrow.ZeroAddress.selector);
        new BotAttestationEscrow(address(denylist), address(vault), address(0));
    }

    function test_constructorRejectsZeroVault() public {
        vm.expectRevert(BotAttestationEscrow.ZeroAddress.selector);
        new BotAttestationEscrow(address(denylist), address(0), address(panel));
    }

    function test_ownerCanRepointDeps() public {
        Denylist d2 = new Denylist();
        Vault v2 = new Vault(address(d2));
        DisputePanel p2 = new DisputePanel();
        escrow.setDenylist(address(d2));
        escrow.setVault(address(v2));
        escrow.setDisputePanel(address(p2));
        assertEq(address(escrow.denylist()), address(d2));
        assertEq(address(escrow.vault()), address(v2));
        assertEq(address(escrow.disputePanel()), address(p2));
    }

    function test_strangerCannotRepointDeps() public {
        vm.prank(makeAddr("eve"));
        vm.expectRevert();
        escrow.setDenylist(address(denylist));
    }

    function test_vaultOperatorBindAndRotate() public {
        bytes32 botId = keccak256("op-bot");
        vault.register(botId, keccak256("w5"), keccak256("b5"), keccak256("p5"), Vault.Tier.Financial);
        assertEq(vault.operator(botId), address(0));
        vault.setOperator(botId, payer);
        assertEq(vault.operator(botId), payer);
        vault.setOperator(botId, payee);
        assertEq(vault.operator(botId), payee);
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

contract DeployEscrowGuardTest is Test {
    DeployBotAttestationEscrow internal deploy;

    function setUp() public {
        deploy = new DeployBotAttestationEscrow();
    }

    function test_allowsBaseSepolia() public {
        vm.chainId(84532);
        deploy.requireAllowedChain();
    }

    function test_refusesMainnet() public {
        vm.chainId(1);
        vm.expectRevert(bytes("DeployEscrow: mainnet forbidden"));
        deploy.requireAllowedChain();
    }

    function test_refusesEthSepoliaByDefault() public {
        vm.chainId(11155111);
        vm.expectRevert(bytes("DeployEscrow: Base Sepolia (84532) only; see README to switch to ETH Sepolia (11155111)"));
        deploy.requireAllowedChain();
    }

    function test_refusesAnvil() public {
        vm.chainId(31337);
        vm.expectRevert(bytes("DeployEscrow: Base Sepolia (84532) only; see README to switch to ETH Sepolia (11155111)"));
        deploy.requireAllowedChain();
    }

    function test_constantsDocumentEthSepolia() public view {
        assertEq(deploy.ETH_SEPOLIA_CHAIN_ID(), 11155111);
        assertEq(deploy.ALLOWED_CHAIN_ID(), 84532);
        assertEq(deploy.ETH_MAINNET_CHAIN_ID(), 1);
    }

    function test_timelockMustBeSetAndNotDeployer() public {
        address deployer = address(this);
        vm.expectRevert(bytes("DeployEscrow: CORE_TIMELOCK unset"));
        deploy.requireTimelock(deployer, address(0));
        vm.expectRevert(bytes("DeployEscrow: CORE_TIMELOCK must not be deployer"));
        deploy.requireTimelock(deployer, deployer);
        deploy.requireTimelock(deployer, address(0x71C0));
    }

    function test_depsMustBeSet() public {
        address ok = address(0xBEEF);
        vm.expectRevert(bytes("DeployEscrow: DENYLIST unset"));
        deploy.requireDeps(address(0), ok, ok);
        vm.expectRevert(bytes("DeployEscrow: VAULT unset"));
        deploy.requireDeps(ok, address(0), ok);
        vm.expectRevert(bytes("DeployEscrow: DISPUTE_PANEL unset"));
        deploy.requireDeps(ok, ok, address(0));
        deploy.requireDeps(ok, ok, ok);
    }

    function test_readAddressUnsetReverts() public {
        vm.expectRevert(bytes("DeployEscrow: DENYLIST unset"));
        deploy.readAddress("DENYLIST", "DeployEscrow: DENYLIST unset");
    }

    function test_readAddressZeroReverts() public {
        vm.setEnv("DENYLIST", vm.toString(address(0)));
        vm.expectRevert(bytes("DeployEscrow: DENYLIST unset"));
        deploy.readAddress("DENYLIST", "DeployEscrow: DENYLIST unset");
    }

    function test_deployWiresDepsAndHandsOffToTimelock() public {
        Denylist denylist = new Denylist();
        Vault vault = new Vault(address(denylist));
        DisputePanel panel = new DisputePanel();
        address timelock = address(0x71C0);

        BotAttestationEscrow escrow = deploy.deploy(address(denylist), address(vault), address(panel), timelock);
        assertEq(address(escrow.denylist()), address(denylist));
        assertEq(address(escrow.vault()), address(vault));
        assertEq(address(escrow.disputePanel()), address(panel));
        assertEq(escrow.owner(), address(deploy));
        assertEq(escrow.pendingOwner(), timelock);

        vm.prank(timelock);
        escrow.acceptOwnership();
        assertEq(escrow.owner(), timelock);
        assertEq(escrow.pendingOwner(), address(0));
    }
}
