// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { Test } from "forge-std/Test.sol";
import { BVT } from "../contracts/bvt/BVT.sol";
import { BVTStaking } from "../contracts/bvt/BVTStaking.sol";
import { BVTFeeRouter } from "../contracts/bvt/BVTFeeRouter.sol";
import { BVTTimelock } from "../contracts/bvt/BVTTimelock.sol";
import { BVTGovernor } from "../contracts/bvt/BVTGovernor.sol";
import { FeeKind, SlashReason } from "../contracts/bvt/IBVTHooks.sol";
import { DeployBVT } from "../script/DeployBVT.s.sol";
import { Denylist } from "../contracts/Denylist.sol";
import { Vault } from "../contracts/Vault.sol";

contract BVTTest is Test {
    BVT internal bvt;
    BVTStaking internal staking;
    BVTFeeRouter internal fees;
    BVTTimelock internal timelock;
    BVTGovernor internal governor;

    address internal insurance = address(0x1111);
    address internal treasury = address(0x2222);
    address internal alice = address(0xA11CE);
    address internal bob = address(0xB0B);
    address internal challenger = address(0xC11A);

    uint256 internal constant MIN_STAKE = 10_000 ether;

    function setUp() public {
        bvt = new BVT(address(this));
        timelock = new BVTTimelock(address(this), address(this));
        staking = new BVTStaking(bvt, address(this), insurance);
        fees = new BVTFeeRouter(bvt, staking, address(this), insurance, treasury);
        governor = new BVTGovernor(staking, timelock, address(this));
        _wire();
    }

    function _wire() internal {
        bvt.grantRole(bvt.MINTER_ROLE(), address(staking));
        bvt.grantRole(bvt.MINTER_ROLE(), address(fees));
        bvt.grantRole(bvt.LOCKER_ROLE(), address(staking));
        staking.grantRole(staking.BOOTSTRAP_ROLE(), address(this));
        staking.grantRole(staking.SLASHER_ROLE(), address(timelock));
        staking.grantRole(staking.SLASHER_ROLE(), address(this));
        staking.grantRole(staking.REWARDER_ROLE(), address(fees));
        staking.grantRole(staking.GOVERNANCE_ROLE(), address(timelock));
        fees.grantRole(fees.GOVERNANCE_ROLE(), address(timelock));
        fees.grantRole(fees.EARNER_ROLE(), address(timelock));
        timelock.setGovernor(address(governor));
    }

    // ── no premine / no public sale
    // ─────────────────────────────────────────

    function test_noPremineOnDeploy() public view {
        assertEq(bvt.totalSupply(), 0);
        assertEq(bvt.balanceOf(address(this)), 0);
        assertEq(bvt.balanceOf(alice), 0);
        assertEq(bvt.name(), "Bot Verifier Token");
        assertEq(bvt.symbol(), "BVT");
        assertEq(bvt.decimals(), 18);
    }

    function test_randomAccountCannotMint() public {
        vm.prank(alice);
        vm.expectRevert();
        bvt.mint(alice, 1 ether);
    }

    function test_noPublicSaleBuy() public {
        // There is no buy / presale / ICO function. A stray call to a missing
        // selector reverts; supply stays zero until earn or operator bootstrap.
        (bool ok,) = address(bvt).call(abi.encodeWithSignature("buy()"));
        assertFalse(ok);
        (ok,) = address(bvt).call(abi.encodeWithSignature("presale(uint256)", uint256(1)));
        assertFalse(ok);
        (ok,) = address(staking).call(abi.encodeWithSignature("buyStake()"));
        assertFalse(ok);
        assertEq(bvt.totalSupply(), 0);
    }

    function test_bootstrapIsLockedNotSale() public {
        staking.bootstrapOperator(alice, MIN_STAKE);
        assertEq(bvt.totalSupply(), MIN_STAKE);
        assertEq(bvt.balanceOf(alice), MIN_STAKE);
        assertEq(bvt.locked(alice), MIN_STAKE);
        assertEq(bvt.unlockedOf(alice), 0);
        vm.prank(alice);
        vm.expectRevert(bytes("BVT: insufficient unlocked"));
        bvt.transfer(bob, 1);
    }

    // ── mint / earn paths
    // ───────────────────────────────────────────────────

    function test_earnMintOnUsage() public {
        staking.bootstrapOperator(alice, MIN_STAKE);
        fees.awardUsage(bob, 80 ether, keccak256("scenario-contrib"));
        assertEq(bvt.balanceOf(bob), 80 ether);
        assertEq(bvt.unlockedOf(bob), 80 ether);
        assertEq(bvt.locked(bob), 0);
    }

    function test_settleAuditMintsUsageReward() public {
        staking.bootstrapOperator(alice, MIN_STAKE);
        fees.awardUsage(bob, 250 ether, keccak256("seed"));
        bytes32 botId = keccak256("bot-1");
        vm.startPrank(bob);
        bvt.approve(address(fees), type(uint256).max);
        fees.payAudit(botId, alice);
        vm.stopPrank();

        uint256 beforeBal = bvt.balanceOf(alice);
        fees.settleAudit(botId, alice, 0);
        assertEq(bvt.balanceOf(alice), beforeBal + fees.usageReward());
        assertTrue(fees.isSettled(botId));
        (,,, uint256 audits,, bool active,) = staking.auditors(alice);
        assertEq(audits, 1);
        assertTrue(active);
    }

    function test_settleAuditIsOneShot() public {
        staking.bootstrapOperator(alice, MIN_STAKE);
        fees.awardUsage(bob, 250 ether, keccak256("seed"));
        bytes32 botId = keccak256("bot-oneshot");
        vm.startPrank(bob);
        bvt.approve(address(fees), type(uint256).max);
        fees.payAudit(botId, alice);
        vm.stopPrank();

        fees.settleAudit(botId, alice, 10 ether);
        assertTrue(fees.isSettled(botId));
        uint256 afterFirst = bvt.balanceOf(alice);
        vm.expectRevert(bytes("Fee: already settled"));
        fees.settleAudit(botId, alice, 10 ether);
        assertEq(bvt.balanceOf(alice), afterFirst);
    }

    function test_settleAuditRequiresPaidFee() public {
        staking.bootstrapOperator(alice, MIN_STAKE);
        vm.expectRevert(bytes("Fee: audit unpaid"));
        fees.settleAudit(keccak256("unpaid"), alice, 10 ether);
    }

    // ── stake / unstake
    // ─────────────────────────────────────────────────────

    function test_stakeAndUnstake() public {
        fees.awardUsage(alice, MIN_STAKE + 1_000 ether, keccak256("earn"));
        vm.startPrank(alice);
        staking.stake(MIN_STAKE);
        assertTrue(staking.isActiveAuditor(alice));
        assertEq(staking.stakeOf(alice), MIN_STAKE);
        assertEq(bvt.unlockedOf(alice), 1_000 ether);

        staking.requestUnstake(MIN_STAKE);
        assertFalse(staking.isActiveAuditor(alice));
        vm.expectRevert(bytes("Staking: cooldown"));
        staking.withdrawStake();

        vm.warp(block.timestamp + 48 hours);
        staking.withdrawStake();
        vm.stopPrank();

        assertEq(bvt.unlockedOf(alice), MIN_STAKE + 1_000 ether);
        assertEq(bvt.locked(alice), 0);
        assertEq(staking.stakeOf(alice), 0);
    }

    function test_cannotStakeWhenBanned() public {
        staking.bootstrapOperator(alice, MIN_STAKE);
        staking.slash(alice, SlashReason.FakeHash, address(0));
        fees.awardUsage(alice, MIN_STAKE, keccak256("later"));
        vm.prank(alice);
        vm.expectRevert(bytes("Staking: banned"));
        staking.stake(MIN_STAKE);
    }

    // ── slash
    // ───────────────────────────────────────────────────────────────

    function test_slashFakeHashBansAndPaysInsurance() public {
        staking.bootstrapOperator(alice, MIN_STAKE);
        staking.slash(alice, SlashReason.FakeHash, address(0));
        assertTrue(staking.isBanned(alice));
        assertFalse(staking.isActiveAuditor(alice));
        assertEq(staking.stakeOf(alice), 0);
        assertEq(bvt.balanceOf(insurance), MIN_STAKE);
        assertEq(bvt.locked(alice), 0);
    }

    function test_slashBuriedIsFiftyPercent() public {
        staking.bootstrapOperator(alice, MIN_STAKE);
        staking.slash(alice, SlashReason.BuriedIncidents, address(0));
        assertEq(staking.stakeOf(alice), MIN_STAKE / 2);
        assertFalse(staking.isBanned(alice));
        assertFalse(staking.isActiveAuditor(alice)); // below min
        assertEq(bvt.balanceOf(insurance), MIN_STAKE / 2);
    }

    function test_slashPaysChallengerThirtyPercent() public {
        staking.bootstrapOperator(alice, MIN_STAKE);
        staking.slash(alice, SlashReason.RiggedScores, challenger);
        uint256 toChallenger = (MIN_STAKE * 3_000) / 10_000;
        assertEq(bvt.unlockedOf(challenger), toChallenger);
        assertEq(bvt.balanceOf(insurance), MIN_STAKE - toChallenger);
        assertTrue(staking.isBanned(alice));
    }

    function test_strangerCannotSlash() public {
        staking.bootstrapOperator(alice, MIN_STAKE);
        vm.prank(bob);
        vm.expectRevert();
        staking.slash(alice, SlashReason.FakeHash, bob);
    }

    // ── fee pay
    // ─────────────────────────────────────────────────────────────

    function test_feePaySplitsAndMarksPaid() public {
        fees.awardUsage(bob, 1_000 ether, keccak256("liq"));
        bytes32 botId = keccak256("reg-bot");
        uint256 fee = fees.feeOf(FeeKind.Registration);
        vm.startPrank(bob);
        bvt.approve(address(fees), fee);
        fees.pay(botId, FeeKind.Registration);
        vm.stopPrank();

        assertTrue(fees.hasPaid(botId, FeeKind.Registration));
        fees.requirePaid(botId, FeeKind.Registration);

        uint256 auditorShare = (fee * 7_000) / 10_000;
        uint256 insShare = (fee * 2_000) / 10_000;
        uint256 treShare = fee - auditorShare - insShare;
        assertEq(bvt.balanceOf(treasury), auditorShare + treShare);
        assertEq(bvt.balanceOf(insurance), insShare);
        assertEq(bvt.balanceOf(address(fees)), 0);
    }

    function test_payVaultAccessRecordsTier() public {
        fees.awardUsage(bob, 1_000 ether, keccak256("liq"));
        bytes32 botId = keccak256("vault-bot");
        vm.startPrank(bob);
        bvt.approve(address(fees), 500 ether);
        fees.payVaultAccess(botId, 4); // Critical
        vm.stopPrank();
        assertTrue(fees.hasPaid(botId, FeeKind.VaultAccess));
        assertEq(fees.vaultTierPaid(botId), 4);
    }

    function test_cannotDoublePay() public {
        fees.awardUsage(bob, 1_000 ether, keccak256("liq"));
        bytes32 botId = keccak256("dup");
        vm.startPrank(bob);
        bvt.approve(address(fees), type(uint256).max);
        fees.pay(botId, FeeKind.Registration);
        vm.expectRevert(bytes("Fee: already paid"));
        fees.pay(botId, FeeKind.Registration);
        vm.stopPrank();
    }

    function test_hooksDoNotBreakExistingVault() public {
        Denylist denylist = new Denylist();
        Vault vault = new Vault(address(denylist));
        bytes32 botId = keccak256("legacy");
        vault.register(botId, keccak256("w"), keccak256("s"), keccak256("p"), Vault.Tier.Chat);
        (,,,, bool active,) = vault.bots(botId);
        assertTrue(active);
        assertTrue(vault.grantAccess(botId, 1));
        // BVT gate is opt-in later: Vault does not call requirePaid yet.
        assertFalse(fees.hasPaid(botId, FeeKind.Registration));
    }

    // ── proposal + timelock
    // ─────────────────────────────────────────────────

    function test_proposalTimelockChangesMinStake() public {
        staking.bootstrapOperator(alice, MIN_STAKE);
        staking.bootstrapOperator(bob, MIN_STAKE);

        address[] memory targets = new address[](1);
        bytes[] memory data = new bytes[](1);
        targets[0] = address(staking);
        data[0] = abi.encodeWithSelector(BVTStaking.setMinStake.selector, uint256(12_000 ether));

        vm.prank(alice);
        uint256 id = governor.propose(targets, data, "raise min stake to 12k");
        assertEq(uint256(governor.state(id)), uint256(BVTGovernor.ProposalState.Active));

        vm.prank(alice);
        governor.vote(id, true);
        vm.prank(bob);
        governor.vote(id, true);

        vm.expectRevert(bytes("Governor: not succeeded"));
        governor.queue(id);

        vm.warp(block.timestamp + 5 days);
        assertEq(uint256(governor.state(id)), uint256(BVTGovernor.ProposalState.Succeeded));

        uint256 batchId = governor.queue(id);
        assertEq(uint256(governor.state(id)), uint256(BVTGovernor.ProposalState.Queued));

        vm.expectRevert(bytes("Timelock: delay"));
        timelock.execute(batchId);

        vm.warp(block.timestamp + 48 hours);
        timelock.execute(batchId);

        assertEq(staking.minStake(), 12_000 ether);
        assertEq(uint256(governor.state(id)), uint256(BVTGovernor.ProposalState.Executed));
        assertEq(timelock.delay(), 48 hours);
    }

    function test_guardianCanCancelQueued() public {
        staking.bootstrapOperator(alice, MIN_STAKE);
        address[] memory targets = new address[](1);
        bytes[] memory data = new bytes[](1);
        targets[0] = address(fees);
        data[0] = abi.encodeWithSelector(BVTFeeRouter.setFee.selector, FeeKind.Audit, uint256(1 ether));

        vm.prank(alice);
        uint256 id = governor.propose(targets, data, "cut audit fee");
        vm.prank(alice);
        governor.vote(id, true);
        vm.warp(block.timestamp + 5 days);
        uint256 batchId = governor.queue(id);
        timelock.cancel(batchId, "objection");
        vm.warp(block.timestamp + 48 hours);
        vm.expectRevert(bytes("Timelock: closed"));
        timelock.execute(batchId);
        assertEq(fees.feeOf(FeeKind.Audit), 250 ether);
    }

    function test_cannotSetUnstakeCooldownBelowFloor() public {
        staking.setUnstakeCooldown(2 hours);
        assertEq(staking.unstakeCooldown(), 2 hours);
        vm.expectRevert(bytes("Staking: cooldown floor"));
        staking.setUnstakeCooldown(0);
        vm.expectRevert(bytes("Staking: cooldown floor"));
        staking.setUnstakeCooldown(1 hours - 1);
        assertEq(staking.unstakeCooldown(), 2 hours);
        assertEq(staking.MIN_UNSTAKE_COOLDOWN(), 1 hours);
    }

    function test_belowThresholdCannotPropose() public {
        fees.awardUsage(alice, 100 ether, keccak256("dust"));
        vm.prank(alice);
        staking.stake(100 ether);
        address[] memory targets = new address[](1);
        bytes[] memory data = new bytes[](1);
        targets[0] = address(staking);
        data[0] = abi.encodeWithSelector(BVTStaking.setMinStake.selector, uint256(1));
        vm.prank(alice);
        vm.expectRevert(bytes("Governor: threshold"));
        governor.propose(targets, data, "nope");
    }

    function test_voteWeightUsesProposeSnapshotAfterUnstake() public {
        staking.bootstrapOperator(alice, MIN_STAKE);
        staking.bootstrapOperator(bob, MIN_STAKE);

        (address[] memory targets, bytes[] memory data) = _dummyProposal();
        vm.prank(alice);
        uint256 id = governor.propose(targets, data, "snapshot after unstake");
        assertEq(governor.snapshotWeight(id, alice), MIN_STAKE);

        vm.roll(block.number + 1);
        vm.prank(alice);
        staking.requestUnstake(MIN_STAKE);
        assertEq(staking.stakeOf(alice), 0);
        assertEq(governor.snapshotWeight(id, alice), MIN_STAKE);

        vm.prank(alice);
        governor.vote(id, true);
        (,,, uint256 forVotes,,,,,,) = governor.proposals(id);
        assertEq(forVotes, MIN_STAKE);
    }

    function test_cannotInflateVoteWeightAfterPropose() public {
        staking.bootstrapOperator(alice, MIN_STAKE);
        staking.bootstrapOperator(bob, MIN_STAKE);

        (address[] memory targets, bytes[] memory data) = _dummyProposal();
        vm.prank(alice);
        uint256 id = governor.propose(targets, data, "no inflate");

        vm.roll(block.number + 1);
        staking.bootstrapOperator(alice, MIN_STAKE);
        assertEq(staking.stakeOf(alice), 2 * MIN_STAKE);
        assertEq(governor.snapshotWeight(id, alice), MIN_STAKE);

        vm.prank(alice);
        governor.vote(id, true);
        (,,, uint256 forVotes,,,,,,) = governor.proposals(id);
        assertEq(forVotes, MIN_STAKE);
    }

    function test_unstakeAfterVoteDoesNotChangeTally() public {
        staking.bootstrapOperator(alice, MIN_STAKE);
        staking.bootstrapOperator(bob, MIN_STAKE);

        (address[] memory targets, bytes[] memory data) = _dummyProposal();
        vm.prank(alice);
        uint256 id = governor.propose(targets, data, "unstake after vote");
        vm.prank(alice);
        governor.vote(id, true);

        vm.roll(block.number + 1);
        vm.prank(alice);
        staking.requestUnstake(MIN_STAKE);
        (,,, uint256 forVotes,,,,,,) = governor.proposals(id);
        assertEq(forVotes, MIN_STAKE);
        assertEq(staking.stakeOf(alice), 0);
    }

    function _dummyProposal() internal view returns (address[] memory targets, bytes[] memory data) {
        targets = new address[](1);
        data = new bytes[](1);
        targets[0] = address(fees);
        data[0] = abi.encodeWithSelector(BVTFeeRouter.setFee.selector, FeeKind.Audit, uint256(1 ether));
    }
}

