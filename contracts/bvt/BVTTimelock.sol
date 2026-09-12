// SPDX-License-Identifier: MIT
// Timelock for BVT governance. Default delay 48 hours (timelock_pattern.md).
// Not audited. For illustration and local testing.
pragma solidity ^0.8.20;

/// @title BVTTimelock
/// @notice Queued governance actions cannot execute until `delay` has passed.
contract BVTTimelock {
    uint256 public constant MIN_DELAY = 1 hours;
    uint256 public constant MAX_DELAY = 30 days;
    uint256 public constant DEFAULT_DELAY = 48 hours;

    address public admin;
    address public governor;
    address public guardian;
    uint256 public delay = DEFAULT_DELAY;

    struct Batch {
        address[] targets;
        bytes[] calldatas;
        uint256 eta;
        bool executed;
        bool cancelled;
    }

    mapping(uint256 => Batch) public batches;
    uint256 public nextBatchId;

    event Queued(uint256 indexed id, address[] targets, uint256 eta);
    event Executed(uint256 indexed id);
    event Cancelled(uint256 indexed id, string reason);
    event DelayUpdated(uint256 delay);
    event GovernorUpdated(address governor);
    event GuardianUpdated(address guardian);
    event AdminUpdated(address admin);

    modifier onlyAdmin() {
        require(msg.sender == admin, "Timelock: not admin");
        _;
    }

    modifier onlyGovernor() {
        require(msg.sender == governor, "Timelock: not governor");
        _;
    }

    modifier onlySelf() {
        require(msg.sender == address(this), "Timelock: only self");
        _;
    }

    constructor(
        address _admin,
        address _guardian
    ) {
        require(_admin != address(0), "Timelock: admin zero");
        admin = _admin;
        guardian = _guardian == address(0) ? _admin : _guardian;
    }

    function setGovernor(
        address _governor
    ) external onlyAdmin {
        require(_governor != address(0), "Timelock: governor zero");
        governor = _governor;
        emit GovernorUpdated(_governor);
    }

    function setGuardian(
        address _guardian
    ) external onlySelf {
        guardian = _guardian;
        emit GuardianUpdated(_guardian);
    }

    function setAdmin(
        address _admin
    ) external onlySelf {
        require(_admin != address(0), "Timelock: admin zero");
        admin = _admin;
        emit AdminUpdated(_admin);
    }

    /// @notice One-way handoff after `setGovernor`. Typical: `transferAdmin(address(this))`
    /// so the deployer can no longer call `setGovernor`.
    function transferAdmin(
        address newAdmin
    ) external onlyAdmin {
        require(newAdmin != address(0), "Timelock: admin zero");
        require(governor != address(0), "Timelock: no governor");
        admin = newAdmin;
        emit AdminUpdated(newAdmin);
    }

    function setDelay(
        uint256 next
    ) external onlySelf {
        require(next >= MIN_DELAY && next <= MAX_DELAY, "Timelock: delay");
        delay = next;
        emit DelayUpdated(next);
    }

    /// @notice Called by the governor after a proposal passes.
    function queue(
        address[] calldata targets,
        bytes[] calldata calldatas
    ) external onlyGovernor returns (uint256 id) {
        require(targets.length > 0 && targets.length == calldatas.length, "Timelock: length");
        id = nextBatchId++;
        uint256 eta = block.timestamp + delay;
        Batch storage b = batches[id];
        for (uint256 i = 0; i < targets.length; i++) {
            b.targets.push(targets[i]);
            b.calldatas.push(calldatas[i]);
        }
        b.eta = eta;
        emit Queued(id, targets, eta);
    }

    function execute(
        uint256 id
    ) external {
        Batch storage b = batches[id];
        require(b.eta != 0, "Timelock: unknown");
        require(!b.executed && !b.cancelled, "Timelock: closed");
        require(block.timestamp >= b.eta, "Timelock: delay");
        b.executed = true;
        uint256 n = b.targets.length;
        for (uint256 i = 0; i < n; i++) {
            (bool ok, bytes memory ret) = b.targets[i].call(b.calldatas[i]);
            require(ok, _revertMsg(ret));
        }
        emit Executed(id);
    }

    function cancel(
        uint256 id,
        string calldata reason
    ) external {
        require(msg.sender == guardian || msg.sender == governor || msg.sender == admin, "Timelock: cannot cancel");
        Batch storage b = batches[id];
        require(b.eta != 0 && !b.executed && !b.cancelled, "Timelock: closed");
        b.cancelled = true;
        emit Cancelled(id, reason);
    }

    function getBatch(
        uint256 id
    )
        external
        view
        returns (address[] memory targets, bytes[] memory calldatas, uint256 eta, bool executed, bool cancelled)
    {
        Batch storage b = batches[id];
        return (b.targets, b.calldatas, b.eta, b.executed, b.cancelled);
    }

    function _revertMsg(
        bytes memory ret
    ) private pure returns (string memory) {
        if (ret.length < 68) return "Timelock: inner revert";
        assembly {
            ret := add(ret, 0x04)
        }
        return abi.decode(ret, (string));
    }
}
