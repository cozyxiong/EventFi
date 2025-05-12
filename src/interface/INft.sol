// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

interface INft {
    function mint() external returns (uint256);
    function withdraw(address tokenAddress, address account, uint256 amount) external returns (bool);
    function withdrawNativeToken(address account, uint256 amount) external returns (bool);
    function updateNftNameAndSymbol(string memory _name, string memory _symbol) external;
    function updateNftURI(string memory _nftURI) external;
    function getTokenURI(uint256 tokenId) external view returns (string memory);
    function getNftExpirationTime(address account) external view returns (uint256);
    function getTokenBalance(address tokenAddress) external view returns (uint256);
}
