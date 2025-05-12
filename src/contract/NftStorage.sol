// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

contract NftStorage {
    address public redemptionPool;
    uint256 public nftValue = 6e6;
    uint256 public constant validPeriod = 30 days;
    mapping(address => uint256) public nftExpirationTime;
    uint256 public rewardTokenAmount = 10e6;
    uint256 public tokenId;
    string public nftURI = "";
    string public newName;
    string public newSymbol;
}