contract DeployBVTGuardTest is Test {
    DeployBVT internal deploy;

    function setUp() public {
        deploy = new DeployBVT();
    }

    function test_allowsBaseSepolia() public {
        vm.chainId(84532);
        deploy.requireAllowedChain();
    }

    function test_refusesMainnet() public {
        vm.chainId(1);
        vm.expectRevert(bytes("DeployBVT: mainnet forbidden"));
        deploy.requireAllowedChain();
    }

    function test_refusesEthSepoliaByDefault() public {
        vm.chainId(11155111);
        vm.expectRevert(bytes("DeployBVT: Base Sepolia (84532) only; see README to switch to ETH Sepolia (11155111)"));
        deploy.requireAllowedChain();
    }

    function test_refusesAnvil() public {
        vm.chainId(31337);
        vm.expectRevert(bytes("DeployBVT: Base Sepolia (84532) only; see README to switch to ETH Sepolia (11155111)"));
        deploy.requireAllowedChain();
    }

    function test_constantsDocumentEthSepolia() public view {
        assertEq(deploy.ETH_SEPOLIA_CHAIN_ID(), 11155111);
        assertEq(deploy.ALLOWED_CHAIN_ID(), 84532);
        assertEq(deploy.ETH_MAINNET_CHAIN_ID(), 1);
    }
}

