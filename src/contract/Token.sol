// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20BurnableUpgradeable.sol";

import "./TokenStorage.sol";

contract Token is Initializable, OwnableUpgradeable, ReentrancyGuardUpgradeable, ERC20Upgradeable, ERC20BurnableUpgradeable, TokenStorage{

    string private constant NAME = "CozyXiongCoin";
    string private constant SYMBOL = "CXC";

    event BurnTokens(address account, uint256 burnedAmount, uint256 totalBurnedAmount);

    modifier onlyRedemptionPool() {
        require(msg.sender == redemptionPool, "Token.OnlyRedemptionPool: only redemptionPool can call the function");
        _;
    }

    constructor(){
        _disableInitializers();
    }

    function initialize(address _owner, address _redemptionPool) public initializer {
        __Ownable_init(_owner);

        __ERC20_init(NAME, SYMBOL);
        __ERC20Burnable_init();

        redemptionPool = _redemptionPool;
        isAllocated = false;
    }

    function decimals() public view virtual override returns (uint8) {
        return 6;
    }

    function setRedemptionPool(address _redemptionPool) external onlyOwner {
        redemptionPool = _redemptionPool;
    }

    function setAllocatePool(allocatePoolAddress memory pool) external onlyOwner {
        require(!isAllocated, "Token.setPoolAddress: token is already mint and allocated");

        require(pool.eventPool != address(0), "Token.setPoolAddress: eventPool address not exists");
        require(pool.tradePool != address(0), "Token.setPoolAddress: tradePool address not exists");
        require(pool.rewardPool != address(0), "Token.setPoolAddress: rewardPool address not exists");
        require(pool.foundationPool != address(0), "Token.setPoolAddress: foundationPool address not exists");

        allocatePool = pool;
    }

    function mintAndAllocate() external onlyOwner {
        require(!isAllocated, "Token.mintAndAllocate: token is already mint and allocated");

        _mint(allocatePool.eventPool, (TotalSupply * 4) / 10);
        _mint(allocatePool.tradePool, (TotalSupply * 3) / 10);
        _mint(allocatePool.rewardPool, (TotalSupply * 2) / 10);
        _mint(allocatePool.foundationPool, TotalSupply / 10);

        isAllocated = true;
    }

    function burn(address account, uint256 amount) external onlyRedemptionPool {
        _burn(account, amount);
        totalBurnedAmount += amount;
        emit BurnTokens(account, amount, totalBurnedAmount);
    }

    function getTotalSupply() external view returns(uint256) {
        return totalSupply();
    }

    function getAccountBalance(address account) external view returns(uint256) {
        return balanceOf(account);
    }
}
