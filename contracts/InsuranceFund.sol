// SPDX-License-Identifier: MIT
// Insurance fund backstop for bot-verifier liability.
// Funded by vault fees. Pays out when owner/auditor cannot.
// Not audited. For illustration.
pragma solidity ^0.8.20;

contract InsuranceFund {
    address public owner;
    uint256 public balance;

    event Funded(address indexed from, uint256 amount);
    event PaidOut(address indexed to, uint256 amount, bytes32 indexed claimId);

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "not owner");
        _;
    }

    function fund() external payable {
        require(msg.value > 0, "zero");
        balance += msg.value;
        emit Funded(msg.sender, msg.value);
    }

    /// @notice Called by Liability contract to pay a claim.
    function payout(address payable recipient, uint256 amount, bytes32 claimId) external {
        require(amount <= balance, "insufficient fund");
        balance -= amount;
        (bool ok, ) = recipient.call{value: amount}("");
        require(ok, "payout failed");
        emit PaidOut(recipient, amount, claimId);
    }

    function setOwner(address _owner) external onlyOwner {
        owner = _owner;
    }
}
