// SPDX-License-Identifier: MIT
// Liability waterfall for bot-verifier.
// Owner -> Auditor -> InsuranceFund. Not audited. For illustration.
pragma solidity ^0.8.20;

interface IInsuranceFund {
    function payout(address payable recipient, uint256 amount, bytes32 claimId) external;
    function balance() external view returns (uint256);
}

contract Liability {
    address public owner;
    IInsuranceFund public insurance;

    enum Party { None, Owner, Auditor, Insurance }

    struct Claim {
        bytes32 botId;
        bytes32 incidentHash;
        address payable claimant;
        uint256 amount;
        Party liable;
        bool paid;
        uint256 createdAt;
    }

    mapping(bytes32 => Claim) public claims; // claimId => Claim
    mapping(bytes32 => bool) public incidentKnown; // prevent double claims

    event ClaimFiled(bytes32 indexed claimId, bytes32 indexed botId, Party liable, uint256 amount);
    event ClaimPaid(bytes32 indexed claimId, Party liable, uint256 amount);

    constructor(address _insurance) {
        owner = msg.sender;
        insurance = IInsuranceFund(_insurance);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "not owner");
        _;
    }

    /// @notice File a claim. liableParty is determined off-chain from audit trail,
    /// but recorded here for on-chain settlement.
    function fileClaim(
        bytes32 claimId,
        bytes32 botId,
        bytes32 incidentHash,
        address payable claimant,
        uint256 amount,
        Party liable
    ) external onlyOwner {
        require(!incidentKnown[incidentHash], "incident already claimed");
        require(amount > 0, "zero amount");
        claims[claimId] = Claim({
            botId: botId,
            incidentHash: incidentHash,
            claimant: claimant,
            amount: amount,
            liable: liable,
            paid: false,
            createdAt: block.timestamp
        });
        incidentKnown[incidentHash] = true;
        emit ClaimFiled(claimId, botId, liable, amount);
    }

    /// @notice Settle a claim following the waterfall: Owner, then Auditor, then Insurance.
    /// For this stub the owner is assumed to have pre-funded the contract.
    function settle(bytes32 claimId) external onlyOwner {
        Claim storage c = claims[claimId];
        require(!c.paid, "already paid");
        require(c.amount > 0, "no claim");

        if (c.liable == Party.Owner) {
            (bool ok, ) = c.claimant.call{value: c.amount}("");
            require(ok, "owner payout failed");
        } else if (c.liable == Party.Auditor) {
            // Auditor stake is assumed held elsewhere; here we just mark and rely on off-chain slash.
            // In production this would call the auditor staking contract.
        } else if (c.liable == Party.Insurance) {
            insurance.payout(c.claimant, c.amount, claimId);
        } else {
            revert("unknown liable party");
        }

        c.paid = true;
        emit ClaimPaid(claimId, c.liable, c.amount);
    }

    receive() external payable {}
}
