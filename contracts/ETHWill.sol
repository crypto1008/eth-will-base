// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title ETH Will Contract
/// @notice Lock ETH and assign beneficiaries who can claim after a date
/// @dev Deployed on Base Mainnet

contract ETHWill {

    address public owner;
    uint256 public unlockDate;
    uint256 public lastCheckIn;
    uint256 public checkInPeriod;
    bool public executed;

    struct Beneficiary {
        address wallet;
        uint256 sharePercent;
        string name;
        bool claimed;
    }

    Beneficiary[] public beneficiaries;
    uint256 public totalDeposited;

    event Deposited(address indexed owner, uint256 amount);
    event BeneficiaryAdded(address indexed wallet, uint256 share, string name);
    event CheckedIn(address indexed owner, uint256 timestamp);
    event Claimed(address indexed beneficiary, uint256 amount);
    event WillCancelled(address indexed owner);

    modifier onlyOwner() {
        require(msg.sender == owner, "Not the will owner");
        _;
    }

    modifier notExecuted() {
        require(!executed, "Will already executed");
        _;
    }

    constructor(uint256 _unlockDate, uint256 _checkInPeriod) {
        require(_unlockDate > block.timestamp, "Date must be future");
        owner = msg.sender;
        unlockDate = _unlockDate;
        checkInPeriod = _checkInPeriod;
        lastCheckIn = block.timestamp;
    }

    function deposit() external payable onlyOwner notExecuted {
        require(msg.value > 0, "Send some ETH");
        totalDeposited += msg.value;
        emit Deposited(msg.sender, msg.value);
    }

    function addBeneficiary(
        address _wallet,
        uint256 _sharePercent,
        string calldata _name
    ) external onlyOwner notExecuted {
        require(_wallet != address(0), "Invalid address");
        require(_sharePercent > 0 && _sharePercent <= 100, "Invalid share");
        require(_totalShares() + _sharePercent <= 100, "Shares exceed 100%");
        beneficiaries.push(Beneficiary(_wallet, _sharePercent, _name, false));
        emit BeneficiaryAdded(_wallet, _sharePercent, _name);
    }

    function checkIn() external onlyOwner notExecuted {
        lastCheckIn = block.timestamp;
        emit CheckedIn(msg.sender, block.timestamp);
    }

    function cancelWill() external onlyOwner notExecuted {
        executed = true;
        uint256 balance = address(this).balance;
        payable(owner).transfer(balance);
        emit WillCancelled(msg.sender);
    }

    function claim(uint256 index) external notExecuted {
        require(_isUnlocked(), "Will not yet unlocked");
        Beneficiary storage b = beneficiaries[index];
        require(msg.sender == b.wallet, "Not your share");
        require(!b.claimed, "Already claimed");
        b.claimed = true;
        uint256 payout = (address(this).balance * b.sharePercent) / 100;
        payable(b.wallet).transfer(payout);
        emit Claimed(b.wallet, payout);
    }

    function getBeneficiaries() external view returns (Beneficiary[] memory) {
        return beneficiaries;
    }

    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }

    function isUnlocked() external view returns (bool) {
        return _isUnlocked();
    }

    function timeUntilUnlock() external view returns (uint256) {
        if (_isUnlocked()) return 0;
        return unlockDate - block.timestamp;
    }

    function _isUnlocked() internal view returns (bool) {
        bool dateReached = block.timestamp >= unlockDate;
        bool inactivity = block.timestamp >= lastCheckIn + checkInPeriod;
        return dateReached || inactivity;
    }

    function _totalShares() internal view returns (uint256 total) {
        for (uint256 i = 0; i < beneficiaries.length; i++) {
            total += beneficiaries[i].sharePercent;
        }
    }

    receive() external payable {
        totalDeposited += msg.value;
    }
}
