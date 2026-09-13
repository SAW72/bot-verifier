// SPDX-License-Identifier: MIT
// Denylist registry — permanent, irreversible blacklist of dangerous bot fingerprints.
// Not audited. For illustration and local testing.
pragma solidity ^0.8.20;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { Ownable2Step } from "@openzeppelin/contracts/access/Ownable2Step.sol";

contract Denylist is Ownable2Step {
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

    constructor() Ownable(msg.sender) {}

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
    /// @dev Marked view so callers (e.g. escrow) can read it without state changes.
    function check(bytes32 weightHash, bytes32 behaviorSig, bytes32 promptHash)
        external
        view
        returns (MatchLevel)
    {
        if (denylistedHashes[weightHash]) {
            return MatchLevel.ExactBlock;
        }
        if (denylistedSignatures[behaviorSig]) {
            return MatchLevel.SignatureBlock;
        }
        if (denylistedPrompts[promptHash]) {
            return MatchLevel.PromptReview;
        }
        return MatchLevel.None;
    }

    /// @notice No removal function exists on purpose. Denylisting is permanent.
    function remove(bytes32) external pure {
        revert("denylist is irreversible");
    }
}
