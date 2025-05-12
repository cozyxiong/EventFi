// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

interface IRedemptionPool {
    function claim(uint256 amount) external;
}
