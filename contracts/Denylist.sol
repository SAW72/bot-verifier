// SPDX-License-Identifier: MIT
// Denylist registry — permanent, irreversible blacklist of dangerous bot fingerprints.
// Not audited. For illustration and local testing.
pragma solidity ^0.8.20;

contract Denylist {
    address public owner;

    // Exact weight-hash denylist. Irreversible once added.
    mapping(bytes32 => bool) public denylistedHashes;
    // Behavioral signature denylist (fuzzy). Irreversible.
    mapping(bytes32 => bool) public denylistedSignatures;
    // Prompt-hash denylist. Irreversible.
    mapping(bytes32 => bool) public denylistedPrompts;

    // Graduated matching: exact = hard block, signature = block+appeal, prompt = review.
    enum MatchLevel { None, PromptReview, SignatureBlock, ExactBlock }

    event Denylisted(bytes32 indexed hash, string kind, uint256 ts);
    event Checked(bytes32 indexed hash, MatchLevel level, uint256 ts);
    event OwnerUpdated(address indexed previous, address indexed next);

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "not owner");
        _;
    }

    /// @notice Hand off to a timelock (or other owner). Matches IOwnableHook.
    function setOwner(address newOwner) external onlyOwner {
        require(newOwner != address(0), "owner zero");
        emit OwnerUpdated(owner, newOwner);
        owner = newOwner;
    }

    /// @notice Irreversibly denylist an exact weight hash.
    function addExact(bytes32 hash) external onlyOwner {
        require(!denylistedHashes[hash], "already denylisted");
        denylistedHashes[hash] = true;
        emit Denylisted(hash, "exact", block.timestamp);
    }

    /// @notice Irreversibly denylist a behavioral signature.
    function addSignature(bytes32 sig) external onlyOwner {
        require(!denylistedSignatures[sig], "already denylisted");
        denylistedSignatures[sig] = true;
        emit Denylisted(sig, "signature", block.timestamp);
    }

    /// @notice Irreversibly denylist a prompt hash.
    function addPrompt(bytes32 promptHash) external onlyOwner {
        require(!denylistedPrompts[promptHash], "already denylisted");
        denylistedPrompts[promptHash] = true;
        emit Denylisted(promptHash, "prompt", block.timestamp);
    }

    /// @notice Check a candidate bot. Returns the highest match level found.
    function check(bytes32 weightHash, bytes32 behaviorSig, bytes32 promptHash)
        external
        returns (MatchLevel)
    {
        if (denylistedHashes[weightHash]) {
            emit Checked(weightHash, MatchLevel.ExactBlock, block.timestamp);
            return MatchLevel.ExactBlock;
        }
        if (denylistedSignatures[behaviorSig]) {
            emit Checked(behaviorSig, MatchLevel.SignatureBlock, block.timestamp);
            return MatchLevel.SignatureBlock;
        }
        if (denylistedPrompts[promptHash]) {
            emit Checked(promptHash, MatchLevel.PromptReview, block.timestamp);
            return MatchLevel.PromptReview;
        }
        emit Checked(weightHash, MatchLevel.None, block.timestamp);
        return MatchLevel.None;
    }

    /// @notice No removal function exists on purpose. Denylisting is permanent.
    function remove(bytes32) external pure {
        revert("denylist is irreversible");
    }
}
