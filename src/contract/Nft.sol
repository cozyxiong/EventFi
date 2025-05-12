// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721URIStorageUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "./NftStorage.sol";
import "../interface/INft.sol";

contract Nft is Initializable, OwnableUpgradeable, ReentrancyGuardUpgradeable, ERC721Upgradeable, ERC721URIStorageUpgradeable, NftStorage, INft{

    string private constant NAME = "CryptoCozyXiong";
    string private constant SYMBOL = "COZY";

    using SafeERC20 for IERC20;
    IERC20 public usdt;
    IERC20 public token;

    event NativeTokenReceived(address sender, uint256 amount);
    event NFTMint(address indexed owner, uint256 indexed tokenId, string tokenURI, uint256 expirationTime);
    event USDTWithdraw(address initializer, address account, uint256 amount);
    event NativeTokenWithdraw(address initializer, address account, uint256 amount);
    event NftNameAndSymbolUpdated(address initialzer, string newName, string newSymbol);
    event NftURIUpdated(address initialzer, string newNftURI);

    constructor(){
        _disableInitializers();
    }

    function initialize(address _owner, address _tokenAddress, address _usdtAddress, address _redemptionPool) public initializer {
        __Ownable_init(_owner);
        __ReentrancyGuard_init();

        __ERC721_init(NAME, SYMBOL);

        token = IERC20(_tokenAddress);
        usdt = IERC20(_usdtAddress);
        redemptionPool = _redemptionPool;
    }

    receive() external payable {
        emit NativeTokenReceived(msg.sender, msg.value);
    }

    function mint() external nonReentrant returns (uint256) {
        require(
            usdt.allowance(msg.sender, address(this)) >= nftValue && usdt.balanceOf(msg.sender) >= nftValue,
            "Nft.Mint: balance or allowance not enough"
        );

        usdt.safeTransferFrom(msg.sender, address(this), nftValue);
        usdt.safeTransfer(redemptionPool, (nftValue * 75) / 100);
        token.safeTransfer(msg.sender, rewardTokenAmount);

        tokenId++;
        _safeMint(msg.sender, tokenId);
        nftExpirationTime[msg.sender] = block.timestamp + validPeriod;

        emit NFTMint(msg.sender, tokenId, nftURI, nftExpirationTime[msg.sender]);

        return tokenId;
    }

    function tokenURI(uint256 tokenId) public view override(ERC721Upgradeable, ERC721URIStorageUpgradeable) returns (string memory)  {
        require(_ownerOf(tokenId) != address(0), "Nft.tokenURI: this tokenId not exists");
        return nftURI;
    }

    function withdraw(address tokenAddress, address account, uint256 amount) external onlyOwner returns (bool) {
        require(tokenAddress != address(0), "Nft.withdraw: token address is none");
        require(account != address(0), "Nft.withdraw: account address is none");
        require(IERC20(tokenAddress).balanceOf(address(this)) >= amount, "Nft.withdraw: token balance not enough");

        IERC20(tokenAddress).safeTransfer(account, amount);

        emit USDTWithdraw(msg.sender, account, amount);

        return true;
    }

    function withdrawNativeToken(address account, uint256 amount) external onlyOwner returns (bool) {
        require(account != address(0), "Nft.withdrawNativeToken: account address is none");
        require(address(this).balance >= amount, "Nft.withdrawNativeToken: token balance not enough");

        (bool result,) = account.call{value: amount}("");

        emit NativeTokenWithdraw(msg.sender, account, amount);

        return result;
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721Upgradeable, ERC721URIStorageUpgradeable) returns (bool){
        return super.supportsInterface(interfaceId);
    }

    function updateNftNameAndSymbol(string memory _name, string memory _symbol) external onlyOwner {
        newName = _name;
        newSymbol = _symbol;
        emit NftNameAndSymbolUpdated(msg.sender, newName, newSymbol);
    }

    function name() public view override returns (string memory) {
        return bytes(newName).length > 0 ? newName : super.name();
    }

    function symbol() public view override returns (string memory) {
        return bytes(newSymbol).length > 0 ? newSymbol : super.symbol();
    }

    function updateNftURI(string memory _nftURI) external onlyOwner {
        nftURI = _nftURI;
        emit NftURIUpdated(msg.sender, nftURI);
    }

    function getTokenURI(uint256 tokenId) public view returns (string memory) {
        return tokenURI(tokenId);
    }

    function getNftExpirationTime(address account) public view returns (uint256) {
        return nftExpirationTime[account];
    }

    function getTokenBalance(address tokenAddress) public view returns (uint256) {
        return IERC20(tokenAddress).balanceOf(address(this));
    }
}
