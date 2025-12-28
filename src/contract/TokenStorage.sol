// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

contract TokenStorage {
    uint256 public constant TotalSupply = 100_000_000 * 1e6;
    struct allocatePoolAddress {
        address eventPool;
        address tradePool;
        address rewardPool;
        address foundationPool;
    }
    allocatePoolAddress public allocatePool;
    address public redemptionPool;
    bool public isAllocated;
    uint256 public totalBurnedAmount;
}
