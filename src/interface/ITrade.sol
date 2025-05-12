// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

interface ITrade {
    function purchaseTokenWithUSDT(uint256 tokenAmount) external;
    function purchaseTokenByUSDT(uint256 usdtAmount) external;
    function getTokenBalance(address tokenAddress) external view returns (uint256);
    function getTotalSoldTokenAmount() external view returns (uint256);
    function getTotalReceivedUSDTAmount() external view returns (uint256);
}