/// @notice Production DeployBVT path: sinks default to timelock; deployer hot roles renounced.
contract BVTHardenTest is Test {
    BVT internal bvt;
    BVTStaking internal staking;
    BVTFeeRouter internal fees;
    BVTTimelock internal timelock;
    BVTGovernor internal governor;
    address internal deployer;

    function setUp() public {
        deployer = address(this);
        bvt = new BVT(deployer);
        timelock = new BVTTimelock(deployer, deployer);
        staking = new BVTStaking(bvt, deployer, address(timelock));
        fees = new BVTFeeRouter(bvt, staking, deployer, address(timelock), address(timelock));
        governor = new BVTGovernor(staking, timelock, deployer);
        _wireAndHarden();
    }

    function _wireAndHarden() internal {
        bvt.grantRole(bvt.MINTER_ROLE(), address(staking));
        bvt.grantRole(bvt.MINTER_ROLE(), address(fees));
        bvt.grantRole(bvt.LOCKER_ROLE(), address(staking));
        staking.grantRole(staking.BOOTSTRAP_ROLE(), address(timelock));
        staking.grantRole(staking.SLASHER_ROLE(), address(timelock));
        staking.grantRole(staking.REWARDER_ROLE(), address(fees));
        staking.grantRole(staking.GOVERNANCE_ROLE(), address(timelock));
        fees.grantRole(fees.GOVERNANCE_ROLE(), address(timelock));
        fees.grantRole(fees.EARNER_ROLE(), address(timelock));
        timelock.setGovernor(address(governor));

        bytes32 adminRole = bvt.DEFAULT_ADMIN_ROLE();
        bvt.grantRole(adminRole, address(timelock));
        staking.grantRole(adminRole, address(timelock));
        fees.grantRole(adminRole, address(timelock));
        governor.setAdmin(address(timelock));
        timelock.transferAdmin(address(timelock));
        staking.renounceRole(staking.GOVERNANCE_ROLE(), deployer);
        staking.renounceRole(adminRole, deployer);
        fees.renounceRole(fees.EARNER_ROLE(), deployer);
        fees.renounceRole(fees.GOVERNANCE_ROLE(), deployer);
        fees.renounceRole(adminRole, deployer);
        bvt.renounceRole(adminRole, deployer);
    }

    function test_sinksDefaultToTimelockNotDeployer() public view {
        assertEq(fees.insuranceSink(), address(timelock));
        assertEq(fees.treasury(), address(timelock));
        assertEq(staking.insuranceSink(), address(timelock));
        assertTrue(fees.insuranceSink() != deployer);
    }

    function test_hardenRenouncesDeployerMintSlashAdmin() public view {
        bytes32 adminRole = bvt.DEFAULT_ADMIN_ROLE();
        assertFalse(bvt.hasRole(adminRole, deployer));
        assertFalse(staking.hasRole(adminRole, deployer));
        assertFalse(fees.hasRole(adminRole, deployer));
        assertFalse(fees.hasRole(fees.EARNER_ROLE(), deployer));
        assertFalse(staking.hasRole(staking.BOOTSTRAP_ROLE(), deployer));
        assertFalse(staking.hasRole(staking.SLASHER_ROLE(), deployer));
        assertFalse(staking.hasRole(staking.GOVERNANCE_ROLE(), deployer));
        assertFalse(fees.hasRole(fees.GOVERNANCE_ROLE(), deployer));

        assertTrue(bvt.hasRole(adminRole, address(timelock)));
        assertTrue(fees.hasRole(fees.EARNER_ROLE(), address(timelock)));
        assertTrue(staking.hasRole(staking.BOOTSTRAP_ROLE(), address(timelock)));
        assertTrue(staking.hasRole(staking.SLASHER_ROLE(), address(timelock)));
        assertEq(governor.admin(), address(timelock));
        assertEq(timelock.admin(), address(timelock));
        assertEq(timelock.governor(), address(governor));
    }

    function test_afterHardenDeployerCannotEarnBootstrapSlashOrSetGovernor() public {
        vm.expectRevert();
        fees.awardUsage(deployer, 1 ether, bytes32(uint256(1)));
        vm.expectRevert();
        staking.bootstrapOperator(address(0xA11CE), 10_000 ether);
        vm.expectRevert();
        staking.slash(address(0xA11CE), SlashReason.FakeHash, address(0));
        vm.expectRevert(bytes("Timelock: not admin"));
        timelock.setGovernor(deployer);
        bytes32 minter = bvt.MINTER_ROLE();
        vm.expectRevert();
        bvt.grantRole(minter, deployer);
    }
}
